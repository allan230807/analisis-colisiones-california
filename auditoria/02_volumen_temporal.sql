-- 02_volumen_temporal.sql
-- EECA-UCV, Computacion II | Auditoria SWITRS California 2016-2021
-- Que responde: cuantos choques, partes y victimas hay por ano y por dia.
-- Para el perfil de siniestros: el tamano del retrato (2016-2021) y sus huecos
-- (2021 llega solo hasta junio).

INSTALL sqlite;
LOAD sqlite;
ATTACH 'data/raw/switrs.sqlite' AS sw (TYPE sqlite, READ_ONLY);

-- T01 Volumen collisions del periodo + rango + dias con datos + unicidad case_id.
SELECT COUNT(*) AS n_colisiones_16_21,
       COUNT(DISTINCT case_id) AS n_case_id_distintos,
       COUNT(*) - COUNT(DISTINCT case_id) AS n_case_id_repetidos,
       COUNT(DISTINCT collision_date) AS n_dias_con_datos,
       MIN(collision_date) AS min_fecha,
       MAX(collision_date) AS max_fecha
FROM sw.collisions
WHERE collision_date >= '2016-01-01' AND collision_date < '2022-01-01';

-- T02 Collisions por anio (GROUP BY simple; el TOTAL va en T01, sin GROUPING SETS).
SELECT CAST(substr(collision_date, 1, 4) AS INTEGER) AS anio, COUNT(*) AS n_colisiones
FROM sw.collisions
WHERE collision_date >= '2016-01-01' AND collision_date < '2022-01-01'
GROUP BY substr(collision_date, 1, 4)
ORDER BY anio;

-- T03 Parties por anio (anio heredado de collisions via EXISTS; sin GROUPING SETS).
SELECT CAST(substr(c.collision_date, 1, 4) AS INTEGER) AS anio,
       COUNT(*) AS n_partes
FROM sw.parties AS p
WHERE EXISTS (
    SELECT 1
    FROM sw.collisions AS c
    WHERE c.case_id = p.case_id
      AND c.collision_date >= '2016-01-01'
      AND c.collision_date < '2022-01-01'
)
GROUP BY anio
ORDER BY anio;

-- T04 Victims por anio (mismo patron).
SELECT CAST(substr(c.collision_date, 1, 4) AS INTEGER) AS anio, COUNT(*) AS n_victimas
FROM sw.victims AS v
JOIN sw.collisions AS c ON c.case_id = v.case_id
WHERE c.collision_date >= '2016-01-01' AND c.collision_date < '2022-01-01'
GROUP BY substr(c.collision_date, 1, 4)
ORDER BY anio;

-- T05 Calendario completo: 2192 dias esperados vs dias con datos vs dias en cero.
-- RANGE con fechas explicitas (forma canonica DuckDB); debe dar 2192 exactos.
WITH dias(dia) AS (
    SELECT CAST(t.d AS DATE) AS dia
    FROM RANGE(DATE '2016-01-01', DATE '2022-01-01', INTERVAL 1 DAY) AS t(d)
),
diario AS (
    SELECT CAST(collision_date AS DATE) AS dia
    FROM sw.collisions
    WHERE collision_date >= '2016-01-01' AND collision_date < '2022-01-01'
    GROUP BY CAST(collision_date AS DATE)
)
SELECT (SELECT COUNT(*) FROM dias) AS dias_esperados_2192,
       (SELECT COUNT(*) FROM diario) AS dias_con_datos,
       (SELECT COUNT(*) FROM dias AS d LEFT JOIN diario AS x USING (dia) WHERE x.dia IS NULL) AS dias_en_cero;

-- T06 Primeros 100 dias sin colisiones (esperado: cola 2021-06-04 a 2021-12-31 por truncado).
WITH dias(dia) AS (
    SELECT CAST(t.d AS DATE) AS dia
    FROM RANGE(DATE '2016-01-01', DATE '2022-01-01', INTERVAL 1 DAY) AS t(d)
),
diario AS (
    SELECT CAST(collision_date AS DATE) AS dia
    FROM sw.collisions
    WHERE collision_date >= '2016-01-01' AND collision_date < '2022-01-01'
    GROUP BY CAST(collision_date AS DATE)
)
SELECT d.dia AS dia_sin_colisiones
FROM dias AS d LEFT JOIN diario AS x USING (dia)
WHERE x.dia IS NULL
ORDER BY d.dia
LIMIT 100;

-- T07 Intensidad diaria (dimensiona particiones y lote de carga).
WITH diario AS (
    SELECT CAST(collision_date AS DATE) AS dia, COUNT(*) AS n_dia
    FROM sw.collisions
    WHERE collision_date >= '2016-01-01' AND collision_date < '2022-01-01'
    GROUP BY CAST(collision_date AS DATE)
)
SELECT ROUND((SELECT COUNT(*) FROM sw.collisions
              WHERE collision_date >= '2016-01-01' AND collision_date < '2022-01-01') / 2192.0, 1) AS promedio_diario_sobre_calendario,
       ROUND(AVG(n_dia), 1) AS promedio_diario_solo_dias_con_datos,
       MAX(n_dia) AS pico_diario
FROM diario;

-- T08 Cierre: como se parte el retrato por ano (2021 parcial).
SELECT 'DECISION_NORMALIZACION: particionar el hecho por anio (6 particiones 2016-2021); 2021 es particion parcial (corte 2021-06-03, documentar en diccionario); dim_fecha precargada con 2192 dias + flag tiene_datos para que los dias en cero no rompan series; case_id como PK del grano colision si T01 confirma unicidad.' AS decision_normalizacion;
