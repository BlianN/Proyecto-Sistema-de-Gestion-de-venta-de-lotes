
-- DATOS DE PRUEBA - MÓDULO 2: VENTAS

BEGIN;

INSERT INTO persona (tipo_persona, direccion, telefono, telefono_2, correo)
VALUES
    ('N', 'Calle Mercaderes 214, Cercado, Arequipa',              '958100101', NULL,        'rosa.quispe@correo.pe'),         -- 1
    ('N', 'Urb. Los Álamos B-12, Cayma',                          '958200202', '054251102', 'carlos.huaman@nuevocorreo.pe'),  -- 2
    ('N', 'Av. Venezuela 845, Arequipa',                          '958100103', NULL,        'lucia.flores@correo.pe'),        -- 3
    ('N', 'Calle Jerusalén 530, Arequipa',                        '958100104', NULL,        NULL),                            -- 4
    ('N', 'Ciudad Municipal Mz C Lt 7, Cerro Colorado',           '958100105', NULL,        'jorge.salas@correo.pe'),         -- 5
    ('N', 'Av. Goyeneche 310, Arequipa',                          '958100106', NULL,        'ana.valdivia@correo.pe'),        -- 6
    ('N', 'Calle Ugarte 120, Yanahuara',                          '958100107', NULL,        NULL),                            -- 7
    ('N', 'Urb. Cabo Verde Mz D Lt 4, Cayma',                     '958100108', NULL,        'daniela.caceres@correo.pe'),     -- 8  (asesora)
    ('N', 'Calle Mariano Melgar 77, Paucarpata',                  '958100109', NULL,        'luis.mendoza@correo.pe'),        -- 9  (asesor)
    ('N', 'Av. Ejército 1020, Yanahuara',                         '958100110', NULL,        'ricardo.bejar@correo.pe'),       -- 10 (empleado)
    ('N', 'Calle San Francisco 301, Arequipa',                    '958100111', NULL,        'karla.zevallos@correo.pe'),      -- 11 (empleada)
    ('N', 'Asoc. Villa Hermosa Mz F Lt 2, Paucarpata',            '958100112', NULL,        NULL),                            -- 12 (empleado)
    ('N', 'AA.HH. Alto Misti Mz G Lt 9, Miraflores',              '958100113', NULL,        NULL),                            -- 13 (empleada)
    ('N', 'Urb. La Campiña Mz A Lt 15, Paucarpata',               '958100114', NULL,        'patricia.vera@correo.pe'),       -- 14 (empleada)
    ('J', 'Av. Dolores 450 Of. 202, J. L. Bustamante y Rivero',   '054380115', '958100115', 'contacto@asesoresandes.pe'),     -- 15 (asesor)
    ('J', 'Calle Palacio Viejo 108 Of. 5, Cercado',               '054380116', NULL,        'info@volcanpropiedades.pe'),     -- 16 (asesor)
    ('J', 'Av. Parra 612, Cercado',                               '054380117', NULL,        'ventas@constructoramisti.pe'),   -- 17
    ('J', 'Parque Industrial Río Seco Mz B Lt 3, Cerro Colorado', '054380118', NULL,        'admin@inversioneschachani.pe'),  -- 18
    ('J', 'Av. Jesús 240, Cercado',                               '054380119', NULL,        'servicios@yanahuarasac.pe'),     -- 19 (asesor)
    ('N', 'Calle Bolívar 410, Cercado',                           '958100120', NULL,        'marco.tejada@correo.pe'),        -- 20
    ('N', 'Urb. Semi Rural Pachacútec Mz K Lt 3, Cerro Colorado', '958100121', NULL,        NULL),                            -- 21
    ('N', 'Av. Kennedy 1550, Paucarpata',                         '958100122', NULL,        'silvia.arce@correo.pe'),         -- 22
    ('N', 'Calle Puente Grau 220, Cercado',                       '958100123', NULL,        'hugo.nina@correo.pe'),           -- 23
    ('N', 'Urb. Magisterial II Mz B Lt 11, Yanahuara',            '958100124', '054270124', 'veronica.paz@correo.pe');        -- 24

INSERT INTO persona_natural (id_persona, tipo_documento, nro_documento, nombres,
                             apellido_paterno, apellido_materno, nacionalidad,
                             estado_civil, ocupacion)
VALUES
    (1,  'DNI', '45120001',  'Rosa Elena',     'Quispe',   'Mamani',    'Peruana',    'SOLTERA',     'Comerciante'),
    (2,  'DNI', '45120002',  'Carlos Alberto', 'Huamán',   'Condori',   'Peruana',    'CASADO',      'Ingeniero civil'),
    (3,  'DNI', '45120003',  'Lucía Fernanda', 'Flores',   'Ccopa',     'Peruana',    'CASADA',      'Contadora'),
    (4,  'DNI', '45120004',  'Miguel Ángel',   'Paredes',  'Gutiérrez', 'Peruana',    'SOLTERO',     'Docente'),
    (5,  'DNI', '45120005',  'Jorge Luis',     'Salas',    'Rondón',    'Peruana',    'CASADO',      'Transportista'),
    (6,  'DNI', '45120006',  'Ana María',      'Valdivia', 'Cutipa',    'Peruana',    'CONVIVIENTE', 'Enfermera'),
    (7,  'DNI', '45120007',  'Pedro Pablo',    'Choque',   'Apaza',     'Peruana',    'CASADO',      'Empresario'),
    (8,  'DNI', '45120008',  'Daniela Sofía',  'Cáceres',  'Linares',   'Peruana',    'SOLTERA',     'Asesora inmobiliaria'),
    (9,  'CE',  '001234567', 'Luis Fernando',  'Mendoza',  NULL,        'Colombiana', 'SOLTERO',     'Asesor inmobiliario'),
    (10, 'DNI', '45120010',  'Ricardo',        'Béjar',    'Salinas',   'Peruana',    'CASADO',      'Administrador'),
    (11, 'DNI', '45120011',  'Karla Nicole',   'Zevallos', 'Núñez',     'Peruana',    'SOLTERA',     'Secretaria'),
    (12, 'DNI', '45120012',  'Juan Carlos',    'Mamani',   'Turpo',     'Peruana',    'CASADO',      'Guardián'),
    (13, 'DNI', '45120013',  'Elsa',           'Condori',  'Huanca',    'Peruana',    'VIUDA',       'Personal de limpieza'),
    (14, 'DNI', '45120014',  'Patricia',       'Vera',     'Delgado',   'Peruana',    'SOLTERA',     'Asistente administrativa'),
    (20, 'DNI', '45120020',  'Marco Antonio',  'Tejada',   'Pinto',     'Peruana',    'CASADO',      'Comerciante'),
    (21, 'DNI', '04512021',  'Gladys',         'Ccama',    'Huarca',    'Peruana',    'SOLTERA',     'Agricultora'),
    (22, 'DNI', '45120022',  'Silvia Roxana',  'Arce',     'Medina',    'Peruana',    'DIVORCIADA',  'Abogada'),
    (23, 'DNI', '45120023',  'Hugo',           'Nina',     'Quispe',    'Peruana',    'CASADO',      'Mecánico'),
    (24, 'DNI', '45120024',  'Verónica',       'Paz',      'Soto',      'Peruana',    'CASADA',      'Docente');

INSERT INTO persona_juridica (id_persona, id_representante, ruc, razon_social)
VALUES
    (15, 1, '20601234561', 'Asesores Inmobiliarios Andes S.A.C.'),
    (16, 8, '20601234562', 'Agencia Volcán Propiedades S.R.L.'),
    (17, 2, '20601234563', 'Constructora Misti E.I.R.L.'),
    (18, 4, '20601234564', 'Inversiones Chachani S.A.C.'),
    (19, 3, '20601234565', 'Servicios Yanahuara S.A.C.');

COMMIT;

BEGIN;
INSERT INTO asesor (id_persona, fecha_alta, estado)
VALUES
    (8,  '2024-03-01', 'ACTIVO'),     -- asesor 1: Daniela Cáceres
    (9,  '2024-06-15', 'ACTIVO'),     -- asesor 2: Luis Mendoza
    (15, '2024-09-01', 'ACTIVO'),     -- asesor 3: Asesores Inmobiliarios Andes
    (16, '2025-01-10', 'ACTIVO'),     -- asesor 4: Agencia Volcán Propiedades
    (19, '2025-02-20', 'ACTIVO');     -- asesor 5: Servicios Yanahuara
COMMIT;

BEGIN;
INSERT INTO separacion (id_lote, id_persona, id_asesor, fecha_hora, monto,
                        fecha_vencimiento, estado, destino_monto)
VALUES
    (2,  2, 1,    '2026-05-02 10:30', 100.00, '2026-05-09', 'CONVERTIDA', 'PRECIO'),     -- 1
    (5,  4, 2,    '2026-08-20 09:15', 200.00, '2026-08-27', 'CONVERTIDA', 'ESCRITURA'),  -- 2
    (6,  6, NULL, '2026-11-21 11:00', 100.00, '2026-11-28', 'VIGENTE',    NULL),         -- 3
    (7,  7, 3,    '2026-09-10 16:20', 150.00, '2026-09-17', 'VENCIDA',    NULL),         -- 4
    (8,  1, 4,    '2026-10-01 12:00', 100.00, '2026-10-08', 'RETIRADA',   NULL),         -- 5
    (12, 3, 1,    '2026-11-22 15:00', 300.00, '2026-11-29', 'VIGENTE',    NULL);         -- 6
COMMIT;

-- Ventas: cada venta y sus participantes van en la misma transacción,
-- porque el trigger diferido exige exactamente un titular al COMMIT.
-- Ventas al contado pagadas: estado CANCELADA. Ventas en cuotas: ACTIVA.
BEGIN;

INSERT INTO venta (id_lote, id_separacion, id_asesor, codigo_oficina, fecha_venta, modalidad,
                   precio_lista, descuento, inicial, plazo_meses, dia_pago,
                   fecha_primera_cuota, estado_venta, motivo_excepcion)
VALUES
    (1,  NULL, 4,    'OFIC-CRDO', '2026-03-10', 'CONTADO', 48000.00, 2000.00, 46000.00, NULL, NULL, NULL,         'CANCELADA', NULL),  -- 1
    (2,  1,    1,    'OFIC-CRDO', '2026-05-06', 'CUOTAS',  45000.00,    0.00, 22500.00, 12,   5,    '2026-06-05', 'ACTIVA',    NULL),  -- 2
    (3,  NULL, 3,    'OFIC-LL',   '2026-07-20', 'CUOTAS',  36000.00,    0.00, 18000.00,  6,   20,   '2026-08-20', 'ACTIVA',    NULL),  -- 3
    (4,  NULL, NULL, 'OFIC-MGG',  '2026-04-10', 'CUOTAS',  36000.00, 2000.00, 19000.00,  3,   10,   '2026-05-10', 'CANCELADA', NULL),  -- 4
    (5,  2,    2,    'OFIC-CRDO', '2026-08-25', 'CUOTAS',  40000.00,    0.00, 12000.00, 14,   15,   '2026-09-15', 'ACTIVA',
        'Excepción aprobada por gerencia: inicial menor al 50 % y plazo de 14 meses'),                                                 -- 5
    (13, NULL, 1,    'OFIC-CRDO', '2026-01-15', 'CONTADO', 40000.00, 2000.00, 38000.00, NULL, NULL, NULL,         'CANCELADA', NULL),  -- 6
    (14, NULL, 1,    'OFIC-CRDO', '2026-02-03', 'CUOTAS',  40000.00,    0.00, 20000.00, 10,   3,    '2026-03-03', 'ACTIVA',    NULL),  -- 7
    (15, NULL, 1,    'OFIC-MGG',  '2026-06-12', 'CONTADO', 40000.00, 2000.00, 38000.00, NULL, NULL, NULL,         'CANCELADA', NULL),  -- 8
    (16, NULL, 1,    'OFIC-MGG',  '2026-09-08', 'CUOTAS',  40000.00,    0.00, 24000.00,  8,   8,    '2026-10-08', 'ACTIVA',    NULL),  -- 9
    (17, NULL, 2,    'OFIC-MGG',  '2026-02-20', 'CONTADO', 40000.00, 2000.00, 38000.00, NULL, NULL, NULL,         'CANCELADA', NULL),  -- 10
    (21, NULL, 2,    'OFIC-CRDO', '2026-05-18', 'CUOTAS',  45000.00,    0.00, 22500.00, 12,   18,   '2026-06-18', 'ACTIVA',    NULL),  -- 11
    (22, NULL, 2,    'OFIC-LL',   '2026-10-02', 'CONTADO', 45000.00, 2000.00, 43000.00, NULL, NULL, NULL,         'CANCELADA', NULL),  -- 12
    (23, NULL, 3,    'OFIC-LL',   '2026-03-11', 'CONTADO', 45000.00, 2000.00, 43000.00, NULL, NULL, NULL,         'CANCELADA', NULL),  -- 13
    (24, NULL, 3,    'OFIC-CRDO', '2026-09-25', 'CUOTAS',  45000.00,    0.00, 27000.00,  6,   25,   '2026-10-25', 'ACTIVA',    NULL),  -- 14
    (29, NULL, 1,    'OFIC-LL',   '2026-04-07', 'CONTADO', 38000.00, 2000.00, 36000.00, NULL, NULL, NULL,         'CANCELADA', NULL),  -- 15
    (30, NULL, 2,    'OFIC-LL',   '2026-07-14', 'CUOTAS',  38000.00,    0.00, 19000.00, 12,   14,   '2026-08-14', 'ACTIVA',    NULL),  -- 16
    (31, NULL, 4,    'OFIC-LL',   '2026-08-03', 'CONTADO', 38000.00, 2000.00, 36000.00, NULL, NULL, NULL,         'CANCELADA', NULL),  -- 17
    (32, NULL, 1,    'OFIC-LL',   '2026-10-21', 'CUOTAS',  38000.00,    0.00, 20000.00,  9,   21,   '2026-11-21', 'ACTIVA',    NULL),  -- 18
    (33, NULL, 5,    'OFIC-CRDO', '2026-11-10', 'CONTADO', 38000.00, 2000.00, 36000.00, NULL, NULL, NULL,         'CANCELADA', NULL),  -- 19
    (25, NULL, NULL, 'OFIC-MGG',  '2026-06-30', 'CONTADO', 45000.00, 2000.00, 43000.00, NULL, NULL, NULL,         'CANCELADA', NULL);  -- 20

INSERT INTO venta_participante (id_venta, id_persona, rol)
VALUES
    (1,  3,  'TITULAR'),
    (2,  2,  'TITULAR'),
    (2,  1,  'COPROPIETARIO'),
    (3,  5,  'TITULAR'),
    (4,  18, 'TITULAR'),
    (5,  4,  'TITULAR'),
    (5,  6,  'COPROPIETARIO'),
    (5,  7,  'FINANCIADOR'),
    (6,  20, 'TITULAR'),
    (7,  21, 'TITULAR'),
    (7,  3,  'COPROPIETARIO'),
    (8,  22, 'TITULAR'),
    (9,  23, 'TITULAR'),
    (10, 24, 'TITULAR'),
    (11, 1,  'TITULAR'),
    (12, 2,  'TITULAR'),
    (13, 17, 'TITULAR'),
    (14, 5,  'TITULAR'),
    (15, 21, 'TITULAR'),
    (16, 22, 'TITULAR'),
    (17, 6,  'TITULAR'),
    (18, 23, 'TITULAR'),
    (19, 24, 'TITULAR'),
    (20, 7,  'TITULAR');

COMMIT;
