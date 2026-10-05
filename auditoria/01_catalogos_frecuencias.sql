-- 01_catalogos_frecuencias.sql
-- EECA-UCV, Computacion II | Auditoria SWITRS California 2016-2021
-- Que responde: que valores existen en cada campo y cuantos choques aporta cada uno.
-- Para el perfil de siniestros: de aqui salen las listas base (clima, causa,
-- severidad, edad, sexo, etc.) y que va a "Sin clasificar".

INSTALL sqlite;
LOAD sqlite;
ATTACH 'data/raw/switrs.sqlite' AS sw (TYPE sqlite, READ_ONLY);

-- S00-a Total collisions del periodo (denominador de los pct).
SELECT COUNT(*) AS n_colisiones_16_21
FROM sw.collisions
WHERE collision_date >= '2016-01-01' AND collision_date < '2022-01-01';

-- S00-b Total partes del periodo (semi-join; cada parte pega con 1 colision).
SELECT COUNT(*) AS n_partes_16_21
FROM sw.parties AS p
WHERE EXISTS (
    SELECT 1 FROM sw.collisions AS c
    WHERE c.case_id = p.case_id
      AND c.collision_date >= '2016-01-01' AND c.collision_date < '2022-01-01'
);

-- S00-c Total victimas del periodo (mismo patron semi-join).
SELECT COUNT(*) AS n_victimas_16_21
FROM sw.victims AS v
WHERE EXISTS (
    SELECT 1 FROM sw.collisions AS c
    WHERE c.case_id = v.case_id
      AND c.collision_date >= '2016-01-01' AND c.collision_date < '2022-01-01'
);

-- S01 weather_1 TOP 30 (pct sobre CTE: evita SUM(COUNT(*)) OVER () en linea).
WITH g AS (
    SELECT weather_1 AS valor, COUNT(*) AS n
    FROM sw.collisions
    WHERE collision_date >= '2016-01-01' AND collision_date < '2022-01-01'
    GROUP BY weather_1
)
SELECT valor, n, ROUND(100.0 * n / SUM(n) OVER (), 2) AS pct
FROM g ORDER BY n DESC NULLS LAST LIMIT 30;

-- S02 lighting TOP 30.
WITH g AS (
    SELECT lighting AS valor, COUNT(*) AS n
    FROM sw.collisions
    WHERE collision_date >= '2016-01-01' AND collision_date < '2022-01-01'
    GROUP BY lighting
)
SELECT valor, n, ROUND(100.0 * n / SUM(n) OVER (), 2) AS pct
FROM g ORDER BY n DESC NULLS LAST LIMIT 30;

-- S03 road_surface TOP 30.
WITH g AS (
    SELECT road_surface AS valor, COUNT(*) AS n
    FROM sw.collisions
    WHERE collision_date >= '2016-01-01' AND collision_date < '2022-01-01'
    GROUP BY road_surface
)
SELECT valor, n, ROUND(100.0 * n / SUM(n) OVER (), 2) AS pct
FROM g ORDER BY n DESC NULLS LAST LIMIT 30;

-- S04 road_condition_1 TOP 30.
WITH g AS (
    SELECT road_condition_1 AS valor, COUNT(*) AS n
    FROM sw.collisions
    WHERE collision_date >= '2016-01-01' AND collision_date < '2022-01-01'
    GROUP BY road_condition_1
)
SELECT valor, n, ROUND(100.0 * n / SUM(n) OVER (), 2) AS pct
FROM g ORDER BY n DESC NULLS LAST LIMIT 30;

-- S05 control_device TOP 30.
WITH g AS (
    SELECT control_device AS valor, COUNT(*) AS n
    FROM sw.collisions
    WHERE collision_date >= '2016-01-01' AND collision_date < '2022-01-01'
    GROUP BY control_device
)
SELECT valor, n, ROUND(100.0 * n / SUM(n) OVER (), 2) AS pct
FROM g ORDER BY n DESC NULLS LAST LIMIT 30;

-- S06 primary_collision_factor TOP 30.
WITH g AS (
    SELECT primary_collision_factor AS valor, COUNT(*) AS n
    FROM sw.collisions
    WHERE collision_date >= '2016-01-01' AND collision_date < '2022-01-01'
    GROUP BY primary_collision_factor
)
SELECT valor, n, ROUND(100.0 * n / SUM(n) OVER (), 2) AS pct
FROM g ORDER BY n DESC NULLS LAST LIMIT 30;

-- S07 pcf_violation_category TOP 30.
WITH g AS (
    SELECT pcf_violation_category AS valor, COUNT(*) AS n
    FROM sw.collisions
    WHERE collision_date >= '2016-01-01' AND collision_date < '2022-01-01'
    GROUP BY pcf_violation_category
)
SELECT valor, n, ROUND(100.0 * n / SUM(n) OVER (), 2) AS pct
FROM g ORDER BY n DESC NULLS LAST LIMIT 30;

-- S08 type_of_collision TOP 30.
WITH g AS (
    SELECT type_of_collision AS valor, COUNT(*) AS n
    FROM sw.collisions
    WHERE collision_date >= '2016-01-01' AND collision_date < '2022-01-01'
    GROUP BY type_of_collision
)
SELECT valor, n, ROUND(100.0 * n / SUM(n) OVER (), 2) AS pct
FROM g ORDER BY n DESC NULLS LAST LIMIT 30;

-- S09 motor_vehicle_involved_with TOP 30.
WITH g AS (
    SELECT motor_vehicle_involved_with AS valor, COUNT(*) AS n
    FROM sw.collisions
    WHERE collision_date >= '2016-01-01' AND collision_date < '2022-01-01'
    GROUP BY motor_vehicle_involved_with
)
SELECT valor, n, ROUND(100.0 * n / SUM(n) OVER (), 2) AS pct
FROM g ORDER BY n DESC NULLS LAST LIMIT 30;

-- S10 collision_severity TOP 30.
WITH g AS (
    SELECT collision_severity AS valor, COUNT(*) AS n
    FROM sw.collisions
    WHERE collision_date >= '2016-01-01' AND collision_date < '2022-01-01'
    GROUP BY collision_severity
)
SELECT valor, n, ROUND(100.0 * n / SUM(n) OVER (), 2) AS pct
FROM g ORDER BY n DESC NULLS LAST LIMIT 30;

-- S11 county_location TOP 30 (hay 58 condados; el TOP cubre los de volumen).
WITH g AS (
    SELECT county_location AS valor, COUNT(*) AS n
    FROM sw.collisions
    WHERE collision_date >= '2016-01-01' AND collision_date < '2022-01-01'
    GROUP BY county_location
)
SELECT valor, n, ROUND(100.0 * n / SUM(n) OVER (), 2) AS pct
FROM g ORDER BY n DESC NULLS LAST LIMIT 30;

-- S12 party_type TOP 30 (partes del periodo via EXISTS).
WITH g AS (
    SELECT p.party_type AS valor, COUNT(*) AS n
    FROM sw.parties AS p
    WHERE EXISTS (
        SELECT 1 FROM sw.collisions AS c
        WHERE c.case_id = p.case_id
          AND c.collision_date >= '2016-01-01' AND c.collision_date < '2022-01-01'
    )
    GROUP BY p.party_type
)
SELECT valor, n, ROUND(100.0 * n / SUM(n) OVER (), 2) AS pct
FROM g ORDER BY n DESC NULLS LAST LIMIT 30;

-- S13 party_sobriety TOP 30.
WITH g AS (
    SELECT p.party_sobriety AS valor, COUNT(*) AS n
    FROM sw.parties AS p
    WHERE EXISTS (
        SELECT 1 FROM sw.collisions AS c
        WHERE c.case_id = p.case_id
          AND c.collision_date >= '2016-01-01' AND c.collision_date < '2022-01-01'
    )
    GROUP BY p.party_sobriety
)
SELECT valor, n, ROUND(100.0 * n / SUM(n) OVER (), 2) AS pct
FROM g ORDER BY n DESC NULLS LAST LIMIT 30;

-- S14 direction_of_travel TOP 30.
WITH g AS (
    SELECT p.direction_of_travel AS valor, COUNT(*) AS n
    FROM sw.parties AS p
    WHERE EXISTS (
        SELECT 1 FROM sw.collisions AS c
        WHERE c.case_id = p.case_id
          AND c.collision_date >= '2016-01-01' AND c.collision_date < '2022-01-01'
    )
    GROUP BY p.direction_of_travel
)
SELECT valor, n, ROUND(100.0 * n / SUM(n) OVER (), 2) AS pct
FROM g ORDER BY n DESC NULLS LAST LIMIT 30;

-- S15 party_race TOP 30.
WITH g AS (
    SELECT p.party_race AS valor, COUNT(*) AS n
    FROM sw.parties AS p
    WHERE EXISTS (
        SELECT 1 FROM sw.collisions AS c
        WHERE c.case_id = p.case_id
          AND c.collision_date >= '2016-01-01' AND c.collision_date < '2022-01-01'
    )
    GROUP BY p.party_race
)
SELECT valor, n, ROUND(100.0 * n / SUM(n) OVER (), 2) AS pct
FROM g ORDER BY n DESC NULLS LAST LIMIT 30;

-- S16 party_sex TOP 30.
WITH g AS (
    SELECT p.party_sex AS valor, COUNT(*) AS n
    FROM sw.parties AS p
    WHERE EXISTS (
        SELECT 1 FROM sw.collisions AS c
        WHERE c.case_id = p.case_id
          AND c.collision_date >= '2016-01-01' AND c.collision_date < '2022-01-01'
    )
    GROUP BY p.party_sex
)
SELECT valor, n, ROUND(100.0 * n / SUM(n) OVER (), 2) AS pct
FROM g ORDER BY n DESC NULLS LAST LIMIT 30;

-- S17 victim_role TOP 30.
WITH g AS (
    SELECT v.victim_role AS valor, COUNT(*) AS n
    FROM sw.victims AS v
    WHERE EXISTS (
        SELECT 1 FROM sw.collisions AS c
        WHERE c.case_id = v.case_id
          AND c.collision_date >= '2016-01-01' AND c.collision_date < '2022-01-01'
    )
    GROUP BY v.victim_role
)
SELECT valor, n, ROUND(100.0 * n / SUM(n) OVER (), 2) AS pct
FROM g ORDER BY n DESC NULLS LAST LIMIT 30;

-- S18 victim_sex TOP 30 (incluye basura fuera de male/female: se ve aqui).
WITH g AS (
    SELECT v.victim_sex AS valor, COUNT(*) AS n
    FROM sw.victims AS v
    WHERE EXISTS (
        SELECT 1 FROM sw.collisions AS c
        WHERE c.case_id = v.case_id
          AND c.collision_date >= '2016-01-01' AND c.collision_date < '2022-01-01'
    )
    GROUP BY v.victim_sex
)
SELECT valor, n, ROUND(100.0 * n / SUM(n) OVER (), 2) AS pct
FROM g ORDER BY n DESC NULLS LAST LIMIT 30;

-- S19 victim_degree_of_injury TOP 30.
WITH g AS (
    SELECT v.victim_degree_of_injury AS valor, COUNT(*) AS n
    FROM sw.victims AS v
    WHERE EXISTS (
        SELECT 1 FROM sw.collisions AS c
        WHERE c.case_id = v.case_id
          AND c.collision_date >= '2016-01-01' AND c.collision_date < '2022-01-01'
    )
    GROUP BY v.victim_degree_of_injury
)
SELECT valor, n, ROUND(100.0 * n / SUM(n) OVER (), 2) AS pct
FROM g ORDER BY n DESC NULLS LAST LIMIT 30;

-- S20 victim_seating_position TOP 30.
WITH g AS (
    SELECT v.victim_seating_position AS valor, COUNT(*) AS n
    FROM sw.victims AS v
    WHERE EXISTS (
        SELECT 1 FROM sw.collisions AS c
        WHERE c.case_id = v.case_id
          AND c.collision_date >= '2016-01-01' AND c.collision_date < '2022-01-01'
    )
    GROUP BY v.victim_seating_position
)
SELECT valor, n, ROUND(100.0 * n / SUM(n) OVER (), 2) AS pct
FROM g ORDER BY n DESC NULLS LAST LIMIT 30;

-- S21 victim_safety_equipment_1 TOP 30.
WITH g AS (
    SELECT v.victim_safety_equipment_1 AS valor, COUNT(*) AS n
    FROM sw.victims AS v
    WHERE EXISTS (
        SELECT 1 FROM sw.collisions AS c
        WHERE c.case_id = v.case_id
          AND c.collision_date >= '2016-01-01' AND c.collision_date < '2022-01-01'
    )
    GROUP BY v.victim_safety_equipment_1
)
SELECT valor, n, ROUND(100.0 * n / SUM(n) OVER (), 2) AS pct
FROM g ORDER BY n DESC NULLS LAST LIMIT 30;

-- S25 Cierre: que listas se arman con estos TOP 30.
SELECT 'DECISION_NORMALIZACION: crear dims (clima, iluminacion, superficie, condicion_vial, dispositivo_control, factor_colision, categoria_pcf, tipo_colision, vehiculo_contra, severidad, condado, tipo_parte, sobriedad, direccion, raza, rol_victima, sexo, grado_lesion, asiento, equipo_seguridad) con id=0 Sin clasificar para NULL+basura; cada dim guarda codigo_original + descripcion_ES + orden/grupo; el TOP 30 de este script es el seed de cada catalogo.' AS decision_normalizacion;
