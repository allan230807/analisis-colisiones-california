-- 04_fanout_rangos.sql
-- EECA-UCV, Computacion II | Auditoria SWITRS California 2010-2019
-- Que responde: si los totales cuadran y que numeros raros hay (codigos centinela
-- 998/999 en victim_age, edades > 110, vehicle_year fuera de 1900-2020, coordenadas incompletas).
-- Para el perfil de siniestros: que cifras son de fiar y cuales se apartan
-- antes de armar los perfiles de edad, vehiculo y gravedad.

INSTALL sqlite;
LOAD sqlite;
ATTACH 'data/raw/switrs.sqlite' AS sw (TYPE sqlite, READ_ONLY);

-- Control 0. Denominador comun + unicidad de case_id en el periodo.
SELECT COUNT(*) AS n_colisiones_periodo,
       COUNT(DISTINCT case_id) AS n_case_id_distintos,
       COUNT(*) - COUNT(DISTINCT case_id) AS n_case_id_repetidos,
       'DOCUMENTAR' AS decision_normalizacion
FROM sw.collisions
WHERE collision_date >= '2010-01-01' AND collision_date < '2020-01-01';

-- Control A. SUM(party_count) declarado vs filas reales en parties (escalares independientes).
SELECT suma_party_count_declarado,
       filas_parties_reales,
       suma_party_count_declarado - filas_parties_reales AS diferencia,
       CASE WHEN suma_party_count_declarado = filas_parties_reales
            THEN 'CUADRA: party_count es consistente'
            ELSE 'DIFERENCIA: derivar el conteo desde parties, no sumar party_count'
       END AS veredicto,
       'DOCUMENTAR' AS decision_normalizacion
FROM (
    SELECT (SELECT COALESCE(SUM(party_count), 0) FROM sw.collisions
            WHERE collision_date >= '2010-01-01' AND collision_date < '2020-01-01') AS suma_party_count_declarado,
           (SELECT COUNT(*) FROM sw.parties AS p
            WHERE EXISTS (SELECT 1 FROM sw.collisions AS c WHERE c.case_id = p.case_id
                          AND c.collision_date >= '2010-01-01' AND c.collision_date < '2020-01-01')) AS filas_parties_reales
) AS control_a;

-- Control B1. SUM(killed_victims) vs victimas con grado killed (periodo).
SELECT suma_killed_declarado,
       victimas_killed_reales,
       suma_killed_declarado - victimas_killed_reales AS diferencia,
       CASE WHEN suma_killed_declarado = victimas_killed_reales THEN 'CUADRA'
            ELSE 'DIFERENCIA: el conteo del fact no sustituye el conteo por grado en victims'
       END AS veredicto,
       'DOCUMENTAR' AS decision_normalizacion
FROM (
    SELECT (SELECT COALESCE(SUM(killed_victims), 0) FROM sw.collisions
            WHERE collision_date >= '2010-01-01' AND collision_date < '2020-01-01') AS suma_killed_declarado,
           (SELECT COUNT(*) FROM sw.victims AS v
            WHERE LOWER(TRIM(v.victim_degree_of_injury)) = 'killed'
              AND EXISTS (SELECT 1 FROM sw.collisions AS c WHERE c.case_id = v.case_id
                          AND c.collision_date >= '2010-01-01' AND c.collision_date < '2020-01-01')) AS victimas_killed_reales
) AS control_b1;

-- Control B2. SUM(injured_victims) vs victimas con lesion confirmada + unknown aparte.
SELECT suma_injured_declarado,
       victimas_lesion_confirmada,
       victimas_grado_unknown,
       suma_injured_declarado - victimas_lesion_confirmada AS diferencia_bruta,
       'DOCUMENTAR' AS decision_normalizacion
FROM (
    SELECT (SELECT COALESCE(SUM(injured_victims), 0) FROM sw.collisions
            WHERE collision_date >= '2010-01-01' AND collision_date < '2020-01-01') AS suma_injured_declarado,
           (SELECT COUNT(*) FROM sw.victims AS v
            WHERE LOWER(TRIM(v.victim_degree_of_injury)) IN
                  ('complaint of pain','possible injury','other visible injury',
                   'suspected minor injury','suspected serious injury','severe injury')
              AND EXISTS (SELECT 1 FROM sw.collisions AS c WHERE c.case_id = v.case_id
                          AND c.collision_date >= '2010-01-01' AND c.collision_date < '2020-01-01')) AS victimas_lesion_confirmada,
           (SELECT COUNT(*) FROM sw.victims AS v
            WHERE LOWER(TRIM(v.victim_degree_of_injury)) = 'unknown'
              AND EXISTS (SELECT 1 FROM sw.collisions AS c WHERE c.case_id = v.case_id
                          AND c.collision_date >= '2010-01-01' AND c.collision_date < '2020-01-01')) AS victimas_grado_unknown
) AS control_b2;

-- Control C1. party_age crudo vs limpio 0-110. En 2010-2019 party_age NO usa 998/999
-- (0 casos); sus atipicos son edades reales > 110 (max 125).
SELECT MIN(p.party_age) AS min_crudo,
       MAX(p.party_age) AS max_crudo,
       AVG(p.party_age) AS avg_crudo_mentiroso,
       SUM(CASE WHEN p.party_age IS NULL THEN 1 ELSE 0 END) AS n_nulos,
       SUM(CASE WHEN p.party_age IN (998, 999) THEN 1 ELSE 0 END) AS n_codigos_998_999,
       SUM(CASE WHEN p.party_age IS NOT NULL AND (p.party_age < 0 OR p.party_age > 110) THEN 1 ELSE 0 END) AS n_fuera_rango,
       AVG(CASE WHEN p.party_age BETWEEN 0 AND 110 THEN p.party_age END) AS avg_limpio_0_110,
       MIN(CASE WHEN p.party_age BETWEEN 0 AND 110 THEN p.party_age END) AS min_limpio,
       MAX(CASE WHEN p.party_age BETWEEN 0 AND 110 THEN p.party_age END) AS max_limpio,
       'CUARENTENA' AS decision_normalizacion
FROM sw.parties AS p
WHERE EXISTS (SELECT 1 FROM sw.collisions AS c WHERE c.case_id = p.case_id
              AND c.collision_date >= '2010-01-01' AND c.collision_date < '2020-01-01');

-- Control C2. victim_age crudo vs limpio 0-110. Aqui si aparecen centinelas 998/999,
-- que quedan incluidos dentro de n_fuera_rango (no se suman aparte).
SELECT MIN(v.victim_age) AS min_crudo,
       MAX(v.victim_age) AS max_crudo,
       AVG(v.victim_age) AS avg_crudo_mentiroso,
       SUM(CASE WHEN v.victim_age IS NULL THEN 1 ELSE 0 END) AS n_nulos,
       SUM(CASE WHEN v.victim_age IN (998, 999) THEN 1 ELSE 0 END) AS n_codigos_998_999,
       SUM(CASE WHEN v.victim_age IS NOT NULL AND (v.victim_age < 0 OR v.victim_age > 110) THEN 1 ELSE 0 END) AS n_fuera_rango,
       AVG(CASE WHEN v.victim_age BETWEEN 0 AND 110 THEN v.victim_age END) AS avg_limpio_0_110,
       'CUARENTENA' AS decision_normalizacion
FROM sw.victims AS v
WHERE EXISTS (SELECT 1 FROM sw.collisions AS c WHERE c.case_id = v.case_id
              AND c.collision_date >= '2010-01-01' AND c.collision_date < '2020-01-01');

-- Control C3. vehicle_year crudo vs limpio 1900-2020: expone atipicos fuera de decada.
SELECT MIN(p.vehicle_year) AS min_crudo,
       MAX(p.vehicle_year) AS max_crudo,
       AVG(p.vehicle_year) AS avg_crudo_mentiroso,
       SUM(CASE WHEN p.vehicle_year IS NULL THEN 1 ELSE 0 END) AS n_nulos,
       SUM(CASE WHEN p.vehicle_year IS NOT NULL AND (p.vehicle_year < 1900 OR p.vehicle_year > 2020) THEN 1 ELSE 0 END) AS n_fuera_rango,
       AVG(CASE WHEN p.vehicle_year BETWEEN 1900 AND 2020 THEN p.vehicle_year END) AS avg_limpio,
       MIN(CASE WHEN p.vehicle_year BETWEEN 1900 AND 2020 THEN p.vehicle_year END) AS min_limpio,
       MAX(CASE WHEN p.vehicle_year BETWEEN 1900 AND 2020 THEN p.vehicle_year END) AS max_limpio,
       'CUARENTENA' AS decision_normalizacion
FROM sw.parties AS p
WHERE EXISTS (SELECT 1 FROM sw.collisions AS c WHERE c.case_id = p.case_id
              AND c.collision_date >= '2010-01-01' AND c.collision_date < '2020-01-01');

-- Control D1. Coordenadas: par completo dentro/fuera del bbox California
-- (lat 32-43, lon -125 a -114), par incompleto (solo una coordenada) y par nulo.
-- Las categorias son excluyentes y suman n_total. Un par incompleto no es un
-- punto valido: va al grupo sin coordenadas, no a la tabla geo.
SELECT COUNT(*) AS n_total,
       SUM(CASE WHEN latitude IS NOT NULL AND longitude IS NOT NULL
                 AND latitude BETWEEN 32 AND 43 AND longitude BETWEEN -125 AND -114 THEN 1 ELSE 0 END) AS n_par_dentro_bbox,
       SUM(CASE WHEN latitude IS NOT NULL AND longitude IS NOT NULL
                 AND NOT (latitude BETWEEN 32 AND 43 AND longitude BETWEEN -125 AND -114) THEN 1 ELSE 0 END) AS n_par_fuera_bbox,
       SUM(CASE WHEN (latitude IS NULL) <> (longitude IS NULL) THEN 1 ELSE 0 END) AS n_par_incompleto,
       SUM(CASE WHEN latitude IS NULL AND longitude IS NULL THEN 1 ELSE 0 END) AS n_par_nulo,
       'CUARENTENA' AS decision_normalizacion
FROM sw.collisions
WHERE collision_date >= '2010-01-01' AND collision_date < '2020-01-01';

-- Control D2. Rangos crudos de lat/lon para documentar el ruido.
SELECT MIN(latitude) AS min_lat, MAX(latitude) AS max_lat,
       MIN(longitude) AS min_lon, MAX(longitude) AS max_lon,
       'CUARENTENA' AS decision_normalizacion
FROM sw.collisions
WHERE collision_date >= '2010-01-01' AND collision_date < '2020-01-01';

-- Control E1. party_count sospechoso (en 2010-2019: MIN 0, MAX 38).
SELECT SUM(CASE WHEN party_count = 0 THEN 1 ELSE 0 END) AS n_party_count_cero,
       SUM(CASE WHEN party_count > 20 THEN 1 ELSE 0 END) AS n_party_count_mayor_20,
       MIN(party_count) AS min_party_count,
       MAX(party_count) AS max_party_count,
       'CUARENTENA' AS decision_normalizacion
FROM sw.collisions
WHERE collision_date >= '2010-01-01' AND collision_date < '2020-01-01';

-- Control E2. Distribucion completa de party_count con bandera de sospecha.
SELECT party_count, COUNT(*) AS n_colisiones,
       CASE WHEN party_count = 0 OR party_count > 20 THEN 'SOSPECHOSO' ELSE 'OK' END AS bandera,
       'CUARENTENA' AS decision_normalizacion
FROM sw.collisions
WHERE collision_date >= '2010-01-01' AND collision_date < '2020-01-01'
GROUP BY party_count
ORDER BY party_count;

-- Control F. Cierre: que cifras entran al perfil y cuales se apartan.
SELECT 'DECISION_NORMALIZACION: party_count, killed_victims, injured_victims y los demas conteos de collisions NO se almacenan (derivables, 07-N06): toda medida se calcula con COUNT sobre parte y victima, eliminando el riesgo de fan-out; edades (0-110) y vehicle_year (1900-2020) se almacenan como UTINYINT/USMALLINT y los atipicos (998/999, >110, 2021) quedan NULL con bandera de cuarentena, sin eliminar la fila (el valor crudo permanece en la fuente); geo 1:0..1 solo con par completo dentro del bbox CA (lat 32-43, lon -125 a -114).' AS decision_normalizacion;
