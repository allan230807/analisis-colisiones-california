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
