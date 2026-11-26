-- =====================================================================
-- MÓDULO 1: PROYECTOS Y LOTES
-- =====================================================================

BEGIN;

CREATE TABLE proyecto (
    id_proyecto        SERIAL        PRIMARY KEY,
    nombre             VARCHAR(80)   NOT NULL,
    tipo_proyecto      VARCHAR(20)   NOT NULL DEFAULT 'URBANIZACION',
    departamento       VARCHAR(40)   NOT NULL,
    provincia          VARCHAR(40)   NOT NULL,
    distrito           VARCHAR(40)   NOT NULL,
    partida_registral  VARCHAR(20)   NOT NULL,
    hectareas          NUMERIC(8,2)  NOT NULL,
    estado             VARCHAR(15)   NOT NULL DEFAULT 'PLANIFICACION',
    CONSTRAINT uq_proyecto_nombre    UNIQUE (nombre),
    CONSTRAINT ck_proyecto_hectareas CHECK (hectareas > 0),
    CONSTRAINT ck_proyecto_tipo      CHECK (tipo_proyecto IN ('URBANIZACION')),
    CONSTRAINT ck_proyecto_estado    CHECK (estado IN ('PLANIFICACION', 'EN_VENTA', 'CERRADO'))
);

CREATE TABLE sector (
    id_sector     SERIAL       PRIMARY KEY,
    id_proyecto   INTEGER      NOT NULL
                  REFERENCES proyecto (id_proyecto) ON DELETE CASCADE,
    tipo_sector   VARCHAR(10)  NOT NULL,
    nombre        VARCHAR(20)  NOT NULL,
    CONSTRAINT uq_sector_proyecto_nombre UNIQUE (id_proyecto, nombre),
    CONSTRAINT ck_sector_tipo CHECK (tipo_sector IN ('ZONA', 'ETAPA'))
);

CREATE TABLE manzana (
    id_manzana  SERIAL      PRIMARY KEY,
    id_sector   INTEGER     NOT NULL
                REFERENCES sector (id_sector) ON DELETE CASCADE,
    codigo      VARCHAR(5)  NOT NULL,
    CONSTRAINT uq_manzana_sector_codigo UNIQUE (id_sector, codigo)
);

CREATE TABLE lote (
    id_lote            SERIAL         PRIMARY KEY,
    id_manzana         INTEGER        NOT NULL
                       REFERENCES manzana (id_manzana) ON DELETE CASCADE,
    numero             SMALLINT       NOT NULL,
    tipo_lote          VARCHAR(15)    NOT NULL DEFAULT 'VENDIBLE',
    estado_lote        VARCHAR(15)    NOT NULL DEFAULT 'DISPONIBLE',
    area_m2            NUMERIC(8,2)   NOT NULL,
    perimetro_m        NUMERIC(8,2)   NOT NULL,
    frente_m           NUMERIC(6,2)   NOT NULL,
    fondo_m            NUMERIC(6,2)   NOT NULL,
    lado_izq_m         NUMERIC(6,2)   NOT NULL,
    lado_der_m         NUMERIC(6,2)   NOT NULL,
    colinda_frente     VARCHAR(100),
    colinda_fondo      VARCHAR(100),
    colinda_izq        VARCHAR(100),
    colinda_der        VARCHAR(100),
    partida_registral  VARCHAR(20),
    es_esquina         BOOLEAN        NOT NULL DEFAULT FALSE,
    frente_parque      BOOLEAN        NOT NULL DEFAULT FALSE,
    en_avenida         BOOLEAN        NOT NULL DEFAULT FALSE,
    CONSTRAINT uq_lote_manzana_numero UNIQUE (id_manzana, numero),
    CONSTRAINT ck_lote_numero   CHECK (numero > 0),
    CONSTRAINT ck_lote_tipo     CHECK (tipo_lote IN ('VENDIBLE', 'AREA_VERDE', 'FCMP')),
    CONSTRAINT ck_lote_estado   CHECK (estado_lote IN ('DISPONIBLE', 'SEPARADO', 'RESERVADO',
                                       'BLOQUEADO', 'EN_CUOTAS', 'CANCELADO', 'ESCRITURADO')),
    -- Las áreas verdes y los aportes (FCMP) nunca se venden: siempre bloqueados.
    CONSTRAINT ck_lote_no_vendible_bloqueado
        CHECK (tipo_lote = 'VENDIBLE' OR estado_lote = 'BLOQUEADO'),
    CONSTRAINT ck_lote_medidas  CHECK (area_m2 > 0 AND perimetro_m > 0 AND frente_m > 0
                                       AND fondo_m > 0 AND lado_izq_m > 0 AND lado_der_m > 0)
);

CREATE TABLE precio_lote (
    id_precio     SERIAL         PRIMARY KEY,
    id_lote       INTEGER        NOT NULL
                  REFERENCES lote (id_lote) ON DELETE CASCADE,
    precio        NUMERIC(12,2)  NOT NULL,
    fecha_inicio  DATE           NOT NULL DEFAULT CURRENT_DATE,
    fecha_fin     DATE,
    motivo        VARCHAR(150),
    CONSTRAINT ck_precio_lote_precio  CHECK (precio > 0),
    CONSTRAINT ck_precio_lote_fechas  CHECK (fecha_fin IS NULL OR fecha_fin >= fecha_inicio)
);

-- Un lote tiene un solo precio vigente (el que no tiene fecha_fin).
CREATE UNIQUE INDEX uq_precio_lote_vigente
    ON precio_lote (id_lote) WHERE fecha_fin IS NULL;

CREATE INDEX ix_precio_lote_lote ON precio_lote (id_lote);

COMMIT;
