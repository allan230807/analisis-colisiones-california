"""
07_distribucion_medidas.sql
===============================================================================
AUDITORÍA DE DISTRIBUCIÓN DE MEDIDAS ADITIVAS
Investigación: Perfiles de riesgo en colisiones de tránsito en California,
2016-2021.
Escuela de Estadística y Ciencias Actuariales (EECA-UCV) — Computación II
===============================================================================

Este script verifica el rango de valores de las medidas aditivas para confirmar
que SMALLINT es suficiente como tipo de dato.

Las medidas aditivas son valores numéricos que se pueden sumar (killed_victims,
injured_victims, party_count). Su rango determina el tipo de dato: si el máximo
es menor que 32,767, SMALLINT es suficiente.

Los resultados de este script se documentan en RESULTADOS_AUDITORIA.md.
"""

-- 1. Distribución de killed_victims
SELECT 'killed_victims' AS medida,
       MIN(killed_victims) AS minimo,
       MAX(killed_victims) AS maximo,
       AVG(killed_victims) AS promedio,
       SUM(killed_victims) AS total
FROM collisions;

-- 2. Distribución de injured_victims
SELECT 'injured_victims' AS medida,
       MIN(injured_victims) AS minimo,
       MAX(injured_victims) AS maximo,
       AVG(injured_victims) AS promedio,
       SUM(injured_victims) AS total
FROM collisions;

-- 3. Distribución de party_count
SELECT 'party_count' AS medida,
       MIN(party_count) AS minimo,
       MAX(party_count) AS maximo,
       AVG(party_count) AS promedio,
       SUM(party_count) AS total
FROM collisions;

-- 4. Distribución de severe_injury_count
SELECT 'severe_injury_count' AS medida,
       MIN(severe_injury_count) AS minimo,
       MAX(severe_injury_count) AS maximo,
       AVG(severe_injury_count) AS promedio,
       SUM(severe_injury_count) AS total
FROM collisions;

-- 5. Distribución de party_age
SELECT 'party_age' AS medida,
       MIN(party_age) AS minimo,
       MAX(party_age) AS maximo,
       AVG(party_age) AS promedio,
       SUM(party_age) AS total
FROM parties;

-- 6. Distribución de victim_age
SELECT 'victim_age' AS medida,
       MIN(victim_age) AS minimo,
       MAX(victim_age) AS maximo,
       AVG(victim_age) AS promedio,
       SUM(victim_age) AS total
FROM victims;

-- 7. Distribución de vehicle_year
SELECT 'vehicle_year' AS medida,
       MIN(vehicle_year) AS minimo,
       MAX(vehicle_year) AS maximo,
       AVG(vehicle_year) AS promedio,
       SUM(vehicle_year) AS total
FROM parties;
