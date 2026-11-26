-- =====================================================================
-- DATOS DE PRUEBA - MÓDULO 1: PROYECTOS Y LOTES
-- Responsable: Ian Anci
-- Se ejecuta en una base recién creada, así que los id empiezan en 1.
-- =====================================================================

BEGIN;

INSERT INTO proyecto (nombre, tipo_proyecto, departamento, provincia, distrito,
                      partida_registral, hectareas, estado)
VALUES
    ('Valle Grande',    'URBANIZACION', 'Arequipa', 'Arequipa', 'Mariano Melgar', 'P06000101', 11.00, 'EN_VENTA'),
    ('Los Claveles',    'URBANIZACION', 'Arequipa', 'Arequipa', 'Cerro Colorado', 'P06000102',  8.50, 'EN_VENTA'),
    ('Villa Hermosa',   'URBANIZACION', 'Arequipa', 'Arequipa', 'Paucarpata',     'P06000103',  5.20, 'CERRADO'),
    ('Las Palmeras',    'URBANIZACION', 'Arequipa', 'Arequipa', 'Characato',      'P06000104', 14.75, 'EN_VENTA'),
    ('Mirador del Sol', 'URBANIZACION', 'Arequipa', 'Arequipa', 'Mariano Melgar', 'P06000105',  9.30, 'PLANIFICACION');

-- Valle Grande se divide en zonas; Los Claveles, en etapas.
INSERT INTO sector (id_proyecto, tipo_sector, nombre)
VALUES
    (1, 'ZONA',  'A'),           -- id 1
    (1, 'ZONA',  'B'),           -- id 2
    (1, 'ZONA',  'C'),           -- id 3
    (2, 'ETAPA', 'Etapa I'),     -- id 4
    (2, 'ETAPA', 'Etapa II');    -- id 5

INSERT INTO manzana (id_sector, codigo)
VALUES
    (1, 'A'),     -- id 1  (Valle Grande, zona A)
    (1, 'B'),     -- id 2  (Valle Grande, zona A)
    (2, 'C'),     -- id 3  (Valle Grande, zona B)
    (2, 'D'),     -- id 4  (Valle Grande, zona B)
    (3, 'E'),     -- id 5  (Valle Grande, zona C)
    (4, 'B1'),    -- id 6  (Los Claveles, etapa I)
    (5, 'D2'),    -- id 7  (Los Claveles, etapa II)
    (5, 'Ñ');     -- id 8  (Los Claveles, etapa II)

-- Lotes 1 a 12: lotes con características particulares.
INSERT INTO lote (id_manzana, numero, tipo_lote, estado_lote,
                  area_m2, perimetro_m, frente_m, fondo_m, lado_izq_m, lado_der_m,
                  colinda_frente, colinda_fondo, colinda_izq, colinda_der,
                  partida_registral, es_esquina, frente_parque, en_avenida)
VALUES
    (1, 1, 'VENDIBLE',   'ESCRITURADO', 200.00, 60.00, 10.00, 10.00, 20.00, 20.00,
        'Calle 1', 'Propiedad de terceros', 'Av. Los Cedros', 'Lote 2 mz. A',     'P06-A-01',  TRUE,  FALSE, FALSE),
    (1, 2, 'VENDIBLE',   'EN_CUOTAS',   200.00, 60.00, 10.00, 10.00, 20.00, 20.00,
        'Calle 1', 'Propiedad de terceros', 'Lote 1 mz. A',   'Lote 3 mz. A',     'P06-A-02',  FALSE, FALSE, FALSE),
    (1, 3, 'VENDIBLE',   'EN_CUOTAS',   160.00, 56.00,  8.00,  8.00, 20.00, 20.00,
        'Calle 1', 'Propiedad de terceros', 'Lote 2 mz. A',   'Lote 4 mz. A',     'P06-A-03',  FALSE, FALSE, FALSE),
    (1, 4, 'VENDIBLE',   'CANCELADO',   160.00, 56.00,  8.00,  8.00, 20.00, 20.00,
        'Calle 1', 'Propiedad de terceros', 'Lote 3 mz. A',   'Calle 2',          'P06-A-04',  TRUE,  FALSE, FALSE),
    (2, 1, 'VENDIBLE',   'EN_CUOTAS',   150.00, 50.00, 10.00, 10.00, 15.00, 15.00,
        'Parque central', 'Lote 1 mz. C', 'Calle 2', 'Lote 2 mz. B',              'P06-B-01',  FALSE, TRUE,  FALSE),
    (2, 2, 'VENDIBLE',   'SEPARADO',    150.00, 50.00, 10.00, 10.00, 15.00, 15.00,
        'Parque central', 'Lote 2 mz. C', 'Lote 1 mz. B', 'Lote 3 mz. B',         'P06-B-02',  FALSE, TRUE,  FALSE),
    (2, 3, 'VENDIBLE',   'DISPONIBLE',  180.00, 54.00, 12.00, 12.00, 15.00, 15.00,
        'Av. Principal', 'Lote 3 mz. C', 'Lote 2 mz. B', 'Propiedad de terceros', 'P06-B-03',  TRUE,  FALSE, TRUE),
    (3, 1, 'VENDIBLE',   'DISPONIBLE',  200.00, 60.00, 10.00, 10.00, 20.00, 20.00,
        'Calle 3', 'Lote 1 mz. B', 'Calle 4', 'Lote 2 mz. C',                     'P06-C-01',  FALSE, FALSE, FALSE),
    (3, 2, 'AREA_VERDE', 'BLOQUEADO',   500.00, 90.00, 20.00, 20.00, 25.00, 25.00,
        'Calle 3', 'Lote 2 mz. B', 'Lote 1 mz. C', 'Calle 5',                     NULL,        FALSE, FALSE, FALSE),
    (4, 1, 'FCMP',       'BLOQUEADO',   300.00, 70.00, 15.00, 15.00, 20.00, 20.00,
        'Calle 6', 'Calle 7', 'Calle 8', 'Calle 9',                               NULL,        FALSE, FALSE, FALSE),
    (6, 1, 'VENDIBLE',   'DISPONIBLE',  162.00, 54.00,  9.00,  9.00, 18.00, 18.00,
        'Pasaje 1', 'Propiedad de terceros', 'Lote 2 mz. B1', 'Pasaje 2',         'P06-B1-01', FALSE, FALSE, FALSE),
    (7, 1, 'VENDIBLE',   'SEPARADO',    162.00, 54.00,  9.00,  9.00, 18.00, 18.00,
        'Av. Los Claveles', 'Propiedad de terceros', 'Pasaje 3', 'Lote 2 mz. D2', 'P06-D2-01', TRUE,  FALSE, TRUE);

-- Lotes 13 a 20: manzana C de Valle Grande, números 3 al 10 (150 m²).
INSERT INTO lote (id_manzana, numero, tipo_lote, estado_lote,
                  area_m2, perimetro_m, frente_m, fondo_m, lado_izq_m, lado_der_m,
                  colinda_frente, es_esquina, frente_parque, en_avenida)
SELECT 3, n, 'VENDIBLE',
       CASE WHEN n IN (3, 5, 7) THEN 'CANCELADO'
            WHEN n IN (4, 6)    THEN 'EN_CUOTAS'
            ELSE 'DISPONIBLE' END,
       150.00, 50.00, 10.00, 10.00, 15.00, 15.00,
       'Calle 3', n = 10, FALSE, FALSE
FROM generate_series(3, 10) AS n
ORDER BY n;

-- Lotes 21 a 28: manzana E de Valle Grande, números 1 al 8 (180 m²).
INSERT INTO lote (id_manzana, numero, tipo_lote, estado_lote,
                  area_m2, perimetro_m, frente_m, fondo_m, lado_izq_m, lado_der_m,
                  colinda_frente, es_esquina, frente_parque, en_avenida)
SELECT 5, n, 'VENDIBLE',
       CASE WHEN n IN (2, 3, 5) THEN 'CANCELADO'
            WHEN n IN (1, 4)    THEN 'EN_CUOTAS'
            ELSE 'DISPONIBLE' END,
       180.00, 54.00, 12.00, 12.00, 15.00, 15.00,
       'Av. Principal', n = 1, FALSE, TRUE
FROM generate_series(1, 8) AS n
ORDER BY n;

-- Lotes 29 a 35: manzana B1 de Los Claveles, números 2 al 8 (162 m²).
INSERT INTO lote (id_manzana, numero, tipo_lote, estado_lote,
                  area_m2, perimetro_m, frente_m, fondo_m, lado_izq_m, lado_der_m,
                  colinda_frente, es_esquina, frente_parque, en_avenida)
SELECT 6, n, 'VENDIBLE',
       CASE WHEN n IN (2, 4, 6) THEN 'CANCELADO'
            WHEN n IN (3, 5)    THEN 'EN_CUOTAS'
            ELSE 'DISPONIBLE' END,
       162.00, 54.00, 9.00, 9.00, 18.00, 18.00,
       'Pasaje 1', FALSE, n IN (7, 8), FALSE
FROM generate_series(2, 8) AS n
ORDER BY n;

-- Historial de precios: el lote 1 tuvo un reajuste.
INSERT INTO precio_lote (id_lote, precio, fecha_inicio, fecha_fin, motivo)
VALUES
    (1,  45000.00, '2025-01-01', '2026-02-28', 'Precio de lanzamiento'),
    (1,  48000.00, '2026-03-01', NULL,         'Reajuste por alta demanda: quedan pocos lotes en la manzana A'),
    (2,  45000.00, '2025-01-01', NULL,         'Precio de lanzamiento'),
    (3,  36000.00, '2025-01-01', NULL,         'Precio de lanzamiento'),
    (4,  36000.00, '2025-01-01', NULL,         'Precio de lanzamiento'),
    (5,  40000.00, '2025-01-01', NULL,         'Precio de lanzamiento'),
    (6,  40000.00, '2025-01-01', NULL,         'Precio de lanzamiento'),
    (7,  50000.00, '2025-01-01', NULL,         'Lote en avenida'),
    (8,  45000.00, '2025-01-01', NULL,         'Precio de lanzamiento'),
    (11, 38000.00, '2025-06-01', NULL,         'Precio de lanzamiento'),
    (12, 38000.00, '2025-06-01', NULL,         'Lote en esquina y avenida');

-- Precio de lanzamiento de los lotes 13 a 35 según su manzana.
INSERT INTO precio_lote (id_lote, precio, fecha_inicio, motivo)
SELECT l.id_lote,
       CASE l.id_manzana WHEN 3 THEN 40000.00 WHEN 5 THEN 45000.00 ELSE 38000.00 END,
       CASE l.id_manzana WHEN 6 THEN DATE '2025-06-01' ELSE DATE '2025-01-01' END,
       'Precio de lanzamiento'
FROM lote l
WHERE l.id_lote BETWEEN 13 AND 35
ORDER BY l.id_lote;

COMMIT;
