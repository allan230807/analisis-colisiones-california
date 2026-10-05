"""
03_nulos_e_inconsistencias.sql
===============================================================================
AUDITORÍA DE NULOS E INCONSISTENCIAS
Investigación: Perfiles de riesgo en colisiones de tránsito en California,
2016-2021.
Escuela de Estadística y Ciencias Actuariales (EECA-UCV) — Computación II
===============================================================================

Este script detecta valores nulos en columnas que se proponen como FKs o medidas,
para definir constraints NOT NULL en el esquema estrella.

Los nulos son críticos porque afectan la integridad de los datos: una FK con
nulos puede romper la integridad referencial, y una medida con nulos puede
producir resultados incorrectos en agregaciones.

Los resultados de este script se documentan en RESULTADOS_AUDITORIA.md.
"""

-- 1. Nulos en columnas de collisions que serán FKs o medidas
SELECT 'collisions' AS tabla,
       SUM(CASE WHEN case_id IS NULL THEN 1 ELSE 0 END) AS nulos_case_id,
       SUM(CASE WHEN collision_date IS NULL THEN 1 ELSE 0 END) AS nulos_collision_date,
       SUM(CASE WHEN collision_time IS NULL THEN 1 ELSE 0 END) AS nulos_collision_time,
       SUM(CASE WHEN weather_1 IS NULL THEN 1 ELSE 0 END) AS nulos_weather_1,
       SUM(CASE WHEN lighting IS NULL THEN 1 ELSE 0 END) AS nulos_lighting,
       SUM(CASE WHEN road_surface IS NULL THEN 1 ELSE 0 END) AS nulos_road_surface,
       SUM(CASE WHEN road_condition_1 IS NULL THEN 1 ELSE 0 END) AS nulos_road_condition_1,
       SUM(CASE WHEN control_device IS NULL THEN 1 ELSE 0 END) AS nulos_control_device,
       SUM(CASE WHEN primary_collision_factor IS NULL THEN 1 ELSE 0 END) AS nulos_primary_collision_factor,
       SUM(CASE WHEN pcf_violation_category IS NULL THEN 1 ELSE 0 END) AS nulos_pcf_violation_category,
       SUM(CASE WHEN type_of_collision IS NULL THEN 1 ELSE 0 END) AS nulos_type_of_collision,
       SUM(CASE WHEN motor_vehicle_involved_with IS NULL THEN 1 ELSE 0 END) AS nulos_motor_vehicle_involved_with,
       SUM(CASE WHEN collision_severity IS NULL THEN 1 ELSE 0 END) AS nulos_collision_severity,
       SUM(CASE WHEN alcohol_involved IS NULL THEN 1 ELSE 0 END) AS nulos_alcohol_involved,
       SUM(CASE WHEN killed_victims IS NULL THEN 1 ELSE 0 END) AS nulos_killed_victims,
       SUM(CASE WHEN injured_victims IS NULL THEN 1 ELSE 0 END) AS nulos_injured_victims,
       SUM(CASE WHEN party_count IS NULL THEN 1 ELSE 0 END) AS nulos_party_count,
       SUM(CASE WHEN latitude IS NULL THEN 1 ELSE 0 END) AS nulos_latitude,
       SUM(CASE WHEN longitude IS NULL THEN 1 ELSE 0 END) AS nulos_longitude
FROM collisions;

-- 2. Nulos en columnas de parties que serán FKs o medidas
SELECT 'parties' AS tabla,
       SUM(CASE WHEN case_id IS NULL THEN 1 ELSE 0 END) AS nulos_case_id,
       SUM(CASE WHEN party_number IS NULL THEN 1 ELSE 0 END) AS nulos_party_number,
       SUM(CASE WHEN party_type IS NULL THEN 1 ELSE 0 END) AS nulos_party_type,
       SUM(CASE WHEN at_fault IS NULL THEN 1 ELSE 0 END) AS nulos_at_fault,
       SUM(CASE WHEN party_sex IS NULL THEN 1 ELSE 0 END) AS nulos_party_sex,
       SUM(CASE WHEN party_age IS NULL THEN 1 ELSE 0 END) AS nulos_party_age,
       SUM(CASE WHEN party_sobriety IS NULL THEN 1 ELSE 0 END) AS nulos_party_sobriety,
       SUM(CASE WHEN direction_of_travel IS NULL THEN 1 ELSE 0 END) AS nulos_direction_of_travel,
       SUM(CASE WHEN vehicle_year IS NULL THEN 1 ELSE 0 END) AS nulos_vehicle_year,
       SUM(CASE WHEN statewide_vehicle_type IS NULL THEN 1 ELSE 0 END) AS nulos_statewide_vehicle_type,
       SUM(CASE WHEN party_race IS NULL THEN 1 ELSE 0 END) AS nulos_party_race
FROM parties;

-- 3. Nulos en columnas de victims que serán FKs o medidas
SELECT 'victims' AS tabla,
       SUM(CASE WHEN case_id IS NULL THEN 1 ELSE 0 END) AS nulos_case_id,
       SUM(CASE WHEN party_number IS NULL THEN 1 ELSE 0 END) AS nulos_party_number,
       SUM(CASE WHEN victim_role IS NULL THEN 1 ELSE 0 END) AS nulos_victim_role,
       SUM(CASE WHEN victim_sex IS NULL THEN 1 ELSE 0 END) AS nulos_victim_sex,
       SUM(CASE WHEN victim_age IS NULL THEN 1 ELSE 0 END) AS nulos_victim_age,
       SUM(CASE WHEN victim_degree_of_injury IS NULL THEN 1 ELSE 0 END) AS nulos_victim_degree_of_injury,
       SUM(CASE WHEN victim_seating_position IS NULL THEN 1 ELSE 0 END) AS nulos_victim_seating_position,
       SUM(CASE WHEN victim_safety_equipment_1 IS NULL THEN 1 ELSE 0 END) AS nulos_victim_safety_equipment_1,
       SUM(CASE WHEN victim_ejected IS NULL THEN 1 ELSE 0 END) AS nulos_victim_ejected
FROM victims;
