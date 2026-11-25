# API REST Inmobiliaria - Entregable 1

API desarrollada con **Python (FastAPI)** y **PostgreSQL** que implementa operaciones CRUD complejas sobre 3 o más tablas relacionadas mediante transacciones explícitas.

## Endpoints implementados
- **POST `/api/ventas`**: Registra una venta completa afectando 4 tablas (`venta`, `venta_participante`, `lote`, `separacion`).
- **POST `/api/clientes/juridicos`**: Registra una empresa y su representante legal en 3 tablas (`persona`, `persona_natural`, `persona_juridica`).
- **PUT `/api/ventas/{id_venta}/anular`**: Anula una venta y libera el lote vinculado (`venta`, `lote`, `separacion`).
- **GET `/api/ventas/{id_venta}`**: Consulta consolidada cruzando 6 tablas relacionadas.

## Instalación y ejecución
1. Ejecutar `database.sql` en PostgreSQL.
2. Configurar las credenciales de conexión en `main.py`.
3. Instalar dependencias:
   ```bash
   pip install -r requirements.txt
