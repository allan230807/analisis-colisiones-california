"""
06_integridad_referencial.sql
===============================================================================
AUDITORÍA DE INTEGRIDAD REFERENCIAL
Investigación: Perfiles de riesgo en colisiones de tránsito en California,
2016-2021.
Escuela de Estadística y Ciencias Actuariales (EECA-UCV) — Computación II
===============================================================================

Este script verifica que las relaciones entre tablas son consistentes
(case_id, party_number), garantizando que no haya huérfanos.

La integridad referencial es fundamental para la calidad de los datos: una FK
sin su correspondiente PK rompe la consistencia del modelo y produce resultados
incorrectos en los JOINs.

Los resultados de este script se documentan en RESULTADOS_AUDITORIA.md.
"""

-- 1. Verificar que todos los case_id de parties existen en collisions
SELECT 'parties -> collisions' AS relacion,
       COUNT(*) AS total_partes,
       SUM(CASE WHEN c.case_id IS NULL THEN 1 ELSE 0 END) AS huerfanos
FROM parties p
LEFT JOIN collisions c ON p.case_id = c.case_id;

-- 2. Verificar que todos los case_id de victims existen en collisions
SELECT 'victims -> collisions' AS relacion,
       COUNT(*) AS total_victimas,
       SUM(CASE WHEN c.case_id IS NULL THEN 1 ELSE 0 END) AS huerfanos
FROM victims v
LEFT JOIN collisions c ON v.case_id = c.case_id;

-- 3. Verificar que todos los (case_id, party_number) de victims existen en parties
SELECT 'victims -> parties' AS relacion,
       COUNT(*) AS total_victimas,
       SUM(CASE WHEN p.case_id IS NULL THEN 1 ELSE 0 END) AS huerfanos
FROM victims v
LEFT JOIN parties p ON v.case_id = p.case_id AND v.party_number = p.party_number;

-- 4. Verificar duplicados en case_ids (tabla auxiliar)
SELECT 'case_ids' AS tabla,
       COUNT(*) AS total_registros,
       COUNT(DISTINCT case_id) AS case_ids_unicos,
       COUNT(*) - COUNT(DISTINCT case_id) AS duplicados
FROM case_ids;

-- 5. Verificar que case_ids no tenga huerfanos con collisions
SELECT 'case_ids -> collisions' AS relacion,
       COUNT(*) AS total_case_ids,
       SUM(CASE WHEN c.case_id IS NULL THEN 1 ELSE 0 END) AS huerfanos
FROM case_ids ci
LEFT JOIN collisions c ON ci.case_id = c.case_id;
