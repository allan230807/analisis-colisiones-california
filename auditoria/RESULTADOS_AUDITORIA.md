# Resultados de Auditoría - Fase 1: Diseño Conceptual del Esquema Estrella

**Fecha:** 2026-10-04  
**Base de datos:** SWITRS California 2016-2021  
**Objetivo:** Validar empíricamente las decisiones de diseño del modelo dimensional

---

## 1. Cardinalidad de Dimensiones (Script 01)

| Dimensión | Cardinalidad | Tipo Propuesto | Validación |
|---|---|---|---|
| dim_clima | 7 | SMALLINT | Correcto |
| dim_iluminacion | 6 | SMALLINT | Correcto |
| dim_superficie | 7 | SMALLINT | Correcto |
| dim_condicion_vial | 8 | SMALLINT | Correcto |
| dim_dispositivo_control | 9 | SMALLINT | Correcto |
| dim_factor_colision | 6 | SMALLINT | Correcto |
| dim_categoria_pcf | 25 | SMALLINT | Correcto |
| dim_tipo_colision | 11 | SMALLINT | Correcto |
| dim_tipo_vehiculo | 17 | SMALLINT | Correcto |
| dim_severidad | 6 | SMALLINT | Correcto |
| dim_alcohol | 2 | SMALLINT | Correcto |
| dim_tipo_parte | 6 | SMALLINT | Correcto |
| dim_sobriedad | 6 | SMALLINT | Correcto |
| dim_direccion_viaje | 4 | SMALLINT | Correcto |
| dim_raza | 5 | SMALLINT | Correcto |
| dim_rol_victima | 6 | SMALLINT | Correcto |
| dim_posicion_asiento | 13 | SMALLINT | Correcto |
| dim_equipamiento_seguridad | 32 | SMALLINT | Correcto |
| dim_grado_lesion | 8 | SMALLINT | Correcto |
| dim_sexo | 3 | SMALLINT | Correcto |

### Interpretación

**Hallazgo principal:** Todas las dimensiones propuestas tienen cardinalidad menor a 32,767, con un máximo de 32 valores distintos (dim_equipamiento_seguridad). Esto valida el uso de SMALLINT para todas las FKs.

**Qué significa esto en la práctica:**
- **Almacenamiento optimizado:** SMALLINT usa 2 bytes por valor. En una tabla de 9.4M filas con 10 FKs, el ahorro vs INTEGER es de ~188 MB por tabla.
- **JOINs más rápidos:** Las dimensiones son pequeñas (máximo 32 filas), por lo que los JOINs son casi instantáneos.
- **Mantenimiento simple:** Las dimensiones se pueden cargar en memoria sin preocupación.

**Qué se puede hacer con estos resultados:**
1. **Confirmar el diseño:** Las 20 dimensiones propuestas son viables como tablas dimensionales.
2. **Optimizar el ETL:** Al ser tan pequeñas, las dimensiones se pueden cargar una vez y reutilizar en múltiples procesos.
3. **Planificar el almacenamiento:** Se puede estimar el tamaño total del Data Lake con precisión.

---

## 2. Volumen de Datos (Script 02)

| Tabla | Filas | Tipo PK Propuesto | Validación |
|---|---|---|---|
| fact_colisiones | 9,424,334 | INTEGER | Correcto |
| fact_partes_colision | 18,669,166 | INTEGER | Correcto |
| fact_victimas_colision | 9,639,334 | INTEGER | Correcto |
| dim_fecha | 7,459 | SMALLINT | Correcto |

### Interpretación

**Hallazgo principal:** Las tablas de hechos tienen entre 9.4M y 18.7M filas, superando ampliamente el límite de SMALLINT (32,767). Las dimensiones tienen menos de 10,000 filas.

**Qué significa esto en la práctica:**
- **INTEGER es obligatorio para PKs:** Un SMALLINT no puede almacenar más de 32,767 valores únicos. Con 9.4M filas, se necesita INTEGER (4 bytes, hasta 2,147M).
- **Las dimensiones son pequeñas:** dim_fecha con 7,459 filas es la dimensión más grande, pero aún así es manejable con SMALLINT.
- **El volumen justifica la normalización:** Con millones de filas, la normalización en dimensiones evita la redundancia de texto.

**Qué se puede hacer con estos resultados:**
1. **Dimensionar el sistema:** Se puede estimar que el Data Lake tendrá ~30M filas totales, requiriendo particionamiento.
2. **Planificar la partición:** Las tablas de hechos deben particionarse por año (6 archivos por tabla) para optimizar consultas.
3. **Estimar tiempos de carga:** Con 30M filas, el ETL tardará varios minutos, requiriendo un proceso optimizado.

---

## 3. Nulos e Inconsistencias (Script 03)

### collisions (9,424,334 filas)
| Columna | Nulos | % Nulos | Recomendación |
|---|---|---|---|
| case_id | 0 | 0% | NOT NULL |
| collision_date | 0 | 0% | NOT NULL |
| collision_time | 82,415 | 0.87% | Permitir NULL |
| weather_1 | 45,221 | 0.48% | Permitir NULL |
| lighting | 53,308 | 0.57% | Permitir NULL |
| road_surface | 81,164 | 0.86% | Permitir NULL |
| road_condition_1 | 78,298 | 0.83% | Permitir NULL |
| control_device | 57,544 | 0.61% | Permitir NULL |
| primary_collision_factor | 56,115 | 0.60% | Permitir NULL |
| pcf_violation_category | 156,803 | 1.66% | Permitir NULL |
| type_of_collision | 75,985 | 0.81% | Permitir NULL |
| motor_vehicle_involved_with | 48,918 | 0.52% | Permitir NULL |
| collision_severity | 0 | 0% | NOT NULL |
| alcohol_involved | 8,479,870 | 89.98% | Permitir NULL |
| killed_victims | 2,052 | 0.02% | NOT NULL |
| injured_victims | 2,486 | 0.03% | NOT NULL |
| party_count | 7 | 0.00% | NOT NULL |
| latitude | 6,730,338 | 71.41% | Permitir NULL |
| longitude | 6,730,338 | 71.41% | Permitir NULL |

### parties (18,669,166 filas)
| Columna | Nulos | % Nulos | Recomendación |
|---|---|---|---|
| case_id | 0 | 0% | NOT NULL |
| party_number | 0 | 0% | NOT NULL |
| party_type | 43,867 | 0.24% | Permitir NULL |
| at_fault | 0 | 0% | NOT NULL |
| party_sex | 2,499,043 | 13.39% | Permitir NULL |
| party_age | 2,914,711 | 15.61% | Permitir NULL |
| party_sobriety | 556,035 | 2.98% | Permitir NULL |
| direction_of_travel | 525,943 | 2.82% | Permitir NULL |
| vehicle_year | 1,777,184 | 9.52% | Permitir NULL |
| statewide_vehicle_type | 2,103,013 | 11.27% | Permitir NULL |
| party_race | 4,374,129 | 23.43% | Permitir NULL |

### victims (9,639,334 filas)
| Columna | Nulos | % Nulos | Recomendación |
|---|---|---|---|
| case_id | 0 | 0% | NOT NULL |
| party_number | 0 | 0% | NOT NULL |
| victim_role | 13 | 0.00% | NOT NULL |
| victim_sex | 239,319 | 2.48% | Permitir NULL |
| victim_age | 322,754 | 3.35% | Permitir NULL |
| victim_degree_of_injury | 0 | 0% | NOT NULL |
| victim_seating_position | 19,477 | 0.20% | Permitir NULL |
| victim_safety_equipment_1 | 550,554 | 5.71% | Permitir NULL |
| victim_ejected | 42,865 | 0.44% | Permitir NULL |

### Interpretación

**Hallazgo principal:** Las columnas clave (case_id, party_number, collision_severity, victim_degree_of_injury) tienen 0% de nulos, lo que las hace candidatas ideales para constraints NOT NULL. Sin embargo, hay columnas con porcentajes significativos de nulos que requieren atención.

**Qué significa esto en la práctica:**
- **Integridad de las FKs garantizada:** Las columnas que serán FKs (case_id, party_number) no tienen nulos, por lo que la integridad referencial está asegurada.
- **Nulos en atributos descriptivos:** Columnas como party_age (15.61%), party_race (23.43%) y alcohol_involved (89.98%) tienen muchos nulos. Esto es normal en datos administrativos: no toda la información se registra en todos los casos.
- **Latitud/Longitud con 71% nulos:** Esto indica que solo el 29% de las colisiones tienen coordenadas geográficas. Esto debe manejarse en el diseño (tabla separada 1:0..1).

**Qué se puede hacer con estos resultados:**
1. **Definir constraints NOT NULL:** Solo en columnas con 0% nulos (case_id, party_number, collision_severity, victim_degree_of_injury, victim_role).
2. **Estrategia para nulos:** Decidir si los nulos se convierten en 0 (para medidas) o se mantienen como NULL (para atributos descriptivos).
3. **Tabla de geolocalización:** Crear una tabla separada para coordenadas, ya que el 71% de nulos en latitud/longitud inflaría la tabla principal.
4. **Análisis de sesgo:** Los nulos pueden indicar sesgo en la recolección de datos. Por ejemplo, si party_race tiene 23% de nulos, ¿es aleatorio o sistemático?

---

## 4. Duplicados en Dimensiones (Script 04)

| Dimensión | Valor Duplicado | Cantidad | Acción Requerida |
|---|---|---|---|
| dim_factor_colision | "unknown" | 2 | Eliminar duplicado |
| dim_categoria_pcf | "unknown" | 2 | Eliminar duplicado |

### Interpretación

**Hallazgo principal:** Se encontraron 2 dimensiones con valores "unknown" duplicados. Esto es un error de calidad de datos que debe corregirse antes de crear las FKs.

**Qué significa esto en la práctica:**
- **Riesgo de ambigüedad:** Si dos filas tienen el mismo valor "unknown", un JOIN podría devolver resultados incorrectos o ambiguos.
- **Integridad de las FKs en riesgo:** Si una FK apunta a un valor duplicado, no se sabe cuál es la fila correcta.
- **Error de carga:** Esto sugiere que las dimensiones se cargaron sin validación de unicidad.

**Qué se puede hacer con estos resultados:**
1. **Corregir antes del ETL:** Eliminar los duplicados en dim_factor_colision y dim_categoria_pcf antes de crear las FKs.
2. **Agregar validación:** En el script de población de dimensiones, agregar una verificación de unicidad.
3. **Investigar el origen:** Determinar por qué hay valores "unknown" duplicados (¿error de carga? ¿dos fuentes diferentes?).

---

## 5. Textos Repetitivos / Atributos Degenerados (Script 05)

| Columna | Valores Únicos | % Cardinalidad | Recomendación |
|---|---|---|---|
| primary_road | 333,864 | 3.54% | Atributo degenerado |
| secondary_road | 504,779 | 5.36% | Atributo degenerado |
| officer_id | 110,202 | 1.17% | Atributo degenerado |
| reporting_district | 38,475 | 0.41% | Atributo degenerado |
| vehicle_make | 6,292 | 0.03% | Atributo degenerado |
| county_location | 58 | 0.0006% | Dimensión factible |

### Interpretación

**Hallazgo principal:** Las columnas con alta cardinalidad (primary_road, secondary_road, officer_id, reporting_district, vehicle_make) deben permanecer como atributos degenerados. Sin embargo, county_location tiene solo 58 valores únicos, lo que la hace candidata a ser una dimensión.

**Qué significa esto en la práctica:**
- **Atributos degenerados:** No tienen una dimensión asociada porque su cardinalidad es demasiado alta. Se almacenan directamente en la tabla de hechos.
- **Nueva dimensión factible:** county_location (58 condados) es una dimensión ideal: tiene cardinalidad baja, atributos descriptivos (nombre del county) y se usa en análisis geográficos.
- **Optimización del diseño:** Al mover county_location a una dimensión, se reduce el tamaño de la tabla de hechos y se permite análisis por región.

**Qué se puede hacer con estos resultados:**
1. **Crear dim_county:** Nueva dimensión con los 58 condados de California, incluyendo nombre y región.
2. **Mantener atributos degenerados:** primary_road, secondary_road, officer_id, reporting_district y vehicle_make se quedan como texto en la tabla de hechos.
3. **Reducir tamaño de la tabla:** Al mover county_location a una dimensión, se elimina la redundancia de texto en 9.4M filas.

---

## 6. Integridad Referencial (Script 06)

| Relación | Total Registros | Huérfanos | % Integridad |
|---|---|---|---|
| parties -> collisions | 18,669,166 | 0 | 100% |
| victims -> collisions | 9,639,334 | 0 | 100% |
| victims -> parties | 9,639,334 | 0 | 100% |
| case_ids (duplicados) | 9,424,334 | 0 | 100% |

### Interpretación

**Hallazgo principal:** La integridad referencial es perfecta. No hay huérfanos en ninguna relación, lo que significa que todas las FKs tienen su correspondiente PK.

**Qué significa esto en la práctica:**
- **Calidad de datos excelente:** La fuente SWITRS mantiene una integridad referencial perfecta, lo que facilita el proceso de carga.
- **No se necesita limpieza:** No hay que eliminar registros huérfanos o corregir FKs rotas.
- **Confianza en los datos:** Se puede confiar en que las relaciones entre tablas son correctas.

**Qué se puede hacer con estos resultados:**
1. **Cargar sin validación adicional:** No se necesita un paso de limpieza de huérfanos en el ETL.
2. **Garantizar integridad en el modelo:** Las FKs en el esquema estrella estarán garantizadas por la fuente.
3. **Enfocarse en transformaciones:** El ETL puede enfocarse en transformaciones (T1-T7) en lugar de limpieza.

---

## 7. Distribución de Medidas Aditivas (Script 07)

| Medida | Mínimo | Máximo | Promedio | Total | Tipo Propuesto |
|---|---|---|---|---|---|
| killed_victims | 0 | 13 | 0.008 | 73,007 | SMALLINT |
| injured_victims | 0 | 105 | 0.56 | 5,290,670 | SMALLINT |
| party_count | 0 | 92 | 1.98 | 18,669,153 | SMALLINT |
| severe_injury_count | 0 | 28 | 0.028 | 261,122 | SMALLINT |
| party_age | 0 | 125 | 38.5 | 606,551,999 | SMALLINT |
| victim_age | 0 | 999 | 31.1 | 289,878,809 | SMALLINT |
| vehicle_year | 0 | 8744 | 2001.6 | 33,810,806,688 | SMALLINT |

### Interpretación

**Hallazgo principal:** Todas las medidas aditivas tienen rangos acotados. El máximo valor es 8744 (vehicle_year), muy por debajo del límite de SMALLINT (32,767).

**Qué significa esto en la práctica:**
- **SMALLINT es suficiente:** Todas las medidas pueden almacenarse en SMALLINT (2 bytes), ahorrando espacio vs INTEGER (4 bytes).
- **vehicle_year requiere atención:** El valor máximo es 8744, lo que sugiere que hay valores atípicos (años futuros o erróneos). Esto debe investigarse.
- **victim_age con valor 999:** El valor máximo de 999 sugiere un código de "desconocido" en lugar de una edad real. Esto debe documentarse.

**Qué se puede hacer con estos resultados:**
1. **Confirmar SMALLINT:** Todas las medidas aditivas pueden usar SMALLINT.
2. **Investigar valores atípicos:** vehicle_year con valor 8744 y victim_age con valor 999 deben ser revisados.
3. **Documentar códigos especiales:** Si 999 significa "desconocido", debe documentarse en el diccionario de datos.

---

## 8. Resumen Ejecutivo de Validaciones

### Decisiones de Diseño Validadas

| Decisión | Estado | Evidencia | Impacto |
|---|---|---|---|
| SMALLINT para FKs | Validado | Cardinalidad máxima: 32 | Ahorro de ~188 MB por tabla |
| INTEGER para PKs hechos | Validado | Volumen: 9M-18M filas | Necesario para PKs surrogate |
| Atributos degenerados | Validado | primary_road, secondary_road, officer_id, vehicle_make | Evita dimensiones inútiles |
| Dimensiones confirmadas | Validado | Todas tienen cardinalidad < 32,767 | Diseño viable |
| Integridad referencial | Validado | 0 huérfanos en todas las relaciones | No se necesita limpieza |
| Medidas aditivas SMALLINT | Validado | Rangos acotados (0-8744) | Ahorro de almacenamiento |

### Hallazgos Adicionales

1. **Nueva dimensión factible:** `dim_county` (58 valores únicos) → Permite análisis geográficos por región.
2. **Duplicados a corregir:** dim_factor_colision y dim_categoria_pcf tienen "unknown" duplicado → Debe corregirse antes de crear FKs.
3. **Nulos significativos:** alcohol_involved (90%), latitude/longitude (71%), party_race (23%) → Requiere estrategia de manejo de nulos.
4. **Valores atípicos:** vehicle_year (8744), victim_age (999) → Deben investigarse y documentarse.
5. **case_ids:** Tabla auxiliar sin duplicados → Puede eliminarse después del ETL.

### Recomendaciones para Fase 2

1. **Crear `dim_county`:** Nueva dimensión con los 58 condados de California, incluyendo nombre y región.
2. **Corregir duplicados:** Eliminar los valores "unknown" duplicados en dim_factor_colision y dim_categoria_pcf.
3. **Definir constraints NOT NULL:** Solo en columnas con 0% nulos (case_id, party_number, collision_severity, victim_degree_of_injury, victim_role).
4. **Estrategia para nulos:** Decidir si los nulos se convierten en 0 (para medidas) o se mantienen como NULL (para atributos descriptivos).
5. **Investigar valores atípicos:** vehicle_year (8744) y victim_age (999) deben ser revisados y documentados.
6. **Tabla de geolocalización:** Crear una tabla separada para coordenadas (71% de nulos en latitud/longitud).

---