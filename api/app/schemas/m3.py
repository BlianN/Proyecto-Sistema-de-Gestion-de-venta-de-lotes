"""Modelos de entrada del Módulo 3: Cobranza y Comisiones.

Responsable: Mijael Pol Escobar
"""
from datetime import date, datetime
from decimal import Decimal

from pydantic import BaseModel, Field


class OficinaIn(BaseModel):
    codigo_oficina: str = Field(examples=["OFIC-YAN"])
    nombre: str = Field(examples=["Yanahuara"])
    distrito: str = Field(examples=["Yanahuara"])
    direccion: str = Field(examples=["Av. Ejército 500"])
    es_central: bool = False
    ultimo_nro_recibo: int = 0


class CuentaBancariaIn(BaseModel):
    banco: str = Field(examples=["BBVA"])
    nro_cuenta: str = Field(examples=["0011-0250-0100123456"])
    cci: str | None = Field(None, examples=["01125000010012345678"])
    moneda: str = Field("PEN", description="PEN o USD", examples=["PEN"])
    estado: str = Field("ACTIVA", description="ACTIVA o INACTIVA", examples=["ACTIVA"])


class CuotaIn(BaseModel):
    id_venta: int = Field(examples=[2])
    nro_cuota: int = Field(examples=[13])
    fecha_vencimiento: date = Field(examples=["2027-06-05"])
    monto: Decimal = Field(examples=[500])
    estado_cuota: str = Field("PENDIENTE", description="PENDIENTE, PAGADA, PARCIAL o VENCIDA")


class CuotaActualizarIn(BaseModel):
    fecha_vencimiento: date = Field(examples=["2027-01-05"])
    monto: Decimal = Field(examples=[1875])
    estado_cuota: str = Field("PENDIENTE", description="PENDIENTE, PAGADA, PARCIAL o VENCIDA")


class PagoIn(BaseModel):
    codigo_oficina: str = Field(examples=["OFIC-CRDO"])
    nro_recibo: int = Field(description="En el CRUD simple se escribe a mano; "
                                        "/pagos/registrar lo asigna solo", examples=[999])
    id_venta: int | None = Field(None, examples=[2])
    id_separacion: int | None = None
    id_cuenta: int | None = None
    fecha_hora: datetime = Field(default_factory=datetime.now)
    concepto: str = Field(description="SEPARACION, INICIAL, CUOTA, CANCELACION o GASTOS_ESCRITURA",
                          examples=["GASTOS_ESCRITURA"])
    monto: Decimal = Field(examples=[350])
    medio_pago: str = Field(description="EFECTIVO, DEPOSITO o TRANSFERENCIA", examples=["EFECTIVO"])
    nro_operacion: str | None = None
    estado_recibo: str = Field("EMITIDO", description="EMITIDO o ANULADO")


class PagoCuotaIn(BaseModel):
    id_pago: int = Field(examples=[1])
    id_venta: int = Field(examples=[2])
    nro_cuota: int = Field(examples=[5])
    monto_aplicado: Decimal = Field(examples=[100])


class MontoAplicadoIn(BaseModel):
    monto_aplicado: Decimal = Field(examples=[100])


class ComisionIn(BaseModel):
    id_venta: int = Field(examples=[11])
    tramo: str = Field(description="UNICO, TRAMO1 o TRAMO2", examples=["TRAMO2"])
    base: Decimal = Field(examples=[22500])
    porcentaje: Decimal = Field(Decimal("8"), examples=[8])
    monto: Decimal | None = Field(None, description="Si no se envía: base × porcentaje / 100")
    fecha_generacion: date = Field(default_factory=date.today)
    estado: str = Field("PENDIENTE", description="PENDIENTE, PARCIAL o PAGADA")


class PagoComisionIn(BaseModel):
    id_comision: int = Field(examples=[6])
    fecha_pago: date = Field(default_factory=date.today)
    monto: Decimal = Field(examples=[480])
    medio_pago: str = Field(description="EFECTIVO, DEPOSITO, TRANSFERENCIA o INTERNO",
                            examples=["TRANSFERENCIA"])
    descripcion: str | None = Field(None, examples=["Pago de comisión"])


# ---------------------------------------------------------------------------
# Endpoint complejo
# ---------------------------------------------------------------------------
class PagoNuevoIn(BaseModel):
    codigo_oficina: str = Field(description="Oficina que emite el recibo", examples=["OFIC-CRDO"])
    id_venta: int | None = Field(None, examples=[11])
    id_separacion: int | None = Field(None, description="Solo para pagar una separación")
    concepto: str = Field(description="SEPARACION, INICIAL, CUOTA, CANCELACION o GASTOS_ESCRITURA",
                          examples=["CUOTA"])
    monto: Decimal = Field(examples=[2500])
    medio_pago: str = Field(description="EFECTIVO, DEPOSITO o TRANSFERENCIA", examples=["EFECTIVO"])
    id_cuenta: int | None = Field(None, description="Obligatoria si no es efectivo")
    nro_operacion: str | None = Field(None, description="Obligatorio si no es efectivo")


# Ejemplos completos que /docs carga en "Try it out".
EJEMPLO_PAGO = {
    "cuota": {
        "summary": "Pago de cuotas de la venta 11 (cliente atrasado)",
        "value": {"codigo_oficina": "OFIC-CRDO", "id_venta": 11, "id_separacion": None, "concepto": "CUOTA",
                  "monto": 2500, "medio_pago": "EFECTIVO", "id_cuenta": None, "nro_operacion": None},
    },
    "transferencia": {
        "summary": "Pago por transferencia a una cuenta (venta 16)",
        "value": {"codigo_oficina": "OFIC-LL", "id_venta": 16, "id_separacion": None, "concepto": "CUOTA",
                  "monto": 1583.33, "medio_pago": "TRANSFERENCIA", "id_cuenta": 1, "nro_operacion": "OP-123456"},
    },
    "separacion": {
        "summary": "Pago de la separación 3",
        "value": {"codigo_oficina": "OFIC-CRDO", "id_venta": None, "id_separacion": 3, "concepto": "SEPARACION",
                  "monto": 100, "medio_pago": "EFECTIVO", "id_cuenta": None, "nro_operacion": None},
    },
}
