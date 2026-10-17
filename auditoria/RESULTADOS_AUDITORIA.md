# Resultados de Auditoría Integral — Calidad, Estructura e Integridad de Datos SWITRS (2010–2019)

**Proyecto:** Perfiles de riesgo en colisiones de tránsito — California (2010–2019)  
**Institución:** Escuela de Estadística y Ciencias Actuariales (EECA-UCV) — Cátedra de Computación II  
**Versión de informe:** 2.0 (Unificación decenal 2010–2019)  
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
- **Justificación técnica:** El procesamiento directo en SQLite sobre tablas de más de 18 millones de filas genera *timeouts* y bloqueos por falta de índices secundarios; DuckDB ejecuta escaneos columnares en memoria con paralelismo vectorial sin modificar la fuente cruda.

### 4. Tablas Analizadas
| Tabla Fuente | Filas Globales (2001–2021) | Filas Período (2010–2019) | Grano de la Información |
|---|---|---|---|
| `sw.collisions` | 9.424.334 | **4.368.293** | Un registro por evento de colisión (`case_id`). |
| `sw.parties` | 18.669.166 | **8.688.142** | Un registro por actor/vehículo involucrado en el siniestro. |
| `sw.victims` | 9.639.334 | **4.280.801** | Un registro por persona lesionada o fallecida. |
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
- **Patrón semanal:** Viernes es el día con mayor volumen (714.156 siniestros; 16,35%), mientras que el domingo registra la menor frecuencia (508.014; 11,63%).
- **Patrón horario:** Horas pico de la tarde entre las 15:00 y las 18:30 (superando 25.000 colisiones por tramo horario). El 0,91% de los registros presenta `collision_time` nulo.

### 2. Catálogos y Factores de Entorno (01_catalogos_frecuencias.sql)
- **Severidad del evento (`collision_severity`):**
  - *Property damage only* (Solo daños materiales): 2.591.057 (59,31%)
  - *Pain* (Queja de dolor): 1.102.846 (25,25%)
  - *Other visible injury* (Lesión visible no grave): 535.313 (12,25%)
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
  - Coordenadas no nulas dentro de California (lat 32°–43° N, lon -125° a -114° O): **2.159.739** (49,44%).
  - Coordenadas fuera de rango geográfico: **1** caso.
  - Coordenadas nulas: **2.208.554** (50,56%).
  - *Regla metodológica:* Prohibido imputar coordenadas (centroides o ceros). Se diseña una tabla de extensión de grano `1:0..1` (`hecho_colision_geo`) y una bandera booleana `tiene_coordenadas` en el hecho principal.
- **Hora del siniestro (`collision_time`):** 39.693 nulos (0,91%). Se mantiene como hora desconocida; prohibido imputar `00:00:00` para no distorsionar las colisiones de medianoche.

### 4. Consistencia Matemática y Control Anti Fan-Out (04_fanout_rangos.sql)
La auditoría comprobó la consistencia aditiva entre las medidas escalares declaradas en `collisions` y el conteo de filas desagregadas en tablas subordinadas:

| Métrica Controlada | Valor Declarado en `collisions` | Conteo Real en Detalle (`victims`/`parties`) | Diferencia | Veredicto |
|---|---|---|---|---|
| **Víctimas mortales (`killed_victims`)** | 33.541 | 33.541 (`victim_degree_of_injury = 'killed'`) | **0** | **Consistencia exacta (100%)** |
| **Víctimas lesionadas (`injured_victims`)** | 2.491.217 | 2.491.217 (grados de lesión confirmados) | **0** | **Consistencia exacta (100%)** |
| **Víctimas con grado desconocido** | — | 0 (`unknown`) | **0** | **Sin ruido en severidad de víctimas** |
| **Conteo de partes (`party_count`)** | 8.688.140 | 8.688.142 (filas reales en `parties`) | **−2** | Diferencia marginal del 0,00002%. La medida aditiva en el modelo dimensional debe ser `COUNT(parties.id)` y no `SUM(party_count)`. |

### 5. Claves Candidatas e Integridad Referencial (05_integridad_duplicados.sql)
- **Unicidad de `collisions.case_id`:** 4.368.293 identificadores únicos, **0 duplicados** y **0 nulos**. Es la clave primaria natural absoluta del hecho de colisiones.
- **Clave candidata en `parties`:** La combinación compuesta `(case_id, party_number)` presenta 8.688.142 registros y **0 duplicados**.
- **Evaluación de `victims.id`:** La columna preexistente `id` en `victims` presenta **1 duplicado** en el período. Por tanto, no puede ser adoptada como clave primaria sin generar una clave subrogada determinista en la normalización.
- **Registros huérfanos:**
  - Partes sin colisión padre (`parties -> collisions`): **0 huérfanos** (100% integridad).
  - Víctimas sin colisión padre (`victims -> collisions`): **0 huérfanos** (100% integridad).
  - Víctimas sin participante padre (`victims -> parties` vía `case_id + party_number`): **0 huérfanos**.
- **Catálogo `case_ids`:** Coincide biyectivamente con las colisiones (9.424.334 registros globales; 0 discrepancias).
- **Alerta sobre tablas `dim_*` preexistentes en SQLite:**
  - En el archivo `switrs.sqlite` existen tablas auxiliares creadas en un prototipo previo (`dim_fecha`, `dim_clima`, etc.).
  - Se verificó que `dim_fecha` solo posee 2.191 filas (período 2016–2021), resultando insuficiente para el período 2010–2019 (3.652 días requeridos).
  - Las tablas dimensionales definitivas deben generarse desde cero en la Fase 2 durante el pipeline de normalización, no heredarse del prototipo.

### 6. Rangos Numéricos y Protocolo de Cuarentena (04_fanout_rangos.sql)
- **Edad de participantes (`party_age`):** Rango de 0 a 125 años. Media en rango limpio (0–110): 39,3 años. Se identificaron 38 registros > 110 años.
- **Edad de víctimas (`victim_age`):** Media en rango limpio: 32,4 años. Se detectaron 48 registros con códigos centinela 998/999 y 171 registros con edad > 110.
- **Año-modelo del vehículo (`vehicle_year`):**
  - Rango válido verificado: 1900 a 2020.
  - Media del parque automotor involucrado: **año 2005,5**.
  - Nulos: 869.373 registros (10,01%), asociados primordialmente a peatones, ciclistas y vehículos que se dieron a la fuga (*hit and run*).
  - Atípicos fuera de período: únicamente **2 registros** reportaron año > 2020.
- **Tratamiento metodológico:** Todo registro atípico o código centinela (998/999) se traslada a la categoría `Desconocido / En cuarentena` en la dimensión correspondiente, garantizando que el evento de colisión y las métricas de víctimas no se eliminen del hecho principal.

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
| **CP-08** | Control de rangos (edad y año vehículo) | **⚠️ ADVERTENCIA** | 38 edades de partes > 110; 48 códigos 998/999; 2 años > 2020. Cuarentena sin eliminación. |
| **CP-09** | Coherencia entre SQL y documentación | **✅ CORRECTO** | Scripts 01–06, suite automatizada y documentación sincronizados en 2010–2019. |

---

## D. Decisiones Metodológicas para la Fase 2 (Normalización y Modelo Estrella)

1. **Grano del Hecho Principal:**
   - `hecho_colision`: Grano de evento colisión identificado por `case_id` (o su clave subrogada entera `collision_sk`).
   - `hecho_victimas`: Grano por víctima involucrada, relacionado con la colisión y el participante padre.
   - `hecho_colision_geo`: Extensión de grano `1:0..1` exclusiva para las 2.159.739 colisiones con latitud/longitud válidas.
2. **Dimensiones Confirmadas:**
   - `dim_fecha`: Pre-generación de los 3.652 días decenales (2010-01-01 a 2019-12-31).
   - `dim_county`: Los 58 condados oficiales de California.
   - `dim_severidad`: 5 categorías oficiales de severidad.
   - `dim_entorno`: Fusión de clima (`weather_1`) e iluminación (`lighting`).
   - `dim_vial`: Fusión de superficie vial, condición y dispositivo de control.
   - `dim_tipo_colision`: Tipo de colisión reportada.
   - `dim_causa`: Factor primario y categoría de infracción (con deduplicación del código `unknown`).
   - `dim_actor`: Sexo y bandas etarias excluyentes: `0-17`, `18-25`, `26-35`, `36-50`, `51-64`, `65+`, `Desconocido`.
   - `dim_vehiculo`: Tipo de vehículo y **año-modelo del vehículo (`vehicle_year`) preservado explícitamente para dar respuesta al Objetivo Específico 4**.
3. **Manejo de Valores Nulos:**
   - Adopción de la convención dimensional Kimball: toda clave foránea nula o categoría basura se enlaza al registro sustituto `id = 0` (*"Sin clasificar / No reportado"*), garantizando integridad referencial estricta sin registros huérfanos.

---

## E. Conclusión de la Auditoría

Los datos de colisiones de tránsito de California para el período **2010–2019** poseen una **calidad estructural e integridad referencial sobresaliente** (integridad del 100% entre colisiones, partes y víctimas, cobertura temporal completa sin días faltantes y cuadratura matemática exacta en fatalidades y lesiones).

Los riesgos identificados (50,56% de coordenadas nulas, atípicos centinela 998/999 en edad y codificación asimétrica en `alcohol_involved`) no comprometen la viabilidad de la investigación, pues cuentan con tratamientos metodológicos claros y documentados (tabla satélite geográfica, categorías de cuarentena y distinción semántica de alcohol).

**Dictamen:** La fuente de datos está formalmente **aprobada y lista** para proceder con la Fase 2 de normalización a Tercera Forma Normal (3FN), diseño físico columnar en DuckDB y exportación a Parquet para el tablero de Power BI.
