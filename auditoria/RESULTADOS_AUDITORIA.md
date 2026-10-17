# Resultados de Auditoría Integral — Calidad, Estructura e Integridad de Datos SWITRS (2010–2019)

**Proyecto:** Perfiles de riesgo en colisiones de tránsito — California (2010–2019)  
**Institución:** Escuela de Estadística y Ciencias Actuariales (EECA-UCV) — Cátedra de Computación II  
**Versión de informe:** 2.1 (Unificación decenal 2010–2019 y evidencia para la normalización)  
**Fecha de corte de auditoría:** 2026-10-17  

---

## A. Alcance y Entorno Técnico

### 1. Objetivo de la Auditoría
Evaluar de forma empírica y reproducible la calidad, completitud, estructura, semántica e integridad referencial de los registros de siniestralidad vial en California, garantizando una base técnica y metodológicamente sólida antes de iniciar la normalización a Tercera Forma Normal (3FN) y la construcción del modelo dimensional en estrella para Power BI.

### 2. Período Estudiado
- **Intervalo:** 1 de enero de 2010 al 31 de diciembre de 2019 (`collision_date >= '2010-01-01' AND collision_date < '2020-01-01'`).
- **Justificación decenal:** Cubre los 10 años exactos de la serie histórica de SWITRS analizada en el reporte anual oficial de la *California Highway Patrol* (CHP), permitiendo estudiar tendencias estructurales previas a las alteraciones de movilidad derivadas de la pandemia por COVID-19.

### 3. Fuente de Datos y Motor de Ejecución
- **Fuente primaria:** Base de datos relacional SQLite oficial de SWITRS (`data/raw/switrs.sqlite`), con un volumen global de 9.424.334 colisiones (2001–2021).
- **Motor analítico:** **DuckDB** mediante la extensión `sqlite` (`ATTACH 'data/raw/switrs.sqlite' AS sw (TYPE sqlite, READ_ONLY)`).
- **Justificación técnica:** El procesamiento directo en SQLite sobre tablas de más de 18 millones de filas genera *timeouts* y bloqueos: la fuente no tiene índices sobre `case_id` y almacena casi todo como `TEXT`. DuckDB ejecuta escaneos columnares con paralelismo vectorial sin modificar la fuente cruda.
- **Peso y margen de optimización:** La fuente completa (2001–2021) ocupa **9,9 GB**. El mismo período 2010–2019 copiado sin tipar ni normalizar a formato columnar DuckDB ocupa **539 MB**; el tipado y la eliminación de columnas derivables (sección B.7) reducen aún más ese volumen en la Fase 2.

### 4. Tablas Analizadas
| Tabla Fuente | Filas Globales (2001–2021) | Filas Período (2010–2019) | Grano de la Información |
|---|---|---|---|
| `sw.collisions` | 9.424.334 | **4.368.293** | Un registro por evento de colisión (`case_id`). |
| `sw.parties` | 18.669.166 | **8.688.142** | Un registro por actor/vehículo involucrado en el siniestro. |
| `sw.victims` | 9.639.334 | **4.280.801** | Un registro por persona reportada como víctima (conductor, pasajero, peatón o ciclista), sea fallecida, lesionada o ilesa (`no injury`). |
| `sw.case_ids` | 9.424.334 | **4.368.293** | Catálogo índice de identificadores únicos de colisión. |

---

## B. Resultados por Dimensión de Calidad

### 1. Cobertura Temporal y Estacionalidad (02_volumen_temporal.sql)
- **Días del calendario:** El período decenal contempla **3.652 días cronológicos** (incluyendo los años bisiestos 2012 y 2016).
- **Días con registro activo:** **3.652 días** (100,0% de cobertura; **0 días en cero**). A diferencia de datos posteriores a 2020, la década 2010–2019 no presenta truncamientos ni ventanas temporales sin reportes.
- **Intensidad diaria:** Media de **1.196,1 colisiones/día** sobre calendario. Mínimo registrado: 556 colisiones; pico máximo diario: 2.028 colisiones.
- **Distribución anual:**
  - 2010: 416.490 colisiones (9,53%) | 817.529 partes | 448.742 víctimas
  - 2011: 403.629 colisiones (9,24%) | 796.094 partes | 443.290 víctimas
  - 2012: 395.901 colisiones (9,06%) | 779.800 partes | 434.963 víctimas
  - 2013: 383.840 colisiones (8,79%) | 763.081 partes | 424.852 víctimas
  - 2014: 399.565 colisiones (9,15%) | 792.515 partes | 437.961 víctimas
  - 2015: 438.169 colisiones (10,03%) | 871.647 partes | 481.291 víctimas
  - 2016: 491.619 colisiones (11,25%) | 982.363 partes | 529.156 víctimas
  - 2017: 486.432 colisiones (11,14%) | 975.846 partes | 366.353 víctimas
  - 2018: 482.296 colisiones (11,04%) | 967.685 partes | 361.195 víctimas
  - 2019: 470.352 colisiones (10,77%) | 941.582 partes | 352.998 víctimas
- **Advertencia sobre víctimas:** la caída de víctimas desde 2017 (de 529.156 en 2016 a 366.353 en 2017) no refleja menos lesionados: se debe a que la fuente registra muchas menos víctimas ilesas desde ese año (ver sección B.9).
- **Patrón semanal:** Viernes es el día con mayor volumen (714.156 siniestros; 16,35%), mientras que el domingo registra la menor frecuencia (508.014; 11,63%).
- **Patrón horario:** Horas pico de la tarde entre las 15:00 y las 18:30 (superando 25.000 colisiones por tramo horario). El 0,91% de los registros presenta `collision_time` nulo.

### 2. Catálogos y Factores de Entorno (01_catalogos_frecuencias.sql)
- **Severidad del evento (`collision_severity`):**
  - *Property damage only* (Solo daños materiales): 2.591.057 (59,31%)
  - *Pain* (Queja de dolor): 1.102.846 (25,25%)
  - *Other injury* (Otra lesión visible no grave): 535.313 (12,25%)
  - *Severe injury* (Lesión grave): 108.209 (2,48%)
  - *Fatal* (Colisión mortal): 30.867 (0,71%)
  - *Código basura `N`:* 1 caso (0,00%). Se canaliza a `id=0 Sin clasificar`.
- **Condiciones meteorológicas (`weather_1`):**
  - Despejado (*clear*): 3.650.012 (83,56%)
  - Nublado (*cloudy*): 530.657 (12,15%)
  - Lluvia (*raining*): 146.417 (3,35%)
  - Niebla (*fog*): 14.296 (0,33%)
  - Nieve (*snowing*): 5.260 (0,12%)
  - Viento / Otro (*wind/other*): 6.256 (0,14%)
  - Nulo (*NULL*): 15.395 (0,35%)
- **Iluminación (`lighting`):**
  - Luz de día (*daylight*): 2.886.856 (66,09%)
  - Oscuridad con alumbrado funcionando: 940.764 (21,54%)
  - Oscuridad sin alumbrado: 355.471 (8,14%)
  - Amanecer / Atardecer (*dusk/dawn*): 154.606 (3,54%)
  - Alumbrado defectuoso: 10.801 (0,25%)
  - Nulo (*NULL*): 19.795 (0,45%)
- **Distribución geográfica:** Los 58 condados de California están presentes. Los 3 condados principales concentran más del 40% del volumen estatal: Los Angeles (1.205.803; 27,60%), Orange (335.798; 7,69%) y San Diego (308.297; 7,06%).

### 3. Valores Faltantes y Tratamiento Semántico (03_nulos_semantica.sql)
- **Comportamiento del indicador de Alcohol (`alcohol_involved`):**
  - En la base cruda, `alcohol_involved` solo contiene dos estados: `1` (440.917 colisiones; 10,09%) y `NULL` (3.927.376 colisiones; 89,91%). **No existe el valor 0 en la fuente.**
  - *Regla metodológica:* En el formulario policial CHP 555, el oficial marca la casilla únicamente ante evidencia flagrante o prueba positiva. La ausencia de marca (`NULL`) significa que no se reportó o no se practicó prueba, **no una prueba negativa de sobriedad**. No se debe colapsar a `FALSE` bajo la suposición de "sobrio verificado".
- **Georreferenciación (`latitude`, `longitude`):**
  - Par de coordenadas completo y dentro de California (lat 32°–43° N, lon -125° a -114° O): **2.159.739** (49,44%).
  - Par completo fuera de California: **0** casos.
  - Par incompleto (longitud sin latitud, lon = -37,06): **1** caso. No es un punto válido y se trata como sin coordenadas.
  - Par nulo: **2.208.553** (50,56%). Junto con el par incompleto, **2.208.554** colisiones quedan sin georreferencia.
  - *Regla metodológica:* Prohibido imputar coordenadas (centroides o ceros). Se diseña una tabla de extensión de grano `1:0..1` (`hecho_colision_geo`) y una bandera booleana `tiene_coordenadas` en el hecho principal.
- **Hora del siniestro (`collision_time`):** 39.693 nulos (0,91%). Se mantiene como hora desconocida; prohibido imputar `00:00:00` para no distorsionar las colisiones de medianoche.

### 4. Consistencia Matemática y Control Anti Fan-Out (04_fanout_rangos.sql)
La auditoría comprobó la consistencia aditiva entre las medidas escalares declaradas en `collisions` y el conteo de filas desagregadas en tablas subordinadas:

| Métrica Controlada | Valor Declarado en `collisions` | Conteo Real en Detalle (`victims`/`parties`) | Diferencia | Veredicto |
|---|---|---|---|---|
| **Víctimas mortales (`killed_victims`)** | 33.541 | 33.541 (`victim_degree_of_injury = 'killed'`) | **0** | **Consistencia exacta (100%)** |
| **Víctimas lesionadas (`injured_victims`)** | 2.491.217 | 2.491.217 (grados de lesión confirmados) | **0** | **Consistencia exacta (100%)** |
| **Víctimas con grado desconocido** | — | 0 (`unknown`) | **0** | **Sin ruido en severidad de víctimas** |
| **Conteo de partes (`party_count`)** | 8.688.140 | 8.688.142 (filas reales en `parties`) | **−2** | Concentrada en 1 sola colisión. La medida se calcula como `COUNT(*)` sobre la tabla de partes y `party_count` no se almacena (sección B.7). |

### 5. Claves Candidatas e Integridad Referencial (05_integridad_duplicados.sql)
- **Unicidad de `collisions.case_id`:** 4.368.293 identificadores únicos, **0 duplicados** y **0 nulos**. Es la clave primaria natural absoluta del hecho de colisiones.
- **Clave candidata en `parties`:** La combinación compuesta `(case_id, party_number)` presenta 8.688.142 registros y **0 duplicados**.
- **Evaluación de `parties.id` y `victims.id`:** Ninguna de las dos columnas `id` es clave. `parties.id` presenta **3 duplicados** y `victims.id` **1 duplicado** (el id 4439952 aparece en dos colisiones distintas). `victims` además carece de un número de víctima dentro de la parte, por lo que requiere una clave subrogada determinista generada en la normalización.
- **Registros huérfanos:**
  - Partes sin colisión padre (`parties -> collisions`): **0 huérfanos** (100% integridad).
  - Víctimas sin colisión padre (`victims -> collisions`): **0 huérfanos** (100% integridad).
  - Víctimas sin participante padre (`victims -> parties` vía `case_id + party_number`): **0 huérfanos**.
- **Catálogo `case_ids`:** Coincide biyectivamente con las colisiones (9.424.334 registros globales; 0 discrepancias).
- **Alerta sobre tablas `dim_*` preexistentes en SQLite:**
  - En el archivo `switrs.sqlite` existen tablas auxiliares creadas en un prototipo previo (`dim_fecha`, `dim_clima`, etc.).
  - Se verificó que `dim_fecha` solo posee 2.192 filas (período 2016–2021), resultando insuficiente para el período 2010–2019 (3.652 días requeridos).
  - Las tablas dimensionales definitivas deben generarse desde cero en la Fase 2 durante el pipeline de normalización, no heredarse del prototipo.

### 6. Rangos Numéricos y Protocolo de Cuarentena (04_fanout_rangos.sql)
- **Edad de participantes (`party_age`):** Rango crudo de 0 a 125 años. No se detectaron códigos centinela 998/999 (0 registros). Se identificaron **38 registros con edad real fuera del rango 0–110** (máximo 125). Media en rango limpio (0–110): 39,3 años.
- **Edad de víctimas (`victim_age`):** Rango crudo de 0 a 999 años. Se detectaron **48 registros con códigos centinela 998/999** y **171 registros totales fuera del rango 0–110** (los 48 centinela están incluidos en los 171; el resto son edades reales >110). Media en rango limpio: 32,4 años. Los códigos centinela no se contabilizan como edades reales extremas.
- **Año-modelo del vehículo (`vehicle_year`):** Rango válido verificado: 1900 a 2020. Se identificaron **2 registros fuera de rango, ambos con año 2021** (ninguno menor a 1900). Nulos: 869.373 registros (10,01%), asociados primordialmente a peatones, ciclistas, vehículos estacionados y vehículos que se dieron a la fuga (*hit and run*).
- **Tratamiento metodológico:** Todo registro con código centinela (998/999) o edad/año fuera de rango definido se traslada a la categoría `Desconocido / En cuarentena` en la dimensión correspondiente, garantizando que el evento de colisión y las métricas de víctimas no se eliminen del hecho principal. No se eliminan ni modifican registros de la fuente.

### 7. Dependencias Funcionales y Columnas Derivables (07_dependencias_tipos.sql)
Una tabla está en Tercera Forma Normal cuando cada atributo depende solo de su clave. La auditoría identificó qué columnas de la fuente violan esa condición.

**a) Dependencias transitivas (se extraen a catálogo):**

| Dependencia | Violaciones | Decisión |
|---|---|---|
| `county_city_location → county_location` | 0 | Catálogo `ubicacion` (542 filas) → `condado` (58). |
| `county_city_location → population` | 0 | `poblacion` (8 categorías) pasa al catálogo `ubicacion`. |
| `jurisdiction → county_location` | 94 | No es dependencia: `jurisdiction` queda como atributo de la colisión. |
| `pcf_violation → pcf_violation_category` | 124 | No es dependencia: ambos quedan en la colisión. |
| `pcf_violation_category → primary_collision_factor` | 3 | No es dependencia estricta: catálogos independientes. |
| `caltrans_county → county_location` | 55 | No es dependencia: `caltrans_county` pertenece al bloque Caltrans. |

**b) Columnas derivables desde las tablas de detalle (no se almacenan):** se recalculó cada columna a partir de `victims` y `parties` y se contaron las filas donde el valor declarado difiere.

| Columna en la fuente | Se recalcula como | Filas con diferencia |
|---|---|---|
| `killed_victims` | víctimas con `killed` | 0 |
| `injured_victims` | víctimas con nivel A, B o C | 0 |
| `severe_injury_count` / `other_visible_injury_count` / `complaint_of_pain_injury_count` | víctimas A / B / C | 1 / 0 / 0 |
| `pedestrian_killed_count` / `pedestrian_injured_count` | víctimas con `victim_role = pedestrian` | 0 / 0 |
| `bicyclist_killed_count` / `bicyclist_injured_count` | víctimas de partes `bicyclist` | 0 / 6 |
| `motorcyclist_killed_count` / `motorcyclist_injured_count` | víctimas de vehículos moto o *moped* | 0 / 0 |
| `party_count` | filas de `parties` | 1 |
| `parties.party_number_killed` / `party_number_injured` | víctimas de esa parte | 0 / 0 |
| `collision_severity` | lesión máxima KABCO de sus víctimas | 0 (el código basura `N` corresponde a nivel 0) |
| `statewide_vehicle_type_at_fault` / `chp_vehicle_type_at_fault` | vehículo de la parte con `at_fault = 1` | 3 / 3 |
| `pedestrian_collision` / `bicycle_collision` / `motorcycle_collision` / `truck_collision` | existencia de una parte de ese tipo | 0 / 0 / 0 / 0 |

Las 21 columnas (19 de `collisions` y 2 de `parties`) son redundantes: almacenarlas duplicaría información y abriría la puerta a inconsistencias (las 1–6 filas discrepantes lo demuestran). En el modelo normalizado se calculan en vistas y, ante discrepancia, prevalece el valor recalculado desde el detalle.

### 8. Columnas Dispersas, Constantes y Subtipos 1:0..1 (07_dependencias_tipos.sql)
- **Bloque Caltrans:** `caltrans_county`, `caltrans_district`, `state_route`, `postmile`, `location_type` y `side_of_highway` son nulas **a la vez** en 3.463.712 colisiones (79,29%) y no nulas a la vez en **904.581**; no existen bloques parciales. Es un subtipo (colisión en carretera estatal) y va a la tabla `colision_carretera` de grano `1:0..1`, igual que `colision_geo`.
- **Columnas sin información:** `not_private_property` es constante (siempre 1), `oaf_violation_code` está 100% nula, `pcf_violation_code` 99,99% y `route_suffix` 99,96%. No se migran.
- **Columnas dispersas con contenido:** `weather_2` (97,27% nula), `road_condition_2` (99,55%), `other_associate_factor_2`, `oaf_violation_suffix`, `hazardous_materials` y `school_bus_related` (banderas 1/NULL) se conservan como columnas nulables: en almacenamiento columnar los nulos casi no ocupan espacio. `ramp_intersection` y `postmile_prefix` pasan a `colision_carretera`; `primary_ramp` y `secondary_ramp` quedan fuera del modelo (sección D).
- **Códigos basura por catálogo:** `collision_severity = 'N'` (1), `primary_collision_factor = '2'` (1), `direction = '155.00'` (1), `chp_road_type = 'A'` (1), `statewide_vehicle_type = '04'` (2) y `victim_sex = '2'` (1). Se asignan a `id = 0 Sin clasificar`. El código `G` de `party_drug_physical` (808.174 partes) no es basura: es el código oficial de "deterioro desconocido" y se decodifica en el catálogo.

### 9. Ruptura de Codificación y Cobertura en Víctimas desde 2017 (07_dependencias_tipos.sql)
SWITRS cambió la codificación de `victim_degree_of_injury` en 2017–2018 (`severe injury` → `suspected serious injury`, `other visible injury` → `suspected minor injury`, `complaint of pain` → `possible injury`). Homologadas a la escala **KABCO**, las series K, A, B y C son continuas:

| Año | K (muerto) | A (grave) | B (visible) | C (dolor/posible) | O (ileso) |
|---|---|---|---|---|---|
| 2010 | 2.739 | 10.423 | 58.824 | 160.107 | 216.649 |
| 2013 | 3.104 | 10.664 | 56.986 | 155.478 | 198.620 |
| 2016 | 3.860 | 13.259 | 67.408 | 199.372 | 245.257 |
| 2017 | 3.904 | 14.201 | 70.126 | 192.837 | **85.285** |
| 2018 | 3.805 | 16.158 | 75.452 | 183.251 | **82.529** |
| 2019 | 3.736 | 16.433 | 73.269 | 179.215 | **80.345** |

- **Hallazgo:** desde 2017 la fuente registra ~65% menos víctimas ilesas (O). Esa es la causa de la caída del total anual de víctimas en 2017–2019 (sección B.1), no una reducción real de la siniestralidad.
- **Decisión:** el catálogo `lesion` mapea los 8 códigos originales a K/A/B/C/O. Los análisis de severidad usan K–C (comparables en toda la década); los conteos de ilesos y el total de víctimas no se comparan antes y después de 2017.
- `collision_severity` (grano colisión) no se ve afectada: conserva los mismos 5 valores durante toda la década.

### 10. Claves, Tipos Físicos y Unidad de Análisis (05 y 07)
- **`case_id`:** 100% numérico, de 7 u 8 dígitos, sin ceros a la izquierda, máximo 91.463.275 → se almacena como `INTEGER` (4 bytes) en lugar de `TEXT`, en las tres tablas.
- **Fechas:** `collision_date` y `process_date` son 100% convertibles a `DATE`; `collision_time` a `TIME` (sin segundos en ningún registro).
- **Enteros pequeños:** `party_number` (1–38) y edades válidas (0–110) caben en `UTINYINT`; `vehicle_year` en `USMALLINT`; los ids de catálogo en `UTINYINT` (≤ 255 valores) salvo `ubicacion` (`USMALLINT`).
- **Clave de víctimas:** `victims` no tiene número de víctima y su `id` no es único. La PK será `(case_id, party_number, victim_ordinal)` con el ordinal asignado por `id` dentro de cada parte; el `id` no se repite dentro de ninguna parte (verificado). 25.710 filas son idénticas salvo el `id` y se conservan: son personas distintas con el mismo perfil (p. ej. dos pasajeros), no duplicados.
- **Unidad de análisis para el Objetivo 2 (edad del conductor):** hay 7.796.486 partes `driver` (1,78 por colisión; 9,70% sin edad). Cada colisión tiene **como máximo un culpable** (`at_fault = 1`): 4.064.710 colisiones con culpable y 303.583 (6,95%) sin culpable. Para relacionar la edad con la severidad de la colisión se usa el conductor culpable (relación `1:0..1`), lo que evita contar una colisión varias veces.
- **Unidad de análisis para el Objetivo 4 (año-modelo):** `vehicle_year` es atributo de la parte, y cada víctima pertenece a una parte (`victims → parties` sin huérfanos). La relación año-modelo vs lesión se mide a grano víctima con lesión homologada K–C.

---

## C. Matriz de Evidencia Empírica de Pruebas

| Código | Prueba de Calidad Ejecutada | Estado | Resultado / Métrica Real Verificada |
|---|---|---|---|
| **CP-01** | Cobertura temporal 2010–2019 | **✅ CORRECTO** | 4.368.293 colisiones, 3.652 días con datos (100%), 0 días en cero. |
| **CP-02** | Existencia de tablas originales | **✅ CORRECTO** | `collisions`, `parties`, `victims` y `case_ids` verificadas y funcionales. |
| **CP-03** | Unicidad de clave de colisión | **✅ CORRECTO** | `case_id` 100% único (0 duplicados, 0 nulos). |
| **CP-04** | Integridad referencial de partes y víctimas | **✅ CORRECTO** | 0 partes huérfanas, 0 víctimas huérfanas, 0 víctimas sin participante padre. |
| **CP-05** | Georreferenciación y nulos de coordenadas | **⚠️ ADVERTENCIA** | 50,56% nulos. Requiere tabla satélite 1:0..1 `hecho_colision_geo`. |
| **CP-06** | Semántica de alcohol involucrado | **✅ CORRECTO** | 440.917 con alcohol (10,09%); 3.927.376 no reportado/nulo (89,91%). |
| **CP-07** | Consistencia de métricas de severidad | **✅ CORRECTO** | Muertos declarados (33.541) = muertos reales (33.541); Heridos (2.491.217) = heridos reales (2.491.217). |
| **CP-08** | Control de rangos (edad y año vehículo) | **⚠️ ADVERTENCIA** | 38 `party_age` > 110; 171 `victim_age` fuera de 0–110 (48 son centinelas 998/999); 2 `vehicle_year` = 2021. Cuarentena sin eliminación. |
| **CP-09** | Coherencia entre scripts SQL y documentación | **✅ CORRECTO** | Scripts 01–07 alineados con el período 2010–2019; las comprobaciones de consistencia se leen directamente de cada query ejecutado. |
| **CP-10** | Dependencias transitivas (3FN) | **✅ CORRECTO** | `county_city_location → county_location, population` sin violaciones: catálogo `ubicacion` (542 filas). |
| **CP-11** | Columnas derivables | **⚠️ ADVERTENCIA** | 19 columnas de `collisions` y 2 de `parties` son recalculables desde el detalle (0–6 discrepancias); no se almacenan. |
| **CP-12** | Bloques dispersos y columnas vacías | **✅ CORRECTO** | Bloque Caltrans nulo en bloque (0 parciales) → subtipo 1:0..1; 4 columnas sin información no se migran. |
| **CP-13** | Continuidad de la lesión de víctimas | **⚠️ ADVERTENCIA** | Recodificación 2017–2018 resuelta con KABCO; ilesos (O) caen ~65% desde 2017 y no son comparables. |
| **CP-14** | Claves y tipos físicos | **✅ CORRECTO** | `case_id` → `INTEGER`; fechas → `DATE`/`TIME`; víctima con PK `(case_id, party_number, victim_ordinal)` determinista. |

---

## D. Decisiones Metodológicas para la Fase 2 (Normalización)

El objetivo de la Fase 2 es una base **lo más normalizada posible y liviana**. Se separan dos capas:

1. **Núcleo normalizado en 3FN (almacenamiento físico, Parquet ZSTD particionado por año):**

| Tabla | Grano / PK | Filas 2010–2019 | Contenido |
|---|---|---|---|
| `colision` | `case_id` (INTEGER) | 4.368.293 | Fecha (`DATE`), hora (`TIME`, NULL = desconocida), FK a `ubicacion` y a catálogos de entorno, vía, causa y tipo; banderas propias en `BOOLEAN` (`alcohol_involved` con NULL semántico: TRUE o NULL, nunca FALSE). |
| `colision_geo` | `case_id` (1:0..1) | 2.159.739 | Latitud y longitud con par completo dentro de California. |
| `colision_carretera` | `case_id` (1:0..1) | 904.581 | Bloque Caltrans. |
| `parte` | `(case_id, party_number)` | 8.688.142 | Tipo de parte, culpabilidad, sexo, edad, sobriedad, vehículo y `vehicle_year` (Objetivo 4). |
| `victima` | `(case_id, party_number, victim_ordinal)` | 4.280.801 | Rol, sexo, edad, lesión, asiento, equipo de seguridad y eyección. |
| `ubicacion` → `condado`, `poblacion` | `county_city_location` | 542 → 58, 8 | Elimina la dependencia transitiva de la colisión. |
| Catálogos de códigos | `id` UTINYINT | — | `id = 0 Sin clasificar` para NULL y códigos basura; `codigo_original` + `descripcion_es`. `lesion` incluye el nivel KABCO. |
| `dim_fecha` | `fecha` | 3.652 | Generada por calendario, no desde los datos. |

2. **Capa analítica en estrella (vistas sobre el núcleo, para Power BI):** `vw_hecho_colision` (severidad derivada, conteos K/A/B/C, número de partes, banderas peatón/ciclista/moto/camión, vehículo del culpable, `tiene_coordenadas`), `vw_hecho_parte` (bandas etarias excluyentes `0-17`, `18-25`, `26-35`, `36-50`, `51-64`, `65+`, `Desconocido`) y `vw_hecho_victima` (lesión KABCO). Las medidas se calculan con `COUNT` sobre el grano correcto, lo que elimina el riesgo de *fan-out*.

3. **Lo que no se almacena:** las 21 columnas derivables (sección B.7), las 4 columnas sin información (B.8), `parties.id`, `victims.id`, la tabla `case_ids` (redundante con `collisions`) y las tablas `dim_*` del prototipo. Las columnas administrativas y de texto libre que ningún objetivo usa (`officer_id`, `reporting_district`, `beat_*`, `chp_shift`, `chp_beat_*`, `city_division_lapd`, `chp_road_type`, `primary_road`, `secondary_road`, `distance`, `direction`, `primary_ramp`, `secondary_ramp`, `process_date`) quedan fuera del modelo y son recuperables desde la fuente por `case_id`.

4. **Valores atípicos:** edades fuera de 0–110 (incluidos 998/999) y `vehicle_year` fuera de 1900–2020 se almacenan como NULL con bandera de cuarentena; la fila se conserva y el valor crudo permanece en la fuente.

---

## E. Conclusión de la Auditoría

Los datos de colisiones de tránsito de California para el período **2010–2019** poseen una **calidad estructural e integridad referencial sobresaliente** (integridad del 100% entre colisiones, partes y víctimas, cobertura temporal completa sin días faltantes y cuadratura matemática exacta en fatalidades y lesiones).

Los riesgos identificados (50,56% de coordenadas nulas, atípicos centinela 998/999 en edad, codificación asimétrica en `alcohol_involved` y ruptura de cobertura de víctimas ilesas en 2017) no comprometen la viabilidad de la investigación, pues cuentan con tratamientos metodológicos claros y documentados (tabla satélite geográfica, categorías de cuarentena, distinción semántica de alcohol y homologación KABCO).

La auditoría además demuestra que la fuente es fuertemente redundante: 21 columnas son recalculables desde el detalle, `county_city_location` determina condado y población, el bloque Caltrans es un subtipo y `case_id` admite un tipo entero. Estas evidencias fundamentan el núcleo en 3FN de la sección D.

**Dictamen:** La fuente de datos para el período 2010–2019 ha sido auditada y documentada. Los hallazgos identificados (cobertura de coordenadas, códigos centinela 998/999, `alcohol_involved` sin valor 0, columnas derivables y ruptura de víctimas ilesas en 2017) cuentan con tratamientos metodológicos claros. Se encuentra lista para proceder con la Fase 2: construcción del núcleo normalizado en 3FN y de su capa de vistas en estrella, bajo las condiciones y limitaciones descritas.
