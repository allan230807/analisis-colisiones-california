"""
01_creacion_esquema.py
================================================================================
CREACION DEL ESQUEMA NORMALIZADO (3FN) Y DE LA CAPA DE VISTAS EN ESTRELLA
Proyecto: Perfiles de riesgo en colisiones de transito — California (2010-2019)
Escuela de Estadistica y Ciencias Actuariales (EECA-UCV) — Computacion II
================================================================================

QUE SE CREA
-----------
Tres capas, cada una justificada por la auditoria (auditoria/RESULTADOS_AUDITORIA.md):

  1. CATALOGOS (30 tablas): 24 catalogos de codigos con id = 0 "Sin clasificar"
     + calendario, condado, poblacion, ubicacion, severidad y banda_edad.

  2. NUCLEO 3FN (5 tablas). Cada atributo depende solo de la clave de su tabla:

        colision ............. PK case_id                  (4.368.293)
        colision_geo ......... PK case_id, 1:0..1          (2.159.739)
        colision_carretera ... PK case_id, 1:0..1          (  904.581)
        parte ................ PK (case_id, numero_parte)  (8.688.142)
        victima .............. PK (case_id, numero_parte, numero_victima) (4.280.801)

     NO se almacena ninguna columna derivable (07-N06 a N10): muertos, heridos,
     party_count, collision_severity, banderas peaton/ciclista/moto/camion,
     vehiculo del culpable. Todas se recalculan en las vistas.

  3. VISTAS EN ESTRELLA (3 vistas) para el consumo analitico y Power BI:
     vw_hecho_colision, vw_hecho_parte y vw_hecho_victima.

TIPOS FISICOS (07-N01 a N03)
----------------------------
case_id es 100% numerico (max 91.463.275): INTEGER de 4 bytes en lugar de TEXT
en las tres tablas que lo repiten. Fechas DATE, hora TIME. Ids de catalogo,
edades y numero de parte UTINYINT; anio de vehiculo y ubicacion USMALLINT.

LLAVES: DECLARADAS EN CATALOGOS, VERIFICADAS EN EL NUCLEO
---------------------------------------------------------
DuckDB implementa cada PRIMARY KEY y cada FOREIGN KEY con un indice ART. Sobre
tablas de millones de filas esos indices pesan mucho mas que los datos; se midio
con la base cargada:

    PK y FK declaradas en el nucleo ......... ~3,4 GB
    Solo PK declaradas en el nucleo ......... ~0,7 GB
    Sin indices en el nucleo (base final) ... 315 MB   (fuente: 9,9 GB)

Y no aceleran nada en un motor columnar: las consultas analiticas recorren
columnas enteras con uniones por dispersion, no buscan filas sueltas.

Por eso:
  - Los catalogos (miles de filas como maximo) declaran PK, UNIQUE y FK.
  - Las cinco tablas del nucleo documentan su PK y sus FK en comentarios y las
    VERIFICA 03_procesamiento_carga.py con un control explicito por cada llave
    (unicidad de la PK y anti-join por cada FK). Si alguno falla, la carga se
    detiene con codigo 1.
"""

import os

from comun import BASE, CATALOGOS, conectar, titulo


# ==============================================================================
# BLOQUE 1 — CATALOGOS
# ==============================================================================

def crear_catalogos_de_codigos(con):
    """Los 24 catalogos de codigos comparten estructura (ver comun.CATALOGOS)."""
    for nombre, extras in CATALOGOS.items():
        columnas_extra = "".join(f",\n            {col} {tipo}" for col, tipo in extras)
        con.execute(f"""
            CREATE TABLE {nombre} (
                {nombre}_id UTINYINT PRIMARY KEY,
                codigo      VARCHAR UNIQUE,      -- valor literal de la fuente; NULL en id 0
                etiqueta    VARCHAR NOT NULL,    -- denominacion en espanol
                orden       UTINYINT NOT NULL{columnas_extra}
            )
        """)
    print(f"[OK] {len(CATALOGOS)} catalogos de codigos creados.")


def crear_catalogos_especiales(con):
    con.execute("""
        CREATE TABLE calendario (
            fecha         DATE PRIMARY KEY,
            anio          USMALLINT NOT NULL,
            mes           UTINYINT NOT NULL,
            nombre_mes    VARCHAR NOT NULL,
            trimestre     UTINYINT NOT NULL,
            dia_semana    UTINYINT NOT NULL,   -- 1 = lunes ... 7 = domingo (ISO)
            nombre_dia    VARCHAR NOT NULL,
            es_fin_semana BOOLEAN NOT NULL
        )
    """)
    # condado_id es el codigo oficial del estado (01 Alameda ... 58 Yuba): son
    # los dos primeros digitos de county_city_location.
    con.execute("""
        CREATE TABLE condado (
            condado_id UTINYINT PRIMARY KEY,
            codigo     VARCHAR UNIQUE,         -- nombre tal como aparece en la fuente
            nombre     VARCHAR NOT NULL
        )
    """)
    con.execute("""
        CREATE TABLE poblacion (
            poblacion_id UTINYINT PRIMARY KEY,
            codigo       VARCHAR UNIQUE,
            etiqueta     VARCHAR NOT NULL,
            orden        UTINYINT NOT NULL
        )
    """)
    # Dependencia transitiva resuelta (07-N04): county_city_location determina
    # condado y categoria de poblacion. Su codigo numerico es la propia PK.
    con.execute("""
        CREATE TABLE ubicacion (
            ubicacion_id USMALLINT PRIMARY KEY,   -- county_city_location como entero
            condado_id   UTINYINT NOT NULL REFERENCES condado (condado_id),
            poblacion_id UTINYINT NOT NULL REFERENCES poblacion (poblacion_id)
        )
    """)
    # severidad_id = nivel KABCO maximo de las victimas (0 a 4). No hay id
    # "Sin clasificar": la severidad se deriva, nunca se lee de la fuente.
    con.execute("""
        CREATE TABLE severidad (
            severidad_id UTINYINT PRIMARY KEY,
            codigo       VARCHAR UNIQUE NOT NULL,   -- valor de collision_severity en la fuente
            etiqueta     VARCHAR NOT NULL,
            es_lesion    BOOLEAN NOT NULL
        )
    """)
    con.execute("""
        CREATE TABLE banda_edad (
            banda_edad_id UTINYINT PRIMARY KEY,
            etiqueta      VARCHAR NOT NULL UNIQUE,
            edad_min      UTINYINT,
            edad_max      UTINYINT
        )
    """)
    print("[OK] Catalogos especiales creados: calendario, condado, poblacion, "
          "ubicacion, severidad, banda_edad.")


# ==============================================================================
# BLOQUE 2 — NUCLEO 3FN
# ==============================================================================

def crear_colision(con):
    """
    Un registro por colision. Solo atributos propios del evento.

    Las columnas *_2 (segunda condicion de clima y de via) admiten NULL: su
    ausencia significa "no hubo segunda condicion", no "sin clasificar".
    alcohol_implicado guarda TRUE o NULL, nunca FALSE: la fuente solo marca la
    presencia confirmada (03-C01).
    """
    con.execute("""
        CREATE TABLE colision (
            case_id                 INTEGER NOT NULL,                 -- PK
            fecha                   DATE NOT NULL,  -- FK -> calendario
            hora                    TIME,                     -- NULL = hora desconocida
            ubicacion_id            USMALLINT NOT NULL,  -- FK -> ubicacion
            jurisdiccion            USMALLINT,
            clima_id                UTINYINT NOT NULL,  -- FK -> clima
            clima_2_id              UTINYINT,  -- FK -> clima
            iluminacion_id          UTINYINT NOT NULL,  -- FK -> iluminacion
            superficie_id           UTINYINT NOT NULL,  -- FK -> superficie
            condicion_via_id        UTINYINT NOT NULL,  -- FK -> condicion_via
            condicion_via_2_id      UTINYINT,  -- FK -> condicion_via
            dispositivo_control_id  UTINYINT NOT NULL,  -- FK -> dispositivo_control
            tipo_colision_id        UTINYINT NOT NULL,  -- FK -> tipo_colision
            implicado_con_id        UTINYINT NOT NULL,  -- FK -> implicado_con
            factor_primario_id      UTINYINT NOT NULL,  -- FK -> factor_primario
            categoria_infraccion_id UTINYINT NOT NULL,  -- FK -> categoria_infraccion
            infraccion_codigo       INTEGER,                  -- pcf_violation
            infraccion_inciso       VARCHAR,                  -- pcf_violation_subsection
            fuga_id                 UTINYINT NOT NULL,  -- FK -> fuga
            accion_peaton_id        UTINYINT NOT NULL,  -- FK -> accion_peaton
            en_interseccion         BOOLEAN,
            vehiculo_remolcado      BOOLEAN,
            carretera_estatal       BOOLEAN,
            condicion_especial      BOOLEAN,
            alcohol_implicado       BOOLEAN                   -- TRUE o NULL, nunca FALSE
        )
    """)


def crear_subtipos_colision(con):
    """
    Dos extensiones 1:0..1. Su PK es a la vez FK a colision: una colision tiene
    a lo sumo una fila en cada una. La existencia de la fila ES la bandera.
    """
    con.execute("""
        CREATE TABLE colision_geo (
            case_id  INTEGER NOT NULL,      -- PK, FK -> colision
            latitud  DOUBLE NOT NULL,
            longitud DOUBLE NOT NULL
        )
    """)
    # Bloque Caltrans: nulo o no nulo siempre en conjunto (07-N12).
    con.execute("""
        CREATE TABLE colision_carretera (
            case_id                 INTEGER NOT NULL,   -- PK, FK -> colision
            condado_caltrans_id     UTINYINT NOT NULL,  -- FK -> condado
            distrito_caltrans       UTINYINT,
            ruta_estatal            USMALLINT,
            prefijo_postmile        VARCHAR,
            postmile                DOUBLE,
            tipo_ubicacion          VARCHAR,     -- highway / intersection / ramp
            sentido                 VARCHAR,     -- side_of_highway
            rampa_interseccion      VARCHAR
        )
    """)


def crear_parte(con):
    """
    Un registro por parte (conductor, peaton, ciclista, vehiculo estacionado...).

    edad y anio_vehiculo guardan solo valores dentro del rango auditado; fuera de
    el quedan NULL y la bandera *_en_cuarentena lo distingue de un NULL de origen.
    """
    con.execute("""
        CREATE TABLE parte (
            case_id                   INTEGER NOT NULL,   -- PK, FK -> colision
            numero_parte              UTINYINT NOT NULL,  -- PK
            tipo_parte_id             UTINYINT NOT NULL,  -- FK -> tipo_parte
            culpable                  BOOLEAN NOT NULL,
            sexo_id                   UTINYINT NOT NULL,  -- FK -> sexo
            edad                      UTINYINT,
            edad_en_cuarentena        BOOLEAN NOT NULL,
            raza_id                   UTINYINT NOT NULL,  -- FK -> raza
            sobriedad_id              UTINYINT NOT NULL,  -- FK -> sobriedad
            droga_fisica_id           UTINYINT NOT NULL,  -- FK -> droga_fisica
            direccion_id              UTINYINT NOT NULL,  -- FK -> direccion
            movimiento_previo_id      UTINYINT NOT NULL,  -- FK -> movimiento_previo
            equipo_seguridad_1_id     UTINYINT NOT NULL,  -- FK -> equipo_seguridad
            equipo_seguridad_2_id     UTINYINT,  -- FK -> equipo_seguridad
            tipo_vehiculo_id          UTINYINT NOT NULL,  -- FK -> tipo_vehiculo
            anio_vehiculo             USMALLINT,
            anio_vehiculo_en_cuarentena BOOLEAN NOT NULL,
            marca_vehiculo            VARCHAR,
            tipo_vehiculo_chp         VARCHAR,     -- chp_vehicle_type_towing
            tipo_remolque_chp         VARCHAR,     -- chp_vehicle_type_towed
            responsabilidad_financiera VARCHAR,
            usaba_celular             BOOLEAN,
            uso_celular               VARCHAR,
            materiales_peligrosos     BOOLEAN,     -- TRUE o NULL, como en la fuente
            relacion_bus_escolar      BOOLEAN,     -- TRUE o NULL, como en la fuente
            otra_infraccion_categoria VARCHAR,
            otra_infraccion_seccion   VARCHAR,
            otra_infraccion_sufijo    VARCHAR,
            factor_asociado_1         VARCHAR,
            factor_asociado_2         VARCHAR
        )
    """)


def crear_victima(con):
    """
    Un registro por victima. La fuente no trae numero de victima y su columna id
    no es unica (05-A04): numero_victima se asigna con ROW_NUMBER() por id dentro
    de cada parte, lo que es determinista porque id no se repite en una parte
    (05-A06).
    """
    con.execute("""
        CREATE TABLE victima (
            case_id               INTEGER NOT NULL,   -- PK, FK -> parte
            numero_parte          UTINYINT NOT NULL,  -- PK, FK -> parte
            numero_victima        UTINYINT NOT NULL,  -- PK
            rol_victima_id        UTINYINT NOT NULL,  -- FK -> rol_victima
            sexo_id               UTINYINT NOT NULL,  -- FK -> sexo
            edad                  UTINYINT,
            edad_en_cuarentena    BOOLEAN NOT NULL,
            lesion_id             UTINYINT NOT NULL,  -- FK -> lesion
            asiento_id            UTINYINT NOT NULL,  -- FK -> asiento
            equipo_seguridad_1_id UTINYINT NOT NULL,  -- FK -> equipo_seguridad
            equipo_seguridad_2_id UTINYINT,  -- FK -> equipo_seguridad
            eyeccion_id           UTINYINT NOT NULL  -- FK -> eyeccion
        )
    """)


# ==============================================================================
# BLOQUE 3 — VISTAS EN ESTRELLA
# Las medidas se calculan sobre el grano correcto (COUNT sobre victima y parte),
# por lo que ninguna vista puede inflar totales por fan-out.
# ==============================================================================

def crear_vistas(con):
    # Resumen por colision de sus victimas (escala KABCO) y de sus partes.
    con.execute("""
        CREATE VIEW vw_hecho_colision AS
        WITH v AS (
            SELECT vi.case_id,
                   MAX(l.nivel)                              AS nivel_max,
                   COUNT(*)                                  AS victimas,
                   COUNT(*) FILTER (WHERE l.kabco = 'K')     AS muertos,
                   COUNT(*) FILTER (WHERE l.kabco = 'A')     AS heridos_graves,
                   COUNT(*) FILTER (WHERE l.kabco = 'B')     AS heridos_visibles,
                   COUNT(*) FILTER (WHERE l.kabco = 'C')     AS heridos_leves
            FROM victima vi JOIN lesion l USING (lesion_id)
            GROUP BY vi.case_id
        ),
        p AS (
            SELECT pa.case_id,
                   COUNT(*)                                              AS partes,
                   BOOL_OR(tp.codigo = 'pedestrian')                     AS peaton_implicado,
                   BOOL_OR(tp.codigo = 'bicyclist')                      AS ciclista_implicado,
                   BOOL_OR(tv.grupo = 'Motocicleta')                     AS motociclista_implicado,
                   BOOL_OR(tv.grupo = 'Camión')                          AS camion_implicado,
                   ANY_VALUE(pa.tipo_vehiculo_id) FILTER (WHERE pa.culpable)       AS tipo_vehiculo_culpable_id,
                   ANY_VALUE(pa.tipo_parte_id) FILTER (WHERE pa.culpable)          AS tipo_parte_culpable_id,
                   ANY_VALUE(pa.edad) FILTER (WHERE pa.culpable)                   AS edad_culpable,
                   ANY_VALUE(pa.anio_vehiculo) FILTER (WHERE pa.culpable)          AS anio_vehiculo_culpable
            FROM parte pa
            JOIN tipo_parte tp USING (tipo_parte_id)
            JOIN tipo_vehiculo tv USING (tipo_vehiculo_id)
            GROUP BY pa.case_id
        )
        SELECT c.*,
               u.condado_id,
               u.poblacion_id,
               COALESCE(v.nivel_max, 0)::UTINYINT               AS severidad_id,
               COALESCE(v.victimas, 0)                          AS victimas,
               COALESCE(v.muertos, 0)                           AS muertos,
               COALESCE(v.heridos_graves, 0)                    AS heridos_graves,
               COALESCE(v.heridos_visibles, 0)                  AS heridos_visibles,
               COALESCE(v.heridos_leves, 0)                     AS heridos_leves,
               COALESCE(v.heridos_graves + v.heridos_visibles + v.heridos_leves, 0) AS heridos_total,
               COALESCE(p.partes, 0)                            AS partes,
               COALESCE(p.peaton_implicado, FALSE)              AS peaton_implicado,
               COALESCE(p.ciclista_implicado, FALSE)            AS ciclista_implicado,
               COALESCE(p.motociclista_implicado, FALSE)        AS motociclista_implicado,
               COALESCE(p.camion_implicado, FALSE)              AS camion_implicado,
               p.tipo_parte_culpable_id,
               p.tipo_vehiculo_culpable_id,
               p.edad_culpable,
               p.anio_vehiculo_culpable,
               g.case_id IS NOT NULL                            AS tiene_coordenadas,
               k.case_id IS NOT NULL                            AS tiene_datos_caltrans
        FROM colision c
        JOIN ubicacion u USING (ubicacion_id)
        LEFT JOIN v USING (case_id)
        LEFT JOIN p USING (case_id)
        LEFT JOIN colision_geo g USING (case_id)
        LEFT JOIN colision_carretera k USING (case_id)
    """)

    # Grano parte: Objetivo 2 (edad del conductor culpable) y Objetivo 4
    # (anio-modelo). Lleva las lesiones de las victimas de esa parte.
    con.execute("""
        CREATE VIEW vw_hecho_parte AS
        WITH v AS (
            SELECT vi.case_id, vi.numero_parte,
                   MAX(l.nivel)                          AS nivel_max_victimas,
                   COUNT(*)                              AS victimas,
                   COUNT(*) FILTER (WHERE l.kabco = 'K') AS muertos,
                   COUNT(*) FILTER (WHERE l.kabco IN ('A', 'B', 'C')) AS heridos
            FROM victima vi JOIN lesion l USING (lesion_id)
            GROUP BY vi.case_id, vi.numero_parte
        )
        SELECT pa.*,
               c.fecha,
               u.condado_id,
               COALESCE(b.banda_edad_id, 0)::UTINYINT          AS banda_edad_id,
               v.nivel_max_victimas,
               COALESCE(v.victimas, 0)                         AS victimas,
               COALESCE(v.muertos, 0)                          AS muertos,
               COALESCE(v.heridos, 0)                          AS heridos
        FROM parte pa
        JOIN colision c USING (case_id)
        JOIN ubicacion u USING (ubicacion_id)
        LEFT JOIN banda_edad b
               ON b.banda_edad_id > 0 AND pa.edad BETWEEN b.edad_min AND b.edad_max
        LEFT JOIN v USING (case_id, numero_parte)
    """)

    # Grano victima: lesion homologada KABCO y vehiculo en el que viajaba.
    con.execute("""
        CREATE VIEW vw_hecho_victima AS
        SELECT vi.*,
               l.kabco,
               l.nivel                                         AS nivel_lesion,
               COALESCE(b.banda_edad_id, 0)::UTINYINT          AS banda_edad_id,
               pa.tipo_parte_id,
               pa.tipo_vehiculo_id,
               pa.anio_vehiculo,
               pa.culpable                                     AS parte_culpable,
               c.fecha,
               u.condado_id
        FROM victima vi
        JOIN lesion l USING (lesion_id)
        JOIN parte pa USING (case_id, numero_parte)
        JOIN colision c USING (case_id)
        JOIN ubicacion u USING (ubicacion_id)
        LEFT JOIN banda_edad b
               ON b.banda_edad_id > 0 AND vi.edad BETWEEN b.edad_min AND b.edad_max
    """)
    print("[OK] Vistas creadas: vw_hecho_colision, vw_hecho_parte, vw_hecho_victima.")


# ==============================================================================
# EJECUCION
# ==============================================================================

def main():
    for ruta in (BASE, BASE + ".wal"):
        if os.path.exists(ruta):
            os.remove(ruta)
    con = conectar()
    titulo("CREACION DEL ESQUEMA NORMALIZADO (3FN)")

    crear_catalogos_de_codigos(con)
    crear_catalogos_especiales(con)
    crear_colision(con)
    crear_subtipos_colision(con)
    crear_parte(con)
    crear_victima(con)
    print("[OK] Nucleo 3FN creado: colision, colision_geo, colision_carretera, parte, victima.")
    crear_vistas(con)

    tablas = con.execute("SELECT COUNT(*) FROM duckdb_tables()").fetchone()[0]
    vistas = con.execute("SELECT COUNT(*) FROM duckdb_views() WHERE NOT internal").fetchone()[0]
    con.close()
    print("-" * 72)
    print(f"{tablas} tablas y {vistas} vistas en {os.path.basename(BASE)}")


if __name__ == "__main__":
    main()
