"""
02_volumen_datos.sql
===============================================================================
AUDITORÍA DE VOLUMEN DE DATOS EN TABLAS DE HECHOS
Investigación: Perfiles de riesgo en colisiones de tránsito en California,
2016-2021.
Escuela de Estadística y Ciencias Actuariales (EECA-UCV) — Computación II
===============================================================================

Este script verifica que las tablas de hechos requieren INTEGER (millones de
filas) para sus PKs surrogate, mientras que las dimensiones pueden usar SMALLINT.

El volumen de datos es un factor crítico en la elección del tipo de dato: un
INTEGER permite hasta 2,147,483,647 registros, mientras que SMALLINT solo llega
a 32,767. Usar INTEGER para todo desperdicia almacenamiento y ralentiza los JOINs.

Los resultados de este script se documentan en RESULTADOS_AUDITORIA.md.
"""

-- 1. Volumen de colisiones (fact_colisiones)
SELECT 'fact_colisiones' AS tabla, COUNT(*) AS total_filas
FROM collisions;

-- 2. Volumen de partes (fact_partes_colision)
SELECT 'fact_partes_colision' AS tabla, COUNT(*) AS total_filas
FROM parties;

-- 3. Volumen de víctimas (fact_victimas_colision)
SELECT 'fact_victimas_colision' AS tabla, COUNT(*) AS total_filas
FROM victims;

-- 4. Volumen de fechas únicas (dim_fecha)
SELECT 'dim_fecha' AS tabla, COUNT(DISTINCT collision_date) AS total_filas
FROM collisions;
