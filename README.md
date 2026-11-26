# Sistema de Gestión de Venta de Lotes

API backend para gestionar la venta de lotes de una inmobiliaria de Arequipa: proyectos de urbanización, lotes y precios, clientes, separaciones, ventas al contado y en cuotas, cobranza con recibos por oficina, comisiones de asesores y sueldos del personal.

## Integrantes y módulos

- Escobar Aguilar Mijael Pol (BlianN)
- Anci alvarez Ian Lucian enoc
- Calancho Llerena Diego Miguel

| Integrante | Módulo | Tablas |
|---|---|---|
| Ian Luciana Enoc Anci Alvarez | 1. Proyectos y Lotes | proyecto, sector, manzana, lote, precio_lote |
| Diego Miguel Calancho Llerena | 2. Ventas | persona, persona_natural, persona_juridica, asesor, separacion, venta, venta_participante |
| Mijael Pol Escobar Aguilar | 3. Cobranza y Comisiones | oficina, cuenta_bancaria, cuota, pago, pago_cuota, comision, pago_comision |
| Ian Luciana Enoc Anci Alvarez | 4. Personal y Sueldos | empleado, sueldo, pago_sueldo |
| Diego Miguel Calancho Llerena | Reportes | ventas por proyecto y asesor, exportable a CSV y Excel |

## Requisitos

- [Docker Desktop](https://www.docker.com/products/docker-desktop/), abierto y en ejecución.
- [Git](https://git-scm.com/).

## Cómo levantar el proyecto

```bash
git clone https://github.com/BlianN/Proyecto-Sistema-de-Gestion-de-venta-de-lotes.git
cd Proyecto-Sistema-de-Gestion-de-venta-de-lotes
docker compose up --build
```
- **Base de datos:** `localhost:5433`, base `inmobiliaria`, usuario `inmobiliaria`, contraseña `inmobiliaria`.

Comandos útiles:

| Para | Comando |
|---|---|
| Detener | `Ctrl + C`, o `docker compose down` |
| Borrar la base y crearla de nuevo con los datos de prueba | `docker compose down -v` y luego `docker compose up --build` |
| Abrir una consola SQL | `docker compose exec db psql -U inmobiliaria -d inmobiliaria` |
| Levantar también pgAdmin (en <http://localhost:5050>) | `docker compose --profile herramientas up --build` |

## Cómo se crea la base de datos

La primera vez que arranca el contenedor `db`, PostgreSQL ejecuta en orden alfabético los scripts de la carpeta `db/`. Ese orden resuelve las dependencias entre módulos:

| Archivo | Contenido |
|---|---|
| `01_m1_proyectos_lotes.sql` | Tablas del módulo 1 |
| `02_m2_ventas.sql` | Tablas del módulo 2 y triggers de personas y ventas |
| `03_m3_cobranza.sql` | Tablas del módulo 3, la FK venta → oficina y las funciones `fn_generar_cronograma` y `fn_recalcular_estado_cuotas` |
| `04_m4_personal.sql` | Tablas del módulo 4 |
| `11_datos_m1.sql` … `15_datos_m4.sql` | Datos de prueba: 5 proyectos, 35 lotes, 24 personas, 20 ventas, 92 cuotas, 55 recibos, etc. |

Para recrear la base sin Docker, se ejecutan los mismos archivos en ese orden con `psql -f`.

## Estructura

```
├── docker-compose.yml       PostgreSQL + API (+ pgAdmin opcional)
├── .env.example             Variables (puertos y credenciales)
├── db/                      Scripts SQL: tablas, restricciones, funciones, triggers y datos
└── api/
    ├── Dockerfile
    ├── requirements.txt     fastapi, uvicorn, psycopg (driver, sin ORM), openpyxl
    └── app/
        ├── main.py          Arranque; registra solo los routers de app/routers/
        ├── db.py            Conexión, transacciones (BEGIN/COMMIT/ROLLBACK) y errores
        ├── schemas/         Modelos de entrada de cada módulo
        └── routers/         Endpoints de cada módulo (SQL escrito a mano)
```

## Endpoints

Hay **CRUD completo de las 22 tablas** (listar, ver, crear, actualizar y eliminar). Los procesos que tocan 3 o más tablas en una sola transacción son:

| Endpoint | Módulo | Qué hace |
|---|---|---|
| `POST /proyectos/completo` | 1 | Crea el proyecto con sus sectores, manzanas, lotes y precios (inserción en cascada). Si falla un lote, se deshace todo. |
| `PUT /lotes/{id}/precio` | 1 | Cierra el precio vigente y registra el nuevo (historial de precios). |
| `POST /empleados/completo` | 4 | Contrata: persona + persona_natural + empleado + sueldo. |
| `PUT /empleados/{id}/sueldo` | 4 | Cierra el sueldo vigente y registra el nuevo. |
| `POST /separaciones/registrar` | 2 | Separa un lote: crea la separación y marca el lote como SEPARADO. |
| `POST /ventas/registrar` | 2 | Hace todo esto en una sola transacción:<br>• bloquea el lote y toma su precio vigente;<br>• inserta la venta y sus participantes;<br>• convierte la separación;<br>• cambia el estado del lote;<br>• genera el cronograma de cuotas. |
| `PUT /ventas/{id}/anular` | 2 | Anula una venta sin pagos, borra su cronograma y libera el lote. |
| `POST /pagos/registrar` | 3 | Hace todo esto en una sola transacción:<br>• emite el recibo con el correlativo de la oficina, bloqueado para que dos pagos simultáneos no repitan número;<br>• reparte el monto entre las cuotas más antiguas;<br>• actualiza los estados de las cuotas;<br>• si la venta queda pagada, cierra la venta y el lote. |
| `PUT /pagos/{id}/anular` | 3 | Anula un recibo y recalcula las cuotas, la venta y el lote. |
| `GET /estado-cuenta/{id_venta}` | 3 | Muestra el cronograma con lo pagado y el saldo de cada cuota. |

| Código | Cuándo |
|---|---|
| **409** | `UNIQUE` o `FOREIGN KEY` |
| **422** | `CHECK`, `NOT NULL` o reglas de los triggers |
| **404** | El registro no existe |
