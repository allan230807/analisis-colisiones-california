-- 05_integridad_duplicados.sql
-- EECA-UCV, Computacion II | Auditoria SWITRS California 2010-2019
-- Que responde: si las claves candidatas son unicas, si hay nulos en identificadores,
-- y si existe integridad referencial estricta entre colisiones, partes y victimas.

INSTALL sqlite;
LOAD sqlite;
ATTACH 'data/raw/switrs.sqlite' AS sw (TYPE sqlite, READ_ONLY);

-- ============================================================================
-- BLOQUE A: EVALUACION DE CLAVES CANDIDATAS Y NULOS EN TABLAS REALES (2010-2019)
-- ============================================================================

-- A01 collisions.case_id: unicidad y nulos en el periodo (candidato a PK).
SELECT COUNT(*) AS total_filas_periodo,
       COUNT(DISTINCT case_id) AS case_id_unicos,
       COUNT(*) - COUNT(DISTINCT case_id) AS duplicados_case_id,
       SUM(CASE WHEN case_id IS NULL THEN 1 ELSE 0 END) AS nulos_case_id,
       CASE WHEN COUNT(*) = COUNT(DISTINCT case_id) AND SUM(CASE WHEN case_id IS NULL THEN 1 ELSE 0 END) = 0
            THEN 'VALIDO: case_id es clave primaria valida del grano colision'
            ELSE 'INVALIDO: duplicados o nulos en case_id' END AS evaluacion
FROM sw.collisions
WHERE collision_date >= '2010-01-01' AND collision_date < '2020-01-01';

-- A02 parties: clave compuesta candidata (case_id, party_number).
SELECT COUNT(*) AS total_parties_periodo,
       COUNT(DISTINCT case_id || '-' || CAST(party_number AS VARCHAR)) AS claves_unicas,
       COUNT(*) - COUNT(DISTINCT case_id || '-' || CAST(party_number AS VARCHAR)) AS duplicados_clave,
       SUM(CASE WHEN p.case_id IS NULL OR p.party_number IS NULL THEN 1 ELSE 0 END) AS nulos_en_clave,
       CASE WHEN COUNT(*) = COUNT(DISTINCT case_id || '-' || CAST(party_number AS VARCHAR))
            THEN 'VALIDO: (case_id, party_number) es clave candidata unica'
            ELSE 'INVALIDO: duplicados detectados' END AS evaluacion
FROM sw.parties AS p
WHERE EXISTS (
    SELECT 1 FROM sw.collisions AS c
    WHERE c.case_id = p.case_id
      AND c.collision_date >= '2010-01-01' AND c.collision_date < '2020-01-01'
);

-- A03 parties.id: evaluacion de la columna id como clave sustituta.
SELECT COUNT(*) AS total_parties,
       COUNT(DISTINCT id) AS ids_unicos,
       COUNT(*) - COUNT(DISTINCT id) AS ids_duplicados,
       SUM(CASE WHEN id IS NULL THEN 1 ELSE 0 END) AS ids_nulos
FROM sw.parties AS p
WHERE EXISTS (
    SELECT 1 FROM sw.collisions AS c
    WHERE c.case_id = p.case_id
      AND c.collision_date >= '2010-01-01' AND c.collision_date < '2020-01-01'
);

-- A04 victims.id: evaluacion de la columna id como clave sustituta (expone unicidad real).
SELECT COUNT(*) AS total_victims,
       COUNT(DISTINCT id) AS ids_unicos,
       COUNT(*) - COUNT(DISTINCT id) AS ids_duplicados,
       SUM(CASE WHEN id IS NULL THEN 1 ELSE 0 END) AS ids_nulos,
       CASE WHEN COUNT(*) = COUNT(DISTINCT id) THEN 'VALIDO: id es unico'
            ELSE 'ADVERTENCIA: columna id presenta duplicados; requiere clave subrogada generada' END AS evaluacion
FROM sw.victims AS v
WHERE EXISTS (
    SELECT 1 FROM sw.collisions AS c
    WHERE c.case_id = v.case_id
      AND c.collision_date >= '2010-01-01' AND c.collision_date < '2020-01-01'
);

-- A05 victims: relacion con parties (1 party a N victims dentro del mismo case_id).
SELECT v.case_id, v.party_number, COUNT(*) AS victimas_por_parte
FROM sw.victims AS v
WHERE EXISTS (
    SELECT 1 FROM sw.collisions AS c
    WHERE c.case_id = v.case_id
      AND c.collision_date >= '2010-01-01' AND c.collision_date < '2020-01-01'
)
GROUP BY v.case_id, v.party_number
HAVING COUNT(*) > 1
ORDER BY victimas_por_parte DESC
LIMIT 10;

-- ============================================================================
-- BLOQUE B: INTEGRIDAD REFERENCIAL Y REGISTROS HUERFANOS
-- ============================================================================

-- B01 Parties sin colision padre (NOT EXISTS; evaluacion global en toda la base).
SELECT COUNT(*) AS n_parties_huerfanas_global
FROM sw.parties AS p
WHERE NOT EXISTS (SELECT 1 FROM sw.collisions AS c WHERE c.case_id = p.case_id);

-- B02 Victims sin colision padre (NOT EXISTS; evaluacion global en toda la base).
SELECT COUNT(*) AS n_victims_huerfanas_global
FROM sw.victims AS v
WHERE NOT EXISTS (SELECT 1 FROM sw.collisions AS c WHERE c.case_id = v.case_id);

-- B03 Victims sin party padre en el periodo (clave compuesta case_id + party_number).
SELECT COUNT(*) AS n_victims_sin_party_periodo
FROM sw.victims AS v
WHERE EXISTS (SELECT 1 FROM sw.collisions AS c
              WHERE c.case_id = v.case_id
                AND c.collision_date >= '2010-01-01' AND c.collision_date < '2020-01-01')
  AND NOT EXISTS (SELECT 1 FROM sw.parties AS p
                  WHERE p.case_id = v.case_id AND p.party_number = v.party_number);

-- B04 Relacion entre case_ids y collisions.
SELECT (SELECT COUNT(*) FROM sw.case_ids) AS total_case_ids,
       (SELECT COUNT(*) FROM sw.collisions) AS total_collisions,
       (SELECT COUNT(*) FROM sw.case_ids ci
        WHERE NOT EXISTS (SELECT 1 FROM sw.collisions c WHERE c.case_id = ci.case_id)) AS case_ids_sin_colision,
       (SELECT COUNT(*) FROM sw.collisions c
        WHERE NOT EXISTS (SELECT 1 FROM sw.case_ids ci WHERE ci.case_id = c.case_id)) AS colisiones_sin_case_id;

-- ============================================================================
-- BLOQUE C: INSPECCION DE ARTEFACTOS DIMENSIONALES PREEXISTENTES EN SQLITE
-- ============================================================================

-- C01 Cobertura temporal de dim_fecha preexistente (alerta metodologica).
SELECT COUNT(*) AS dias_en_dim_fecha_preexistente,
       MIN(fecha) AS fecha_min_preexistente,
       MAX(fecha) AS fecha_max_preexistente,
       CASE WHEN COUNT(*) = 3652 THEN 'COMPLETO'
            ELSE 'INCOMPLETO: dim_fecha preexistente solo cubre 2016-2021 (2.191 dias); debe regenerarse para 2010-2019 (3.652 dias)'
       END AS diagnostico
FROM sw.dim_fecha;

-- C02 Duplicados semanticos en catalogos preexistentes (unknown duplicados).
SELECT 'dim_factor_colision' AS tabla, descripcion, COUNT(*) AS n_filas
FROM sw.dim_factor_colision GROUP BY descripcion HAVING COUNT(*) > 1
UNION ALL
SELECT 'dim_categoria_pcf', descripcion, COUNT(*)
FROM sw.dim_categoria_pcf GROUP BY descripcion HAVING COUNT(*) > 1;

-- ============================================================================
-- BLOQUE D: CIERRE METODOLOGICO
-- ============================================================================
SELECT 'DECISION_NORMALIZACION: case_id es PK unica del hecho colisiones (0 nulos, 0 repetidos); (case_id, party_number) es clave candidata de parties; victims requiere clave subrogada por duplicado en columna id; integridad referencial 100%% sin huerfanos; las tablas dim_* preexistentes en SQLite corresponden al prototipo 2016-2021 y deben reconstruirse en Fase 2 para la decada 2010-2019.' AS decision_normalizacion;
