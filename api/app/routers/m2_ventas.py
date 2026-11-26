"""Módulo 2: Ventas.

CRUD de persona (natural y jurídica), asesor, separacion, venta y
venta_participante, más los procesos que tocan varias tablas:
  * POST /separaciones/registrar -> separación + estado del lote
  * POST /ventas/registrar       -> venta + participantes + separación + lote
                                    + cronograma de cuotas (fn_generar_cronograma, módulo 3)
  * PUT  /ventas/{id}/anular     -> venta + cuotas + lote
"""
from datetime import date, timedelta

from typing import Annotated

from fastapi import APIRouter, Body, HTTPException, Query

from app.db import consultar, consultar_uno, exigir, transaccion
from app.schemas.m2 import (EJEMPLO_SEPARACION, EJEMPLO_VENTA, AsesorIn, PersonaJuridicaIn, PersonaNaturalIn, RolIn,
                            SeparacionIn, SeparacionNuevaIn, VentaCrearIn, VentaIn,
                            VentaNuevaIn, VentaParticipanteIn)

router = APIRouter()

T_PERS = "M2 · Personas"
T_ASES = "M2 · Asesores"
T_SEPA = "M2 · Separaciones"
T_VENT = "M2 · Ventas"
T_PART = "M2 · Participantes de venta"

# Nombre para mostrar de cualquier persona (natural o jurídica).
NOMBRE_PERSONA = """COALESCE(pn.nombres || ' ' || pn.apellido_paterno
                          || COALESCE(' ' || pn.apellido_materno, ''), pj.razon_social)"""


# =============================================================================
# PERSONA (vista general de naturales y jurídicas)
# =============================================================================
@router.get("/personas", tags=[T_PERS], summary="Listar personas (naturales y jurídicas)")
def listar_personas(tipo: str | None = Query(None, description="N o J"),
                    buscar: str | None = Query(None, description="Nombre, razón social, DNI o RUC"),
                    limite: int = Query(100, ge=1, le=1000), desplazamiento: int = Query(0, ge=0)):
    return consultar(
        f"""
        SELECT p.id_persona, p.tipo_persona, {NOMBRE_PERSONA} AS nombre,
               COALESCE(pn.tipo_documento, 'RUC') AS tipo_documento,
               COALESCE(pn.nro_documento, pj.ruc)  AS nro_documento,
               p.direccion, p.telefono, p.correo
        FROM   persona p
        LEFT JOIN persona_natural  pn ON pn.id_persona = p.id_persona
        LEFT JOIN persona_juridica pj ON pj.id_persona = p.id_persona
        WHERE  (%(tipo)s::char IS NULL OR p.tipo_persona = %(tipo)s)
          AND  (%(buscar)s::varchar IS NULL
                OR {NOMBRE_PERSONA} ILIKE '%%' || %(buscar)s || '%%'
                OR pn.nro_documento = %(buscar)s OR pj.ruc = %(buscar)s)
        ORDER  BY p.id_persona
        LIMIT  %(limite)s OFFSET %(desplazamiento)s
        """,
        {"tipo": tipo, "buscar": buscar, "limite": limite, "desplazamiento": desplazamiento},
    )


@router.get("/personas/{id_persona}", tags=[T_PERS], summary="Ver una persona")
def ver_persona(id_persona: int):
    fila = consultar_uno(
        f"""
        SELECT p.*, {NOMBRE_PERSONA} AS nombre
        FROM   persona p
        LEFT JOIN persona_natural  pn ON pn.id_persona = p.id_persona
        LEFT JOIN persona_juridica pj ON pj.id_persona = p.id_persona
        WHERE  p.id_persona = %s
        """,
        (id_persona,),
    )
    return exigir(fila, "Persona", id_persona)


@router.delete("/personas/{id_persona}", tags=[T_PERS],
               summary="Eliminar una persona (borra en cascada su fila natural o jurídica)")
def eliminar_persona(id_persona: int):
    fila = consultar_uno(
        "DELETE FROM persona WHERE id_persona = %s RETURNING id_persona, tipo_persona", (id_persona,)
    )
    return {"eliminado": exigir(fila, "Persona", id_persona)}


# =============================================================================
# PERSONA_NATURAL  (cada alta inserta en persona y persona_natural)
# =============================================================================
_SQL_NATURAL = """
    SELECT p.id_persona, pn.tipo_documento, pn.nro_documento, pn.nombres,
           pn.apellido_paterno, pn.apellido_materno, pn.nacionalidad, pn.estado_civil,
           pn.ocupacion, p.direccion, p.telefono, p.telefono_2, p.correo
    FROM   persona p
    JOIN   persona_natural pn ON pn.id_persona = p.id_persona
"""


@router.get("/personas-naturales", tags=[T_PERS], summary="Listar personas naturales")
def listar_naturales(limite: int = Query(100, ge=1, le=1000), desplazamiento: int = Query(0, ge=0)):
    return consultar(_SQL_NATURAL + " ORDER BY p.id_persona LIMIT %s OFFSET %s",
                     (limite, desplazamiento))


@router.get("/personas-naturales/{id_persona}", tags=[T_PERS], summary="Ver una persona natural")
def ver_natural(id_persona: int):
    fila = consultar_uno(_SQL_NATURAL + " WHERE p.id_persona = %s", (id_persona,))
    return exigir(fila, "Persona natural", id_persona)


@router.post("/personas-naturales", tags=[T_PERS], status_code=201,
             summary="Crear persona natural (persona + persona_natural en una transacción)")
def crear_natural(datos: PersonaNaturalIn):
    with transaccion() as cur:
        id_persona = cur.execute(
            """
            INSERT INTO persona (tipo_persona, direccion, telefono, telefono_2, correo)
            VALUES ('N', %(direccion)s, %(telefono)s, %(telefono_2)s, %(correo)s)
            RETURNING id_persona
            """,
            datos.model_dump(),
        ).fetchone()["id_persona"]
        cur.execute(
            """
            INSERT INTO persona_natural (id_persona, tipo_documento, nro_documento, nombres,
                                         apellido_paterno, apellido_materno, nacionalidad,
                                         estado_civil, ocupacion)
            VALUES (%(id)s, %(tipo_documento)s, %(nro_documento)s, %(nombres)s,
                    %(apellido_paterno)s, %(apellido_materno)s, %(nacionalidad)s,
                    %(estado_civil)s, %(ocupacion)s)
            """,
            {**datos.model_dump(), "id": id_persona},
        )
    return ver_natural(id_persona)


@router.put("/personas-naturales/{id_persona}", tags=[T_PERS], summary="Actualizar persona natural")
def actualizar_natural(id_persona: int, datos: PersonaNaturalIn):
    valores = {**datos.model_dump(), "id": id_persona}
    with transaccion() as cur:
        fila = cur.execute(
            """
            UPDATE persona_natural
            SET    tipo_documento = %(tipo_documento)s, nro_documento = %(nro_documento)s,
                   nombres = %(nombres)s, apellido_paterno = %(apellido_paterno)s,
                   apellido_materno = %(apellido_materno)s, nacionalidad = %(nacionalidad)s,
                   estado_civil = %(estado_civil)s, ocupacion = %(ocupacion)s
            WHERE  id_persona = %(id)s
            RETURNING id_persona
            """,
            valores,
        ).fetchone()
        exigir(fila, "Persona natural", id_persona)
        cur.execute(
            """
            UPDATE persona
            SET    direccion = %(direccion)s, telefono = %(telefono)s,
                   telefono_2 = %(telefono_2)s, correo = %(correo)s
            WHERE  id_persona = %(id)s
            """,
            valores,
        )
    return ver_natural(id_persona)


@router.delete("/personas-naturales/{id_persona}", tags=[T_PERS], summary="Eliminar persona natural")
def eliminar_natural(id_persona: int):
    fila = consultar_uno(
        "DELETE FROM persona WHERE id_persona = %s AND tipo_persona = 'N' RETURNING id_persona",
        (id_persona,),
    )
    return {"eliminado": exigir(fila, "Persona natural", id_persona)}


# =============================================================================
# PERSONA_JURIDICA  (cada alta inserta en persona y persona_juridica)
# =============================================================================
_SQL_JURIDICA = """
    SELECT p.id_persona, pj.ruc, pj.razon_social, pj.id_representante,
           rep.nombres || ' ' || rep.apellido_paterno AS representante,
           p.direccion, p.telefono, p.telefono_2, p.correo
    FROM   persona p
    JOIN   persona_juridica pj ON pj.id_persona = p.id_persona
    JOIN   persona_natural rep ON rep.id_persona = pj.id_representante
"""


@router.get("/personas-juridicas", tags=[T_PERS], summary="Listar personas jurídicas")
def listar_juridicas():
    return consultar(_SQL_JURIDICA + " ORDER BY p.id_persona")


@router.get("/personas-juridicas/{id_persona}", tags=[T_PERS], summary="Ver una persona jurídica")
def ver_juridica(id_persona: int):
    fila = consultar_uno(_SQL_JURIDICA + " WHERE p.id_persona = %s", (id_persona,))
    return exigir(fila, "Persona jurídica", id_persona)


@router.post("/personas-juridicas", tags=[T_PERS], status_code=201,
             summary="Crear persona jurídica (persona + persona_juridica en una transacción)")
def crear_juridica(datos: PersonaJuridicaIn):
    with transaccion() as cur:
        id_persona = cur.execute(
            """
            INSERT INTO persona (tipo_persona, direccion, telefono, telefono_2, correo)
            VALUES ('J', %(direccion)s, %(telefono)s, %(telefono_2)s, %(correo)s)
            RETURNING id_persona
            """,
            datos.model_dump(),
        ).fetchone()["id_persona"]
        cur.execute(
            """
            INSERT INTO persona_juridica (id_persona, id_representante, ruc, razon_social)
            VALUES (%(id)s, %(id_representante)s, %(ruc)s, %(razon_social)s)
            """,
            {**datos.model_dump(), "id": id_persona},
        )
    return ver_juridica(id_persona)


@router.put("/personas-juridicas/{id_persona}", tags=[T_PERS], summary="Actualizar persona jurídica")
def actualizar_juridica(id_persona: int, datos: PersonaJuridicaIn):
    valores = {**datos.model_dump(), "id": id_persona}
    with transaccion() as cur:
        fila = cur.execute(
            """
            UPDATE persona_juridica
            SET    id_representante = %(id_representante)s, ruc = %(ruc)s,
                   razon_social = %(razon_social)s
            WHERE  id_persona = %(id)s
            RETURNING id_persona
            """,
            valores,
        ).fetchone()
        exigir(fila, "Persona jurídica", id_persona)
        cur.execute(
            """
            UPDATE persona
            SET    direccion = %(direccion)s, telefono = %(telefono)s,
                   telefono_2 = %(telefono_2)s, correo = %(correo)s
            WHERE  id_persona = %(id)s
            """,
            valores,
        )
    return ver_juridica(id_persona)


@router.delete("/personas-juridicas/{id_persona}", tags=[T_PERS], summary="Eliminar persona jurídica")
def eliminar_juridica(id_persona: int):
    fila = consultar_uno(
        "DELETE FROM persona WHERE id_persona = %s AND tipo_persona = 'J' RETURNING id_persona",
        (id_persona,),
    )
    return {"eliminado": exigir(fila, "Persona jurídica", id_persona)}


# =============================================================================
# ASESOR
# =============================================================================
_SQL_ASESOR = f"""
    SELECT a.id_asesor, a.id_persona, {NOMBRE_PERSONA} AS nombre, a.fecha_alta, a.estado,
           (SELECT COUNT(*) FROM venta v
            WHERE v.id_asesor = a.id_asesor AND v.estado_venta <> 'ANULADA') AS ventas
    FROM   asesor a
    JOIN   persona p ON p.id_persona = a.id_persona
    LEFT JOIN persona_natural  pn ON pn.id_persona = p.id_persona
    LEFT JOIN persona_juridica pj ON pj.id_persona = p.id_persona
"""


@router.get("/asesores", tags=[T_ASES], summary="Listar asesores")
def listar_asesores(estado: str | None = None):
    return consultar(
        _SQL_ASESOR + " WHERE (%(estado)s::varchar IS NULL OR a.estado = %(estado)s) ORDER BY a.id_asesor",
        {"estado": estado},
    )


@router.get("/asesores/{id_asesor}", tags=[T_ASES], summary="Ver un asesor")
def ver_asesor(id_asesor: int):
    return exigir(consultar_uno(_SQL_ASESOR + " WHERE a.id_asesor = %s", (id_asesor,)),
                  "Asesor", id_asesor)


@router.post("/asesores", tags=[T_ASES], status_code=201, summary="Registrar un asesor")
def crear_asesor(datos: AsesorIn):
    return consultar_uno(
        """
        INSERT INTO asesor (id_persona, fecha_alta, estado)
        VALUES (%(id_persona)s, %(fecha_alta)s, %(estado)s)
        RETURNING *
        """,
        datos.model_dump(),
    )


@router.put("/asesores/{id_asesor}", tags=[T_ASES], summary="Actualizar un asesor")
def actualizar_asesor(id_asesor: int, datos: AsesorIn):
    fila = consultar_uno(
        """
        UPDATE asesor
        SET    id_persona = %(id_persona)s, fecha_alta = %(fecha_alta)s, estado = %(estado)s
        WHERE  id_asesor = %(id)s
        RETURNING *
        """,
        {**datos.model_dump(), "id": id_asesor},
    )
    return exigir(fila, "Asesor", id_asesor)


@router.delete("/asesores/{id_asesor}", tags=[T_ASES],
               summary="Eliminar un asesor (sus ventas y separaciones quedan sin asesor: SET NULL)")
def eliminar_asesor(id_asesor: int):
    fila = consultar_uno("DELETE FROM asesor WHERE id_asesor = %s RETURNING *", (id_asesor,))
    return {"eliminado": exigir(fila, "Asesor", id_asesor)}


# =============================================================================
# SEPARACION
# =============================================================================
@router.get("/separaciones", tags=[T_SEPA], summary="Listar separaciones")
def listar_separaciones(estado: str | None = None, id_lote: int | None = None):
    return consultar(
        f"""
        SELECT s.*, {NOMBRE_PERSONA} AS cliente, m.codigo || '-' || l.numero AS lote
        FROM   separacion s
        JOIN   persona p ON p.id_persona = s.id_persona
        LEFT JOIN persona_natural  pn ON pn.id_persona = p.id_persona
        LEFT JOIN persona_juridica pj ON pj.id_persona = p.id_persona
        JOIN   lote l    ON l.id_lote = s.id_lote
        JOIN   manzana m ON m.id_manzana = l.id_manzana
        WHERE  (%(estado)s::varchar IS NULL OR s.estado = %(estado)s)
          AND  (%(id_lote)s::int IS NULL OR s.id_lote = %(id_lote)s)
        ORDER  BY s.fecha_hora DESC
        """,
        {"estado": estado, "id_lote": id_lote},
    )


@router.get("/separaciones/{id_separacion}", tags=[T_SEPA], summary="Ver una separación")
def ver_separacion(id_separacion: int):
    fila = consultar_uno("SELECT * FROM separacion WHERE id_separacion = %s", (id_separacion,))
    return exigir(fila, "Separación", id_separacion)


@router.post("/separaciones", tags=[T_SEPA], status_code=201, summary="Crear una separación (CRUD)")
def crear_separacion(datos: SeparacionIn):
    return consultar_uno(
        """
        INSERT INTO separacion (id_lote, id_persona, id_asesor, fecha_hora, monto,
                                fecha_vencimiento, estado, destino_monto)
        VALUES (%(id_lote)s, %(id_persona)s, %(id_asesor)s, %(fecha_hora)s, %(monto)s,
                %(fecha_vencimiento)s, %(estado)s, %(destino_monto)s)
        RETURNING *
        """,
        datos.model_dump(),
    )


@router.put("/separaciones/{id_separacion}", tags=[T_SEPA], summary="Actualizar una separación")
def actualizar_separacion(id_separacion: int, datos: SeparacionIn):
    fila = consultar_uno(
        """
        UPDATE separacion
        SET    id_lote = %(id_lote)s, id_persona = %(id_persona)s, id_asesor = %(id_asesor)s,
               fecha_hora = %(fecha_hora)s, monto = %(monto)s,
               fecha_vencimiento = %(fecha_vencimiento)s, estado = %(estado)s,
               destino_monto = %(destino_monto)s
        WHERE  id_separacion = %(id)s
        RETURNING *
        """,
        {**datos.model_dump(), "id": id_separacion},
    )
    return exigir(fila, "Separación", id_separacion)


@router.delete("/separaciones/{id_separacion}", tags=[T_SEPA], summary="Eliminar una separación")
def eliminar_separacion(id_separacion: int):
    fila = consultar_uno("DELETE FROM separacion WHERE id_separacion = %s RETURNING *", (id_separacion,))
    return {"eliminado": exigir(fila, "Separación", id_separacion)}


# -----------------------------------------------------------------------------
# Proceso: separar un lote (separación + estado del lote)
# -----------------------------------------------------------------------------
@router.post("/separaciones/registrar", tags=[T_SEPA], status_code=201,
             summary="Separar un lote: crea la separación y marca el lote como SEPARADO")
def registrar_separacion(datos: Annotated[SeparacionNuevaIn, Body(openapi_examples=EJEMPLO_SEPARACION)]):
    """El pago de la separación se registra después con POST /pagos/registrar (módulo 3)."""
    with transaccion() as cur:
        lote = cur.execute(
            "SELECT id_lote, tipo_lote, estado_lote FROM lote WHERE id_lote = %s FOR UPDATE",
            (datos.id_lote,),
        ).fetchone()
        exigir(lote, "Lote", datos.id_lote)
        if lote["estado_lote"] != "DISPONIBLE":
            raise HTTPException(409, f"El lote {datos.id_lote} no está disponible "
                                     f"(estado actual: {lote['estado_lote']})")

        separacion = cur.execute(
            """
            INSERT INTO separacion (id_lote, id_persona, id_asesor, fecha_hora, monto,
                                    fecha_vencimiento, estado)
            VALUES (%s, %s, %s, now(), %s, %s, 'VIGENTE')
            RETURNING *
            """,
            (datos.id_lote, datos.id_persona, datos.id_asesor, datos.monto,
             date.today() + timedelta(days=datos.dias_vigencia)),
        ).fetchone()

        cur.execute("UPDATE lote SET estado_lote = 'SEPARADO' WHERE id_lote = %s", (datos.id_lote,))

    return {"separacion": separacion, "estado_lote": "SEPARADO"}


# =============================================================================
# VENTA
# =============================================================================
_SQL_VENTAS = f"""
    SELECT v.*, (v.precio_lista - v.descuento) AS precio_final,
           pr.nombre AS proyecto, m.codigo || '-' || l.numero AS lote,
           o.nombre AS oficina,
           (SELECT {NOMBRE_PERSONA}
            FROM   venta_participante vp
            JOIN   persona p ON p.id_persona = vp.id_persona
            LEFT JOIN persona_natural  pn ON pn.id_persona = p.id_persona
            LEFT JOIN persona_juridica pj ON pj.id_persona = p.id_persona
            WHERE  vp.id_venta = v.id_venta AND vp.rol = 'TITULAR') AS titular
    FROM   venta v
    JOIN   lote l      ON l.id_lote = v.id_lote
    JOIN   manzana m   ON m.id_manzana = l.id_manzana
    JOIN   sector s    ON s.id_sector = m.id_sector
    JOIN   proyecto pr ON pr.id_proyecto = s.id_proyecto
    JOIN   oficina o   ON o.codigo_oficina = v.codigo_oficina
"""


@router.get("/ventas", tags=[T_VENT], summary="Listar ventas con proyecto, lote, oficina y titular")
def listar_ventas(estado: str | None = None, modalidad: str | None = None,
                  id_asesor: int | None = None, id_proyecto: int | None = None,
                  limite: int = Query(100, ge=1, le=1000), desplazamiento: int = Query(0, ge=0)):
    return consultar(
        _SQL_VENTAS + """
        WHERE  (%(estado)s::varchar    IS NULL OR v.estado_venta = %(estado)s)
          AND  (%(modalidad)s::varchar IS NULL OR v.modalidad    = %(modalidad)s)
          AND  (%(id_asesor)s::int     IS NULL OR v.id_asesor    = %(id_asesor)s)
          AND  (%(id_proyecto)s::int   IS NULL OR pr.id_proyecto = %(id_proyecto)s)
        ORDER  BY v.fecha_venta DESC, v.id_venta DESC
        LIMIT  %(limite)s OFFSET %(desplazamiento)s
        """,
        {"estado": estado, "modalidad": modalidad, "id_asesor": id_asesor,
         "id_proyecto": id_proyecto, "limite": limite, "desplazamiento": desplazamiento},
    )


@router.get("/ventas/{id_venta}", tags=[T_VENT], summary="Ver una venta con sus participantes")
def ver_venta(id_venta: int):
    venta = exigir(consultar_uno(_SQL_VENTAS + " WHERE v.id_venta = %s", (id_venta,)),
                   "Venta", id_venta)
    venta["participantes"] = consultar(
        f"""
        SELECT vp.id_persona, vp.rol, {NOMBRE_PERSONA} AS nombre
        FROM   venta_participante vp
        JOIN   persona p ON p.id_persona = vp.id_persona
        LEFT JOIN persona_natural  pn ON pn.id_persona = p.id_persona
        LEFT JOIN persona_juridica pj ON pj.id_persona = p.id_persona
        WHERE  vp.id_venta = %s
        ORDER  BY vp.rol DESC
        """,
        (id_venta,),
    )
    return venta


_COLUMNAS_VENTA = """
    id_lote = %(id_lote)s, id_separacion = %(id_separacion)s, id_asesor = %(id_asesor)s,
    codigo_oficina = %(codigo_oficina)s, fecha_venta = %(fecha_venta)s, modalidad = %(modalidad)s,
    precio_lista = %(precio_lista)s, descuento = %(descuento)s, inicial = %(inicial)s,
    plazo_meses = %(plazo_meses)s, dia_pago = %(dia_pago)s,
    fecha_primera_cuota = %(fecha_primera_cuota)s, estado_venta = %(estado_venta)s,
    motivo_excepcion = %(motivo_excepcion)s
"""


@router.post("/ventas", tags=[T_VENT], status_code=201,
             summary="Crear una venta con su titular (CRUD simple; el proceso completo es /ventas/registrar)")
def crear_venta(datos: VentaCrearIn):
    """Inserta la venta tal cual llega, sin tocar el lote ni generar cuotas.
    Toda venta necesita un TITULAR al terminar la transacción (trigger diferido),
    por eso la venta y su titular se insertan juntos."""
    with transaccion() as cur:
        venta = cur.execute(
            """
            INSERT INTO venta (id_lote, id_separacion, id_asesor, codigo_oficina, fecha_venta,
                               modalidad, precio_lista, descuento, inicial, plazo_meses, dia_pago,
                               fecha_primera_cuota, estado_venta, motivo_excepcion)
            VALUES (%(id_lote)s, %(id_separacion)s, %(id_asesor)s, %(codigo_oficina)s, %(fecha_venta)s,
                    %(modalidad)s, %(precio_lista)s, %(descuento)s, %(inicial)s, %(plazo_meses)s,
                    %(dia_pago)s, %(fecha_primera_cuota)s, %(estado_venta)s, %(motivo_excepcion)s)
            RETURNING *
            """,
            datos.model_dump(),
        ).fetchone()
        cur.execute(
            "INSERT INTO venta_participante (id_venta, id_persona, rol) VALUES (%s, %s, 'TITULAR')",
            (venta["id_venta"], datos.id_titular),
        )
    return venta


@router.put("/ventas/{id_venta}", tags=[T_VENT], summary="Actualizar una venta")
def actualizar_venta(id_venta: int, datos: VentaIn):
    fila = consultar_uno(
        f"UPDATE venta SET {_COLUMNAS_VENTA} WHERE id_venta = %(id)s RETURNING *",
        {**datos.model_dump(), "id": id_venta},
    )
    return exigir(fila, "Venta", id_venta)


@router.delete("/ventas/{id_venta}", tags=[T_VENT],
               summary="Eliminar una venta (borra participantes y cuotas; se bloquea si tiene pagos)")
def eliminar_venta(id_venta: int):
    fila = consultar_uno(
        "DELETE FROM venta WHERE id_venta = %s RETURNING id_venta, id_lote, estado_venta", (id_venta,)
    )
    return {"eliminado": exigir(fila, "Venta", id_venta)}


# -----------------------------------------------------------------------------
# Proceso: registrar una venta completa (5 tablas + función del módulo 3)
# -----------------------------------------------------------------------------
@router.post("/ventas/registrar", tags=[T_VENT], status_code=201,
             summary="Registrar venta: venta + participantes + separación + lote + cronograma")
def registrar_venta(datos: Annotated[VentaNuevaIn, Body(openapi_examples=EJEMPLO_VENTA)]):
    """Pasos, todos dentro de una sola transacción:
    1. Bloquea el lote (FOR UPDATE) y toma su precio vigente.
    2. Si viene de una separación, la valida y la marca CONVERTIDA.
    3. Inserta la venta y sus participantes (debe haber exactamente un TITULAR).
    4. Cambia el estado del lote: EN_CUOTAS, o RESERVADO si es al contado
       (pasa a CANCELADO cuando se registra el pago en el módulo 3).
    5. Si es en cuotas, genera el cronograma con fn_generar_cronograma.
    """
    with transaccion() as cur:
        # 1. Lote y precio vigente. FOR UPDATE evita que dos ventas tomen el mismo lote a la vez.
        lote = cur.execute(
            """
            SELECT l.id_lote, l.tipo_lote, l.estado_lote, pl.precio
            FROM   lote l
            LEFT JOIN precio_lote pl ON pl.id_lote = l.id_lote AND pl.fecha_fin IS NULL
            WHERE  l.id_lote = %s
            FOR UPDATE OF l
            """,
            (datos.id_lote,),
        ).fetchone()
        exigir(lote, "Lote", datos.id_lote)
        if lote["tipo_lote"] != "VENDIBLE":
            raise HTTPException(422, f"El lote {datos.id_lote} es {lote['tipo_lote']} y no se vende")
        if lote["precio"] is None:
            raise HTTPException(422, f"El lote {datos.id_lote} no tiene precio vigente")

        # 2. Separación previa (opcional).
        if datos.id_separacion is not None:
            sep = cur.execute(
                "SELECT id_lote, estado FROM separacion WHERE id_separacion = %s FOR UPDATE",
                (datos.id_separacion,),
            ).fetchone()
            exigir(sep, "Separación", datos.id_separacion)
            if sep["id_lote"] != datos.id_lote or sep["estado"] != "VIGENTE":
                raise HTTPException(422, "La separación no está vigente o es de otro lote")
        elif lote["estado_lote"] != "DISPONIBLE":
            raise HTTPException(409, f"El lote {datos.id_lote} no está disponible "
                                     f"(estado actual: {lote['estado_lote']})")

        # 3. Venta y participantes. Al contado, la inicial es el precio completo.
        inicial = (lote["precio"] - datos.descuento) if datos.modalidad == "CONTADO" else datos.inicial
        venta = cur.execute(
            """
            INSERT INTO venta (id_lote, id_separacion, id_asesor, codigo_oficina, fecha_venta,
                               modalidad, precio_lista, descuento, inicial, plazo_meses, dia_pago,
                               fecha_primera_cuota, estado_venta, motivo_excepcion)
            VALUES (%(id_lote)s, %(id_separacion)s, %(id_asesor)s, %(codigo_oficina)s,
                    %(fecha_venta)s, %(modalidad)s, %(precio)s, %(descuento)s, %(inicial)s,
                    %(plazo_meses)s, %(dia_pago)s, %(fecha_primera_cuota)s, 'ACTIVA',
                    %(motivo_excepcion)s)
            RETURNING *
            """,
            {**datos.model_dump(exclude={"participantes", "inicial"}),
             "precio": lote["precio"], "inicial": inicial},
        ).fetchone()

        for p in datos.participantes:
            cur.execute(
                "INSERT INTO venta_participante (id_venta, id_persona, rol) VALUES (%s, %s, %s)",
                (venta["id_venta"], p.id_persona, p.rol),
            )

        if datos.id_separacion is not None:
            cur.execute(
                """
                UPDATE separacion SET estado = 'CONVERTIDA', destino_monto = %s
                WHERE  id_separacion = %s
                """,
                (datos.destino_separacion, datos.id_separacion),
            )

        # 4. Estado del lote.
        nuevo_estado = "EN_CUOTAS" if datos.modalidad == "CUOTAS" else "RESERVADO"
        cur.execute("UPDATE lote SET estado_lote = %s WHERE id_lote = %s",
                    (nuevo_estado, datos.id_lote))

        # 5. Cronograma (función del módulo 3).
        cuotas = []
        if datos.modalidad == "CUOTAS":
            cur.execute("SELECT fn_generar_cronograma(%s)", (venta["id_venta"],))
            cuotas = cur.execute(
                """
                SELECT nro_cuota, fecha_vencimiento, monto, estado_cuota
                FROM   cuota WHERE id_venta = %s ORDER BY nro_cuota
                """,
                (venta["id_venta"],),
            ).fetchall()
        # Al hacer COMMIT, el trigger diferido revisa que haya exactamente un TITULAR.

    return {"venta": venta, "estado_lote": nuevo_estado,
            "participantes": [p.model_dump() for p in datos.participantes], "cuotas": cuotas}


# -----------------------------------------------------------------------------
# Proceso: anular una venta sin pagos (venta + cuotas + lote)
# -----------------------------------------------------------------------------
@router.put("/ventas/{id_venta}/anular", tags=[T_VENT],
            summary="Anular una venta sin pagos: venta ANULADA, se borra el cronograma y el lote se libera")
def anular_venta(id_venta: int):
    with transaccion() as cur:
        venta = cur.execute(
            "SELECT id_venta, id_lote, estado_venta FROM venta WHERE id_venta = %s FOR UPDATE",
            (id_venta,),
        ).fetchone()
        exigir(venta, "Venta", id_venta)
        if venta["estado_venta"] != "ACTIVA":
            raise HTTPException(422, f"Solo se anulan ventas ACTIVAS (estado: {venta['estado_venta']})")
        pagos = cur.execute(
            "SELECT COUNT(*) AS n FROM pago WHERE id_venta = %s AND estado_recibo = 'EMITIDO'",
            (id_venta,),
        ).fetchone()["n"]
        if pagos:
            raise HTTPException(409, f"La venta tiene {pagos} pago(s) emitido(s); primero anúlelos")

        cur.execute("UPDATE venta SET estado_venta = 'ANULADA' WHERE id_venta = %s", (id_venta,))
        cuotas = cur.execute("DELETE FROM cuota WHERE id_venta = %s", (id_venta,)).rowcount
        cur.execute("UPDATE lote SET estado_lote = 'DISPONIBLE' WHERE id_lote = %s", (venta["id_lote"],))

    return {"id_venta": id_venta, "estado_venta": "ANULADA", "cuotas_eliminadas": cuotas,
            "lote_liberado": venta["id_lote"]}


# =============================================================================
# VENTA_PARTICIPANTE  (clave compuesta: id_venta + id_persona)
# =============================================================================
@router.get("/venta-participantes", tags=[T_PART], summary="Listar participantes de ventas")
def listar_participantes(id_venta: int | None = None):
    return consultar(
        f"""
        SELECT vp.id_venta, vp.id_persona, vp.rol, {NOMBRE_PERSONA} AS nombre
        FROM   venta_participante vp
        JOIN   persona p ON p.id_persona = vp.id_persona
        LEFT JOIN persona_natural  pn ON pn.id_persona = p.id_persona
        LEFT JOIN persona_juridica pj ON pj.id_persona = p.id_persona
        WHERE  (%(id_venta)s::int IS NULL OR vp.id_venta = %(id_venta)s)
        ORDER  BY vp.id_venta, vp.rol DESC
        """,
        {"id_venta": id_venta},
    )


@router.get("/venta-participantes/{id_venta}/{id_persona}", tags=[T_PART], summary="Ver un participante")
def ver_participante(id_venta: int, id_persona: int):
    fila = consultar_uno(
        "SELECT * FROM venta_participante WHERE id_venta = %s AND id_persona = %s",
        (id_venta, id_persona),
    )
    return exigir(fila, "Participante", f"{id_venta}/{id_persona}")


@router.post("/venta-participantes", tags=[T_PART], status_code=201,
             summary="Agregar un participante a una venta")
def crear_participante(datos: VentaParticipanteIn):
    return consultar_uno(
        """
        INSERT INTO venta_participante (id_venta, id_persona, rol)
        VALUES (%(id_venta)s, %(id_persona)s, %(rol)s)
        RETURNING *
        """,
        datos.model_dump(),
    )


@router.put("/venta-participantes/{id_venta}/{id_persona}", tags=[T_PART],
            summary="Cambiar el rol de un participante")
def actualizar_participante(id_venta: int, id_persona: int, datos: RolIn):
    fila = consultar_uno(
        """
        UPDATE venta_participante SET rol = %s
        WHERE  id_venta = %s AND id_persona = %s
        RETURNING *
        """,
        (datos.rol, id_venta, id_persona),
    )
    return exigir(fila, "Participante", f"{id_venta}/{id_persona}")


@router.delete("/venta-participantes/{id_venta}/{id_persona}", tags=[T_PART],
               summary="Quitar un participante (no se puede quitar al único titular)")
def eliminar_participante(id_venta: int, id_persona: int):
    fila = consultar_uno(
        "DELETE FROM venta_participante WHERE id_venta = %s AND id_persona = %s RETURNING *",
        (id_venta, id_persona),
    )
    return {"eliminado": exigir(fila, "Participante", f"{id_venta}/{id_persona}")}
