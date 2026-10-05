-- 05_integridad_duplicados.sql
-- EECA-UCV, Computacion II | Auditoria SWITRS California 2016-2021
-- Que responde: si las piezas encajan (partes y victimas con su choque) y si
-- las listas tienen repetidos.
-- Para el perfil de siniestros: garantiza que ningun perfil cuente choques
-- huerfanos ni listas duplicadas.

INSTALL sqlite;
LOAD sqlite;
ATTACH 'data/raw/switrs.sqlite' AS sw (TYPE sqlite, READ_ONLY);

-- A01 Duplicados dim_severidad (esperado: limpio).
SELECT 'dim_severidad' AS dimension, codigo_original AS valor, COUNT(*) AS n_filas,
       MIN(severidad_id) AS id_min, MAX(severidad_id) AS id_max,
       STRING_AGG(CAST(severidad_id AS VARCHAR), ', ' ORDER BY severidad_id) AS ids
FROM sw.dim_severidad
GROUP BY codigo_original
HAVING COUNT(*) > 1;

-- A02 Duplicados dim_grado_lesion (esperado: limpio).
SELECT 'dim_grado_lesion' AS dimension, codigo_original AS valor, COUNT(*) AS n_filas,
       MIN(grado_lesion_id) AS id_min, MAX(grado_lesion_id) AS id_max,
       STRING_AGG(CAST(grado_lesion_id AS VARCHAR), ', ' ORDER BY grado_lesion_id) AS ids
FROM sw.dim_grado_lesion
GROUP BY codigo_original
HAVING COUNT(*) > 1;

-- A03 Duplicados dim_tipo_vehiculo (esperado: limpio).
SELECT 'dim_tipo_vehiculo' AS dimension, codigo_original AS valor, COUNT(*) AS n_filas,
       MIN(tipo_vehiculo_id) AS id_min, MAX(tipo_vehiculo_id) AS id_max,
       STRING_AGG(CAST(tipo_vehiculo_id AS VARCHAR), ', ' ORDER BY tipo_vehiculo_id) AS ids
FROM sw.dim_tipo_vehiculo
GROUP BY codigo_original
HAVING COUNT(*) > 1;

-- A04 Duplicados dim_sexo (esperado: limpio).
SELECT 'dim_sexo' AS dimension, codigo AS valor, COUNT(*) AS n_filas,
       MIN(sexo_id) AS id_min, MAX(sexo_id) AS id_max,
       STRING_AGG(CAST(sexo_id AS VARCHAR), ', ' ORDER BY sexo_id) AS ids
FROM sw.dim_sexo
GROUP BY codigo
HAVING COUNT(*) > 1;

-- A05 Duplicados dim_grupo_edad (esperado: limpio).
SELECT 'dim_grupo_edad' AS dimension, etiqueta AS valor, COUNT(*) AS n_filas,
       MIN(grupo_edad_id) AS id_min, MAX(grupo_edad_id) AS id_max,
       STRING_AGG(CAST(grupo_edad_id AS VARCHAR), ', ' ORDER BY grupo_edad_id) AS ids
FROM sw.dim_grupo_edad
GROUP BY etiqueta
HAVING COUNT(*) > 1;

-- A06 Duplicados dim_tipo_colision.
SELECT 'dim_tipo_colision' AS dimension, descripcion AS valor, COUNT(*) AS n_filas,
       MIN(tipo_colision_id) AS id_min, MAX(tipo_colision_id) AS id_max,
       STRING_AGG(CAST(tipo_colision_id AS VARCHAR), ', ' ORDER BY tipo_colision_id) AS ids
FROM sw.dim_tipo_colision
GROUP BY descripcion
HAVING COUNT(*) > 1;

-- A07 Duplicados dim_clima.
SELECT 'dim_clima' AS dimension, descripcion AS valor, COUNT(*) AS n_filas,
       MIN(clima_id) AS id_min, MAX(clima_id) AS id_max,
       STRING_AGG(CAST(clima_id AS VARCHAR), ', ' ORDER BY clima_id) AS ids
FROM sw.dim_clima
GROUP BY descripcion
HAVING COUNT(*) > 1;

-- A08 Duplicados dim_iluminacion.
SELECT 'dim_iluminacion' AS dimension, descripcion AS valor, COUNT(*) AS n_filas,
       MIN(iluminacion_id) AS id_min, MAX(iluminacion_id) AS id_max,
       STRING_AGG(CAST(iluminacion_id AS VARCHAR), ', ' ORDER BY iluminacion_id) AS ids
FROM sw.dim_iluminacion
GROUP BY descripcion
HAVING COUNT(*) > 1;

-- A09 Duplicados dim_superficie.
SELECT 'dim_superficie' AS dimension, descripcion AS valor, COUNT(*) AS n_filas,
       MIN(superficie_id) AS id_min, MAX(superficie_id) AS id_max,
       STRING_AGG(CAST(superficie_id AS VARCHAR), ', ' ORDER BY superficie_id) AS ids
FROM sw.dim_superficie
GROUP BY descripcion
HAVING COUNT(*) > 1;

-- A10 Duplicados dim_condicion_vial.
SELECT 'dim_condicion_vial' AS dimension, descripcion AS valor, COUNT(*) AS n_filas,
       MIN(condicion_id) AS id_min, MAX(condicion_id) AS id_max,
       STRING_AGG(CAST(condicion_id AS VARCHAR), ', ' ORDER BY condicion_id) AS ids
FROM sw.dim_condicion_vial
GROUP BY descripcion
HAVING COUNT(*) > 1;

-- A11 Duplicados dim_dispositivo_control.
SELECT 'dim_dispositivo_control' AS dimension, descripcion AS valor, COUNT(*) AS n_filas,
       MIN(control_id) AS id_min, MAX(control_id) AS id_max,
       STRING_AGG(CAST(control_id AS VARCHAR), ', ' ORDER BY control_id) AS ids
FROM sw.dim_dispositivo_control
GROUP BY descripcion
HAVING COUNT(*) > 1;

-- A12 Duplicados dim_factor_colision. Hallazgo verificado: 'unknown' x2.
SELECT 'dim_factor_colision' AS dimension, descripcion AS valor, COUNT(*) AS n_filas,
       MIN(factor_id) AS id_min, MAX(factor_id) AS id_max,
       STRING_AGG(CAST(factor_id AS VARCHAR), ', ' ORDER BY factor_id) AS ids
FROM sw.dim_factor_colision
GROUP BY descripcion
HAVING COUNT(*) > 1;

-- A13 Duplicados dim_categoria_pcf. Hallazgo verificado: 'unknown' x2.
SELECT 'dim_categoria_pcf' AS dimension, descripcion AS valor, COUNT(*) AS n_filas,
       MIN(categoria_id) AS id_min, MAX(categoria_id) AS id_max,
       STRING_AGG(CAST(categoria_id AS VARCHAR), ', ' ORDER BY categoria_id) AS ids
FROM sw.dim_categoria_pcf
GROUP BY descripcion
HAVING COUNT(*) > 1;

-- A14 Duplicados dim_fecha (PK natural fecha: solo muestra si repite).
SELECT 'dim_fecha' AS dimension, CAST(fecha AS VARCHAR) AS valor, COUNT(*) AS n_filas
FROM sw.dim_fecha
GROUP BY fecha
HAVING COUNT(*) > 1;

-- B01 Parties sin colision padre (NOT EXISTS; conteo global, sin filtro temporal).
SELECT COUNT(*) AS n_parties_sin_colision
FROM sw.parties AS p
WHERE NOT EXISTS (SELECT 1 FROM sw.collisions AS c WHERE c.case_id = p.case_id);

-- B01b Parties fuera de la cobertura del periodo (huerfanas + pre-2016/post-2021).
SELECT COUNT(*) AS n_parties_fuera_periodo
FROM sw.parties AS p
WHERE NOT EXISTS (SELECT 1 FROM sw.collisions AS c
                  WHERE c.case_id = p.case_id
                    AND c.collision_date >= '2016-01-01' AND c.collision_date < '2022-01-01');

-- B01c Muestra de parties sin colision (max 20, trazabilidad).
SELECT p.case_id, p.party_number
FROM sw.parties AS p
WHERE NOT EXISTS (SELECT 1 FROM sw.collisions AS c WHERE c.case_id = p.case_id)
LIMIT 20;

-- B02 Victims sin colision padre (NOT EXISTS; conteo global).
SELECT COUNT(*) AS n_victims_sin_colision
FROM sw.victims AS v
WHERE NOT EXISTS (SELECT 1 FROM sw.collisions AS c WHERE c.case_id = v.case_id);

-- B02b Victims fuera de la cobertura del periodo.
SELECT COUNT(*) AS n_victims_fuera_periodo
FROM sw.victims AS v
WHERE NOT EXISTS (SELECT 1 FROM sw.collisions AS c
                  WHERE c.case_id = v.case_id
                    AND c.collision_date >= '2016-01-01' AND c.collision_date < '2022-01-01');

-- B02c Muestra de victims sin colision (max 20).
SELECT v.case_id, v.party_number, v.victim_degree_of_injury
FROM sw.victims AS v
WHERE NOT EXISTS (SELECT 1 FROM sw.collisions AS c WHERE c.case_id = v.case_id)
LIMIT 20;

-- B03 Victims sin party (clave compuesta case_id + party_number), solo periodo.
-- Justifica FK compuesta o validacion previa en normalizacion.
SELECT COUNT(*) AS n_victims_sin_party
FROM sw.victims AS v
WHERE EXISTS (SELECT 1 FROM sw.collisions AS c
              WHERE c.case_id = v.case_id
                AND c.collision_date >= '2016-01-01' AND c.collision_date < '2022-01-01')
  AND NOT EXISTS (SELECT 1 FROM sw.parties AS p
                  WHERE p.case_id = v.case_id AND p.party_number = v.party_number);

-- B03b Muestra de victims sin party en el periodo (max 20).
SELECT v.case_id, v.party_number, v.victim_degree_of_injury
FROM sw.victims AS v
WHERE EXISTS (SELECT 1 FROM sw.collisions AS c
              WHERE c.case_id = v.case_id
                AND c.collision_date >= '2016-01-01' AND c.collision_date < '2022-01-01')
  AND NOT EXISTS (SELECT 1 FROM sw.parties AS p
                  WHERE p.case_id = v.case_id AND p.party_number = v.party_number)
LIMIT 20;

-- C01 Unicidad de case_id en collisions del periodo (grano candidato del fact).
SELECT COUNT(*) AS n_filas_periodo,
       COUNT(DISTINCT case_id) AS n_case_id_distintos,
       COUNT(*) - COUNT(DISTINCT case_id) AS n_case_id_repetidos
FROM sw.collisions
WHERE collision_date >= '2016-01-01' AND collision_date < '2022-01-01';

-- C02 Detalle de case_id repetidos en el periodo (max 50).
SELECT case_id, COUNT(*) AS n_veces
FROM sw.collisions
WHERE collision_date >= '2016-01-01' AND collision_date < '2022-01-01'
GROUP BY case_id
HAVING COUNT(*) > 1
ORDER BY n_veces DESC, case_id
LIMIT 50;

-- C03 Cierre: que se limpia antes de armar las listas.
SELECT 'DECISION_NORMALIZACION: DEDUPLICAR dim_factor_colision y dim_categoria_pcf (unknown x2) antes de crear FKs; case_id como PK del grano colision en el periodo; validar FK compuesta victims(case_id,party_number)->parties; ETL solo con claves cubiertas por 2016-2021.' AS decision_normalizacion;
