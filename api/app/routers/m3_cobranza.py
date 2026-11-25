"""Módulo 3: Cobranza y Comisiones.

Responsable: Mijael Pol Escobar
CRUD de oficina, cuenta_bancaria, cuota, pago, pago_cuota, comision y
pago_comision, más los procesos que tocan varias tablas:
  * POST /pagos/registrar         -> oficina (recibo) + pago + pago_cuota + cuota
                                     + venta + lote + separación
  * PUT  /pagos/{id}/anular       -> pago + cuota + venta + lote
  * GET  /estado-cuenta/{id_venta}-> cronograma con lo pagado y el saldo de cada cuota
"""
from decimal import Decimal

from typing import Annotated

from fastapi import APIRouter, Body, HTTPException, Query

from app.db import conectar, consultar, consultar_uno, exigir, transaccion
from app.schemas.m3 import (EJEMPLO_PAGO, ComisionIn, CuentaBancariaIn, CuotaActualizarIn, CuotaIn,
                            MontoAplicadoIn, OficinaIn, PagoComisionIn, PagoCuotaIn, PagoIn,
                            PagoNuevoIn)

router = APIRouter()

T_OFIC = "M3 · Oficinas"
T_CUEN = "M3 · Cuentas bancarias"
T_CUOT = "M3 · Cuotas"
T_PAGO = "M3 · Pagos"
T_PCUO = "M3 · Pagos aplicados a cuotas"
T_COMI = "M3 · Comisiones"
T_PCOM = "M3 · Pagos de comisión"

# Saldo de cada cuota de una venta: monto menos lo aplicado con recibos EMITIDOS.
SQL_SALDO_CUOTAS = """
    SELECT c.nro_cuota, c.fecha_vencimiento, c.monto, c.estado_cuota,
           COALESCE(SUM(pc.monto_aplicado) FILTER (WHERE p.estado_recibo = 'EMITIDO'), 0) AS pagado,
           c.monto - COALESCE(SUM(pc.monto_aplicado) FILTER (WHERE p.estado_recibo = 'EMITIDO'), 0)
               AS saldo
    FROM   cuota c
    LEFT JOIN pago_cuota pc ON pc.id_venta = c.id_venta AND pc.nro_cuota = c.nro_cuota
    LEFT JOIN pago p        ON p.id_pago = pc.id_pago
    WHERE  c.id_venta = %s
    GROUP  BY c.nro_cuota, c.fecha_vencimiento, c.monto, c.estado_cuota
    ORDER  BY c.nro_cuota
"""


# =============================================================================
# OFICINA
# =============================================================================
@router.get("/oficinas", tags=[T_OFIC], summary="Listar oficinas")
def listar_oficinas():
    return consultar("SELECT * FROM oficina ORDER BY es_central DESC, codigo_oficina")


@router.get("/oficinas/{codigo_oficina}", tags=[T_OFIC], summary="Ver una oficina")
def ver_oficina(codigo_oficina: str):
    fila = consultar_uno("SELECT * FROM oficina WHERE codigo_oficina = %s", (codigo_oficina,))
    return exigir(fila, "Oficina", codigo_oficina)


@router.post("/oficinas", tags=[T_OFIC], status_code=201, summary="Crear una oficina")
def crear_oficina(datos: OficinaIn):
    return consultar_uno(
        """
        INSERT INTO oficina (codigo_oficina, nombre, distrito, direccion, es_central, ultimo_nro_recibo)
        VALUES (%(codigo_oficina)s, %(nombre)s, %(distrito)s, %(direccion)s, %(es_central)s,
                %(ultimo_nro_recibo)s)
        RETURNING *
        """,
        datos.model_dump(),
    )


@router.put("/oficinas/{codigo_oficina}", tags=[T_OFIC],
            summary="Actualizar una oficina (si cambia el código, se propaga: ON UPDATE CASCADE)")
def actualizar_oficina(codigo_oficina: str, datos: OficinaIn):
    fila = consultar_uno(
        """
        UPDATE oficina
        SET    codigo_oficina = %(codigo_oficina)s, nombre = %(nombre)s, distrito = %(distrito)s,
               direccion = %(direccion)s, es_central = %(es_central)s,
               ultimo_nro_recibo = %(ultimo_nro_recibo)s
        WHERE  codigo_oficina = %(codigo_actual)s
        RETURNING *
        """,
        {**datos.model_dump(), "codigo_actual": codigo_oficina},
    )
    return exigir(fila, "Oficina", codigo_oficina)


@router.delete("/oficinas/{codigo_oficina}", tags=[T_OFIC],
               summary="Eliminar una oficina (se bloquea si tiene ventas, pagos o empleados)")
def eliminar_oficina(codigo_oficina: str):
    fila = consultar_uno("DELETE FROM oficina WHERE codigo_oficina = %s RETURNING *", (codigo_oficina,))
    return {"eliminado": exigir(fila, "Oficina", codigo_oficina)}


# =============================================================================
# CUENTA_BANCARIA
# =============================================================================
@router.get("/cuentas-bancarias", tags=[T_CUEN], summary="Listar cuentas bancarias")
def listar_cuentas(estado: str | None = None):
    return consultar(
        """
        SELECT c.*,
               (SELECT COALESCE(SUM(p.monto), 0) FROM pago p
                WHERE  p.id_cuenta = c.id_cuenta AND p.estado_recibo = 'EMITIDO') AS total_recibido
        FROM   cuenta_bancaria c
        WHERE  (%(estado)s::varchar IS NULL OR c.estado = %(estado)s)
        ORDER  BY c.id_cuenta
        """,
        {"estado": estado},
    )


@router.get("/cuentas-bancarias/{id_cuenta}", tags=[T_CUEN], summary="Ver una cuenta bancaria")
def ver_cuenta(id_cuenta: int):
    fila = consultar_uno("SELECT * FROM cuenta_bancaria WHERE id_cuenta = %s", (id_cuenta,))
    return exigir(fila, "Cuenta", id_cuenta)


@router.post("/cuentas-bancarias", tags=[T_CUEN], status_code=201, summary="Crear una cuenta bancaria")
def crear_cuenta(datos: CuentaBancariaIn):
    return consultar_uno(
        """
        INSERT INTO cuenta_bancaria (banco, nro_cuenta, cci, moneda, estado)
        VALUES (%(banco)s, %(nro_cuenta)s, %(cci)s, %(moneda)s, %(estado)s)
        RETURNING *
        """,
        datos.model_dump(),
    )


@router.put("/cuentas-bancarias/{id_cuenta}", tags=[T_CUEN], summary="Actualizar una cuenta bancaria")
def actualizar_cuenta(id_cuenta: int, datos: CuentaBancariaIn):
    fila = consultar_uno(
        """
        UPDATE cuenta_bancaria
        SET    banco = %(banco)s, nro_cuenta = %(nro_cuenta)s, cci = %(cci)s,
               moneda = %(moneda)s, estado = %(estado)s
        WHERE  id_cuenta = %(id)s
        RETURNING *
        """,
        {**datos.model_dump(), "id": id_cuenta},
    )
    return exigir(fila, "Cuenta", id_cuenta)


@router.delete("/cuentas-bancarias/{id_cuenta}", tags=[T_CUEN],
               summary="Eliminar una cuenta (se bloquea si recibió pagos)")
def eliminar_cuenta(id_cuenta: int):
    fila = consultar_uno("DELETE FROM cuenta_bancaria WHERE id_cuenta = %s RETURNING *", (id_cuenta,))
    return {"eliminado": exigir(fila, "Cuenta", id_cuenta)}


# =============================================================================
# CUOTA  (clave compuesta: id_venta + nro_cuota)
# =============================================================================
@router.get("/cuotas", tags=[T_CUOT], summary="Listar cuotas")
def listar_cuotas(id_venta: int | None = None, estado: str | None = None,
                  limite: int = Query(200, ge=1, le=2000), desplazamiento: int = Query(0, ge=0)):
    return consultar(
        """
        SELECT * FROM cuota
        WHERE  (%(id_venta)s::int    IS NULL OR id_venta = %(id_venta)s)
          AND  (%(estado)s::varchar  IS NULL OR estado_cuota = %(estado)s)
        ORDER  BY id_venta, nro_cuota
        LIMIT  %(limite)s OFFSET %(desplazamiento)s
        """,
        {"id_venta": id_venta, "estado": estado, "limite": limite, "desplazamiento": desplazamiento},
    )


@router.get("/cuotas/{id_venta}/{nro_cuota}", tags=[T_CUOT], summary="Ver una cuota")
def ver_cuota(id_venta: int, nro_cuota: int):
    fila = consultar_uno("SELECT * FROM cuota WHERE id_venta = %s AND nro_cuota = %s",
                         (id_venta, nro_cuota))
    return exigir(fila, "Cuota", f"{id_venta}/{nro_cuota}")


@router.post("/cuotas", tags=[T_CUOT], status_code=201, summary="Crear una cuota")
def crear_cuota(datos: CuotaIn):
    return consultar_uno(
        """
        INSERT INTO cuota (id_venta, nro_cuota, fecha_vencimiento, monto, estado_cuota)
        VALUES (%(id_venta)s, %(nro_cuota)s, %(fecha_vencimiento)s, %(monto)s, %(estado_cuota)s)
        RETURNING *
        """,
        datos.model_dump(),
    )


@router.post("/cuotas/generar/{id_venta}", tags=[T_CUOT], status_code=201,
             summary="Generar el cronograma de una venta en cuotas (fn_generar_cronograma)")
def generar_cronograma(id_venta: int):
    consultar_uno("SELECT fn_generar_cronograma(%s) AS cuotas", (id_venta,))
    return consultar("SELECT * FROM cuota WHERE id_venta = %s ORDER BY nro_cuota", (id_venta,))


@router.put("/cuotas/{id_venta}/{nro_cuota}", tags=[T_CUOT], summary="Actualizar una cuota")
def actualizar_cuota(id_venta: int, nro_cuota: int, datos: CuotaActualizarIn):
    fila = consultar_uno(
        """
        UPDATE cuota
        SET    fecha_vencimiento = %(fecha_vencimiento)s, monto = %(monto)s,
               estado_cuota = %(estado_cuota)s
        WHERE  id_venta = %(id_venta)s AND nro_cuota = %(nro_cuota)s
        RETURNING *
        """,
        {**datos.model_dump(), "id_venta": id_venta, "nro_cuota": nro_cuota},
    )
    return exigir(fila, "Cuota", f"{id_venta}/{nro_cuota}")


@router.delete("/cuotas/{id_venta}/{nro_cuota}", tags=[T_CUOT],
               summary="Eliminar una cuota (se bloquea si ya tiene pagos aplicados)")
def eliminar_cuota(id_venta: int, nro_cuota: int):
    fila = consultar_uno(
        "DELETE FROM cuota WHERE id_venta = %s AND nro_cuota = %s RETURNING *", (id_venta, nro_cuota)
    )
    return {"eliminado": exigir(fila, "Cuota", f"{id_venta}/{nro_cuota}")}


@router.get("/estado-cuenta/{id_venta}", tags=[T_CUOT],
            summary="Estado de cuenta de una venta: cada cuota con lo pagado y su saldo")
def estado_cuenta(id_venta: int):
    venta = exigir(consultar_uno(
        """
        SELECT id_venta, modalidad, estado_venta, precio_lista, descuento, inicial,
               precio_lista - descuento AS precio_final
        FROM   venta WHERE id_venta = %s
        """,
        (id_venta,),
    ), "Venta", id_venta)
    cuotas = consultar(SQL_SALDO_CUOTAS, (id_venta,))
    venta["total_cuotas"] = sum((c["monto"] for c in cuotas), Decimal("0"))
    venta["total_pagado_cuotas"] = sum((c["pagado"] for c in cuotas), Decimal("0"))
    venta["saldo_pendiente"] = venta["total_cuotas"] - venta["total_pagado_cuotas"]
    venta["cuotas"] = cuotas
    return venta


# =============================================================================
# PAGO
# =============================================================================
@router.get("/pagos", tags=[T_PAGO], summary="Listar pagos (recibos)")
def listar_pagos(codigo_oficina: str | None = None, id_venta: int | None = None,
                 concepto: str | None = None, estado: str | None = None,
                 limite: int = Query(100, ge=1, le=1000), desplazamiento: int = Query(0, ge=0)):
    return consultar(
        """
        SELECT p.*, o.nombre AS oficina, cb.banco
        FROM   pago p
        JOIN   oficina o ON o.codigo_oficina = p.codigo_oficina
        LEFT JOIN cuenta_bancaria cb ON cb.id_cuenta = p.id_cuenta
        WHERE  (%(oficina)s::varchar  IS NULL OR p.codigo_oficina = %(oficina)s)
          AND  (%(id_venta)s::int     IS NULL OR p.id_venta = %(id_venta)s)
          AND  (%(concepto)s::varchar IS NULL OR p.concepto = %(concepto)s)
          AND  (%(estado)s::varchar   IS NULL OR p.estado_recibo = %(estado)s)
        ORDER  BY p.fecha_hora DESC
        LIMIT  %(limite)s OFFSET %(desplazamiento)s
        """,
        {"oficina": codigo_oficina, "id_venta": id_venta, "concepto": concepto,
         "estado": estado, "limite": limite, "desplazamiento": desplazamiento},
    )


@router.get("/pagos/{id_pago}", tags=[T_PAGO], summary="Ver un pago con sus aplicaciones a cuotas")
def ver_pago(id_pago: int):
    pago = exigir(consultar_uno("SELECT * FROM pago WHERE id_pago = %s", (id_pago,)), "Pago", id_pago)
    pago["aplicado_a_cuotas"] = consultar(
        "SELECT id_venta, nro_cuota, monto_aplicado FROM pago_cuota WHERE id_pago = %s ORDER BY nro_cuota",
        (id_pago,),
    )
    return pago


_COLUMNAS_PAGO = """
    codigo_oficina = %(codigo_oficina)s, nro_recibo = %(nro_recibo)s, id_venta = %(id_venta)s,
    id_separacion = %(id_separacion)s, id_cuenta = %(id_cuenta)s, fecha_hora = %(fecha_hora)s,
    concepto = %(concepto)s, monto = %(monto)s, medio_pago = %(medio_pago)s,
    nro_operacion = %(nro_operacion)s, estado_recibo = %(estado_recibo)s
"""


@router.post("/pagos", tags=[T_PAGO], status_code=201,
             summary="Crear un pago (CRUD simple; el proceso completo es /pagos/registrar)")
def crear_pago(datos: PagoIn):
    return consultar_uno(
        """
        INSERT INTO pago (codigo_oficina, nro_recibo, id_venta, id_separacion, id_cuenta, fecha_hora,
                          concepto, monto, medio_pago, nro_operacion, estado_recibo)
        VALUES (%(codigo_oficina)s, %(nro_recibo)s, %(id_venta)s, %(id_separacion)s, %(id_cuenta)s,
                %(fecha_hora)s, %(concepto)s, %(monto)s, %(medio_pago)s, %(nro_operacion)s,
                %(estado_recibo)s)
        RETURNING *
        """,
        datos.model_dump(),
    )


@router.put("/pagos/{id_pago}", tags=[T_PAGO], summary="Actualizar un pago")
def actualizar_pago(id_pago: int, datos: PagoIn):
    fila = consultar_uno(
        f"UPDATE pago SET {_COLUMNAS_PAGO} WHERE id_pago = %(id)s RETURNING *",
        {**datos.model_dump(), "id": id_pago},
    )
    return exigir(fila, "Pago", id_pago)


@router.delete("/pagos/{id_pago}", tags=[T_PAGO],
               summary="Eliminar un pago (borra en cascada su aplicación a cuotas)")
def eliminar_pago(id_pago: int):
    with transaccion() as cur:
        fila = cur.execute("DELETE FROM pago WHERE id_pago = %s RETURNING *", (id_pago,)).fetchone()
        exigir(fila, "Pago", id_pago)
        if fila["id_venta"] is not None:
            cur.execute("SELECT fn_recalcular_estado_cuotas(%s)", (fila["id_venta"],))
    return {"eliminado": fila}


# -----------------------------------------------------------------------------
# Proceso crítico: registrar un pago (transacción ACID, entregable 7)
# -----------------------------------------------------------------------------
@router.post("/pagos/registrar", tags=[T_PAGO], status_code=201,
             summary="Registrar un pago: recibo correlativo + aplicación a cuotas + estados (ACID)")
def registrar_pago(datos: Annotated[PagoNuevoIn, Body(openapi_examples=EJEMPLO_PAGO)]):
    """Todo ocurre en una sola transacción (BEGIN ... COMMIT). Si algo falla, ROLLBACK:
    no queda ni el recibo, ni el número de recibo consumido, ni cuotas a medio aplicar.

    1. Toma el siguiente número de recibo de la oficina. El UPDATE bloquea la fila de la
       oficina hasta el COMMIT, así dos cajeros de la misma oficina nunca obtienen el
       mismo número (control de concurrencia).
    2. Valida la venta o la separación y bloquea su fila (FOR UPDATE).
    3. Inserta el pago.
    4. Si es CUOTA o CANCELACION, reparte el monto entre las cuotas con saldo,
       de la más antigua a la más nueva (pago_cuota) y recalcula su estado.
    5. Si con este pago la venta queda pagada, la venta pasa a CANCELADA y el lote a CANCELADO.
    """
    conn = conectar()
    cur = conn.cursor()
    try:
        cur.execute("BEGIN")

        # 1. Número de recibo correlativo por oficina (bloquea la fila de la oficina).
        oficina = cur.execute(
            """
            UPDATE oficina SET ultimo_nro_recibo = ultimo_nro_recibo + 1
            WHERE  codigo_oficina = %s
            RETURNING codigo_oficina, ultimo_nro_recibo
            """,
            (datos.codigo_oficina,),
        ).fetchone()
        exigir(oficina, "Oficina", datos.codigo_oficina)
        nro_recibo = oficina["ultimo_nro_recibo"]

        venta = None
        if datos.id_separacion is not None:
            # 2a. Pago de una separación.
            sep = cur.execute(
                "SELECT id_separacion, estado FROM separacion WHERE id_separacion = %s FOR UPDATE",
                (datos.id_separacion,),
            ).fetchone()
            exigir(sep, "Separación", datos.id_separacion)
            if sep["estado"] != "VIGENTE":
                raise HTTPException(422, f"La separación está {sep['estado']}, no se puede pagar")
        elif datos.id_venta is not None:
            # 2b. Pago de una venta: solo ventas ACTIVAS.
            venta = cur.execute(
                """
                SELECT v.id_venta, v.id_lote, v.modalidad, v.estado_venta,
                       v.precio_lista - v.descuento AS precio_final, v.inicial,
                       -- lo ya pagado de la venta (sin gastos de escritura) + separación aplicada al precio
                       COALESCE((SELECT SUM(p.monto) FROM pago p
                                 WHERE  p.id_venta = v.id_venta AND p.estado_recibo = 'EMITIDO'
                                   AND  p.concepto <> 'GASTOS_ESCRITURA'), 0)
                     + COALESCE((SELECT SUM(p.monto) FROM pago p
                                 JOIN   separacion s ON s.id_separacion = p.id_separacion
                                 WHERE  s.id_separacion = v.id_separacion
                                   AND  s.destino_monto = 'PRECIO'
                                   AND  p.estado_recibo = 'EMITIDO'), 0) AS pagado
                FROM   venta v
                WHERE  v.id_venta = %s
                FOR UPDATE OF v
                """,
                (datos.id_venta,),
            ).fetchone()
            exigir(venta, "Venta", datos.id_venta)
            if venta["estado_venta"] != "ACTIVA":
                raise HTTPException(422, f"La venta está {venta['estado_venta']}; no admite pagos")
            _validar_monto_venta(cur, venta, datos)

        # 3. El pago (las reglas de la tabla, como el arco venta/separación, las valida la BD).
        pago = cur.execute(
            """
            INSERT INTO pago (codigo_oficina, nro_recibo, id_venta, id_separacion, id_cuenta,
                              fecha_hora, concepto, monto, medio_pago, nro_operacion, estado_recibo)
            VALUES (%(codigo_oficina)s, %(nro_recibo)s, %(id_venta)s, %(id_separacion)s, %(id_cuenta)s,
                    now(), %(concepto)s, %(monto)s, %(medio_pago)s, %(nro_operacion)s, 'EMITIDO')
            RETURNING *
            """,
            {**datos.model_dump(), "nro_recibo": nro_recibo},
        ).fetchone()

        # 4. Aplicación a cuotas, de la más antigua a la más nueva.
        aplicaciones = []
        if venta and venta["modalidad"] == "CUOTAS" and datos.concepto in ("CUOTA", "CANCELACION"):
            restante = datos.monto
            for cuota in cur.execute(SQL_SALDO_CUOTAS, (venta["id_venta"],)).fetchall():
                if restante <= 0:
                    break
                if cuota["saldo"] <= 0:
                    continue
                aplicado = min(restante, cuota["saldo"])
                cur.execute(
                    """
                    INSERT INTO pago_cuota (id_pago, id_venta, nro_cuota, monto_aplicado)
                    VALUES (%s, %s, %s, %s)
                    """,
                    (pago["id_pago"], venta["id_venta"], cuota["nro_cuota"], aplicado),
                )
                aplicaciones.append({"nro_cuota": cuota["nro_cuota"], "monto_aplicado": aplicado,
                                     "saldo_restante_cuota": cuota["saldo"] - aplicado})
                restante -= aplicado
            cur.execute("SELECT fn_recalcular_estado_cuotas(%s)", (venta["id_venta"],))

        # 5. ¿Quedó pagada la venta?
        estado_venta = venta["estado_venta"] if venta else None
        if venta and _venta_pagada(cur, venta, datos):
            cur.execute("UPDATE venta SET estado_venta = 'CANCELADA' WHERE id_venta = %s",
                        (venta["id_venta"],))
            cur.execute("UPDATE lote SET estado_lote = 'CANCELADO' WHERE id_lote = %s",
                        (venta["id_lote"],))
            estado_venta = "CANCELADA"

        cur.execute("COMMIT")
    except Exception:
        cur.execute("ROLLBACK")
        raise
    finally:
        conn.close()

    return {"recibo": f"{pago['codigo_oficina']}-{pago['nro_recibo']:06d}", "pago": pago,
            "aplicado_a_cuotas": aplicaciones, "estado_venta": estado_venta}


def _deuda_cuotas(cur, id_venta: int) -> Decimal:
    fila = cur.execute(f"SELECT COALESCE(SUM(saldo), 0) AS deuda FROM ({SQL_SALDO_CUOTAS}) x",
                       (id_venta,)).fetchone()
    return fila["deuda"]


def _validar_monto_venta(cur, venta: dict, datos: PagoNuevoIn) -> None:
    """Reglas de cobranza según la modalidad de la venta y el concepto del pago."""
    c = datos.concepto
    if c == "SEPARACION":
        raise HTTPException(422, "Una separación se paga con id_separacion, no con id_venta")
    if c == "GASTOS_ESCRITURA":
        return
    if venta["modalidad"] == "CONTADO":
        falta = venta["precio_final"] - venta["pagado"]
        if c != "CANCELACION":
            raise HTTPException(422, "Una venta al contado se paga con concepto CANCELACION")
        if datos.monto != falta:
            raise HTTPException(422, f"Al contado se paga el saldo completo: S/ {falta}")
        return
    # Venta en cuotas
    if c == "INICIAL":
        inicial_pagada = venta["pagado"] - _pagado_cuotas(cur, venta["id_venta"])
        falta = venta["inicial"] - inicial_pagada
        if datos.monto > falta:
            raise HTTPException(422, f"El monto supera lo que falta de la inicial: S/ {falta}")
        return
    deuda = _deuda_cuotas(cur, venta["id_venta"])
    if c == "CUOTA" and datos.monto > deuda:
        raise HTTPException(422, f"El monto supera la deuda de cuotas: S/ {deuda}")
    if c == "CANCELACION" and datos.monto != deuda:
        raise HTTPException(422, f"Para cancelar se paga toda la deuda de cuotas: S/ {deuda}")


def _pagado_cuotas(cur, id_venta: int) -> Decimal:
    fila = cur.execute(
        """
        SELECT COALESCE(SUM(pc.monto_aplicado), 0) AS total
        FROM   pago_cuota pc JOIN pago p ON p.id_pago = pc.id_pago
        WHERE  pc.id_venta = %s AND p.estado_recibo = 'EMITIDO'
        """,
        (id_venta,),
    ).fetchone()
    return fila["total"]


def _venta_pagada(cur, venta: dict, datos: PagoNuevoIn) -> bool:
    if datos.concepto == "GASTOS_ESCRITURA":
        return False
    if venta["modalidad"] == "CONTADO":
        return datos.concepto == "CANCELACION"
    return datos.concepto in ("CUOTA", "CANCELACION") and _deuda_cuotas(cur, venta["id_venta"]) == 0


# -----------------------------------------------------------------------------
# Proceso: anular un recibo
# -----------------------------------------------------------------------------
@router.put("/pagos/{id_pago}/anular", tags=[T_PAGO],
            summary="Anular un recibo: deja de contar en las cuotas y la venta vuelve a ACTIVA si hace falta")
def anular_pago(id_pago: int):
    with transaccion() as cur:
        pago = cur.execute("SELECT * FROM pago WHERE id_pago = %s FOR UPDATE", (id_pago,)).fetchone()
        exigir(pago, "Pago", id_pago)
        if pago["estado_recibo"] == "ANULADO":
            raise HTTPException(422, "El recibo ya está anulado")
        cur.execute("UPDATE pago SET estado_recibo = 'ANULADO' WHERE id_pago = %s", (id_pago,))

        estado_venta = None
        if pago["id_venta"] is not None:
            venta = cur.execute(
                "SELECT id_venta, id_lote, modalidad, estado_venta FROM venta WHERE id_venta = %s FOR UPDATE",
                (pago["id_venta"],),
            ).fetchone()
            cur.execute("SELECT fn_recalcular_estado_cuotas(%s)", (venta["id_venta"],))
            estado_venta = venta["estado_venta"]
            if venta["estado_venta"] == "CANCELADA" and pago["concepto"] in ("CUOTA", "CANCELACION"):
                lote = "EN_CUOTAS" if venta["modalidad"] == "CUOTAS" else "RESERVADO"
                cur.execute("UPDATE venta SET estado_venta = 'ACTIVA' WHERE id_venta = %s",
                            (venta["id_venta"],))
                cur.execute("UPDATE lote SET estado_lote = %s WHERE id_lote = %s", (lote, venta["id_lote"]))
                estado_venta = "ACTIVA"

    return {"id_pago": id_pago, "estado_recibo": "ANULADO", "estado_venta": estado_venta}


# =============================================================================
# PAGO_CUOTA  (clave compuesta: id_pago + id_venta + nro_cuota)
# =============================================================================
@router.get("/pagos-cuotas", tags=[T_PCUO], summary="Listar aplicaciones de pagos a cuotas")
def listar_pagos_cuotas(id_venta: int | None = None, id_pago: int | None = None):
    return consultar(
        """
        SELECT pc.*, p.codigo_oficina, p.nro_recibo, p.estado_recibo
        FROM   pago_cuota pc
        JOIN   pago p ON p.id_pago = pc.id_pago
        WHERE  (%(id_venta)s::int IS NULL OR pc.id_venta = %(id_venta)s)
          AND  (%(id_pago)s::int  IS NULL OR pc.id_pago  = %(id_pago)s)
        ORDER  BY pc.id_venta, pc.nro_cuota
        """,
        {"id_venta": id_venta, "id_pago": id_pago},
    )


@router.get("/pagos-cuotas/{id_pago}/{id_venta}/{nro_cuota}", tags=[T_PCUO], summary="Ver una aplicación")
def ver_pago_cuota(id_pago: int, id_venta: int, nro_cuota: int):
    fila = consultar_uno(
        "SELECT * FROM pago_cuota WHERE id_pago = %s AND id_venta = %s AND nro_cuota = %s",
        (id_pago, id_venta, nro_cuota),
    )
    return exigir(fila, "Aplicación", f"{id_pago}/{id_venta}/{nro_cuota}")


@router.post("/pagos-cuotas", tags=[T_PCUO], status_code=201, summary="Aplicar un pago a una cuota")
def crear_pago_cuota(datos: PagoCuotaIn):
    with transaccion() as cur:
        fila = cur.execute(
            """
            INSERT INTO pago_cuota (id_pago, id_venta, nro_cuota, monto_aplicado)
            VALUES (%(id_pago)s, %(id_venta)s, %(nro_cuota)s, %(monto_aplicado)s)
            RETURNING *
            """,
            datos.model_dump(),
        ).fetchone()
        cur.execute("SELECT fn_recalcular_estado_cuotas(%s)", (datos.id_venta,))
    return fila


@router.put("/pagos-cuotas/{id_pago}/{id_venta}/{nro_cuota}", tags=[T_PCUO],
            summary="Cambiar el monto aplicado")
def actualizar_pago_cuota(id_pago: int, id_venta: int, nro_cuota: int, datos: MontoAplicadoIn):
    with transaccion() as cur:
        fila = cur.execute(
            """
            UPDATE pago_cuota SET monto_aplicado = %s
            WHERE  id_pago = %s AND id_venta = %s AND nro_cuota = %s
            RETURNING *
            """,
            (datos.monto_aplicado, id_pago, id_venta, nro_cuota),
        ).fetchone()
        exigir(fila, "Aplicación", f"{id_pago}/{id_venta}/{nro_cuota}")
        cur.execute("SELECT fn_recalcular_estado_cuotas(%s)", (id_venta,))
    return fila


@router.delete("/pagos-cuotas/{id_pago}/{id_venta}/{nro_cuota}", tags=[T_PCUO],
               summary="Quitar una aplicación")
def eliminar_pago_cuota(id_pago: int, id_venta: int, nro_cuota: int):
    with transaccion() as cur:
        fila = cur.execute(
            "DELETE FROM pago_cuota WHERE id_pago = %s AND id_venta = %s AND nro_cuota = %s RETURNING *",
            (id_pago, id_venta, nro_cuota),
        ).fetchone()
        exigir(fila, "Aplicación", f"{id_pago}/{id_venta}/{nro_cuota}")
        cur.execute("SELECT fn_recalcular_estado_cuotas(%s)", (id_venta,))
    return {"eliminado": fila}


# =============================================================================
# COMISION
# =============================================================================
@router.get("/comisiones", tags=[T_COMI], summary="Listar comisiones con lo pagado y el saldo")
def listar_comisiones(estado: str | None = None, id_venta: int | None = None):
    return consultar(
        """
        SELECT c.*, v.id_asesor,
               COALESCE(SUM(pc.monto), 0)           AS pagado,
               c.monto - COALESCE(SUM(pc.monto), 0) AS saldo
        FROM   comision c
        JOIN   venta v ON v.id_venta = c.id_venta
        LEFT JOIN pago_comision pc ON pc.id_comision = c.id_comision
        WHERE  (%(estado)s::varchar IS NULL OR c.estado = %(estado)s)
          AND  (%(id_venta)s::int   IS NULL OR c.id_venta = %(id_venta)s)
        GROUP  BY c.id_comision, v.id_asesor
        ORDER  BY c.id_comision
        """,
        {"estado": estado, "id_venta": id_venta},
    )


@router.get("/comisiones/{id_comision}", tags=[T_COMI], summary="Ver una comisión")
def ver_comision(id_comision: int):
    fila = consultar_uno("SELECT * FROM comision WHERE id_comision = %s", (id_comision,))
    return exigir(fila, "Comisión", id_comision)


@router.post("/comisiones", tags=[T_COMI], status_code=201, summary="Crear una comisión")
def crear_comision(datos: ComisionIn):
    return consultar_uno(
        """
        INSERT INTO comision (id_venta, tramo, base, porcentaje, monto, fecha_generacion, estado)
        VALUES (%(id_venta)s, %(tramo)s, %(base)s, %(porcentaje)s,
                COALESCE(%(monto)s, ROUND(%(base)s * %(porcentaje)s / 100, 2)),
                %(fecha_generacion)s, %(estado)s)
        RETURNING *
        """,
        datos.model_dump(),
    )


@router.put("/comisiones/{id_comision}", tags=[T_COMI], summary="Actualizar una comisión")
def actualizar_comision(id_comision: int, datos: ComisionIn):
    fila = consultar_uno(
        """
        UPDATE comision
        SET    id_venta = %(id_venta)s, tramo = %(tramo)s, base = %(base)s,
               porcentaje = %(porcentaje)s,
               monto = COALESCE(%(monto)s, ROUND(%(base)s * %(porcentaje)s / 100, 2)),
               fecha_generacion = %(fecha_generacion)s, estado = %(estado)s
        WHERE  id_comision = %(id)s
        RETURNING *
        """,
        {**datos.model_dump(), "id": id_comision},
    )
    return exigir(fila, "Comisión", id_comision)


@router.delete("/comisiones/{id_comision}", tags=[T_COMI],
               summary="Eliminar una comisión (se bloquea si ya tiene pagos)")
def eliminar_comision(id_comision: int):
    fila = consultar_uno("DELETE FROM comision WHERE id_comision = %s RETURNING *", (id_comision,))
    return {"eliminado": exigir(fila, "Comisión", id_comision)}


# =============================================================================
# PAGO_COMISION
# =============================================================================
@router.get("/pagos-comision", tags=[T_PCOM], summary="Listar pagos de comisión")
def listar_pagos_comision(id_comision: int | None = None):
    return consultar(
        """
        SELECT * FROM pago_comision
        WHERE  (%(id)s::int IS NULL OR id_comision = %(id)s)
        ORDER  BY fecha_pago, id_pago_comision
        """,
        {"id": id_comision},
    )


@router.get("/pagos-comision/{id_pago_comision}", tags=[T_PCOM], summary="Ver un pago de comisión")
def ver_pago_comision(id_pago_comision: int):
    fila = consultar_uno("SELECT * FROM pago_comision WHERE id_pago_comision = %s", (id_pago_comision,))
    return exigir(fila, "Pago de comisión", id_pago_comision)


def _actualizar_estado_comision(cur, id_comision: int) -> None:
    """La comisión queda PAGADA, PARCIAL o PENDIENTE según la suma de sus pagos."""
    cur.execute(
        """
        UPDATE comision c
        SET    estado = CASE WHEN x.pagado >= c.monto THEN 'PAGADA'
                             WHEN x.pagado > 0        THEN 'PARCIAL'
                             ELSE 'PENDIENTE' END
        FROM  (SELECT COALESCE(SUM(monto), 0) AS pagado
               FROM   pago_comision WHERE id_comision = %(id)s) x
        WHERE  c.id_comision = %(id)s
        """,
        {"id": id_comision},
    )


@router.post("/pagos-comision", tags=[T_PCOM], status_code=201,
             summary="Pagar una comisión (actualiza el estado de la comisión)")
def crear_pago_comision(datos: PagoComisionIn):
    with transaccion() as cur:
        comision = cur.execute(
            """
            SELECT c.monto - COALESCE((SELECT SUM(monto) FROM pago_comision p
                                       WHERE p.id_comision = c.id_comision), 0) AS saldo
            FROM   comision c WHERE c.id_comision = %s FOR UPDATE
            """,
            (datos.id_comision,),
        ).fetchone()
        exigir(comision, "Comisión", datos.id_comision)
        if datos.monto > comision["saldo"]:
            raise HTTPException(422, f"El pago supera el saldo de la comisión: S/ {comision['saldo']}")
        fila = cur.execute(
            """
            INSERT INTO pago_comision (id_comision, fecha_pago, monto, medio_pago, descripcion)
            VALUES (%(id_comision)s, %(fecha_pago)s, %(monto)s, %(medio_pago)s, %(descripcion)s)
            RETURNING *
            """,
            datos.model_dump(),
        ).fetchone()
        _actualizar_estado_comision(cur, datos.id_comision)
    return fila


@router.put("/pagos-comision/{id_pago_comision}", tags=[T_PCOM], summary="Actualizar un pago de comisión")
def actualizar_pago_comision(id_pago_comision: int, datos: PagoComisionIn):
    with transaccion() as cur:
        fila = cur.execute(
            """
            UPDATE pago_comision
            SET    id_comision = %(id_comision)s, fecha_pago = %(fecha_pago)s, monto = %(monto)s,
                   medio_pago = %(medio_pago)s, descripcion = %(descripcion)s
            WHERE  id_pago_comision = %(id)s
            RETURNING *
            """,
            {**datos.model_dump(), "id": id_pago_comision},
        ).fetchone()
        exigir(fila, "Pago de comisión", id_pago_comision)
        _actualizar_estado_comision(cur, datos.id_comision)
    return fila


@router.delete("/pagos-comision/{id_pago_comision}", tags=[T_PCOM], summary="Eliminar un pago de comisión")
def eliminar_pago_comision(id_pago_comision: int):
    with transaccion() as cur:
        fila = cur.execute(
            "DELETE FROM pago_comision WHERE id_pago_comision = %s RETURNING *", (id_pago_comision,)
        ).fetchone()
        exigir(fila, "Pago de comisión", id_pago_comision)
        _actualizar_estado_comision(cur, fila["id_comision"])
    return {"eliminado": fila}
