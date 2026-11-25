import os
import csv
import io
from datetime import date, timedelta
from decimal import Decimal
from typing import Optional, Literal
import psycopg
from psycopg.rows import dict_row
from fastapi import APIRouter, FastAPI, HTTPException, Query
from fastapi.responses import StreamingResponse
from pydantic import BaseModel, Field

router = APIRouter(prefix='/api')

def get_connection():
    return psycopg.connect(os.environ['DATABASE_URL'], row_factory=dict_row)

def uno(cur, sql, params=()):
    cur.execute(sql, params)
    fila = cur.fetchone()
    if fila is None:
        raise HTTPException(404, 'Registro no encontrado o no elegible')
    return fila

class ProyectoCreate(BaseModel):
    codigo: str
    nombre: str
    departamento: str = 'Arequipa'
    provincia: str = 'Arequipa'
    distrito: str
    partida_registral: str
    hectareas: Decimal = Field(gt=0)
    tipo_sector: Literal['ZONA', 'ETAPA']
    sector: str
    manzana: str
    numero: int = Field(gt=0)
    area_m2: Decimal = Field(gt=0)
    perimetro_m: Decimal = Field(gt=0)
    frente_m: Decimal = Field(gt=0)
    fondo_m: Decimal = Field(gt=0)
    lado_izq_m: Decimal = Field(gt=0)
    lado_der_m: Decimal = Field(gt=0)
    precio: Decimal = Field(gt=0)

class CambioMonto(BaseModel):
    monto: Decimal = Field(gt=0)
    motivo: str = 'Actualizacion'

class EmpleadoCreate(BaseModel):
    direccion: str
    telefono: str
    correo: Optional[str] = None
    tipo_documento: str = 'DNI'
    nro_documento: str
    nombres: str
    apellido_paterno: str
    apellido_materno: Optional[str] = None
    nacionalidad: str = 'Peruana'
    codigo_oficina: str
    id_proyecto: Optional[int] = None
    cargo: str
    sueldo: Decimal = Field(gt=0)

class PagoCreate(BaseModel):
    id_empleado: int
    mes: int = Field(ge=1, le=12)
    anio: int = Field(ge=2000, le=9998)
    medio_pago: Literal['EFECTIVO', 'DEPOSITO', 'TRANSFERENCIA']

@router.post('/proyectos', status_code=201)
def registrar_proyecto(d: ProyectoCreate):
    with get_connection() as conn, conn.cursor() as cur:
        p = uno(cur, '''INSERT INTO proyecto(codigo,nombre,tipo_proyecto,departamento,provincia,distrito,partida_registral,hectareas,estado) VALUES (%s,%s,'URBANIZACION',%s,%s,%s,%s,%s,'EN_VENTA') RETURNING id_proyecto''', (d.codigo,d.nombre,d.departamento,d.provincia,d.distrito,d.partida_registral,d.hectareas))
        s = uno(cur, 'INSERT INTO sector(id_proyecto,tipo_sector,nombre) VALUES (%s,%s,%s) RETURNING id_sector', (p['id_proyecto'],d.tipo_sector,d.sector))
        m = uno(cur, 'INSERT INTO manzana(id_sector,codigo) VALUES (%s,%s) RETURNING id_manzana', (s['id_sector'],d.manzana))
        l = uno(cur, '''INSERT INTO lote(id_manzana,numero,tipo_lote,area_m2,perimetro_m,frente_m,fondo_m,lado_izq_m,lado_der_m) VALUES (%s,%s,'VENDIBLE',%s,%s,%s,%s,%s,%s) RETURNING id_lote''', (m['id_manzana'],d.numero,d.area_m2,d.perimetro_m,d.frente_m,d.fondo_m,d.lado_izq_m,d.lado_der_m))
        cur.execute("INSERT INTO precio_lote(id_lote,precio,fecha_desde,motivo) VALUES (%s,%s,CURRENT_DATE,'Precio inicial')", (l['id_lote'],d.precio))
        return {**p, **s, **m, **l}

@router.get('/lotes/{id_lote}')
def detalle_lote(id_lote: int):
    with get_connection() as conn, conn.cursor() as cur:
        return uno(cur, '''SELECT l.*, p.nombre AS proyecto,s.nombre AS sector,m.codigo AS manzana,pl.precio FROM lote l JOIN manzana m USING(id_manzana) JOIN sector s USING(id_sector) JOIN proyecto p USING(id_proyecto) LEFT JOIN precio_lote pl ON pl.id_lote=l.id_lote AND CURRENT_DATE BETWEEN pl.fecha_desde AND COALESCE(pl.fecha_hasta,'infinity'::date) WHERE l.id_lote=%s''', (id_lote,))

@router.get('/lotes/{id_lote}/historial')
def historial_lote(id_lote: int):
    with get_connection() as conn, conn.cursor() as cur:
        cur.execute('SELECT * FROM precio_lote WHERE id_lote=%s ORDER BY fecha_desde', (id_lote,))
        return cur.fetchall()

@router.put('/lotes/{id_lote}/precio')
def cambiar_precio(id_lote: int, d: CambioMonto):
    with get_connection() as conn, conn.cursor() as cur:
        uno(cur,"SELECT id_lote FROM lote WHERE id_lote=%s AND tipo_lote='VENDIBLE' FOR UPDATE",(id_lote,))
        anterior=uno(cur,'SELECT * FROM precio_lote WHERE id_lote=%s AND fecha_hasta IS NULL FOR UPDATE',(id_lote,))
        hoy=uno(cur,'SELECT CURRENT_DATE AS hoy')['hoy']
        if anterior['fecha_desde'] >= hoy:
            raise HTTPException(409,'El nuevo precio debe comenzar despues del anterior')
        cur.execute('UPDATE precio_lote SET fecha_hasta=CURRENT_DATE-1 WHERE id_precio=%s',(anterior['id_precio'],))
        return uno(cur,'INSERT INTO precio_lote(id_lote,precio,fecha_desde,motivo) VALUES (%s,%s,CURRENT_DATE,%s) RETURNING *',(id_lote,d.monto,d.motivo))

@router.delete('/lotes/{id_lote}')
def eliminar_lote(id_lote: int):
    with get_connection() as conn, conn.cursor() as cur:
        return uno(cur,"DELETE FROM lote WHERE id_lote=%s AND estado_lote='DISPONIBLE' AND NOT EXISTS (SELECT 1 FROM precio_lote WHERE id_lote=%s) RETURNING id_lote",(id_lote,id_lote))

@router.post('/empleados', status_code=201)
def registrar_empleado(d: EmpleadoCreate):
    with get_connection() as conn, conn.cursor() as cur:
        p=uno(cur,"INSERT INTO persona(tipo_persona,direccion,telefono,correo) VALUES ('N',%s,%s,%s) RETURNING id_persona",(d.direccion,d.telefono,d.correo))
        cur.execute('INSERT INTO persona_natural(id_persona,tipo_documento,nro_documento,nombres,apellido_paterno,apellido_materno,nacionalidad) VALUES (%s,%s,%s,%s,%s,%s,%s)',(p['id_persona'],d.tipo_documento,d.nro_documento,d.nombres,d.apellido_paterno,d.apellido_materno,d.nacionalidad))
        e=uno(cur,"INSERT INTO empleado(id_persona,codigo_oficina,id_proyecto,cargo,fecha_ingreso,estado) VALUES (%s,%s,%s,%s,CURRENT_DATE,'ACTIVO') RETURNING id_empleado",(p['id_persona'],d.codigo_oficina,d.id_proyecto,d.cargo))
        s=uno(cur,'INSERT INTO sueldo(id_empleado,monto_mensual,fecha_inicio) VALUES (%s,%s,CURRENT_DATE) RETURNING id_sueldo',(e['id_empleado'],d.sueldo))
        return {**p,**e,**s}

@router.get('/empleados/{id_empleado}')
def detalle_empleado(id_empleado: int):
    with get_connection() as conn, conn.cursor() as cur:
        return uno(cur,'''SELECT e.*,pn.nombres,pn.apellido_paterno,o.nombre AS oficina,p.nombre AS proyecto,s.monto_mensual FROM empleado e JOIN persona_natural pn USING(id_persona) JOIN oficina o USING(codigo_oficina) LEFT JOIN proyecto p USING(id_proyecto) LEFT JOIN sueldo s ON s.id_empleado=e.id_empleado AND s.fecha_fin IS NULL WHERE e.id_empleado=%s''',(id_empleado,))

@router.put('/empleados/{id_empleado}/sueldo')
def cambiar_sueldo(id_empleado: int,d: CambioMonto):
    with get_connection() as conn, conn.cursor() as cur:
        uno(cur,"SELECT id_empleado FROM empleado WHERE id_empleado=%s AND estado='ACTIVO' FOR UPDATE",(id_empleado,))
        s=uno(cur,'SELECT * FROM sueldo WHERE id_empleado=%s AND fecha_fin IS NULL FOR UPDATE',(id_empleado,))
        hoy=uno(cur,'SELECT CURRENT_DATE AS hoy')['hoy']
        if s['fecha_inicio'] >= hoy:
            raise HTTPException(409,'El nuevo sueldo debe comenzar despues del anterior')
        cur.execute('UPDATE sueldo SET fecha_fin=CURRENT_DATE-1 WHERE id_sueldo=%s',(s['id_sueldo'],))
        return uno(cur,'INSERT INTO sueldo(id_empleado,monto_mensual,fecha_inicio) VALUES (%s,%s,CURRENT_DATE) RETURNING *',(id_empleado,d.monto))

@router.put('/empleados/{id_empleado}/cesar')
def cesar_empleado(id_empleado: int):
    with get_connection() as conn, conn.cursor() as cur:
        e=uno(cur,"UPDATE empleado SET estado='CESADO',fecha_cese=CURRENT_DATE WHERE id_empleado=%s AND estado='ACTIVO' RETURNING id_empleado",(id_empleado,))
        cur.execute('UPDATE sueldo SET fecha_fin=CURRENT_DATE WHERE id_empleado=%s AND fecha_fin IS NULL',(id_empleado,))
        return e

@router.post('/sueldos/pagos',status_code=201)
def registrar_pago(d: PagoCreate):
    inicio=date(d.anio,d.mes,1)
    fin=date(d.anio+1,1,1) if d.mes==12 else date(d.anio,d.mes+1,1)
    fin-=timedelta(days=1)
    with get_connection() as conn, conn.cursor() as cur:
        uno(cur,'SELECT id_empleado FROM empleado WHERE id_empleado=%s FOR UPDATE',(d.id_empleado,))
        hoy=uno(cur,'SELECT CURRENT_DATE AS hoy')['hoy']
        if fin>hoy:
            raise HTTPException(400,'El periodo aun no termina')
        # Solo periodos completos con un sueldo; casos parciales requieren politica grupal.
        s=uno(cur,'''SELECT s.* FROM sueldo s JOIN empleado e USING(id_empleado) WHERE s.id_empleado=%s AND s.fecha_inicio<=%s AND (s.fecha_fin IS NULL OR s.fecha_fin>=%s) AND e.fecha_ingreso<=%s AND (e.fecha_cese IS NULL OR e.fecha_cese>=%s)''',(d.id_empleado,inicio,fin,inicio,fin))
        return uno(cur,'INSERT INTO pago_sueldo(id_sueldo,id_empleado,mes,anio,fecha_pago,monto,medio_pago) VALUES (%s,%s,%s,%s,CURRENT_DATE,%s,%s) RETURNING *',(s['id_sueldo'],d.id_empleado,d.mes,d.anio,s['monto_mensual'],d.medio_pago))

def exportar(filas,columnas,nombre):
    buffer=io.StringIO()
    buffer.write('\ufeff')
    writer=csv.DictWriter(buffer,fieldnames=columnas,delimiter=';')
    writer.writeheader()
    for fila in filas:
        writer.writerow({k: ("'"+v if isinstance(v,str) and v.lstrip().startswith(('=','+','-','@')) else v) for k,v in fila.items()})
    return StreamingResponse(iter([buffer.getvalue()]),media_type='text/csv; charset=utf-8',headers={'Content-Disposition':f'attachment; filename="{nombre}.csv"'})

@router.get('/reportes/lotes/exportar')
def reporte_lotes(minimo: int=Query(1,ge=1)):
    with get_connection() as conn, conn.cursor() as cur:
        cur.execute('''SELECT p.codigo,p.nombre AS proyecto,COUNT(*) AS lotes_disponibles,SUM(l.area_m2) AS area_total,ROUND(AVG(pl.precio),2) AS precio_promedio,SUM(pl.precio) AS valor_total FROM proyecto p JOIN sector s USING(id_proyecto) JOIN manzana m USING(id_sector) JOIN lote l USING(id_manzana) JOIN precio_lote pl ON pl.id_lote=l.id_lote AND CURRENT_DATE BETWEEN pl.fecha_desde AND COALESCE(pl.fecha_hasta,'infinity'::date) WHERE l.tipo_lote='VENDIBLE' AND l.estado_lote='DISPONIBLE' GROUP BY p.id_proyecto,p.codigo,p.nombre HAVING COUNT(*) >= %s ORDER BY p.codigo''',(minimo,))
        return exportar(cur.fetchall(),[c.name for c in cur.description],'reporte_lotes')

@router.get('/reportes/sueldos/exportar')
def reporte_sueldos(anio: int=Query(2026,ge=2000),mes: int=Query(9,ge=1,le=12),minimo: Decimal=Query(0,ge=0)):
    with get_connection() as conn, conn.cursor() as cur:
        cur.execute('''SELECT o.codigo_oficina,o.nombre AS oficina,ps.anio,ps.mes,COUNT(DISTINCT e.id_empleado) AS empleados_pagados,ROUND(AVG(ps.monto),2) AS promedio,SUM(ps.monto) AS total_pagado FROM pago_sueldo ps JOIN empleado e USING(id_empleado) JOIN sueldo s ON s.id_sueldo=ps.id_sueldo AND s.id_empleado=ps.id_empleado JOIN oficina o ON o.codigo_oficina=e.codigo_oficina WHERE ps.anio=%s AND ps.mes=%s GROUP BY o.codigo_oficina,o.nombre,ps.anio,ps.mes HAVING SUM(ps.monto)>=%s ORDER BY total_pagado DESC''',(anio,mes,minimo))
        return exportar(cur.fetchall(),[c.name for c in cur.description],'reporte_sueldos')

# Para probar individualmente. En el main.py grupal basta importar router.
app=FastAPI(title='Modulos 1 y 4')
app.include_router(router)

@app.exception_handler(psycopg.IntegrityError)
async def error_integridad(request, exc):
    from fastapi.responses import JSONResponse
    return JSONResponse(status_code=409,content={'detail':'La operacion incumple una restriccion de integridad'})
