# Perfiles de riesgo en colisiones de tránsito — California (2010–2019)

Investigación descriptiva e inferencial sobre **colisiones de tránsito en California (2010–2019)** a partir del registro oficial **SWITRS** (*Statewide Integrated Traffic Records System*). Integramos `collisions`, `parties` y `victims` para construir perfiles de riesgo que crucen **factor primario, severidad, entorno, demografía y comportamiento**.

> **Escuela de Estadística y Ciencias Actuariales (EECA-UCV) — Computación II**

---

## 📌 Planteamiento del problema

La seguridad vial constituye un **problema de salud pública**. La Organización Mundial de la Salud estimó que en 2021 las colisiones de tránsito ocasionaron alrededor de **1,19 millones de muertes** en el mundo, y señaló que las lesiones viales siguen siendo una de las **principales causas de muerte entre personas de 5 a 29 años** (OMS, 2023).

Comprender este fenómeno requiere analizar no solo cuántas colisiones ocurren, sino también **cómo se distribuyen en el tiempo y el territorio** y **qué características aparecen asociadas con sus consecuencias**.

En California, el sistema **SWITRS** (*Statewide Integrated Traffic Records System*), administrado por la *California Highway Patrol*, recopila información sobre colisiones y publica resúmenes por tiempo, ubicación, conductores y vehículos. Su informe anual de 2019 incluye series de diez años para **2010–2019** y reporta, para 2019, **3.438 colisiones mortales** y **187.211 colisiones con lesiones** (CHP, s. f.). Estos registros permiten estudiar patrones durante una década utilizando un marco temporal y geográfico definido.

La literatura científica señala que:
- La **edad del conductor** puede estar asociada con la severidad de las lesiones (Hanrahan et al., 2009).
- Las **condiciones viales y ambientales** (iluminación, entorno) se asocian con la severidad (Jafari Anarkooli & Hadji Hosseinlou, 2016; Wang & Zhang, 2017).
- El **año-modelo del vehículo** se relaciona con la severidad de lesiones en colisiones mortales (NHTSA, 2013), aunque la cantidad de vehículos observados no demuestra por sí sola mayor probabilidad de colisionar; para estimar riesgo se necesitarían datos de exposición (vehículos en circulación o millas recorridas).

---

## 🎯 Pregunta de investigación

> **¿Qué patrones presentan las colisiones de tránsito registradas en California durante 2010–2019, y qué asociaciones se observan entre la edad del conductor, la severidad de la colisión, las condiciones ambientales registradas y el año-modelo del vehículo involucrado?**

---

## 🎯 Objetivo general

> **Analizar los registros de colisiones de tránsito de California correspondientes al período 2010–2019 mediante técnicas de estadística descriptiva e inferencial, para identificar patrones temporales y geográficos, describir las condiciones ambientales reportadas y examinar las asociaciones entre la edad del conductor, la severidad de la colisión y el año-modelo del vehículo.**

---

## 📋 Preguntas y objetivos específicos

| # | Pregunta específica | Objetivo específico |
|---|---|---|
| **1** | ¿Qué patrones temporales y geográficos presentan las colisiones registradas en California entre 2010 y 2019, considerando el año, el mes, el día de la semana, la hora y el condado? | Identificar los patrones temporales y geográficos de las colisiones mediante frecuencias y proporciones por año, mes, día de la semana, hora y condado. |
| **2** | ¿Existe una asociación estadísticamente significativa entre la edad del conductor involucrado y la severidad registrada de la colisión? | Evaluar, mediante un contraste de hipótesis, si existe asociación estadísticamente significativa entre la edad del conductor y la severidad de la colisión. <br> **H₀**: no existe asociación estadísticamente significativa entre la edad del conductor y la severidad de la colisión.<br> **H₁**: existe asociación estadísticamente significativa entre ambas variables. La prueba definitiva se seleccionará según la codificación y distribución de los datos, comprobando sus supuestos. |
| **3** | ¿Cómo se distribuyen las colisiones según las condiciones de iluminación y meteorológicas reportadas durante 2010–2019? | Describir la distribución de las colisiones según las condiciones de iluminación y meteorológicas reportadas, utilizando frecuencias, porcentajes y representaciones gráficas. |
| **4** | ¿Se observan patrones en la distribución de las colisiones y su severidad según el año-modelo del vehículo involucrado? | Examinar los patrones observados entre el año-modelo de los vehículos y la severidad registrada de las colisiones, distinguiendo el número de casos de una estimación del riesgo. |
| **5** | — | Diseñar un tablero interactivo en **Power BI** que permita explorar los principales resultados por período, condado, severidad, edad del conductor, condiciones ambientales y año-modelo del vehículo. |

---

## 🔬 Alcance del análisis

- **Período**: 1 de enero de 2010 – 31 de diciembre de 2019 (SWITRS).
- **Campos**: los disponibles en `collisions`, `parties` y `victims`.
- **Tratamiento de datos**: valores faltantes o desconocidos contabilizados y tratados de forma transparente; evitación de duplicados al relacionar colisiones, conductores y vehículos.
- **Naturaleza de los resultados**: descriptivos e inferenciales; **no demuestran causalidad**.
- **Limitación clave**: los registros por año-modelo **no se interpretarán como tasas de riesgo** sin un denominador de exposición adecuado (vehículos en circulación o millas recorridas).

---

## 🛠️ Pipeline de datos (estado actual)

```
Kaggle: switrs.sqlite (9.3 GB, 4 tablas, SIN ÍNDICES)
        │
        ▼
[ETL con DuckDB]  Normalización a 3FN · esquema en estrella · 1:0..1
        │
        ▼
Base normalizada DuckDB (13+ dimensiones · 3 hechos)
        │
        ▼
[Exportación]  Parquet + ZSTD, PARTICIONADO POR AÑO (10 archivos 2010-2019)
        │
        ▼
Data Lake (versionado en repo)
        │
        ├──▶ DuckDB + Streamlit  (investigación interactiva)
        └──▶ Power BI Desktop    (tablero ejecutivo)
```

**Stack tecnológico**:

| Capa | Herramienta | Por qué |
|---|---|---|
| Motor analítico | **DuckDB** | Hash joins sobre 9 GB sin índices en ~3 s; lee `.sqlite` directo |
| Formato Data Lake | **Parquet + ZSTD** | Columnar, ~15× compresión, poda de particiones por año |
| App interactiva | **Streamlit** | Documentación + diccionario + terminal SQL + resultados |
| Tablero ejecutivo | **Power BI** | Visualización geográfica y temporal para presentación |

---

## 📁 Estado del repositorio (Fase 1 completada)

```
analisis-colisiones-california/
├── .gitignore
├── requirements.txt
├── README.md
│
├── auditoria/                    ← FASE 1 ✅
│   ├── 01_catalogos_frecuencias.sql
│   ├── 02_volumen_temporal.sql
│   ├── 03_nulos_semantica.sql
│   ├── 04_fanout_rangos.sql
│   ├── 05_integridad_duplicados.sql
│   ├── 06_decision_estrella.sql
│   └── RESULTADOS_AUDITORIA.md
│
├── data/
│   └── raw/switrs.sqlite         ← Fuente cruda (no versionada, ~9 GB)
│
├── src/                          ← FASE 2+ ⏳
│   ├── 01_creacion_esquema.py
│   ├── 02_poblacion_dimensiones.py
│   ├── 03_procesamiento_carga.py
│   └── 04_exportacion_parquet.py
│
├── notebooks/                    ← Exploración y validación ⏳
├── visualizaciones/              ← Gráficos y dashboards ⏳
└── assets/                       ← Recursos visuales ⏳
```

---

## 🚀 Puesta en marcha

```bash
# 1. Clonar
git clone https://github.com/allan230807/analisis-colisiones-california.git
cd analisis-colisiones-california

# 2. Dependencias
pip install -r requirements.txt

# 3. Descargar switrs.sqlite de Kaggle y colocar en data/raw/
# 4. Ejecutar auditoría (ya validada)
duckdb < auditoria/01_catalogos_frecuencias.sql
duckdb < auditoria/02_volumen_temporal.sql
duckdb < auditoria/03_nulos_semantica.sql
duckdb < auditoria/04_fanout_rangos.sql
duckdb < auditoria/05_integridad_duplicados.sql
duckdb < auditoria/06_decision_estrella.sql
```

---

## ⚠️ Limitaciones declaradas

- **Registro administrativo, no censo**: faltan colisiones leves sin parte policial → letalidad calculada ≥ real.
- **Factor primario = atribución del agente**, no medición objetiva.
- **Cobertura geo crece** a lo largo del período.
- **Alcohol**: `1` o vacío (nunca `0`) → ETL normaliza a `0`.
- **Códigos basura** (`21804`, `N`, `I`, `O`, `H`, `J`) → caen en `Sin clasificar`.
- **Valores atípicos**: `vehicle_year = 8744`, `victim_age = 999` → cuarentena documentada.
- **Sin denominador de exposición**: año-modelo ≠ tasa de riesgo.

---

## 📚 Referencias

- California Highway Patrol. (s. f.). *2019 annual report of fatal and injury motor vehicle traffic collisions*. SWITRS.
- Hanrahan, R. B., Layde, P. M., Zhu, S., Guse, C. E., & Hargarten, S. W. (2009). The association of driver age with traffic injury severity in Wisconsin. *Traffic Injury Prevention*, 10(4), 361–367.
- Jafari Anarkooli, A., & Hadji Hosseinlou, M. (2016). Analysis of the injury severity of crashes by considering different lighting conditions on two-lane rural roads. *Journal of Safety Research*, 56, 57–65.
- National Highway Traffic Safety Administration. (2013). *How vehicle age and model year relate to driver injury severity in fatal crashes* (Report No. DOT HS 811 825).
- Organización Mundial de la Salud. (2023). *Informe sobre la situación mundial de la seguridad vial 2023: resumen*.
- Wang, Y., & Zhang, W. (2017). Analysis of roadway and environmental factors affecting traffic crash severities. *Transportation Research Procedia*, 25, 2119–2125.

---

## 👥 Créditos

Proyecto académico — **EECA-UCV / Computación II**  
Metodología: Kimball (dimensional) + DuckDB (columnar) + auditoría empírica antes de escribir ETL.

---

*Última actualización: 2026-10-17 — Auditoría v2 completada y versionada (6 scripts). Siguiente: Fase 2 — esquema estrella + ETL.*