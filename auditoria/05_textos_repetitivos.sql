"""
05_textos_repetitivos.sql
===============================================================================
AUDITORÍA DE TEXTOS REPETITIVOS (DIMENSIONES DEGENERADAS)
Investigación: Perfiles de riesgo en colisiones de tránsito en California,
2016-2021.
Escuela de Estadística y Ciencias Actuariales (EECA-UCV) — Computación II
===============================================================================

Este script identifica columnas con alta cardinalidad que deben permanecer como
atributos degenerados en la tabla de hechos, en lugar de crear dimensiones.

Las dimensiones degeneradas son atributos que no tienen una dimensión asociada
porque su cardinalidad es demasiado alta para justificar una tabla separada.
Ejemplos: primary_road, secondary_road, officer_id, vehicle_make.

Los resultados de este script se documentan en RESULTADOS_AUDITORIA.md.
"""

-- 1. primary_road - ¿Cuántos valores únicos hay?
SELECT 'primary_road' AS columna,
       COUNT(DISTINCT primary_road) AS valores_unicos,
       COUNT(*) AS total_filas,
       ROUND(COUNT(DISTINCT primary_road) * 100.0 / COUNT(*), 2) AS porcentaje_cardinalidad
FROM collisions;

-- 2. secondary_road
SELECT 'secondary_road' AS columna,
       COUNT(DISTINCT secondary_road) AS valores_unicos,
       COUNT(*) AS total_filas,
       ROUND(COUNT(DISTINCT secondary_road) * 100.0 / COUNT(*), 2) AS porcentaje_cardinalidad
FROM collisions;

-- 3. officer_id
SELECT 'officer_id' AS columna,
       COUNT(DISTINCT officer_id) AS valores_unicos,
       COUNT(*) AS total_filas,
       ROUND(COUNT(DISTINCT officer_id) * 100.0 / COUNT(*), 2) AS porcentaje_cardinalidad
FROM collisions;

-- 4. reporting_district
SELECT 'reporting_district' AS columna,
       COUNT(DISTINCT reporting_district) AS valores_unicos,
       COUNT(*) AS total_filas,
       ROUND(COUNT(DISTINCT reporting_district) * 100.0 / COUNT(*), 2) AS porcentaje_cardinalidad
FROM collisions;

-- 5. vehicle_make (parties)
SELECT 'vehicle_make' AS columna,
       COUNT(DISTINCT vehicle_make) AS valores_unicos,
       COUNT(*) AS total_filas,
       ROUND(COUNT(DISTINCT vehicle_make) * 100.0 / COUNT(*), 2) AS porcentaje_cardinalidad
FROM parties;

-- 6. county_location
SELECT 'county_location' AS columna,
       COUNT(DISTINCT county_location) AS valores_unicos,
       COUNT(*) AS total_filas,
       ROUND(COUNT(DISTINCT county_location) * 100.0 / COUNT(*), 2) AS porcentaje_cardinalidad
FROM collisions;