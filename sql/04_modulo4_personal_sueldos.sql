
CREATE TABLE empleado (
    id_empleado SERIAL PRIMARY KEY,
    id_persona INTEGER NOT NULL UNIQUE REFERENCES persona_natural(id_persona),
    codigo_oficina VARCHAR(10) NOT NULL REFERENCES oficina(codigo_oficina),
    id_proyecto INTEGER REFERENCES proyecto(id_proyecto),  -- solo personal de campo
    cargo VARCHAR(30) NOT NULL,
    fecha_ingreso DATE NOT NULL,
    fecha_cese DATE,
    estado VARCHAR(10) NOT NULL CHECK (estado IN ('ACTIVO', 'CESADO')),
    CHECK (fecha_cese IS NULL OR fecha_cese >= fecha_ingreso)
);

CREATE TABLE sueldo (
    id_sueldo SERIAL PRIMARY KEY,
    id_empleado INTEGER NOT NULL REFERENCES empleado(id_empleado),
    monto_mensual NUMERIC(10,2) NOT NULL CHECK (monto_mensual > 0),
    fecha_inicio DATE NOT NULL,
    fecha_fin DATE,                                   
    CHECK (fecha_fin IS NULL OR fecha_fin >= fecha_inicio)
);

CREATE UNIQUE INDEX uq_sueldo_vigente
    ON sueldo (id_empleado) WHERE fecha_fin IS NULL;

CREATE TABLE pago_sueldo (
    id_pago_sueldo SERIAL PRIMARY KEY,
    id_sueldo INTEGER NOT NULL REFERENCES sueldo(id_sueldo),
    id_empleado INTEGER NOT NULL REFERENCES empleado(id_empleado),
    mes SMALLINT NOT NULL CHECK (mes BETWEEN 1 AND 12),
    anio SMALLINT NOT NULL CHECK (anio >= 2000),
    fecha_pago DATE NOT NULL,
    monto NUMERIC(10,2) NOT NULL CHECK (monto > 0),
    medio_pago VARCHAR(15) NOT NULL
        CHECK (medio_pago IN ('EFECTIVO', 'DEPOSITO', 'TRANSFERENCIA')),
    UNIQUE (id_empleado, anio, mes)                   -- RN-18
);
