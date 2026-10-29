CREATE TABLE proyecto (
    id_proyecto SERIAL PRIMARY KEY,
    codigo VARCHAR(10) NOT NULL UNIQUE,
    nombre VARCHAR(100) NOT NULL,
    tipo_proyecto VARCHAR(20) NOT NULL CHECK (tipo_proyecto IN ('URBANIZACION')),
    departamento VARCHAR(40) NOT NULL,
    provincia VARCHAR(40) NOT NULL,
    distrito VARCHAR(40) NOT NULL,
    partida_registral VARCHAR(30) NOT NULL UNIQUE,   -- N° partida SUNARP
    hectareas NUMERIC(10,2) NOT NULL CHECK (hectareas > 0),
    estado VARCHAR(15) NOT NULL
);

CREATE TABLE sector (
    id_sector SERIAL PRIMARY KEY,
    id_proyecto INTEGER NOT NULL REFERENCES proyecto(id_proyecto),
    tipo_sector VARCHAR(5) NOT NULL CHECK (tipo_sector IN ('ZONA', 'ETAPA')),
    nombre VARCHAR(30) NOT NULL,                      -- 'A', 'B', 'I', 'II'...
    UNIQUE (id_proyecto, nombre)
);

CREATE TABLE manzana (
    id_manzana SERIAL PRIMARY KEY,
    id_sector INTEGER NOT NULL REFERENCES sector(id_sector),
    codigo VARCHAR(5) NOT NULL,                       -- 'A', 'B1', 'D2', 'Ñ'
    UNIQUE (id_sector, codigo)
);

CREATE TABLE lote (
    id_lote SERIAL PRIMARY KEY,
    id_manzana INTEGER NOT NULL REFERENCES manzana(id_manzana),
    numero SMALLINT NOT NULL CHECK (numero > 0),
    tipo_lote VARCHAR(20) NOT NULL
        CHECK (tipo_lote IN ('VENDIBLE', 'AREA_VERDE_APORTE', 'FCMP')),
    estado_lote VARCHAR(15) NOT NULL DEFAULT 'DISPONIBLE'
        CHECK (estado_lote IN ('DISPONIBLE', 'SEPARADO', 'RESERVADO', 'BLOQUEADO',
                               'EN_CUOTAS', 'CANCELADO', 'ESCRITURADO')),
    area_m2 NUMERIC(10,2) NOT NULL CHECK (area_m2 > 0),
    perimetro_m NUMERIC(10,2) NOT NULL CHECK (perimetro_m > 0),
    frente_m NUMERIC(8,2) NOT NULL CHECK (frente_m > 0),
    fondo_m NUMERIC(8,2) NOT NULL CHECK (fondo_m > 0),
    lado_izq_m NUMERIC(8,2) NOT NULL CHECK (lado_izq_m > 0),
    lado_der_m NUMERIC(8,2) NOT NULL CHECK (lado_der_m > 0),
    colindante_frente VARCHAR(100),
    colindante_fondo VARCHAR(100),
    colindante_izq VARCHAR(100),
    colindante_der VARCHAR(100),
    partida_registral VARCHAR(30),
    es_esquina BOOLEAN NOT NULL DEFAULT FALSE,
    frente_parque BOOLEAN NOT NULL DEFAULT FALSE,
    sobre_avenida BOOLEAN NOT NULL DEFAULT FALSE,
    UNIQUE (id_manzana, numero)                       -- RN-01
);

CREATE TABLE precio_lote (
    id_precio SERIAL PRIMARY KEY,
    id_lote INTEGER NOT NULL REFERENCES lote(id_lote),
    precio NUMERIC(12,2) NOT NULL CHECK (precio > 0),
    fecha_desde DATE NOT NULL,
    fecha_hasta DATE,                                 -- NULL = precio vigente
    motivo VARCHAR(200),
    CHECK (fecha_hasta IS NULL OR fecha_hasta >= fecha_desde)
);

-- RN-04: cada lote tiene un solo precio vigente
CREATE UNIQUE INDEX uq_precio_lote_vigente
    ON precio_lote (id_lote) WHERE fecha_hasta IS NULL;
