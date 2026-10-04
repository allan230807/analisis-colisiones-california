-- ============================================================
-- PIPELINE DE NORMALIZACIÓN Y MODELADO DIMENSIONAL SWITRS (2016-2021)
-- ============================================================
-- Proyecto: Análisis y Perfil de Siniestralidad Vehicular en California
-- Motor: DuckDB (Procesamiento analítico columnar vectorial)
--
-- ARQUITECTURA DEL MODELO: STAR SCHEMA REAL (KIMBALL)
--   * Tabla de hechos: colisiones_integrada
--   * Dimensiones: fecha, severidad, grado_lesion, tipo_vehiculo, sexo,
--                 grupo_edad, tipo_colision, clima, iluminacion,
--                 superficie, condicion_vial, dispositivo_control,
--                 factor_colision, categoria_pcf, hit_and_run
--   * Todas las FK son numéricas y tienen restricciones explícitas.
--   * Redundancia temporal eliminada: solo collision_date (FK a dim_fecha).
--   * Exportación optimizada: tabla de hechos + 13 dimensiones en Parquet.
-- ============================================================

INSTALL sqlite_scanner;
LOAD sqlite_scanner;

ATTACH 'data/raw/switrs.sqlite' AS switrs (TYPE sqlite);

-- ============================================================
-- FASE 1: CREACIÓN DE DIMENSIONES (STAR SCHEMA)
-- ============================================================

-- 1.1 Dimensión Calendario
CREATE OR REPLACE TABLE dim_fecha (
    fecha           DATE PRIMARY KEY,
    anio            SMALLINT NOT NULL,
    mes             SMALLINT NOT NULL,
    dia             SMALLINT NOT NULL,
    dia_semana      SMALLINT NOT NULL,  -- 0=Domingo, 6=Sábado
    nombre_dia      TEXT NOT NULL,
    nombre_mes      TEXT NOT NULL,
    trimestre       SMALLINT NOT NULL,
    es_fin_semana   BOOLEAN NOT NULL
);
INSERT INTO dim_fecha
SELECT
    fecha::DATE                                     AS fecha,
    EXTRACT(YEAR FROM fecha)::SMALLINT              AS anio,
    EXTRACT(MONTH FROM fecha)::SMALLINT             AS mes,
    EXTRACT(DAY FROM fecha)::SMALLINT               AS dia,
    EXTRACT(DOW FROM fecha)::SMALLINT               AS dia_semana,
    CASE EXTRACT(DOW FROM fecha) WHEN 0 THEN 'Domingo'   WHEN 1 THEN 'Lunes'
                                 WHEN 2 THEN 'Martes'    WHEN 3 THEN 'Miércoles'
                                 WHEN 4 THEN 'Jueves'    WHEN 5 THEN 'Viernes'
                                 WHEN 6 THEN 'Sábado' END          AS nombre_dia,
    CASE EXTRACT(MONTH FROM fecha) WHEN 1 THEN 'Enero'   WHEN 2 THEN 'Febrero'
                                     WHEN 3 THEN 'Marzo'   WHEN 4 THEN 'Abril'
                                     WHEN 5 THEN 'Mayo'    WHEN 6 THEN 'Junio'
                                     WHEN 7 THEN 'Julio'   WHEN 8 THEN 'Agosto'
                                     WHEN 9 THEN 'Septiembre' WHEN 10 THEN 'Octubre'
                                     WHEN 11 THEN 'Noviembre' WHEN 12 THEN 'Diciembre' END AS nombre_mes,
    EXTRACT(QUARTER FROM fecha)::SMALLINT           AS trimestre,
    (EXTRACT(DOW FROM fecha) IN (0,6))               AS es_fin_semana
FROM generate_series(DATE '2016-01-01', DATE '2021-12-31', INTERVAL '1 day') AS t(fecha);

-- 1.2 Dimensión Severidad
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

-- 1.3 Dimensión Grado de Lesión (MMUCC)
CREATE OR REPLACE TABLE dim_grado_lesion (
    grado_lesion_id SMALLINT PRIMARY KEY,
    codigo_original TEXT NOT NULL,
    descripcion     TEXT NOT NULL,
    es_herido       BOOLEAN NOT NULL,
    es_fatal        BOOLEAN NOT NULL,
    orden_gravedad  SMALLINT NOT NULL
);
INSERT INTO dim_grado_lesion VALUES
    (1, 'no injury',                 'Sin lesiones aparentes',     FALSE, FALSE, 0),
    (2, 'complaint of pain',         'Queja de dolor',            TRUE,  FALSE, 1),
    (3, 'possible injury',           'Lesión posible (MMUCC)',    TRUE,  FALSE, 2),
    (4, 'other visible injury',      'Otra lesión visible',       TRUE,  FALSE, 3),
    (5, 'suspected minor injury',    'Lesión menor sospechada',   TRUE,  FALSE, 4),
    (6, 'suspected serious injury',  'Lesión severa sospechada',  TRUE,  FALSE, 5),
    (7, 'severe injury',             'Lesión severa incapacitante',TRUE, FALSE, 6),
    (8, 'killed',                    'Víctima fallecida',          FALSE, TRUE,  7),
    (0, 'unknown',                   'No especificado/Desconocido',FALSE,FALSE,-1);

-- 1.4 Dimensión Tipo de Vehículo
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

-- 1.5 Dimensión Sexo
CREATE OR REPLACE TABLE dim_sexo (
    sexo_id     SMALLINT PRIMARY KEY,
    codigo      TEXT NOT NULL,
    descripcion TEXT NOT NULL
);
INSERT INTO dim_sexo VALUES
    (1, 'male',    'Masculino'),
    (2, 'female',  'Femenino'),
    (0, 'unknown', 'Desconocido / No reportado');

-- 1.6 Dimensión Grupo de Edad
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

-- 1.7 Dimensiones de atributos textuales de colisión (Junk Dimensions)
-- Cada una contiene un id numérico y la descripción textual original.

CREATE OR REPLACE TABLE dim_tipo_colision (
    tipo_colision_id SMALLINT PRIMARY KEY,
    descripcion      TEXT NOT NULL
);
INSERT INTO dim_tipo_colision (tipo_colision_id, descripcion)
SELECT DISTINCT ROW_NUMBER() OVER (ORDER BY c.type_of_collision) AS id,
                COALESCE(c.type_of_collision, 'unknown')
FROM   switrs.collisions c
WHERE  EXTRACT(YEAR FROM CAST(c.collision_date AS DATE)) BETWEEN 2016 AND 2021;

CREATE OR REPLACE TABLE dim_clima (
    clima_id  SMALLINT PRIMARY KEY,
    descripcion TEXT NOT NULL
);
INSERT INTO dim_clima (clima_id, descripcion)
SELECT DISTINCT ROW_NUMBER() OVER (ORDER BY c.weather_1) AS id,
                COALESCE(c.weather_1, 'unknown')
FROM   switrs.collisions c
WHERE  EXTRACT(YEAR FROM CAST(c.collision_date AS DATE)) BETWEEN 2016 AND 2021;

CREATE OR REPLACE TABLE dim_iluminacion (
    iluminacion_id SMALLINT PRIMARY KEY,
    descripcion    TEXT NOT NULL
);
INSERT INTO dim_iluminacion (iluminacion_id, descripcion)
SELECT DISTINCT ROW_NUMBER() OVER (ORDER BY c.lighting) AS id,
                COALESCE(c.lighting, 'unknown')
FROM   switrs.collisions c
WHERE  EXTRACT(YEAR FROM CAST(c.collision_date AS DATE)) BETWEEN 2016 AND 2021;

CREATE OR REPLACE TABLE dim_superficie (
    superficie_id SMALLINT PRIMARY KEY,
    descripcion   TEXT NOT NULL
);
INSERT INTO dim_superficie (superficie_id, descripcion)
SELECT DISTINCT ROW_NUMBER() OVER (ORDER BY c.road_surface) AS id,
                COALESCE(c.road_surface, 'unknown')
FROM   switrs.collisions c
WHERE  EXTRACT(YEAR FROM CAST(c.collision_date AS DATE)) BETWEEN 2016 AND 2021;

CREATE OR REPLACE TABLE dim_condicion_vial (
    condicion_id SMALLINT PRIMARY KEY,
    descripcion  TEXT NOT NULL
);
INSERT INTO dim_condicion_vial (condicion_id, descripcion)
SELECT DISTINCT ROW_NUMBER() OVER (ORDER BY c.road_condition_1) AS id,
                COALESCE(c.road_condition_1, 'unknown')
FROM   switrs.collisions c
WHERE  EXTRACT(YEAR FROM CAST(c.collision_date AS DATE)) BETWEEN 2016 AND 2021;

CREATE OR REPLACE TABLE dim_dispositivo_control (
    control_id  SMALLINT PRIMARY KEY,
    descripcion TEXT NOT NULL
);
INSERT INTO dim_dispositivo_control (control_id, descripcion)
SELECT DISTINCT ROW_NUMBER() OVER (ORDER BY c.control_device) AS id,
                COALESCE(c.control_device, 'unknown')
FROM   switrs.collisions c
WHERE  EXTRACT(YEAR FROM CAST(c.collision_date AS DATE)) BETWEEN 2016 AND 2021;

CREATE OR REPLACE TABLE dim_factor_colision (
    factor_id   SMALLINT PRIMARY KEY,
    descripcion TEXT NOT NULL
);
INSERT INTO dim_factor_colision (factor_id, descripcion)
SELECT DISTINCT ROW_NUMBER() OVER (ORDER BY c.primary_collision_factor) AS id,
                COALESCE(c.primary_collision_factor, 'unknown')
FROM   switrs.collisions c
WHERE  EXTRACT(YEAR FROM CAST(c.collision_date AS DATE)) BETWEEN 2016 AND 2021;

CREATE OR REPLACE TABLE dim_categoria_pcf (
    categoria_id SMALLINT PRIMARY KEY,
    descripcion  TEXT NOT NULL
);
INSERT INTO dim_categoria_pcf (categoria_id, descripcion)
SELECT DISTINCT ROW_NUMBER() OVER (ORDER BY c.pcf_violation_category) AS id,
                COALESCE(c.pcf_violation_category, 'unknown')
FROM   switrs.collisions c
WHERE  EXTRACT(YEAR FROM CAST(c.collision_date AS DATE)) BETWEEN 2016 AND 2021;

CREATE OR REPLACE TABLE dim_hit_and_run (
    hitrun_id   SMALLINT PRIMARY KEY,
    descripcion TEXT NOT NULL
);
INSERT INTO dim_hit_and_run (hitrun_id, descripcion)
SELECT DISTINCT ROW_NUMBER() OVER (ORDER BY c.hit_and_run) AS id,
                COALESCE(c.hit_and_run, 'not hit and run')
FROM   switrs.collisions c
WHERE  EXTRACT(YEAR FROM CAST(c.collision_date AS DATE)) BETWEEN 2016 AND 2021;

-- ============================================================
-- FASE 2: NORMALIZACIÓN DE COLLISIONS (tabla intermedia)
-- ============================================================
CREATE OR REPLACE TABLE collisions_normalizada AS
SELECT
    c.case_id,
    CAST(c.collision_date AS DATE)                              AS collision_date,
    TRY_CAST(c.collision_time AS TIME)                          AS collision_time,
    LOWER(TRIM(c.county_location))                              AS county_location,
    COALESCE(LOWER(TRIM(c.city_division_lapd)), 'non-lapd')    AS city_division_lapd,
    COALESCE(ds.severidad_id, 0)::SMALLINT                      AS severidad_id,
    -- Joins a dimensiones textuales
    COALESCE(dtcol.tipo_colision_id, 0)::SMALLINT                AS tipo_colision_id,
    COALESCE(dclima.clima_id, 0)::SMALLINT                      AS clima_id,
    COALESCE(dilum.iluminacion_id, 0)::SMALLINT                AS iluminacion_id,
    COALESCE(dsurf.superficie_id, 0)::SMALLINT                 AS superficie_id,
    COALESCE(dcond.condicion_id, 0)::SMALLINT                   AS condicion_vial_id,
    COALESCE(dctrl.control_id, 0)::SMALLINT                    AS control_device_id,
    COALESCE(dfact.factor_id, 0)::SMALLINT                      AS factor_colision_id,
    COALESCE(dpcf.categoria_id, 0)::SMALLINT                    AS categoria_pcf_id,
    COALESCE(dhit.hitrun_id, 0)::SMALLINT                      AS hit_and_run_id,
    COALESCE(c.alcohol_involved = 1, FALSE)                     AS alcohol_involved,
    COALESCE(c.killed_victims, 0)::SMALLINT                     AS killed_victims,
    COALESCE(c.injured_victims, 0)::SMALLINT                    AS injured_victims,
    COALESCE(c.party_count, 0)::SMALLINT                        AS party_count,
    COALESCE(c.pedestrian_collision = 1, FALSE)                 AS pedestrian_collision,
    COALESCE(c.bicycle_collision = 1, FALSE)                    AS bicycle_collision,
    COALESCE(c.motorcycle_collision = 1, FALSE)                 AS motorcycle_collision,
    COALESCE(c.truck_collision = 1, FALSE)                      AS truck_collision,
    c.latitude::FLOAT                                           AS latitude,
    c.longitude::FLOAT                                          AS longitude,
    (c.latitude IS NOT NULL AND c.longitude IS NOT NULL)        AS tiene_coordenadas
FROM switrs.collisions c
LEFT JOIN dim_severidad ds       ON c.collision_severity = ds.codigo_original
LEFT JOIN dim_tipo_colision dtcol ON COALESCE(c.type_of_collision, 'unknown') = dtcol.descripcion
LEFT JOIN dim_clima dclima       ON COALESCE(c.weather_1, 'unknown') = dclima.descripcion
LEFT JOIN dim_iluminacion dilum  ON COALESCE(c.lighting, 'unknown') = dilum.descripcion
LEFT JOIN dim_superficie dsurf   ON COALESCE(c.road_surface, 'unknown') = dsurf.descripcion
LEFT JOIN dim_condicion_vial dcond ON COALESCE(c.road_condition_1, 'unknown') = dcond.descripcion
LEFT JOIN dim_dispositivo_control dctrl ON COALESCE(c.control_device, 'unknown') = dctrl.descripcion
LEFT JOIN dim_factor_colision dfact ON COALESCE(c.primary_collision_factor, 'unknown') = dfact.descripcion
LEFT JOIN dim_categoria_pcf dpcf  ON COALESCE(c.pcf_violation_category, 'unknown') = dpcf.descripcion
LEFT JOIN dim_hit_and_run dhit   ON COALESCE(c.hit_and_run, 'not hit and run') = dhit.descripcion
WHERE EXTRACT(YEAR FROM CAST(c.collision_date AS DATE)) BETWEEN 2016 AND 2021;

-- ============================================================
-- FASE 3: NORMALIZACIÓN DE PARTIES
-- ============================================================
CREATE OR REPLACE TABLE parties_normalizada AS
SELECT
    p.id::INTEGER                                               AS id,
    p.case_id,
    p.party_number::SMALLINT                                    AS party_number,
    CASE WHEN p.party_type IN ('driver','pedestrian','parked vehicle','bicyclist','other')
         THEN p.party_type ELSE 'unknown' END                    AS party_type,
    COALESCE(p.at_fault = 1, FALSE)                             AS at_fault,
    COALESCE(ds.sexo_id, 0)::SMALLINT                           AS sexo_id,
    CASE WHEN p.party_age BETWEEN 0 AND 120 THEN p.party_age::SMALLINT ELSE NULL END AS party_age,
    COALESCE(dge.grupo_edad_id, 0)::SMALLINT                    AS grupo_edad_id,
    COALESCE(p.party_sobriety, 'unknown')                       AS party_sobriety,
    COALESCE(p.cellphone_in_use = 1, FALSE)                     AS cellphone_in_use,
    CASE WHEN p.vehicle_year BETWEEN 1900 AND 2025 THEN p.vehicle_year::SMALLINT ELSE NULL END AS vehicle_year,
    COALESCE(p.vehicle_make, 'unknown')                         AS vehicle_make,
    COALESCE(dtv.tipo_vehiculo_id, 0)::SMALLINT                 AS tipo_vehiculo_id
FROM switrs.parties p
INNER JOIN switrs.collisions c ON p.case_id = c.case_id
LEFT JOIN dim_sexo ds       ON LOWER(TRIM(p.party_sex)) = ds.codigo
LEFT JOIN dim_grupo_edad dge ON p.party_age BETWEEN dge.edad_min AND dge.edad_max
LEFT JOIN dim_tipo_vehiculo dtv ON (CASE WHEN p.statewide_vehicle_type = '04' THEN 'unknown' ELSE p.statewide_vehicle_type END) = dtv.codigo_original
WHERE EXTRACT(YEAR FROM CAST(c.collision_date AS DATE)) BETWEEN 2016 AND 2021;

-- ============================================================
-- FASE 4: NORMALIZACIÓN DE VICTIMS
-- ============================================================
CREATE OR REPLACE TABLE victims_normalizada AS
SELECT
    v.id::INTEGER                                               AS id,
    v.case_id,
    v.party_number::SMALLINT                                    AS party_number,
    COALESCE(v.victim_role, 'unknown')                          AS victim_role,
    COALESCE(ds.sexo_id, 0)::SMALLINT                           AS sexo_id,
    CASE WHEN v.victim_age BETWEEN 0 AND 120 THEN v.victim_age::SMALLINT ELSE NULL END AS victim_age,
    COALESCE(dge.grupo_edad_id, 0)::SMALLINT                    AS grupo_edad_id,
    COALESCE(dgl.grado_lesion_id, 0)::SMALLINT                  AS grado_lesion_id,
    COALESCE(v.victim_seating_position, 'unknown')              AS victim_seating_position,
    COALESCE(v.victim_safety_equipment_1, 'unknown')            AS safety_equipment,
    COALESCE(v.victim_ejected, 'unknown')                       AS victim_ejected
FROM switrs.victims v
INNER JOIN switrs.collisions c ON v.case_id = c.case_id
LEFT JOIN dim_sexo ds       ON LOWER(TRIM(v.victim_sex)) = ds.codigo
LEFT JOIN dim_grupo_edad dge ON v.victim_age BETWEEN dge.edad_min AND dge.edad_max
LEFT JOIN dim_grado_lesion dgl ON v.victim_degree_of_injury = dgl.codigo_original
WHERE EXTRACT(YEAR FROM CAST(c.collision_date AS DATE)) BETWEEN 2016 AND 2021;

-- ============================================================
-- FASE 5: TABLA DE HECHOS FINAL CON FK EXPÍCITAS
-- ============================================================
CREATE OR REPLACE TABLE colisiones_integrada (
    case_id                     TEXT PRIMARY KEY,
    collision_date              DATE NOT NULL REFERENCES dim_fecha(fecha),
    collision_time              TIME,
    county_location             TEXT,
    city_division_lapd          TEXT,
    severidad_id                SMALLINT NOT NULL REFERENCES dim_severidad(severidad_id),
    tipo_colision_id            SMALLINT NOT NULL REFERENCES dim_tipo_colision(tipo_colision_id),
    clima_id                    SMALLINT NOT NULL REFERENCES dim_clima(clima_id),
    iluminacion_id              SMALLINT NOT NULL REFERENCES dim_iluminacion(iluminacion_id),
    superficie_id               SMALLINT NOT NULL REFERENCES dim_superficie(superficie_id),
    condicion_vial_id           SMALLINT NOT NULL REFERENCES dim_condicion_vial(condicion_id),
    control_device_id           SMALLINT NOT NULL REFERENCES dim_dispositivo_control(control_id),
    factor_colision_id          SMALLINT NOT NULL REFERENCES dim_factor_colision(factor_id),
    categoria_pcf_id            SMALLINT NOT NULL REFERENCES dim_categoria_pcf(categoria_id),
    hit_and_run_id              SMALLINT NOT NULL REFERENCES dim_hit_and_run(hitrun_id),
    alcohol_involved            BOOLEAN NOT NULL,
    killed_victims              SMALLINT NOT NULL,
    injured_victims             SMALLINT NOT NULL,
    party_count                 SMALLINT NOT NULL,
    pedestrian_collision        BOOLEAN NOT NULL,
    bicycle_collision           BOOLEAN NOT NULL,
    motorcycle_collision        BOOLEAN NOT NULL,
    truck_collision             BOOLEAN NOT NULL,
    latitude                    FLOAT,
    longitude                   FLOAT,
    tiene_coordenadas           BOOLEAN NOT NULL,
    total_parties               SMALLINT NOT NULL,
    total_at_fault              SMALLINT NOT NULL,
    total_victims               SMALLINT NOT NULL,
    heridos_reales              SMALLINT NOT NULL,
    fatales_reales              SMALLINT NOT NULL,
    diff_heridos                SMALLINT NOT NULL,
    diff_fatales                SMALLINT NOT NULL
);

INSERT INTO colisiones_integrada
SELECT
    c.case_id,
    c.collision_date,
    c.collision_time,
    c.county_location,
    c.city_division_lapd,
    c.severidad_id,
    c.tipo_colision_id,
    c.clima_id,
    c.iluminacion_id,
    c.superficie_id,
    c.condicion_vial_id,
    c.control_device_id,
    c.factor_colision_id,
    c.categoria_pcf_id,
    c.hit_and_run_id,
    c.alcohol_involved,
    c.killed_victims,
    c.injured_victims,
    c.party_count,
    c.pedestrian_collision,
    c.bicycle_collision,
    c.motorcycle_collision,
    c.truck_collision,
    c.latitude,
    c.longitude,
    c.tiene_coordenadas,
    COALESCE(p.total_parties, 0)::SMALLINT    AS total_parties,
    COALESCE(p.total_at_fault, 0)::SMALLINT   AS total_at_fault,
    COALESCE(v.total_victims, 0)::SMALLINT    AS total_victims,
    COALESCE(v.heridos_reales, 0)::SMALLINT   AS heridos_reales,
    COALESCE(v.fatales_reales, 0)::SMALLINT   AS fatales_reales,
    (c.injured_victims - COALESCE(v.heridos_reales,0))::SMALLINT AS diff_heridos,
    (c.killed_victims - COALESCE(v.fatales_reales,0))::SMALLINT AS diff_fatales
FROM collisions_normalizada c
LEFT JOIN (
    SELECT case_id,
           COUNT(*)::SMALLINT                          AS total_parties,
           SUM(CASE WHEN at_fault THEN 1 ELSE 0 END)::SMALLINT AS total_at_fault
    FROM parties_normalizada
    GROUP BY case_id
) p ON c.case_id = p.case_id
LEFT JOIN (
    SELECT v.case_id,
           COUNT(*)::SMALLINT                          AS total_victims,
           SUM(CASE WHEN dgl.es_herido THEN 1 ELSE 0 END)::SMALLINT AS heridos_reales,
           SUM(CASE WHEN dgl.es_fatal  THEN 1 ELSE 0 END)::SMALLINT AS fatales_reales
    FROM victims_normalizada v
    LEFT JOIN dim_grado_lesion dgl ON v.grado_lesion_id = dgl.grado_lesion_id
    GROUP BY v.case_id
) v ON c.case_id = v.case_id;

-- ============================================================
-- FASE 6: EXPORTACIÓN A PARQUET (solo tabla de hechos + dimensiones)
-- ============================================================
COPY colisiones_integrada   TO 'data/processed/colisiones_integrada.parquet' (FORMAT PARQUET);
COPY dim_fecha              TO 'data/processed/dim_fecha.parquet' (FORMAT PARQUET);
COPY dim_severidad          TO 'data/processed/dim_severidad.parquet' (FORMAT PARQUET);
COPY dim_grado_lesion       TO 'data/processed/dim_grado_lesion.parquet' (FORMAT PARQUET);
COPY dim_tipo_vehiculo      TO 'data/processed/dim_tipo_vehiculo.parquet' (FORMAT PARQUET);
COPY dim_sexo               TO 'data/processed/dim_sexo.parquet' (FORMAT PARQUET);
COPY dim_grupo_edad         TO 'data/processed/dim_grupo_edad.parquet' (FORMAT PARQUET);
COPY dim_tipo_colision      TO 'data/processed/dim_tipo_colision.parquet' (FORMAT PARQUET);
COPY dim_clima              TO 'data/processed/dim_clima.parquet' (FORMAT PARQUET);
COPY dim_iluminacion        TO 'data/processed/dim_iluminacion.parquet' (FORMAT PARQUET);
COPY dim_superficie         TO 'data/processed/dim_superficie.parquet' (FORMAT PARQUET);
COPY dim_condicion_vial     TO 'data/processed/dim_condicion_vial.parquet' (FORMAT PARQUET);
COPY dim_dispositivo_control TO 'data/processed/dim_dispositivo_control.parquet' (FORMAT PARQUET);
COPY dim_factor_colision    TO 'data/processed/dim_factor_colision.parquet' (FORMAT PARQUET);
COPY dim_categoria_pcf      TO 'data/processed/dim_categoria_pcf.parquet' (FORMAT PARQUET);
COPY dim_hit_and_run        TO 'data/processed/dim_hit_and_run.parquet' (FORMAT PARQUET);

-- ============================================================
-- FASE 7: VALIDACIÓN FINAL
-- ============================================================
SELECT 'colisiones_integrada' AS entidad, COUNT(*) AS registros FROM colisiones_integrada
UNION ALL SELECT 'dim_fecha',               COUNT(*) FROM dim_fecha
UNION ALL SELECT 'dim_severidad',           COUNT(*) FROM dim_severidad
UNION ALL SELECT 'dim_grado_lesion',        COUNT(*) FROM dim_grado_lesion
UNION ALL SELECT 'dim_tipo_vehiculo',       COUNT(*) FROM dim_tipo_vehiculo
UNION ALL SELECT 'dim_sexo',                COUNT(*) FROM dim_sexo
UNION ALL SELECT 'dim_grupo_edad',          COUNT(*) FROM dim_grupo_edad
UNION ALL SELECT 'dim_tipo_colision',       COUNT(*) FROM dim_tipo_colision
UNION ALL SELECT 'dim_clima',               COUNT(*) FROM dim_clima
UNION ALL SELECT 'dim_iluminacion',         COUNT(*) FROM dim_iluminacion
UNION ALL SELECT 'dim_superficie',          COUNT(*) FROM dim_superficie
UNION ALL SELECT 'dim_condicion_vial',      COUNT(*) FROM dim_condicion_vial
UNION ALL SELECT 'dim_dispositivo_control', COUNT(*) FROM dim_dispositivo_control
UNION ALL SELECT 'dim_factor_colision',     COUNT(*) FROM dim_factor_colision
UNION ALL SELECT 'dim_categoria_pcf',       COUNT(*) FROM dim_categoria_pcf
UNION ALL SELECT 'dim_hit_and_run',         COUNT(*) FROM dim_hit_and_run;

SELECT
    SUM(injured_victims)                        AS heridos_reportados_policial,
    SUM(heridos_reales)                         AS heridos_reales_mmucc,
    SUM(injured_victims) - SUM(heridos_reales)  AS diferencia_global_heridos,
    SUM(killed_victims)                         AS fallecidos_reportados_policial,
    SUM(fatales_reales)                         AS fallecidos_reales_victims,
    SUM(killed_victims) - SUM(fatales_reales)   AS diferencia_global_fatales
FROM colisiones_integrada;

DETACH switrs;
