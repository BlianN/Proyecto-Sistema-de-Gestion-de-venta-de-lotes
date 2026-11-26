"""Modelos de entrada del Módulo 1: Proyectos y Lotes.

Responsable: Ian Anci
Las reglas (valores permitidos, montos positivos, etc.) las valida la base de
datos con sus CHECK; aquí solo se definen los tipos y los ejemplos de /docs.
"""
from datetime import date
from decimal import Decimal

from pydantic import BaseModel, Field


class ProyectoIn(BaseModel):
    nombre: str = Field(examples=["Altos del Misti"])
    tipo_proyecto: str = Field("URBANIZACION", examples=["URBANIZACION"])
    departamento: str = Field("Arequipa", examples=["Arequipa"])
    provincia: str = Field("Arequipa", examples=["Arequipa"])
    distrito: str = Field(examples=["Mariano Melgar"])
    partida_registral: str = Field(examples=["P06000199"])
    hectareas: Decimal = Field(examples=[6.5])
    estado: str = Field("PLANIFICACION", description="PLANIFICACION, EN_VENTA o CERRADO",
                        examples=["PLANIFICACION"])


class SectorIn(BaseModel):
    id_proyecto: int = Field(examples=[1])
    tipo_sector: str = Field(description="ZONA o ETAPA", examples=["ZONA"])
    nombre: str = Field(examples=["D"])


class ManzanaIn(BaseModel):
    id_sector: int = Field(examples=[1])
    codigo: str = Field(examples=["F"])


class LoteBase(BaseModel):
    numero: int = Field(examples=[1])
    tipo_lote: str = Field("VENDIBLE", description="VENDIBLE, AREA_VERDE o FCMP", examples=["VENDIBLE"])
    area_m2: Decimal = Field(examples=[150])
    perimetro_m: Decimal = Field(examples=[50])
    frente_m: Decimal = Field(examples=[10])
    fondo_m: Decimal = Field(examples=[10])
    lado_izq_m: Decimal = Field(examples=[15])
    lado_der_m: Decimal = Field(examples=[15])
    colinda_frente: str | None = Field(None, examples=["Calle 1"])
    colinda_fondo: str | None = None
    colinda_izq: str | None = None
    colinda_der: str | None = None
    partida_registral: str | None = None
    es_esquina: bool = False
    frente_parque: bool = False
    en_avenida: bool = False


class LoteIn(LoteBase):
    id_manzana: int = Field(examples=[1])
    estado_lote: str = Field("DISPONIBLE", examples=["DISPONIBLE"],
                             description="DISPONIBLE, SEPARADO, RESERVADO, BLOQUEADO, "
                                         "EN_CUOTAS, CANCELADO o ESCRITURADO")


class PrecioLoteIn(BaseModel):
    id_lote: int = Field(examples=[8])
    precio: Decimal = Field(examples=[46000])
    fecha_inicio: date = Field(default_factory=date.today)
    fecha_fin: date | None = None
    motivo: str | None = Field(None, examples=["Reajuste anual"])


# ---------------------------------------------------------------------------
# Endpoints complejos
# ---------------------------------------------------------------------------
class LoteNuevo(LoteBase):
    precio: Decimal | None = Field(None, description="Precio de lanzamiento (solo lotes vendibles)",
                                   examples=[40000])


class ManzanaNueva(BaseModel):
    codigo: str = Field(examples=["A"])
    lotes: list[LoteNuevo] = []


class SectorNuevo(BaseModel):
    tipo_sector: str = Field(examples=["ZONA"])
    nombre: str = Field(examples=["A"])
    manzanas: list[ManzanaNueva] = []


class ProyectoCompletoIn(ProyectoIn):
    fecha_inicio_precios: date = Field(default_factory=date.today)
    sectores: list[SectorNuevo] = Field(
        examples=[[{
            "tipo_sector": "ZONA", "nombre": "A",
            "manzanas": [{
                "codigo": "A",
                "lotes": [
                    {"numero": 1, "area_m2": 150, "perimetro_m": 50, "frente_m": 10, "fondo_m": 10,
                     "lado_izq_m": 15, "lado_der_m": 15, "es_esquina": True, "precio": 42000},
                    {"numero": 2, "area_m2": 150, "perimetro_m": 50, "frente_m": 10, "fondo_m": 10,
                     "lado_izq_m": 15, "lado_der_m": 15, "precio": 40000},
                    {"numero": 3, "tipo_lote": "AREA_VERDE", "area_m2": 400, "perimetro_m": 80,
                     "frente_m": 20, "fondo_m": 20, "lado_izq_m": 20, "lado_der_m": 20},
                ],
            }],
        }]]
    )


class CambioPrecioIn(BaseModel):
    precio: Decimal = Field(examples=[47000])
    motivo: str | None = Field(None, examples=["Reajuste por alta demanda"])
    fecha_inicio: date = Field(default_factory=date.today)


# Ejemplo completo que /docs carga en "Try it out".
EJEMPLO_PROYECTO_COMPLETO = {
    "nuevo": {
        "summary": "Proyecto con una zona, una manzana y tres lotes",
        "value": {
            "nombre": "Altos del Misti", "tipo_proyecto": "URBANIZACION", "departamento": "Arequipa",
            "provincia": "Arequipa", "distrito": "Mariano Melgar", "partida_registral": "P06000199",
            "hectareas": 6.5, "estado": "EN_VENTA", "fecha_inicio_precios": "2026-12-01",
            "sectores": [{"tipo_sector": "ZONA", "nombre": "A", "manzanas": [{"codigo": "A", "lotes": [
                {"numero": 1, "area_m2": 150, "perimetro_m": 50, "frente_m": 10, "fondo_m": 10,
                 "lado_izq_m": 15, "lado_der_m": 15, "es_esquina": True, "precio": 42000},
                {"numero": 2, "area_m2": 150, "perimetro_m": 50, "frente_m": 10, "fondo_m": 10,
                 "lado_izq_m": 15, "lado_der_m": 15, "precio": 40000},
                {"numero": 3, "tipo_lote": "AREA_VERDE", "area_m2": 400, "perimetro_m": 80,
                 "frente_m": 20, "fondo_m": 20, "lado_izq_m": 20, "lado_der_m": 20},
            ]}]}],
        },
    }
}
