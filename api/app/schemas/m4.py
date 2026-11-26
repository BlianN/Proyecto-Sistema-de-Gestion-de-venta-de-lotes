"""Modelos de entrada del Módulo 4: Personal y Sueldos.

Responsable: Ian Anci
"""
from datetime import date
from decimal import Decimal

from pydantic import BaseModel, Field


class EmpleadoIn(BaseModel):
    id_persona: int = Field(description="id_persona de una persona natural", examples=[20])
    codigo_oficina: str = Field(examples=["OFIC-CRDO"])
    id_proyecto: int | None = Field(None, examples=[1])
    cargo: str = Field(examples=["Asistente de ventas"])
    fecha_ingreso: date = Field(default_factory=date.today)
    fecha_cese: date | None = None
    estado: str = Field("ACTIVO", description="ACTIVO o CESADO", examples=["ACTIVO"])


class SueldoIn(BaseModel):
    id_empleado: int = Field(examples=[2])
    monto_mensual: Decimal = Field(examples=[1900])
    fecha_inicio: date = Field(default_factory=date.today)
    fecha_fin: date | None = None


class PagoSueldoIn(BaseModel):
    id_empleado: int = Field(examples=[1])
    periodo: str = Field(description="Año-mes, por ejemplo 2026-11", examples=["2026-11"])
    fecha_pago: date = Field(default_factory=date.today)
    monto: Decimal = Field(examples=[5500])
    medio_pago: str = Field(description="EFECTIVO, DEPOSITO o TRANSFERENCIA", examples=["TRANSFERENCIA"])


# ---------------------------------------------------------------------------
# Endpoints complejos
# ---------------------------------------------------------------------------
class EmpleadoCompletoIn(BaseModel):
    """Datos de la persona natural + del empleado + su primer sueldo."""
    tipo_documento: str = Field("DNI", examples=["DNI"])
    nro_documento: str = Field(examples=["46778899"])
    nombres: str = Field(examples=["Andrea"])
    apellido_paterno: str = Field(examples=["Gómez"])
    apellido_materno: str | None = Field(None, examples=["Ríos"])
    nacionalidad: str = Field("Peruana", examples=["Peruana"])
    estado_civil: str | None = Field(None, examples=["SOLTERA"])
    direccion: str = Field(examples=["Calle Santa Catalina 150, Cercado"])
    telefono: str = Field(examples=["958777888"])
    correo: str | None = Field(None, examples=["andrea.gomez@correo.pe"])
    codigo_oficina: str = Field(examples=["OFIC-MGG"])
    id_proyecto: int | None = Field(None, examples=[1])
    cargo: str = Field(examples=["Secretaria"])
    fecha_ingreso: date = Field(default_factory=date.today)
    sueldo_mensual: Decimal = Field(examples=[1500])


class CambioSueldoIn(BaseModel):
    monto_mensual: Decimal = Field(examples=[2000])
    fecha_inicio: date = Field(default_factory=date.today)


# Ejemplo completo que /docs carga en "Try it out".
EJEMPLO_EMPLEADO_COMPLETO = {
    "nuevo": {
        "summary": "Contratar una secretaria para la oficina Miguel Grau",
        "value": {
            "tipo_documento": "DNI", "nro_documento": "46778899", "nombres": "Andrea",
            "apellido_paterno": "Gómez", "apellido_materno": "Ríos", "nacionalidad": "Peruana",
            "estado_civil": "SOLTERA", "direccion": "Calle Santa Catalina 150, Cercado",
            "telefono": "958777888", "correo": "andrea.gomez@correo.pe", "codigo_oficina": "OFIC-MGG",
            "id_proyecto": 1, "cargo": "Secretaria", "fecha_ingreso": "2026-12-01", "sueldo_mensual": 1500,
        },
    }
}
