-- =========================================================
-- 02_dml_poblado_datos.sql
-- Módulos 1 (Proyectos y Lotes) y 4 (Personal y Sueldos)
-- =========================================================
-- ===== MÓDULO 1: Proyectos y Lotes =====

-- proyecto
INSERT INTO proyecto (codigo, nombre, tipo_proyecto, departamento, provincia, distrito, partida_registral, hectareas, estado) VALUES
('VGR-01', 'Valle Grande',        'URBANIZACION', 'Arequipa', 'Arequipa', 'Chiguata',  'P06012345', 12.50, 'EN_VENTA'),
('CLV-01', 'Los Claveles',        'URBANIZACION', 'Arequipa', 'Arequipa', 'Chiguata',  'P06012346',  8.30, 'EN_VENTA'),
('ALM-01', 'Altos del Misti',     'URBANIZACION', 'Arequipa', 'Arequipa', 'Characato', 'P06012347', 15.00, 'EN_VENTA'),
('MCH-01', 'Mirador de Chiguata', 'URBANIZACION', 'Arequipa', 'Arequipa', 'Chiguata',  'P06012348',  6.75, 'PLANIFICACION'),
('VSJ-01', 'Villa San José',      'URBANIZACION', 'Arequipa', 'Arequipa', 'Sachaca',   'P06012349',  9.20, 'EN_VENTA');
-- sector
INSERT INTO sector (id_proyecto, tipo_sector, nombre) VALUES
(1, 'ZONA',  'A'),
(1, 'ZONA',  'B'),
(1, 'ZONA',  'C'),
(2, 'ETAPA', 'I'),
(2, 'ETAPA', 'II');
-- manzana
INSERT INTO manzana (id_sector, codigo) VALUES
(1, 'A'),
(1, 'B1'),
(2, 'D2'),
(3, 'Ñ'),
(4, 'C'),
(5, 'E');
-- lote
INSERT INTO lote (id_manzana, numero, tipo_lote, estado_lote, area_m2, perimetro_m, frente_m, fondo_m, lado_izq_m, lado_der_m,
                  colindante_frente, colindante_fondo, colindante_izq, colindante_der, partida_registral,
                  es_esquina, frente_parque, sobre_avenida) VALUES
(1, 1, 'VENDIBLE', 'DISPONIBLE', 120.00, 46.00,  8.00, 15.00, 15.00, 15.00,
    'Calle 1', 'Lote 10', 'Calle 2', 'Lote 2', 'P06100001', TRUE,  FALSE, FALSE),
(1, 2, 'VENDIBLE', 'DISPONIBLE', 120.00, 46.00,  8.00, 15.00, 15.00, 15.00,
    'Calle 1', 'Lote 11', 'Lote 1', 'Lote 3', 'P06100002', FALSE, FALSE, FALSE),
(2, 1, 'VENDIBLE', 'DISPONIBLE', 200.00, 60.00, 10.00, 20.00, 20.00, 20.00,
    'Parque Central', 'Lote 12', 'Calle 3', 'Lote 2', 'P06100003', FALSE, TRUE, FALSE),
(3, 5, 'VENDIBLE', 'DISPONIBLE', 162.00, 54.00,  9.00, 18.00, 18.00, 18.00,
    'Av. Principal', 'Lote 9', 'Lote 4', 'Lote 6', 'P06100004', FALSE, FALSE, TRUE),
(4, 3, 'FCMP',     'BLOQUEADO',  300.00, 70.00, 15.00, 20.00, 20.00, 20.00,
    'Calle 5', 'Área verde', 'Lote 2', 'Lote 4', 'P06100005', FALSE, FALSE, FALSE),
(5, 1, 'VENDIBLE', 'DISPONIBLE', 150.00, 50.00, 10.00, 15.00, 15.00, 15.00,
    'Calle 6', 'Lote 8', 'Calle 7', 'Lote 2', 'P06100006', TRUE,  FALSE, FALSE);
-- precio_lote
INSERT INTO precio_lote (id_lote, precio, fecha_desde, fecha_hasta, motivo) VALUES
(1, 35000.00, '2025-01-01', '2026-06-30', 'Precio de lanzamiento'),
(1, 38000.00, '2026-07-01', NULL,         'Aumento por pocos lotes disponibles'),
(2, 36000.00, '2025-01-01', NULL,         'Precio de lanzamiento'),
(3, 62000.00, '2025-01-01', NULL,         'Precio de lanzamiento'),
(4, 52000.00, '2025-01-01', NULL,         'Precio de lanzamiento'),
(6, 48000.00, '2025-06-01', NULL,         'Precio de lanzamiento');

-- empleado
INSERT INTO empleado (id_persona, codigo_oficina, id_proyecto, cargo, fecha_ingreso, fecha_cese, estado) VALUES
(11, 'OFIC-CRDO', NULL, 'GERENTE',    '2024-03-01', NULL, 'ACTIVO'),
(12, 'OFIC-CRDO', NULL, 'SECRETARIA', '2024-05-15', NULL, 'ACTIVO'),
(13, 'OFIC-LL',   NULL, 'GESTION',    '2025-01-10', NULL, 'ACTIVO'),
(14, 'OFIC-MGG',  1,    'GUARDIA',    '2025-02-01', NULL, 'ACTIVO'),
(15, 'OFIC-LL',   2,    'LIMPIEZA',   '2025-06-01', NULL, 'ACTIVO');
-- sueldo
INSERT INTO sueldo (id_empleado, monto_mensual, fecha_inicio, fecha_fin) VALUES
(1, 4500.00, '2024-03-01', '2025-12-31'),
(1, 5000.00, '2026-01-01', NULL),
(2, 1800.00, '2024-05-15', NULL),
(3, 2500.00, '2025-01-10', NULL),
(4, 1500.00, '2025-02-01', NULL),
(5, 1300.00, '2025-06-01', NULL);
-- pago_sueldo
INSERT INTO pago_sueldo (id_sueldo, id_empleado, mes, anio, fecha_pago, monto, medio_pago) VALUES
(2, 1,  9, 2026, '2026-09-30', 5000.00, 'TRANSFERENCIA'),
(3, 2,  9, 2026, '2026-09-30', 1800.00, 'TRANSFERENCIA'),
(4, 3,  9, 2026, '2026-09-30', 2500.00, 'TRANSFERENCIA'),
(5, 4,  9, 2026, '2026-09-30', 1500.00, 'EFECTIVO'),
(6, 5,  9, 2026, '2026-09-30', 1300.00, 'EFECTIVO'),
(2, 1, 10, 2026, '2026-10-31', 5000.00, 'TRANSFERENCIA');
-- =========================================================
-- UPDATE - MÓDULO 1: Proyectos y Lotes
-- =========================================================

-- proyecto: el proyecto en planificación pasa a venta
UPDATE proyecto SET estado = 'EN_VENTA' WHERE codigo = 'MCH-01';

-- sector: renumeración de una etapa
UPDATE sector SET nombre = 'III' WHERE id_proyecto = 2 AND nombre = 'II';

-- manzana: corrección de código
UPDATE manzana SET codigo = 'B2' WHERE id_sector = 1 AND codigo = 'B1';

-- lote: el lote 1 de la manzana A se vendió en cuotas
UPDATE lote SET estado_lote = 'EN_CUOTAS' WHERE id_manzana = 1 AND numero = 1;

-- precio_lote: cambio de precio (RN-04: se cierra el vigente y se crea uno nuevo)
BEGIN;
UPDATE precio_lote SET fecha_hasta = '2026-10-31'
WHERE id_lote = 3 AND fecha_hasta IS NULL;
INSERT INTO precio_lote (id_lote, precio, fecha_desde, fecha_hasta, motivo)
VALUES (3, 65000.00, '2026-11-01', NULL, 'Aumento por lote frente a parque');
COMMIT;
