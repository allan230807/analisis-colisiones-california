"""
02_poblacion_catalogos.py
================================================================================
POBLACION DE LOS CATALOGOS
Proyecto: Perfiles de riesgo en colisiones de transito — California (2010-2019)
Escuela de Estadistica y Ciencias Actuariales (EECA-UCV) — Computacion II
================================================================================

POR QUE LOS CATALOGOS SE ESCRIBEN A MANO
----------------------------------------
Los dominios de cada codigo se auditaron en 01_catalogos_frecuencias.sql. Aqui se
escriben explicitamente, y no se deducen de la fuente, por tres razones:

  1. TRADUCCION. La fuente esta en ingles ('property damage only'); el estudio
     se presenta en espanol.
  2. ORDEN. El orden alfabetico no tiene sentido ('fatal' antes que 'pain').
     La columna `orden` fija una secuencia con significado.
  3. CLASIFICACION. Algunas columnas (`grupo`, `es_adverso`, `kabco`) son
     decisiones de esta investigacion y deben quedar a la vista.

VALORES SIN CLASIFICAR
----------------------
Todo catalogo de codigos tiene una fila id = 0 "Sin clasificar". En la carga
(03) los NULL y los codigos basura detectados en la auditoria (07-N13: 'N', '2',
'04', 'Z'...) caen ahi. Ninguna fila se descarta por un codigo invalido.

UBICACION
---------
Es el unico catalogo derivado de la fuente: los 542 valores de
county_city_location del periodo, con su condado (dos primeros digitos = codigo
oficial del condado) y su categoria de poblacion. El script verifica que la
dependencia funcional auditada (07-N04) se cumple antes de insertar.
"""

from comun import CATALOGOS, DESDE, HASTA, adjuntar_fuente, conectar, titulo

# ==============================================================================
# CATALOGOS DE CODIGOS: (codigo en la fuente, etiqueta en espanol, extras...)
# El id y el orden son la posicion en la lista (1, 2, 3...).
# ==============================================================================

VALORES = {
    # ----------------------------------------------------------- grano colision
    "clima": [  # es_adverso
        ("clear", "Despejado", False),
        ("cloudy", "Nublado", False),
        ("raining", "Lluvia", True),
        ("fog", "Niebla", True),
        ("snowing", "Nieve", True),
        ("wind", "Viento fuerte", True),
        ("other", "Otro", False),
    ],
    "iluminacion": [  # es_oscuridad
        ("daylight", "Luz diurna", False),
        ("dusk or dawn", "Amanecer o atardecer", False),
        ("dark with street lights", "Oscuridad con alumbrado", True),
        ("dark with street lights not functioning", "Oscuridad con alumbrado averiado", True),
        ("dark with no street lights", "Oscuridad sin alumbrado", True),
    ],
    "superficie": [  # es_adversa
        ("dry", "Seca", False),
        ("wet", "Mojada", True),
        ("snowy", "Nieve o hielo", True),
        ("slippery", "Resbaladiza", True),
    ],
    "condicion_via": [
        ("normal", "Normal"),
        ("construction", "Obras"),
        ("obstruction", "Obstrucción"),
        ("holes", "Baches"),
        ("loose material", "Material suelto"),
        ("reduced width", "Ancho reducido"),
        ("flooded", "Inundada"),
        ("other", "Otra"),
    ],
    "dispositivo_control": [
        ("none", "Ninguno"),
        ("functioning", "Funcionando"),
        ("not functioning", "Averiado"),
        ("obscured", "Obstruido"),
    ],
    "tipo_colision": [
        ("rear end", "Alcance trasero"),
        ("sideswipe", "Roce lateral"),
        ("broadside", "Impacto lateral"),
        ("head-on", "Frontal"),
        ("hit object", "Choque contra objeto"),
        ("overturned", "Vuelco"),
        ("pedestrian", "Atropello"),
        ("other", "Otro"),
    ],
    "implicado_con": [
        ("other motor vehicle", "Otro vehículo motorizado"),
        ("motor vehicle on other roadway", "Vehículo en otra vía"),
        ("parked motor vehicle", "Vehículo estacionado"),
        ("pedestrian", "Peatón"),
        ("bicycle", "Bicicleta"),
        ("train", "Tren"),
        ("animal", "Animal"),
        ("fixed object", "Objeto fijo"),
        ("other object", "Otro objeto"),
        ("non-collision", "Sin colisión"),
    ],
    "factor_primario": [
        ("vehicle code violation", "Infracción al código vehicular"),
        ("other improper driving", "Otra conducción indebida"),
        ("fell asleep", "Se durmió"),
        ("other than driver", "Ajeno al conductor"),
        ("unknown", "Desconocido"),
    ],
    "categoria_infraccion": [  # grupo
        ("speeding", "Exceso de velocidad", "Conducta del conductor"),
        ("improper turning", "Giro indebido", "Conducta del conductor"),
        ("unsafe lane change", "Cambio de carril inseguro", "Conducta del conductor"),
        ("following too closely", "Distancia insuficiente", "Conducta del conductor"),
        ("improper passing", "Adelantamiento indebido", "Conducta del conductor"),
        ("wrong side of road", "Circular por el lado contrario", "Conducta del conductor"),
        ("unsafe starting or backing", "Arranque o retroceso inseguro", "Conducta del conductor"),
        ("impeding traffic", "Obstrucción del tránsito", "Conducta del conductor"),
        ("hazardous parking", "Estacionamiento peligroso", "Conducta del conductor"),
        ("other hazardous violation", "Otra infracción peligrosa", "Conducta del conductor"),
        ("other improper driving", "Otra conducción indebida", "Conducta del conductor"),
        ("automobile right of way", "Prioridad de paso vehicular", "Prioridad y señalización"),
        ("pedestrian right of way", "Prioridad de paso del peatón", "Prioridad y señalización"),
        ("traffic signals and signs", "Semáforos y señales", "Prioridad y señalización"),
        ("dui", "Conducir bajo los efectos", "Estado del conductor"),
        ("fell asleep", "Se durmió", "Estado del conductor"),
        ("pedestrian violation", "Infracción del peatón", "Peatón"),
        ("pedestrian dui", "Peatón bajo los efectos", "Peatón"),
        ("brakes", "Frenos", "Vehículo"),
        ("lights", "Luces", "Vehículo"),
        ("other equipment", "Otro equipo", "Vehículo"),
        ("other than driver (or pedestrian)", "Ajeno al conductor o peatón", "Otros / no determinado"),
        ("unknown", "Desconocido", "Otros / no determinado"),
    ],
    "fuga": [
        ("not hit and run", "Sin fuga"),
        ("misdemeanor", "Fuga (delito menor)"),
        ("felony", "Fuga (delito grave)"),
    ],
    "accion_peaton": [
        ("no pedestrian involved", "Sin peatón"),
        ("crossing in intersection crosswalk", "Cruzando por paso peatonal en intersección"),
        ("crossing non-intersection crosswalk", "Cruzando por paso peatonal fuera de intersección"),
        ("crossing not in crosswalk", "Cruzando fuera del paso peatonal"),
        ("in road", "En la calzada"),
        ("not in road", "Fuera de la calzada"),
        ("using school bus", "Usando autobús escolar"),
    ],
    # -------------------------------------------------------------- grano parte
    "tipo_parte": [
        ("driver", "Conductor"),
        ("pedestrian", "Peatón"),
        ("bicyclist", "Ciclista"),
        ("parked vehicle", "Vehículo estacionado"),
        ("other", "Otro"),
    ],
    "sobriedad": [
        ("had not been drinking", "No había bebido"),
        ("had been drinking, not under influence", "Bebió, sin estar bajo los efectos"),
        ("had been drinking, impairment unknown", "Bebió, efecto desconocido"),
        ("had been drinking, under influence", "Bebió, bajo los efectos"),
        ("impairment unknown", "Deterioro desconocido"),
        ("not applicable", "No aplica"),
    ],
    "droga_fisica": [
        ("under drug influence", "Bajo efectos de drogas"),
        ("impairment - physical", "Impedimento físico"),
        ("sleepy/fatigued", "Somnolencia o fatiga"),
        ("G", "Deterioro desconocido"),   # codigo oficial, no basura (B.8)
        ("not applicable", "No aplica"),
    ],
    "direccion": [
        ("north", "Norte"),
        ("south", "Sur"),
        ("east", "Este"),
        ("west", "Oeste"),
    ],
    "movimiento_previo": [
        ("proceeding straight", "Avanzando recto"),
        ("slowing/stopping", "Frenando o deteniéndose"),
        ("stopped", "Detenido"),
        ("making left turn", "Girando a la izquierda"),
        ("making right turn", "Girando a la derecha"),
        ("making u-turn", "Giro en U"),
        ("other unsafe turning", "Otro giro inseguro"),
        ("changing lanes", "Cambiando de carril"),
        ("passing other vehicle", "Adelantando"),
        ("merging", "Convergiendo"),
        ("entering traffic", "Incorporándose al tránsito"),
        ("crossed into opposing lane", "Invadió el carril contrario"),
        ("traveling wrong way", "Circulando en sentido contrario"),
        ("ran off road", "Salida de la vía"),
        ("backing", "Retrocediendo"),
        ("parking maneuver", "Maniobra de estacionamiento"),
        ("parked", "Estacionado"),
        ("other", "Otro"),
    ],
    "raza": [
        ("white", "Blanca"),
        ("hispanic", "Hispana"),
        ("black", "Negra"),
        ("asian", "Asiática"),
        ("other", "Otra"),
    ],
    "tipo_vehiculo": [  # grupo
        ("passenger car", "Automóvil", "Automóvil"),
        ("passenger car with trailer", "Automóvil con remolque", "Automóvil"),
        ("pickup or panel truck", "Camioneta pickup o panel", "Camioneta"),
        ("pickup or panel truck with trailer", "Camioneta pickup o panel con remolque", "Camioneta"),
        ("truck or truck tractor", "Camión o tractocamión", "Camión"),
        ("truck or truck tractor with trailer", "Camión o tractocamión con remolque", "Camión"),
        ("motorcycle or scooter", "Motocicleta o escúter", "Motocicleta"),
        ("moped", "Ciclomotor", "Motocicleta"),
        ("schoolbus", "Autobús escolar", "Autobús"),
        ("other bus", "Otro autobús", "Autobús"),
        ("emergency vehicle", "Vehículo de emergencia", "Otro"),
        ("highway construction equipment", "Maquinaria de obras viales", "Otro"),
        ("other vehicle", "Otro vehículo", "Otro"),
        ("bicycle", "Bicicleta", "No motorizado"),
        ("pedestrian", "Peatón", "No motorizado"),
    ],
    # ------------------------------------------------------------ grano victima
    "rol_victima": [
        ("driver", "Conductor"),
        ("passenger", "Pasajero"),
        ("pedestrian", "Peatón"),
        ("bicyclist", "Ciclista"),
        ("other", "Otro"),
    ],
    "asiento": [
        ("driver", "Conductor"),
        ("passenger seat 2", "Pasajero, asiento 2"),
        ("passenger seat 3", "Pasajero, asiento 3"),
        ("passenger seat 4", "Pasajero, asiento 4"),
        ("passenger seat 5", "Pasajero, asiento 5"),
        ("passenger seat 6", "Pasajero, asiento 6"),
        ("station wagon rear", "Parte trasera de station wagon"),
        ("rear occupant of truck or van", "Ocupante trasero de camión o furgoneta"),
        ("other occupants", "Otros ocupantes"),
        ("position unknown", "Posición desconocida"),
    ],
    "eyeccion": [
        ("not ejected", "No eyectado"),
        ("partially ejected", "Parcialmente eyectado"),
        ("fully ejected", "Totalmente eyectado"),
        ("unknown", "Desconocido"),
    ],
    # Homologacion KABCO (07-N14/N15): los codigos anteriores y posteriores a la
    # recodificacion 2017-2018 comparten nivel.
    "lesion": [  # kabco, nivel
        ("killed", "Fallecido", "K", 4),
        ("severe injury", "Lesión grave", "A", 3),
        ("suspected serious injury", "Presunta lesión grave", "A", 3),
        ("other visible injury", "Lesión visible", "B", 2),
        ("suspected minor injury", "Presunta lesión leve", "B", 2),
        ("complaint of pain", "Queja de dolor", "C", 1),
        ("possible injury", "Posible lesión", "C", 1),
        ("no injury", "Ileso", "O", 0),
    ],
    # ------------------------------------------------- compartidos parte/victima
    "sexo": [
        ("male", "Masculino"),
        ("female", "Femenino"),
        ("X", "No binario"),
    ],
    "equipo_seguridad": [
        ("lap/shoulder harness used", "Cinturón de tres puntos usado"),
        ("lap/shoulder harness not used", "Cinturón de tres puntos no usado"),
        ("lap belt used", "Cinturón abdominal usado"),
        ("lap belt not used", "Cinturón abdominal no usado"),
        ("shoulder harness used", "Cinturón de hombro usado"),
        ("shoulder harness not used", "Cinturón de hombro no usado"),
        ("passive restraint used", "Sujeción pasiva usada"),
        ("passive restraint not used", "Sujeción pasiva no usada"),
        ("air bag deployed", "Airbag desplegado"),
        ("air bag not deployed", "Airbag no desplegado"),
        ("child restraint in vehicle used", "Silla infantil usada"),
        ("child restraint in vehicle not used", "Silla infantil no usada"),
        ("child restraint in vehicle, improper use", "Silla infantil mal usada"),
        ("child restraint in vehicle, use unknown", "Silla infantil, uso desconocido"),
        ("no child restraint in vehicle", "Sin silla infantil en el vehículo"),
        ("driver, motorcycle helmet used", "Conductor con casco"),
        ("driver, motorcycle helmet not used", "Conductor sin casco"),
        ("passenger, motorcycle helmet used", "Pasajero con casco"),
        ("passenger, motorcycle helmet not used", "Pasajero sin casco"),
        ("none in vehicle", "Ninguno en el vehículo"),
        ("not required", "No requerido"),
        ("other", "Otro"),
        ("unknown", "Desconocido"),
    ],
}

# Los 58 condados con su codigo oficial (orden alfabetico del estado).
CONDADOS = [
    "Alameda", "Alpine", "Amador", "Butte", "Calaveras", "Colusa", "Contra Costa",
    "Del Norte", "El Dorado", "Fresno", "Glenn", "Humboldt", "Imperial", "Inyo",
    "Kern", "Kings", "Lake", "Lassen", "Los Angeles", "Madera", "Marin", "Mariposa",
    "Mendocino", "Merced", "Modoc", "Mono", "Monterey", "Napa", "Nevada", "Orange",
    "Placer", "Plumas", "Riverside", "Sacramento", "San Benito", "San Bernardino",
    "San Diego", "San Francisco", "San Joaquin", "San Luis Obispo", "San Mateo",
    "Santa Barbara", "Santa Clara", "Santa Cruz", "Shasta", "Sierra", "Siskiyou",
    "Solano", "Sonoma", "Stanislaus", "Sutter", "Tehama", "Trinity", "Tulare",
    "Tuolumne", "Ventura", "Yolo", "Yuba",
]

POBLACION = [
    ("<2500", "Menos de 2.500"),
    ("2500 to 10000", "2.500 a 10.000"),
    ("10000 to 25000", "10.000 a 25.000"),
    ("25000 to 50000", "25.000 a 50.000"),
    ("50000 to 100000", "50.000 a 100.000"),
    ("100000 to 250000", "100.000 a 250.000"),
    (">250000", "Más de 250.000"),
    ("unincorporated", "Zona no incorporada"),
]

# severidad_id = nivel KABCO maximo de las victimas de la colision.
SEVERIDAD = [
    (0, "property damage only", "Solo daños materiales", False),
    (1, "pain", "Lesión leve (queja de dolor)", True),
    (2, "other injury", "Lesión visible", True),
    (3, "severe injury", "Lesión grave", True),
    (4, "fatal", "Mortal", True),
]

# Bandas etarias excluyentes (06-D09). La 0 recoge NULL y edades en cuarentena.
BANDAS_EDAD = [
    (0, "Desconocida", None, None),
    (1, "0-17", 0, 17),
    (2, "18-25", 18, 25),
    (3, "26-35", 26, 35),
    (4, "36-50", 36, 50),
    (5, "51-64", 51, 64),
    (6, "65+", 65, 110),
]

MESES = ["enero", "febrero", "marzo", "abril", "mayo", "junio", "julio",
         "agosto", "septiembre", "octubre", "noviembre", "diciembre"]
DIAS = ["lunes", "martes", "miércoles", "jueves", "viernes", "sábado", "domingo"]


# ==============================================================================
# POBLACION
# ==============================================================================

def poblar_catalogos_de_codigos(con):
    faltantes = set(CATALOGOS) ^ set(VALORES)
    if faltantes:
        raise SystemExit(f"Catalogos sin definir o sobrantes: {sorted(faltantes)}")
    for nombre, filas in VALORES.items():
        n_extras = len(CATALOGOS[nombre])
        marcadores = ", ".join(["?"] * (4 + n_extras))
        con.execute(f"DELETE FROM {nombre}")
        con.execute(f"INSERT INTO {nombre} VALUES ({marcadores})",
                    [0, None, "Sin clasificar", 0] + [None] * n_extras)
        con.executemany(f"INSERT INTO {nombre} VALUES ({marcadores})",
                        [[i, fila[0], fila[1], i, *fila[2:]] for i, fila in enumerate(filas, start=1)])
        print(f"[OK] {nombre:<22}{len(filas) + 1:>4} filas")


def poblar_calendario(con):
    """Los 3.652 dias del periodo, tengan o no colisiones."""
    con.execute("DELETE FROM calendario")
    con.execute(f"""
        INSERT INTO calendario
        SELECT fecha,
               year(fecha),
               month(fecha),
               list_value({', '.join(repr(m) for m in MESES)})[month(fecha)],
               quarter(fecha),
               isodow(fecha),
               list_value({', '.join(repr(d) for d in DIAS)})[isodow(fecha)],
               isodow(fecha) >= 6
        FROM (SELECT unnest(generate_series(DATE '{DESDE}', DATE '{HASTA}' - INTERVAL 1 DAY,
                                            INTERVAL 1 DAY))::DATE AS fecha)
    """)
    n = con.execute("SELECT COUNT(*) FROM calendario").fetchone()[0]
    print(f"[OK] {'calendario':<22}{n:>4,} filas")


def poblar_especiales(con):
    for tabla in ("ubicacion", "condado", "poblacion", "severidad", "banda_edad"):
        con.execute(f"DELETE FROM {tabla}")
    con.execute("INSERT INTO condado VALUES (0, NULL, 'Sin clasificar')")
    con.executemany("INSERT INTO condado VALUES (?, ?, ?)",
                    [[i, nombre.lower(), nombre] for i, nombre in enumerate(CONDADOS, start=1)])
    con.execute("INSERT INTO poblacion VALUES (0, NULL, 'Sin clasificar', 0)")
    con.executemany("INSERT INTO poblacion VALUES (?, ?, ?, ?)",
                    [[i, c, e, i] for i, (c, e) in enumerate(POBLACION, start=1)])
    con.executemany("INSERT INTO severidad VALUES (?, ?, ?, ?)", SEVERIDAD)
    con.executemany("INSERT INTO banda_edad VALUES (?, ?, ?, ?)", BANDAS_EDAD)
    for tabla in ("condado", "poblacion", "severidad", "banda_edad"):
        n = con.execute(f"SELECT COUNT(*) FROM {tabla}").fetchone()[0]
        print(f"[OK] {tabla:<22}{n:>4} filas")


def poblar_ubicacion(con):
    """
    Catalogo derivado de la fuente. Antes de insertar se comprueba:
      - county_city_location -> (county_location, population) sin violaciones;
      - el condado de los dos primeros digitos coincide con county_location.
    Si algo falla, la carga se detiene: el modelo asume esa dependencia.
    """
    adjuntar_fuente(con)
    con.execute(f"""
        CREATE TEMP TABLE ubicacion_fuente AS
        SELECT DISTINCT county_city_location AS ccl, county_location, population
        FROM src.collisions
        WHERE collision_date >= '{DESDE}' AND collision_date < '{HASTA}'
    """)
    violaciones = con.execute("""
        SELECT COUNT(*) FROM (SELECT ccl FROM ubicacion_fuente GROUP BY ccl HAVING COUNT(*) > 1)
    """).fetchone()[0]
    incoherentes = con.execute("""
        SELECT COUNT(*) FROM ubicacion_fuente u
        LEFT JOIN condado c ON c.condado_id = CAST(substr(u.ccl, 1, 2) AS UTINYINT)
        WHERE c.codigo IS DISTINCT FROM u.county_location
    """).fetchone()[0]
    if violaciones or incoherentes:
        raise SystemExit(f"Dependencia funcional rota: {violaciones} violaciones, "
                         f"{incoherentes} condados incoherentes.")
    con.execute("""
        INSERT INTO ubicacion
        SELECT CAST(u.ccl AS USMALLINT),
               CAST(substr(u.ccl, 1, 2) AS UTINYINT),
               COALESCE(p.poblacion_id, 0)
        FROM ubicacion_fuente u
        LEFT JOIN poblacion p ON p.codigo = u.population
        ORDER BY 1
    """)
    con.execute("DETACH src")
    n = con.execute("SELECT COUNT(*) FROM ubicacion").fetchone()[0]
    print(f"[OK] {'ubicacion':<22}{n:>4} filas  (dependencia county_city_location verificada)")


def main():
    con = conectar()
    titulo("POBLACION DE LOS CATALOGOS")
    poblar_catalogos_de_codigos(con)
    poblar_calendario(con)
    poblar_especiales(con)
    poblar_ubicacion(con)
    con.close()


if __name__ == "__main__":
    main()
