CREATE TABLE persona (
    id_persona SERIAL PRIMARY KEY,
    tipo_persona CHAR(1) NOT NULL CHECK (tipo_persona IN ('N', 'J')), 
    direccion VARCHAR(150) NOT NULL,
    telefono VARCHAR(15) NOT NULL,
    telefono_2 VARCHAR(15),
    correo VARCHAR(100) UNIQUE
);

CREATE TABLE persona_natural (
    id_persona INTEGER PRIMARY KEY REFERENCES persona(id_persona),
    tipo_documento VARCHAR(10) NOT NULL,
    nro_documento VARCHAR(15) NOT NULL UNIQUE,
    nombres VARCHAR(60) NOT NULL,
    apellido_paterno VARCHAR(40) NOT NULL,
    apellido_materno VARCHAR(40),
    nacionalidad VARCHAR(40) NOT NULL,
    estado_civil VARCHAR(15),
    ocupacion VARCHAR(60)
);

CREATE TABLE persona_juridica (
    id_persona INTEGER PRIMARY KEY REFERENCES persona(id_persona),
    id_representante INTEGER NOT NULL REFERENCES persona_natural(id_persona),
    ruc CHAR(11) NOT NULL UNIQUE,
    razon_social VARCHAR(150) NOT NULL
);

CREATE TABLE asesor (
    id_asesor SERIAL PRIMARY KEY,
    id_persona INTEGER NOT NULL REFERENCES persona(id_persona),
    fecha_alta DATE NOT NULL,
    estado VARCHAR(10) NOT NULL CHECK (estado IN ('ACTIVO', 'INACTIVO'))
);

CREATE TABLE separacion (
    id_separacion SERIAL PRIMARY KEY,
    id_lote INTEGER NOT NULL REFERENCES lote(id_lote),
    id_persona INTEGER NOT NULL REFERENCES persona(id_persona),
    id_asesor INTEGER REFERENCES asesor(id_asesor),
    fecha_hora TIMESTAMP NOT NULL,
    monto NUMERIC(10,2) NOT NULL CHECK (monto >= 0),
    fecha_vencimiento DATE NOT NULL,
    estado VARCHAR(12) NOT NULL,
    destino_monto VARCHAR(10)
);

CREATE TABLE venta (
    id_venta SERIAL PRIMARY KEY,
    id_lote INTEGER NOT NULL REFERENCES lote(id_lote),
    id_separacion INTEGER REFERENCES separacion(id_separacion),
    id_asesor INTEGER REFERENCES asesor(id_asesor),
    codigo_oficina VARCHAR(10) NOT NULL REFERENCES oficina(codigo_oficina),
    fecha_venta DATE NOT NULL,
    modalidad VARCHAR(7) NOT NULL CHECK (modalidad IN ('CONTADO', 'CREDITO')),
    precio_lista NUMERIC(12,2) NOT NULL CHECK (precio_lista >= 0),
    descuento NUMERIC(12,2) NOT NULL CHECK (descuento >= 0),
    inicial NUMERIC(12,2) NOT NULL CHECK (inicial >= 0),
    plazo_meses SMALLINT CHECK (plazo_meses >= 0),
    dia_pago SMALLINT CHECK (dia_pago BETWEEN 1 AND 31),
    fecha_primera_cuota DATE,
    estado_venta VARCHAR(15) NOT NULL,
    motivo_excepcion VARCHAR(200)
);

CREATE TABLE venta_participante (
    id_venta INTEGER NOT NULL REFERENCES venta(id_venta),
    id_persona INTEGER NOT NULL REFERENCES persona(id_persona),
    rol VARCHAR(15) NOT NULL,
    PRIMARY KEY (id_venta, id_persona)
);
