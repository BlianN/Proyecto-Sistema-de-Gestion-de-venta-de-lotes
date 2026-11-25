
-- MÓDULO 2: VENTAS


BEGIN;

CREATE TABLE persona (
    id_persona    SERIAL        PRIMARY KEY,
    tipo_persona  CHAR(1)       NOT NULL,
    direccion     VARCHAR(150)  NOT NULL,
    telefono      VARCHAR(15)   NOT NULL,
    telefono_2    VARCHAR(15),
    correo        VARCHAR(100),
    CONSTRAINT ck_persona_tipo       CHECK (tipo_persona IN ('N', 'J')),
    CONSTRAINT ck_persona_telefono   CHECK (telefono ~ '^[0-9]{6,15}$'),
    CONSTRAINT ck_persona_telefono_2 CHECK (telefono_2 IS NULL OR telefono_2 ~ '^[0-9]{6,15}$'),
    CONSTRAINT ck_persona_correo     CHECK (correo IS NULL OR correo ~ '^[^@\s]+@[^@\s]+\.[^@\s]+$')
);

CREATE TABLE persona_natural (
    id_persona        INTEGER      PRIMARY KEY
                      REFERENCES persona (id_persona) ON DELETE CASCADE,
    tipo_documento    VARCHAR(10)  NOT NULL,
    nro_documento     VARCHAR(15)  NOT NULL,
    nombres           VARCHAR(60)  NOT NULL,
    apellido_paterno  VARCHAR(40)  NOT NULL,
    apellido_materno  VARCHAR(40),
    nacionalidad      VARCHAR(40)  NOT NULL DEFAULT 'Peruana',
    estado_civil      VARCHAR(15),
    ocupacion         VARCHAR(60),
    CONSTRAINT uq_persona_natural_documento UNIQUE (tipo_documento, nro_documento),
    CONSTRAINT ck_persona_natural_tipo_doc  CHECK (tipo_documento IN ('DNI', 'CE', 'PASAPORTE')),
    -- El DNI peruano tiene exactamente 8 dígitos (se guarda como texto para no perder ceros).
    CONSTRAINT ck_persona_natural_dni       CHECK (tipo_documento <> 'DNI' OR nro_documento ~ '^[0-9]{8}$'),
    CONSTRAINT ck_persona_natural_estado_civil CHECK (estado_civil IS NULL OR estado_civil IN
        ('SOLTERO', 'SOLTERA', 'CASADO', 'CASADA', 'CONVIVIENTE',
         'DIVORCIADO', 'DIVORCIADA', 'VIUDO', 'VIUDA'))
);

CREATE TABLE persona_juridica (
    id_persona        INTEGER       PRIMARY KEY
                      REFERENCES persona (id_persona) ON DELETE CASCADE,
    id_representante  INTEGER       NOT NULL REFERENCES persona_natural (id_persona),
    ruc               CHAR(11)      NOT NULL,
    razon_social      VARCHAR(150)  NOT NULL,
    CONSTRAINT uq_persona_juridica_ruc UNIQUE (ruc),
    CONSTRAINT ck_persona_juridica_ruc CHECK (ruc ~ '^(10|20)[0-9]{9}$')
);

CREATE TABLE asesor (
    id_asesor   SERIAL       PRIMARY KEY,
    id_persona  INTEGER      NOT NULL REFERENCES persona (id_persona),
    fecha_alta  DATE         NOT NULL DEFAULT CURRENT_DATE,
    estado      VARCHAR(10)  NOT NULL DEFAULT 'ACTIVO',
    CONSTRAINT uq_asesor_persona UNIQUE (id_persona),
    CONSTRAINT ck_asesor_estado  CHECK (estado IN ('ACTIVO', 'INACTIVO'))
);

CREATE TABLE separacion (
    id_separacion      SERIAL         PRIMARY KEY,
    id_lote            INTEGER        NOT NULL REFERENCES lote (id_lote),
    id_persona         INTEGER        NOT NULL REFERENCES persona (id_persona),
    id_asesor          INTEGER        REFERENCES asesor (id_asesor) ON DELETE SET NULL,
    fecha_hora         TIMESTAMP      NOT NULL DEFAULT now(),
    monto              NUMERIC(10,2)  NOT NULL,
    fecha_vencimiento  DATE           NOT NULL,
    estado             VARCHAR(12)    NOT NULL DEFAULT 'VIGENTE',
    destino_monto      VARCHAR(10),
    CONSTRAINT ck_separacion_monto    CHECK (monto >= 100),
    CONSTRAINT ck_separacion_estado   CHECK (estado IN ('VIGENTE', 'CONVERTIDA', 'RETIRADA', 'VENCIDA')),
    CONSTRAINT ck_separacion_destino  CHECK (destino_monto IS NULL OR destino_monto IN ('ESCRITURA', 'PRECIO')),
    -- Al convertirse en venta hay que decir a qué se aplica el monto separado.
    CONSTRAINT ck_separacion_convertida CHECK (estado <> 'CONVERTIDA' OR destino_monto IS NOT NULL),
    CONSTRAINT ck_separacion_fechas   CHECK (fecha_vencimiento >= fecha_hora::date)
);

CREATE TABLE venta (
    id_venta             SERIAL         PRIMARY KEY,
    id_lote              INTEGER        NOT NULL REFERENCES lote (id_lote),
    id_separacion        INTEGER        REFERENCES separacion (id_separacion),
    id_asesor            INTEGER        REFERENCES asesor (id_asesor) ON DELETE SET NULL,
    codigo_oficina       VARCHAR(10)    NOT NULL,          -- FK creada en el módulo 3
    fecha_venta          DATE           NOT NULL DEFAULT CURRENT_DATE,
    modalidad            VARCHAR(7)     NOT NULL,
    precio_lista         NUMERIC(12,2)  NOT NULL,
    descuento            NUMERIC(12,2)  NOT NULL DEFAULT 0,
    inicial              NUMERIC(12,2)  NOT NULL,
    plazo_meses          SMALLINT,
    dia_pago             SMALLINT,
    fecha_primera_cuota  DATE,
    estado_venta         VARCHAR(15)    NOT NULL DEFAULT 'ACTIVA',
    motivo_excepcion     VARCHAR(200),
    CONSTRAINT uq_venta_separacion UNIQUE (id_separacion),
    CONSTRAINT ck_venta_estado     CHECK (estado_venta IN ('ACTIVA', 'CANCELADA', 'ANULADA')),
    CONSTRAINT ck_venta_modalidad  CHECK (modalidad IN ('CONTADO', 'CUOTAS')),
    CONSTRAINT ck_venta_montos     CHECK (precio_lista > 0 AND descuento >= 0
                                          AND descuento < precio_lista
                                          AND inicial >= 0
                                          AND inicial <= precio_lista - descuento),
    CONSTRAINT ck_venta_dia_pago   CHECK (dia_pago BETWEEN 1 AND 31),
    CONSTRAINT ck_venta_datos_cuotas CHECK (
        modalidad = 'CONTADO'
        OR (plazo_meses IS NOT NULL AND dia_pago IS NOT NULL AND fecha_primera_cuota IS NOT NULL)
    ),
    -- Al contado no hay cuotas: la inicial es el precio completo.
    CONSTRAINT ck_venta_contado CHECK (
        modalidad = 'CUOTAS'
        OR (plazo_meses IS NULL AND dia_pago IS NULL AND fecha_primera_cuota IS NULL
            AND inicial = precio_lista - descuento)
    ),
    -- Hasta 12 meses; más plazo solo con excepción aprobada por gerencia.
    CONSTRAINT ck_venta_plazo CHECK (
        modalidad = 'CONTADO'
        OR (plazo_meses >= 1 AND (plazo_meses <= 12 OR motivo_excepcion IS NOT NULL))
    ),
    -- Inicial mínima del 50 %; menos solo con excepción aprobada por gerencia.
    CONSTRAINT ck_venta_inicial_minima CHECK (
        modalidad = 'CONTADO'
        OR inicial >= 0.5 * (precio_lista - descuento)
        OR motivo_excepcion IS NOT NULL
    ),
    CONSTRAINT ck_venta_primera_cuota CHECK (fecha_primera_cuota IS NULL OR fecha_primera_cuota > fecha_venta)
);

CREATE TABLE venta_participante (
    id_venta    INTEGER      NOT NULL REFERENCES venta (id_venta) ON DELETE CASCADE,
    id_persona  INTEGER      NOT NULL REFERENCES persona (id_persona),
    rol         VARCHAR(15)  NOT NULL,
    PRIMARY KEY (id_venta, id_persona),
    CONSTRAINT ck_venta_participante_rol CHECK (rol IN ('TITULAR', 'COPROPIETARIO', 'FINANCIADOR'))
);

-- ---------------------------------------------------------------------
-- Índices únicos parciales (reglas de negocio)
-- ---------------------------------------------------------------------

-- Un lote no puede tener dos ventas vigentes (evita la doble venta).
CREATE UNIQUE INDEX uq_venta_lote_activa
    ON venta (id_lote) WHERE estado_venta IN ('ACTIVA', 'CANCELADA');

-- Un lote no puede tener dos separaciones vigentes.
CREATE UNIQUE INDEX uq_separacion_lote_vigente
    ON separacion (id_lote) WHERE estado = 'VIGENTE';

-- Una venta tiene como máximo un titular y un financiador.
CREATE UNIQUE INDEX uq_venta_un_titular
    ON venta_participante (id_venta) WHERE rol = 'TITULAR';
CREATE UNIQUE INDEX uq_venta_un_financiador
    ON venta_participante (id_venta) WHERE rol = 'FINANCIADOR';

-- ---------------------------------------------------------------------
-- Índices de apoyo para claves foráneas
-- ---------------------------------------------------------------------
CREATE INDEX ix_persona_juridica_repr   ON persona_juridica (id_representante);
CREATE INDEX ix_separacion_lote         ON separacion (id_lote);
CREATE INDEX ix_separacion_persona      ON separacion (id_persona);
CREATE INDEX ix_separacion_asesor       ON separacion (id_asesor);
CREATE INDEX ix_venta_lote              ON venta (id_lote);
CREATE INDEX ix_venta_asesor            ON venta (id_asesor);
CREATE INDEX ix_venta_oficina           ON venta (codigo_oficina);
CREATE INDEX ix_venta_participante_pers ON venta_participante (id_persona);

-- ---------------------------------------------------------------------
-- Triggers (reglas que no caben en una sola restricción)
-- ---------------------------------------------------------------------

-- La fila del subtipo debe coincidir con el tipo de la persona.
CREATE FUNCTION fn_subtipo_coincide_con_persona() RETURNS trigger AS $$
BEGIN
    IF NOT EXISTS (SELECT 1 FROM persona
                   WHERE id_persona = NEW.id_persona
                     AND tipo_persona = TG_ARGV[0]) THEN
        RAISE EXCEPTION 'La persona % no es de tipo % (tabla %)',
            NEW.id_persona, TG_ARGV[0], TG_TABLE_NAME;
    END IF;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trg_persona_natural_tipo
    BEFORE INSERT OR UPDATE OF id_persona ON persona_natural
    FOR EACH ROW EXECUTE FUNCTION fn_subtipo_coincide_con_persona('N');

CREATE TRIGGER trg_persona_juridica_tipo
    BEFORE INSERT OR UPDATE OF id_persona ON persona_juridica
    FOR EACH ROW EXECUTE FUNCTION fn_subtipo_coincide_con_persona('J');

-- Toda persona debe tener su fila de subtipo al terminar la transacción.
CREATE FUNCTION fn_persona_requiere_subtipo() RETURNS trigger AS $$
BEGIN
    IF NOT EXISTS (SELECT 1 FROM persona WHERE id_persona = NEW.id_persona) THEN
        RETURN NULL;   -- la persona fue borrada dentro de la misma transacción
    END IF;
    IF NEW.tipo_persona = 'N'
       AND NOT EXISTS (SELECT 1 FROM persona_natural WHERE id_persona = NEW.id_persona) THEN
        RAISE EXCEPTION 'La persona % es de tipo N y no tiene fila en persona_natural', NEW.id_persona;
    ELSIF NEW.tipo_persona = 'J'
       AND NOT EXISTS (SELECT 1 FROM persona_juridica WHERE id_persona = NEW.id_persona) THEN
        RAISE EXCEPTION 'La persona % es de tipo J y no tiene fila en persona_juridica', NEW.id_persona;
    END IF;
    RETURN NULL;
END;
$$ LANGUAGE plpgsql;

CREATE CONSTRAINT TRIGGER trg_persona_requiere_subtipo
    AFTER INSERT OR UPDATE OF tipo_persona ON persona
    DEFERRABLE INITIALLY DEFERRED
    FOR EACH ROW EXECUTE FUNCTION fn_persona_requiere_subtipo();

-- Toda venta debe tener exactamente un titular al terminar la transacción.
CREATE FUNCTION fn_venta_un_titular() RETURNS trigger AS $$
DECLARE
    v_ids INTEGER[];
    v_id  INTEGER;
BEGIN
    IF TG_TABLE_NAME = 'venta' THEN
        v_ids := ARRAY[NEW.id_venta];
    ELSIF TG_OP = 'DELETE' THEN
        v_ids := ARRAY[OLD.id_venta];
    ELSIF TG_OP = 'UPDATE' THEN
        v_ids := ARRAY[OLD.id_venta, NEW.id_venta];
    ELSE
        v_ids := ARRAY[NEW.id_venta];
    END IF;

    FOREACH v_id IN ARRAY v_ids LOOP
        IF EXISTS (SELECT 1 FROM venta WHERE id_venta = v_id)
           AND (SELECT count(*) FROM venta_participante
                WHERE id_venta = v_id AND rol = 'TITULAR') <> 1 THEN
            RAISE EXCEPTION 'La venta % debe tener exactamente un titular', v_id;
        END IF;
    END LOOP;
    RETURN NULL;
END;
$$ LANGUAGE plpgsql;

CREATE CONSTRAINT TRIGGER trg_venta_un_titular
    AFTER INSERT ON venta
    DEFERRABLE INITIALLY DEFERRED
    FOR EACH ROW EXECUTE FUNCTION fn_venta_un_titular();

CREATE CONSTRAINT TRIGGER trg_venta_participante_un_titular
    AFTER INSERT OR UPDATE OR DELETE ON venta_participante
    DEFERRABLE INITIALLY DEFERRED
    FOR EACH ROW EXECUTE FUNCTION fn_venta_un_titular();

COMMIT;
