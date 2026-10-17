-- 02_volumen_temporal.sql
-- EECA-UCV, Computacion II | Auditoria SWITRS California 2010-2019
-- Que responde: cuantos choques, partes y victimas hay por ano, mes, dia de semana, hora y condado.
-- Cobertura: periodo decenal completo 2010-2019 (3.652 dias, sin truncamientos).

INSTALL sqlite;
LOAD sqlite;
ATTACH 'data/raw/switrs.sqlite' AS sw (TYPE sqlite, READ_ONLY);

-- T01 Volumen collisions del periodo + rango + dias con datos + unicidad case_id.
-- Se separa: total, nulos, no nulos, distintos y duplicados entre no nulos.
SELECT COUNT(*) AS n_colisiones_10_19,
       SUM(CASE WHEN case_id IS NULL THEN 1 ELSE 0 END) AS nulos_case_id,
       COUNT(*) - SUM(CASE WHEN case_id IS NULL THEN 1 ELSE 0 END) AS no_nulos_case_id,
       COUNT(DISTINCT case_id) AS n_case_id_distintos,
       CASE WHEN SUM(CASE WHEN case_id IS NULL THEN 1 ELSE 0 END) = 0
            THEN COUNT(*) - COUNT(DISTINCT case_id)
            ELSE NULL END AS duplicados_case_id_entre_no_nulos,
       COUNT(DISTINCT collision_date) AS n_dias_con_datos,
       MIN(collision_date) AS min_fecha,
       MAX(collision_date) AS max_fecha
FROM sw.collisions
WHERE collision_date >= '2010-01-01' AND collision_date < '2020-01-01';

-- T02 Collisions por anio (2010 a 2019).
SELECT CAST(substr(collision_date, 1, 4) AS INTEGER) AS anio, COUNT(*) AS n_colisiones
FROM sw.collisions
WHERE collision_date >= '2010-01-01' AND collision_date < '2020-01-01'
GROUP BY substr(collision_date, 1, 4)
ORDER BY anio;

-- T02b Collisions por mes (patron estacional).
SELECT strftime(CAST(collision_date AS DATE), '%m') AS mes,
       COUNT(*) AS n_colisiones,
       ROUND(100.0 * COUNT(*) / (SELECT COUNT(*) FROM sw.collisions WHERE collision_date >= '2010-01-01' AND collision_date < '2020-01-01'), 2) AS pct
FROM sw.collisions
WHERE collision_date >= '2010-01-01' AND collision_date < '2020-01-01'
GROUP BY mes
ORDER BY mes;

-- T02c Collisions por dia de la semana (patron semanal).
SELECT dayname(CAST(collision_date AS DATE)) AS dia_semana,
       COUNT(*) AS n_colisiones,
       ROUND(100.0 * COUNT(*) / (SELECT COUNT(*) FROM sw.collisions WHERE collision_date >= '2010-01-01' AND collision_date < '2020-01-01'), 2) AS pct
FROM sw.collisions
WHERE collision_date >= '2010-01-01' AND collision_date < '2020-01-01'
GROUP BY dia_semana
ORDER BY n_colisiones DESC;

-- T02d Collisions por hora del dia (patron horario a partir de collision_time).
SELECT CASE WHEN collision_time IS NULL THEN 'DESCONOCIDA'
            ELSE substr(collision_time, 1, 2) || ':00' END AS hora,
       COUNT(*) AS n_colisiones,
       ROUND(100.0 * COUNT(*) / (SELECT COUNT(*) FROM sw.collisions WHERE collision_date >= '2010-01-01' AND collision_date < '2020-01-01'), 2) AS pct
FROM sw.collisions
WHERE collision_date >= '2010-01-01' AND collision_date < '2020-01-01'
GROUP BY hora
ORDER BY hora;

-- T02e Collisions por condado (distribucion geografica, TOP 20).
SELECT county_location AS condado,
       COUNT(*) AS n_colisiones,
       ROUND(100.0 * COUNT(*) / (SELECT COUNT(*) FROM sw.collisions WHERE collision_date >= '2010-01-01' AND collision_date < '2020-01-01'), 2) AS pct
FROM sw.collisions
WHERE collision_date >= '2010-01-01' AND collision_date < '2020-01-01'
GROUP BY county_location
ORDER BY n_colisiones DESC
LIMIT 20;

-- T03 Parties por anio (anio obtenido via JOIN con collisions; resuelve error de ambito en subquery).
SELECT CAST(substr(c.collision_date, 1, 4) AS INTEGER) AS anio,
       COUNT(*) AS n_partes
FROM sw.parties AS p
JOIN sw.collisions AS c ON c.case_id = p.case_id
WHERE c.collision_date >= '2010-01-01' AND c.collision_date < '2020-01-01'
GROUP BY anio
ORDER BY anio;

-- T04 Victims por anio. Ojo: desde 2017 SWITRS reporta ~65% menos victimas ilesas
-- (no injury), por lo que el total anual de victimas no es comparable antes/despues
-- de 2017; la serie homologada por nivel KABCO esta en 07-N15.
SELECT CAST(substr(c.collision_date, 1, 4) AS INTEGER) AS anio,
       COUNT(*) AS n_victimas
FROM sw.victims AS v
JOIN sw.collisions AS c ON c.case_id = v.case_id
WHERE c.collision_date >= '2010-01-01' AND c.collision_date < '2020-01-01'
GROUP BY substr(c.collision_date, 1, 4)
ORDER BY anio;

-- T05 Calendario completo: 3652 dias esperados (2010-2019, incluye bisiestos 2012 y 2016).
WITH dias(dia) AS (
    SELECT CAST(t.d AS DATE) AS dia
    FROM RANGE(DATE '2010-01-01', DATE '2020-01-01', INTERVAL 1 DAY) AS t(d)
),
diario AS (
    SELECT CAST(collision_date AS DATE) AS dia
    FROM sw.collisions
    WHERE collision_date >= '2010-01-01' AND collision_date < '2020-01-01'
    GROUP BY CAST(collision_date AS DATE)
)
SELECT (SELECT COUNT(*) FROM dias) AS dias_esperados_3652,
       (SELECT COUNT(*) FROM diario) AS dias_con_datos,
       (SELECT COUNT(*) FROM dias AS d LEFT JOIN diario AS x USING (dia) WHERE x.dia IS NULL) AS dias_en_cero;

-- T06 Dias sin colisiones en el periodo (esperado: 0 dias vacios en 2010-2019).
WITH dias(dia) AS (
    SELECT CAST(t.d AS DATE) AS dia
    FROM RANGE(DATE '2010-01-01', DATE '2020-01-01', INTERVAL 1 DAY) AS t(d)
),
diario AS (
    SELECT CAST(collision_date AS DATE) AS dia
    FROM sw.collisions
    WHERE collision_date >= '2010-01-01' AND collision_date < '2020-01-01'
    GROUP BY CAST(collision_date AS DATE)
)
SELECT d.dia AS dia_sin_colisiones
FROM dias AS d LEFT JOIN diario AS x USING (dia)
WHERE x.dia IS NULL
ORDER BY d.dia
LIMIT 50;

-- T07 Intensidad diaria (media sobre calendario, media en dias con datos y valor pico).
WITH diario AS (
    SELECT CAST(collision_date AS DATE) AS dia, COUNT(*) AS n_dia
    FROM sw.collisions
    WHERE collision_date >= '2010-01-01' AND collision_date < '2020-01-01'
    GROUP BY CAST(collision_date AS DATE)
)
SELECT ROUND((SELECT COUNT(*) FROM sw.collisions
              WHERE collision_date >= '2010-01-01' AND collision_date < '2020-01-01') / 3652.0, 1) AS promedio_diario_sobre_calendario,
       ROUND(AVG(n_dia), 1) AS promedio_diario_solo_dias_con_datos,
       MIN(n_dia) AS minimo_diario,
       MAX(n_dia) AS pico_diario
FROM diario;

-- T08 Cierre metodologico: resumen del volumen temporal 2010-2019.
SELECT 'DECISION_NORMALIZACION: cobertura decenal 2010-2019 completa y continua (3.652 dias sin huecos); collision_date se almacena como DATE y collision_time como TIME (NULL = hora desconocida); dim_fecha se genera por calendario (3.652 dias), no a partir de los datos; los hechos se particionan por anio (10 particiones Parquet); el total anual de victimas no es comparable antes/despues de 2017 para ilesos (07-N15).' AS decision_normalizacion;
