"""
04_exportacion_parquet.py
================================================================================
EXPORTACION DE LA BASE NORMALIZADA A PARQUET
Proyecto: Perfiles de riesgo en colisiones de transito — California (2010-2019)
Escuela de Estadistica y Ciencias Actuariales (EECA-UCV) — Computacion II
================================================================================

POR QUE PARQUET
---------------
El archivo .duckdb es propio de un motor y de una version. Parquet es un formato
abierto y columnar que leen DuckDB, pandas, R, Spark y Power BI. Ademas:

  1. LECTURA SELECTIVA: una consulta que usa 3 columnas lee solo esas 3.
  2. COMPRESION: valores homogeneos por columna + ZSTD.
  3. CODIFICACION DELTA: con PARQUET_VERSION V2, las claves ordenadas (case_id)
     se guardan como diferencias entre valores consecutivos, que son pequenas.

PARTICION POR ANIO
------------------
Las cinco tablas del nucleo se escriben en un archivo por anio. Asi ningun
archivo supera el limite recomendado de GitHub (50 MB) y, al filtrar por anio,
DuckDB y Power BI ni siquiera abren los archivos de los anios descartados.
parte, victima y los subtipos heredan el anio de su colision.

SALIDA (data/processed/)
------------------------
    catalogos/<catalogo>.parquet ............... 30 archivos
    <tabla>/<tabla>_<anio>.parquet ............. 5 tablas x 10 anios

Las vistas en estrella no se exportan: son consultas sobre el nucleo y se
reconstruyen en el destino (DuckDB o el modelo de Power BI).
"""

import os
import shutil
import time

import duckdb

from comun import ANIOS, BASE, CATALOGOS, CATALOGOS_ESPECIALES, NUCLEO, SALIDA, conectar, titulo

ORDEN = {
    "colision": "case_id",
    "colision_geo": "case_id",
    "colision_carretera": "case_id",
    "parte": "case_id, numero_parte",
    "victima": "case_id, numero_parte, numero_victima",
}

OPCIONES = "FORMAT PARQUET, COMPRESSION ZSTD, COMPRESSION_LEVEL 9, PARQUET_VERSION V2"


def tamano(ruta):
    if os.path.isfile(ruta):
        return os.path.getsize(ruta)
    return sum(os.path.getsize(os.path.join(r, f)) for r, _, fs in os.walk(ruta) for f in fs)


def exportar_catalogos(con):
    destino = os.path.join(SALIDA, "catalogos")
    os.makedirs(destino)
    for nombre in list(CATALOGOS) + CATALOGOS_ESPECIALES:
        con.execute(f"COPY (SELECT * FROM {nombre} ORDER BY 1) "
                    f"TO '{os.path.join(destino, nombre + '.parquet')}' ({OPCIONES})")
    n = len(CATALOGOS) + len(CATALOGOS_ESPECIALES)
    print(f"{'catalogos/':<24}{n:>6} archivos{tamano(destino) / 1e6:>14.2f} MB")


def exportar_nucleo(con):
    for tabla in NUCLEO:
        destino = os.path.join(SALIDA, tabla)
        os.makedirs(destino)
        mayor = 0
        for anio in ANIOS:
            ruta = os.path.join(destino, f"{tabla}_{anio}.parquet")
            con.execute(f"""
                COPY (SELECT t.* FROM {tabla} t
                      SEMI JOIN (SELECT case_id FROM colision WHERE year(fecha) = {anio}) a USING (case_id)
                      ORDER BY {ORDEN[tabla]})
                TO '{ruta}' ({OPCIONES})
            """)
            mayor = max(mayor, os.path.getsize(ruta))
        print(f"{tabla + '/':<24}{len(ANIOS):>6} archivos{tamano(destino) / 1e6:>14.2f} MB"
              f"   (mayor: {mayor / 1e6:.2f} MB)")


def verificar(con):
    """
    Los Parquet deben reproducir exactamente la base. Se leen los archivos recien
    escritos, no la base: si la exportacion perdiera o duplicara filas, se detecta.
    """
    titulo("VERIFICACION DE LOS PARQUET")
    lago = duckdb.connect()
    print(f"{'TABLA':<22}{'FILAS BASE':>14}{'FILAS PARQUET':>16}{'CLAVES PARQUET':>16}")
    print("-" * 72)
    todo = True
    for tabla in NUCLEO:
        patron = os.path.join(SALIDA, tabla, "*.parquet")
        base = con.execute(f"SELECT COUNT(*) FROM {tabla}").fetchone()[0]
        filas, claves = lago.execute(
            f"SELECT COUNT(*), COUNT(DISTINCT ({ORDEN[tabla]})) FROM read_parquet('{patron}')").fetchone()
        ok = base == filas == claves
        todo = todo and ok
        print(f"{tabla:<22}{base:>14,}{filas:>16,}{claves:>16,}{'' if ok else '   <-- DISCREPA'}")

    # Medida de control recalculada desde los Parquet: muertos por la escala KABCO.
    muertos_base = con.execute("SELECT SUM(muertos) FROM vw_hecho_colision").fetchone()[0]
    muertos_lago = lago.execute(f"""
        SELECT COUNT(*) FROM read_parquet('{os.path.join(SALIDA, 'victima', '*.parquet')}') v
        JOIN read_parquet('{os.path.join(SALIDA, 'catalogos', 'lesion.parquet')}') l USING (lesion_id)
        WHERE l.kabco = 'K'
    """).fetchone()[0]
    ok = muertos_base == muertos_lago
    todo = todo and ok
    print(f"{'muertos (KABCO = K)':<22}{muertos_base:>14,}{muertos_lago:>16,}{'':>16}{'' if ok else '   <-- DISCREPA'}")
    lago.close()
    return todo


def main():
    con = conectar(solo_lectura=True)
    if con.execute("SELECT COUNT(*) FROM colision").fetchone()[0] == 0:
        raise SystemExit("La base esta vacia. Ejecute antes 01, 02 y 03.")
    if os.path.exists(SALIDA):
        shutil.rmtree(SALIDA)
    os.makedirs(SALIDA)

    titulo("EXPORTACION A PARQUET (data/processed/)")
    t0 = time.time()
    exportar_catalogos(con)
    exportar_nucleo(con)
    print("-" * 72)
    archivos = sum(len(fs) for _, _, fs in os.walk(SALIDA))
    print(f"Total: {archivos} archivos, {tamano(SALIDA) / 1e6:.1f} MB ({time.time() - t0:.0f}s)")
    print(f"Base normalizada .duckdb: {os.path.getsize(BASE) / 1e6:.1f} MB")

    bien = verificar(con)
    con.close()
    print("\n" + ("EXPORTACION VERIFICADA" if bien else "ATENCION: HAY DISCREPANCIAS"))
    if not bien:
        raise SystemExit(1)


if __name__ == "__main__":
    main()
