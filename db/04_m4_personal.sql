-- =====================================================================
-- MÓDULO 4: PERSONAL Y SUELDOS
-- =====================================================================

BEGIN;

CREATE TABLE empleado (
    id_empleado     SERIAL       PRIMARY KEY,
    id_persona      INTEGER      NOT NULL REFERENCES persona_natural (id_persona),
    codigo_oficina  VARCHAR(10)  NOT NULL
                    REFERENCES oficina (codigo_oficina) ON UPDATE CASCADE,
    id_proyecto     INTEGER
                    REFERENCES proyecto (id_proyecto) ON DELETE SET NULL,
    cargo           VARCHAR(40)  NOT NULL,
    fecha_ingreso   DATE         NOT NULL DEFAULT CURRENT_DATE,
    fecha_cese      DATE,
    estado          VARCHAR(10)  NOT NULL DEFAULT 'ACTIVO',
    CONSTRAINT uq_empleado_persona UNIQUE (id_persona),
    CONSTRAINT ck_empleado_estado  CHECK (estado IN ('ACTIVO', 'CESADO')),
    CONSTRAINT ck_empleado_fechas  CHECK (fecha_cese IS NULL OR fecha_cese >= fecha_ingreso),
    -- Un empleado cesado tiene fecha de cese, y uno activo no.
    CONSTRAINT ck_empleado_cese    CHECK ((estado = 'CESADO') = (fecha_cese IS NOT NULL))
);

CREATE TABLE sueldo (
    id_sueldo      SERIAL         PRIMARY KEY,
    id_empleado    INTEGER        NOT NULL
                   REFERENCES empleado (id_empleado) ON DELETE CASCADE,
    monto_mensual  NUMERIC(10,2)  NOT NULL,
    fecha_inicio   DATE           NOT NULL DEFAULT CURRENT_DATE,
    fecha_fin      DATE,
    CONSTRAINT ck_sueldo_monto  CHECK (monto_mensual > 0),
    CONSTRAINT ck_sueldo_fechas CHECK (fecha_fin IS NULL OR fecha_fin >= fecha_inicio)
);

-- Un empleado tiene un solo sueldo vigente (el que no tiene fecha_fin).
CREATE UNIQUE INDEX uq_sueldo_vigente ON sueldo (id_empleado) WHERE fecha_fin IS NULL;

CREATE TABLE pago_sueldo (
    id_pago_sueldo  SERIAL         PRIMARY KEY,
    id_empleado     INTEGER        NOT NULL REFERENCES empleado (id_empleado),
    periodo         CHAR(7)        NOT NULL,
    fecha_pago      DATE           NOT NULL DEFAULT CURRENT_DATE,
    monto           NUMERIC(10,2)  NOT NULL,
    medio_pago      VARCHAR(15)    NOT NULL,
    -- Un solo pago de sueldo por empleado y mes.
    CONSTRAINT uq_pago_sueldo_periodo UNIQUE (id_empleado, periodo),
    CONSTRAINT ck_pago_sueldo_periodo CHECK (periodo ~ '^[0-9]{4}-(0[1-9]|1[0-2])$'),
    CONSTRAINT ck_pago_sueldo_monto   CHECK (monto > 0),
    CONSTRAINT ck_pago_sueldo_medio   CHECK (medio_pago IN ('EFECTIVO', 'DEPOSITO', 'TRANSFERENCIA'))
);

CREATE INDEX ix_empleado_oficina  ON empleado (codigo_oficina);
CREATE INDEX ix_empleado_proyecto ON empleado (id_proyecto);
CREATE INDEX ix_sueldo_empleado   ON sueldo (id_empleado);

COMMIT;
