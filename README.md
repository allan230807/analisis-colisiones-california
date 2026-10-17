# Perfiles de riesgo en colisiones de tránsito — California (2010–2019)

Investigación descriptiva e inferencial sobre **colisiones de tránsito en California durante el período decenal 2010–2019** a partir del registro oficial **SWITRS** (*Statewide Integrated Traffic Records System*), administrado por la *California Highway Patrol* (CHP).

> **Escuela de Estadística y Ciencias Actuariales (EECA-UCV) — Cátedra de Computación II**  
> **Estado del proyecto:** Fase 1 (Auditoría Integral y Calidad de Datos) completada y verificada.

---

## 📌 Planteamiento del problema

La seguridad vial constituye un problema crítico de salud pública. La Organización Mundial de la Salud (OMS, 2023) estimó que las lesiones viales son una de las principales causas de muerte en personas de 5 a 29 años a nivel global.

En California, el sistema **SWITRS** recopila reportes policiales estandarizados sobre colisiones, conductores, vehículos y víctimas. Para estudiar este fenómeno con rigor estadístico y metodológico, este proyecto analiza la serie decenal **2010–2019**, correspondiente a 10 años continuos de registros oficiales previos a las distorsiones de movilidad derivadas de la pandemia.

---

## 🎯 Pregunta y Objetivo General

> **¿Qué patrones temporales y geográficos presentan las colisiones registradas en California durante 2010–2019, y qué asociaciones se observan entre la edad del conductor, la severidad de la colisión, las condiciones de iluminación y meteorológicas, y el año-modelo del vehículo involucrado?**

**Objetivo general:**  
Analizar los registros de colisiones de tránsito de California correspondientes al período 2010–2019 mediante técnicas de estadística descriptiva e inferencial, para identificar patrones temporales y espaciales, describir las condiciones ambientales registradas y examinar las asociaciones entre la edad del conductor, la severidad del evento y el año-modelo del vehículo, dejando los datos normalizados, tipados y optimizados para su explotación analítica en un tablero interactivo.

---

## 📋 Objetivos Específicos

| # | Pregunta específica | Objetivo específico | Variable clave auditada |
|---|---|---|---|
| **1** | ¿Qué patrones temporales y espaciales presentan las colisiones entre 2010 y 2019 según año, mes, día de semana, hora y condado? | Describir patrones temporales y geográficos mediante frecuencias y proporciones decenales. | `collision_date`, `collision_time`, `county_city_location` → `county_location`. |
| **2** | ¿Existe asociación estadísticamente significativa entre la edad del conductor culpable y la gravedad de la colisión? | Evaluar mediante contrastes de hipótesis la asociación entre la edad del conductor culpable (a lo sumo uno por colisión) y la severidad registrada. | `party_age`, `party_type`, `at_fault`, `collision_severity`. |
| **3** | ¿Cómo se distribuyen las colisiones según las condiciones ambientales reportadas? | Caracterizar la distribución de siniestros según iluminación y clima reportados. | `weather_1`, `lighting`. |
| **4** | ¿Qué patrones se observan entre el año-modelo del vehículo y la severidad de las lesiones de sus ocupantes? | Examinar la relación entre el año de fabricación del vehículo y la lesión de las víctimas asociadas a ese vehículo (distinguiendo recuento de riesgo relativo). | `vehicle_year`, `victim_degree_of_injury` homologada a KABCO. |
| **5** | ¿Cómo estructurar una fuente de ~9,9 GB para analizarla y visualizarla de forma eficiente? | Diseñar un modelo normalizado en 3FN, tipado y sin columnas derivables, y una capa de vistas en estrella que alimente un tablero en Power BI con filtros cruzados. | Claves, dependencias funcionales, columnas derivables, tipos físicos y medidas calculadas sobre el grano correcto. |

---

## 🔬 Alcance y Limitaciones Metodológicas

- **Período de estudio:** 1 de enero de 2010 al 31 de diciembre de 2019 inclusivo (4.368.293 colisiones verificadas; 3.652 días con datos).
- **Cobertura geográfica:** Los 58 condados del estado de California.
- **Georreferenciación:** El 49,44% de las colisiones dispone de coordenadas válidas (latitud 32°–43° N, longitud -125° a -114° O); el 50,56% presenta coordenadas nulas. En el modelo dimensional, las coordenadas se tratan en una tabla de extensión satélite `1:0..1` sin imputación artificial.
- **Variable de alcohol:** `alcohol_involved` registra únicamente presencia confirmada (`1`, 10,09%) o no reportado/desconocido (`NULL`, 89,91%). No contiene ceros; no se imputa como sobriedad verificada.
- **Año del vehículo:** Se audita y preserva explícitamente `vehicle_year` en el rango verificado 1900–2020 para responder al Objetivo 4, documentando que el conteo de siniestros no equivale a una tasa de riesgo sin denominadores de exposición (parque circulante o millas transitadas).
- **Unidad de análisis del Objetivo 2:** Hay en promedio 1,78 conductores por colisión, por lo que relacionar la edad de *todos* los conductores con la severidad de la colisión contaría cada colisión varias veces. Se usa el conductor culpable (`at_fault = 1`), que existe en el 93,05% de las colisiones y nunca es más de uno.
- **Lesión de víctimas desde 2017:** SWITRS recodificó `victim_degree_of_injury` en 2017–2018 y desde 2017 registra ~65% menos víctimas ilesas. La lesión se homologa a la escala KABCO (K, A, B, C, O); las comparaciones de severidad usan K–C y el total de víctimas no se compara antes y después de 2017.
- **Redundancia de la fuente:** 21 columnas de la fuente son recalculables desde el detalle (conteos de víctimas, `party_count`, `collision_severity`, banderas de tipo de colisión). El modelo normalizado no las almacena y las calcula en vistas.

---

## 📁 Estructura Real del Repositorio

```
analisis-colisiones-california/
├── README.md                           ← Documentación general del proyecto y estado
├── requirements.txt                    ← Dependencias de entorno
├── .gitignore                          ← Exclusión de binarios y fuentes crudas pesadas
│
├── auditoria/                          ← FASE 1: AUDITORÍA INTEGRAL DE DATOS ✅
│   ├── 01_catalogos_frecuencias.sql    ← Diagnóstico de categorías, frecuencias y valores centinela
│   ├── 02_volumen_temporal.sql         ← Series anuales, mensuales, semanales, horarias y geográficas
│   ├── 03_nulos_semantica.sql          ← Análisis de completitud, nulos y reglas semánticas
│   ├── 04_fanout_rangos.sql            ← Controles anti fan-out, consistencia de medidas y cuarentena
│   ├── 05_integridad_duplicados.sql    ← Unicidad de claves primarias, foráneas y orfandad
│   ├── 06_decision_estrella.sql        ← Modelo objetivo: núcleo 3FN + vistas en estrella
│   ├── 07_dependencias_tipos.sql       ← Dependencias funcionales, columnas derivables, tipos y KABCO
│   └── RESULTADOS_AUDITORIA.md         ← Informe técnico con evidencia empírica decenal (2010–2019)
│
└── data/                               ← No versionado (.gitignore)
    └── raw/
        └── switrs.sqlite               ← Base de datos original SWITRS (~9,9 GB, 2001–2021)
```

Directorios previstos para fases siguientes (aún no existen): `src/` (pipeline de normalización, Fase 2), `data/processed/` (Parquet normalizado, Fase 2), `notebooks/` (inferencia, Fase 3) y `visualizaciones/` (Power BI, Fase 4).

---

## ⚙️ Requisitos y Configuración del Entorno

### 1. Requisitos de software
- **DuckDB CLI** versión 1.1 o superior (recomendado para ejecución analítica de los scripts SQL).
- Fuente original `switrs.sqlite` descargada y ubicada en `data/raw/switrs.sqlite`.

### 2. Instalación de dependencias
La auditoría solo necesita el CLI de DuckDB. `requirements.txt` declara las dependencias Python (DuckDB, PyArrow, pandas) que usará el pipeline de la Fase 2:
```bash
pip install -r requirements.txt
```

Los scripts usan la ruta relativa `data/raw/switrs.sqlite`, por lo que deben ejecutarse **desde la raíz del repositorio**.

---

## 🚀 Ejecución de los scripts SQL de auditoría

Los scripts de auditoría están parametrizados para operar en modo solo lectura (`READ_ONLY`), sin alterar los datos originales ni crear tablas prematuras en la base de datos fuente. Cada script consulta directamente el archivo `data/raw/switrs.sqlite` a través de DuckDB.

Para ejecutarlos de forma secuencial:
```bash
# 1. Catálogos y frecuencias de variables categóricas
duckdb -dark-mode < auditoria/01_catalogos_frecuencias.sql

# 2. Análisis temporal (año, mes, día, hora) y espacial (condado)
duckdb -dark-mode < auditoria/02_volumen_temporal.sql

# 3. Semántica de nulos y banderas de siniestros
duckdb -dark-mode < auditoria/03_nulos_semantica.sql

# 4. Verificación de medidas aditivas y rangos atípicos
duckdb -dark-mode < auditoria/04_fanout_rangos.sql

# 5. Integridad referencial de claves primarias y registros huérfanos
duckdb -dark-mode < auditoria/05_integridad_duplicados.sql

# 6. Matriz de cardinalidad y modelo objetivo (núcleo 3FN + vistas estrella)
duckdb -dark-mode < auditoria/06_decision_estrella.sql

# 7. Dependencias funcionales, columnas derivables, tipos físicos y homologación KABCO
duckdb -dark-mode < auditoria/07_dependencias_tipos.sql
```

---

## 📊 Estado de Pruebas y Fases del Proyecto

- **Fase 1: Auditoría Integral y Calidad de Datos (COMPLETADA ✅)**
  - Se eliminó `auditoria/validar_auditoria.py`; las validaciones pasan por la ejecución directa de los 7 scripts SQL sobre DuckDB.
  - Resultados empíricos, conteos y porcentajes documentados en [`auditoria/RESULTADOS_AUDITORIA.md`](auditoria/RESULTADOS_AUDITORIA.md).
- **Fase 2: Normalización y Pipeline ETL (PENDIENTE ⏳)**
  - Núcleo en 3FN: `colision`, `colision_geo` (1:0..1), `colision_carretera` (1:0..1), `parte`, `victima`, catálogo `ubicacion` y catálogos de códigos con `id = 0 Sin clasificar` (diseño en la sección D del informe de auditoría).
  - Tipado físico mínimo (`case_id` INTEGER, `DATE`/`TIME`, ids `UTINYINT`) y sin columnas derivables.
  - Vistas en estrella para Power BI sobre el núcleo; exportación a Parquet particionado por año con compresión ZSTD.
- **Fase 3: Análisis Inferencial y Modelado Estadístico (PENDIENTE ⏳)**
  - Contrastes de hipótesis sobre edad del conductor vs. severidad y modelos multivariados.
- **Fase 4: Tablero Ejecutivo en Power BI (PENDIENTE ⏳)**
  - Construcción del dashboard interactivo con navegación temporal y geográfica.

---

## 📚 Referencias

- California Highway Patrol. (s. f.). *Annual report of fatal and injury motor vehicle traffic collisions*. SWITRS.
- Hanrahan, R. B., Layde, P. M., Zhu, S., Guse, C. E., & Hargarten, S. W. (2009). The association of driver age with traffic injury severity in Wisconsin. *Traffic Injury Prevention*, 10(4), 361–367.
- Kimball, R., & Ross, M. (2013). *The Data Warehouse Toolkit: The Definitive Guide to Dimensional Modeling* (3rd ed.). Wiley.
- National Highway Traffic Safety Administration. (2013). *How vehicle age and model year relate to driver injury severity in fatal crashes* (Report No. DOT HS 811 825).
- Organización Mundial de la Salud. (2023). *Informe sobre la situación mundial de la seguridad vial 2023: resumen*. OMS.