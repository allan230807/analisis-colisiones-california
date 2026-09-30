-- ============================================================
-- NORMALIZACIÓN Y MODELADO DIMENSIONAL SWITRS (2016-2021)
-- ============================================================
-- Proyecto: Análisis y Perfil de Siniestralidad Vehicular en California
-- Motor: DuckDB (Procesamiento analítico columnar vectorial)
--
-- JUSTIFICACIÓN DEL PERIODO 2016-2021:
-- A partir de 2016, la Patrulla de Caminos de California (CHP) adoptó
-- el estándar federal MMUCC (Model Minimum Uniform Crash Criteria).
-- Este cambio modificó la taxonomía de lesiones (victim_degree_of_injury),
-- introduciendo clasificaciones como 'suspected serious injury',
-- 'suspected minor injury' y 'possible injury' que no existían de forma
-- estandarizada en años previos. Analizar el bloque 2016-2021 garantiza
-- homogeneidad taxonómica y consistencia estadística.
-- ============================================================

INSTALL sqlite_scanner;
LOAD sqlite_scanner;

ATTACH 'data/raw/switrs.sqlite' AS switrs (TYPE sqlite);

-- ============================================================
-- FASE 1: CREACIÓN DE TABLAS DE DIMENSIÓN (STAR SCHEMA)
-- ============================================================

-- 1.1 Dimensión Calendario (Evita cálculo repetitivo de EXTRACT en consultas)
CREATE OR REPLACE TABLE dim_fecha AS
SELECT
    fecha::DATE                                     AS fecha,
    EXTRACT(YEAR FROM fecha)::SMALLINT              AS anio,
    EXTRACT(MONTH FROM fecha)::SMALLINT             AS mes,
    EXTRACT(DAY FROM fecha)::SMALLINT               AS dia,
    EXTRACT(DOW FROM fecha)::SMALLINT               AS dia_semana,  -- 0=Domingo, 6=Sábado
    CASE EXTRACT(DOW FROM fecha)
        WHEN 0 THEN 'Domingo'   WHEN 1 THEN 'Lunes'
        WHEN 2 THEN 'Martes'    WHEN 3 THEN 'Miércoles'
        WHEN 4 THEN 'Jueves'    WHEN 5 THEN 'Viernes'
        WHEN 6 THEN 'Sábado'
    END                                             AS nombre_dia,
    CASE EXTRACT(MONTH FROM fecha)
        WHEN 1  THEN 'Enero'     WHEN 2  THEN 'Febrero'
        WHEN 3  THEN 'Marzo'     WHEN 4  THEN 'Abril'
        WHEN 5  THEN 'Mayo'      WHEN 6  THEN 'Junio'
        WHEN 7  THEN 'Julio'     WHEN 8  THEN 'Agosto'
        WHEN 9  THEN 'Septiembre'WHEN 10 THEN 'Octubre'
        WHEN 11 THEN 'Noviembre' WHEN 12 THEN 'Diciembre'
    END                                             AS nombre_mes,
    EXTRACT(QUARTER FROM fecha)::SMALLINT           AS trimestre,
    (EXTRACT(DOW FROM fecha) IN (0, 6))             AS es_fin_semana
FROM generate_series(DATE '2016-01-01', DATE '2021-12-31', INTERVAL '1 day') AS t(fecha);

-- 1.2 Dimensión Severidad de Colisión
CREATE OR REPLACE TABLE dim_severidad (
    severidad_id    SMALLINT PRIMARY KEY,
    codigo_original TEXT NOT NULL,
    descripcion     TEXT NOT NULL,
    orden_gravedad  SMALLINT NOT NULL
);
INSERT INTO dim_severidad VALUES
    (1, 'property damage only', 'Solo daños a la propiedad', 1),
    (2, 'pain',                 'Queja de dolor',            2),
    (3, 'other injury',         'Otra lesión visible',       3),
    (4, 'severe injury',        'Lesión severa',             4),
    (5, 'fatal',                'Colisión fatal',            5),
    (0, 'unknown',              'No especificado/Inválido',  0);

-- 1.3 Dimensión Grado de Lesión de la Víctima (Adaptado a MMUCC 2016+)
CREATE OR REPLACE TABLE dim_grado_lesion (
    grado_lesion_id SMALLINT PRIMARY KEY,
    codigo_original TEXT NOT NULL,
    descripcion     TEXT NOT NULL,
    es_herido       BOOLEAN NOT NULL,
    es_fatal        BOOLEAN NOT NULL,
    orden_gravedad  SMALLINT NOT NULL
);
INSERT INTO dim_grado_lesion VALUES
    (1, 'no injury',                 'Sin lesiones aparentes',    FALSE, FALSE, 0),
    (2, 'complaint of pain',         'Queja de dolor',            TRUE,  FALSE, 1),
    (3, 'possible injury',           'Lesión posible (MMUCC)',    TRUE,  FALSE, 2),
    (4, 'other visible injury',      'Otra lesión visible',       TRUE,  FALSE, 3),
    (5, 'suspected minor injury',    'Lesión menor sospechada',   TRUE,  FALSE, 4),
    (6, 'suspected serious injury',  'Lesión severa sospechada',  TRUE,  FALSE, 5),
    (7, 'severe injury',             'Lesión severa incapacitante',TRUE, FALSE, 6),
    (8, 'killed',                    'Víctima fallecida',         FALSE, TRUE,  7),
    (0, 'unknown',                   'No especificado/Desconocido',FALSE,FALSE, -1);

-- 1.4 Dimensión Tipo de Vehículo Estandarizada
CREATE OR REPLACE TABLE dim_tipo_vehiculo (
    tipo_vehiculo_id   SMALLINT PRIMARY KEY,
    codigo_original    TEXT NOT NULL,
    descripcion        TEXT NOT NULL,
    categoria_macro    TEXT NOT NULL
);
INSERT INTO dim_tipo_vehiculo VALUES
    (1,  'passenger car',                       'Automóvil particular',             'Autos'),
    (2,  'passenger car with trailer',          'Automóvil con remolque',           'Autos'),
    (3,  'pickup or panel truck',               'Camioneta Pickup o Panel',         'Camionetas'),
    (4,  'pickup or panel truck with trailer',  'Camioneta con remolque',           'Camionetas'),
    (5,  'truck or truck tractor',              'Camión o tractocamión',            'Camiones'),
    (6,  'truck or truck tractor with trailer', 'Camión con remolque',              'Camiones'),
    (7,  'motorcycle or scooter',               'Motocicleta o scooter',            'Motocicletas'),
    (8,  'moped',                               'Ciclomotor / Moped',               'Motocicletas'),
    (9,  'bicycle',                             'Bicicleta',                        'Movilidad Activa'),
    (10, 'pedestrian',                          'Peatón',                           'Movilidad Activa'),
    (11, 'emergency vehicle',                   'Vehículo de emergencia',           'Servicios'),
    (12, 'schoolbus',                           'Autobús escolar',                  'Transporte Masivo'),
    (13, 'other bus',                           'Otro tipo de autobús',             'Transporte Masivo'),
    (14, 'highway construction equipment',      'Maquinaria de construcción',       'Especiales'),
    (15, 'other vehicle',                       'Otro vehículo motorizado',         'Otros'),
    (0,  'unknown',                             'Desconocido o no reportado',       'Desconocido');

-- 1.5 Dimensión Demográfica: Sexo
CREATE OR REPLACE TABLE dim_sexo (
    sexo_id     SMALLINT PRIMARY KEY,
    codigo      TEXT NOT NULL,
    descripcion TEXT NOT NULL
);
INSERT INTO dim_sexo VALUES
    (1, 'male',    'Masculino'),
    (2, 'female',  'Femenino'),
    (0, 'unknown', 'Desconocido / No reportado');

-- 1.6 Dimensión Demográfica: Grupo de Edad
CREATE OR REPLACE TABLE dim_grupo_edad (
    grupo_edad_id SMALLINT PRIMARY KEY,
    etiqueta      TEXT NOT NULL,
    edad_min      SMALLINT,
    edad_max      SMALLINT
);
INSERT INTO dim_grupo_edad VALUES
    (1, 'Menor de 18',  0,    17),
    (2, '18-25',        18,   25),
    (3, '26-35',        26,   35),
    (4, '36-50',        36,   50),
    (5, '51-65',        51,   65),
    (6, 'Mayor de 65',  66,  120),
    (0, 'Desconocido',  NULL, NULL);

-- ============================================================
-- FASE 2: NORMALIZACIÓN DE TABLA DE COLISIONES (collisions)
-- ============================================================
-- Correcciones aplicadas:
-- - Filtro estricto 2016-2021
-- - Eliminación de duplicidad en 'type_of_collision'
-- - Tipado eficiente (SMALLINT, DATE, TIME, FLOAT)
-- - Flags booleanos normalizados
-- - Eliminación de duplicidad 'columna' y 'columna_limpia'

CREATE OR REPLACE TABLE collisions_normalizada AS
SELECT
    c.case_id,
    CAST(c.collision_date AS DATE)                              AS collision_date,
    TRY_CAST(c.collision_time AS TIME)                          AS collision_time,
    EXTRACT(YEAR FROM CAST(c.collision_date AS DATE))::SMALLINT AS anio,
    EXTRACT(MONTH FROM CAST(c.collision_date AS DATE))::SMALLINT AS mes,
    EXTRACT(DOW FROM CAST(c.collision_date AS DATE))::SMALLINT  AS dia_semana,
    EXTRACT(HOUR FROM TRY_CAST(c.collision_time AS TIME))::SMALLINT AS hora,
    LOWER(TRIM(c.county_location))                              AS county_location,
    COALESCE(LOWER(TRIM(c.city_division_lapd)), 'non-lapd')    AS city_division_lapd,

    -- Severidad mapeada a código estándar
    CASE c.collision_severity
        WHEN 'property damage only' THEN 'property damage only'
        WHEN 'pain'                 THEN 'pain'
        WHEN 'other injury'         THEN 'other injury'
        WHEN 'severe injury'        THEN 'severe injury'
        WHEN 'fatal'                THEN 'fatal'
        ELSE 'unknown'
    END                                                         AS collision_severity,

    -- Tipo de colisión (sin duplicados en SELECT)
    COALESCE(c.type_of_collision, 'unknown')                    AS type_of_collision,

    -- Alcohol: NULL preservado semánticamente como FALSE / No confirmado
    COALESCE(c.alcohol_involved = 1, FALSE)                     AS alcohol_involved,

    -- Métricas de víctimas
    COALESCE(c.killed_victims, 0)::SMALLINT                     AS killed_victims,
    COALESCE(c.injured_victims, 0)::SMALLINT                    AS injured_victims,
    COALESCE(c.party_count, 0)::SMALLINT                        AS party_count,

    -- Factores y circunstancias viales
    COALESCE(c.primary_collision_factor, 'unknown')             AS primary_collision_factor,
    COALESCE(c.pcf_violation_category, 'unknown')               AS pcf_violation_category,
    COALESCE(c.hit_and_run, 'not hit and run')                  AS hit_and_run,
    COALESCE(c.road_surface, 'unknown')                         AS road_surface,
    COALESCE(c.road_condition_1, 'unknown')                     AS road_condition,
    COALESCE(c.weather_1, 'unknown')                            AS weather,
    COALESCE(c.lighting, 'unknown')                             AS lighting,
    COALESCE(c.control_device, 'unknown')                       AS control_device,

    -- Flags booleanos de actores vulnerables / involucrados
    COALESCE(c.pedestrian_collision = 1, FALSE)                 AS pedestrian_collision,
    COALESCE(c.bicycle_collision = 1, FALSE)                    AS bicycle_collision,
    COALESCE(c.motorcycle_collision = 1, FALSE)                 AS motorcycle_collision,
    COALESCE(c.truck_collision = 1, FALSE)                      AS truck_collision,

    -- Coordenadas espaciales (FLOAT de 32 bits, 50% ahorro de espacio)
    c.latitude::FLOAT                                           AS latitude,
    c.longitude::FLOAT                                          AS longitude,
    (c.latitude IS NOT NULL AND c.longitude IS NOT NULL)        AS tiene_coordenadas

FROM switrs.collisions c
WHERE EXTRACT(YEAR FROM CAST(c.collision_date AS DATE)) BETWEEN 2016 AND 2021;

-- ============================================================
-- FASE 3: NORMALIZACIÓN DE TABLA DE PARTES (parties)
-- ============================================================
-- Correcciones aplicadas:
-- - Eliminación del centinela -1 (uso de NULL nativo para edades y años)
-- - Normalización estricta de género (valores espurios reclasificados a 'unknown')
-- - Corrección de nomenclaturas vehiculares (eliminado error '04')
-- - Limpieza de valores anómalos en party_type ('6' -> 'unknown')

CREATE OR REPLACE TABLE parties_normalizada AS
SELECT
    p.id::INTEGER                                               AS id,
    p.case_id,
    p.party_number::SMALLINT                                    AS party_number,

    -- Tipo de parte limpio
    CASE
        WHEN p.party_type IN ('driver', 'pedestrian', 'parked vehicle', 'bicyclist', 'other')
            THEN p.party_type
        ELSE 'unknown'
    END                                                         AS party_type,

    COALESCE(p.at_fault = 1, FALSE)                             AS at_fault,

    -- Sexo estandarizado
    CASE
        WHEN p.party_sex = 'male'   THEN 'male'
        WHEN p.party_sex = 'female' THEN 'female'
        ELSE 'unknown'
    END                                                         AS party_sex,

    -- Edad: NULL nativo sin contaminar cálculos estadísticos con -1
    CASE
        WHEN p.party_age BETWEEN 0 AND 120 THEN p.party_age::SMALLINT
        ELSE NULL
    END                                                         AS party_age,

    -- Clasificación en grupo etario
    CASE
        WHEN p.party_age < 18               THEN 'Menor de 18'
        WHEN p.party_age BETWEEN 18 AND 25  THEN '18-25'
        WHEN p.party_age BETWEEN 26 AND 35  THEN '26-35'
        WHEN p.party_age BETWEEN 36 AND 50  THEN '36-50'
        WHEN p.party_age BETWEEN 51 AND 65  THEN '51-65'
        WHEN p.party_age > 65               THEN 'Mayor de 65'
        ELSE 'Desconocido'
    END                                                         AS party_age_group,

    COALESCE(p.party_sobriety, 'unknown')                       AS party_sobriety,
    COALESCE(p.cellphone_in_use = 1, FALSE)                     AS cellphone_in_use,

    -- Año de vehículo saneado
    CASE
        WHEN p.vehicle_year BETWEEN 1900 AND 2025 THEN p.vehicle_year::SMALLINT
        ELSE NULL
    END                                                         AS vehicle_year,

    COALESCE(p.vehicle_make, 'unknown')                         AS vehicle_make,

    -- Nomenclatura vehicular sin el código espurio '04'
    CASE
        WHEN p.statewide_vehicle_type = '04' THEN 'unknown'
        WHEN p.statewide_vehicle_type IS NULL THEN 'unknown'
        ELSE p.statewide_vehicle_type
    END                                                         AS statewide_vehicle_type

FROM switrs.parties p
INNER JOIN switrs.collisions c ON p.case_id = c.case_id
WHERE EXTRACT(YEAR FROM CAST(c.collision_date AS DATE)) BETWEEN 2016 AND 2021;

-- ============================================================
-- FASE 4: NORMALIZACIÓN DE TABLA DE VÍCTIMAS (victims)
-- ============================================================
-- Correcciones aplicadas:
-- - Vinculación de taxonomía completa MMUCC 2016+
-- - Normalización de género (depuración de códigos espurios 'X', 1-5, B, G, etc.)
-- - Eliminación de centinela -1

CREATE OR REPLACE TABLE victims_normalizada AS
SELECT
    v.id::INTEGER                                               AS id,
    v.case_id,
    v.party_number::SMALLINT                                    AS party_number,
    COALESCE(v.victim_role, 'unknown')                          AS victim_role,

    -- Sexo limpio
    CASE
        WHEN v.victim_sex = 'male'   THEN 'male'
        WHEN v.victim_sex = 'female' THEN 'female'
        ELSE 'unknown'
    END                                                         AS victim_sex,

    -- Edad con NULL nativo
    CASE
        WHEN v.victim_age BETWEEN 0 AND 120 THEN v.victim_age::SMALLINT
        ELSE NULL
    END                                                         AS victim_age,

    -- Grupo de edad
    CASE
        WHEN v.victim_age < 18               THEN 'Menor de 18'
        WHEN v.victim_age BETWEEN 18 AND 25  THEN '18-25'
        WHEN v.victim_age BETWEEN 26 AND 35  THEN '26-35'
        WHEN v.victim_age BETWEEN 36 AND 50  THEN '36-50'
        WHEN v.victim_age BETWEEN 51 AND 65  THEN '51-65'
        WHEN v.victim_age > 65               THEN 'Mayor de 65'
        ELSE 'Desconocido'
    END                                                         AS victim_age_group,

    -- Taxonomía completa y validada de grado de lesión MMUCC
    COALESCE(v.victim_degree_of_injury, 'unknown')              AS victim_degree_of_injury,
    COALESCE(v.victim_seating_position, 'unknown')              AS victim_seating_position,
    COALESCE(v.victim_safety_equipment_1, 'unknown')            AS safety_equipment,
    COALESCE(v.victim_ejected, 'unknown')                       AS victim_ejected

FROM switrs.victims v
INNER JOIN switrs.collisions c ON v.case_id = c.case_id
WHERE EXTRACT(YEAR FROM CAST(c.collision_date AS DATE)) BETWEEN 2016 AND 2021;

-- ============================================================
-- FASE 5: TABLA INTEGRADA CON AUDITORÍA DE CONTEO
-- ============================================================
-- Resuelve la discrepancia de conteo integrando la tabla victims
-- como la fuente granular de verdad para heridos y fallecidos reales.

CREATE OR REPLACE TABLE colisiones_integrada AS
SELECT
    c.*,
    COALESCE(p.total_parties, 0)::SMALLINT                      AS total_parties,
    COALESCE(p.total_at_fault, 0)::SMALLINT                     AS total_at_fault,
    COALESCE(v.total_victims, 0)::SMALLINT                      AS total_victims,
    COALESCE(v.heridos_reales, 0)::SMALLINT                     AS heridos_reales,
    COALESCE(v.fatales_reales, 0)::SMALLINT                     AS fatales_reales,

    -- Auditoría fila a fila de discrepancias de conteo policial
    (c.injured_victims - COALESCE(v.heridos_reales, 0))::SMALLINT AS diff_heridos,
    (c.killed_victims - COALESCE(v.fatales_reales, 0))::SMALLINT  AS diff_fatales

FROM collisions_normalizada c

LEFT JOIN (
    SELECT
        case_id,
        COUNT(*)::SMALLINT                      AS total_parties,
        SUM(CASE WHEN at_fault THEN 1 ELSE 0 END)::SMALLINT AS total_at_fault
    FROM parties_normalizada
    GROUP BY case_id
) p ON c.case_id = p.case_id

LEFT JOIN (
    SELECT
        case_id,
        COUNT(*)::SMALLINT                      AS total_victims,
        -- Mapeo exacto de todas las categorías de lesiones MMUCC
        SUM(CASE
            WHEN victim_degree_of_injury IN (
                'complaint of pain',
                'other visible injury',
                'severe injury',
                'suspected minor injury',
                'suspected serious injury',
                'possible injury'
            ) THEN 1 ELSE 0
        END)::SMALLINT                          AS heridos_reales,
        SUM(CASE
            WHEN victim_degree_of_injury = 'killed' THEN 1 ELSE 0
        END)::SMALLINT                          AS fatales_reales
    FROM victims_normalizada
    GROUP BY case_id
) v ON c.case_id = v.case_id;

-- ============================================================
-- FASE 6: EXPORTACIÓN EN FORMATO PARQUET
-- ============================================================

COPY collisions_normalizada TO 'data/processed/collisions_normalizada.parquet' (FORMAT PARQUET);
COPY parties_normalizada    TO 'data/processed/parties_normalizada.parquet' (FORMAT PARQUET);
COPY victims_normalizada    TO 'data/processed/victims_normalizada.parquet' (FORMAT PARQUET);
COPY colisiones_integrada   TO 'data/processed/colisiones_integrada.parquet' (FORMAT PARQUET);

-- Exportar tablas de dimensión del modelo estrella
COPY dim_fecha              TO 'data/processed/dim_fecha.parquet' (FORMAT PARQUET);
COPY dim_severidad          TO 'data/processed/dim_severidad.parquet' (FORMAT PARQUET);
COPY dim_grado_lesion       TO 'data/processed/dim_grado_lesion.parquet' (FORMAT PARQUET);
COPY dim_tipo_vehiculo      TO 'data/processed/dim_tipo_vehiculo.parquet' (FORMAT PARQUET);
COPY dim_sexo               TO 'data/processed/dim_sexo.parquet' (FORMAT PARQUET);
COPY dim_grupo_edad         TO 'data/processed/dim_grupo_edad.parquet' (FORMAT PARQUET);

-- ============================================================
-- FASE 7: VERIFICACIÓN Y AUDITORÍA DE CALIDAD FINAL
-- ============================================================

SELECT 'collisions_normalizada' AS entidad, COUNT(*) AS registros FROM collisions_normalizada
UNION ALL
SELECT 'parties_normalizada',               COUNT(*) FROM parties_normalizada
UNION ALL
SELECT 'victims_normalizada',               COUNT(*) FROM victims_normalizada
UNION ALL
SELECT 'colisiones_integrada',              COUNT(*) FROM colisiones_integrada;

-- Validación de resolución de discrepancia de víctimas
SELECT
    SUM(injured_victims)                        AS heridos_reportados_policial,
    SUM(heridos_reales)                         AS heridos_reales_mmucc,
    SUM(injured_victims) - SUM(heridos_reales)  AS diferencia_global_heridos,
    SUM(killed_victims)                         AS fallecidos_reportados_policial,
    SUM(fatales_reales)                         AS fallecidos_reales_victims,
    SUM(killed_victims) - SUM(fatales_reales)   AS diferencia_global_fatales
FROM colisiones_integrada;

DETACH switrs;
