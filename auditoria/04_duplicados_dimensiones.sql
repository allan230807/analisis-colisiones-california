"""
04_duplicados_dimensiones.sql
===============================================================================
AUDITORÍA DE DUPLICADOS EN DIMENSIONES EXISTENTES
Investigación: Perfiles de riesgo en colisiones de tránsito en California,
2016-2021.
Escuela de Estadística y Ciencias Actuariales (EECA-UCV) — Computación II
===============================================================================

Este script verifica que las dimensiones existentes no tengan duplicados en sus
atributos descriptivos, lo que garantiza la integridad de las FKs.

Los duplicados en dimensiones son críticos porque pueden causar ambigüedad en
los JOINs: si dos filas tienen el mismo valor, no se sabe cuál es la correcta.

Hallazgo: Se encontraron duplicados en dim_factor_colision y dim_categoria_pcf
con el valor "unknown".

Los resultados de este script se documentan en RESULTADOS_AUDITORIA.md.
"""

-- 1. Verificar duplicados en dim_severidad
SELECT 'dim_severidad' AS dimension, codigo_original, COUNT(*) AS total
FROM dim_severidad
GROUP BY codigo_original
HAVING COUNT(*) > 1;

-- 2. Verificar duplicados en dim_grado_lesion
SELECT 'dim_grado_lesion' AS dimension, codigo_original, COUNT(*) AS total
FROM dim_grado_lesion
GROUP BY codigo_original
HAVING COUNT(*) > 1;

-- 3. Verificar duplicados en dim_tipo_vehiculo
SELECT 'dim_tipo_vehiculo' AS dimension, codigo_original, COUNT(*) AS total
FROM dim_tipo_vehiculo
GROUP BY codigo_original
HAVING COUNT(*) > 1;

-- 4. Verificar duplicados en dim_sexo
SELECT 'dim_sexo' AS dimension, codigo, COUNT(*) AS total
FROM dim_sexo
GROUP BY codigo
HAVING COUNT(*) > 1;

-- 5. Verificar duplicados en dim_grupo_edad
SELECT 'dim_grupo_edad' AS dimension, etiqueta, COUNT(*) AS total
FROM dim_grupo_edad
GROUP BY etiqueta
HAVING COUNT(*) > 1;

-- 6. Verificar duplicados en dim_tipo_colision
SELECT 'dim_tipo_colision' AS dimension, descripcion, COUNT(*) AS total
FROM dim_tipo_colision
GROUP BY descripcion
HAVING COUNT(*) > 1;

-- 7. Verificar duplicados en dim_clima
SELECT 'dim_clima' AS dimension, descripcion, COUNT(*) AS total
FROM dim_clima
GROUP BY descripcion
HAVING COUNT(*) > 1;

-- 8. Verificar duplicados en dim_iluminacion
SELECT 'dim_iluminacion' AS dimension, descripcion, COUNT(*) AS total
FROM dim_iluminacion
GROUP BY descripcion
HAVING COUNT(*) > 1;

-- 9. Verificar duplicados en dim_superficie
SELECT 'dim_superficie' AS dimension, descripcion, COUNT(*) AS total
FROM dim_superficie
GROUP BY descripcion
HAVING COUNT(*) > 1;

-- 10. Verificar duplicados en dim_condicion_vial
SELECT 'dim_condicion_vial' AS dimension, descripcion, COUNT(*) AS total
FROM dim_condicion_vial
GROUP BY descripcion
HAVING COUNT(*) > 1;

-- 11. Verificar duplicados en dim_dispositivo_control
SELECT 'dim_dispositivo_control' AS dimension, descripcion, COUNT(*) AS total
FROM dim_dispositivo_control
GROUP BY descripcion
HAVING COUNT(*) > 1;

-- 12. Verificar duplicados en dim_factor_colision
SELECT 'dim_factor_colision' AS dimension, descripcion, COUNT(*) AS total
FROM dim_factor_colision
GROUP BY descripcion
HAVING COUNT(*) > 1;

-- 13. Verificar duplicados en dim_categoria_pcf
SELECT 'dim_categoria_pcf' AS dimension, descripcion, COUNT(*) AS total
FROM dim_categoria_pcf
GROUP BY descripcion
HAVING COUNT(*) > 1;

-- 14. Verificar duplicados en dim_fecha
SELECT 'dim_fecha' AS dimension, fecha, COUNT(*) AS total
FROM dim_fecha
GROUP BY fecha
HAVING COUNT(*) > 1;
