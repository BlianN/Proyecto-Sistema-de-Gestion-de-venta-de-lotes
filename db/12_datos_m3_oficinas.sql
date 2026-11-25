-- =====================================================================
-- DATOS DE PRUEBA - MÓDULO 3 (parte 1): OFICINAS Y CUENTAS BANCARIAS
-- Responsable: Mijael Pol Escobar
-- Se cargan antes que las ventas (módulo 2), porque toda venta se
-- registra en una oficina.
-- =====================================================================

BEGIN;

INSERT INTO oficina (codigo_oficina, nombre, distrito, direccion, es_central)
VALUES
    ('OFIC-CRDO', 'Cercado',     'Cercado',        'C.C. Los Portales, Calle Nueva 209 Of. 228', TRUE),
    ('OFIC-LL',   'Llamagas',    'Cerro Colorado', 'Zona Llamagas, Cerro Colorado',              FALSE),
    ('OFIC-MGG',  'Miguel Grau', 'Paucarpata',     'Av. Miguel Grau 100, ref. Óvalo Grau',       FALSE);

INSERT INTO cuenta_bancaria (banco, nro_cuenta, cci, moneda, estado)
VALUES
    ('BCP',           '191-2345678-0-11', '00219100234567801112', 'PEN', 'ACTIVA'),    -- id 1
    ('BCP',           '191-8765432-1-22', '00219100876543212215', 'USD', 'ACTIVA'),    -- id 2
    ('Caja Arequipa', '110-0123456789',   '81600011001234567891', 'PEN', 'ACTIVA'),    -- id 3
    ('Caja Arequipa', '110-9876543210',   '81600011009876543210', 'USD', 'ACTIVA'),    -- id 4
    ('Interbank',     '898-3001234567',   '00389800300123456748', 'PEN', 'INACTIVA');  -- id 5

COMMIT;
