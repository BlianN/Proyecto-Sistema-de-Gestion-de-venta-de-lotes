-- Tablas padre
INSERT INTO persona (tipo_persona, direccion, telefono, telefono_2, correo) 
VALUES
('N', 'Av. Los Incas 123, Arequipa', '987654321', NULL, 'juan.perez@email.com'),
('N', 'Calle Bolognesi 456, Cayma', '912345678', '054-123456', 'maria.lopez@email.com'),
('J', 'Av. Ejército 789, Yanahuara', '999888777', NULL, 'contacto@empresa-abc.com'),
('N', 'Urb. Magisterial Mz A Lt 2', '955444333', NULL, 'carlos.ruiz@email.com'),
('J', 'Parque Industrial Mz C, Arequipa', '054-987654', '999111222', 'ventas@industrias-xyz.com');

-- Tablas hijas
INSERT INTO persona_natural (id_persona, tipo_documento, nro_documento, nombres, apellido_paterno, apellido_materno, nacionalidad, estado_civil, ocupacion) VALUES
(1, 'DNI', '71112223', 'Juan', 'Pérez', 'Salas', 'Peruana', 'Soltero', 'Ingeniero'),
(2, 'DNI', '72223334', 'María', 'Gómez', 'López', 'Peruana', 'Casada', 'Arquitecta'),
(3, 'DNI', '73334445', 'Carlos', 'Ruiz', 'Díaz', 'Peruana', 'Soltero', 'Vendedor'),
(4, 'DNI', '74445556', 'Ana', 'Ríos', 'Castro', 'Peruana', 'Casada', 'Médico'),
(5, 'DNI', '75556667', 'Luis', 'Soto', 'Vargas', 'Peruana', 'Divorciado', 'Abogado');


INSERT INTO persona_juridica (id_persona, id_representante, ruc, razon_social) VALUES
(6, 1, '20123456781', 'Empresa Alpha S.A.C.'),
(7, 2, '20123456782', 'Constructora Beta E.I.R.L.'),
(8, 3, '20123456783', 'Inversiones Gamma S.A.'),
(9, 4, '20123456784', 'Grupo Delta S.R.L.'),
(10, 5, '20123456785', 'Omega Proyectos S.A.C.');

INSERT INTO asesor (id_persona, fecha_alta, estado) VALUES
(1, '2023-01-15', 'ACTIVO'),
(2, '2023-02-20', 'ACTIVO'),
(3, '2023-03-10', 'ACTIVO'),
(4, '2023-04-05', 'INACTIVO'),
(5, '2023-05-12', 'ACTIVO');

INSERT INTO separacion (id_lote, id_persona, id_asesor, fecha_hora, monto, fecha_vencimiento, estado, destino_monto) VALUES
(1, 1, 1, '2023-10-25 10:30:00', 500.00, '2023-11-10', 'VIGENTE', 'INICIAL'),
(2, 6, 2, '2023-10-26 15:45:00', 1000.00, '2023-11-15', 'VIGENTE', 'INICIAL'),
(3, 7, 3, '2023-10-27 09:15:00', 750.00, '2023-11-16', 'VIGENTE', 'INICIAL'),
(4, 3, 1, '2023-10-28 11:20:00', 500.00, '2023-11-17', 'VENCIDA', 'PENALIDAD'),
(5, 10, 5, '2023-10-29 16:00:00', 2000.00, '2023-11-18', 'VIGENTE', 'INICIAL');

INSERT INTO venta (id_lote, id_separacion, id_asesor, codigo_oficina, fecha_venta, modalidad, precio_lista, descuento, inicial, plazo_meses, dia_pago, fecha_primera_cuota, estado_venta, motivo_excepcion) VALUES
(1, 1, 1, 'OFI-01', '2023-11-05', 'CREDITO', 50000.00, 2000.00, 5000.00, 60, 15, '2023-12-15', 'APROBADA', NULL),
(2, 2, 2, 'OFI-02', '2023-11-10', 'CONTADO', 45000.00, 5000.00, 40000.00, 0, NULL, NULL, 'CERRADA', 'Venta directa'),
(3, 3, 3, 'OFI-03', '2023-11-12', 'CREDITO', 60000.00, 1000.00, 10000.00, 120, 30, '2023-12-30', 'APROBADA', NULL),
(4, NULL, 5, 'OFI-04', '2023-11-15', 'CONTADO', 55000.00, 0.00, 55000.00, 0, NULL, NULL, 'CERRADA', 'Venta sin separación previa'),
(5, 5, 5, 'OFI-05', '2023-11-16', 'CREDITO', 75000.00, 2500.00, 7500.00, 72, 10, '2023-12-10', 'APROBADA', NULL);

INSERT INTO venta_participante (id_venta, id_persona, rol) VALUES
(1, 1, 'TITULAR'),       
(2, 6, 'TITULAR'),       
(3, 7, 'TITULAR'),       
(4, 3, 'TITULAR'),       
(5, 10, 'TITULAR');
