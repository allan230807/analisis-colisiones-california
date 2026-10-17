-- 07_dependencias_tipos.sql
-- EECA-UCV, Computacion II | Auditoria SWITRS California 2010-2019
-- Que responde: que columnas son derivables de otras tablas (no se almacenan en 3FN),
-- que dependencias funcionales obligan a separar catalogos, que bloques de columnas son
-- dispersos (subtipos 1:0..1), como homologar la lesion de victimas (KABCO) y que tipo
-- fisico minimo admite cada campo. Es la evidencia directa del diseno de la Fase 2.
--
-- Optimizacion: el periodo se materializa UNA vez en tablas TEMP de DuckDB (memoria/spill,
-- nunca en la fuente). Evita re-escanear el SQLite de ~9,9 GB en cada consulta.

INSTALL sqlite;
LOAD sqlite;
ATTACH 'data/raw/switrs.sqlite' AS sw (TYPE sqlite, READ_ONLY);

CREATE TEMP TABLE c10 AS
SELECT * FROM sw.collisions
WHERE collision_date >= '2010-01-01' AND collision_date < '2020-01-01';

CREATE TEMP TABLE p10 AS
SELECT * FROM sw.parties WHERE case_id IN (SELECT case_id FROM c10);

CREATE TEMP TABLE v10 AS
SELECT * FROM sw.victims WHERE case_id IN (SELECT case_id FROM c10);

-- ============================================================================
-- BLOQUE N1: TIPOS FISICOS MINIMOS
-- ============================================================================

-- N01 case_id: todo numerico, sin ceros a la izquierda -> cabe en INTEGER (4 bytes)
-- en lugar de TEXT. Es la clave que se repite en parties y victims.
SELECT COUNT(*) AS n,
       SUM(CASE WHEN TRY_CAST(case_id AS BIGINT) IS NULL THEN 1 ELSE 0 END) AS no_numericos,
       SUM(CASE WHEN case_id LIKE '0%' THEN 1 ELSE 0 END) AS con_cero_izquierda,
       MIN(length(case_id)) AS long_min,
       MAX(length(case_id)) AS long_max,
       MAX(TRY_CAST(case_id AS BIGINT)) AS max_numerico,
       CASE WHEN MAX(TRY_CAST(case_id AS BIGINT)) <= 2147483647 THEN 'INTEGER' ELSE 'BIGINT' END AS tipo_propuesto
FROM c10;

-- N02 Fechas y hora: TEXT convertible a DATE/TIME sin perdida; la hora no trae segundos.
SELECT SUM(CASE WHEN TRY_CAST(collision_date AS DATE) IS NULL THEN 1 ELSE 0 END) AS fecha_invalida,
       SUM(CASE WHEN collision_time IS NOT NULL AND TRY_CAST(collision_time AS TIME) IS NULL THEN 1 ELSE 0 END) AS hora_invalida,
       SUM(CASE WHEN substr(collision_time, 7, 2) <> '00' THEN 1 ELSE 0 END) AS hora_con_segundos,
       SUM(CASE WHEN TRY_CAST(process_date AS DATE) < TRY_CAST(collision_date AS DATE) THEN 1 ELSE 0 END) AS proceso_antes_de_colision
FROM c10;

-- N03 Rangos de enteros pequenos (seleccion de UTINYINT / USMALLINT).
SELECT 'parties.party_number' AS campo, MIN(party_number) AS minimo, MAX(party_number) AS maximo FROM p10
UNION ALL SELECT 'parties.party_age', MIN(party_age), MAX(party_age) FROM p10
UNION ALL SELECT 'parties.vehicle_year', MIN(vehicle_year), MAX(vehicle_year) FROM p10
UNION ALL SELECT 'victims.party_number', MIN(party_number), MAX(party_number) FROM v10
UNION ALL SELECT 'victims.victim_age', MIN(victim_age), MAX(victim_age) FROM v10;

-- ============================================================================
-- BLOQUE N2: DEPENDENCIAS FUNCIONALES (3FN)
-- violaciones = valores del determinante asociados a mas de un valor dependiente.
-- 0 violaciones -> el dependiente sale a un catalogo propio (dependencia transitiva).
-- ============================================================================

-- N04 Dependencias candidatas en collisions.
SELECT 'county_city_location -> county_location' AS dependencia, COUNT(*) AS violaciones
FROM (SELECT county_city_location FROM c10 GROUP BY 1 HAVING COUNT(DISTINCT county_location) > 1)
UNION ALL
SELECT 'county_city_location -> population', COUNT(*)
FROM (SELECT county_city_location FROM c10 GROUP BY 1 HAVING COUNT(DISTINCT population) > 1)
UNION ALL
SELECT 'jurisdiction -> county_location', COUNT(*)
FROM (SELECT jurisdiction FROM c10 GROUP BY 1 HAVING COUNT(DISTINCT county_location) > 1)
UNION ALL
SELECT 'pcf_violation -> pcf_violation_category', COUNT(*)
FROM (SELECT pcf_violation FROM c10 WHERE pcf_violation IS NOT NULL GROUP BY 1 HAVING COUNT(DISTINCT pcf_violation_category) > 1)
UNION ALL
SELECT 'pcf_violation_category -> primary_collision_factor', COUNT(*)
FROM (SELECT pcf_violation_category FROM c10 GROUP BY 1 HAVING COUNT(DISTINCT primary_collision_factor) > 1)
UNION ALL
SELECT 'caltrans_county -> county_location', COUNT(*)
FROM (SELECT caltrans_county FROM c10 GROUP BY 1 HAVING COUNT(DISTINCT county_location) > 1);

-- N05 Cardinalidad del catalogo de ubicacion (county_city_location, county, population).
SELECT COUNT(DISTINCT county_city_location) AS n_county_city_location,
       COUNT(DISTINCT county_location) AS n_condados,
       COUNT(DISTINCT population) AS n_categorias_poblacion,
       (SELECT COUNT(*) FROM (SELECT DISTINCT county_city_location, county_location, population FROM c10)) AS n_combinaciones
FROM c10;

-- ============================================================================
-- BLOQUE N3: COLUMNAS DERIVABLES (no se almacenan; se calculan en vistas)
-- diferencia = colisiones/partes donde el valor declarado no coincide con el
-- recalculado desde la tabla de detalle.
-- ============================================================================

-- N06 Conteos de collisions vs victims/parties. Peaton se define por victim_role;
-- ciclista y motociclista por la parte a la que pertenece la victima (party_type =
-- 'bicyclist'; statewide_vehicle_type moto o moped), que es la regla con la que cuadra SWITRS.
WITH vk AS (
    SELECT v.case_id,
           COUNT(*) FILTER (WHERE v.victim_degree_of_injury = 'killed') AS k,
           COUNT(*) FILTER (WHERE v.victim_degree_of_injury IN ('severe injury', 'suspected serious injury')) AS a,
           COUNT(*) FILTER (WHERE v.victim_degree_of_injury IN ('other visible injury', 'suspected minor injury')) AS b,
           COUNT(*) FILTER (WHERE v.victim_degree_of_injury IN ('complaint of pain', 'possible injury')) AS cc,
           COUNT(*) FILTER (WHERE v.victim_role = 'pedestrian' AND v.victim_degree_of_injury = 'killed') AS ped_k,
           COUNT(*) FILTER (WHERE v.victim_role = 'pedestrian' AND v.victim_degree_of_injury NOT IN ('killed', 'no injury')) AS ped_i,
           COUNT(*) FILTER (WHERE p.party_type = 'bicyclist' AND v.victim_degree_of_injury = 'killed') AS bic_k,
           COUNT(*) FILTER (WHERE p.party_type = 'bicyclist' AND v.victim_degree_of_injury NOT IN ('killed', 'no injury')) AS bic_i,
           COUNT(*) FILTER (WHERE p.statewide_vehicle_type IN ('motorcycle or scooter', 'moped') AND v.victim_degree_of_injury = 'killed') AS moto_k,
           COUNT(*) FILTER (WHERE p.statewide_vehicle_type IN ('motorcycle or scooter', 'moped') AND v.victim_degree_of_injury NOT IN ('killed', 'no injury')) AS moto_i
    FROM v10 AS v
    LEFT JOIN p10 AS p USING (case_id, party_number)
    GROUP BY v.case_id
),
pc AS (SELECT case_id, COUNT(*) AS np FROM p10 GROUP BY case_id)
SELECT COUNT(*) AS colisiones,
       SUM(CASE WHEN c.killed_victims <> COALESCE(k, 0) THEN 1 ELSE 0 END) AS dif_killed_victims,
       SUM(CASE WHEN c.injured_victims <> COALESCE(a, 0) + COALESCE(b, 0) + COALESCE(cc, 0) THEN 1 ELSE 0 END) AS dif_injured_victims,
       SUM(CASE WHEN c.severe_injury_count <> COALESCE(a, 0) THEN 1 ELSE 0 END) AS dif_severe_injury_count,
       SUM(CASE WHEN c.other_visible_injury_count <> COALESCE(b, 0) THEN 1 ELSE 0 END) AS dif_other_visible_injury_count,
       SUM(CASE WHEN c.complaint_of_pain_injury_count <> COALESCE(cc, 0) THEN 1 ELSE 0 END) AS dif_complaint_of_pain_count,
       SUM(CASE WHEN c.pedestrian_killed_count <> COALESCE(ped_k, 0) THEN 1 ELSE 0 END) AS dif_pedestrian_killed,
       SUM(CASE WHEN c.pedestrian_injured_count <> COALESCE(ped_i, 0) THEN 1 ELSE 0 END) AS dif_pedestrian_injured,
       SUM(CASE WHEN c.bicyclist_killed_count <> COALESCE(bic_k, 0) THEN 1 ELSE 0 END) AS dif_bicyclist_killed,
       SUM(CASE WHEN c.bicyclist_injured_count <> COALESCE(bic_i, 0) THEN 1 ELSE 0 END) AS dif_bicyclist_injured,
       SUM(CASE WHEN c.motorcyclist_killed_count <> COALESCE(moto_k, 0) THEN 1 ELSE 0 END) AS dif_motorcyclist_killed,
       SUM(CASE WHEN c.motorcyclist_injured_count <> COALESCE(moto_i, 0) THEN 1 ELSE 0 END) AS dif_motorcyclist_injured,
       SUM(CASE WHEN c.party_count <> COALESCE(np, 0) THEN 1 ELSE 0 END) AS dif_party_count
FROM c10 AS c
LEFT JOIN vk USING (case_id)
LEFT JOIN pc USING (case_id);

-- N07 parties.party_number_killed / party_number_injured vs victims de esa parte.
WITH vp AS (
    SELECT case_id, party_number,
           COUNT(*) FILTER (WHERE victim_degree_of_injury = 'killed') AS k,
           COUNT(*) FILTER (WHERE victim_degree_of_injury NOT IN ('killed', 'no injury')) AS i
    FROM v10 GROUP BY case_id, party_number
)
SELECT COUNT(*) AS partes,
       SUM(CASE WHEN p.party_number_killed <> COALESCE(vp.k, 0) THEN 1 ELSE 0 END) AS dif_party_number_killed,
       SUM(CASE WHEN p.party_number_injured <> COALESCE(vp.i, 0) THEN 1 ELSE 0 END) AS dif_party_number_injured
FROM p10 AS p
LEFT JOIN vp USING (case_id, party_number);

-- N08 collision_severity vs lesion maxima de sus victimas (escala KABCO 4..0).
-- Si cada severidad corresponde a un unico nivel, collision_severity es derivable.
WITH vs AS (
    SELECT case_id,
           MAX(CASE victim_degree_of_injury
                   WHEN 'killed' THEN 4
                   WHEN 'severe injury' THEN 3 WHEN 'suspected serious injury' THEN 3
                   WHEN 'other visible injury' THEN 2 WHEN 'suspected minor injury' THEN 2
                   WHEN 'complaint of pain' THEN 1 WHEN 'possible injury' THEN 1
                   ELSE 0 END) AS nivel_max
    FROM v10 GROUP BY case_id
)
SELECT c.collision_severity, COALESCE(vs.nivel_max, 0) AS nivel_kabco_max_victimas, COUNT(*) AS n_colisiones
FROM c10 AS c LEFT JOIN vs USING (case_id)
GROUP BY ALL
ORDER BY nivel_kabco_max_victimas DESC, n_colisiones DESC;

-- N09 Atributos "del culpable" repetidos en collisions vs la parte con at_fault = 1.
WITH f AS (
    SELECT case_id, statewide_vehicle_type, chp_vehicle_type_towing
    FROM p10 WHERE at_fault = 1
)
SELECT COUNT(*) AS colisiones_con_culpable,
       SUM(CASE WHEN c.statewide_vehicle_type_at_fault IS DISTINCT FROM f.statewide_vehicle_type THEN 1 ELSE 0 END) AS dif_statewide_vehicle_type_at_fault,
       SUM(CASE WHEN c.chp_vehicle_type_at_fault IS DISTINCT FROM f.chp_vehicle_type_towing THEN 1 ELSE 0 END) AS dif_chp_vehicle_type_at_fault
FROM c10 AS c JOIN f USING (case_id);

-- N10 Banderas de tipo de colision vs tipos de parte / vehiculo presentes.
WITH pt AS (
    SELECT case_id,
           BOOL_OR(party_type = 'pedestrian') AS hay_peaton,
           BOOL_OR(party_type = 'bicyclist') AS hay_ciclista,
           BOOL_OR(statewide_vehicle_type IN ('motorcycle or scooter', 'moped')) AS hay_moto,
           BOOL_OR(statewide_vehicle_type IN ('truck or truck tractor', 'truck or truck tractor with trailer')) AS hay_camion
    FROM p10 GROUP BY case_id
)
SELECT SUM(CASE WHEN (c.pedestrian_collision = 1) <> COALESCE(hay_peaton, FALSE) THEN 1 ELSE 0 END) AS dif_pedestrian_collision,
       SUM(CASE WHEN (c.bicycle_collision = 1) <> COALESCE(hay_ciclista, FALSE) THEN 1 ELSE 0 END) AS dif_bicycle_collision,
       SUM(CASE WHEN (c.motorcycle_collision = 1) <> COALESCE(hay_moto, FALSE) THEN 1 ELSE 0 END) AS dif_motorcycle_collision,
       SUM(CASE WHEN (c.truck_collision = 1) <> COALESCE(hay_camion, FALSE) THEN 1 ELSE 0 END) AS dif_truck_collision
FROM c10 AS c LEFT JOIN pt USING (case_id);

-- ============================================================================
-- BLOQUE N4: COLUMNAS DISPERSAS, CONSTANTES Y BLOQUES 1:0..1
-- ============================================================================

-- N11 Columnas casi vacias (> 95% nulos) o constantes (<= 1 valor distinto).
SELECT 'collisions' AS tabla, column_name, CAST(null_percentage AS DOUBLE) AS pct_nulos, approx_unique
FROM (SUMMARIZE c10)
WHERE CAST(null_percentage AS DOUBLE) > 95 OR approx_unique <= 1
UNION ALL
SELECT 'parties', column_name, CAST(null_percentage AS DOUBLE), approx_unique
FROM (SUMMARIZE p10)
WHERE CAST(null_percentage AS DOUBLE) > 95 OR approx_unique <= 1
UNION ALL
SELECT 'victims', column_name, CAST(null_percentage AS DOUBLE), approx_unique
FROM (SUMMARIZE v10)
WHERE CAST(null_percentage AS DOUBLE) > 95 OR approx_unique <= 1
ORDER BY tabla, pct_nulos DESC;

-- N12 Bloque Caltrans (carretera estatal): sus 6 columnas son nulas a la vez -> subtipo 1:0..1.
SELECT COUNT(*) AS colisiones,
       COUNT(*) FILTER (WHERE caltrans_county IS NOT NULL) AS con_bloque_caltrans,
       COUNT(*) FILTER (WHERE caltrans_county IS NULL AND caltrans_district IS NULL AND state_route IS NULL
                          AND postmile IS NULL AND location_type IS NULL AND side_of_highway IS NULL) AS bloque_totalmente_nulo,
       COUNT(*) FILTER (WHERE caltrans_county IS NULL) - COUNT(*) FILTER (WHERE caltrans_county IS NULL AND caltrans_district IS NULL AND state_route IS NULL
                          AND postmile IS NULL AND location_type IS NULL AND side_of_highway IS NULL) AS bloque_parcial
FROM c10;

-- N13 Codigos basura (valores fuera del dominio textual de cada catalogo) -> id = 0.
SELECT 'collision_severity' AS columna, collision_severity AS valor, COUNT(*) AS n FROM c10 WHERE collision_severity = 'N' GROUP BY ALL
UNION ALL SELECT 'primary_collision_factor', primary_collision_factor, COUNT(*) FROM c10 WHERE primary_collision_factor = '2' GROUP BY ALL
UNION ALL SELECT 'direction', direction, COUNT(*) FROM c10 WHERE direction NOT IN ('north', 'south', 'east', 'west') GROUP BY ALL
UNION ALL SELECT 'chp_road_type', chp_road_type, COUNT(*) FROM c10 WHERE chp_road_type = 'A' GROUP BY ALL
UNION ALL SELECT 'statewide_vehicle_type', statewide_vehicle_type, COUNT(*) FROM p10 WHERE statewide_vehicle_type = '04' GROUP BY ALL
UNION ALL SELECT 'victim_sex', victim_sex, COUNT(*) FROM v10 WHERE victim_sex NOT IN ('male', 'female', 'X') GROUP BY ALL
ORDER BY columna;

-- ============================================================================
-- BLOQUE N5: HOMOLOGACION DE LESION (KABCO) Y RUPTURA DE COBERTURA 2017
-- SWITRS cambio la codificacion de victim_degree_of_injury en 2017-2018
-- (severe -> suspected serious, other visible -> suspected minor, complaint of
-- pain -> possible injury) y desde 2017 reporta muchas menos victimas ilesas.
-- ============================================================================

-- N14 Codigos originales por anio (muestra la transicion).
PIVOT (
    SELECT substr(c.collision_date, 1, 4) AS anio, v.victim_degree_of_injury AS grado
    FROM v10 AS v JOIN c10 AS c USING (case_id)
) ON grado USING COUNT(*) ORDER BY anio;

-- N15 Serie homologada KABCO por anio: K, A, B y C son continuas; O (ilesos) cae ~65% en 2017.
PIVOT (
    SELECT substr(c.collision_date, 1, 4) AS anio,
           CASE v.victim_degree_of_injury
               WHEN 'killed' THEN 'K'
               WHEN 'severe injury' THEN 'A' WHEN 'suspected serious injury' THEN 'A'
               WHEN 'other visible injury' THEN 'B' WHEN 'suspected minor injury' THEN 'B'
               WHEN 'complaint of pain' THEN 'C' WHEN 'possible injury' THEN 'C'
               WHEN 'no injury' THEN 'O'
               ELSE 'SIN_CLASIFICAR' END AS kabco
    FROM v10 AS v JOIN c10 AS c USING (case_id)
) ON kabco IN ('K', 'A', 'B', 'C', 'O', 'SIN_CLASIFICAR') USING COUNT(*) ORDER BY anio;

-- ============================================================================
-- BLOQUE N6: UNIDAD DE ANALISIS DE LOS OBJETIVOS 2 Y 4
-- ============================================================================

-- N16 Partes por tipo, culpables y disponibilidad de edad.
SELECT party_type, COUNT(*) AS n_partes,
       COUNT(*) FILTER (WHERE at_fault = 1) AS n_culpables,
       COUNT(*) FILTER (WHERE party_age BETWEEN 0 AND 110) AS n_edad_valida
FROM p10
GROUP BY party_type
ORDER BY n_partes DESC;

-- N17 Culpables por colision: a lo sumo 1 -> relacion colision 1:0..1 culpable.
SELECT n_culpables, COUNT(*) AS n_colisiones
FROM (
    SELECT c.case_id, COUNT(p.case_id) AS n_culpables
    FROM c10 AS c LEFT JOIN p10 AS p ON p.case_id = c.case_id AND p.at_fault = 1
    GROUP BY c.case_id
)
GROUP BY n_culpables
ORDER BY n_culpables;

-- ============================================================================
-- BLOQUE N7: SESGOS QUE CONDICIONAN EL ANALISIS (FASE 3)
-- ============================================================================

-- N19 Cobertura de coordenadas por anio: crece con el tiempo. Una serie o un mapa
-- comparativo entre anios con colision_geo mostraria un aumento administrativo.
SELECT substr(collision_date, 1, 4) AS anio,
       COUNT(*) AS colisiones,
       ROUND(100.0 * COUNT(*) FILTER (WHERE latitude BETWEEN 32 AND 43
                                       AND longitude BETWEEN -125 AND -114) / COUNT(*), 1) AS pct_con_coordenadas
FROM c10
GROUP BY anio
ORDER BY anio;

-- N20 Edad faltante del culpable segun tipo de parte y fuga: el faltante no es
-- aleatorio (el conductor que huye no fue identificado).
SELECT p.party_type, c.hit_and_run,
       COUNT(*) AS culpables,
       ROUND(100.0 * COUNT(*) FILTER (WHERE p.party_age IS NULL OR p.party_age > 110) / COUNT(*), 1) AS pct_sin_edad_valida
FROM p10 AS p
JOIN c10 AS c USING (case_id)
WHERE p.at_fault = 1
GROUP BY ALL
ORDER BY culpables DESC;

-- N21 Anio-modelo posterior al anio de la colision (modelo del anio siguiente).
-- La edad del vehiculo (anio colision - anio-modelo) da -1 y se acota a 0.
SELECT COUNT(*) FILTER (WHERE p.vehicle_year > CAST(substr(c.collision_date, 1, 4) AS INTEGER)) AS modelo_posterior,
       COUNT(*) FILTER (WHERE p.vehicle_year > CAST(substr(c.collision_date, 1, 4) AS INTEGER) + 1) AS posterior_mas_de_un_anio
FROM p10 AS p
JOIN c10 AS c USING (case_id)
WHERE p.vehicle_year BETWEEN 1900 AND 2020;

-- N22 Cierre: diseno normalizado que se desprende de este script.
SELECT 'DECISION_NORMALIZACION: case_id a INTEGER, fechas a DATE/TIME, enteros pequenos a UTINYINT/USMALLINT; catalogo ubicacion(county_city_location -> condado, poblacion) por dependencia transitiva; NO almacenar columnas derivables (killed/injured/severe/visible/pain/peaton/ciclista counts, party_count, party_number_killed/injured, collision_severity, *_vehicle_type_at_fault, banderas peaton/ciclista): se recalculan en vistas; bloque Caltrans a subtipo 1:0..1; descartar columnas constantes o >95% nulas sin uso en objetivos; lesion con catalogo homologado KABCO; ilesos (O) no comparables antes/despues de 2017.' AS decision_normalizacion;
