# Diccionario de datos

Descripción, campo por campo, de la base normalizada `colisiones_california.duckdb` y de su exportación Parquet en `data/processed/`. Período: **2010–2019**. Los porcentajes de nulos y de "Sin clasificar" se midieron sobre la base cargada por `03_procesamiento_carga.py`.

## Convenciones

| Etiqueta | Significado |
|---|---|
| **FUENTE** | Se toma de SWITRS sin cambiar su valor (solo el tipo). |
| **DERIVADO** | Se obtiene de un campo de la fuente con una regla explícita (indicada entre paréntesis). |
| **CONSTRUIDO** | No existe en la fuente: lo define esta investigación. |

- **PK** = llave primaria · **FK → t** = llave foránea a la tabla `t`.
- En los catálogos de códigos, el **id 0 = "Sin clasificar"** recoge los NULL y los códigos basura de la fuente. Ninguna fila se descarta por un código inválido.
- Las PK y FK de las cinco tablas del núcleo **no se declaran en el motor**: se documentan aquí y las verifica `03_procesamiento_carga.py` (5 PK sin duplicados, 0 huérfanos en 37 relaciones). Ver [MODELADO_DE_DATOS.md](MODELADO_DE_DATOS.md#42-llaves-verificadas-y-no-declaradas).

---

## 1. `colision` — 4.368.293 filas

Grano: **una colisión**. Archivo: `data/processed/colision/colision_<año>.parquet`.

| Campo | Tipo | Llave | Procedencia | Descripción | Nulos / Sin clasificar |
|---|---|---|---|---|---:|
| `case_id` | INTEGER | PK | FUENTE (`case_id`) | Identificador oficial del atestado. En la fuente es TEXT; es 100% numérico (máx. 91.463.275). | 0 % |
| `fecha` | DATE | FK → calendario | FUENTE (`collision_date`) | Fecha del siniestro. | 0 % |
| `hora` | TIME | | FUENTE (`collision_time`) | Hora del siniestro, con resolución de minutos. **NULL = hora desconocida** (no se imputa 00:00). | 0,91 % nulo |
| `ubicacion_id` | USMALLINT | FK → ubicacion | FUENTE (`county_city_location`) | Código condado-ciudad como entero. Determina condado y población. | 0 % |
| `jurisdiccion` | USMALLINT | | FUENTE (`jurisdiction`) | Código de la agencia con jurisdicción. | 0,19 % nulo |
| `clima_id` | UTINYINT | FK → clima | FUENTE (`weather_1`) | Condición atmosférica principal. | 0,35 % sin clasificar |
| `clima_2_id` | UTINYINT | FK → clima | FUENTE (`weather_2`) | Segunda condición. **NULL = no hubo segunda condición.** | 97,27 % nulo |
| `iluminacion_id` | UTINYINT | FK → iluminacion | FUENTE (`lighting`) | Condición de luz. | 0,45 % sin clasificar |
| `superficie_id` | UTINYINT | FK → superficie | FUENTE (`road_surface`) | Estado de la calzada. | 0,67 % sin clasificar |
| `condicion_via_id` | UTINYINT | FK → condicion_via | FUENTE (`road_condition_1`) | Condición de la vía. | 0,69 % sin clasificar |
| `condicion_via_2_id` | UTINYINT | FK → condicion_via | FUENTE (`road_condition_2`) | Segunda condición de la vía. NULL = no hubo. | 99,55 % nulo |
| `dispositivo_control_id` | UTINYINT | FK → dispositivo_control | FUENTE (`control_device`) | Semáforo o señal y su estado. | 0,61 % sin clasificar |
| `tipo_colision_id` | UTINYINT | FK → tipo_colision | FUENTE (`type_of_collision`) | Mecánica del impacto. | 0,88 % sin clasificar |
| `implicado_con_id` | UTINYINT | FK → implicado_con | FUENTE (`motor_vehicle_involved_with`) | Con qué chocó el vehículo. | 0,53 % sin clasificar |
| `factor_primario_id` | UTINYINT | FK → factor_primario | FUENTE (`primary_collision_factor`) | Factor primario. Incluye 1 código basura `'2'`. | 0,35 % sin clasificar |
| `categoria_infraccion_id` | UTINYINT | FK → categoria_infraccion | FUENTE (`pcf_violation_category`) | Categoría de la infracción principal. | 1,29 % sin clasificar |
| `infraccion_codigo` | INTEGER | | FUENTE (`pcf_violation`) | Sección del código vehicular infringida. No depende funcionalmente de la categoría (124 violaciones, auditoría B.7). | 6,42 % nulo |
| `infraccion_inciso` | VARCHAR | | FUENTE (`pcf_violation_subsection`) | Inciso de la sección. | 64,49 % nulo |
| `fuga_id` | UTINYINT | FK → fuga | FUENTE (`hit_and_run`) | Fuga del responsable y su tipificación. | 1 fila sin clasificar |
| `accion_peaton_id` | UTINYINT | FK → accion_peaton | FUENTE (`pedestrian_action`) | Qué hacía el peatón, si lo hubo. | 0,07 % sin clasificar |
| `en_interseccion` | BOOLEAN | | FUENTE (`intersection`) | Ocurrió en una intersección. | 0,61 % nulo |
| `vehiculo_remolcado` | BOOLEAN | | FUENTE (`tow_away`) | Algún vehículo fue remolcado. | 0,73 % nulo |
| `carretera_estatal` | BOOLEAN | | FUENTE (`state_highway_indicator`) | Ocurrió en una carretera estatal. | 0,02 % nulo |
| `condicion_especial` | BOOLEAN | | DERIVADO (`special_condition = '1'`) | Condición especial del lugar. | 0 % |
| `alcohol_implicado` | BOOLEAN | | DERIVADO (`1 → TRUE`) | **TRUE o NULL, nunca FALSE.** La fuente solo marca la presencia confirmada; NULL significa "no reportado", no "sobrio". 440.917 colisiones con TRUE (10,09 %). | 89,91 % nulo |

**Campos de la fuente que no se almacenan por ser derivables** (se recalculan en `vw_hecho_colision`): `killed_victims`, `injured_victims`, `severe_injury_count`, `other_visible_injury_count`, `complaint_of_pain_injury_count`, `pedestrian_*_count`, `bicyclist_*_count`, `motorcyclist_*_count`, `party_count`, `collision_severity`, `statewide_vehicle_type_at_fault`, `chp_vehicle_type_at_fault`, `pedestrian_collision`, `bicycle_collision`, `motorcycle_collision` y `truck_collision`.

## 2. `colision_geo` — 2.159.739 filas

Grano: **una colisión georreferenciada**. Relación **1:0..1** con `colision` (49,44 % de cobertura).

| Campo | Tipo | Llave | Procedencia | Descripción |
|---|---|---|---|---|
| `case_id` | INTEGER | PK, FK → colision | FUENTE | La PK es a la vez FK: cada colisión tiene a lo sumo una fila. |
| `latitud` | DOUBLE | | FUENTE (`latitude`) | Grados decimales. Rango: 32,50 a 42,04. |
| `longitud` | DOUBLE | | FUENTE (`longitude`) | Grados decimales. Rango: −124,50 a −114,10. |

Solo entran pares completos dentro de la caja de California (lat 32–43, lon −125 a −114). El único par incompleto del período (longitud sin latitud) queda fuera. No se imputan coordenadas.

## 3. `colision_carretera` — 904.581 filas

Grano: **una colisión con datos de carretera estatal (Caltrans)**. Relación **1:0..1** con `colision`. Las columnas del bloque Caltrans son nulas o no nulas siempre juntas (auditoría B.8).

| Campo | Tipo | Llave | Procedencia | Descripción | Nulos |
|---|---|---|---|---|---:|
| `case_id` | INTEGER | PK, FK → colision | FUENTE | | 0 % |
| `condado_caltrans_id` | UTINYINT | FK → condado | FUENTE (`caltrans_county`) | Condado del tramo según Caltrans. Puede diferir del condado de la colisión; el código basura `'N'` → 0. | 0 % |
| `distrito_caltrans` | UTINYINT | | FUENTE (`caltrans_district`) | Distrito Caltrans (1–12). | 0 % |
| `ruta_estatal` | USMALLINT | | FUENTE (`state_route`) | Número de la ruta estatal. | 0 % |
| `prefijo_postmile` | VARCHAR | | FUENTE (`postmile_prefix`) | Prefijo del poste kilométrico. | 69,18 % |
| `postmile` | DOUBLE | | FUENTE (`postmile`) | Poste miliar del tramo. | 0 % |
| `tipo_ubicacion` | VARCHAR | | FUENTE (`location_type`) | `highway`, `intersection` o `ramp`. | 0 % |
| `sentido` | VARCHAR | | FUENTE (`side_of_highway`) | Calzada (northbound, southbound...). | 0 % |
| `rampa_interseccion` | VARCHAR | | FUENTE (`ramp_intersection`) | Posición respecto de rampas e intersecciones. | 77,97 % |

## 4. `parte` — 8.688.142 filas

Grano: **una parte implicada** (conductor, peatón, ciclista, vehículo estacionado u otro). PK compuesta `(case_id, numero_parte)`.

| Campo | Tipo | Llave | Procedencia | Descripción | Nulos / Sin clasificar |
|---|---|---|---|---|---:|
| `case_id` | INTEGER | PK, FK → colision | FUENTE | | 0 % |
| `numero_parte` | UTINYINT | PK | FUENTE (`party_number`) | Número de la parte dentro de la colisión (1–38). | 0 % |
| `tipo_parte_id` | UTINYINT | FK → tipo_parte | FUENTE (`party_type`) | Conductor, peatón, ciclista... | 0,10 % sin clasificar |
| `culpable` | BOOLEAN | | DERIVADO (`at_fault = 1`) | Parte culpable. **A lo sumo una por colisión** (verificado). | 0 % |
| `sexo_id` | UTINYINT | FK → sexo | FUENTE (`party_sex`) | | 13,64 % sin clasificar |
| `edad` | UTINYINT | | DERIVADO (rango 0–110) | Edad en años. Fuera de rango → NULL. | 15,62 % nulo |
| `edad_en_cuarentena` | BOOLEAN | | CONSTRUIDO | TRUE si la fuente traía una edad fuera de 0–110 (38 casos). Distingue ese NULL de un NULL de origen. | 0 % |
| `raza_id` | UTINYINT | FK → raza | FUENTE (`party_race`) | | 17,31 % sin clasificar |
| `sobriedad_id` | UTINYINT | FK → sobriedad | FUENTE (`party_sobriety`) | Estado respecto del alcohol. | 2,65 % sin clasificar |
| `droga_fisica_id` | UTINYINT | FK → droga_fisica | FUENTE (`party_drug_physical`) | Drogas o condición física. El código `G` (808.174) es "deterioro desconocido", no basura. | 82,88 % sin clasificar |
| `direccion_id` | UTINYINT | FK → direccion | FUENTE (`direction_of_travel`) | Sentido de circulación. | 2,75 % sin clasificar |
| `movimiento_previo_id` | UTINYINT | FK → movimiento_previo | FUENTE (`movement_preceding_collision`) | Maniobra previa al impacto. | 1,89 % sin clasificar |
| `equipo_seguridad_1_id` | UTINYINT | FK → equipo_seguridad | FUENTE (`party_safety_equipment_1`) | | 17,09 % sin clasificar |
| `equipo_seguridad_2_id` | UTINYINT | FK → equipo_seguridad | FUENTE (`party_safety_equipment_2`) | NULL = no se registró un segundo equipo. | 19,74 % nulo |
| `tipo_vehiculo_id` | UTINYINT | FK → tipo_vehiculo | FUENTE (`statewide_vehicle_type`) | Incluye 2 códigos basura `'04'`. | 10,15 % sin clasificar |
| `anio_vehiculo` | USMALLINT | | DERIVADO (rango 1900–2020) | Año-modelo del vehículo (**Objetivo 4**). | 10,01 % nulo |
| `anio_vehiculo_en_cuarentena` | BOOLEAN | | CONSTRUIDO | TRUE si la fuente traía un año fuera de rango (2 casos, ambos 2021). | 0 % |
| `marca_vehiculo` | VARCHAR | | FUENTE (`vehicle_make`) | Texto libre (5.627 variantes). | 9,22 % |
| `tipo_vehiculo_chp` | VARCHAR | | FUENTE (`chp_vehicle_type_towing`) | Clasificación CHP del vehículo. No depende de `tipo_vehiculo_id`. | 9,27 % |
| `tipo_remolque_chp` | VARCHAR | | FUENTE (`chp_vehicle_type_towed`) | Clasificación CHP del remolque. | 68,23 % |
| `responsabilidad_financiera` | VARCHAR | | FUENTE (`financial_responsibility`) | Prueba de seguro. | 7,78 % |
| `usaba_celular` | BOOLEAN | | FUENTE (`cellphone_in_use`) | | 15,83 % |
| `uso_celular` | VARCHAR | | FUENTE (`cellphone_use_type`) | Tipo de uso del celular. | 15,20 % |
| `materiales_peligrosos` | BOOLEAN | | DERIVADO (`1 → TRUE`) | TRUE o NULL, como en la fuente. | 99,86 % |
| `relacion_bus_escolar` | BOOLEAN | | DERIVADO (`1 → TRUE`) | TRUE o NULL, como en la fuente. | 99,63 % |
| `otra_infraccion_categoria` | VARCHAR | | FUENTE (`oaf_violation_category`) | Otra infracción asociada. | 93,49 % |
| `otra_infraccion_seccion` | VARCHAR | | FUENTE (`oaf_violation_section`) | | 93,42 % |
| `otra_infraccion_sufijo` | VARCHAR | | FUENTE (`oaf_violation_suffix`) | | 98,18 % |
| `factor_asociado_1` | VARCHAR | | FUENTE (`other_associate_factor_1`) | Otro factor asociado. | 5,65 % |
| `factor_asociado_2` | VARCHAR | | FUENTE (`other_associate_factor_2`) | | 98,01 % |

**No se almacenan:** `id` (no es clave: 3 duplicados), `party_number_killed` y `party_number_injured` (derivables de `victima`), `oaf_violation_code` (100 % nulo).

## 5. `victima` — 4.280.801 filas

Grano: **una persona reportada como víctima** (fallecida, lesionada o ilesa). PK compuesta `(case_id, numero_parte, numero_victima)`.

| Campo | Tipo | Llave | Procedencia | Descripción | Nulos / Sin clasificar |
|---|---|---|---|---|---:|
| `case_id` | INTEGER | PK, FK → parte | FUENTE | | 0 % |
| `numero_parte` | UTINYINT | PK, FK → parte | FUENTE (`party_number`) | Parte (vehículo) en la que viajaba o que la atropelló. | 0 % |
| `numero_victima` | UTINYINT | PK | CONSTRUIDO | `ROW_NUMBER()` por `id` de la fuente dentro de la parte (1–118). Determinista: `id` no se repite dentro de una parte. | 0 % |
| `rol_victima_id` | UTINYINT | FK → rol_victima | FUENTE (`victim_role`) | Conductor, pasajero, peatón... | 0 % |
| `sexo_id` | UTINYINT | FK → sexo | FUENTE (`victim_sex`) | Incluye 1 código basura `'2'`. | 2,41 % sin clasificar |
| `edad` | UTINYINT | | DERIVADO (rango 0–110) | Fuera de rango (incluidos los centinelas 998/999) → NULL. | 3,32 % nulo |
| `edad_en_cuarentena` | BOOLEAN | | CONSTRUIDO | TRUE en 171 víctimas (48 eran centinelas 998/999). | 0 % |
| `lesion_id` | UTINYINT | FK → lesion | FUENTE (`victim_degree_of_injury`) | Grado de lesión; el catálogo lo homologa a KABCO. | 0 % |
| `asiento_id` | UTINYINT | FK → asiento | FUENTE (`victim_seating_position`) | | 0,01 % sin clasificar |
| `equipo_seguridad_1_id` | UTINYINT | FK → equipo_seguridad | FUENTE (`victim_safety_equipment_1`) | | 5,82 % sin clasificar |
| `equipo_seguridad_2_id` | UTINYINT | FK → equipo_seguridad | FUENTE (`victim_safety_equipment_2`) | NULL = no se registró; 1 código basura `'Z'` → 0. | 11,78 % nulo |
| `eyeccion_id` | UTINYINT | FK → eyeccion | FUENTE (`victim_ejected`) | Si salió despedida del vehículo. | 0,08 % sin clasificar |

Distribución KABCO: K = 33.541 · A = 125.566 · B = 641.272 · C = 1.724.379 · O = 1.756.043.

> [!WARNING]
> Desde 2017 la fuente registra ~65 % menos víctimas ilesas (O). Las comparaciones de severidad entre años deben usar K–C. Ver la sección B.9 del [informe de auditoría](../auditoria/RESULTADOS_AUDITORIA.md).

---

## 6. Catálogos de códigos (24)

Estructura común: `<catalogo>_id` UTINYINT PK · `codigo` VARCHAR UNIQUE (valor literal de la fuente; NULL en id 0) · `etiqueta` VARCHAR (español) · `orden` UTINYINT · columnas extra. Contenido completo en `02_poblacion_catalogos.py` y en `data/processed/catalogos/`.

| Catálogo | Filas | Columna de origen | Extras (CONSTRUIDO) |
|---|---:|---|---|
| `clima` | 8 | `weather_1`, `weather_2` | `es_adverso` |
| `iluminacion` | 6 | `lighting` | `es_oscuridad` |
| `superficie` | 5 | `road_surface` | `es_adversa` |
| `condicion_via` | 9 | `road_condition_1`, `road_condition_2` | |
| `dispositivo_control` | 5 | `control_device` | |
| `tipo_colision` | 9 | `type_of_collision` | |
| `implicado_con` | 11 | `motor_vehicle_involved_with` | |
| `factor_primario` | 6 | `primary_collision_factor` | |
| `categoria_infraccion` | 24 | `pcf_violation_category` | `grupo` (6 bloques) |
| `fuga` | 4 | `hit_and_run` | |
| `accion_peaton` | 8 | `pedestrian_action` | |
| `tipo_parte` | 6 | `party_type` | |
| `sobriedad` | 7 | `party_sobriety` | |
| `droga_fisica` | 6 | `party_drug_physical` | |
| `direccion` | 5 | `direction_of_travel` | |
| `movimiento_previo` | 19 | `movement_preceding_collision` | |
| `raza` | 6 | `party_race` | |
| `tipo_vehiculo` | 16 | `statewide_vehicle_type` | `grupo` (7 bloques) |
| `rol_victima` | 6 | `victim_role` | |
| `asiento` | 11 | `victim_seating_position` | |
| `eyeccion` | 5 | `victim_ejected` | |
| `lesion` | 9 | `victim_degree_of_injury` | `kabco`, `nivel` |
| `sexo` | 4 | `party_sex`, `victim_sex` | |
| `equipo_seguridad` | 24 | `*_safety_equipment_1/2` | |

### 6.1. `lesion` — homologación KABCO

| Código de la fuente | Etiqueta | KABCO | Nivel | Vigencia en la fuente |
|---|---|:---:|:---:|---|
| `killed` | Fallecido | K | 4 | Toda la década |
| `severe injury` | Lesión grave | A | 3 | Hasta 2017–2018 |
| `suspected serious injury` | Presunta lesión grave | A | 3 | Desde 2017 |
| `other visible injury` | Lesión visible | B | 2 | Hasta 2017–2018 |
| `suspected minor injury` | Presunta lesión leve | B | 2 | Desde 2017 |
| `complaint of pain` | Queja de dolor | C | 1 | Hasta 2017–2018 |
| `possible injury` | Posible lesión | C | 1 | Desde 2017 |
| `no injury` | Ileso | O | 0 | Toda la década (cobertura reducida desde 2017) |

### 6.2. `categoria_infraccion` — grupos

| Grupo | Categorías |
|---|---|
| Conducta del conductor | velocidad, giro indebido, cambio de carril, distancia, adelantamiento, lado contrario, arranque o retroceso, obstrucción, estacionamiento peligroso, otra infracción peligrosa, otra conducción indebida |
| Prioridad y señalización | prioridad vehicular, prioridad del peatón, semáforos y señales |
| Estado del conductor | conducir bajo los efectos, se durmió |
| Peatón | infracción del peatón, peatón bajo los efectos |
| Vehículo | frenos, luces, otro equipo |
| Otros / no determinado | ajeno al conductor o peatón, desconocido |

### 6.3. `tipo_vehiculo` — grupos

Automóvil · Camioneta · Camión · Motocicleta (incluye ciclomotor) · Autobús · No motorizado (bicicleta, peatón) · Otro. Los grupos `Motocicleta` y `Camión` reproducen exactamente las banderas `motorcycle_collision` y `truck_collision` de la fuente (0 diferencias).

## 7. Catálogos especiales (6)

| Tabla | Filas | PK | Contenido |
|---|---:|---|---|
| `calendario` | 3.652 | `fecha` | Todos los días de 2010–2019 (también los que no tienen colisiones): `anio`, `mes`, `nombre_mes`, `trimestre`, `dia_semana` (1 = lunes, ISO), `nombre_dia`, `es_fin_semana`. |
| `condado` | 59 | `condado_id` | Los 58 condados con su **código oficial** (01 Alameda … 58 Yuba) + id 0. `codigo` = nombre en la fuente. |
| `poblacion` | 9 | `poblacion_id` | Categorías de población de la ciudad (`population`), ordenadas de menor a mayor + id 0. |
| `ubicacion` | 542 | `ubicacion_id` | `county_city_location` del período → `condado_id` (FK) y `poblacion_id` (FK). Resuelve la dependencia transitiva. |
| `severidad` | 5 | `severidad_id` | Nivel KABCO máximo de la colisión: 0 solo daños, 1 dolor, 2 visible, 3 grave, 4 mortal. `codigo` = valor equivalente de `collision_severity`. |
| `banda_edad` | 7 | `banda_edad_id` | Bandas excluyentes 0-17, 18-25, 26-35, 36-50, 51-64, 65+ y 0 = Desconocida (NULL o cuarentena). |

## 8. Vistas en estrella

No se almacenan ni se exportan: son consultas sobre el núcleo (ver `01_creacion_esquema.py`).

| Vista | Grano | Agrega al núcleo |
|---|---|---|
| `vw_hecho_colision` | colisión | `condado_id`, `poblacion_id`, `severidad_id` derivada, `victimas`, `muertos`, `heridos_graves`, `heridos_visibles`, `heridos_leves`, `heridos_total`, `partes`, banderas `peaton/ciclista/motociclista/camion_implicado`, datos del culpable (`tipo_parte_culpable_id`, `tipo_vehiculo_culpable_id`, `edad_culpable` de cualquier tipo de parte, **`edad_conductor_culpable`** solo si el culpable es conductor —variable del Objetivo 2—, `anio_vehiculo_culpable`, `edad_vehiculo_culpable`), `tiene_coordenadas`, `tiene_datos_caltrans`. |
| `vw_hecho_parte` | parte | `fecha`, `condado_id`, `banda_edad_id`, **`edad_vehiculo`**, lesión máxima, víctimas, muertos y heridos de esa parte. |
| `vw_hecho_victima` | víctima | `kabco`, `nivel_lesion`, `banda_edad_id`, tipo, año-modelo y **`edad_vehiculo`** del vehículo de su parte, `parte_culpable`, `fecha`, `condado_id`. |

`edad_vehiculo` = año de la colisión − año-modelo, acotada a 0: 34.314 partes tienen un modelo del año siguiente al siniestro (auditoría B.11). Es la variable del Objetivo 4; el año-modelo solo mezcla la antigüedad del vehículo con la tendencia del calendario.

## 9. Campos de la fuente que no se migran

| Campos | Motivo |
|---|---|
| Los 19 derivables de `collisions` (sección 1) y 2 de `parties` | Redundantes en 3FN: se recalculan en las vistas sin diferencias. |
| `not_private_property`, `pcf_violation_code`, `oaf_violation_code`, `route_suffix` | Sin información (constante o ≥ 99,9 % nulos). |
| `parties.id`, `victims.id`, tabla `case_ids` | No son claves o son redundantes. |
| `officer_id`, `reporting_district`, `chp_shift`, `beat_type`, `chp_beat_type`, `chp_beat_class`, `beat_number`, `city_division_lapd`, `chp_road_type`, `primary_road`, `secondary_road`, `distance`, `direction`, `primary_ramp`, `secondary_ramp`, `process_date`, `county_location`, `population` | Administrativos o de texto libre sin uso en los objetivos; `county_location` y `population` viven en `ubicacion`. Recuperables desde la fuente por `case_id`. |
