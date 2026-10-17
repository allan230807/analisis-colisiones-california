"""
comun.py
================================================================================
CONFIGURACION COMPARTIDA DEL PIPELINE DE NORMALIZACION
Proyecto: Perfiles de riesgo en colisiones de transito — California (2010-2019)
Escuela de Estadistica y Ciencias Actuariales (EECA-UCV) — Computacion II
================================================================================

Rutas, periodo de estudio y la definicion de los catalogos de codigos. Se
centralizan aqui para que los cuatro scripts (01 a 04) no puedan divergir: si el
periodo o un catalogo cambia, cambia para todos.
"""

import os

import duckdb

DIRECTORIO = os.path.dirname(os.path.abspath(__file__))
RAIZ = os.path.abspath(os.path.join(DIRECTORIO, ".."))

# Base normalizada (no se versiona: se reconstruye con 01 -> 03).
BASE = os.path.join(DIRECTORIO, "colisiones_california.duckdb")

# Fuente cruda SWITRS. Se puede indicar otra ubicacion con SWITRS_PATH.
FUENTE = os.environ.get("SWITRS_PATH", os.path.join(RAIZ, "data", "raw", "switrs.sqlite"))

# Salida Parquet de la base normalizada.
SALIDA = os.path.join(RAIZ, "data", "processed")

# Periodo de estudio: 2010-01-01 <= fecha < 2020-01-01. La fuente guarda la
# fecha como TEXTO ISO, por lo que la comparacion lexicografica es cronologica.
DESDE, HASTA = "2010-01-01", "2020-01-01"
ANIOS = range(2010, 2020)

# Rangos validos auditados (04_fanout_rangos.sql). Fuera de ellos el valor se
# almacena NULL con bandera de cuarentena; la fila nunca se elimina.
EDAD_MIN, EDAD_MAX = 0, 110
ANIO_VEHICULO_MIN, ANIO_VEHICULO_MAX = 1900, 2020

# Caja geografica de California (lat 32-43, lon -125 a -114).
LAT_MIN, LAT_MAX, LON_MIN, LON_MAX = 32, 43, -125, -114

# ------------------------------------------------------------------------------
# CATALOGOS DE CODIGOS
# Todos comparten la estructura:
#     <nombre>_id UTINYINT PK | codigo VARCHAR UNIQUE | etiqueta | orden | extras
# El id 0 es siempre "Sin clasificar": absorbe NULL y codigos basura de la fuente.
# Clave = nombre del catalogo; valor = columnas extra (nombre, tipo DuckDB).
# ------------------------------------------------------------------------------
CATALOGOS = {
    # Grano colision
    "clima": [("es_adverso", "BOOLEAN")],
    "iluminacion": [("es_oscuridad", "BOOLEAN")],
    "superficie": [("es_adversa", "BOOLEAN")],
    "condicion_via": [],
    "dispositivo_control": [],
    "tipo_colision": [],
    "implicado_con": [],
    "factor_primario": [],
    "categoria_infraccion": [("grupo", "VARCHAR")],
    "fuga": [],
    "accion_peaton": [],
    # Grano parte
    "tipo_parte": [],
    "sobriedad": [],
    "droga_fisica": [],
    "direccion": [],
    "movimiento_previo": [],
    "raza": [],
    "tipo_vehiculo": [("grupo", "VARCHAR")],
    # Grano victima
    "rol_victima": [],
    "asiento": [],
    "eyeccion": [],
    "lesion": [("kabco", "VARCHAR"), ("nivel", "UTINYINT")],
    # Compartidos entre parte y victima
    "sexo": [],
    "equipo_seguridad": [],
}

# Catalogos especiales (estructura propia, ver 01_creacion_esquema.py).
CATALOGOS_ESPECIALES = ["calendario", "condado", "poblacion", "ubicacion", "severidad", "banda_edad"]

# Tablas del nucleo normalizado, en orden de carga (padres antes que hijos).
NUCLEO = ["colision", "colision_geo", "colision_carretera", "parte", "victima"]


def conectar(solo_lectura=False):
    return duckdb.connect(BASE, read_only=solo_lectura)


def adjuntar_fuente(con):
    if not os.path.exists(FUENTE):
        raise SystemExit(f"No se encuentra la fuente SWITRS en {FUENTE}\n"
                         "Ubiquela en data/raw/switrs.sqlite o indique SWITRS_PATH.")
    con.execute("INSTALL sqlite; LOAD sqlite;")
    con.execute(f"ATTACH '{FUENTE}' AS src (TYPE sqlite, READ_ONLY)")


def titulo(texto):
    print("=" * 72)
    print(texto)
    print("=" * 72)
