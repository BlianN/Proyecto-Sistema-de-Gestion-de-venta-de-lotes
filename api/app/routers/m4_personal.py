"""Módulo 4: Personal y Sueldos.

Responsable: Ian Anci
CRUD de empleado, sueldo y pago_sueldo, más dos procesos que tocan varias tablas:
  * POST /empleados/completo      -> persona + persona_natural + empleado + sueldo
  * PUT  /empleados/{id}/sueldo   -> cierra el sueldo vigente y abre uno nuevo
"""
from typing import Annotated

from fastapi import APIRouter, Body, HTTPException

from app.db import consultar, consultar_uno, exigir, transaccion
from app.schemas.m4 import EJEMPLO_EMPLEADO_COMPLETO, CambioSueldoIn, EmpleadoCompletoIn, EmpleadoIn, PagoSueldoIn, SueldoIn

router = APIRouter()

T_EMPL = "M4 · Empleados"
T_SUEL = "M4 · Sueldos"
T_PSUE = "M4 · Pagos de sueldo"


# =============================================================================
# EMPLEADO
# =============================================================================
_SQL_EMPLEADOS = """
    SELECT e.*, pn.nombres || ' ' || pn.apellido_paterno AS nombre, pn.nro_documento,
           o.nombre AS oficina, pr.nombre AS proyecto, s.monto_mensual AS sueldo_vigente
    FROM   empleado e
    JOIN   persona_natural pn ON pn.id_persona = e.id_persona
    JOIN   oficina o          ON o.codigo_oficina = e.codigo_oficina
    LEFT JOIN proyecto pr     ON pr.id_proyecto = e.id_proyecto
    LEFT JOIN sueldo s        ON s.id_empleado = e.id_empleado AND s.fecha_fin IS NULL
"""


@router.get("/empleados", tags=[T_EMPL], summary="Listar empleados con oficina, proyecto y sueldo vigente")
def listar_empleados(estado: str | None = None, codigo_oficina: str | None = None):
    return consultar(
        _SQL_EMPLEADOS + """
        WHERE  (%(estado)s::varchar  IS NULL OR e.estado = %(estado)s)
          AND  (%(oficina)s::varchar IS NULL OR e.codigo_oficina = %(oficina)s)
        ORDER  BY e.id_empleado
        """,
        {"estado": estado, "oficina": codigo_oficina},
    )


@router.get("/empleados/{id_empleado}", tags=[T_EMPL], summary="Ver un empleado")
def ver_empleado(id_empleado: int):
    return exigir(consultar_uno(_SQL_EMPLEADOS + " WHERE e.id_empleado = %s", (id_empleado,)),
                  "Empleado", id_empleado)


@router.post("/empleados", tags=[T_EMPL], status_code=201,
             summary="Crear un empleado a partir de una persona natural existente")
def crear_empleado(datos: EmpleadoIn):
    return consultar_uno(
        """
        INSERT INTO empleado (id_persona, codigo_oficina, id_proyecto, cargo,
                              fecha_ingreso, fecha_cese, estado)
        VALUES (%(id_persona)s, %(codigo_oficina)s, %(id_proyecto)s, %(cargo)s,
                %(fecha_ingreso)s, %(fecha_cese)s, %(estado)s)
        RETURNING *
        """,
        datos.model_dump(),
    )


@router.put("/empleados/{id_empleado}", tags=[T_EMPL], summary="Actualizar un empleado")
def actualizar_empleado(id_empleado: int, datos: EmpleadoIn):
    fila = consultar_uno(
        """
        UPDATE empleado
        SET    id_persona = %(id_persona)s, codigo_oficina = %(codigo_oficina)s,
               id_proyecto = %(id_proyecto)s, cargo = %(cargo)s, fecha_ingreso = %(fecha_ingreso)s,
               fecha_cese = %(fecha_cese)s, estado = %(estado)s
        WHERE  id_empleado = %(id)s
        RETURNING *
        """,
        {**datos.model_dump(), "id": id_empleado},
    )
    return exigir(fila, "Empleado", id_empleado)


@router.delete("/empleados/{id_empleado}", tags=[T_EMPL],
               summary="Eliminar un empleado (borra su historial de sueldos; se bloquea si tiene sueldos pagados)")
def eliminar_empleado(id_empleado: int):
    fila = consultar_uno("DELETE FROM empleado WHERE id_empleado = %s RETURNING *", (id_empleado,))
    return {"eliminado": exigir(fila, "Empleado", id_empleado)}


# -----------------------------------------------------------------------------
# Proceso: contratar a una persona nueva (4 tablas en una transacción)
# -----------------------------------------------------------------------------
@router.post("/empleados/completo", tags=[T_EMPL], status_code=201,
             summary="Contratar: persona + persona_natural + empleado + sueldo en una transacción")
def crear_empleado_completo(
        datos: Annotated[EmpleadoCompletoIn, Body(openapi_examples=EJEMPLO_EMPLEADO_COMPLETO)]):
    """Si el DNI ya existe, o la oficina no existe, se hace ROLLBACK y no queda nada a medias."""
    d = datos.model_dump()
    with transaccion() as cur:
        id_persona = cur.execute(
            """
            INSERT INTO persona (tipo_persona, direccion, telefono, correo)
            VALUES ('N', %(direccion)s, %(telefono)s, %(correo)s)
            RETURNING id_persona
            """,
            d,
        ).fetchone()["id_persona"]
        d["id_persona"] = id_persona

        cur.execute(
            """
            INSERT INTO persona_natural (id_persona, tipo_documento, nro_documento, nombres,
                                         apellido_paterno, apellido_materno, nacionalidad,
                                         estado_civil, ocupacion)
            VALUES (%(id_persona)s, %(tipo_documento)s, %(nro_documento)s, %(nombres)s,
                    %(apellido_paterno)s, %(apellido_materno)s, %(nacionalidad)s,
                    %(estado_civil)s, %(cargo)s)
            """,
            d,
        )

        empleado = cur.execute(
            """
            INSERT INTO empleado (id_persona, codigo_oficina, id_proyecto, cargo, fecha_ingreso, estado)
            VALUES (%(id_persona)s, %(codigo_oficina)s, %(id_proyecto)s, %(cargo)s,
                    %(fecha_ingreso)s, 'ACTIVO')
            RETURNING *
            """,
            d,
        ).fetchone()

        sueldo = cur.execute(
            """
            INSERT INTO sueldo (id_empleado, monto_mensual, fecha_inicio)
            VALUES (%s, %s, %s)
            RETURNING *
            """,
            (empleado["id_empleado"], datos.sueldo_mensual, datos.fecha_ingreso),
        ).fetchone()

    return {"empleado": empleado, "sueldo": sueldo}


# -----------------------------------------------------------------------------
# Proceso: cambio de sueldo (actualización vinculada)
# -----------------------------------------------------------------------------
@router.put("/empleados/{id_empleado}/sueldo", tags=[T_EMPL],
            summary="Cambiar el sueldo: cierra el sueldo vigente y registra el nuevo")
def cambiar_sueldo(id_empleado: int, datos: CambioSueldoIn):
    with transaccion() as cur:
        empleado = cur.execute(
            "SELECT id_empleado, estado FROM empleado WHERE id_empleado = %s FOR UPDATE", (id_empleado,)
        ).fetchone()
        exigir(empleado, "Empleado", id_empleado)
        if empleado["estado"] != "ACTIVO":
            raise HTTPException(422, "Solo se cambia el sueldo de empleados activos")

        anterior = cur.execute(
            """
            UPDATE sueldo
            SET    fecha_fin = GREATEST(%(fecha)s::date - 1, fecha_inicio)
            WHERE  id_empleado = %(id)s AND fecha_fin IS NULL
            RETURNING *
            """,
            {"fecha": datos.fecha_inicio, "id": id_empleado},
        ).fetchone()

        nuevo = cur.execute(
            """
            INSERT INTO sueldo (id_empleado, monto_mensual, fecha_inicio)
            VALUES (%s, %s, %s)
            RETURNING *
            """,
            (id_empleado, datos.monto_mensual, datos.fecha_inicio),
        ).fetchone()

    return {"sueldo_anterior": anterior, "sueldo_nuevo": nuevo}


# =============================================================================
# SUELDO
# =============================================================================
@router.get("/sueldos", tags=[T_SUEL], summary="Listar sueldos (historial)")
def listar_sueldos(id_empleado: int | None = None):
    return consultar(
        """
        SELECT s.*, (s.fecha_fin IS NULL) AS vigente
        FROM   sueldo s
        WHERE  (%(id)s::int IS NULL OR s.id_empleado = %(id)s)
        ORDER  BY s.id_empleado, s.fecha_inicio
        """,
        {"id": id_empleado},
    )


@router.get("/sueldos/{id_sueldo}", tags=[T_SUEL], summary="Ver un sueldo")
def ver_sueldo(id_sueldo: int):
    return exigir(consultar_uno("SELECT * FROM sueldo WHERE id_sueldo = %s", (id_sueldo,)),
                  "Sueldo", id_sueldo)


@router.post("/sueldos", tags=[T_SUEL], status_code=201, summary="Crear un sueldo")
def crear_sueldo(datos: SueldoIn):
    return consultar_uno(
        """
        INSERT INTO sueldo (id_empleado, monto_mensual, fecha_inicio, fecha_fin)
        VALUES (%(id_empleado)s, %(monto_mensual)s, %(fecha_inicio)s, %(fecha_fin)s)
        RETURNING *
        """,
        datos.model_dump(),
    )


@router.put("/sueldos/{id_sueldo}", tags=[T_SUEL], summary="Actualizar un sueldo")
def actualizar_sueldo(id_sueldo: int, datos: SueldoIn):
    fila = consultar_uno(
        """
        UPDATE sueldo
        SET    id_empleado = %(id_empleado)s, monto_mensual = %(monto_mensual)s,
               fecha_inicio = %(fecha_inicio)s, fecha_fin = %(fecha_fin)s
        WHERE  id_sueldo = %(id)s
        RETURNING *
        """,
        {**datos.model_dump(), "id": id_sueldo},
    )
    return exigir(fila, "Sueldo", id_sueldo)


@router.delete("/sueldos/{id_sueldo}", tags=[T_SUEL], summary="Eliminar un sueldo")
def eliminar_sueldo(id_sueldo: int):
    fila = consultar_uno("DELETE FROM sueldo WHERE id_sueldo = %s RETURNING *", (id_sueldo,))
    return {"eliminado": exigir(fila, "Sueldo", id_sueldo)}


# =============================================================================
# PAGO_SUELDO
# =============================================================================
@router.get("/pagos-sueldo", tags=[T_PSUE], summary="Listar pagos de sueldo")
def listar_pagos_sueldo(id_empleado: int | None = None, periodo: str | None = None):
    return consultar(
        """
        SELECT ps.*, pn.nombres || ' ' || pn.apellido_paterno AS empleado
        FROM   pago_sueldo ps
        JOIN   empleado e        ON e.id_empleado = ps.id_empleado
        JOIN   persona_natural pn ON pn.id_persona = e.id_persona
        WHERE  (%(id)s::int          IS NULL OR ps.id_empleado = %(id)s)
          AND  (%(periodo)s::varchar IS NULL OR ps.periodo = %(periodo)s)
        ORDER  BY ps.periodo DESC, ps.id_empleado
        """,
        {"id": id_empleado, "periodo": periodo},
    )


@router.get("/pagos-sueldo/{id_pago_sueldo}", tags=[T_PSUE], summary="Ver un pago de sueldo")
def ver_pago_sueldo(id_pago_sueldo: int):
    return exigir(consultar_uno("SELECT * FROM pago_sueldo WHERE id_pago_sueldo = %s", (id_pago_sueldo,)),
                  "Pago de sueldo", id_pago_sueldo)


@router.post("/pagos-sueldo", tags=[T_PSUE], status_code=201, summary="Registrar un pago de sueldo")
def crear_pago_sueldo(datos: PagoSueldoIn):
    return consultar_uno(
        """
        INSERT INTO pago_sueldo (id_empleado, periodo, fecha_pago, monto, medio_pago)
        VALUES (%(id_empleado)s, %(periodo)s, %(fecha_pago)s, %(monto)s, %(medio_pago)s)
        RETURNING *
        """,
        datos.model_dump(),
    )


@router.put("/pagos-sueldo/{id_pago_sueldo}", tags=[T_PSUE], summary="Actualizar un pago de sueldo")
def actualizar_pago_sueldo(id_pago_sueldo: int, datos: PagoSueldoIn):
    fila = consultar_uno(
        """
        UPDATE pago_sueldo
        SET    id_empleado = %(id_empleado)s, periodo = %(periodo)s, fecha_pago = %(fecha_pago)s,
               monto = %(monto)s, medio_pago = %(medio_pago)s
        WHERE  id_pago_sueldo = %(id)s
        RETURNING *
        """,
        {**datos.model_dump(), "id": id_pago_sueldo},
    )
    return exigir(fila, "Pago de sueldo", id_pago_sueldo)


@router.delete("/pagos-sueldo/{id_pago_sueldo}", tags=[T_PSUE], summary="Eliminar un pago de sueldo")
def eliminar_pago_sueldo(id_pago_sueldo: int):
    fila = consultar_uno("DELETE FROM pago_sueldo WHERE id_pago_sueldo = %s RETURNING *", (id_pago_sueldo,))
    return {"eliminado": exigir(fila, "Pago de sueldo", id_pago_sueldo)}
