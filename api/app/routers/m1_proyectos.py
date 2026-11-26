"""Módulo 1: Proyectos y Lotes.

Responsable: Ian Anci
CRUD de proyecto, sector, manzana, lote y precio_lote, más dos procesos que
tocan varias tablas:
  * POST /proyectos/completo    -> proyecto + sectores + manzanas + lotes + precios
  * PUT  /lotes/{id}/precio     -> cierra el precio vigente y abre uno nuevo
"""
from typing import Annotated

from fastapi import APIRouter, Body, HTTPException, Query

from app.db import consultar, consultar_uno, exigir, transaccion
from app.schemas.m1 import (EJEMPLO_PROYECTO_COMPLETO, CambioPrecioIn, ManzanaIn, LoteIn, PrecioLoteIn,
                            ProyectoCompletoIn, ProyectoIn, SectorIn)

router = APIRouter()

T_PROY = "M1 · Proyectos"
T_SECT = "M1 · Sectores"
T_MANZ = "M1 · Manzanas"
T_LOTE = "M1 · Lotes"
T_PREC = "M1 · Precios de lote"


# =============================================================================
# PROYECTO
# =============================================================================
@router.get("/proyectos", tags=[T_PROY], summary="Listar proyectos")
def listar_proyectos(estado: str | None = None):
    return consultar(
        """
        SELECT id_proyecto, nombre, tipo_proyecto, departamento, provincia, distrito,
               partida_registral, hectareas, estado
        FROM   proyecto
        WHERE  (%(estado)s::varchar IS NULL OR estado = %(estado)s)
        ORDER  BY id_proyecto
        """,
        {"estado": estado},
    )


@router.get("/proyectos/{id_proyecto}", tags=[T_PROY], summary="Ver un proyecto")
def ver_proyecto(id_proyecto: int):
    fila = consultar_uno("SELECT * FROM proyecto WHERE id_proyecto = %s", (id_proyecto,))
    return exigir(fila, "Proyecto", id_proyecto)


@router.get("/proyectos/{id_proyecto}/resumen", tags=[T_PROY],
            summary="Resumen de lotes del proyecto por estado (JOIN + GROUP BY)")
def resumen_proyecto(id_proyecto: int):
    exigir(consultar_uno("SELECT 1 FROM proyecto WHERE id_proyecto = %s", (id_proyecto,)),
           "Proyecto", id_proyecto)
    return consultar(
        """
        SELECT l.estado_lote,
               COUNT(*)                AS cantidad_lotes,
               SUM(l.area_m2)          AS area_total_m2,
               SUM(pl.precio)          AS valor_a_precio_vigente
        FROM   lote l
        JOIN   manzana m ON m.id_manzana = l.id_manzana
        JOIN   sector  s ON s.id_sector  = m.id_sector
        LEFT JOIN precio_lote pl ON pl.id_lote = l.id_lote AND pl.fecha_fin IS NULL
        WHERE  s.id_proyecto = %s
        GROUP  BY l.estado_lote
        ORDER  BY cantidad_lotes DESC
        """,
        (id_proyecto,),
    )


@router.post("/proyectos", tags=[T_PROY], status_code=201, summary="Crear un proyecto")
def crear_proyecto(datos: ProyectoIn):
    return consultar_uno(
        """
        INSERT INTO proyecto (nombre, tipo_proyecto, departamento, provincia, distrito,
                              partida_registral, hectareas, estado)
        VALUES (%(nombre)s, %(tipo_proyecto)s, %(departamento)s, %(provincia)s, %(distrito)s,
                %(partida_registral)s, %(hectareas)s, %(estado)s)
        RETURNING *
        """,
        datos.model_dump(),
    )


@router.put("/proyectos/{id_proyecto}", tags=[T_PROY], summary="Actualizar un proyecto")
def actualizar_proyecto(id_proyecto: int, datos: ProyectoIn):
    fila = consultar_uno(
        """
        UPDATE proyecto
        SET    nombre = %(nombre)s, tipo_proyecto = %(tipo_proyecto)s,
               departamento = %(departamento)s, provincia = %(provincia)s,
               distrito = %(distrito)s, partida_registral = %(partida_registral)s,
               hectareas = %(hectareas)s, estado = %(estado)s
        WHERE  id_proyecto = %(id)s
        RETURNING *
        """,
        {**datos.model_dump(), "id": id_proyecto},
    )
    return exigir(fila, "Proyecto", id_proyecto)


@router.delete("/proyectos/{id_proyecto}", tags=[T_PROY],
               summary="Eliminar un proyecto (borra en cascada sectores, manzanas, lotes y precios)")
def eliminar_proyecto(id_proyecto: int):
    fila = consultar_uno(
        "DELETE FROM proyecto WHERE id_proyecto = %s RETURNING id_proyecto, nombre",
        (id_proyecto,),
    )
    return {"eliminado": exigir(fila, "Proyecto", id_proyecto)}


# -----------------------------------------------------------------------------
# Proceso: crear un proyecto completo en una sola transacción (5 tablas)
# -----------------------------------------------------------------------------
@router.post("/proyectos/completo", tags=[T_PROY], status_code=201,
             summary="Crear proyecto con sectores, manzanas, lotes y precios (inserción en cascada)")
def crear_proyecto_completo(
        datos: Annotated[ProyectoCompletoIn, Body(openapi_examples=EJEMPLO_PROYECTO_COMPLETO)]):
    """Inserta el proyecto y toda su estructura. Si falla un solo lote (por ejemplo,
    un número repetido en la misma manzana), se hace ROLLBACK y no se guarda nada."""
    resumen = {"sectores": 0, "manzanas": 0, "lotes": 0, "precios": 0}

    with transaccion() as cur:
        proyecto = cur.execute(
            """
            INSERT INTO proyecto (nombre, tipo_proyecto, departamento, provincia, distrito,
                                  partida_registral, hectareas, estado)
            VALUES (%(nombre)s, %(tipo_proyecto)s, %(departamento)s, %(provincia)s, %(distrito)s,
                    %(partida_registral)s, %(hectareas)s, %(estado)s)
            RETURNING *
            """,
            datos.model_dump(exclude={"sectores", "fecha_inicio_precios"}),
        ).fetchone()

        for sector in datos.sectores:
            id_sector = cur.execute(
                """
                INSERT INTO sector (id_proyecto, tipo_sector, nombre)
                VALUES (%s, %s, %s) RETURNING id_sector
                """,
                (proyecto["id_proyecto"], sector.tipo_sector, sector.nombre),
            ).fetchone()["id_sector"]
            resumen["sectores"] += 1

            for manzana in sector.manzanas:
                id_manzana = cur.execute(
                    "INSERT INTO manzana (id_sector, codigo) VALUES (%s, %s) RETURNING id_manzana",
                    (id_sector, manzana.codigo),
                ).fetchone()["id_manzana"]
                resumen["manzanas"] += 1

                for lote in manzana.lotes:
                    valores = lote.model_dump(exclude={"precio"})
                    # Las áreas verdes y aportes nacen bloqueados; los vendibles, disponibles.
                    valores["estado_lote"] = "DISPONIBLE" if lote.tipo_lote == "VENDIBLE" else "BLOQUEADO"
                    valores["id_manzana"] = id_manzana
                    id_lote = cur.execute(
                        """
                        INSERT INTO lote (id_manzana, numero, tipo_lote, estado_lote,
                                          area_m2, perimetro_m, frente_m, fondo_m,
                                          lado_izq_m, lado_der_m, colinda_frente, colinda_fondo,
                                          colinda_izq, colinda_der, partida_registral,
                                          es_esquina, frente_parque, en_avenida)
                        VALUES (%(id_manzana)s, %(numero)s, %(tipo_lote)s, %(estado_lote)s,
                                %(area_m2)s, %(perimetro_m)s, %(frente_m)s, %(fondo_m)s,
                                %(lado_izq_m)s, %(lado_der_m)s, %(colinda_frente)s, %(colinda_fondo)s,
                                %(colinda_izq)s, %(colinda_der)s, %(partida_registral)s,
                                %(es_esquina)s, %(frente_parque)s, %(en_avenida)s)
                        RETURNING id_lote
                        """,
                        valores,
                    ).fetchone()["id_lote"]
                    resumen["lotes"] += 1

                    if lote.precio is not None and lote.tipo_lote == "VENDIBLE":
                        cur.execute(
                            """
                            INSERT INTO precio_lote (id_lote, precio, fecha_inicio, motivo)
                            VALUES (%s, %s, %s, 'Precio de lanzamiento')
                            """,
                            (id_lote, lote.precio, datos.fecha_inicio_precios),
                        )
                        resumen["precios"] += 1

    return {"proyecto": proyecto, "creados": resumen}


# =============================================================================
# SECTOR
# =============================================================================
@router.get("/sectores", tags=[T_SECT], summary="Listar sectores")
def listar_sectores(id_proyecto: int | None = None):
    return consultar(
        """
        SELECT s.id_sector, s.id_proyecto, p.nombre AS proyecto, s.tipo_sector, s.nombre
        FROM   sector s
        JOIN   proyecto p ON p.id_proyecto = s.id_proyecto
        WHERE  (%(id_proyecto)s::int IS NULL OR s.id_proyecto = %(id_proyecto)s)
        ORDER  BY s.id_proyecto, s.nombre
        """,
        {"id_proyecto": id_proyecto},
    )


@router.get("/sectores/{id_sector}", tags=[T_SECT], summary="Ver un sector")
def ver_sector(id_sector: int):
    fila = consultar_uno("SELECT * FROM sector WHERE id_sector = %s", (id_sector,))
    return exigir(fila, "Sector", id_sector)


@router.post("/sectores", tags=[T_SECT], status_code=201, summary="Crear un sector")
def crear_sector(datos: SectorIn):
    return consultar_uno(
        """
        INSERT INTO sector (id_proyecto, tipo_sector, nombre)
        VALUES (%(id_proyecto)s, %(tipo_sector)s, %(nombre)s)
        RETURNING *
        """,
        datos.model_dump(),
    )


@router.put("/sectores/{id_sector}", tags=[T_SECT], summary="Actualizar un sector")
def actualizar_sector(id_sector: int, datos: SectorIn):
    fila = consultar_uno(
        """
        UPDATE sector
        SET    id_proyecto = %(id_proyecto)s, tipo_sector = %(tipo_sector)s, nombre = %(nombre)s
        WHERE  id_sector = %(id)s
        RETURNING *
        """,
        {**datos.model_dump(), "id": id_sector},
    )
    return exigir(fila, "Sector", id_sector)


@router.delete("/sectores/{id_sector}", tags=[T_SECT],
               summary="Eliminar un sector (borra en cascada sus manzanas y lotes)")
def eliminar_sector(id_sector: int):
    fila = consultar_uno("DELETE FROM sector WHERE id_sector = %s RETURNING *", (id_sector,))
    return {"eliminado": exigir(fila, "Sector", id_sector)}


# =============================================================================
# MANZANA
# =============================================================================
@router.get("/manzanas", tags=[T_MANZ], summary="Listar manzanas")
def listar_manzanas(id_sector: int | None = None):
    return consultar(
        """
        SELECT m.id_manzana, m.id_sector, s.nombre AS sector, p.nombre AS proyecto, m.codigo,
               (SELECT COUNT(*) FROM lote l WHERE l.id_manzana = m.id_manzana) AS cantidad_lotes
        FROM   manzana m
        JOIN   sector s   ON s.id_sector = m.id_sector
        JOIN   proyecto p ON p.id_proyecto = s.id_proyecto
        WHERE  (%(id_sector)s::int IS NULL OR m.id_sector = %(id_sector)s)
        ORDER  BY p.nombre, s.nombre, m.codigo
        """,
        {"id_sector": id_sector},
    )


@router.get("/manzanas/{id_manzana}", tags=[T_MANZ], summary="Ver una manzana")
def ver_manzana(id_manzana: int):
    fila = consultar_uno("SELECT * FROM manzana WHERE id_manzana = %s", (id_manzana,))
    return exigir(fila, "Manzana", id_manzana)


@router.post("/manzanas", tags=[T_MANZ], status_code=201, summary="Crear una manzana")
def crear_manzana(datos: ManzanaIn):
    return consultar_uno(
        "INSERT INTO manzana (id_sector, codigo) VALUES (%(id_sector)s, %(codigo)s) RETURNING *",
        datos.model_dump(),
    )


@router.put("/manzanas/{id_manzana}", tags=[T_MANZ], summary="Actualizar una manzana")
def actualizar_manzana(id_manzana: int, datos: ManzanaIn):
    fila = consultar_uno(
        """
        UPDATE manzana SET id_sector = %(id_sector)s, codigo = %(codigo)s
        WHERE  id_manzana = %(id)s
        RETURNING *
        """,
        {**datos.model_dump(), "id": id_manzana},
    )
    return exigir(fila, "Manzana", id_manzana)


@router.delete("/manzanas/{id_manzana}", tags=[T_MANZ],
               summary="Eliminar una manzana (borra en cascada sus lotes)")
def eliminar_manzana(id_manzana: int):
    fila = consultar_uno("DELETE FROM manzana WHERE id_manzana = %s RETURNING *", (id_manzana,))
    return {"eliminado": exigir(fila, "Manzana", id_manzana)}


# =============================================================================
# LOTE
# =============================================================================
_SQL_LOTES = """
    SELECT l.*, m.codigo AS manzana, s.nombre AS sector,
           p.id_proyecto, p.nombre AS proyecto, pl.precio AS precio_vigente
    FROM   lote l
    JOIN   manzana m  ON m.id_manzana  = l.id_manzana
    JOIN   sector s   ON s.id_sector   = m.id_sector
    JOIN   proyecto p ON p.id_proyecto = s.id_proyecto
    LEFT JOIN precio_lote pl ON pl.id_lote = l.id_lote AND pl.fecha_fin IS NULL
"""


@router.get("/lotes", tags=[T_LOTE], summary="Listar lotes con su ubicación y precio vigente")
def listar_lotes(id_proyecto: int | None = None, id_manzana: int | None = None,
                 estado: str | None = None,
                 limite: int = Query(100, ge=1, le=1000), desplazamiento: int = Query(0, ge=0)):
    return consultar(
        _SQL_LOTES + """
        WHERE  (%(id_proyecto)s::int     IS NULL OR p.id_proyecto = %(id_proyecto)s)
          AND  (%(id_manzana)s::int      IS NULL OR l.id_manzana  = %(id_manzana)s)
          AND  (%(estado)s::varchar      IS NULL OR l.estado_lote = %(estado)s)
        ORDER  BY p.id_proyecto, s.nombre, m.codigo, l.numero
        LIMIT  %(limite)s OFFSET %(desplazamiento)s
        """,
        {"id_proyecto": id_proyecto, "id_manzana": id_manzana, "estado": estado,
         "limite": limite, "desplazamiento": desplazamiento},
    )


@router.get("/lotes/{id_lote}", tags=[T_LOTE], summary="Ver un lote")
def ver_lote(id_lote: int):
    fila = consultar_uno(_SQL_LOTES + " WHERE l.id_lote = %s", (id_lote,))
    return exigir(fila, "Lote", id_lote)


_COLUMNAS_LOTE = """
    id_manzana = %(id_manzana)s, numero = %(numero)s, tipo_lote = %(tipo_lote)s,
    estado_lote = %(estado_lote)s, area_m2 = %(area_m2)s, perimetro_m = %(perimetro_m)s,
    frente_m = %(frente_m)s, fondo_m = %(fondo_m)s, lado_izq_m = %(lado_izq_m)s,
    lado_der_m = %(lado_der_m)s, colinda_frente = %(colinda_frente)s,
    colinda_fondo = %(colinda_fondo)s, colinda_izq = %(colinda_izq)s,
    colinda_der = %(colinda_der)s, partida_registral = %(partida_registral)s,
    es_esquina = %(es_esquina)s, frente_parque = %(frente_parque)s, en_avenida = %(en_avenida)s
"""


@router.post("/lotes", tags=[T_LOTE], status_code=201, summary="Crear un lote")
def crear_lote(datos: LoteIn):
    return consultar_uno(
        """
        INSERT INTO lote (id_manzana, numero, tipo_lote, estado_lote, area_m2, perimetro_m,
                          frente_m, fondo_m, lado_izq_m, lado_der_m, colinda_frente,
                          colinda_fondo, colinda_izq, colinda_der, partida_registral,
                          es_esquina, frente_parque, en_avenida)
        VALUES (%(id_manzana)s, %(numero)s, %(tipo_lote)s, %(estado_lote)s, %(area_m2)s,
                %(perimetro_m)s, %(frente_m)s, %(fondo_m)s, %(lado_izq_m)s, %(lado_der_m)s,
                %(colinda_frente)s, %(colinda_fondo)s, %(colinda_izq)s, %(colinda_der)s,
                %(partida_registral)s, %(es_esquina)s, %(frente_parque)s, %(en_avenida)s)
        RETURNING *
        """,
        datos.model_dump(),
    )


@router.put("/lotes/{id_lote}", tags=[T_LOTE], summary="Actualizar un lote")
def actualizar_lote(id_lote: int, datos: LoteIn):
    fila = consultar_uno(
        f"UPDATE lote SET {_COLUMNAS_LOTE} WHERE id_lote = %(id)s RETURNING *",
        {**datos.model_dump(), "id": id_lote},
    )
    return exigir(fila, "Lote", id_lote)


@router.delete("/lotes/{id_lote}", tags=[T_LOTE],
               summary="Eliminar un lote (borra sus precios; se bloquea si tiene ventas o separaciones)")
def eliminar_lote(id_lote: int):
    fila = consultar_uno(
        "DELETE FROM lote WHERE id_lote = %s RETURNING id_lote, id_manzana, numero", (id_lote,)
    )
    return {"eliminado": exigir(fila, "Lote", id_lote)}


# -----------------------------------------------------------------------------
# Proceso: cambiar el precio de un lote (actualización vinculada)
# -----------------------------------------------------------------------------
@router.put("/lotes/{id_lote}/precio", tags=[T_LOTE],
            summary="Cambiar el precio: cierra el precio vigente y registra el nuevo")
def cambiar_precio_lote(id_lote: int, datos: CambioPrecioIn):
    with transaccion() as cur:
        lote = cur.execute(
            "SELECT id_lote, tipo_lote, estado_lote FROM lote WHERE id_lote = %s FOR UPDATE",
            (id_lote,),
        ).fetchone()
        exigir(lote, "Lote", id_lote)
        if lote["tipo_lote"] != "VENDIBLE":
            raise HTTPException(422, f"El lote {id_lote} es {lote['tipo_lote']} y no se vende")

        anterior = cur.execute(
            """
            UPDATE precio_lote
            SET    fecha_fin = GREATEST(%(fecha)s::date - 1, fecha_inicio)
            WHERE  id_lote = %(id)s AND fecha_fin IS NULL
            RETURNING *
            """,
            {"fecha": datos.fecha_inicio, "id": id_lote},
        ).fetchone()

        nuevo = cur.execute(
            """
            INSERT INTO precio_lote (id_lote, precio, fecha_inicio, motivo)
            VALUES (%s, %s, %s, %s)
            RETURNING *
            """,
            (id_lote, datos.precio, datos.fecha_inicio, datos.motivo),
        ).fetchone()

    return {"lote": lote, "precio_anterior": anterior, "precio_nuevo": nuevo}


# =============================================================================
# PRECIO_LOTE
# =============================================================================
@router.get("/precios-lote", tags=[T_PREC], summary="Listar precios (historial)")
def listar_precios(id_lote: int | None = None, solo_vigentes: bool = False):
    return consultar(
        """
        SELECT id_precio, id_lote, precio, fecha_inicio, fecha_fin, motivo,
               (fecha_fin IS NULL) AS vigente
        FROM   precio_lote
        WHERE  (%(id_lote)s::int IS NULL OR id_lote = %(id_lote)s)
          AND  (NOT %(solo_vigentes)s OR fecha_fin IS NULL)
        ORDER  BY id_lote, fecha_inicio
        """,
        {"id_lote": id_lote, "solo_vigentes": solo_vigentes},
    )


@router.get("/precios-lote/{id_precio}", tags=[T_PREC], summary="Ver un precio")
def ver_precio(id_precio: int):
    fila = consultar_uno("SELECT * FROM precio_lote WHERE id_precio = %s", (id_precio,))
    return exigir(fila, "Precio", id_precio)


@router.post("/precios-lote", tags=[T_PREC], status_code=201, summary="Crear un precio")
def crear_precio(datos: PrecioLoteIn):
    return consultar_uno(
        """
        INSERT INTO precio_lote (id_lote, precio, fecha_inicio, fecha_fin, motivo)
        VALUES (%(id_lote)s, %(precio)s, %(fecha_inicio)s, %(fecha_fin)s, %(motivo)s)
        RETURNING *
        """,
        datos.model_dump(),
    )


@router.put("/precios-lote/{id_precio}", tags=[T_PREC], summary="Actualizar un precio")
def actualizar_precio(id_precio: int, datos: PrecioLoteIn):
    fila = consultar_uno(
        """
        UPDATE precio_lote
        SET    id_lote = %(id_lote)s, precio = %(precio)s, fecha_inicio = %(fecha_inicio)s,
               fecha_fin = %(fecha_fin)s, motivo = %(motivo)s
        WHERE  id_precio = %(id)s
        RETURNING *
        """,
        {**datos.model_dump(), "id": id_precio},
    )
    return exigir(fila, "Precio", id_precio)


@router.delete("/precios-lote/{id_precio}", tags=[T_PREC], summary="Eliminar un precio")
def eliminar_precio(id_precio: int):
    fila = consultar_uno("DELETE FROM precio_lote WHERE id_precio = %s RETURNING *", (id_precio,))
    return {"eliminado": exigir(fila, "Precio", id_precio)}
