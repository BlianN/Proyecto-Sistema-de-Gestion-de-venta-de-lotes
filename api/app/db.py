"""Conexión a PostgreSQL y utilidades comunes (sin ORM: todo es SQL escrito a mano).

Responsable: Mijael Pol Escobar

- consultar / consultar_uno / ejecutar: una sentencia SQL en modo autocommit.
- transaccion(): bloque con BEGIN / COMMIT / ROLLBACK explícitos para los
  procesos que tocan varias tablas.
- manejar_error_bd: convierte los errores de PostgreSQL (restricciones,
  claves foráneas, triggers) en respuestas HTTP claras.
"""
import os
from contextlib import contextmanager

import psycopg
from fastapi import HTTPException, Request
from fastapi.responses import JSONResponse
from psycopg import errors
from psycopg.rows import dict_row

DATABASE_URL = os.getenv(
    "DATABASE_URL",
    "postgresql://inmobiliaria:inmobiliaria@localhost:5432/inmobiliaria",
)


def conectar() -> psycopg.Connection:
    """Abre una conexión nueva. autocommit=True: cada sentencia se confirma sola,
    salvo que abramos una transacción con BEGIN (ver transaccion())."""
    return psycopg.connect(DATABASE_URL, autocommit=True, row_factory=dict_row)


def consultar(sql: str, params=None) -> list[dict]:
    """Ejecuta un SELECT (o algo con RETURNING) y devuelve todas las filas."""
    with conectar() as conn:
        return conn.execute(sql, params).fetchall()


def consultar_uno(sql: str, params=None) -> dict | None:
    """Ejecuta una sentencia y devuelve la primera fila (o None)."""
    with conectar() as conn:
        return conn.execute(sql, params).fetchone()


def ejecutar(sql: str, params=None) -> int:
    """Ejecuta un INSERT/UPDATE/DELETE sin RETURNING y devuelve las filas afectadas."""
    with conectar() as conn:
        return conn.execute(sql, params).rowcount


@contextmanager
def transaccion():
    """Bloque transaccional con BEGIN, COMMIT y ROLLBACK escritos en SQL.

    Uso:
        with transaccion() as cur:
            cur.execute("INSERT ...")
            cur.execute("UPDATE ...")
    Si algo falla dentro del bloque (o al COMMIT, por un trigger diferido),
    se hace ROLLBACK y no queda nada a medias.
    """
    with conectar() as conn:
        cur = conn.cursor()
        cur.execute("BEGIN")
        try:
            yield cur
            cur.execute("COMMIT")
        except Exception:
            cur.execute("ROLLBACK")
            raise


def no_encontrado(recurso: str, clave) -> HTTPException:
    return HTTPException(status_code=404, detail=f"{recurso} {clave} no existe")


def exigir(fila: dict | None, recurso: str, clave) -> dict:
    """Devuelve la fila o lanza 404 si no existe."""
    if fila is None:
        raise no_encontrado(recurso, clave)
    return fila


# ---------------------------------------------------------------------------
# Traducción de errores de PostgreSQL a respuestas HTTP
# ---------------------------------------------------------------------------
_ERRORES = [
    (errors.UniqueViolation, 409, "Ya existe un registro con esos datos (UNIQUE)"),
    (errors.ForeignKeyViolation, 409, "Viola la integridad referencial (FOREIGN KEY)"),
    (errors.CheckViolation, 422, "No cumple una regla de la tabla (CHECK)"),
    (errors.NotNullViolation, 422, "Falta un dato obligatorio (NOT NULL)"),
    (errors.RaiseException, 422, "Regla de negocio no cumplida"),
    (errors.ExclusionViolation, 409, "Conflicto con otro registro"),
    (errors.DataError, 422, "Dato con formato o tamaño inválido"),
]


async def manejar_error_bd(request: Request, exc: psycopg.Error) -> JSONResponse:
    diag = exc.diag
    for tipo, codigo, mensaje in _ERRORES:
        if isinstance(exc, tipo):
            return JSONResponse(
                status_code=codigo,
                content={
                    "error": mensaje,
                    "detalle": diag.message_primary,
                    "info": diag.message_detail,
                    "restriccion": diag.constraint_name,
                    "tabla": diag.table_name,
                },
            )
    return JSONResponse(
        status_code=500,
        content={"error": "Error de base de datos", "detalle": diag.message_primary},
    )
