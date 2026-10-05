# Perfiles de riesgo en colisiones de tránsito — California (2016–2021)

Investigación descriptiva sobre **colisiones de tránsito en California (2016–2021)** a partir del registro oficial **SWITRS**. Integramos `collisions`, `parties` y `victims` para construir perfiles de riesgo que crucen **factor primario, severidad, entorno, demografía y comportamiento**.

> **Escuela de Estadística y Ciencias Actuariales (EECA-UCV) — Computación II**

---

## 🎯 Planteamiento del problema (resumido)

El SWITRS contiene millones de registros, pero **su uso directo es inviable**: no tiene índices, mezcla nomenclaturas, arrastra nulos masivos (71 % en coordenadas, 90 % en indicador de alcohol), y las tablas `collisions`, `parties` y `victims` viven desconectadas.  

**Pregunta de investigación**  
> ¿Qué patrones de siniestralidad emergen al cruzar factor primario, severidad, variables demográficas, vehiculares, temporales y geográficas en California 2016–2021, y cómo pueden traducirse en **perfiles descriptivos de riesgo**?

**Objetivo general**  
Normalizar, integrar y analizar el universo SWITRS 2016–2021 para entregar un **Data Lake columnar** y una **aplicación interactiva** que expongan esos perfiles, separando siempre descripción de causalidad.

---

## ✅ Estado actual: Fase 1 completada (Auditoría empírica)

| Script | Qué valida | Hallazgo clave |
|---|---|---|
| `01_cardinalidad_dimensiones.sql` | Cardinalidad de 20 dimensiones candidatas | Todas < 32 767 → **SMALLINT para FKs** |
| `02_volumen_datos.sql` | Volumen de tablas de hechos | 9,4 M – 18,7 M filas → **INTEGER para PKs** |
| `03_nulos_e_inconsistencias.sql` | Nulos en claves y atributos | 0 % nulos en `case_id`, `party_number`; 71 % en lat/lon |
| `04_duplicados_dimensiones.sql` | Unicidad en dimensiones existentes | 2 dimensiones con `"unknown"` duplicado → corregir |
| `05_textos_repetitivos.sql` | Atributos degenerados vs. dimensiones | `county_location` (58 valores) → **nueva `dim_county`** |
| `06_integridad_referencial.sql` | Huérfanos entre tablas | **0 huérfanos** (100 % integridad) |
| `07_distribucion_medidas.sql` | Rango de medidas aditivas | Máx. 8 744 (`vehicle_year`) → **SMALLINT suficiente** |
| `08_resumen_ejecutivo.sql` | Consolidado de decisiones | 6 decisiones validadas, 5 hallazgos accionables |

**Entregable:** [`auditoria/RESULTADOS_AUDITORIA.md`](auditoria/RESULTADOS_AUDITORIA.md) — interpretación y acciones por hallazgo.

---

## 📁 Estructura del repositorio (lo commiteado)

```
analisis-colisiones-california/
├── .gitignore                    # data/, .vscode/, venv/, *.sqlite, etc.
├── requirements.txt              # duckdb, pandas, streamlit, etc.
├── README.md                     # Este archivo
│
├── auditoria/                    # FASE 1 — 8 scripts SQL + resultados
│   ├── 01_cardinalidad_dimensiones.sql
│   ├── 02_volumen_datos.sql
│   ├── 03_nulos_e_inconsistencias.sql
│   ├── 04_duplicados_dimensiones.sql
│   ├── 05_textos_repetitivos.sql
│   ├── 06_integridad_referencial.sql
│   ├── 07_distribucion_medidas.sql
│   ├── 08_resumen_ejecutivo.sql
│   └── RESULTADOS_AUDITORIA.md
│
├── data/
│   └── raw/
│       └── switrs.sqlite         # Fuente cruda (no versionada, ~9 GB)
│
└── src/                          # FASE 2+ (pendiente)
    ├── 01_creacion_esquema.py
    ├── 02_poblacion_dimensiones.py
    ├── 03_procesamiento_carga.py
    └── 04_exportacion_parquet.py
```

---

## 🗺️ Roadmap

| Fase | Estado | Entregable |
|---|---|---|
| 1. Auditoría y diseño | ✅ | `auditoria/` + decisiones validadas |
| 2. Dimensiones (calendario, demográficas, entorno, junk) | ⏳ | Esquema estrella + 13+ dimensiones |
| 3. Normalización `parties` / `victims` | ⏳ | Hechos integrados con FKs |
| 4. Tabla de hechos `colisiones_integrada` | ⏳ | Métricas exactas × perfiles de riesgo |
| 5. Data Lake Parquet particionado por año | ⏳ | Listo para Streamlit / Power BI |

---

## ⚙️ Stack confirmado

| Capa | Herramienta | Por qué |
|---|---|---|
| Motor analítico | **DuckDB** | Hash joins sobre 9 GB sin índices en ~3 s; lee `.sqlite` directo |
| Formato Data Lake | **Parquet + ZSTD** | Columnar, ~15× compresión, poda de particiones por año |
| App interactiva | **Streamlit** | Documentación + diccionario + terminal SQL + resultados |
| Tablero ejecutivo | **Power BI** | Visualización geográfica y temporal para presentación |

---

## 🚀 Puesta en marcha (solo auditoría, por ahora)

```bash
git clone https://github.com/allan230807/analisis-colisiones-california.git
cd analisis-colisiones-california
pip install -r requirements.txt

# Descargar switrs.sqlite de Kaggle y colocar en data/raw/
# Ejecutar scripts de auditoría contra la base cruda:
sqlite3 data/raw/switrs.sqlite < auditoria/01_cardinalidad_dimensiones.sql
sqlite3 data/raw/switrs.sqlite < auditoria/02_volumen_datos.sql
# ... resto de scripts 03–08
```

---

## ⚠️ Limitaciones declaradas (no se corrigen, se documentan)

- **Registro administrativo, no censo:** faltan colisiones leves sin parte policial → letalidad calculada ≥ real.
- **Factor primario = atribución del agente**, no medición objetiva.
- **Cobertura geo crece 0 % → ~66 %** (2001–2020); en 2016–2021 ya arranca con coordenadas.
- **Alcohol:** `1` o vacío (nunca `0`) → ETL normaliza a `0`.
- **Códigos basura** (`21804`, `N`, `I`, `O`, `H`, `J`) → caen en `Sin clasificar`.
- **Valores atípicos detectados:** `vehicle_year = 8744`, `victim_age = 999` → se investigarán en Fase 2.

---

## 📚 Fuente

**California Traffic Collision Data from SWITRS** — Kaggle  
https://www.kaggle.com/datasets/alexgude/california-traffic-collision-data-from-switrs

Registro oficial: *California Highway Patrol — Statewide Integrated Traffic Records System (SWITRS)*

---

## 👥 Créditos

Proyecto académico — **EECA-UCV / Computación II**  
Metodología: Kimball (dimensional) + DuckDB (columnar) + auditoría empírica antes de escribir ETL.