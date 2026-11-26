-- =====================================================================
-- DATOS DE PRUEBA - MÓDULO 3 (parte 2): CUOTAS, PAGOS Y COMISIONES
-- =====================================================================

-- 1. Cronogramas: las cuotas de cada venta en cuotas las genera la función.
BEGIN;
SELECT v.id_venta, fn_generar_cronograma(v.id_venta) AS cuotas_generadas
FROM   venta v
WHERE  v.modalidad = 'CUOTAS'
ORDER  BY v.id_venta;
COMMIT;

-- 2. Pagos de las ventas 1 a 5 y de las separaciones (recibos por oficina).
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
    ('OFIC-CRDO', 12, NULL, 3,    NULL, '2026-11-21 11:00', 'SEPARACION',    100.00, 'EFECTIVO',      NULL,       'EMITIDO'),
    ('OFIC-LL',    1, 3,    NULL, 1,    '2026-07-20 15:00', 'INICIAL',     18000.00, 'TRANSFERENCIA', 'OP-91007', 'EMITIDO'),
    ('OFIC-LL',    2, 3,    NULL, NULL, '2026-08-20 10:00', 'CUOTA',        3500.00, 'EFECTIVO',      NULL,       'ANULADO'),
    ('OFIC-LL',    3, 3,    NULL, NULL, '2026-08-20 10:20', 'CUOTA',        3000.00, 'EFECTIVO',      NULL,       'EMITIDO'),
    ('OFIC-LL',    4, NULL, 4,    NULL, '2026-09-10 16:20', 'SEPARACION',    150.00, 'EFECTIVO',      NULL,       'EMITIDO'),
    ('OFIC-LL',    5, 3,    NULL, 1,    '2026-09-18 12:30', 'CUOTA',        3000.00, 'DEPOSITO',      'DEP-6603', 'EMITIDO'),
    ('OFIC-LL',    6, NULL, 5,    NULL, '2026-10-01 12:00', 'SEPARACION',    100.00, 'EFECTIVO',      NULL,       'EMITIDO'),
    ('OFIC-LL',    7, 3,    NULL, NULL, '2026-10-19 09:50', 'CUOTA',        3000.00, 'EFECTIVO',      NULL,       'EMITIDO'),
    ('OFIC-MGG',   1, 4,    NULL, 1,    '2026-04-10 10:30', 'INICIAL',     19000.00, 'TRANSFERENCIA', 'OP-87001', 'EMITIDO'),
    ('OFIC-MGG',   2, 4,    NULL, NULL, '2026-05-09 10:00', 'CUOTA',        5000.00, 'EFECTIVO',      NULL,       'EMITIDO'),
    ('OFIC-MGG',   3, 4,    NULL, 3,    '2026-06-10 11:20', 'CUOTA',        5000.00, 'DEPOSITO',      'DEP-4410', 'EMITIDO'),
    ('OFIC-MGG',   4, 4,    NULL, 1,    '2026-07-09 09:30', 'CANCELACION',  5000.00, 'TRANSFERENCIA', 'OP-89300', 'EMITIDO'),
    ('OFIC-MGG',   5, NULL, 6,    NULL, '2026-11-22 15:00', 'SEPARACION',    300.00, 'EFECTIVO',      NULL,       'EMITIDO');

-- Aplicación de esos pagos a las cuotas (se busca el pago por oficina y recibo).
INSERT INTO pago_cuota (id_pago, id_venta, nro_cuota, monto_aplicado)
SELECT p.id_pago, a.id_venta, a.nro_cuota, a.monto_aplicado
FROM (VALUES ('OFIC-CRDO',  4, 2, 1, 1875.00),
             ('OFIC-CRDO',  5, 2, 2, 1875.00),
             ('OFIC-CRDO',  6, 2, 3, 1875.00),
             ('OFIC-CRDO',  9, 2, 4, 1875.00),
             ('OFIC-CRDO', 10, 5, 1, 2000.00),
             ('OFIC-CRDO', 11, 5, 2, 1200.00),
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

-- 3. Ventas 6 a 20: pago al contado (CANCELACION) o inicial (INICIAL).
--    El número de recibo continúa la numeración de cada oficina.
BEGIN;
INSERT INTO pago (codigo_oficina, nro_recibo, id_venta, fecha_hora, concepto, monto, medio_pago)
SELECT v.codigo_oficina,
       (SELECT COALESCE(MAX(p.nro_recibo), 0) FROM pago p WHERE p.codigo_oficina = v.codigo_oficina)
         + ROW_NUMBER() OVER (PARTITION BY v.codigo_oficina ORDER BY v.fecha_venta, v.id_venta),
       v.id_venta,
       v.fecha_venta + TIME '11:00',
       CASE v.modalidad WHEN 'CONTADO' THEN 'CANCELACION' ELSE 'INICIAL' END,
       v.inicial,
       'EFECTIVO'
FROM venta v
WHERE v.id_venta BETWEEN 6 AND 20;
COMMIT;

-- 4. Cuotas pagadas de las ventas 6 a 20: todas las vencidas hasta el
--    31/10/2026, salvo la venta 11, que dejó de pagar desde la cuota 4
--    (cliente moroso). Un recibo por cuota, pagado en su fecha de vencimiento.
BEGIN;
WITH a_pagar AS (
    SELECT c.id_venta, c.nro_cuota, c.monto, c.fecha_vencimiento, v.codigo_oficina,
           ROW_NUMBER() OVER (PARTITION BY v.codigo_oficina
                              ORDER BY c.fecha_vencimiento, c.id_venta, c.nro_cuota) AS rn
    FROM   cuota c
    JOIN   venta v ON v.id_venta = c.id_venta
    WHERE  v.id_venta BETWEEN 6 AND 20
      AND  c.fecha_vencimiento <= DATE '2026-10-31'
      AND  NOT (v.id_venta = 11 AND c.nro_cuota >= 4)
),
ultimo AS (
    SELECT codigo_oficina, MAX(nro_recibo) AS ultimo_recibo
    FROM   pago
    GROUP  BY codigo_oficina
),
nuevos AS (
    INSERT INTO pago (codigo_oficina, nro_recibo, id_venta, fecha_hora, concepto, monto, medio_pago)
    SELECT a.codigo_oficina, u.ultimo_recibo + a.rn, a.id_venta,
           a.fecha_vencimiento + TIME '10:00', 'CUOTA', a.monto, 'EFECTIVO'
    FROM   a_pagar a
    JOIN   ultimo u ON u.codigo_oficina = a.codigo_oficina
    RETURNING id_pago, codigo_oficina, nro_recibo
)
INSERT INTO pago_cuota (id_pago, id_venta, nro_cuota, monto_aplicado)
SELECT n.id_pago, a.id_venta, a.nro_cuota, a.monto
FROM   nuevos n
JOIN   ultimo u  ON u.codigo_oficina = n.codigo_oficina
JOIN   a_pagar a ON a.codigo_oficina = n.codigo_oficina
                AND u.ultimo_recibo + a.rn = n.nro_recibo;
COMMIT;

-- 5. Estado de las cuotas según lo pagado y último recibo de cada oficina.
BEGIN;
SELECT fn_recalcular_estado_cuotas(id_venta)
FROM   venta
WHERE  modalidad = 'CUOTAS';

UPDATE oficina o
SET    ultimo_nro_recibo = (SELECT COALESCE(MAX(p.nro_recibo), 0)
                            FROM   pago p
                            WHERE  p.codigo_oficina = o.codigo_oficina);
COMMIT;

-- 6. Comisiones (8 %) y sus pagos.
BEGIN;
INSERT INTO comision (id_venta, tramo, base, monto, fecha_generacion, estado)
VALUES
    (1, 'UNICO',  46000.00, 3680.00, '2026-03-10', 'PAGADA'),
    (2, 'TRAMO1', 22500.00, 1800.00, '2026-05-06', 'PAGADA'),
    (3, 'TRAMO1', 18000.00, 1440.00, '2026-07-20', 'PARCIAL'),
    (4, 'TRAMO1', 19000.00, 1520.00, '2026-04-10', 'PAGADA'),
    (4, 'TRAMO2', 15000.00, 1200.00, '2026-07-09', 'PAGADA'),
    (5, 'TRAMO1', 12000.00,  960.00, '2026-08-25', 'PENDIENTE');

-- Ventas 6 a 20 con asesor: tramo único si es al contado, tramo 1 si es en cuotas.
-- Las de antes de octubre ya se pagaron.
INSERT INTO comision (id_venta, tramo, base, porcentaje, monto, fecha_generacion, estado)
SELECT v.id_venta,
       CASE v.modalidad WHEN 'CONTADO' THEN 'UNICO' ELSE 'TRAMO1' END,
       v.inicial, 8, ROUND(v.inicial * 0.08, 2), v.fecha_venta,
       CASE WHEN v.fecha_venta < DATE '2026-10-01' THEN 'PAGADA' ELSE 'PENDIENTE' END
FROM   venta v
WHERE  v.id_venta BETWEEN 6 AND 20
  AND  v.id_asesor IS NOT NULL
ORDER  BY v.id_venta;

INSERT INTO pago_comision (id_comision, fecha_pago, monto, medio_pago, descripcion)
VALUES
    (1, '2026-03-20', 3680.00, 'TRANSFERENCIA', 'Pago total de comisión - lote A-1'),
    (2, '2026-05-15', 1800.00, 'TRANSFERENCIA', 'Pago total del tramo 1 - lote A-2'),
    (3, '2026-08-01',  700.00, 'TRANSFERENCIA', 'Adelanto de comisión, tramo 1 - lote A-3'),
    (3, '2026-10-05',  300.00, 'EFECTIVO',      'Segundo adelanto, tramo 1 - lote A-3'),
    (4, '2026-04-15', 1520.00, 'INTERNO',       'Liquidación interna: venta directa de la oficina'),
    (5, '2026-07-15', 1200.00, 'INTERNO',       'Liquidación interna: venta directa de la oficina');

INSERT INTO pago_comision (id_comision, fecha_pago, monto, medio_pago, descripcion)
SELECT c.id_comision, c.fecha_generacion + 10, c.monto, 'TRANSFERENCIA',
       'Pago total de comisión - venta ' || c.id_venta
FROM   comision c
WHERE  c.id_venta BETWEEN 6 AND 20
  AND  c.estado = 'PAGADA'
ORDER  BY c.id_comision;
COMMIT;
