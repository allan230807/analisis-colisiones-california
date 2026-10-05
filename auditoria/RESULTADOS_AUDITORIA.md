# Resultados de Auditoría v2 — Fase 1: Diseño Conceptual del Esquema Estrella

**Fecha:** 2026-10-05 (v2; supersede v1 del 2026-10-04)
**Base:** SWITRS California · periodo de estudio 2016-2021
**Motor:** DuckDB + `ATTACH sqlite READ_ONLY` (SQLite puro hace timeout sobre 9-18M de filas)
**Alcance:** solo SELECTs de diagnóstico. Cada script cierra con `DECISION_NORMALIZACION`
que documenta la acción futura sin ejecutarla. Cero DDL en auditoría.

**Números base verificados (periodo 2016-01-01 a 2021-12-31, corte real 2021-06-03):**

| Universo | Filas periodo | Nota |
|---|---|---|
| collisions | 2.429.886 | 2016:491.619 · 2017:486.432 · 2018:482.296 · 2019:470.352 · 2020:366.417 · 2021:132.770 (parcial) |
| parties | 4.836.559 | via EXISTS al periodo |
| victims | periodo en 01-S00c | via EXISTS al periodo |
| case_id periodo | 2.429.886 únicos, 0 repetidos | PK válida del grano colisión |
| calendario | 2.192 días esperados · 1.981 con datos · 211 en cero (cola 2021-06-04+) | dim_fecha precargada + flag tiene_datos |
| coordenadas | 1.514.605 con lat/lon (62,3 %) · 915.281 sin geo (37,7 %) | tabla geo 1:0..1 + bandera |
| condados | 58 distintos exactos | nueva dim_county |
| huérfanos | 0 parties · 0 victims · 0 victims-sin-party | integridad 100 % |

---

## 01_catalogos_frecuencias.sql — TOP 30 + nulos + basura por campo

**Qué hace:** un TOP valor/n/pct por cada campo candidato (11 de collisions + 5 de parties + 5 de victims) con pct sobre CTE (sin `SUM(COUNT(*))` en línea), más 3 bloques UNION ALL de nulos + basura canónica (`21804,N,I,O,H,J`; sexo con `LOWER(TRIM()) NOT IN (male,female)`).

**Qué se hará en normalización:** cada TOP es el seed del catálogo; NULL + basura caen en `id=0 Sin clasificar`; cada dim guarda `codigo_original + descripcion_ES + orden/grupo`.

## 02_volumen_temporal.sql — volumen + calendario + partición

**Qué hace:** totales, por-año sin `GROUPING SETS` (GROUP BY simple + total aparte), calendario canónico `RANGE(DATE'2016-01-01', DATE'2022-01-01', INTERVAL 1 DAY)` = 2.192 exactos, días en cero, intensidad diaria (promedio 1.108,5 · pico 2.028).

**Qué se hará en normalización:** hecho particionado por año (6 particiones); 2021 documentada como parcial; `dim_fecha` con 2.192 días + flag para que los ceros no rompan series.

## 03_nulos_semantica.sql — 3 semánticas de NULL, no una

**Qué hace:** banderas (C01-C02), coordenadas (C03-C04 con pares incompletos, ceros y fuera de CA), códigos/textos (C05-C07). Los atípicos de edad/año se ven en 04. Una sentencia por grupo; `parties/victims` vía `EXISTS`.

**Qué se hará en normalización:** banderas → `BOOLEAN NOT NULL` con `COALESCE(col,0)` (T6); lat/lon → tabla 1:0..1 + `tiene_coordenadas` (nunca imputar coordenadas); códigos → dim con `id=0`; edades/año → grupos con Desconocido + cuarentena en 04; `collision_time NULL` se mantiene.

## 04_fanout_rangos.sql — anti fan-out + cuarentena (hallazgos medidos)

| Control | Declarado | Real | Diferencia | Decisión |
|---|---|---|---|---|
| SUM(party_count) vs COUNT(parties) | 4.836.555 | 4.836.559 | **−4** | derivar COUNT desde parties |
| SUM(killed_victims) vs killed por grado | 19.687 | 19.687 | **0 CUADRA** | medida confiable |
| SUM(injured_victims) vs lesión confirmada | 1.374.050 | 1.374.048 | **+2** (unknown 0) | documentar |
| party_age / victim_age | 998/999 presentes | — | — | CUARENTENA, bandas 0-110 |
| vehicle_year | máx 8.744 | — | — | CUARENTENA 1900-2022 |
| bbox CA 32-43 / −125..−114 | — | — | — | CUARENTENA fuera de rango |
| party_count 0 / >20 | — | — | — | CUARENTENA |

**Qué se hará en normalización:** prohibido el JOIN triple para contar; `AVG` solo sobre rango limpio; cuarentenas documentadas en diccionario.

## 05_integridad_duplicados.sql — dedup + NOT EXISTS + unicidad

**Qué hace:** duplicados con `STRING_AGG(CAST(id AS VARCHAR), ', ' ORDER BY id)` (forma canónica), integridad con `NOT EXISTS` (global + fuera de periodo + muestra 20), unicidad de `case_id` en el periodo.

**Hallazgos:** solo 2 duplicados reales — `dim_factor_colision.descripcion='unknown' x2 (ids 5,5)` y `dim_categoria_pcf.descripcion='unknown' x2 (ids 20,20)`; resto limpio; `case_id` único (0 repetidos).

**Qué se hará en normalización:** deduplicar esas 2 dims antes de crear FKs; `case_id` como PK del grano; validar FK compuesta `victims(case_id,party_number)→parties`; ETL solo con claves del periodo.

## 06_decision_estrella.sql — matriz calculada, no texto estático

**Qué hace:** cardinalidad exacta en el periodo + `CASE(DIMENSION<=200 / EVALUAR<=5000 / DEGENERADO)` por candidato, TOP 25 `vehicle_make` y `primary_road`, condados (58), flags a TINYINT, cobertura geo, prueba `ROW_NUMBER() OVER (ORDER BY collision_date, case_id)` determinista y lista final.

**Decisión (10 dimensiones):** `dim_fecha · dim_county (nueva, 58) · dim_severidad · dim_entorno (clima+luz) · dim_vial (superficie+condición+control) · dim_tipo_colision · dim_causa (factor+pcf, deduplicada) · dim_grado_lesion · dim_actor (sexo+bandas edad) · dim_vehiculo`. Flags peaton/bicicleta/moto/camión/alcohol como TINYINT; geo 1:0..1; `vehicle_make`, `primary_road`, `officer_id` degenerados; surrogate entero determinista.

---
