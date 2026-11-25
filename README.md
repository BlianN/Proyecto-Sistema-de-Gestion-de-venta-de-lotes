# API REST Inmobiliaria - Entregable 1

API desarrollada con Python (FastAPI) y PostgreSQL
utilizando SQL puro, sin ORM.

## Módulos desarrollados

### Módulo 1: Proyectos y Lotes

- proyecto
- sector
- manzana
- lote
- precio_lote

### Módulo 4: Personal y Sueldos

- empleado
- sueldo
- pago_sueldo

## Operaciones CRUD complejas

### Proyectos y Lotes

- POST `/api/proyectos`: Registra un proyecto, sector,
  manzana, lote y precio inicial en 5 tablas relacionadas.
- GET `/api/lotes/{id_lote}`: Consulta la información
  completa de un lote y su precio.
- PUT `/api/lotes/{id_lote}/precio`: Actualiza el precio
  del lote conservando su historial.

### Personal y Sueldos

- POST `/api/empleados`: Registra una persona natural,
  empleado y sueldo inicial.
- GET `/api/empleados/{id_empleado}`: Consulta los datos
  del empleado, oficina, proyecto y sueldo.
- PUT `/api/empleados/{id_empleado}/sueldo`: Actualiza
  el sueldo conservando su historial.
- PUT `/api/empleados/{id_empleado}/cesar`: Registra
  el cese del empleado y cierra su sueldo vigente.
- POST `/api/sueldos/pagos`: Registra el pago mensual
  de un empleado.

## Reportes y exportación

Los reportes utilizan consultas SQL con JOIN, GROUP BY,
HAVING, COUNT, SUM y AVG.

- GET `/api/reportes/lotes/exportar`: Exporta un reporte
  de disponibilidad, área y precios de lotes por proyecto.
- GET `/api/reportes/sueldos/exportar`: Exporta un reporte
  de egresos por sueldos agrupados por oficina y periodo.

Ambos reportes permiten descargar archivos CSV
compatibles con Excel.

## Integridad de datos

- Uso de PRIMARY KEY y FOREIGN KEY.
- Restricciones CHECK, UNIQUE y NOT NULL.
- Un solo precio vigente por lote.
- Un solo sueldo vigente por empleado.
- Un solo pago de sueldo por periodo.
- Validación de lotes no vendibles.
- Conservación del historial de precios y sueldos.

## Tecnologías utilizadas

- Python
- FastAPI
- PostgreSQL
- Psycopg
- Pydantic
- Uvicorn

## Instalación y ejecución

1. Crear las tablas correspondientes en PostgreSQL.
2. Crear y poblar las tablas de los demás módulos
   necesarias para las relaciones.
3. Ejecutar el script de poblado de datos.
4. Configurar la conexión a PostgreSQL.
5. Instalar las dependencias:

   ```bash
   pip install -r requerimientos.txt
   ```

6. Integrar el router de modulos_1_4.py en el main.py
   del proyecto grupal.

   ```python
   from modulos_1_4 import router

   app.include_router(router)
   ```

7. Ejecutar la API:

   ```bash
   uvicorn main:app --reload
   ```

8. Acceder a la documentación de los endpoints:

   http://127.0.0.1:8000/docs

## Estado del desarrollo

Código correspondiente al Entregable 1.
Pendiente de pruebas de integración con los demás
módulos del proyecto.
