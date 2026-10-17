"""
03_procesamiento_carga.py
================================================================================
PROCESAMIENTO, CARGA DEL NUCLEO 3FN Y CONTROLES DE INTEGRIDAD
Proyecto: Perfiles de riesgo en colisiones de transito — California (2010-2019)
Escuela de Estadistica y Ciencias Actuariales (EECA-UCV) — Computacion II
================================================================================

FLUJO
-----
  1. EXTRACCION. Se copia UNA sola vez el periodo 2010-2019 de las tres tablas
     de la fuente a tablas temporales de DuckDB. La fuente no tiene indices
     sobre case_id: re-escanear 9,9 GB por cada tabla destino seria el cuello
     de botella. Las partes y victimas se filtran por semi-join con las
     colisiones del periodo.

  2. TRANSFORMACION Y CARGA, en orden padre -> hijo (las FK se verifican al
     insertar):
        T1  case_id TEXT -> INTEGER; fecha TEXT -> DATE; hora TEXT -> TIME.
        T2  Cada codigo se resuelve contra su catalogo; NULL o codigo basura -> 0.
            Las columnas *_2 conservan NULL cuando no hay segunda condicion.
        T3  Banderas 0/1 -> BOOLEAN. Las que la fuente marca solo como 1/NULL
            (alcohol, materiales peligrosos, bus escolar) quedan TRUE/NULL:
            un NULL ahi es "no reportado", no "no ocurrio".
        T4  Edades fuera de 0-110 y anio de vehiculo fuera de 1900-2020 -> NULL
            con bandera de cuarentena. La fila se conserva.
        T5  numero_victima = ROW_NUMBER() por id dentro de cada parte.
        T6  Coordenadas solo con par completo dentro de California -> colision_geo.
        T7  Bloque Caltrans no nulo -> colision_carretera.
        T8  No se cargan columnas derivables ni sin informacion (auditoria B.7/B.8).

  3. CONTROLES. Se comparan los totales de la base contra la fuente y contra
     las vistas. Si un control falla, el script termina con codigo 1.
"""

import time

from comun import (ANIO_VEHICULO_MAX, ANIO_VEHICULO_MIN, DESDE, EDAD_MAX, EDAD_MIN, HASTA,
                   LAT_MAX, LAT_MIN, LON_MAX, LON_MIN, adjuntar_fuente, conectar, titulo)

# ==============================================================================
# RESOLUCION DE CODIGOS: (columna destino, catalogo, columna fuente, admite NULL)
# ==============================================================================

FK_COLISION = [
    ("clima_id", "clima", "weather_1", False),
    ("clima_2_id", "clima", "weather_2", True),
    ("iluminacion_id", "iluminacion", "lighting", False),
    ("superficie_id", "superficie", "road_surface", False),
    ("condicion_via_id", "condicion_via", "road_condition_1", False),
    ("condicion_via_2_id", "condicion_via", "road_condition_2", True),
    ("dispositivo_control_id", "dispositivo_control", "control_device", False),
    ("tipo_colision_id", "tipo_colision", "type_of_collision", False),
    ("implicado_con_id", "implicado_con", "motor_vehicle_involved_with", False),
    ("factor_primario_id", "factor_primario", "primary_collision_factor", False),
    ("categoria_infraccion_id", "categoria_infraccion", "pcf_violation_category", False),
    ("fuga_id", "fuga", "hit_and_run", False),
    ("accion_peaton_id", "accion_peaton", "pedestrian_action", False),
]

FK_PARTE = [
    ("tipo_parte_id", "tipo_parte", "party_type", False),
    ("sexo_id", "sexo", "party_sex", False),
    ("raza_id", "raza", "party_race", False),
    ("sobriedad_id", "sobriedad", "party_sobriety", False),
    ("droga_fisica_id", "droga_fisica", "party_drug_physical", False),
    ("direccion_id", "direccion", "direction_of_travel", False),
    ("movimiento_previo_id", "movimiento_previo", "movement_preceding_collision", False),
    ("equipo_seguridad_1_id", "equipo_seguridad", "party_safety_equipment_1", False),
    ("equipo_seguridad_2_id", "equipo_seguridad", "party_safety_equipment_2", True),
    ("tipo_vehiculo_id", "tipo_vehiculo", "statewide_vehicle_type", False),
]

FK_VICTIMA = [
    ("rol_victima_id", "rol_victima", "victim_role", False),
    ("sexo_id", "sexo", "victim_sex", False),
    ("lesion_id", "lesion", "victim_degree_of_injury", False),
    ("asiento_id", "asiento", "victim_seating_position", False),
    ("equipo_seguridad_1_id", "equipo_seguridad", "victim_safety_equipment_1", False),
    ("equipo_seguridad_2_id", "equipo_seguridad", "victim_safety_equipment_2", True),
    ("eyeccion_id", "eyeccion", "victim_ejected", False),
]


# Llaves del nucleo. No se declaran en el motor (ver 01, "LLAVES"): se verifican aqui.
PK_NUCLEO = {
    "colision": "case_id",
    "colision_geo": "case_id",
    "colision_carretera": "case_id",
    "parte": "case_id, numero_parte",
    "victima": "case_id, numero_parte, numero_victima",
}

# (tabla, columnas, tabla referida, columnas referidas). Las FK a catalogos de
# codigos se agregan desde FK_COLISION, FK_PARTE y FK_VICTIMA.
FK_NUCLEO = [
    ("colision", "fecha", "calendario", "fecha"),
    ("colision", "ubicacion_id", "ubicacion", "ubicacion_id"),
    ("colision_geo", "case_id", "colision", "case_id"),
    ("colision_carretera", "case_id", "colision", "case_id"),
    ("colision_carretera", "condado_caltrans_id", "condado", "condado_id"),
    ("parte", "case_id", "colision", "case_id"),
    ("victima", "case_id, numero_parte", "parte", "case_id, numero_parte"),
] + [(tabla, destino, catalogo, f"{catalogo}_id")
     for tabla, fks in (("colision", FK_COLISION), ("parte", FK_PARTE), ("victima", FK_VICTIMA))
     for destino, catalogo, _, _ in fks]


def resolver(fks):
    """Devuelve (expresiones SELECT, LEFT JOINs) para resolver codigos contra catalogos."""
    columnas, uniones = [], []
    for i, (destino, catalogo, origen, admite_nulo) in enumerate(fks):
        alias = f"k{i}"
        uniones.append(f"LEFT JOIN {catalogo} {alias} ON {alias}.codigo = s.{origen}")
        if admite_nulo:
            columnas.append(f"CASE WHEN s.{origen} IS NULL THEN NULL "
                            f"ELSE COALESCE({alias}.{catalogo}_id, 0) END AS {destino}")
        else:
            columnas.append(f"COALESCE({alias}.{catalogo}_id, 0) AS {destino}")
    return ",\n               ".join(columnas), "\n        ".join(uniones)


def en_rango(columna, minimo, maximo):
    return f"CASE WHEN {columna} BETWEEN {minimo} AND {maximo} THEN {columna} END"


def en_cuarentena(columna, minimo, maximo):
    return f"({columna} IS NOT NULL AND {columna} NOT BETWEEN {minimo} AND {maximo})"


# ==============================================================================
# 1. EXTRACCION
# ==============================================================================

def extraer(con):
    adjuntar_fuente(con)
    con.execute(f"""
        CREATE TEMP TABLE s_col AS
        SELECT * FROM src.collisions
        WHERE collision_date >= '{DESDE}' AND collision_date < '{HASTA}'
    """)
    con.execute("CREATE TEMP TABLE s_par AS SELECT * FROM src.parties WHERE case_id IN (SELECT case_id FROM s_col)")
    con.execute("CREATE TEMP TABLE s_vic AS SELECT * FROM src.victims WHERE case_id IN (SELECT case_id FROM s_col)")
    con.execute("DETACH src")
    for tabla in ("s_col", "s_par", "s_vic"):
        n = con.execute(f"SELECT COUNT(*) FROM {tabla}").fetchone()[0]
        print(f"[OK] extraido {tabla:<8}{n:>12,} filas")


# ==============================================================================
# 2. CARGA
# ==============================================================================

def cargar_colision(con):
    columnas, uniones = resolver(FK_COLISION)
    con.execute(f"""
        INSERT INTO colision BY NAME
        SELECT CAST(s.case_id AS INTEGER)                       AS case_id,
               CAST(s.collision_date AS DATE)                   AS fecha,
               TRY_CAST(s.collision_time AS TIME)               AS hora,
               CAST(s.county_city_location AS USMALLINT)        AS ubicacion_id,
               CAST(s.jurisdiction AS USMALLINT)                AS jurisdiccion,
               {columnas},
               TRY_CAST(s.pcf_violation AS INTEGER)             AS infraccion_codigo,
               s.pcf_violation_subsection                       AS infraccion_inciso,
               CAST(s.intersection AS BOOLEAN)                  AS en_interseccion,
               CAST(s.tow_away AS BOOLEAN)                      AS vehiculo_remolcado,
               CAST(s.state_highway_indicator AS BOOLEAN)       AS carretera_estatal,
               CAST(s.special_condition = '1' AS BOOLEAN)       AS condicion_especial,
               CASE WHEN s.alcohol_involved = 1 THEN TRUE END   AS alcohol_implicado
        FROM s_col s
        {uniones}
        ORDER BY fecha, case_id
    """)


def cargar_subtipos(con):
    con.execute(f"""
        INSERT INTO colision_geo
        SELECT CAST(case_id AS INTEGER), latitude, longitude
        FROM s_col
        WHERE latitude BETWEEN {LAT_MIN} AND {LAT_MAX}
          AND longitude BETWEEN {LON_MIN} AND {LON_MAX}
        ORDER BY 1
    """)
    con.execute("""
        INSERT INTO colision_carretera
        SELECT CAST(s.case_id AS INTEGER),
               COALESCE(c.condado_id, 0),
               CAST(s.caltrans_district AS UTINYINT),
               CAST(s.state_route AS USMALLINT),
               s.postmile_prefix,
               s.postmile,
               s.location_type,
               s.side_of_highway,
               s.ramp_intersection
        FROM s_col s
        LEFT JOIN condado c ON c.codigo = s.caltrans_county
        WHERE s.caltrans_county IS NOT NULL
        ORDER BY 1
    """)


def cargar_parte(con):
    columnas, uniones = resolver(FK_PARTE)
    con.execute(f"""
        INSERT INTO parte BY NAME
        SELECT CAST(s.case_id AS INTEGER)                                  AS case_id,
               CAST(s.party_number AS UTINYINT)                            AS numero_parte,
               {columnas},
               s.at_fault = 1                                              AS culpable,
               {en_rango('s.party_age', EDAD_MIN, EDAD_MAX)}               AS edad,
               {en_cuarentena('s.party_age', EDAD_MIN, EDAD_MAX)}          AS edad_en_cuarentena,
               {en_rango('s.vehicle_year', ANIO_VEHICULO_MIN, ANIO_VEHICULO_MAX)} AS anio_vehiculo,
               {en_cuarentena('s.vehicle_year', ANIO_VEHICULO_MIN, ANIO_VEHICULO_MAX)} AS anio_vehiculo_en_cuarentena,
               s.vehicle_make                                              AS marca_vehiculo,
               s.chp_vehicle_type_towing                                   AS tipo_vehiculo_chp,
               s.chp_vehicle_type_towed                                    AS tipo_remolque_chp,
               s.financial_responsibility                                  AS responsabilidad_financiera,
               CAST(s.cellphone_in_use AS BOOLEAN)                         AS usaba_celular,
               s.cellphone_use_type                                        AS uso_celular,
               CASE WHEN s.hazardous_materials = 1 THEN TRUE END           AS materiales_peligrosos,
               CASE WHEN s.school_bus_related = 1 THEN TRUE END            AS relacion_bus_escolar,
               s.oaf_violation_category                                    AS otra_infraccion_categoria,
               s.oaf_violation_section                                     AS otra_infraccion_seccion,
               s.oaf_violation_suffix                                      AS otra_infraccion_sufijo,
               s.other_associate_factor_1                                  AS factor_asociado_1,
               s.other_associate_factor_2                                  AS factor_asociado_2
        FROM s_par s
        {uniones}
        ORDER BY case_id, numero_parte
    """)


def cargar_victima(con):
    columnas, uniones = resolver(FK_VICTIMA)
    con.execute(f"""
        INSERT INTO victima BY NAME
        SELECT CAST(s.case_id AS INTEGER)                                  AS case_id,
               CAST(s.party_number AS UTINYINT)                            AS numero_parte,
               CAST(ROW_NUMBER() OVER (PARTITION BY s.case_id, s.party_number
                                       ORDER BY s.id) AS UTINYINT)         AS numero_victima,
               {columnas},
               {en_rango('s.victim_age', EDAD_MIN, EDAD_MAX)}              AS edad,
               {en_cuarentena('s.victim_age', EDAD_MIN, EDAD_MAX)}         AS edad_en_cuarentena
        FROM s_vic s
        {uniones}
        ORDER BY case_id, numero_parte, numero_victima
    """)


# ==============================================================================
# 3. CONTROLES
# ==============================================================================

def controles(con):
    def uno(sql):
        return con.execute(sql).fetchone()[0] or 0

    caja = (f"latitude BETWEEN {LAT_MIN} AND {LAT_MAX} AND longitude BETWEEN {LON_MIN} AND {LON_MAX}")
    pruebas = [
        ("Colisiones cargadas", uno("SELECT COUNT(*) FROM s_col"),
         "SELECT COUNT(*) FROM colision"),
        ("Partes cargadas", uno("SELECT COUNT(*) FROM s_par"),
         "SELECT COUNT(*) FROM parte"),
        ("Victimas cargadas", uno("SELECT COUNT(*) FROM s_vic"),
         "SELECT COUNT(*) FROM victima"),
        ("Colisiones georreferenciadas", uno(f"SELECT COUNT(*) FROM s_col WHERE {caja}"),
         "SELECT COUNT(*) FROM colision_geo"),
        ("Colisiones con bloque Caltrans", uno("SELECT COUNT(*) FROM s_col WHERE caltrans_county IS NOT NULL"),
         "SELECT COUNT(*) FROM colision_carretera"),
        ("Muertos (vista = killed_victims)", uno("SELECT SUM(killed_victims) FROM s_col"),
         "SELECT SUM(muertos) FROM vw_hecho_colision"),
        ("Heridos (vista = injured_victims)", uno("SELECT SUM(injured_victims) FROM s_col"),
         "SELECT SUM(heridos_total) FROM vw_hecho_colision"),
        ("Severidad derivada distinta de la fuente", 0,
         """SELECT COUNT(*) FROM vw_hecho_colision v
            JOIN s_col s ON CAST(s.case_id AS INTEGER) = v.case_id
            JOIN severidad sv ON sv.severidad_id = v.severidad_id
            WHERE s.collision_severity <> 'N' AND sv.codigo <> s.collision_severity"""),
        ("Banderas peaton/ciclista/moto/camion distintas", 0,
         """SELECT COUNT(*) FROM vw_hecho_colision v
            JOIN s_col s ON CAST(s.case_id AS INTEGER) = v.case_id
            WHERE v.peaton_implicado <> (s.pedestrian_collision = 1)
               OR v.ciclista_implicado <> (s.bicycle_collision = 1)
               OR v.motociclista_implicado <> (s.motorcycle_collision = 1)
               OR v.camion_implicado <> (s.truck_collision = 1)"""),
        ("Condado distinto de county_location", 0,
         """SELECT COUNT(*) FROM vw_hecho_colision v
            JOIN s_col s ON CAST(s.case_id AS INTEGER) = v.case_id
            JOIN condado c ON c.condado_id = v.condado_id
            WHERE c.codigo <> s.county_location"""),
        ("Colisiones con mas de un culpable", 0,
         "SELECT COUNT(*) FROM (SELECT case_id FROM parte WHERE culpable GROUP BY case_id HAVING COUNT(*) > 1)"),
        ("Edades de partes en cuarentena",
         uno(f"SELECT COUNT(*) FROM s_par WHERE {en_cuarentena('party_age', EDAD_MIN, EDAD_MAX)}"),
         "SELECT COUNT(*) FROM parte WHERE edad_en_cuarentena"),
        ("Edades de victimas en cuarentena",
         uno(f"SELECT COUNT(*) FROM s_vic WHERE {en_cuarentena('victim_age', EDAD_MIN, EDAD_MAX)}"),
         "SELECT COUNT(*) FROM victima WHERE edad_en_cuarentena"),
        ("Anios de vehiculo en cuarentena",
         uno(f"SELECT COUNT(*) FROM s_par WHERE {en_cuarentena('vehicle_year', ANIO_VEHICULO_MIN, ANIO_VEHICULO_MAX)}"),
         "SELECT COUNT(*) FROM parte WHERE anio_vehiculo_en_cuarentena"),
    ]
    for tabla, llave in PK_NUCLEO.items():
        pruebas.append((f"PK {tabla}: duplicados o nulos", 0,
                        f"SELECT COUNT(*) - COUNT(DISTINCT ({llave})) "
                        f"+ COUNT(*) FILTER (WHERE ({llave}) IS NULL) FROM {tabla}"))
    huerfanos = " + ".join(
        f"""(SELECT COUNT(*) FROM {t} a WHERE ({', '.join('a.' + c.strip() for c in cols.split(','))}) IS NOT NULL
             AND NOT EXISTS (SELECT 1 FROM {ref} b WHERE ({', '.join('b.' + c.strip() for c in rcols.split(','))})
                                                       = ({', '.join('a.' + c.strip() for c in cols.split(','))})))"""
        for t, cols, ref, rcols in FK_NUCLEO)
    pruebas.append((f"FK: huerfanos en {len(FK_NUCLEO)} relaciones", 0, f"SELECT {huerfanos}"))

    titulo("CONTROLES DE INTEGRIDAD")
    print(f"{'CONTROL':<46}{'ESPERADO':>13}{'OBTENIDO':>13}")
    print("-" * 72)
    todo_bien = True
    for nombre, esperado, consulta in pruebas:
        obtenido = uno(consulta)
        ok = int(obtenido) == int(esperado)
        todo_bien = todo_bien and ok
        print(f"{nombre:<46}{int(esperado):>13,}{int(obtenido):>13,}{'' if ok else '   <-- FALLA'}")
    return todo_bien


def reporte_sin_clasificar(con):
    """
    Informativo: cuantas filas cayeron en id 0 por cada columna y de que valores
    venian (NULL o codigo basura). El diccionario de datos declara estas cifras.
    """
    titulo("FILAS ASIGNADAS A 'SIN CLASIFICAR' (id = 0)")
    print(f"{'TABLA.COLUMNA':<42}{'FILAS':>10}{'%':>8}   VALORES DE ORIGEN")
    print("-" * 72)
    for tabla, staging, fks in (("colision", "s_col", FK_COLISION),
                                ("parte", "s_par", FK_PARTE),
                                ("victima", "s_vic", FK_VICTIMA)):
        total = con.execute(f"SELECT COUNT(*) FROM {staging}").fetchone()[0]
        for destino, catalogo, origen, admite_nulo in fks:
            filas = con.execute(f"""
                SELECT s.{origen}, COUNT(*) FROM {staging} s
                LEFT JOIN {catalogo} k ON k.codigo = s.{origen}
                WHERE k.codigo IS NULL {'AND s.' + origen + ' IS NOT NULL' if admite_nulo else ''}
                GROUP BY 1 ORDER BY 2 DESC
            """).fetchall()
            n = sum(f[1] for f in filas)
            if n:
                origenes = ", ".join(f"{'NULL' if v is None else repr(v)}={c:,}" for v, c in filas[:4])
                print(f"{tabla + '.' + destino:<42}{n:>10,}{100 * n / total:>7.2f}%   {origenes}")


# ==============================================================================
# EJECUCION
# ==============================================================================

def main():
    con = conectar()
    if con.execute("SELECT COUNT(*) FROM calendario").fetchone()[0] == 0:
        raise SystemExit("Catalogos vacios. Ejecute antes 01 y 02.")
    titulo("PROCESAMIENTO Y CARGA DEL NUCLEO 3FN")
    for tabla in ("victima", "parte", "colision_carretera", "colision_geo", "colision"):
        con.execute(f"DELETE FROM {tabla}")

    t0 = time.time()
    extraer(con)
    print(f"     extraccion: {time.time() - t0:.0f}s")
    for nombre, paso in (("colision", cargar_colision), ("colision_geo / carretera", cargar_subtipos),
                         ("parte", cargar_parte), ("victima", cargar_victima)):
        t0 = time.time()
        paso(con)
        print(f"[OK] cargado {nombre:<26}({time.time() - t0:.0f}s)")

    bien = controles(con)
    reporte_sin_clasificar(con)
    con.execute("CHECKPOINT")
    con.close()
    print("\n" + ("CARGA COMPLETADA: TODOS LOS CONTROLES PASAN" if bien
                  else "ATENCION: HAY CONTROLES QUE FALLAN"))
    if not bien:
        raise SystemExit(1)


if __name__ == "__main__":
    main()
