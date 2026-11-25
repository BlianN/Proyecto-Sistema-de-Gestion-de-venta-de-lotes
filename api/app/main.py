"""Punto de entrada de la API.

Responsable: Mijael Pol Escobar

Registra automáticamente todos los routers que haya en app/routers/,
así cada integrante agrega su archivo sin tocar este.
Documentación interactiva (para probar los endpoints): http://localhost:8000/docs
"""
import importlib
import pkgutil

import psycopg
from fastapi import FastAPI

from app import routers
from app.db import consultar_uno, manejar_error_bd

app = FastAPI(
    title="Sistema de Gestión de Venta de Lotes",
    description=(
        "API del proyecto final de Base de Datos. PostgreSQL + FastAPI, sin ORM: "
        "todas las consultas están escritas en SQL.\n\n"
        "Módulos: 1 Proyectos y Lotes · 2 Ventas · 3 Cobranza y Comisiones · "
        "4 Personal y Sueldos · Reportes."
    ),
    version="1.0.0",
)

app.add_exception_handler(psycopg.Error, manejar_error_bd)

for modulo in sorted(pkgutil.iter_modules(routers.__path__), key=lambda m: m.name):
    mod = importlib.import_module(f"app.routers.{modulo.name}")
    if hasattr(mod, "router"):
        app.include_router(mod.router)


@app.get("/", tags=["General"], summary="Estado de la API y de la base de datos")
def estado():
    fila = consultar_uno("SELECT version() AS version, current_database() AS base, now() AS hora")
    return {"api": "ok", "documentacion": "/docs", **fila}
