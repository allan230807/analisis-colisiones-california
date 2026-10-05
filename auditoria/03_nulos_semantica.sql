-- 03_nulos_semantica.sql
-- EECA-UCV, Computacion II | Auditoria SWITRS California 2016-2021
-- Que responde: que datos vienen vacios y que significa cada vacio.
-- Para el perfil de siniestros: que casillas se dejan en blanco, cuales se
-- rellenan con cero (alcohol, peaton, moto) y cuales van a "Sin clasificar".

INSTALL sqlite;
LOAD sqlite;
ATTACH 'data/raw/switrs.sqlite' AS sw (TYPE sqlite, READ_ONLY);

-- C01 Banderas collisions: total, nulos, % + REGLA T6 (una sola sentencia).
SELECT 'collisions.alcohol_involved' AS columna, COUNT(*) AS total,
       SUM(CASE WHEN alcohol_involved IS NULL THEN 1 ELSE 0 END) AS n_nulos,
       ROUND(100.0 * SUM(CASE WHEN alcohol_involved IS NULL THEN 1 ELSE 0 END) / COUNT(*), 2) AS pct_nulos,
       'REGLA T6: BOOLEAN NOT NULL; COALESCE(alcohol_involved,0); NULL=desconocido' AS regla_normalizacion
FROM sw.collisions WHERE collision_date >= '2016-01-01' AND collision_date < '2022-01-01'
UNION ALL
SELECT 'collisions.pedestrian_collision', COUNT(*),
       SUM(CASE WHEN pedestrian_collision IS NULL THEN 1 ELSE 0 END),
       ROUND(100.0 * SUM(CASE WHEN pedestrian_collision IS NULL THEN 1 ELSE 0 END) / COUNT(*), 2),
       'REGLA T6: BOOLEAN NOT NULL; COALESCE(col,0)'
FROM sw.collisions WHERE collision_date >= '2016-01-01' AND collision_date < '2022-01-01'
UNION ALL
SELECT 'collisions.bicycle_collision', COUNT(*),
       SUM(CASE WHEN bicycle_collision IS NULL THEN 1 ELSE 0 END),
       ROUND(100.0 * SUM(CASE WHEN bicycle_collision IS NULL THEN 1 ELSE 0 END) / COUNT(*), 2),
       'REGLA T6: BOOLEAN NOT NULL; COALESCE(col,0)'
FROM sw.collisions WHERE collision_date >= '2016-01-01' AND collision_date < '2022-01-01'
UNION ALL
SELECT 'collisions.motorcycle_collision', COUNT(*),
       SUM(CASE WHEN motorcycle_collision IS NULL THEN 1 ELSE 0 END),
       ROUND(100.0 * SUM(CASE WHEN motorcycle_collision IS NULL THEN 1 ELSE 0 END) / COUNT(*), 2),
       'REGLA T6: BOOLEAN NOT NULL; COALESCE(col,0)'
FROM sw.collisions WHERE collision_date >= '2016-01-01' AND collision_date < '2022-01-01'
UNION ALL
SELECT 'collisions.truck_collision', COUNT(*),
       SUM(CASE WHEN truck_collision IS NULL THEN 1 ELSE 0 END),
       ROUND(100.0 * SUM(CASE WHEN truck_collision IS NULL THEN 1 ELSE 0 END) / COUNT(*), 2),
       'REGLA T6: BOOLEAN NOT NULL; COALESCE(col,0)'
FROM sw.collisions WHERE collision_date >= '2016-01-01' AND collision_date < '2022-01-01';

-- C02 Valores distintos por bandera (justifica el COALESCE: solo se admite 0/1/NULL).
SELECT 'alcohol_involved' AS bandera, alcohol_involved AS valor, COUNT(*) AS n
FROM sw.collisions WHERE collision_date >= '2016-01-01' AND collision_date < '2022-01-01'
GROUP BY alcohol_involved
UNION ALL
SELECT 'pedestrian_collision', pedestrian_collision, COUNT(*)
FROM sw.collisions WHERE collision_date >= '2016-01-01' AND collision_date < '2022-01-01'
GROUP BY pedestrian_collision
UNION ALL
SELECT 'bicycle_collision', bicycle_collision, COUNT(*)
FROM sw.collisions WHERE collision_date >= '2016-01-01' AND collision_date < '2022-01-01'
GROUP BY bicycle_collision
UNION ALL
SELECT 'motorcycle_collision', motorcycle_collision, COUNT(*)
FROM sw.collisions WHERE collision_date >= '2016-01-01' AND collision_date < '2022-01-01'
GROUP BY motorcycle_collision
UNION ALL
SELECT 'truck_collision', truck_collision, COUNT(*)
FROM sw.collisions WHERE collision_date >= '2016-01-01' AND collision_date < '2022-01-01'
GROUP BY truck_collision;

-- C03 Coordenadas: total, nulos, % + REGLA tabla 1:0..1.
SELECT 'collisions.latitude' AS columna, COUNT(*) AS total,
       SUM(CASE WHEN latitude IS NULL THEN 1 ELSE 0 END) AS n_nulos,
       ROUND(100.0 * SUM(CASE WHEN latitude IS NULL THEN 1 ELSE 0 END) / COUNT(*), 2) AS pct_nulos,
       'REGLA T-coords: tabla 1:0..1 solo con lat+lon no nulos + bandera tiene_coordenadas en el hecho' AS regla_normalizacion
FROM sw.collisions WHERE collision_date >= '2016-01-01' AND collision_date < '2022-01-01'
UNION ALL
SELECT 'collisions.longitude', COUNT(*),
       SUM(CASE WHEN longitude IS NULL THEN 1 ELSE 0 END),
       ROUND(100.0 * SUM(CASE WHEN longitude IS NULL THEN 1 ELSE 0 END) / COUNT(*), 2),
       'REGLA T-coords: idem latitude; migrar juntas, nunca una sola'
FROM sw.collisions WHERE collision_date >= '2016-01-01' AND collision_date < '2022-01-01';

-- C04 Calidad de coordenadas no nulas (pares incompletos, ceros, fuera de CA).
SELECT COUNT(*) AS total_16_21,
       SUM(CASE WHEN latitude IS NULL AND longitude IS NULL THEN 1 ELSE 0 END) AS par_nulo,
       SUM(CASE WHEN (latitude IS NULL) <> (longitude IS NULL) THEN 1 ELSE 0 END) AS solo_una_nula,
       SUM(CASE WHEN latitude = 0.0 OR longitude = 0.0 THEN 1 ELSE 0 END) AS con_cero,
       SUM(CASE WHEN latitude IS NOT NULL AND (latitude < 32 OR latitude > 43) THEN 1 ELSE 0 END) AS lat_fuera_CA,
       SUM(CASE WHEN longitude IS NOT NULL AND (longitude < -125 OR longitude > -114) THEN 1 ELSE 0 END) AS lon_fuera_CA
FROM sw.collisions
WHERE collision_date >= '2016-01-01' AND collision_date < '2022-01-01';

-- C05 Codigos/textos collisions: total, nulos, % + REGLA dim id=0 (una sentencia).
SELECT 'collisions.weather_1' AS columna, COUNT(*) AS total,
       SUM(CASE WHEN weather_1 IS NULL THEN 1 ELSE 0 END) AS n_nulos,
       ROUND(100.0 * SUM(CASE WHEN weather_1 IS NULL THEN 1 ELSE 0 END) / COUNT(*), 2) AS pct_nulos,
       'REGLA DIM: id=0 Sin clasificar para NULL/basura; conservar codigo_original' AS regla_normalizacion
FROM sw.collisions WHERE collision_date >= '2016-01-01' AND collision_date < '2022-01-01'
UNION ALL
SELECT 'collisions.lighting', COUNT(*),
       SUM(CASE WHEN lighting IS NULL THEN 1 ELSE 0 END),
       ROUND(100.0 * SUM(CASE WHEN lighting IS NULL THEN 1 ELSE 0 END) / COUNT(*), 2),
       'REGLA DIM: id=0 Sin clasificar'
FROM sw.collisions WHERE collision_date >= '2016-01-01' AND collision_date < '2022-01-01'
UNION ALL
SELECT 'collisions.road_surface', COUNT(*),
       SUM(CASE WHEN road_surface IS NULL THEN 1 ELSE 0 END),
       ROUND(100.0 * SUM(CASE WHEN road_surface IS NULL THEN 1 ELSE 0 END) / COUNT(*), 2),
       'REGLA DIM: id=0 Sin clasificar'
FROM sw.collisions WHERE collision_date >= '2016-01-01' AND collision_date < '2022-01-01'
UNION ALL
SELECT 'collisions.road_condition_1', COUNT(*),
       SUM(CASE WHEN road_condition_1 IS NULL THEN 1 ELSE 0 END),
       ROUND(100.0 * SUM(CASE WHEN road_condition_1 IS NULL THEN 1 ELSE 0 END) / COUNT(*), 2),
       'REGLA DIM: id=0 Sin clasificar'
FROM sw.collisions WHERE collision_date >= '2016-01-01' AND collision_date < '2022-01-01'
UNION ALL
SELECT 'collisions.control_device', COUNT(*),
       SUM(CASE WHEN control_device IS NULL THEN 1 ELSE 0 END),
       ROUND(100.0 * SUM(CASE WHEN control_device IS NULL THEN 1 ELSE 0 END) / COUNT(*), 2),
       'REGLA DIM: id=0 Sin clasificar'
FROM sw.collisions WHERE collision_date >= '2016-01-01' AND collision_date < '2022-01-01'
UNION ALL
SELECT 'collisions.primary_collision_factor', COUNT(*),
       SUM(CASE WHEN primary_collision_factor IS NULL THEN 1 ELSE 0 END),
       ROUND(100.0 * SUM(CASE WHEN primary_collision_factor IS NULL THEN 1 ELSE 0 END) / COUNT(*), 2),
       'REGLA DIM: id=0 Sin clasificar'
FROM sw.collisions WHERE collision_date >= '2016-01-01' AND collision_date < '2022-01-01'
UNION ALL
SELECT 'collisions.pcf_violation_category', COUNT(*),
       SUM(CASE WHEN pcf_violation_category IS NULL THEN 1 ELSE 0 END),
       ROUND(100.0 * SUM(CASE WHEN pcf_violation_category IS NULL THEN 1 ELSE 0 END) / COUNT(*), 2),
       'REGLA DIM: id=0 Sin clasificar'
FROM sw.collisions WHERE collision_date >= '2016-01-01' AND collision_date < '2022-01-01'
UNION ALL
SELECT 'collisions.type_of_collision', COUNT(*),
       SUM(CASE WHEN type_of_collision IS NULL THEN 1 ELSE 0 END),
       ROUND(100.0 * SUM(CASE WHEN type_of_collision IS NULL THEN 1 ELSE 0 END) / COUNT(*), 2),
       'REGLA DIM: id=0 Sin clasificar'
FROM sw.collisions WHERE collision_date >= '2016-01-01' AND collision_date < '2022-01-01'
UNION ALL
SELECT 'collisions.motor_vehicle_involved_with', COUNT(*),
       SUM(CASE WHEN motor_vehicle_involved_with IS NULL THEN 1 ELSE 0 END),
       ROUND(100.0 * SUM(CASE WHEN motor_vehicle_involved_with IS NULL THEN 1 ELSE 0 END) / COUNT(*), 2),
       'REGLA DIM: id=0 Sin clasificar'
FROM sw.collisions WHERE collision_date >= '2016-01-01' AND collision_date < '2022-01-01'
UNION ALL
SELECT 'collisions.collision_severity', COUNT(*),
       SUM(CASE WHEN collision_severity IS NULL THEN 1 ELSE 0 END),
       ROUND(100.0 * SUM(CASE WHEN collision_severity IS NULL THEN 1 ELSE 0 END) / COUNT(*), 2),
       'REGLA DIM: id=0 Sin clasificar; severidad nunca se imputa'
FROM sw.collisions WHERE collision_date >= '2016-01-01' AND collision_date < '2022-01-01'
UNION ALL
SELECT 'collisions.county_location', COUNT(*),
       SUM(CASE WHEN county_location IS NULL THEN 1 ELSE 0 END),
       ROUND(100.0 * SUM(CASE WHEN county_location IS NULL THEN 1 ELSE 0 END) / COUNT(*), 2),
       'REGLA DIM: id=0 Sin clasificar; validar contra 58 condados CA'
FROM sw.collisions WHERE collision_date >= '2016-01-01' AND collision_date < '2022-01-01'
UNION ALL
SELECT 'collisions.collision_time', COUNT(*),
       SUM(CASE WHEN collision_time IS NULL THEN 1 ELSE 0 END),
       ROUND(100.0 * SUM(CASE WHEN collision_time IS NULL THEN 1 ELSE 0 END) / COUNT(*), 2),
       'REGLA T-hora: NULL se mantiene (hora desconocida); no imputar 00:00'
FROM sw.collisions WHERE collision_date >= '2016-01-01' AND collision_date < '2022-01-01'
UNION ALL
SELECT 'collisions.hit_and_run', COUNT(*),
       SUM(CASE WHEN hit_and_run IS NULL THEN 1 ELSE 0 END),
       ROUND(100.0 * SUM(CASE WHEN hit_and_run IS NULL THEN 1 ELSE 0 END) / COUNT(*), 2),
       'REGLA DIM: id=0 Sin clasificar para NULL/basura'
FROM sw.collisions WHERE collision_date >= '2016-01-01' AND collision_date < '2022-01-01';

-- C06 parties del periodo via EXISTS (una sentencia UNION ALL, sin WITH multiple).
SELECT 'parties.party_type' AS columna, COUNT(*) AS total,
       SUM(CASE WHEN p.party_type IS NULL THEN 1 ELSE 0 END) AS n_nulos,
       ROUND(100.0 * SUM(CASE WHEN p.party_type IS NULL THEN 1 ELSE 0 END) / COUNT(*), 2) AS pct_nulos,
       'REGLA DIM: id=0 Sin clasificar' AS regla_normalizacion
FROM sw.parties AS p
WHERE EXISTS (SELECT 1 FROM sw.collisions AS c WHERE c.case_id = p.case_id
              AND c.collision_date >= '2016-01-01' AND c.collision_date < '2022-01-01')
UNION ALL
SELECT 'parties.party_sex', COUNT(*),
       SUM(CASE WHEN p.party_sex IS NULL THEN 1 ELSE 0 END),
       ROUND(100.0 * SUM(CASE WHEN p.party_sex IS NULL THEN 1 ELSE 0 END) / COUNT(*), 2),
       'REGLA DIM sexo: id=0 para NULL + LOWER(TRIM()) fuera de (male,female)'
FROM sw.parties AS p
WHERE EXISTS (SELECT 1 FROM sw.collisions AS c WHERE c.case_id = p.case_id
              AND c.collision_date >= '2016-01-01' AND c.collision_date < '2022-01-01')
UNION ALL
SELECT 'parties.party_age', COUNT(*),
       SUM(CASE WHEN p.party_age IS NULL THEN 1 ELSE 0 END),
       ROUND(100.0 * SUM(CASE WHEN p.party_age IS NULL THEN 1 ELSE 0 END) / COUNT(*), 2),
       'REGLA script-04: NULL a grupo Desconocido; atipicos a cuarentena'
FROM sw.parties AS p
WHERE EXISTS (SELECT 1 FROM sw.collisions AS c WHERE c.case_id = p.case_id
              AND c.collision_date >= '2016-01-01' AND c.collision_date < '2022-01-01')
UNION ALL
SELECT 'parties.party_sobriety', COUNT(*),
       SUM(CASE WHEN p.party_sobriety IS NULL THEN 1 ELSE 0 END),
       ROUND(100.0 * SUM(CASE WHEN p.party_sobriety IS NULL THEN 1 ELSE 0 END) / COUNT(*), 2),
       'REGLA DIM: id=0 Sin clasificar'
FROM sw.parties AS p
WHERE EXISTS (SELECT 1 FROM sw.collisions AS c WHERE c.case_id = p.case_id
              AND c.collision_date >= '2016-01-01' AND c.collision_date < '2022-01-01')
UNION ALL
SELECT 'parties.direction_of_travel', COUNT(*),
       SUM(CASE WHEN p.direction_of_travel IS NULL THEN 1 ELSE 0 END),
       ROUND(100.0 * SUM(CASE WHEN p.direction_of_travel IS NULL THEN 1 ELSE 0 END) / COUNT(*), 2),
       'REGLA DIM: id=0 Sin clasificar'
FROM sw.parties AS p
WHERE EXISTS (SELECT 1 FROM sw.collisions AS c WHERE c.case_id = p.case_id
              AND c.collision_date >= '2016-01-01' AND c.collision_date < '2022-01-01')
UNION ALL
SELECT 'parties.party_race', COUNT(*),
       SUM(CASE WHEN p.party_race IS NULL THEN 1 ELSE 0 END),
       ROUND(100.0 * SUM(CASE WHEN p.party_race IS NULL THEN 1 ELSE 0 END) / COUNT(*), 2),
       'REGLA DIM: id=0 Sin clasificar'
FROM sw.parties AS p
WHERE EXISTS (SELECT 1 FROM sw.collisions AS c WHERE c.case_id = p.case_id
              AND c.collision_date >= '2016-01-01' AND c.collision_date < '2022-01-01')
UNION ALL
SELECT 'parties.statewide_vehicle_type', COUNT(*),
       SUM(CASE WHEN p.statewide_vehicle_type IS NULL THEN 1 ELSE 0 END),
       ROUND(100.0 * SUM(CASE WHEN p.statewide_vehicle_type IS NULL THEN 1 ELSE 0 END) / COUNT(*), 2),
       'REGLA DIM vehiculo: id=0 Sin clasificar'
FROM sw.parties AS p
WHERE EXISTS (SELECT 1 FROM sw.collisions AS c WHERE c.case_id = p.case_id
              AND c.collision_date >= '2016-01-01' AND c.collision_date < '2022-01-01')
UNION ALL
SELECT 'parties.vehicle_year', COUNT(*),
       SUM(CASE WHEN p.vehicle_year IS NULL THEN 1 ELSE 0 END),
       ROUND(100.0 * SUM(CASE WHEN p.vehicle_year IS NULL THEN 1 ELSE 0 END) / COUNT(*), 2),
       'REGLA script-04: rango valido 1900-2022; resto a cuarentena'
FROM sw.parties AS p
WHERE EXISTS (SELECT 1 FROM sw.collisions AS c WHERE c.case_id = p.case_id
              AND c.collision_date >= '2016-01-01' AND c.collision_date < '2022-01-01');

-- C07 victims del periodo via EXISTS (una sentencia UNION ALL).
SELECT 'victims.victim_role' AS columna, COUNT(*) AS total,
       SUM(CASE WHEN v.victim_role IS NULL THEN 1 ELSE 0 END) AS n_nulos,
       ROUND(100.0 * SUM(CASE WHEN v.victim_role IS NULL THEN 1 ELSE 0 END) / COUNT(*), 2) AS pct_nulos,
       'REGLA DIM: id=0 Sin clasificar' AS regla_normalizacion
FROM sw.victims AS v
WHERE EXISTS (SELECT 1 FROM sw.collisions AS c WHERE c.case_id = v.case_id
              AND c.collision_date >= '2016-01-01' AND c.collision_date < '2022-01-01')
UNION ALL
SELECT 'victims.victim_sex', COUNT(*),
       SUM(CASE WHEN v.victim_sex IS NULL THEN 1 ELSE 0 END),
       ROUND(100.0 * SUM(CASE WHEN v.victim_sex IS NULL THEN 1 ELSE 0 END) / COUNT(*), 2),
       'REGLA DIM sexo: id=0 para NULL + LOWER(TRIM()) fuera de (male,female)'
FROM sw.victims AS v
WHERE EXISTS (SELECT 1 FROM sw.collisions AS c WHERE c.case_id = v.case_id
              AND c.collision_date >= '2016-01-01' AND c.collision_date < '2022-01-01')
UNION ALL
SELECT 'victims.victim_age', COUNT(*),
       SUM(CASE WHEN v.victim_age IS NULL THEN 1 ELSE 0 END),
       ROUND(100.0 * SUM(CASE WHEN v.victim_age IS NULL THEN 1 ELSE 0 END) / COUNT(*), 2),
       'REGLA script-04: NULL a grupo Desconocido; atipicos a cuarentena'
FROM sw.victims AS v
WHERE EXISTS (SELECT 1 FROM sw.collisions AS c WHERE c.case_id = v.case_id
              AND c.collision_date >= '2016-01-01' AND c.collision_date < '2022-01-01')
UNION ALL
SELECT 'victims.victim_degree_of_injury', COUNT(*),
       SUM(CASE WHEN v.victim_degree_of_injury IS NULL THEN 1 ELSE 0 END),
       ROUND(100.0 * SUM(CASE WHEN v.victim_degree_of_injury IS NULL THEN 1 ELSE 0 END) / COUNT(*), 2),
       'REGLA DIM: id=0 Sin clasificar; lesion nunca se imputa'
FROM sw.victims AS v
WHERE EXISTS (SELECT 1 FROM sw.collisions AS c WHERE c.case_id = v.case_id
              AND c.collision_date >= '2016-01-01' AND c.collision_date < '2022-01-01')
UNION ALL
SELECT 'victims.victim_seating_position', COUNT(*),
       SUM(CASE WHEN v.victim_seating_position IS NULL THEN 1 ELSE 0 END),
       ROUND(100.0 * SUM(CASE WHEN v.victim_seating_position IS NULL THEN 1 ELSE 0 END) / COUNT(*), 2),
       'REGLA DIM: id=0 Sin clasificar'
FROM sw.victims AS v
WHERE EXISTS (SELECT 1 FROM sw.collisions AS c WHERE c.case_id = v.case_id
              AND c.collision_date >= '2016-01-01' AND c.collision_date < '2022-01-01')
UNION ALL
SELECT 'victims.victim_safety_equipment_1', COUNT(*),
       SUM(CASE WHEN v.victim_safety_equipment_1 IS NULL THEN 1 ELSE 0 END),
       ROUND(100.0 * SUM(CASE WHEN v.victim_safety_equipment_1 IS NULL THEN 1 ELSE 0 END) / COUNT(*), 2),
       'REGLA DIM: id=0 Sin clasificar'
FROM sw.victims AS v
WHERE EXISTS (SELECT 1 FROM sw.collisions AS c WHERE c.case_id = v.case_id
              AND c.collision_date >= '2016-01-01' AND c.collision_date < '2022-01-01')
UNION ALL
SELECT 'victims.victim_ejected', COUNT(*),
       SUM(CASE WHEN v.victim_ejected IS NULL THEN 1 ELSE 0 END),
       ROUND(100.0 * SUM(CASE WHEN v.victim_ejected IS NULL THEN 1 ELSE 0 END) / COUNT(*), 2),
       'REGLA DIM: id=0 Sin clasificar'
FROM sw.victims AS v
WHERE EXISTS (SELECT 1 FROM sw.collisions AS c WHERE c.case_id = v.case_id
              AND c.collision_date >= '2016-01-01' AND c.collision_date < '2022-01-01');

-- C09 Cierre: como se trata cada vacio en el perfil.
SELECT 'DECISION_NORMALIZACION: banderas a BOOLEAN NOT NULL con COALESCE(col,0) (T6); lat/lon a tabla 1:0..1 + tiene_coordenadas (nunca imputar coordenadas); todo codigo/texto a su dim con id=0 Sin clasificar; edades y vehicle_year a grupos con Desconocido + cuarentena de atipicos en 04; collision_time NULL se mantiene.' AS decision_normalizacion;
