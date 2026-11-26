"""Modelos de entrada del Módulo 2: Ventas.

"""
from datetime import date, datetime
from decimal import Decimal

from pydantic import BaseModel, Field


class PersonaDatos(BaseModel):
    """Datos comunes de toda persona (tabla persona)."""
    direccion: str = Field(examples=["Av. Lima 123, Cercado, Arequipa"])
    telefono: str = Field(examples=["958123456"])
    telefono_2: str | None = None
    correo: str | None = Field(None, examples=["cliente@correo.pe"])


class PersonaNaturalIn(PersonaDatos):
    tipo_documento: str = Field("DNI", description="DNI, CE o PASAPORTE", examples=["DNI"])
    nro_documento: str = Field(examples=["47123456"])
    nombres: str = Field(examples=["María José"])
    apellido_paterno: str = Field(examples=["Rivera"])
    apellido_materno: str | None = Field(None, examples=["Chávez"])
    nacionalidad: str = Field("Peruana", examples=["Peruana"])
    estado_civil: str | None = Field(None, examples=["SOLTERA"])
    ocupacion: str | None = Field(None, examples=["Ingeniera"])


class PersonaJuridicaIn(PersonaDatos):
    id_representante: int = Field(description="id_persona de una persona natural", examples=[1])
    ruc: str = Field(examples=["20609876541"])
    razon_social: str = Field(examples=["Inversiones Arequipa S.A.C."])


class AsesorIn(BaseModel):
    id_persona: int = Field(examples=[20])
    fecha_alta: date = Field(default_factory=date.today)
    estado: str = Field("ACTIVO", description="ACTIVO o INACTIVO", examples=["ACTIVO"])


class SeparacionIn(BaseModel):
    id_lote: int = Field(examples=[8])
    id_persona: int = Field(examples=[1])
    id_asesor: int | None = Field(None, examples=[1])
    fecha_hora: datetime = Field(default_factory=datetime.now)
    monto: Decimal = Field(examples=[100])
    fecha_vencimiento: date = Field(examples=["2026-12-31"])
    estado: str = Field("VIGENTE", description="VIGENTE, CONVERTIDA, RETIRADA o VENCIDA",
                        examples=["VIGENTE"])
    destino_monto: str | None = Field(None, description="ESCRITURA o PRECIO")


class VentaIn(BaseModel):
    id_lote: int = Field(examples=[8])
    id_separacion: int | None = None
    id_asesor: int | None = Field(None, examples=[1])
    codigo_oficina: str = Field(examples=["OFIC-CRDO"])
    fecha_venta: date = Field(default_factory=date.today)
    modalidad: str = Field(description="CONTADO o CUOTAS", examples=["CONTADO"])
    precio_lista: Decimal = Field(examples=[45000])
    descuento: Decimal = Field(Decimal("0"), examples=[2000])
    inicial: Decimal = Field(examples=[43000])
    plazo_meses: int | None = None
    dia_pago: int | None = None
    fecha_primera_cuota: date | None = None
    estado_venta: str = Field("ACTIVA", description="ACTIVA, CANCELADA o ANULADA", examples=["ACTIVA"])
    motivo_excepcion: str | None = None


class VentaCrearIn(VentaIn):
    id_titular: int = Field(description="Toda venta necesita un TITULAR (trigger diferido)",
                            examples=[20])


class VentaParticipanteIn(BaseModel):
    id_venta: int = Field(examples=[2])
    id_persona: int = Field(examples=[6])
    rol: str = Field(description="TITULAR, COPROPIETARIO o FINANCIADOR", examples=["COPROPIETARIO"])


class RolIn(BaseModel):
    rol: str = Field(description="TITULAR, COPROPIETARIO o FINANCIADOR", examples=["COPROPIETARIO"])


# ---------------------------------------------------------------------------
# Endpoints complejos
# ---------------------------------------------------------------------------
class SeparacionNuevaIn(BaseModel):
    id_lote: int = Field(examples=[8])
    id_persona: int = Field(examples=[1])
    id_asesor: int | None = Field(None, examples=[2])
    monto: Decimal = Field(Decimal("100"), description="Mínimo S/ 100", examples=[100])
    dias_vigencia: int = Field(7, ge=1, le=30, description="La separación dura 7 días por defecto")


class ParticipanteNuevo(BaseModel):
    id_persona: int
    rol: str = Field(description="TITULAR, COPROPIETARIO o FINANCIADOR")


class VentaNuevaIn(BaseModel):
    id_lote: int = Field(examples=[8])
    id_separacion: int | None = Field(None, description="Si el lote estaba separado por el cliente")
    destino_separacion: str = Field("PRECIO", description="A qué se aplica lo separado: PRECIO o ESCRITURA")
    id_asesor: int | None = Field(None, examples=[2])
    codigo_oficina: str = Field(examples=["OFIC-CRDO"])
    fecha_venta: date = Field(default_factory=date.today)
    modalidad: str = Field(description="CONTADO o CUOTAS", examples=["CUOTAS"])
    descuento: Decimal = Field(Decimal("0"), examples=[0])
    inicial: Decimal | None = Field(None, description="En CONTADO se calcula sola (precio - descuento)",
                                    examples=[25000])
    plazo_meses: int | None = Field(None, examples=[10])
    dia_pago: int | None = Field(None, examples=[15])
    fecha_primera_cuota: date | None = Field(None, examples=["2027-01-15"])
    motivo_excepcion: str | None = Field(None, description="Obligatorio si la inicial es menor al 50 % "
                                                           "o el plazo pasa de 12 meses")
    participantes: list[ParticipanteNuevo] = Field(
        examples=[[{"id_persona": 20, "rol": "TITULAR"}, {"id_persona": 22, "rol": "COPROPIETARIO"}]]
    )


# Ejemplos completos que /docs carga en "Try it out".
EJEMPLO_VENTA = {
    "cuotas": {
        "summary": "Venta en cuotas del lote 8 (Valle Grande)",
        "value": {
            "id_lote": 8, "id_separacion": None, "destino_separacion": "PRECIO", "id_asesor": 2,
            "codigo_oficina": "OFIC-CRDO", "fecha_venta": "2026-11-25", "modalidad": "CUOTAS",
            "descuento": 0, "inicial": 25000, "plazo_meses": 10, "dia_pago": 15,
            "fecha_primera_cuota": "2027-01-15", "motivo_excepcion": None,
            "participantes": [{"id_persona": 20, "rol": "TITULAR"}, {"id_persona": 22, "rol": "COPROPIETARIO"}],
        },
    },
    "contado": {
        "summary": "Venta al contado del lote 26 con descuento",
        "value": {
            "id_lote": 26, "id_separacion": None, "destino_separacion": "PRECIO", "id_asesor": 1,
            "codigo_oficina": "OFIC-LL", "fecha_venta": "2026-11-25", "modalidad": "CONTADO",
            "descuento": 2000, "inicial": None, "plazo_meses": None, "dia_pago": None,
            "fecha_primera_cuota": None, "motivo_excepcion": None,
            "participantes": [{"id_persona": 24, "rol": "TITULAR"}],
        },
    },
}

EJEMPLO_SEPARACION = {
    "nueva": {
        "summary": "Separar el lote 27 por 7 días",
        "value": {"id_lote": 27, "id_persona": 3, "id_asesor": 1, "monto": 100, "dias_vigencia": 7},
    }
}
