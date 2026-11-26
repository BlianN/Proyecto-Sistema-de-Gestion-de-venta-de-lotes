"""Reportes (entregable 5): agregaciones con GROUP BY / HAVING y exportación a CSV o Excel.

Responsable: Diego Calancho
  * GET /reportes/ventas-por-asesor?formato=json|csv|xlsx
"""
import csv
import io
from datetime import date
from decimal import Decimal

from fastapi import APIRouter, HTTPException, Query
from fastapi.responses import StreamingResponse
from openpyxl import Workbook
from openpyxl.styles import Alignment, Font, PatternFill
from openpyxl.utils import get_column_letter

from app.db import consultar

router = APIRouter()

T_REPO = "Reportes"

SQL_VENTAS_POR_ASESOR = """
    SELECT pr.nombre                                       AS proyecto,
           COALESCE(pn.nombres || ' ' || pn.apellido_paterno,
                    pj.razon_social, 'VENTA DIRECTA (sin asesor)') AS asesor,
           COUNT(*)                                        AS cantidad_ventas,
           COUNT(*) FILTER (WHERE v.modalidad = 'CONTADO') AS ventas_contado,
           COUNT(*) FILTER (WHERE v.modalidad = 'CUOTAS')  AS ventas_cuotas,
           SUM(l.area_m2)                                  AS area_vendida_m2,
           SUM(v.precio_lista)                             AS monto_lista,
           SUM(v.descuento)                                AS total_descuentos,
           SUM(v.precio_lista - v.descuento)               AS monto_vendido,
           ROUND(AVG(v.precio_lista - v.descuento), 2)     AS ticket_promedio,
           ROUND(SUM(v.precio_lista - v.descuento) / SUM(l.area_m2), 2) AS precio_promedio_m2,
           MIN(v.fecha_venta)                              AS primera_venta,
           MAX(v.fecha_venta)                              AS ultima_venta
    FROM   venta v
    JOIN   lote l      ON l.id_lote = v.id_lote
    JOIN   manzana m   ON m.id_manzana = l.id_manzana
    JOIN   sector s    ON s.id_sector = m.id_sector
    JOIN   proyecto pr ON pr.id_proyecto = s.id_proyecto
    LEFT JOIN asesor a            ON a.id_asesor = v.id_asesor
    LEFT JOIN persona_natural pn  ON pn.id_persona = a.id_persona
    LEFT JOIN persona_juridica pj ON pj.id_persona = a.id_persona
    WHERE  v.estado_venta <> 'ANULADA'
      AND  v.fecha_venta BETWEEN %(desde)s AND %(hasta)s
      AND  (%(id_proyecto)s::int IS NULL OR pr.id_proyecto = %(id_proyecto)s)
    GROUP  BY pr.id_proyecto, pr.nombre, a.id_asesor, pn.nombres, pn.apellido_paterno, pj.razon_social
    HAVING COUNT(*) >= %(min_ventas)s
    ORDER  BY pr.nombre, monto_vendido DESC
"""

ENCABEZADOS = {
    "proyecto": "Proyecto",
    "asesor": "Asesor",
    "cantidad_ventas": "N.º ventas",
    "ventas_contado": "Al contado",
    "ventas_cuotas": "En cuotas",
    "area_vendida_m2": "Área vendida (m²)",
    "monto_lista": "Monto a precio lista (S/)",
    "total_descuentos": "Descuentos (S/)",
    "monto_vendido": "Monto vendido (S/)",
    "ticket_promedio": "Ticket promedio (S/)",
    "precio_promedio_m2": "Precio promedio por m² (S/)",
    "primera_venta": "Primera venta",
    "ultima_venta": "Última venta",
}
COLUMNAS_SUMABLES = {"cantidad_ventas", "ventas_contado", "ventas_cuotas", "area_vendida_m2",
                     "monto_lista", "total_descuentos", "monto_vendido"}


@router.get("/reportes/ventas-por-asesor", tags=[T_REPO],
            summary="Ventas por proyecto y asesor (GROUP BY + HAVING), exportable a CSV o Excel")
def ventas_por_asesor(
    desde: date = Query(date(date.today().year, 1, 1), description="Fecha inicial (incluida)"),
    hasta: date = Query(default_factory=date.today, description="Fecha final (incluida)"),
    min_ventas: int = Query(1, ge=1, description="HAVING: solo asesores con al menos esta cantidad de ventas"),
    id_proyecto: int | None = Query(None, description="Filtrar un proyecto"),
    formato: str = Query("json", pattern="^(json|csv|xlsx)$", description="json, csv o xlsx"),
):
    """Agrupa las ventas no anuladas del periodo por proyecto y asesor. Las ventas
    sin asesor aparecen como VENTA DIRECTA. Con `formato=csv` o `formato=xlsx`
    devuelve un archivo para descargar (en /docs aparece el enlace *Download file*)."""
    if desde > hasta:
        raise HTTPException(422, "'desde' no puede ser posterior a 'hasta'")
    filas = consultar(SQL_VENTAS_POR_ASESOR, {"desde": desde, "hasta": hasta,
                                              "min_ventas": min_ventas, "id_proyecto": id_proyecto})
    nombre = f"ventas_por_asesor_{desde}_{hasta}"

    if formato == "csv":
        return _como_csv(filas, nombre)
    if formato == "xlsx":
        return _como_excel(filas, nombre, desde, hasta, min_ventas, id_proyecto)
    return {"desde": desde, "hasta": hasta, "min_ventas": min_ventas, "filas": filas}


def _como_csv(filas: list[dict], nombre: str) -> StreamingResponse:
    buffer = io.StringIO()
    buffer.write("﻿")  # BOM: para que Excel abra bien las tildes
    escritor = csv.writer(buffer)
    escritor.writerow(ENCABEZADOS.values())
    for f in filas:
        escritor.writerow([f[c] for c in ENCABEZADOS])
    buffer.seek(0)
    return StreamingResponse(
        iter([buffer.getvalue()]),
        media_type="text/csv; charset=utf-8",
        headers={"Content-Disposition": f'attachment; filename="{nombre}.csv"'},
    )


def _como_excel(filas: list[dict], nombre: str, desde, hasta, min_ventas, id_proyecto) -> StreamingResponse:
    libro = Workbook()
    hoja = libro.active
    hoja.title = "Ventas por asesor"
    columnas = list(ENCABEZADOS)

    hoja.append(list(ENCABEZADOS.values()))
    for celda in hoja[1]:
        celda.font = Font(bold=True, color="FFFFFF")
        celda.fill = PatternFill("solid", fgColor="1F4E78")
        celda.alignment = Alignment(horizontal="center", vertical="center", wrap_text=True)

    for f in filas:
        hoja.append([float(f[c]) if isinstance(f[c], Decimal) else f[c] for c in columnas])

    # Fila de totales con fórmulas de Excel.
    if filas:
        ultima = len(filas) + 1
        total = ["TOTAL", ""] + [
            f"=SUM({get_column_letter(i)}2:{get_column_letter(i)}{ultima})" if c in COLUMNAS_SUMABLES else ""
            for i, c in enumerate(columnas[2:], start=3)
        ]
        hoja.append(total)
        for celda in hoja[ultima + 1]:
            celda.font = Font(bold=True)

    # Formatos y anchos.
    for i, c in enumerate(columnas, start=1):
        letra = get_column_letter(i)
        if c in ("monto_lista", "total_descuentos", "monto_vendido", "ticket_promedio",
                 "precio_promedio_m2", "area_vendida_m2"):
            for celda in hoja[letra][1:]:
                celda.number_format = "#,##0.00"
        elif c in ("primera_venta", "ultima_venta"):
            for celda in hoja[letra][1:]:
                celda.number_format = "dd/mm/yyyy"
        hoja.column_dimensions[letra].width = max(14, min(36, len(ENCABEZADOS[c]) + 4))
    hoja.column_dimensions["A"].width = 18
    hoja.column_dimensions["B"].width = 36
    hoja.row_dimensions[1].height = 32
    hoja.freeze_panes = "C2"

    parametros = libro.create_sheet("Parámetros")
    for fila in (["Reporte", "Ventas por proyecto y asesor"], ["Desde", desde], ["Hasta", hasta],
                 ["Mínimo de ventas (HAVING)", min_ventas],
                 ["Proyecto", id_proyecto if id_proyecto else "Todos"],
                 ["Generado", date.today()]):
        parametros.append(fila)
    parametros.column_dimensions["A"].width = 28
    parametros.column_dimensions["B"].width = 32

    salida = io.BytesIO()
    libro.save(salida)
    salida.seek(0)
    return StreamingResponse(
        salida,
        media_type="application/vnd.openxmlformats-officedocument.spreadsheetml.sheet",
        headers={"Content-Disposition": f'attachment; filename="{nombre}.xlsx"'},
    )
