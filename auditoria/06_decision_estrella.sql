-- 06_decision_estrella.sql
-- EECA-UCV, Computacion II | Auditoria SWITRS California 2016-2021
-- Que responde: que campos van a lista cerrada y cuales quedan como texto libre.
-- Para el perfil de siniestros: el plano final de 10 listas (fecha, condado,
-- severidad, entorno, via, tipo, causa, lesion, actor, vehiculo).

INSTALL sqlite;
LOAD sqlite;
ATTACH 'data/raw/switrs.sqlite' AS sw (TYPE sqlite, READ_ONLY);

-- D01 Matriz de cardinalidad exacta en el periodo + recomendacion calculada.
-- collisions: un UNION ALL por candidato (sin WITH multiple: cada rama filtra directo).
SELECT 'collision_severity' AS candidato, 'collisions' AS fuente,
       COUNT(DISTINCT collision_severity) AS cardinalidad_periodo,
       COUNT(*) - COUNT(collision_severity) AS n_nulos_periodo,
       CASE WHEN COUNT(DISTINCT collision_severity) <= 200 THEN 'DIMENSION'
            WHEN COUNT(DISTINCT collision_severity) <= 5000 THEN 'EVALUAR'
            ELSE 'DEGENERADO' END AS recomendacion_calculada
FROM sw.collisions WHERE collision_date >= '2016-01-01' AND collision_date < '2022-01-01'
UNION ALL
SELECT 'weather_1', 'collisions',
       COUNT(DISTINCT weather_1), COUNT(*) - COUNT(weather_1),
       CASE WHEN COUNT(DISTINCT weather_1) <= 200 THEN 'DIMENSION'
            WHEN COUNT(DISTINCT weather_1) <= 5000 THEN 'EVALUAR'
            ELSE 'DEGENERADO' END
FROM sw.collisions WHERE collision_date >= '2016-01-01' AND collision_date < '2022-01-01'
UNION ALL
SELECT 'lighting', 'collisions',
       COUNT(DISTINCT lighting), COUNT(*) - COUNT(lighting),
       CASE WHEN COUNT(DISTINCT lighting) <= 200 THEN 'DIMENSION'
            WHEN COUNT(DISTINCT lighting) <= 5000 THEN 'EVALUAR'
            ELSE 'DEGENERADO' END
FROM sw.collisions WHERE collision_date >= '2016-01-01' AND collision_date < '2022-01-01'
UNION ALL
SELECT 'road_surface', 'collisions',
       COUNT(DISTINCT road_surface), COUNT(*) - COUNT(road_surface),
       CASE WHEN COUNT(DISTINCT road_surface) <= 200 THEN 'DIMENSION'
            WHEN COUNT(DISTINCT road_surface) <= 5000 THEN 'EVALUAR'
            ELSE 'DEGENERADO' END
FROM sw.collisions WHERE collision_date >= '2016-01-01' AND collision_date < '2022-01-01'
UNION ALL
SELECT 'road_condition_1', 'collisions',
       COUNT(DISTINCT road_condition_1), COUNT(*) - COUNT(road_condition_1),
       CASE WHEN COUNT(DISTINCT road_condition_1) <= 200 THEN 'DIMENSION'
            WHEN COUNT(DISTINCT road_condition_1) <= 5000 THEN 'EVALUAR'
            ELSE 'DEGENERADO' END
FROM sw.collisions WHERE collision_date >= '2016-01-01' AND collision_date < '2022-01-01'
UNION ALL
SELECT 'control_device', 'collisions',
       COUNT(DISTINCT control_device), COUNT(*) - COUNT(control_device),
       CASE WHEN COUNT(DISTINCT control_device) <= 200 THEN 'DIMENSION'
            WHEN COUNT(DISTINCT control_device) <= 5000 THEN 'EVALUAR'
            ELSE 'DEGENERADO' END
FROM sw.collisions WHERE collision_date >= '2016-01-01' AND collision_date < '2022-01-01'
UNION ALL
SELECT 'primary_collision_factor', 'collisions',
       COUNT(DISTINCT primary_collision_factor), COUNT(*) - COUNT(primary_collision_factor),
       CASE WHEN COUNT(DISTINCT primary_collision_factor) <= 200 THEN 'DIMENSION'
            WHEN COUNT(DISTINCT primary_collision_factor) <= 5000 THEN 'EVALUAR'
            ELSE 'DEGENERADO' END
FROM sw.collisions WHERE collision_date >= '2016-01-01' AND collision_date < '2022-01-01'
UNION ALL
SELECT 'pcf_violation_category', 'collisions',
       COUNT(DISTINCT pcf_violation_category), COUNT(*) - COUNT(pcf_violation_category),
       CASE WHEN COUNT(DISTINCT pcf_violation_category) <= 200 THEN 'DIMENSION'
            WHEN COUNT(DISTINCT pcf_violation_category) <= 5000 THEN 'EVALUAR'
            ELSE 'DEGENERADO' END
FROM sw.collisions WHERE collision_date >= '2016-01-01' AND collision_date < '2022-01-01'
UNION ALL
SELECT 'type_of_collision', 'collisions',
       COUNT(DISTINCT type_of_collision), COUNT(*) - COUNT(type_of_collision),
       CASE WHEN COUNT(DISTINCT type_of_collision) <= 200 THEN 'DIMENSION'
            WHEN COUNT(DISTINCT type_of_collision) <= 5000 THEN 'EVALUAR'
            ELSE 'DEGENERADO' END
FROM sw.collisions WHERE collision_date >= '2016-01-01' AND collision_date < '2022-01-01'
UNION ALL
SELECT 'county_location', 'collisions',
       COUNT(DISTINCT county_location), COUNT(*) - COUNT(county_location),
       CASE WHEN COUNT(DISTINCT county_location) <= 200 THEN 'DIMENSION'
            WHEN COUNT(DISTINCT county_location) <= 5000 THEN 'EVALUAR'
            ELSE 'DEGENERADO' END
FROM sw.collisions WHERE collision_date >= '2016-01-01' AND collision_date < '2022-01-01'
UNION ALL
SELECT 'hit_and_run', 'collisions',
       COUNT(DISTINCT hit_and_run), COUNT(*) - COUNT(hit_and_run),
       CASE WHEN COUNT(DISTINCT hit_and_run) <= 200 THEN 'DIMENSION'
            WHEN COUNT(DISTINCT hit_and_run) <= 5000 THEN 'EVALUAR'
            ELSE 'DEGENERADO' END
FROM sw.collisions WHERE collision_date >= '2016-01-01' AND collision_date < '2022-01-01'
UNION ALL
SELECT 'statewide_vehicle_type_at_fault', 'collisions',
       COUNT(DISTINCT statewide_vehicle_type_at_fault),
       COUNT(*) - COUNT(statewide_vehicle_type_at_fault),
       CASE WHEN COUNT(DISTINCT statewide_vehicle_type_at_fault) <= 200 THEN 'DIMENSION'
            WHEN COUNT(DISTINCT statewide_vehicle_type_at_fault) <= 5000 THEN 'EVALUAR'
            ELSE 'DEGENERADO' END
FROM sw.collisions WHERE collision_date >= '2016-01-01' AND collision_date < '2022-01-01'
UNION ALL
SELECT 'primary_road', 'collisions',
       COUNT(DISTINCT primary_road), COUNT(*) - COUNT(primary_road),
       CASE WHEN COUNT(DISTINCT primary_road) <= 200 THEN 'DIMENSION'
            WHEN COUNT(DISTINCT primary_road) <= 5000 THEN 'EVALUAR'
            ELSE 'DEGENERADO' END
FROM sw.collisions WHERE collision_date >= '2016-01-01' AND collision_date < '2022-01-01'
UNION ALL
SELECT 'officer_id', 'collisions',
       COUNT(DISTINCT officer_id), COUNT(*) - COUNT(officer_id),
       CASE WHEN COUNT(DISTINCT officer_id) <= 200 THEN 'DIMENSION'
            WHEN COUNT(DISTINCT officer_id) <= 5000 THEN 'EVALUAR'
            ELSE 'DEGENERADO' END
FROM sw.collisions WHERE collision_date >= '2016-01-01' AND collision_date < '2022-01-01';

-- D02 Matriz parties/victims via EXISTS (una sentencia UNION ALL).
SELECT 'party_type' AS candidato, 'parties' AS fuente,
       COUNT(DISTINCT p.party_type) AS cardinalidad_periodo,
       COUNT(*) - COUNT(p.party_type) AS n_nulos_periodo,
       CASE WHEN COUNT(DISTINCT p.party_type) <= 200 THEN 'DIMENSION'
            WHEN COUNT(DISTINCT p.party_type) <= 5000 THEN 'EVALUAR'
            ELSE 'DEGENERADO' END AS recomendacion_calculada
FROM sw.parties AS p
WHERE EXISTS (SELECT 1 FROM sw.collisions AS c WHERE c.case_id = p.case_id
              AND c.collision_date >= '2016-01-01' AND c.collision_date < '2022-01-01')
UNION ALL
SELECT 'party_sobriety', 'parties',
       COUNT(DISTINCT p.party_sobriety), COUNT(*) - COUNT(p.party_sobriety),
       CASE WHEN COUNT(DISTINCT p.party_sobriety) <= 200 THEN 'DIMENSION'
            WHEN COUNT(DISTINCT p.party_sobriety) <= 5000 THEN 'EVALUAR'
            ELSE 'DEGENERADO' END
FROM sw.parties AS p
WHERE EXISTS (SELECT 1 FROM sw.collisions AS c WHERE c.case_id = p.case_id
              AND c.collision_date >= '2016-01-01' AND c.collision_date < '2022-01-01')
UNION ALL
SELECT 'statewide_vehicle_type', 'parties',
       COUNT(DISTINCT p.statewide_vehicle_type), COUNT(*) - COUNT(p.statewide_vehicle_type),
       CASE WHEN COUNT(DISTINCT p.statewide_vehicle_type) <= 200 THEN 'DIMENSION'
            WHEN COUNT(DISTINCT p.statewide_vehicle_type) <= 5000 THEN 'EVALUAR'
            ELSE 'DEGENERADO' END
FROM sw.parties AS p
WHERE EXISTS (SELECT 1 FROM sw.collisions AS c WHERE c.case_id = p.case_id
              AND c.collision_date >= '2016-01-01' AND c.collision_date < '2022-01-01')
UNION ALL
SELECT 'vehicle_make', 'parties',
       COUNT(DISTINCT p.vehicle_make), COUNT(*) - COUNT(p.vehicle_make),
       CASE WHEN COUNT(DISTINCT p.vehicle_make) <= 200 THEN 'DIMENSION'
            WHEN COUNT(DISTINCT p.vehicle_make) <= 5000 THEN 'EVALUAR'
            ELSE 'DEGENERADO' END
FROM sw.parties AS p
WHERE EXISTS (SELECT 1 FROM sw.collisions AS c WHERE c.case_id = p.case_id
              AND c.collision_date >= '2016-01-01' AND c.collision_date < '2022-01-01')
UNION ALL
SELECT 'victim_degree_of_injury', 'victims',
       COUNT(DISTINCT v.victim_degree_of_injury), COUNT(*) - COUNT(v.victim_degree_of_injury),
       CASE WHEN COUNT(DISTINCT v.victim_degree_of_injury) <= 200 THEN 'DIMENSION'
            WHEN COUNT(DISTINCT v.victim_degree_of_injury) <= 5000 THEN 'EVALUAR'
            ELSE 'DEGENERADO' END
FROM sw.victims AS v
WHERE EXISTS (SELECT 1 FROM sw.collisions AS c WHERE c.case_id = v.case_id
              AND c.collision_date >= '2016-01-01' AND c.collision_date < '2022-01-01')
UNION ALL
SELECT 'victim_sex', 'victims',
       COUNT(DISTINCT v.victim_sex), COUNT(*) - COUNT(v.victim_sex),
       CASE WHEN COUNT(DISTINCT v.victim_sex) <= 200 THEN 'DIMENSION'
            WHEN COUNT(DISTINCT v.victim_sex) <= 5000 THEN 'EVALUAR'
            ELSE 'DEGENERADO' END
FROM sw.victims AS v
WHERE EXISTS (SELECT 1 FROM sw.collisions AS c WHERE c.case_id = v.case_id
              AND c.collision_date >= '2016-01-01' AND c.collision_date < '2022-01-01');

-- D03 TOP 25 vehicle_make en el periodo: justifica DEGENERADO (texto libre).
SELECT p.vehicle_make, COUNT(*) AS n_parties
FROM sw.parties AS p
WHERE p.vehicle_make IS NOT NULL
  AND EXISTS (SELECT 1 FROM sw.collisions AS c WHERE c.case_id = p.case_id
              AND c.collision_date >= '2016-01-01' AND c.collision_date < '2022-01-01')
GROUP BY p.vehicle_make
ORDER BY n_parties DESC, p.vehicle_make
LIMIT 25;

-- D04 TOP 25 primary_road en el periodo: justifica DEGENERADO (texto libre).
SELECT primary_road, COUNT(*) AS n_colisiones
FROM sw.collisions
WHERE collision_date >= '2016-01-01' AND collision_date < '2022-01-01'
  AND primary_road IS NOT NULL
GROUP BY primary_road
ORDER BY n_colisiones DESC, primary_road
LIMIT 25;

-- D05 county_location: cardinalidad exacta en el periodo (verificado: 58).
SELECT COUNT(DISTINCT county_location) AS n_county_distintos_periodo
FROM sw.collisions
WHERE collision_date >= '2016-01-01' AND collision_date < '2022-01-01';

-- D05b Detalle de condados para poblar dim_county (orden determinista).
SELECT county_location, COUNT(*) AS n_colisiones
FROM sw.collisions
WHERE collision_date >= '2016-01-01' AND collision_date < '2022-01-01'
GROUP BY county_location
ORDER BY n_colisiones DESC, county_location;

-- D06 Flags candidatos a TINYINT en el fact (dominio 0/1 + nulos del periodo).
SELECT 'pedestrian_collision' AS flag,
       COUNT(DISTINCT pedestrian_collision) AS n_distintos,
       MIN(pedestrian_collision) AS minimo, MAX(pedestrian_collision) AS maximo,
       COUNT(*) - COUNT(pedestrian_collision) AS n_nulos,
       'TINYINT' AS decision
FROM sw.collisions WHERE collision_date >= '2016-01-01' AND collision_date < '2022-01-01'
UNION ALL
SELECT 'bicycle_collision', COUNT(DISTINCT bicycle_collision),
       MIN(bicycle_collision), MAX(bicycle_collision),
       COUNT(*) - COUNT(bicycle_collision), 'TINYINT'
FROM sw.collisions WHERE collision_date >= '2016-01-01' AND collision_date < '2022-01-01'
UNION ALL
SELECT 'motorcycle_collision', COUNT(DISTINCT motorcycle_collision),
       MIN(motorcycle_collision), MAX(motorcycle_collision),
       COUNT(*) - COUNT(motorcycle_collision), 'TINYINT'
FROM sw.collisions WHERE collision_date >= '2016-01-01' AND collision_date < '2022-01-01'
UNION ALL
SELECT 'truck_collision', COUNT(DISTINCT truck_collision),
       MIN(truck_collision), MAX(truck_collision),
       COUNT(*) - COUNT(truck_collision), 'TINYINT'
FROM sw.collisions WHERE collision_date >= '2016-01-01' AND collision_date < '2022-01-01'
UNION ALL
SELECT 'alcohol_involved', COUNT(DISTINCT alcohol_involved),
       MIN(alcohol_involved), MAX(alcohol_involved),
       COUNT(*) - COUNT(alcohol_involved), 'TINYINT'
FROM sw.collisions WHERE collision_date >= '2016-01-01' AND collision_date < '2022-01-01';

-- D07 Cobertura de coordenadas: justifica tabla geo separada 1:0..1.
SELECT COUNT(*) AS n_total,
       COUNT(latitude) AS n_con_lat,
       COUNT(longitude) AS n_con_lon,
       COUNT(*) - COUNT(latitude) AS n_sin_geo,
       'TABLA_GEO_1_0__1' AS decision
FROM sw.collisions
WHERE collision_date >= '2016-01-01' AND collision_date < '2022-01-01';

-- D08 Prueba de surrogate determinista (muestra 10 filas; orden reproducible).
SELECT case_id, collision_date,
       ROW_NUMBER() OVER (ORDER BY collision_date, case_id) AS collision_sk
FROM (SELECT DISTINCT case_id, collision_date
      FROM sw.collisions
      WHERE collision_date >= '2016-01-01' AND collision_date < '2022-01-01')
LIMIT 10;

-- D09 Lista final de decision (10 dimensiones + hechos): documenta el diseno elegido.
SELECT 'dim_fecha' AS elemento, 'DIMENSION (preexistente)' AS decision,
       'grano dia, PK natural fecha; precargar 2192 dias + flag tiene_datos' AS justificacion
UNION ALL
SELECT 'dim_county', 'DIMENSION NUEVA (58 filas)',
       'county_location con 58 distintos verificados en el periodo (D05)'
UNION ALL
SELECT 'dim_severidad', 'DIMENSION (preexistente, limpia)',
       'collision_severity de cardinalidad acotada (D01)'
UNION ALL
SELECT 'dim_entorno', 'DIMENSION (fusion clima+iluminacion)',
       'weather_1 y lighting acotados y del mismo grano del evento (D01)'
UNION ALL
SELECT 'dim_vial', 'DIMENSION (fusion superficie+condicion+control)',
       'road_surface, road_condition_1 y control_device acotados y del mismo grano (D01)'
UNION ALL
SELECT 'dim_tipo_colision', 'DIMENSION (preexistente)',
       'type_of_collision de cardinalidad acotada (D01)'
UNION ALL
SELECT 'dim_causa', 'DIMENSION (fusion factor+pcf, DEDUPLICADA)',
       'primary_collision_factor y pcf_violation_category acotados; exige dedup de unknown (05)'
UNION ALL
SELECT 'dim_grado_lesion', 'DIMENSION (preexistente, limpia)',
       'victim_degree_of_injury acotado; regla es_herido documentada en 04'
UNION ALL
SELECT 'dim_actor', 'DIMENSION (fusion sexo+grupo_edad)',
       'sexo y edad en bandas 0-17/18-25/26-35/36-50/51-65/65+ tras CUARENTENA de 998/999 (04)'
UNION ALL
SELECT 'dim_vehiculo', 'DIMENSION (tipo vehiculo preexistente)',
       'statewide_vehicle_type acotado; vehicle_make queda DEGENERADO en el fact (D02/D03)';

-- D10 Cierre: el plano final de 10 listas del perfil.
SELECT 'DECISION_NORMALIZACION: estrella de 10 dimensiones (fecha, county nueva con 58, severidad, entorno, vial, tipo_colision, causa deduplicada, grado_lesion, actor, vehiculo); flags peaton/bicicleta/moto/camion/alcohol como TINYINT en hechos; geo en tabla 1:0..1; vehicle_make, primary_road y officer_id como DEGENERADOS; surrogate entero determinista ROW_NUMBER() OVER (ORDER BY collision_date, case_id).' AS decision_normalizacion;
