from fastapi import FastAPI, HTTPException, Query
from fastapi.responses import StreamingResponse
from pydantic import BaseModel
from typing import Optional
import io
import csv
import psycopg
from psycopg.rows import dict_row

app = FastAPI(
    title="API Inmobiliaria - Entregable 1",
    description="Operaciones CRUD complejas (3+ tablas) y Reportes con GROUP BY / HAVING exportables a CSV/Excel"
)

# ==========================================
# CONFIGURACIÓN DE CONEXIÓN A POSTGRESQL
# ==========================================
DB_CONFIG = "dbname=TU_BASE_DE_DATOS user=postgres password=TU_CONTRASEÑA host=localhost port=5432"

def get_connection():
    return psycopg.connect(DB_CONFIG, row_factory=dict_row)

# ==========================================
# MODELOS DE ENTRADA (JSON)
# ==========================================
class VentaCompletaCreate(BaseModel):
    id_lote: int
    id_separacion: Optional[int] = None
    id_asesor: int
    codigo_oficina: str
    modalidad: str          # 'CONTADO' o 'CREDITO'
    precio_lista: float
    descuento: float = 0.0
    inicial: float
    plazo_meses: int = 0
    dia_pago: Optional[int] = None
    id_persona_titular: int

class ClienteJuridicoCreate(BaseModel):
    direccion_empresa: str
    telefono_empresa: str
    correo_empresa: str
    ruc: str
    razon_social: str
    direccion_rep: str
    telefono_rep: str
    correo_rep: str
    tipo_documento: str = "DNI"
    nro_documento: str
    nombres: str
    apellido_paterno: str
    apellido_materno: Optional[str] = None
    nacionalidad: str = "Peruana"

class AnulacionVentaUpdate(BaseModel):
    motivo_excepcion: str

# ==========================================
# 1. POST: REGISTRAR VENTA COMPLETA (4 TABLAS)
# Tablas: venta, venta_participante, lote, separacion
# ==========================================
@app.post("/api/ventas", status_code=201)
def registrar_venta_completa(datos: VentaCompletaCreate):
    with get_connection() as conn:
        try:
            with conn.cursor() as cur:
                cur.execute("SELECT estado FROM lote WHERE id_lote = %s FOR UPDATE;", (datos.id_lote,))
                lote = cur.fetchone()
                if not lote:
                    raise HTTPException(status_code=404, detail="El lote no existe")
                if lote["estado"] != "DISPONIBLE":
                    raise HTTPException(status_code=400, detail=f"El lote no está disponible (Estado: {lote['estado']})")

                cur.execute("""
                    INSERT INTO venta (
                        id_lote, id_separacion, id_asesor, codigo_oficina, fecha_venta,
                        modalidad, precio_lista, descuento, inicial, plazo_meses,
                        dia_pago, fecha_primera_cuota, estado_venta
                    ) VALUES (
                        %s, %s, %s, %s, CURRENT_DATE,
                        %s, %s, %s, %s, %s,
                        %s, CURRENT_DATE + INTERVAL '1 month', 'APROBADA'
                    ) RETURNING id_venta;
                """, (
                    datos.id_lote, datos.id_separacion, datos.id_asesor, datos.codigo_oficina,
                    datos.modalidad, datos.precio_lista, datos.descuento, datos.inicial,
                    datos.plazo_meses, datos.dia_pago
                ))
                id_venta = cur.fetchone()["id_venta"]

                cur.execute("""
                    INSERT INTO venta_participante (id_venta, id_persona, rol)
                    VALUES (%s, %s, 'TITULAR');
                """, (id_venta, datos.id_persona_titular))

                cur.execute("UPDATE lote SET estado = 'VENDIDO' WHERE id_lote = %s;", (datos.id_lote,))

                if datos.id_separacion is not None:
                    cur.execute("UPDATE separacion SET estado = 'CONVERTIDA' WHERE id_separacion = %s;", (datos.id_separacion,))

            conn.commit()
            return {
                "mensaje": "Venta registrada en cascada correctamente",
                "id_venta": id_venta,
                "tablas_afectadas": ["venta", "venta_participante", "lote", "separacion"]
            }
        except HTTPException:
            conn.rollback()
            raise
        except Exception as e:
            conn.rollback()
            raise HTTPException(status_code=500, detail=str(e))

# ==========================================
# 2. POST: REGISTRAR CLIENTE JURÍDICO + REPRESENTANTE (3 TABLAS)
# Tablas: persona, persona_natural, persona_juridica
# ==========================================
@app.post("/api/clientes/juridicos", status_code=201)
def registrar_cliente_juridico(datos: ClienteJuridicoCreate):
    with get_connection() as conn:
        try:
            with conn.cursor() as cur:
                cur.execute("""
                    INSERT INTO persona (tipo_persona, direccion, telefono, correo)
                    VALUES ('N', %s, %s, %s) RETURNING id_persona;
                """, (datos.direccion_rep, datos.telefono_rep, datos.correo_rep))
                id_rep = cur.fetchone()["id_persona"]

                cur.execute("""
                    INSERT INTO persona_natural (
                        id_persona, tipo_documento, nro_documento, nombres,
                        apellido_paterno, apellido_materno, nacionalidad
                    ) VALUES (%s, %s, %s, %s, %s, %s, %s);
                """, (
                    id_rep, datos.tipo_documento, datos.nro_documento, datos.nombres,
                    datos.apellido_paterno, datos.apellido_materno, datos.nacionalidad
                ))

                cur.execute("""
                    INSERT INTO persona (tipo_persona, direccion, telefono, correo)
                    VALUES ('J', %s, %s, %s) RETURNING id_persona;
                """, (datos.direccion_empresa, datos.telefono_empresa, datos.correo_empresa))
                id_empresa = cur.fetchone()["id_persona"]

                cur.execute("""
                    INSERT INTO persona_juridica (id_persona, id_representante, ruc, razon_social)
                    VALUES (%s, %s, %s, %s);
                """, (id_empresa, id_rep, datos.ruc, datos.razon_social))

            conn.commit()
            return {
                "mensaje": "Cliente jurídico y representante legal creados en cascada",
                "id_persona_juridica": id_empresa,
                "id_representante_natural": id_rep,
                "tablas_afectadas": ["persona", "persona_natural", "persona_juridica"]
            }
        except Exception as e:
            conn.rollback()
            raise HTTPException(status_code=400, detail=str(e))

# ==========================================
# 3. PUT: ANULAR VENTA CON LIBERACIÓN VINCULADA (3 TABLAS)
# Tablas: venta, lote, separacion
# ==========================================
@app.put("/api/ventas/{id_venta}/anular")
def anular_venta(id_venta: int, datos: AnulacionVentaUpdate):
    with get_connection() as conn:
        try:
            with conn.cursor() as cur:
                cur.execute("SELECT id_lote, id_separacion, estado_venta FROM venta WHERE id_venta = %s;", (id_venta,))
                venta = cur.fetchone()
                if not venta:
                    raise HTTPException(status_code=404, detail="Venta no encontrada")
                if venta["estado_venta"] == "ANULADA":
                    raise HTTPException(status_code=400, detail="La venta ya está anulada")

                cur.execute("""
                    UPDATE venta SET estado_venta = 'ANULADA', motivo_excepcion = %s
                    WHERE id_venta = %s;
                """, (datos.motivo_excepcion, id_venta))

                cur.execute("UPDATE lote SET estado = 'DISPONIBLE' WHERE id_lote = %s;", (venta["id_lote"],))

                if venta["id_separacion"] is not None:
                    cur.execute("""
                        UPDATE separacion SET estado = 'VENCIDA', destino_monto = 'PENALIDAD'
                        WHERE id_separacion = %s;
                    """, (venta["id_separacion"],))

            conn.commit()
            return {
                "mensaje": f"Venta #{id_venta} anulada y lote #{venta['id_lote']} liberado",
                "tablas_afectadas": ["venta", "lote", "separacion"]
            }
        except HTTPException:
            conn.rollback()
            raise
        except Exception as e:
            conn.rollback()
            raise HTTPException(status_code=500, detail=str(e))

# ==========================================
# 4. GET: CONSULTA CONSOLIDADA DE VENTAS (6 TABLAS)
# ==========================================
@app.get("/api/ventas/{id_venta}")
def obtener_detalle_venta(id_venta: int):
    with get_connection() as conn:
        with conn.cursor() as cur:
            cur.execute("""
                SELECT 
                    v.id_venta, v.fecha_venta, v.modalidad, v.precio_lista, v.estado_venta,
                    l.id_lote, l.estado AS estado_lote,
                    o.nombre AS oficina,
                    vp.rol,
                    p.correo AS correo_cliente,
                    COALESCE(pn.nombres || ' ' || pn.apellido_paterno, pj.razon_social) AS cliente,
                    COALESCE(pn.nro_documento, pj.ruc) AS documento_identidad
                FROM venta v
                JOIN lote l ON v.id_lote = l.id_lote
                JOIN oficina o ON v.codigo_oficina = o.codigo_oficina
                JOIN venta_participante vp ON v.id_venta = vp.id_venta
                JOIN persona p ON vp.id_persona = p.id_persona
                LEFT JOIN persona_natural pn ON p.id_persona = pn.id_persona
                LEFT JOIN persona_juridica pj ON p.id_persona = pj.id_persona
                WHERE v.id_venta = %s;
            """, (id_venta,))
            resultado = cur.fetchall()
            if not resultado:
                raise HTTPException(status_code=404, detail="Detalle de venta no encontrado")
            return {"detalle_venta": resultado}

# ==========================================
# 5. GET: REPORTE CON GROUP BY + HAVING Y EXPORTACIÓN CSV/EXCEL
# Tablas: venta, asesor, persona_natural, oficina
# ==========================================
@app.get("/api/reportes/ventas-asesores/exportar")
def exportar_reporte_ventas_csv(
    min_ventas: int = Query(1, ge=1, description="Filtro HAVING: cantidad mínima de ventas realizadas"),
    min_monto_neto: float = Query(45000.0, ge=0, description="Filtro HAVING: monto neto mínimo acumulado")
):
    with get_connection() as conn:
        with conn.cursor() as cur:
            cur.execute("""
                SELECT 
                    o.codigo_oficina,
                    o.nombre AS oficina,
                    a.id_asesor,
                    pn.nro_documento AS dni_asesor,
                    pn.nombres || ' ' || pn.apellido_paterno AS nombre_asesor,
                    a.estado AS estado_asesor,
                    COUNT(v.id_venta) AS total_ventas,
                    SUM(v.precio_lista) AS total_precio_lista,
                    SUM(v.descuento) AS total_descuentos,
                    SUM(v.precio_lista - v.descuento) AS monto_neto_vendido,
                    SUM(v.inicial) AS total_inicial_recaudada,
                    ROUND(AVG(v.precio_lista - v.descuento), 2) AS ticket_promedio
                FROM venta v
                INNER JOIN asesor a ON v.id_asesor = a.id_asesor
                INNER JOIN persona_natural pn ON a.id_persona = pn.id_persona
                INNER JOIN oficina o ON v.codigo_oficina = o.codigo_oficina
                WHERE v.estado_venta <> 'ANULADA'
                GROUP BY 
                    o.codigo_oficina, 
                    o.nombre, 
                    a.id_asesor, 
                    pn.nro_documento, 
                    pn.nombres, 
                    pn.apellido_paterno, 
                    a.estado
                HAVING 
                    COUNT(v.id_venta) >= %s 
                    AND SUM(v.precio_lista - v.descuento) >= %s
                ORDER BY monto_neto_vendido DESC;
            """, (min_ventas, min_monto_neto))
            filas = cur.fetchall()

    if not filas:
        raise HTTPException(
            status_code=404,
            detail="No existen grupos que cumplan con los criterios del filtro HAVING."
        )

    # Generar el archivo CSV en memoria con BOM UTF-8 para apertura directa en Excel
    buffer = io.StringIO()
    buffer.write("\ufeff")
    columnas = list(filas[0].keys())
    writer = csv.DictWriter(buffer, fieldnames=columnas, delimiter=";")
    writer.writeheader()
    writer.writerows(filas)
    buffer.seek(0)

    headers = {
        "Content-Disposition": 'attachment; filename="reporte_ventas_asesores.csv"'
    }
    return StreamingResponse(
        iter([buffer.getvalue()]),
        media_type="text/csv; charset=utf-8",
        headers=headers
    )
