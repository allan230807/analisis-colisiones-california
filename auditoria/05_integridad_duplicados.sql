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
-- Se separa: total, nulos, no nulos, no nulos unicos, repetidos entre no nulos.
SELECT 
    COUNT(*) AS total_filas_periodo,
    SUM(CASE WHEN case_id IS NULL THEN 1 ELSE 0 END) AS nulos_case_id,
    COUNT(*) - SUM(CASE WHEN case_id IS NULL THEN 1 ELSE 0 END) AS no_nulos_case_id,
    COUNT(DISTINCT case_id) AS case_id_distintos,
    CASE WHEN SUM(CASE WHEN case_id IS NULL THEN 1 ELSE 0 END) = 0
         THEN COUNT(*) - COUNT(DISTINCT case_id)
         ELSE NULL END AS duplicados_entre_no_nulos,
    CASE WHEN SUM(CASE WHEN case_id IS NULL THEN 1 ELSE 0 END) = 0
         AND COUNT(*) = COUNT(DISTINCT case_id)
         THEN 'VALIDO: case_id es clave primaria valida (sin nulos, sin duplicados)'
         ELSE 'REVISAR: nulos o duplicados en case_id' END AS evaluacion
FROM sw.collisions
WHERE collision_date >= '2010-01-01' AND collision_date < '2020-01-01';

-- A02 parties: clave compuesta candidata (case_id, party_number).
-- Se verifica primero que ninguno de los componentes sea nulo, despues se mide
-- duplicidad entre las filas con ambos componentes no nulos.
SELECT 
    COUNT(*) AS total_parties_periodo,
    SUM(CASE WHEN p.case_id IS NULL OR p.party_number IS NULL THEN 1 ELSE 0 END) AS nulos_en_clave,
    COUNT(*) - SUM(CASE WHEN p.case_id IS NULL OR p.party_number IS NULL THEN 1 ELSE 0 END) AS filas_con_clave_completa,
    COUNT(DISTINCT p.case_id || '-' || CAST(p.party_number AS VARCHAR)) AS claves_distintas,
    CASE WHEN SUM(CASE WHEN p.case_id IS NULL OR p.party_number IS NULL THEN 1 ELSE 0 END) = 0
         THEN COUNT(*) - COUNT(DISTINCT p.case_id || '-' || CAST(p.party_number AS VARCHAR))
         ELSE NULL END AS duplicados_entre_clave_completa,
    CASE WHEN SUM(CASE WHEN p.case_id IS NULL OR p.party_number IS NULL THEN 1 ELSE 0 END) = 0
         AND COUNT(*) = COUNT(DISTINCT p.case_id || '-' || CAST(p.party_number AS VARCHAR))
         THEN 'VALIDO: (case_id, party_number) es clave candidata unica (sin nulos, sin duplicados)'
         ELSE 'REVISAR: nulos o duplicados en clave compuesta' END AS evaluacion
FROM sw.parties AS p
WHERE EXISTS (
    SELECT 1 FROM sw.collisions AS c
    WHERE c.case_id = p.case_id
      AND c.collision_date >= '2010-01-01' AND c.collision_date < '2020-01-01'
);

-- A03 parties.id: evaluacion de la columna id como clave sustituta.
-- Separa nulos de duplicados entre no nulos; no declara valida solo porque
-- COUNT(*) = COUNT(DISTINCT id) (podría haber nulos y duplicados compensados).
SELECT 
    COUNT(*) AS total_parties,
    SUM(CASE WHEN id IS NULL THEN 1 ELSE 0 END) AS ids_nulos,
    COUNT(*) - SUM(CASE WHEN id IS NULL THEN 1 ELSE 0 END) AS ids_no_nulos,
    COUNT(DISTINCT id) AS ids_distintos,
    CASE WHEN SUM(CASE WHEN id IS NULL THEN 1 ELSE 0 END) = 0
         THEN COUNT(*) - COUNT(DISTINCT id)
         ELSE NULL END AS duplicados_entre_no_nulos,
    CASE WHEN SUM(CASE WHEN id IS NULL THEN 1 ELSE 0 END) = 0
         AND COUNT(*) = COUNT(DISTINCT id)
         THEN 'VALIDO: id es unico sin nulos'
         ELSE 'REVISAR: nulos o duplicados en id; requiere clave subrogada generada' END AS evaluacion
FROM sw.parties AS p
WHERE EXISTS (
    SELECT 1 FROM sw.collisions AS c
    WHERE c.case_id = p.case_id
      AND c.collision_date >= '2010-01-01' AND c.collision_date < '2020-01-01'
);

-- A04 victims.id: evaluacion de la columna id como clave sustituta.
-- Separa nulos de duplicados entre no nulos; no declara valida solo porque
-- COUNT(*) = COUNT(DISTINCT id).
SELECT 
    COUNT(*) AS total_victims,
    SUM(CASE WHEN id IS NULL THEN 1 ELSE 0 END) AS ids_nulos,
    COUNT(*) - SUM(CASE WHEN id IS NULL THEN 1 ELSE 0 END) AS ids_no_nulos,
    COUNT(DISTINCT id) AS ids_distintos,
    CASE WHEN SUM(CASE WHEN id IS NULL THEN 1 ELSE 0 END) = 0
         THEN COUNT(*) - COUNT(DISTINCT id)
         ELSE NULL END AS duplicados_entre_no_nulos,
    CASE WHEN SUM(CASE WHEN id IS NULL THEN 1 ELSE 0 END) = 0
         AND COUNT(*) = COUNT(DISTINCT id)
         THEN 'VALIDO: id es unico sin nulos'
         ELSE 'REVISAR: nulos o duplicados en id; requiere clave subrogada generada' END AS evaluacion
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

-- A06 victims: base de la PK de victima (case_id, numero_parte, numero_victima).
-- numero_victima = ROW_NUMBER() ordenado por id dentro de (case_id, party_number);
-- es determinista si id no se repite dentro del grupo. Las filas identicas salvo id
-- son personas distintas con el mismo perfil (p. ej. dos pasajeros), no duplicados.
SELECT COUNT(*) AS total_victims,
       (SELECT COUNT(*) FROM (
            SELECT v.case_id, v.party_number, v.id FROM sw.victims AS v
            WHERE EXISTS (SELECT 1 FROM sw.collisions AS c WHERE c.case_id = v.case_id
                          AND c.collision_date >= '2010-01-01' AND c.collision_date < '2020-01-01')
            GROUP BY ALL HAVING COUNT(*) > 1)) AS id_repetido_dentro_de_parte,
       COUNT(*) - (SELECT COUNT(*) FROM (
            SELECT DISTINCT v.* EXCLUDE (id) FROM sw.victims AS v
            WHERE EXISTS (SELECT 1 FROM sw.collisions AS c WHERE c.case_id = v.case_id
                          AND c.collision_date >= '2010-01-01' AND c.collision_date < '2020-01-01'))) AS filas_identicas_salvo_id
FROM sw.victims AS v
WHERE EXISTS (SELECT 1 FROM sw.collisions AS c WHERE c.case_id = v.case_id
              AND c.collision_date >= '2010-01-01' AND c.collision_date < '2020-01-01');

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
            ELSE 'INCOMPLETO: dim_fecha preexistente solo cubre 2016-2021 (2.192 dias); debe regenerarse para 2010-2019 (3.652 dias)'
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
SELECT 'DECISION_NORMALIZACION: case_id (INTEGER, 07-N01) es PK de colision; (case_id, party_number) es PK de parte; parties.id y victims.id se descartan (no son claves: 3 y 1 duplicados); victima recibe PK compuesta (case_id, numero_parte, numero_victima) con ordinal determinista por id (A06); las filas de victimas identicas salvo id se conservan; FK victima -> parte -> colision verificadas por NOT EXISTS sin huerfanos; case_ids (case_id, db_year) es redundante con collisions y no se migra; las dim_* del prototipo 2016-2021 se descartan y se reconstruyen en Fase 2.' AS decision_normalizacion;
