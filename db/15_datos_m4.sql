-- =====================================================================
-- DATOS DE PRUEBA - MÓDULO 4: PERSONAL Y SUELDOS
-- =====================================================================

BEGIN;

INSERT INTO empleado (id_persona, codigo_oficina, id_proyecto, cargo, fecha_ingreso, fecha_cese, estado)
VALUES
    (10, 'OFIC-CRDO', NULL, 'Gerente general',      '2020-02-01', NULL, 'ACTIVO'),   -- 1
    (11, 'OFIC-CRDO', NULL, 'Secretaria',           '2022-05-16', NULL, 'ACTIVO'),   -- 2
    (12, 'OFIC-MGG',  1,    'Guardia',              '2023-03-01', NULL, 'ACTIVO'),   -- 3
    (13, 'OFIC-CRDO', 1,    'Personal de limpieza', '2024-01-15', NULL, 'ACTIVO'),   -- 4
    (14, 'OFIC-LL',   NULL, 'Personal de gestión',  '2025-02-03', NULL, 'ACTIVO');   -- 5

-- Historial de sueldos: el gerente tuvo un aumento.
INSERT INTO sueldo (id_empleado, monto_mensual, fecha_inicio, fecha_fin)
VALUES
    (1, 4500.00, '2020-02-01', '2023-12-31'),
    (1, 5500.00, '2024-01-01', NULL),
    (2, 1800.00, '2022-05-16', NULL),
    (3, 1500.00, '2023-03-01', NULL),
    (4, 1130.00, '2024-01-15', NULL),
    (5, 2200.00, '2025-02-03', NULL);

-- Sueldos pagados de setiembre y octubre de 2026 (sueldo vigente).
INSERT INTO pago_sueldo (id_empleado, periodo, fecha_pago, monto, medio_pago)
SELECT s.id_empleado, p.periodo, p.fecha_pago, s.monto_mensual,
       CASE WHEN s.id_empleado = 4 AND p.periodo = '2026-10' THEN 'EFECTIVO' ELSE 'TRANSFERENCIA' END
FROM   sueldo s
CROSS JOIN (VALUES ('2026-09', DATE '2026-09-30'),
                   ('2026-10', DATE '2026-10-31')) AS p(periodo, fecha_pago)
WHERE  s.fecha_fin IS NULL
ORDER  BY s.id_empleado, p.periodo;

COMMIT;
