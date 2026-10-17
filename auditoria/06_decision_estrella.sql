-- 06_decision_estrella.sql
-- EECA-UCV, Computacion II | Auditoria SWITRS California 2010-2019
-- Que responde: que campos van a catalogo cerrado y cuales quedan como texto libre o atributos,
-- y cual es el modelo objetivo de la Fase 2: un nucleo normalizado en 3FN (almacenamiento)
-- y una capa de vistas en estrella para Power BI (consumo). Usa la evidencia de 01-05 y 07.

INSTALL sqlite;
LOAD sqlite;
ATTACH 'data/raw/switrs.sqlite' AS sw (TYPE sqlite, READ_ONLY);

-- D01 Matriz de cardinalidad exacta en el periodo 2010-2019 + recomendacion calculada.
-- collisions: un UNION ALL por candidato (sin WITH multiple: cada rama filtra directo).
SELECT 'collision_severity' AS candidato, 'collisions' AS fuente,
       COUNT(DISTINCT collision_severity) AS cardinalidad_periodo,
       COUNT(*) - COUNT(collision_severity) AS n_nulos_periodo,
       CASE WHEN COUNT(DISTINCT collision_severity) <= 200 THEN 'DIMENSION'
            WHEN COUNT(DISTINCT collision_severity) <= 5000 THEN 'EVALUAR'
            ELSE 'DEGENERADO' END AS recomendacion_calculada
FROM sw.collisions WHERE collision_date >= '2010-01-01' AND collision_date < '2020-01-01'
UNION ALL
SELECT 'weather_1', 'collisions',
       COUNT(DISTINCT weather_1), COUNT(*) - COUNT(weather_1),
       CASE WHEN COUNT(DISTINCT weather_1) <= 200 THEN 'DIMENSION'
            WHEN COUNT(DISTINCT weather_1) <= 5000 THEN 'EVALUAR'
            ELSE 'DEGENERADO' END
FROM sw.collisions WHERE collision_date >= '2010-01-01' AND collision_date < '2020-01-01'
UNION ALL
SELECT 'lighting', 'collisions',
       COUNT(DISTINCT lighting), COUNT(*) - COUNT(lighting),
       CASE WHEN COUNT(DISTINCT lighting) <= 200 THEN 'DIMENSION'
            WHEN COUNT(DISTINCT lighting) <= 5000 THEN 'EVALUAR'
            ELSE 'DEGENERADO' END
FROM sw.collisions WHERE collision_date >= '2010-01-01' AND collision_date < '2020-01-01'
UNION ALL
SELECT 'road_surface', 'collisions',
       COUNT(DISTINCT road_surface), COUNT(*) - COUNT(road_surface),
       CASE WHEN COUNT(DISTINCT road_surface) <= 200 THEN 'DIMENSION'
            WHEN COUNT(DISTINCT road_surface) <= 5000 THEN 'EVALUAR'
            ELSE 'DEGENERADO' END
FROM sw.collisions WHERE collision_date >= '2010-01-01' AND collision_date < '2020-01-01'
UNION ALL
SELECT 'road_condition_1', 'collisions',
       COUNT(DISTINCT road_condition_1), COUNT(*) - COUNT(road_condition_1),
       CASE WHEN COUNT(DISTINCT road_condition_1) <= 200 THEN 'DIMENSION'
            WHEN COUNT(DISTINCT road_condition_1) <= 5000 THEN 'EVALUAR'
            ELSE 'DEGENERADO' END
FROM sw.collisions WHERE collision_date >= '2010-01-01' AND collision_date < '2020-01-01'
UNION ALL
SELECT 'control_device', 'collisions',
       COUNT(DISTINCT control_device), COUNT(*) - COUNT(control_device),
       CASE WHEN COUNT(DISTINCT control_device) <= 200 THEN 'DIMENSION'
            WHEN COUNT(DISTINCT control_device) <= 5000 THEN 'EVALUAR'
            ELSE 'DEGENERADO' END
FROM sw.collisions WHERE collision_date >= '2010-01-01' AND collision_date < '2020-01-01'
UNION ALL
SELECT 'primary_collision_factor', 'collisions',
       COUNT(DISTINCT primary_collision_factor), COUNT(*) - COUNT(primary_collision_factor),
       CASE WHEN COUNT(DISTINCT primary_collision_factor) <= 200 THEN 'DIMENSION'
            WHEN COUNT(DISTINCT primary_collision_factor) <= 5000 THEN 'EVALUAR'
            ELSE 'DEGENERADO' END
FROM sw.collisions WHERE collision_date >= '2010-01-01' AND collision_date < '2020-01-01'
UNION ALL
SELECT 'pcf_violation_category', 'collisions',
       COUNT(DISTINCT pcf_violation_category), COUNT(*) - COUNT(pcf_violation_category),
       CASE WHEN COUNT(DISTINCT pcf_violation_category) <= 200 THEN 'DIMENSION'
            WHEN COUNT(DISTINCT pcf_violation_category) <= 5000 THEN 'EVALUAR'
            ELSE 'DEGENERADO' END
FROM sw.collisions WHERE collision_date >= '2010-01-01' AND collision_date < '2020-01-01'
UNION ALL
SELECT 'type_of_collision', 'collisions',
       COUNT(DISTINCT type_of_collision), COUNT(*) - COUNT(type_of_collision),
       CASE WHEN COUNT(DISTINCT type_of_collision) <= 200 THEN 'DIMENSION'
            WHEN COUNT(DISTINCT type_of_collision) <= 5000 THEN 'EVALUAR'
            ELSE 'DEGENERADO' END
FROM sw.collisions WHERE collision_date >= '2010-01-01' AND collision_date < '2020-01-01'
UNION ALL
SELECT 'county_location', 'collisions',
       COUNT(DISTINCT county_location), COUNT(*) - COUNT(county_location),
       CASE WHEN COUNT(DISTINCT county_location) <= 200 THEN 'DIMENSION'
            WHEN COUNT(DISTINCT county_location) <= 5000 THEN 'EVALUAR'
            ELSE 'DEGENERADO' END
FROM sw.collisions WHERE collision_date >= '2010-01-01' AND collision_date < '2020-01-01'
UNION ALL
SELECT 'hit_and_run', 'collisions',
       COUNT(DISTINCT hit_and_run), COUNT(*) - COUNT(hit_and_run),
       CASE WHEN COUNT(DISTINCT hit_and_run) <= 200 THEN 'DIMENSION'
            WHEN COUNT(DISTINCT hit_and_run) <= 5000 THEN 'EVALUAR'
            ELSE 'DEGENERADO' END
FROM sw.collisions WHERE collision_date >= '2010-01-01' AND collision_date < '2020-01-01'
UNION ALL
SELECT 'statewide_vehicle_type_at_fault', 'collisions',
       COUNT(DISTINCT statewide_vehicle_type_at_fault),
       COUNT(*) - COUNT(statewide_vehicle_type_at_fault),
       CASE WHEN COUNT(DISTINCT statewide_vehicle_type_at_fault) <= 200 THEN 'DIMENSION'
            WHEN COUNT(DISTINCT statewide_vehicle_type_at_fault) <= 5000 THEN 'EVALUAR'
            ELSE 'DEGENERADO' END
FROM sw.collisions WHERE collision_date >= '2010-01-01' AND collision_date < '2020-01-01'
UNION ALL
SELECT 'primary_road', 'collisions',
       COUNT(DISTINCT primary_road), COUNT(*) - COUNT(primary_road),
       CASE WHEN COUNT(DISTINCT primary_road) <= 200 THEN 'DIMENSION'
            WHEN COUNT(DISTINCT primary_road) <= 5000 THEN 'EVALUAR'
            ELSE 'DEGENERADO' END
FROM sw.collisions WHERE collision_date >= '2010-01-01' AND collision_date < '2020-01-01'
UNION ALL
SELECT 'officer_id', 'collisions',
       COUNT(DISTINCT officer_id), COUNT(*) - COUNT(officer_id),
       CASE WHEN COUNT(DISTINCT officer_id) <= 200 THEN 'DIMENSION'
            WHEN COUNT(DISTINCT officer_id) <= 5000 THEN 'EVALUAR'
            ELSE 'DEGENERADO' END
FROM sw.collisions WHERE collision_date >= '2010-01-01' AND collision_date < '2020-01-01';

-- D02 Matriz parties/victims via EXISTS (incluye vehicle_year explicitamente).
SELECT 'party_type' AS candidato, 'parties' AS fuente,
       COUNT(DISTINCT p.party_type) AS cardinalidad_periodo,
       COUNT(*) - COUNT(p.party_type) AS n_nulos_periodo,
       CASE WHEN COUNT(DISTINCT p.party_type) <= 200 THEN 'DIMENSION'
            WHEN COUNT(DISTINCT p.party_type) <= 5000 THEN 'EVALUAR'
            ELSE 'DEGENERADO' END AS recomendacion_calculada
FROM sw.parties AS p
WHERE EXISTS (SELECT 1 FROM sw.collisions AS c WHERE c.case_id = p.case_id
              AND c.collision_date >= '2010-01-01' AND c.collision_date < '2020-01-01')
UNION ALL
SELECT 'party_sobriety', 'parties',
       COUNT(DISTINCT p.party_sobriety), COUNT(*) - COUNT(p.party_sobriety),
       CASE WHEN COUNT(DISTINCT p.party_sobriety) <= 200 THEN 'DIMENSION'
            WHEN COUNT(DISTINCT p.party_sobriety) <= 5000 THEN 'EVALUAR'
            ELSE 'DEGENERADO' END
FROM sw.parties AS p
WHERE EXISTS (SELECT 1 FROM sw.collisions AS c WHERE c.case_id = p.case_id
              AND c.collision_date >= '2010-01-01' AND c.collision_date < '2020-01-01')
UNION ALL
SELECT 'statewide_vehicle_type', 'parties',
       COUNT(DISTINCT p.statewide_vehicle_type), COUNT(*) - COUNT(p.statewide_vehicle_type),
       CASE WHEN COUNT(DISTINCT p.statewide_vehicle_type) <= 200 THEN 'DIMENSION'
            WHEN COUNT(DISTINCT p.statewide_vehicle_type) <= 5000 THEN 'EVALUAR'
            ELSE 'DEGENERADO' END
FROM sw.parties AS p
WHERE EXISTS (SELECT 1 FROM sw.collisions AS c WHERE c.case_id = p.case_id
              AND c.collision_date >= '2010-01-01' AND c.collision_date < '2020-01-01')
UNION ALL
SELECT 'vehicle_year', 'parties',
       COUNT(DISTINCT p.vehicle_year), COUNT(*) - COUNT(p.vehicle_year),
       'PRESERVAR_DIM_VEHICULO (OBJETIVO 4)'
FROM sw.parties AS p
WHERE EXISTS (SELECT 1 FROM sw.collisions AS c WHERE c.case_id = p.case_id
              AND c.collision_date >= '2010-01-01' AND c.collision_date < '2020-01-01')
UNION ALL
SELECT 'vehicle_make', 'parties',
       COUNT(DISTINCT p.vehicle_make), COUNT(*) - COUNT(p.vehicle_make),
       CASE WHEN COUNT(DISTINCT p.vehicle_make) <= 200 THEN 'DIMENSION'
            WHEN COUNT(DISTINCT p.vehicle_make) <= 5000 THEN 'EVALUAR'
            ELSE 'DEGENERADO' END
FROM sw.parties AS p
WHERE EXISTS (SELECT 1 FROM sw.collisions AS c WHERE c.case_id = p.case_id
              AND c.collision_date >= '2010-01-01' AND c.collision_date < '2020-01-01')
UNION ALL
SELECT 'victim_degree_of_injury', 'victims',
       COUNT(DISTINCT v.victim_degree_of_injury), COUNT(*) - COUNT(v.victim_degree_of_injury),
       CASE WHEN COUNT(DISTINCT v.victim_degree_of_injury) <= 200 THEN 'DIMENSION'
            WHEN COUNT(DISTINCT v.victim_degree_of_injury) <= 5000 THEN 'EVALUAR'
            ELSE 'DEGENERADO' END
FROM sw.victims AS v
WHERE EXISTS (SELECT 1 FROM sw.collisions AS c WHERE c.case_id = v.case_id
              AND c.collision_date >= '2010-01-01' AND c.collision_date < '2020-01-01')
UNION ALL
SELECT 'victim_sex', 'victims',
       COUNT(DISTINCT v.victim_sex), COUNT(*) - COUNT(v.victim_sex),
       CASE WHEN COUNT(DISTINCT v.victim_sex) <= 200 THEN 'DIMENSION'
            WHEN COUNT(DISTINCT v.victim_sex) <= 5000 THEN 'EVALUAR'
            ELSE 'DEGENERADO' END
FROM sw.victims AS v
WHERE EXISTS (SELECT 1 FROM sw.collisions AS c WHERE c.case_id = v.case_id
              AND c.collision_date >= '2010-01-01' AND c.collision_date < '2020-01-01');

-- D03 TOP 25 vehicle_make en el periodo: justifica DEGENERADO (alta dispersión de marcas).
SELECT p.vehicle_make, COUNT(*) AS n_parties
FROM sw.parties AS p
WHERE p.vehicle_make IS NOT NULL
  AND EXISTS (SELECT 1 FROM sw.collisions AS c WHERE c.case_id = p.case_id
              AND c.collision_date >= '2010-01-01' AND c.collision_date < '2020-01-01')
GROUP BY p.vehicle_make
ORDER BY n_parties DESC, p.vehicle_make
LIMIT 25;

-- D04 TOP 25 primary_road en el periodo: justifica DEGENERADO (texto libre).
SELECT primary_road, COUNT(*) AS n_colisiones
FROM sw.collisions
WHERE collision_date >= '2010-01-01' AND collision_date < '2020-01-01'
  AND primary_road IS NOT NULL
GROUP BY primary_road
ORDER BY n_colisiones DESC, primary_road
LIMIT 25;

-- D05 county_location: cardinalidad exacta en el periodo (58 condados de California).
SELECT COUNT(DISTINCT county_location) AS n_county_distintos_periodo
FROM sw.collisions
WHERE collision_date >= '2010-01-01' AND collision_date < '2020-01-01';

-- D05b Detalle de condados para poblar el catalogo condado (orden determinista).
SELECT county_location, COUNT(*) AS n_colisiones
FROM sw.collisions
WHERE collision_date >= '2010-01-01' AND collision_date < '2020-01-01'
GROUP BY county_location
ORDER BY n_colisiones DESC, county_location;

-- D06 Flags del hecho colision (dominio 0/1 + nulos del periodo). Las banderas de tipo
-- de colision son derivables de parties (07-N10) y no se almacenan en el nucleo 3FN.
SELECT 'pedestrian_collision' AS flag,
       COUNT(DISTINCT pedestrian_collision) AS n_distintos,
       MIN(pedestrian_collision) AS minimo, MAX(pedestrian_collision) AS maximo,
       COUNT(*) - COUNT(pedestrian_collision) AS n_nulos,
       'DERIVABLE_VISTA (07-N10)' AS decision
FROM sw.collisions WHERE collision_date >= '2010-01-01' AND collision_date < '2020-01-01'
UNION ALL
SELECT 'bicycle_collision', COUNT(DISTINCT bicycle_collision),
       MIN(bicycle_collision), MAX(bicycle_collision),
       COUNT(*) - COUNT(bicycle_collision), 'DERIVABLE_VISTA (07-N10)'
FROM sw.collisions WHERE collision_date >= '2010-01-01' AND collision_date < '2020-01-01'
UNION ALL
SELECT 'motorcycle_collision', COUNT(DISTINCT motorcycle_collision),
       MIN(motorcycle_collision), MAX(motorcycle_collision),
       COUNT(*) - COUNT(motorcycle_collision), 'DERIVABLE_VISTA (07-N10)'
FROM sw.collisions WHERE collision_date >= '2010-01-01' AND collision_date < '2020-01-01'
UNION ALL
SELECT 'truck_collision', COUNT(DISTINCT truck_collision),
       MIN(truck_collision), MAX(truck_collision),
       COUNT(*) - COUNT(truck_collision), 'DERIVABLE_VISTA (07-N10)'
FROM sw.collisions WHERE collision_date >= '2010-01-01' AND collision_date < '2020-01-01'
UNION ALL
SELECT 'alcohol_involved', COUNT(DISTINCT alcohol_involved),
       MIN(alcohol_involved), MAX(alcohol_involved),
       COUNT(*) - COUNT(alcohol_involved), 'BOOLEAN_NULL_SEMANTICO (TRUE o NULL, nunca FALSE)'
FROM sw.collisions WHERE collision_date >= '2010-01-01' AND collision_date < '2020-01-01';

-- D07 Cobertura de coordenadas: justifica tabla geo separada 1:0..1.
SELECT COUNT(*) AS n_total,
       COUNT(latitude) AS n_con_lat,
       COUNT(longitude) AS n_con_lon,
       COUNT(*) - COUNT(latitude) AS n_sin_geo,
       'TABLA_GEO_1_0__1' AS decision
FROM sw.collisions
WHERE collision_date >= '2010-01-01' AND collision_date < '2020-01-01';

-- D08 Prueba de surrogate determinista (muestra 10 filas; orden reproducible). Como case_id
-- es numerico (07-N01) se usa directamente como PK INTEGER; el surrogate solo seria
-- necesario si la fuente cambiara de formato.
SELECT case_id, collision_date,
       ROW_NUMBER() OVER (ORDER BY collision_date, case_id) AS collision_sk
FROM (SELECT DISTINCT case_id, collision_date
      FROM sw.collisions
      WHERE collision_date >= '2010-01-01' AND collision_date < '2020-01-01')
LIMIT 10;

-- D09 Modelo objetivo de la Fase 2.
-- Nucleo 3FN: cada atributo depende solo de la clave de su tabla; nada derivable se almacena.
-- Capa estrella: vistas sobre el nucleo para Power BI (no son tablas fisicas).
SELECT 'colision' AS elemento, 'NUCLEO 3FN (4.368.293 filas)' AS decision,
       'PK case_id INTEGER; fecha DATE; hora TIME NULL; FK ubicacion y catalogos de entorno, via, causa, tipo; banderas propias BOOLEAN (intersection, tow_away, state_highway_indicator, special_condition, alcohol_involved con NULL semantico); detalle nulable (jurisdiction, weather_2, road_condition_2, pcf_violation, pcf_violation_subsection): en almacenamiento columnar los nulos dispersos casi no ocupan espacio' AS justificacion
UNION ALL
SELECT 'colision_geo', 'NUCLEO 3FN 1:0..1 (2.159.739 filas)',
       'latitude/longitude solo con par completo dentro de CA (04-D1, 07)'
UNION ALL
SELECT 'colision_carretera', 'NUCLEO 3FN 1:0..1 (904.581 filas)',
       'bloque Caltrans (caltrans_county, caltrans_district, state_route, postmile_prefix, postmile, location_type, side_of_highway, ramp_intersection) nulo en bloque en 79,29% (07-N12)'
UNION ALL
SELECT 'parte', 'NUCLEO 3FN (8.688.142 filas)',
       'PK (case_id, party_number); FK colision; tipo_parte, at_fault, sexo, edad UTINYINT, sobriedad, droga, movimiento, tipo_vehiculo, vehicle_year USMALLINT (Objetivo 4), vehicle_make texto, raza; detalle nulable (direction_of_travel, equipo_seguridad_1/2, financial_responsibility, cellphone_in_use, cellphone_use_type, hazardous_materials, school_bus_related, oaf_violation_category/section/suffix, other_associate_factor_1/2, chp_vehicle_type_towing/towed)'
UNION ALL
SELECT 'victima', 'NUCLEO 3FN (4.280.801 filas)',
       'PK (case_id, numero_parte, numero_victima) (05-A06); FK parte; rol, sexo, edad, lesion, asiento, equipo, eyeccion'
UNION ALL
SELECT 'ubicacion', 'CATALOGO 3FN (542 filas)',
       'county_city_location -> condado y poblacion (dependencia transitiva, 07-N04/N05)'
UNION ALL
SELECT 'condado / poblacion', 'CATALOGOS (58 / 8 filas + id 0)',
       'county_location y population extraidos de ubicacion'
UNION ALL
SELECT 'catalogos de codigos', 'CATALOGOS con id=0 Sin clasificar',
       'clima, iluminacion, superficie, condicion_via, dispositivo_control, tipo_colision, implicado_con, factor_primario, categoria_infraccion, fuga, accion_peaton, tipo_parte, sobriedad, droga_fisica, direccion, movimiento_previo, raza, tipo_vehiculo, rol_victima, asiento, eyeccion, sexo, equipo_seguridad'
UNION ALL
SELECT 'lesion', 'CATALOGO homologado KABCO',
       '8 codigos originales -> K/A/B/C/O + orden; absorbe el cambio de codificacion 2017-2018 (07-N14/N15)'
UNION ALL
SELECT 'calendario', 'CATALOGO generado (3.652 filas)',
       'calendario 2010-2019 completo (anio, mes, dia_semana, fin_de_semana)'
UNION ALL
SELECT 'vw_hecho_colision', 'VISTA ESTRELLA',
       'severidad derivada (lesion maxima, 07-N08), conteos K/A/B/C, partes, banderas peaton/ciclista/moto/camion, datos del culpable (edad del conductor culpable para el Objetivo 2), tiene_coordenadas'
UNION ALL
SELECT 'vw_hecho_parte / vw_hecho_victima', 'VISTAS ESTRELLA',
       'grano parte (Objetivos 2 y 4: edad en bandas 0-17/18-25/26-35/36-50/51-64/65+/Desconocida, edad_vehiculo) y grano victima (lesion KABCO, edad_vehiculo)'
UNION ALL
SELECT 'columnas derivables', 'NO SE ALMACENAN',
       'killed_victims, injured_victims, severe_injury_count, other_visible_injury_count, complaint_of_pain_injury_count, pedestrian/bicyclist/motorcyclist_killed/injured_count, party_count, collision_severity, statewide/chp_vehicle_type_at_fault, pedestrian/bicycle/motorcycle/truck_collision, party_number_killed/injured (07-N06 a N10)'
UNION ALL
SELECT 'columnas sin informacion', 'NO SE MIGRAN',
       'not_private_property (constante), pcf_violation_code (99,99% nulo), oaf_violation_code (100% nulo), route_suffix (99,96% nulo), parties.id, victims.id, tabla case_ids'
UNION ALL
SELECT 'columnas fuera de los objetivos', 'NO SE MIGRAN (recuperables desde la fuente por case_id)',
       'administrativas y de texto libre: officer_id, reporting_district, beat_type, beat_number, chp_shift, chp_beat_type, chp_beat_class, city_division_lapd, chp_road_type, primary_road, secondary_road, distance, direction, primary_ramp, secondary_ramp, process_date';

-- D10 Cierre metodologico: modelo objetivo de la Fase 2.
SELECT 'DECISION_NORMALIZACION: nucleo 3FN de 5 tablas (colision, colision_geo, colision_carretera, parte, victima) + catalogo ubicacion y catalogos de codigos con id=0; ninguna columna derivable se almacena (se recalcula en vistas); case_id INTEGER, fechas DATE/TIME, ids de catalogo UTINYINT/USMALLINT, Parquet ZSTD particionado por anio; la estrella para Power BI son vistas (vw_hecho_colision, vw_hecho_parte, vw_hecho_victima) sobre el nucleo; vehicle_year preservado para el Objetivo 4 (edad_vehiculo en las vistas); implementado en base_de_datos/ (Fase 2).' AS decision_normalizacion;
