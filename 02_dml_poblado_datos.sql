-- =====================================================================
-- PARTE 1: INSERT
-- =====================================================================

-- ---------------------------------------------------------------------
-- MÓDULO 1: PROYECTOS Y LOTES
-- ---------------------------------------------------------------------

BEGIN;
INSERT INTO proyecto (nombre, tipo_proyecto, departamento, provincia, distrito,
                      partida_registral, hectareas, estado)
VALUES
    ('Valle Grande',    'URBANIZACION', 'Arequipa', 'Arequipa', 'Chiguata',        'P06000101', 11.00, 'EN_VENTA'),
    ('Los Claveles',    'URBANIZACION', 'Arequipa', 'Arequipa', 'Cerro Colorado',  'P06000102',  8.50, 'EN_VENTA'),
    ('Villa Hermosa',   'URBANIZACION', 'Arequipa', 'Arequipa', 'Paucarpata',      'P06000103',  5.20, 'CERRADO'),
    ('Las Palmeras',    'URBANIZACION', 'Arequipa', 'Arequipa', 'Characato',       'P06000104', 14.75, 'EN_VENTA'),
    ('Mirador del Sol', 'URBANIZACION', 'Arequipa', 'Arequipa', 'Mariano Melgar',  'P06000105',  9.30, 'PLANIFICACION')
RETURNING id_proyecto, nombre;
COMMIT;

BEGIN;
INSERT INTO sector (id_proyecto, tipo_sector, nombre)
VALUES
    (1, 'ZONA',  'A'),
    (1, 'ZONA',  'B'),
    (1, 'ZONA',  'C'),
    (2, 'ETAPA', 'I'),
    (2, 'ETAPA', 'II');
COMMIT;

BEGIN;
INSERT INTO manzana (id_sector, codigo)
VALUES
    (1, 'A'),
    (1, 'B'),
    (2, 'C'),
    (2, 'D'),
    (3, 'E'),
    (4, 'B1'),
    (5, 'D2'),
    (5, 'Ñ');
COMMIT;

BEGIN;
INSERT INTO lote (id_manzana, numero, tipo_lote, estado_lote,
                  area_m2, perimetro_m, frente_m, fondo_m, lado_izq_m, lado_der_m,
                  colinda_frente, colinda_fondo, colinda_izq, colinda_der,
                  partida_registral, es_esquina, frente_parque, en_avenida)
VALUES
    (1, 1, 'VENDIBLE',   'ESCRITURADO', 200.00, 60.00, 10.00, 10.00, 20.00, 20.00,
        'Calle 1', 'Propiedad de terceros', 'Av. Los Cedros', 'Lote 2 mz. A',   'P06-A-01', TRUE,  FALSE, FALSE),
    (1, 2, 'VENDIBLE',   'EN_CUOTAS',   200.00, 60.00, 10.00, 10.00, 20.00, 20.00,
        'Calle 1', 'Propiedad de terceros', 'Lote 1 mz. A',   'Lote 3 mz. A',   'P06-A-02', FALSE, FALSE, FALSE),
    (1, 3, 'VENDIBLE',   'EN_CUOTAS',   160.00, 56.00,  8.00,  8.00, 20.00, 20.00,
        'Calle 1', 'Propiedad de terceros', 'Lote 2 mz. A',   'Lote 4 mz. A',   'P06-A-03', FALSE, FALSE, FALSE),
    (1, 4, 'VENDIBLE',   'EN_CUOTAS',   160.00, 56.00,  8.00,  8.00, 20.00, 20.00,
        'Calle 1', 'Propiedad de terceros', 'Lote 3 mz. A',   'Calle 2',        'P06-A-04', TRUE,  FALSE, FALSE),
    (2, 1, 'VENDIBLE',   'EN_CUOTAS',   150.00, 50.00, 10.00, 10.00, 15.00, 15.00,
        'Parque central', 'Lote 1 mz. C', 'Calle 2', 'Lote 2 mz. B',            'P06-B-01', FALSE, TRUE,  FALSE),
    (2, 2, 'VENDIBLE',   'SEPARADO',    150.00, 50.00, 10.00, 10.00, 15.00, 15.00,
        'Parque central', 'Lote 2 mz. C', 'Lote 1 mz. B', 'Lote 3 mz. B',       'P06-B-02', FALSE, TRUE,  FALSE),
    (2, 3, 'VENDIBLE',   'SEPARADO',    180.00, 54.00, 12.00, 12.00, 15.00, 15.00,
        'Av. Principal', 'Lote 3 mz. C', 'Lote 2 mz. B', 'Propiedad de terceros','P06-B-03', TRUE,  FALSE, TRUE),
    (3, 1, 'VENDIBLE',   'DISPONIBLE',  200.00, 60.00, 10.00, 10.00, 20.00, 20.00,
        'Calle 3', 'Lote 1 mz. B', 'Calle 4', 'Lote 2 mz. C',                   'P06-C-01', FALSE, FALSE, FALSE),
    (3, 2, 'AREA_VERDE', 'BLOQUEADO',   500.00, 90.00, 20.00, 20.00, 25.00, 25.00,
        'Calle 3', 'Lote 2 mz. B', 'Lote 1 mz. C', 'Calle 5',                   NULL,       FALSE, FALSE, FALSE),
    (4, 1, 'FCMP',       'BLOQUEADO',   300.00, 70.00, 15.00, 15.00, 20.00, 20.00,
        'Calle 6', 'Calle 7', 'Calle 8', 'Calle 9',                             NULL,       FALSE, FALSE, FALSE),
    (6, 1, 'VENDIBLE',   'DISPONIBLE',  162.00, 54.00,  9.00,  9.00, 18.00, 18.00,
        'Pasaje 1', 'Propiedad de terceros', 'Lote 2 mz. B1', 'Pasaje 2',       'P06-B1-01', FALSE, FALSE, FALSE),
    (7, 1, 'VENDIBLE',   'SEPARADO',    162.00, 54.00,  9.00,  9.00, 18.00, 18.00,
        'Av. Los Claveles', 'Propiedad de terceros', 'Pasaje 3', 'Lote 2 mz. D2','P06-D2-01', TRUE,  FALSE, TRUE);
COMMIT;

BEGIN;
INSERT INTO precio_lote (id_lote, precio, fecha_inicio, fecha_fin, motivo)
VALUES
    (1, 45000.00, '2025-01-01', '2026-02-28', 'Precio de lanzamiento'),
    (1, 48000.00, '2026-03-01', NULL,         'Reajuste: quedan pocos lotes en la manzana'),
    (2, 45000.00, '2025-01-01', NULL,         'Precio de lanzamiento'),
    (3, 36000.00, '2025-01-01', NULL,         'Precio de lanzamiento'),
    (4, 36000.00, '2025-01-01', NULL,         'Precio de lanzamiento'),
    (5, 40000.00, '2025-01-01', NULL,         'Precio de lanzamiento'),
    (6, 40000.00, '2025-01-01', NULL,         'Precio de lanzamiento'),
    (7, 50000.00, '2025-01-01', NULL,         'Lote en avenida'),
    (8, 45000.00, '2025-01-01', NULL,         'Precio de lanzamiento'),
    (11, 38000.00, '2025-06-01', NULL,        'Precio de lanzamiento'),
    (12, 38000.00, '2025-06-01', NULL,        'Lote en esquina y avenida');
COMMIT;

-- ---------------------------------------------------------------------
-- MÓDULO 2: VENTAS (personas, asesores)
-- ---------------------------------------------------------------------

BEGIN;
INSERT INTO persona (tipo_persona, direccion, telefono, telefono_2, correo)
VALUES
    ('N', 'Calle Mercaderes 214, Cercado, Arequipa',                  '958100101', NULL,        'rosa.quispe@correo.pe'),
    ('N', 'Urb. Los Álamos B-12, Cayma',                              '958100102', '054251102', 'carlos.huaman@correo.pe'),
    ('N', 'Av. Venezuela 845, Arequipa',                              '958100103', NULL,        'lucia.flores@correo.pe'),
    ('N', 'Calle Jerusalén 530, Arequipa',                            '958100104', NULL,        NULL),
    ('N', 'Ciudad Municipal Mz C Lt 7, Cerro Colorado',               '958100105', NULL,        'jorge.salas@correo.pe'),
    ('N', 'Av. Goyeneche 310, Arequipa',                              '958100106', NULL,        'ana.valdivia@correo.pe'),
    ('N', 'Calle Ugarte 120, Yanahuara',                              '958100107', NULL,        NULL),
    ('N', 'Urb. Cabo Verde Mz D Lt 4, Cayma',                         '958100108', NULL,        'daniela.caceres@correo.pe'),
    ('N', 'Calle Mariano Melgar 77, Paucarpata',                      '958100109', NULL,        'luis.mendoza@correo.pe'),
    ('N', 'Av. Ejército 1020, Yanahuara',                             '958100110', NULL,        'ricardo.bejar@correo.pe'),
    ('N', 'Calle San Francisco 301, Arequipa',                        '958100111', NULL,        'karla.zevallos@correo.pe'),
    ('N', 'Asoc. Villa Hermosa Mz F Lt 2, Paucarpata',                '958100112', NULL,        NULL),
    ('N', 'AA.HH. Alto Misti Mz G Lt 9, Miraflores',                  '958100113', NULL,        NULL),
    ('N', 'Urb. La Campiña Mz A Lt 15, Paucarpata',                   '958100114', NULL,        'patricia.vera@correo.pe'),
    ('J', 'Av. Dolores 450 Of. 202, J. L. Bustamante y Rivero',       '054380115', '958100115', 'contacto@asesoresandes.pe'),
    ('J', 'Calle Palacio Viejo 108 Of. 5, Cercado',                   '054380116', NULL,        'info@volcanpropiedades.pe'),
    ('J', 'Av. Parra 612, Cercado',                                   '054380117', NULL,        'ventas@constructoramisti.pe'),
    ('J', 'Parque Industrial Río Seco Mz B Lt 3, Cerro Colorado',     '054380118', NULL,        'admin@inversioneschachani.pe'),
    ('J', 'Av. Jesús 240, Cercado',                                   '054380119', NULL,        'servicios@yanahuarasac.pe');

INSERT INTO persona_natural (id_persona, tipo_documento, nro_documento, nombres,
                             apellido_paterno, apellido_materno, nacionalidad,
                             estado_civil, ocupacion)
VALUES
    (1,  'DNI', '45120001', 'Rosa Elena',     'Quispe',    'Mamani',    'Peruana',    'SOLTERA',     'Comerciante'),
    (2,  'DNI', '45120002', 'Carlos Alberto', 'Huamán',    'Condori',   'Peruana',    'CASADO',      'Ingeniero civil'),
    (3,  'DNI', '45120003', 'Lucía Fernanda', 'Flores',    'Ccopa',     'Peruana',    'SOLTERA',     'Contadora'),
    (4,  'DNI', '45120004', 'Miguel Ángel',   'Paredes',   'Gutiérrez', 'Peruana',    'SOLTERO',     'Docente'),
    (5,  'DNI', '45120005', 'Jorge Luis',     'Salas',     'Rondón',    'Peruana',    'CASADO',      'Transportista'),
    (6,  'DNI', '45120006', 'Ana María',      'Valdivia',  'Cutipa',    'Peruana',    'CONVIVIENTE', 'Enfermera'),
    (7,  'DNI', '45120007', 'Pedro Pablo',    'Choque',    'Apaza',     'Peruana',    'CASADO',      'Empresario'),
    (8,  'DNI', '45120008', 'Daniela Sofía',  'Cáceres',   'Linares',   'Peruana',    'SOLTERA',     'Asesora inmobiliaria'),
    (9,  'CE',  '001234567','Luis Fernando',  'Mendoza',   NULL,        'Colombiana', 'SOLTERO',     'Asesor inmobiliario'),
    (10, 'DNI', '45120010', 'Ricardo',        'Béjar',     'Salinas',   'Peruana',    'CASADO',      'Administrador'),
    (11, 'DNI', '45120011', 'Karla Nicole',   'Zevallos',  'Núñez',     'Peruana',    'SOLTERA',     'Secretaria'),
    (12, 'DNI', '45120012', 'Juan Carlos',    'Mamani',    'Turpo',     'Peruana',    'CASADO',      'Guardián'),
    (13, 'DNI', '45120013', 'Elsa',           'Condori',   'Huanca',    'Peruana',    'VIUDA',       'Personal de limpieza'),
    (14, 'DNI', '45120014', 'Patricia',       'Vera',      'Delgado',   'Peruana',    'SOLTERA',     'Asistente administrativa');

INSERT INTO persona_juridica (id_persona, id_representante, ruc, razon_social)
VALUES
    (15, 1, '20601234561', 'Asesores Inmobiliarios Andes S.A.C.'),
    (16, 8, '20601234562', 'Agencia Volcán Propiedades S.R.L.'),
    (17, 2, '20601234563', 'Constructora Misti E.I.R.L.'),
    (18, 4, '20601234564', 'Inversiones Chachani S.A.C.'),
    (19, 5, '20601234565', 'Servicios Yanahuara S.A.C.');
COMMIT;

BEGIN;
INSERT INTO asesor (id_persona, fecha_alta, estado)
VALUES
    (8,  '2024-03-01', 'ACTIVO'),
    (9,  '2024-06-15', 'ACTIVO'),
    (15, '2024-09-01', 'ACTIVO'),
    (16, '2025-01-10', 'ACTIVO'),
    (19, '2025-02-20', 'INACTIVO');
COMMIT;

-- ---------------------------------------------------------------------
-- MÓDULO 3: COBRANZA Y COMISIONES (oficinas, cuentas)
-- ---------------------------------------------------------------------

BEGIN;
INSERT INTO oficina (codigo_oficina, nombre, distrito, direccion, es_central)
VALUES
    ('OFIC-CRDO', 'Cercado',      'Cercado',        'C.C. Los Portales, Calle Nueva 209 Of. 228', TRUE),
    ('OFIC-LL',   'Llamagas',     'Cerro Colorado', 'Zona Llamagas, Cerro Colorado',              FALSE),
    ('OFIC-MGG',  'Miguel Grau',  'Paucarpata',     'Av. Miguel Grau 100, ref. Óvalo Grau',       FALSE),
    ('OFIC-YAN',  'Yanahuara',    'Yanahuara',      'Av. Ejército 500 (dirección de ejemplo)',    FALSE),
    ('OFIC-CAY',  'Cayma',        'Cayma',          'Av. Cayma 300 (dirección de ejemplo)',       FALSE);
COMMIT;

BEGIN;
INSERT INTO cuenta_bancaria (banco, nro_cuenta, cci, moneda, estado)
VALUES
    ('BCP',           '191-2345678-0-11', '00219100234567801112', 'PEN', 'ACTIVA'),
    ('BCP',           '191-8765432-1-22', '00219100876543212215', 'USD', 'ACTIVA'),
    ('Caja Arequipa', '110-0123456789',   '81600011001234567891', 'PEN', 'ACTIVA'),
    ('Caja Arequipa', '110-9876543210',   '81600011009876543210', 'USD', 'ACTIVA'),
    ('Interbank',     '898-3001234567',   '00389800300123456748', 'PEN', 'ACTIVA');
COMMIT;

-- ---------------------------------------------------------------------
-- MÓDULO 4: PERSONAL Y SUELDOS
-- ---------------------------------------------------------------------

BEGIN;
INSERT INTO empleado (id_persona, codigo_oficina, id_proyecto, cargo, fecha_ingreso, fecha_cese, estado)
VALUES
    (10, 'OFIC-CRDO', NULL, 'Gerente general',        '2020-02-01', NULL, 'ACTIVO'),
    (11, 'OFIC-CRDO', NULL, 'Secretaria',             '2022-05-16', NULL, 'ACTIVO'),
    (12, 'OFIC-MGG',  1,    'Guardia',                '2023-03-01', NULL, 'ACTIVO'),
    (13, 'OFIC-CRDO', 2,    'Personal de limpieza',   '2024-01-15', NULL, 'ACTIVO'),
    (14, 'OFIC-LL',   NULL, 'Personal de gestión',    '2025-02-03', NULL, 'ACTIVO');
COMMIT;

BEGIN;
INSERT INTO sueldo (id_empleado, monto_mensual, fecha_inicio, fecha_fin)
VALUES
    (1, 4500.00, '2020-02-01', '2023-12-31'),
    (1, 5500.00, '2024-01-01', NULL),
    (2, 1800.00, '2022-05-16', NULL),
    (3, 1500.00, '2023-03-01', NULL),
    (4, 1130.00, '2024-01-16', NULL),
    (5, 2200.00, '2025-02-03', NULL);
COMMIT;

BEGIN;
INSERT INTO pago_sueldo (id_empleado, periodo, fecha_pago, monto, medio_pago)
SELECT s.id_empleado, p.periodo, p.fecha_pago, s.monto_mensual, 'TRANSFERENCIA'
FROM sueldo s
CROSS JOIN (VALUES ('2026-09', DATE '2026-09-30'),
                   ('2026-10', DATE '2026-10-31')) AS p(periodo, fecha_pago)
WHERE s.fecha_fin IS NULL;
COMMIT;

-- ---------------------------------------------------------------------
-- MÓDULO 2: SEPARACIONES Y VENTAS
-- ---------------------------------------------------------------------

BEGIN;
INSERT INTO separacion (id_lote, id_persona, id_asesor, fecha_hora, monto,
                        fecha_vencimiento, estado, destino_monto)
VALUES
    (2,  2, 1,    '2026-05-02 10:30', 100.00, '2026-05-09', 'CONVERTIDA', 'PRECIO'),
    (5,  4, 2,    '2026-08-20 09:15', 200.00, '2026-08-27', 'CONVERTIDA', 'ESCRITURA'),
    (6,  6, NULL, '2026-11-02 11:00', 100.00, '2026-11-09', 'VIGENTE',    NULL),
    (7,  7, 3,    '2026-09-10 16:20', 150.00, '2026-09-17', 'VIGENTE',    NULL),
    (8,  1, 4,    '2026-10-01 12:00', 100.00, '2026-10-08', 'RETIRADA',   NULL),
    (12, 3, 1,    '2026-11-04 15:00', 300.00, '2026-11-11', 'VIGENTE',    NULL);
COMMIT;

BEGIN;
INSERT INTO venta (id_lote, id_separacion, id_asesor, codigo_oficina, fecha_venta, modalidad,
                   precio_lista, descuento, inicial, plazo_meses, dia_pago,
                   fecha_primera_cuota, estado_venta, motivo_excepcion)
VALUES
    (1, NULL, 4,    'OFIC-CRDO', '2026-03-10', 'CONTADO', 48000.00, 2000.00, 46000.00, NULL, NULL, NULL,         'CANCELADA', NULL),
    (2, 1,    1,    'OFIC-CRDO', '2026-05-06', 'CUOTAS',  45000.00,    0.00, 22500.00, 12,   5,    '2026-06-05', 'ACTIVA',    NULL),
    (3, NULL, 3,    'OFIC-LL',   '2026-07-20', 'CUOTAS',  36000.00,    0.00, 18000.00,  6,   20,   '2026-08-20', 'ACTIVA',    NULL),
    (4, NULL, NULL, 'OFIC-MGG',  '2026-04-10', 'CUOTAS',  36000.00, 2000.00, 19000.00,  3,   10,   '2026-05-10', 'ACTIVA',    NULL),
    (5, 2,    2,    'OFIC-CRDO', '2026-08-25', 'CUOTAS',  40000.00,    0.00, 12000.00, 14,   15,   '2026-09-15', 'ACTIVA',
        'Excepción aprobada por gerencia: inicial menor al 50 % y plazo de 14 meses');

INSERT INTO venta_participante (id_venta, id_persona, rol)
VALUES
    (1, 3,  'TITULAR'),
    (2, 2,  'TITULAR'),
    (2, 1,  'FINANCIADOR'),
    (3, 5,  'TITULAR'),
    (4, 18, 'TITULAR'),
    (5, 4,  'TITULAR'),
    (5, 6,  'COPROPIETARIO'),
    (5, 7,  'FINANCIADOR');
COMMIT;

-- ---------------------------------------------------------------------
-- MÓDULO 3: CUOTAS, PAGOS Y COMISIONES
-- ---------------------------------------------------------------------

BEGIN;
INSERT INTO cuota (id_venta, nro_cuota, fecha_vencimiento, monto, estado_cuota)
SELECT c.id_venta,
       n,
       (c.primera + (n - 1) * INTERVAL '1 month')::date,
       c.monto,
       CASE WHEN n <= c.pagadas             THEN 'PAGADA'
            WHEN c.id_venta = 5 AND n = 2   THEN 'PARCIAL'
            ELSE 'PENDIENTE' END
FROM (VALUES (2, DATE '2026-06-05', 12, 1875.00, 4),
             (3, DATE '2026-08-20',  6, 3000.00, 3),
             (4, DATE '2026-05-10',  3, 5000.00, 3),
             (5, DATE '2026-09-15', 14, 2000.00, 1))
      AS c(id_venta, primera, nro_cuotas, monto, pagadas)
CROSS JOIN LATERAL generate_series(1, c.nro_cuotas) AS n;
COMMIT;

BEGIN;
INSERT INTO pago (codigo_oficina, nro_recibo, id_venta, id_separacion, id_cuenta, fecha_hora,
                  concepto, monto, medio_pago, nro_operacion, estado_recibo)
VALUES
    ('OFIC-CRDO',  1, 1,    NULL, 1,    '2026-03-10 11:15', 'CANCELACION', 46000.00, 'TRANSFERENCIA', 'OP-88121', 'EMITIDO'),
    ('OFIC-CRDO',  2, NULL, 1,    NULL, '2026-05-02 10:30', 'SEPARACION',    100.00, 'EFECTIVO',      NULL,       'EMITIDO'),
    ('OFIC-CRDO',  3, 2,    NULL, 3,    '2026-05-06 12:00', 'INICIAL',     22400.00, 'DEPOSITO',      'DEP-5521', 'EMITIDO'),
    ('OFIC-CRDO',  4, 2,    NULL, NULL, '2026-06-05 09:40', 'CUOTA',        1875.00, 'EFECTIVO',      NULL,       'EMITIDO'),
    ('OFIC-CRDO',  5, 2,    NULL, 1,    '2026-07-04 10:05', 'CUOTA',        1875.00, 'TRANSFERENCIA', 'OP-90211', 'EMITIDO'),
    ('OFIC-CRDO',  6, 2,    NULL, NULL, '2026-08-05 09:20', 'CUOTA',        1875.00, 'EFECTIVO',      NULL,       'EMITIDO'),
    ('OFIC-CRDO',  7, NULL, 2,    NULL, '2026-08-20 09:15', 'SEPARACION',    200.00, 'EFECTIVO',      NULL,       'EMITIDO'),
    ('OFIC-CRDO',  8, 5,    NULL, 1,    '2026-08-25 16:30', 'INICIAL',     12000.00, 'TRANSFERENCIA', 'OP-93455', 'EMITIDO'),
    ('OFIC-CRDO',  9, 2,    NULL, 3,    '2026-09-03 10:10', 'CUOTA',        1875.00, 'DEPOSITO',      'DEP-7710', 'EMITIDO'),
    ('OFIC-CRDO', 10, 5,    NULL, NULL, '2026-09-14 11:00', 'CUOTA',        2000.00, 'EFECTIVO',      NULL,       'EMITIDO'),
    ('OFIC-CRDO', 11, 5,    NULL, NULL, '2026-10-16 10:45', 'CUOTA',        1200.00, 'EFECTIVO',      NULL,       'EMITIDO'),
    ('OFIC-CRDO', 12, NULL, 3,    NULL, '2026-11-02 11:00', 'SEPARACION',    100.00, 'EFECTIVO',      NULL,       'EMITIDO'),
    ('OFIC-LL',    1, 3,    NULL, 1,    '2026-07-20 15:00', 'INICIAL',     18000.00, 'TRANSFERENCIA', 'OP-91007', 'EMITIDO'),
    ('OFIC-LL',    2, 3,    NULL, NULL, '2026-08-20 10:00', 'CUOTA',        3500.00, 'EFECTIVO',      NULL,       'EMITIDO'),
    ('OFIC-LL',    3, 3,    NULL, NULL, '2026-08-20 10:20', 'CUOTA',        3000.00, 'EFECTIVO',      NULL,       'EMITIDO'),
    ('OFIC-LL',    4, NULL, 4,    NULL, '2026-09-10 16:20', 'SEPARACION',    150.00, 'EFECTIVO',      NULL,       'EMITIDO'),
    ('OFIC-LL',    5, 3,    NULL, 1,    '2026-09-18 12:30', 'CUOTA',        3000.00, 'DEPOSITO',      'DEP-6603', 'EMITIDO'),
    ('OFIC-LL',    6, NULL, 5,    NULL, '2026-10-01 12:00', 'SEPARACION',    100.00, 'EFECTIVO',      NULL,       'EMITIDO'),
    ('OFIC-LL',    7, 3,    NULL, NULL, '2026-10-19 09:50', 'CUOTA',        3000.00, 'EFECTIVO',      NULL,       'EMITIDO'),
    ('OFIC-MGG',   1, 4,    NULL, 1,    '2026-04-10 10:30', 'INICIAL',     19000.00, 'TRANSFERENCIA', 'OP-87001', 'EMITIDO'),
    ('OFIC-MGG',   2, 4,    NULL, NULL, '2026-05-09 10:00', 'CUOTA',        5000.00, 'EFECTIVO',      NULL,       'EMITIDO'),
    ('OFIC-MGG',   3, 4,    NULL, 3,    '2026-06-10 11:20', 'CUOTA',        5000.00, 'DEPOSITO',      'DEP-4410', 'EMITIDO'),
    ('OFIC-MGG',   4, 4,    NULL, 1,    '2026-07-09 09:30', 'CANCELACION',  5000.00, 'TRANSFERENCIA', 'OP-89300', 'EMITIDO'),
    ('OFIC-MGG',   5, NULL, 6,    NULL, '2026-11-04 15:00', 'SEPARACION',    300.00, 'EFECTIVO',      NULL,       'EMITIDO');
COMMIT;

BEGIN;
INSERT INTO pago_cuota (id_pago, id_venta, nro_cuota, monto_aplicado)
SELECT p.id_pago, a.id_venta, a.nro_cuota, a.monto_aplicado
FROM (VALUES ('OFIC-CRDO',  4, 2, 1, 1875.00),
             ('OFIC-CRDO',  5, 2, 2, 1875.00),
             ('OFIC-CRDO',  6, 2, 3, 1875.00),
             ('OFIC-CRDO',  9, 2, 4, 1875.00),
             ('OFIC-CRDO', 10, 5, 1, 2000.00),
             ('OFIC-CRDO', 11, 5, 2, 1000.00),
             ('OFIC-LL',    3, 3, 1, 3000.00),
             ('OFIC-LL',    5, 3, 2, 3000.00),
             ('OFIC-LL',    7, 3, 3, 3000.00),
             ('OFIC-MGG',   2, 4, 1, 5000.00),
             ('OFIC-MGG',   3, 4, 2, 5000.00),
             ('OFIC-MGG',   4, 4, 3, 5000.00))
      AS a(codigo_oficina, nro_recibo, id_venta, nro_cuota, monto_aplicado)
JOIN pago p ON p.codigo_oficina = a.codigo_oficina
           AND p.nro_recibo     = a.nro_recibo;
COMMIT;

BEGIN;
INSERT INTO comision (id_venta, tramo, base, monto, fecha_generacion, estado)
VALUES
    (1, 'UNICO',  46000.00, 3680.00, '2026-03-10', 'PAGADA'),
    (2, 'TRAMO1', 22500.00, 1800.00, '2026-05-06', 'PAGADA'),
    (3, 'TRAMO1', 18000.00, 1440.00, '2026-07-20', 'PENDIENTE'),
    (4, 'TRAMO1', 19000.00, 1520.00, '2026-04-10', 'PAGADA'),
    (4, 'TRAMO2', 15000.00, 1200.00, '2026-07-09', 'PAGADA'),
    (5, 'TRAMO1', 12000.00,  960.00, '2026-08-25', 'PENDIENTE');
COMMIT;

BEGIN;
INSERT INTO pago_comision (id_comision, fecha_pago, monto, medio_pago, descripcion)
VALUES
    (1, '2026-03-20', 3680.00, 'TRANSFERENCIA', 'Pago total de comisión - lote A-1'),
    (2, '2026-05-15', 1800.00, 'TRANSFERENCIA', 'Pago total del tramo 1 - lote A-2'),
    (3, '2026-08-01',  700.00, 'EFECTIVO',      'Adelanto de comisión, tramo 1 - lote A-3'),
    (3, '2026-10-05',  300.00, 'EFECTIVO',      'Segundo adelanto, tramo 1 - lote A-3'),
    (4, '2026-04-15', 1520.00, 'INTERNO',       'Liquidación interna: comisión retenida por la oficina (venta directa)'),
    (5, '2026-07-15', 1200.00, 'INTERNO',       'Liquidación interna: comisión retenida por la oficina (venta directa)');
COMMIT;

-- =====================================================================
-- PARTE 2: UPDATE
-- =====================================================================

UPDATE proyecto
SET    estado = 'EN_VENTA'
WHERE  nombre = 'Mirador del Sol';

UPDATE sector
SET    nombre = 'Etapa I'
WHERE  id_proyecto = 2 AND nombre = 'I';

UPDATE manzana
SET    codigo = 'E1'
WHERE  id_sector = 3 AND codigo = 'E';

UPDATE lote
SET    estado_lote = 'DISPONIBLE'
WHERE  id_lote = 7 AND estado_lote = 'SEPARADO';

UPDATE precio_lote
SET    motivo = 'Reajuste por alta demanda: quedan pocos lotes en la manzana A'
WHERE  id_lote = 1 AND fecha_fin IS NULL;

UPDATE persona
SET    telefono = '958200202',
       correo   = 'carlos.huaman@nuevocorreo.pe'
WHERE  id_persona = 2;

UPDATE persona_natural
SET    estado_civil = 'CASADA'
WHERE  tipo_documento = 'DNI' AND nro_documento = '45120003';

UPDATE persona_juridica
SET    id_representante = 3
WHERE  ruc = '20601234565';

UPDATE asesor
SET    estado = 'ACTIVO'
WHERE  id_asesor = 5;

UPDATE oficina o
SET    ultimo_nro_recibo = (SELECT COALESCE(MAX(p.nro_recibo), 0)
                            FROM   pago p
                            WHERE  p.codigo_oficina = o.codigo_oficina)
WHERE  o.codigo_oficina IN ('OFIC-CRDO', 'OFIC-LL', 'OFIC-MGG');

UPDATE cuenta_bancaria
SET    estado = 'INACTIVA'
WHERE  banco = 'Interbank';

UPDATE empleado
SET    id_proyecto = 1
WHERE  id_empleado = 4;

UPDATE sueldo
SET    fecha_inicio = '2024-01-15'
WHERE  id_empleado = 4 AND fecha_fin IS NULL;

UPDATE pago_sueldo
SET    medio_pago = 'EFECTIVO'
WHERE  id_empleado = 4 AND periodo = '2026-10';

UPDATE separacion
SET    estado = 'VENCIDA'
WHERE  estado = 'VIGENTE'
  AND  fecha_vencimiento < DATE '2026-11-05';

BEGIN;
UPDATE venta
SET    estado_venta = 'CANCELADA'
WHERE  id_venta = 4;

UPDATE lote
SET    estado_lote = 'CANCELADO'
WHERE  id_lote = 4;
COMMIT;

UPDATE venta_participante
SET    rol = 'COPROPIETARIO'
WHERE  id_venta = 2 AND id_persona = 1;

UPDATE cuota
SET    estado_cuota = 'VENCIDA'
WHERE  estado_cuota = 'PENDIENTE'
  AND  fecha_vencimiento < DATE '2026-11-05';

UPDATE pago
SET    estado_recibo = 'ANULADO'
WHERE  codigo_oficina = 'OFIC-LL' AND nro_recibo = 2;

UPDATE pago_cuota
SET    monto_aplicado = 1200.00
WHERE  id_venta = 5 AND nro_cuota = 2;

UPDATE comision
SET    estado = 'PARCIAL'
WHERE  id_venta = 3 AND tramo = 'TRAMO1';

UPDATE pago_comision
SET    medio_pago = 'TRANSFERENCIA'
WHERE  id_comision = 3 AND fecha_pago = '2026-08-01';

-- =====================================================================
-- PARTE 3: VERIFICACIÓN
-- =====================================================================

SELECT 'proyecto' AS tabla, count(*) AS registros FROM proyecto
UNION ALL SELECT 'sector',             count(*) FROM sector
UNION ALL SELECT 'manzana',            count(*) FROM manzana
UNION ALL SELECT 'lote',               count(*) FROM lote
UNION ALL SELECT 'precio_lote',        count(*) FROM precio_lote
UNION ALL SELECT 'persona',            count(*) FROM persona
UNION ALL SELECT 'persona_natural',    count(*) FROM persona_natural
UNION ALL SELECT 'persona_juridica',   count(*) FROM persona_juridica
UNION ALL SELECT 'asesor',             count(*) FROM asesor
UNION ALL SELECT 'oficina',            count(*) FROM oficina
UNION ALL SELECT 'cuenta_bancaria',    count(*) FROM cuenta_bancaria
UNION ALL SELECT 'empleado',           count(*) FROM empleado
UNION ALL SELECT 'sueldo',             count(*) FROM sueldo
UNION ALL SELECT 'pago_sueldo',        count(*) FROM pago_sueldo
UNION ALL SELECT 'separacion',         count(*) FROM separacion
UNION ALL SELECT 'venta',              count(*) FROM venta
UNION ALL SELECT 'venta_participante', count(*) FROM venta_participante
UNION ALL SELECT 'cuota',              count(*) FROM cuota
UNION ALL SELECT 'pago',               count(*) FROM pago
UNION ALL SELECT 'pago_cuota',         count(*) FROM pago_cuota
UNION ALL SELECT 'comision',           count(*) FROM comision
UNION ALL SELECT 'pago_comision',      count(*) FROM pago_comision;
