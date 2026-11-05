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
