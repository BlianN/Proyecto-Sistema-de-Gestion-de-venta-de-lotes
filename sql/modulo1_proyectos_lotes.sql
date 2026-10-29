CREATE TABLE IF NOT EXISTS proyecto (
    id_proyecto SERIAL PRIMARY KEY,
    codigo VARCHAR(20) NOT NULL UNIQUE,
    nombre VARCHAR(100) NOT NULL,
    tipo_proyecto VARCHAR(30) NOT NULL,
    departamento VARCHAR(50) NOT NULL,
    provincia VARCHAR(50) NOT NULL,
    distrito VARCHAR(50) NOT NULL,
    partida_registral VARCHAR(30),
    hectareas NUMERIC(12,2) CHECK (hectareas > 0),
    estado VARCHAR(20) NOT NULL
);

CREATE TABLE IF NOT EXISTS sector (
    id_sector SERIAL PRIMARY KEY,
    id_proyecto INTEGER NOT NULL REFERENCES proyecto(id_proyecto),
    tipo_sector VARCHAR(10) NOT NULL
        CHECK (tipo_sector IN ('ZONA', 'ETAPA')),
    nombre VARCHAR(50) NOT NULL,

    UNIQUE(id_proyecto, tipo_sector, nombre)
);



CREATE TABLE IF NOT EXISTS manzana (
    id_manzana SERIAL PRIMARY KEY,
    id_sector INTEGER NOT NULL REFERENCES sector(id_sector),
    codigo VARCHAR(10) NOT NULL,

    UNIQUE(id_sector, codigo)
);


CREATE TABLE IF NOT EXISTS lote (
    id_lote SERIAL PRIMARY KEY,
    id_manzana INTEGER NOT NULL REFERENCES manzana(id_manzana),
    numero VARCHAR(10) NOT NULL,

    tipo_lote VARCHAR(15) NOT NULL
        CHECK (tipo_lote IN (
            'VENDIBLE',
            'AREA_VERDE',
            'APORTE',
            'FCMP'
        )),

    estado VARCHAR(20) NOT NULL
        CHECK (estado IN (
            'DISPONIBLE',
            'SEPARADO',
            'RESERVADO',
            'BLOQUEADO',
            'EN_CUOTAS',
            'CANCELADO',
            'ESCRITURADO'
        )),

    area_m2 NUMERIC(12,2) NOT NULL CHECK (area_m2 > 0),
    perimetro NUMERIC(12,2) CHECK (perimetro > 0),
    frente NUMERIC(10,2) CHECK (frente > 0),
    fondo NUMERIC(10,2) CHECK (fondo > 0),
    lado_izquierdo NUMERIC(10,2) CHECK (lado_izquierdo > 0),
    lado_derecho NUMERIC(10,2) CHECK (lado_derecho > 0),

    colindante_frente VARCHAR(100),
    colindante_fondo VARCHAR(100),
    colindante_izquierdo VARCHAR(100),
    colindante_derecho VARCHAR(100),

    partida_registral VARCHAR(30),

    es_esquina BOOLEAN NOT NULL DEFAULT FALSE,
    frente_parque BOOLEAN NOT NULL DEFAULT FALSE,
    sobre_avenida BOOLEAN NOT NULL DEFAULT FALSE,

    UNIQUE(id_manzana, numero)
);


CREATE TABLE IF NOT EXISTS precio_lote (
    id_precio SERIAL PRIMARY KEY,
    id_lote INTEGER NOT NULL REFERENCES lote(id_lote),

    precio NUMERIC(12,2) NOT NULL CHECK (precio > 0),
    fecha_inicio DATE NOT NULL,
    fecha_fin DATE,
    motivo VARCHAR(200),

    CHECK (
        fecha_fin IS NULL
        OR fecha_fin >= fecha_inicio
    )
);


CREATE UNIQUE INDEX IF NOT EXISTS idx_precio_lote_vigente
ON precio_lote(id_lote)
WHERE fecha_fin IS NULL;
