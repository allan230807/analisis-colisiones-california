"""
01_cardinalidad_dimensiones.sql
===============================================================================
AUDITORÍA DE CARDINALIDAD DE DIMENSIONES PROPUESTAS
Investigación: Perfiles de riesgo en colisiones de tránsito en California,
2016-2021.
Escuela de Estadística y Ciencias Actuariales (EECA-UCV) — Computación II
===============================================================================

CONTEXTO
--------
Este script valida empíricamente que las dimensiones propuestas en el diseño
del esquema estrella tienen cardinalidad acotada (< 32,767 valores distintos),
lo que justifica el uso de SMALLINT como tipo de dato para las llaves foráneas.

La cardinalidad es la decisión de diseño más temprana y más barata de tomar,
pero también la más costosa de cambiar después. Si una dimensión tiene alta
cardinalidad, debería ser un atributo degenerado en lugar de una dimensión.

Los resultados de este script se documentan en RESULTADOS_AUDITORIA.md.
"""

-- 1. Clima (dim_clima)
SELECT 'dim_clima' AS dimension, COUNT(DISTINCT weather_1) AS cardinalidad
FROM collisions;

-- 2. Iluminación (dim_iluminacion)
SELECT 'dim_iluminacion' AS dimension, COUNT(DISTINCT lighting) AS cardinalidad
FROM collisions;

-- 3. Superficie vial (dim_superficie)
SELECT 'dim_superficie' AS dimension, COUNT(DISTINCT road_surface) AS cardinalidad
FROM collisions;

-- 4. Condición vial (dim_condicion_vial)
SELECT 'dim_condicion_vial' AS dimension, COUNT(DISTINCT road_condition_1) AS cardinalidad
FROM collisions;

-- 5. Dispositivo de control (dim_dispositivo_control)
SELECT 'dim_dispositivo_control' AS dimension, COUNT(DISTINCT control_device) AS cardinalidad
FROM collisions;

-- 6. Factor de colisión (dim_factor_colision)
SELECT 'dim_factor_colision' AS dimension, COUNT(DISTINCT primary_collision_factor) AS cardinalidad
FROM collisions;

-- 7. Categoría PCF (dim_categoria_pcf)
SELECT 'dim_categoria_pcf' AS dimension, COUNT(DISTINCT pcf_violation_category) AS cardinalidad
FROM collisions;

-- 8. Tipo de colisión (dim_tipo_colision)
SELECT 'dim_tipo_colision' AS dimension, COUNT(DISTINCT type_of_collision) AS cardinalidad
FROM collisions;

-- 9. Tipo de vehículo involucrado (dim_tipo_vehiculo)
SELECT 'dim_tipo_vehiculo' AS dimension, COUNT(DISTINCT motor_vehicle_involved_with) AS cardinalidad
FROM collisions;

-- 10. Severidad (dim_severidad)
SELECT 'dim_severidad' AS dimension, COUNT(DISTINCT collision_severity) AS cardinalidad
FROM collisions;

-- 11. Alcohol involucrado (dim_alcohol)
SELECT 'dim_alcohol' AS dimension, COUNT(DISTINCT alcohol_involved) AS cardinalidad
FROM collisions;

-- 12. Tipo de parte (dim_tipo_parte)
SELECT 'dim_tipo_parte' AS dimension, COUNT(DISTINCT party_type) AS cardinalidad
FROM parties;

-- 13. Sobriedad (dim_sobriedad)
SELECT 'dim_sobriedad' AS dimension, COUNT(DISTINCT party_sobriety) AS cardinalidad
FROM parties;

-- 14. Dirección de viaje (dim_direccion_viaje)
SELECT 'dim_direccion_viaje' AS dimension, COUNT(DISTINCT direction_of_travel) AS cardinalidad
FROM parties;

-- 15. Raza (dim_raza)
SELECT 'dim_raza' AS dimension, COUNT(DISTINCT party_race) AS cardinalidad
FROM parties;

-- 16. Rol de víctima (dim_rol_victima)
SELECT 'dim_rol_victima' AS dimension, COUNT(DISTINCT victim_role) AS cardinalidad
FROM victims;

-- 17. Posición de asiento (dim_posicion_asiento)
SELECT 'dim_posicion_asiento' AS dimension, COUNT(DISTINCT victim_seating_position) AS cardinalidad
FROM victims;

-- 18. Equipamiento de seguridad (dim_equipamiento_seguridad)
SELECT 'dim_equipamiento_seguridad' AS dimension, COUNT(DISTINCT victim_safety_equipment_1) AS cardinalidad
FROM victims;

-- 19. Grado de lesión (dim_grado_lesion)
SELECT 'dim_grado_lesion' AS dimension, COUNT(DISTINCT victim_degree_of_injury) AS cardinalidad
FROM victims;

-- 20. Sexo (dim_sexo)
SELECT 'dim_sexo' AS dimension, COUNT(DISTINCT party_sex) AS cardinalidad
FROM parties;
