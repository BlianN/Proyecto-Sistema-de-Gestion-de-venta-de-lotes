BEGIN;

-- =====================================================================
-- MÓDULO 1: PROYECTOS Y LOTES
-- =====================================================================

CREATE TABLE proyecto (
    id_proyecto        SERIAL        PRIMARY KEY,
    nombre             VARCHAR(80)   NOT NULL,
    tipo_proyecto      VARCHAR(20)   NOT NULL,
    departamento       VARCHAR(40)   NOT NULL,
    provincia          VARCHAR(40)   NOT NULL,
    distrito           VARCHAR(40)   NOT NULL,
    partida_registral  VARCHAR(20)   NOT NULL,
    hectareas          NUMERIC(8,2)  NOT NULL,
    estado             VARCHAR(15)   NOT NULL,
    CONSTRAINT uq_proyecto_nombre   UNIQUE (nombre),
    CONSTRAINT ck_proyecto_hectareas CHECK (hectareas > 0)
);

CREATE TABLE sector (
    id_sector     SERIAL       PRIMARY KEY,
    id_proyecto   INTEGER      NOT NULL REFERENCES proyecto (id_proyecto),
    tipo_sector   VARCHAR(10)  NOT NULL,
    nombre        VARCHAR(20)  NOT NULL,
    CONSTRAINT uq_sector_proyecto_nombre UNIQUE (id_proyecto, nombre),
    CONSTRAINT ck_sector_tipo CHECK (tipo_sector IN ('ZONA', 'ETAPA'))
);

CREATE TABLE manzana (
    id_manzana  SERIAL      PRIMARY KEY,
    id_sector   INTEGER     NOT NULL REFERENCES sector (id_sector),
    codigo      VARCHAR(5)  NOT NULL,
    CONSTRAINT uq_manzana_sector_codigo UNIQUE (id_sector, codigo)
);

CREATE TABLE lote (
    id_lote            SERIAL         PRIMARY KEY,
    id_manzana         INTEGER        NOT NULL REFERENCES manzana (id_manzana),
    numero             SMALLINT       NOT NULL,
    tipo_lote          VARCHAR(15)    NOT NULL,
    estado_lote        VARCHAR(15)    NOT NULL,
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
    es_esquina         BOOLEAN        NOT NULL,
    frente_parque      BOOLEAN        NOT NULL,
    en_avenida         BOOLEAN        NOT NULL,
    CONSTRAINT uq_lote_manzana_numero UNIQUE (id_manzana, numero),
    CONSTRAINT ck_lote_numero   CHECK (numero > 0),
    CONSTRAINT ck_lote_tipo     CHECK (tipo_lote IN ('VENDIBLE', 'AREA_VERDE', 'FCMP')),
    CONSTRAINT ck_lote_estado   CHECK (estado_lote IN ('DISPONIBLE', 'SEPARADO', 'RESERVADO',
                                       'BLOQUEADO', 'EN_CUOTAS', 'CANCELADO', 'ESCRITURADO')),
    CONSTRAINT ck_lote_medidas  CHECK (area_m2 > 0 AND perimetro_m > 0 AND frente_m > 0
                                       AND fondo_m > 0 AND lado_izq_m > 0 AND lado_der_m > 0)
);

CREATE TABLE precio_lote (
    id_precio     SERIAL         PRIMARY KEY,
    id_lote       INTEGER        NOT NULL REFERENCES lote (id_lote),
    precio        NUMERIC(12,2)  NOT NULL,
    fecha_inicio  DATE           NOT NULL,
    fecha_fin     DATE,
    motivo        VARCHAR(150),
    CONSTRAINT ck_precio_lote_precio  CHECK (precio > 0),
    CONSTRAINT ck_precio_lote_fechas  CHECK (fecha_fin IS NULL OR fecha_fin >= fecha_inicio)
);

-- =====================================================================
-- MÓDULO 2: VENTAS  (personas, asesores, separaciones, ventas)
-- =====================================================================

CREATE TABLE persona (
    id_persona    SERIAL        PRIMARY KEY,
    tipo_persona  CHAR(1)       NOT NULL,
    direccion     VARCHAR(150)  NOT NULL,
    telefono      VARCHAR(15)   NOT NULL,
    telefono_2    VARCHAR(15),
    correo        VARCHAR(100),
    CONSTRAINT ck_persona_tipo CHECK (tipo_persona IN ('N', 'J'))
);

CREATE TABLE persona_natural (
    id_persona        INTEGER      PRIMARY KEY REFERENCES persona (id_persona),
    tipo_documento    VARCHAR(10)  NOT NULL,
    nro_documento     VARCHAR(15)  NOT NULL,
    nombres           VARCHAR(60)  NOT NULL,
    apellido_paterno  VARCHAR(40)  NOT NULL,
    apellido_materno  VARCHAR(40),
    nacionalidad      VARCHAR(40)  NOT NULL,
    estado_civil      VARCHAR(15),
    ocupacion         VARCHAR(60),
    CONSTRAINT uq_persona_natural_documento UNIQUE (tipo_documento, nro_documento),
    CONSTRAINT ck_persona_natural_tipo_doc  CHECK (tipo_documento IN ('DNI', 'CE', 'PASAPORTE'))
);

CREATE TABLE persona_juridica (
    id_persona        INTEGER       PRIMARY KEY REFERENCES persona (id_persona),
    id_representante  INTEGER       NOT NULL REFERENCES persona_natural (id_persona),
    ruc               CHAR(11)      NOT NULL,
    razon_social      VARCHAR(150)  NOT NULL,
    CONSTRAINT uq_persona_juridica_ruc UNIQUE (ruc),
    CONSTRAINT ck_persona_juridica_ruc CHECK (ruc ~ '^[0-9]{11}$')
);

CREATE TABLE asesor (
    id_asesor   SERIAL       PRIMARY KEY,
    id_persona  INTEGER      NOT NULL REFERENCES persona (id_persona),
    fecha_alta  DATE         NOT NULL,
    estado      VARCHAR(10)  NOT NULL,
    CONSTRAINT uq_asesor_persona UNIQUE (id_persona)
);

CREATE TABLE oficina (
    codigo_oficina     VARCHAR(10)   PRIMARY KEY,
    nombre             VARCHAR(60)   NOT NULL,
    distrito           VARCHAR(40)   NOT NULL,
    direccion          VARCHAR(150)  NOT NULL,
    es_central         BOOLEAN       NOT NULL,
    ultimo_nro_recibo  INTEGER       NOT NULL DEFAULT 0,
    CONSTRAINT ck_oficina_ultimo_recibo CHECK (ultimo_nro_recibo >= 0)
);

CREATE TABLE separacion (
    id_separacion      SERIAL         PRIMARY KEY,
    id_lote            INTEGER        NOT NULL REFERENCES lote (id_lote),
    id_persona         INTEGER        NOT NULL REFERENCES persona (id_persona),
    id_asesor          INTEGER        REFERENCES asesor (id_asesor),
    fecha_hora         TIMESTAMP      NOT NULL,
    monto              NUMERIC(10,2)  NOT NULL,
    fecha_vencimiento  DATE           NOT NULL,
    estado             VARCHAR(12)    NOT NULL,
    destino_monto      VARCHAR(10),
    CONSTRAINT ck_separacion_monto   CHECK (monto >= 100),
    CONSTRAINT ck_separacion_estado  CHECK (estado IN ('VIGENTE', 'CONVERTIDA', 'RETIRADA', 'VENCIDA')),
    CONSTRAINT ck_separacion_destino CHECK (destino_monto IS NULL OR destino_monto IN ('ESCRITURA', 'PRECIO')),
    CONSTRAINT ck_separacion_fechas  CHECK (fecha_vencimiento >= fecha_hora::date)
);

CREATE TABLE venta (
    id_venta             SERIAL         PRIMARY KEY,
    id_lote              INTEGER        NOT NULL REFERENCES lote (id_lote),
    id_separacion        INTEGER        REFERENCES separacion (id_separacion),
    id_asesor            INTEGER        REFERENCES asesor (id_asesor),
    codigo_oficina       VARCHAR(10)    NOT NULL REFERENCES oficina (codigo_oficina),
    fecha_venta          DATE           NOT NULL,
    modalidad            VARCHAR(7)     NOT NULL,
    precio_lista         NUMERIC(12,2)  NOT NULL,
    descuento            NUMERIC(12,2)  NOT NULL DEFAULT 0,
    inicial              NUMERIC(12,2)  NOT NULL,
    plazo_meses          SMALLINT,
    dia_pago             SMALLINT,
    fecha_primera_cuota  DATE,
    estado_venta         VARCHAR(15)    NOT NULL,
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
    CONSTRAINT ck_venta_plazo CHECK (
        modalidad = 'CONTADO'
        OR (plazo_meses >= 1 AND (plazo_meses <= 12 OR motivo_excepcion IS NOT NULL))
    ),
    CONSTRAINT ck_venta_inicial_minima CHECK (
        modalidad = 'CONTADO'
        OR inicial >= 0.5 * (precio_lista - descuento)
        OR motivo_excepcion IS NOT NULL
    )
);

CREATE TABLE venta_participante (
    id_venta    INTEGER      NOT NULL REFERENCES venta (id_venta),
    id_persona  INTEGER      NOT NULL REFERENCES persona (id_persona),
    rol         VARCHAR(15)  NOT NULL,
    PRIMARY KEY (id_venta, id_persona),
    CONSTRAINT ck_venta_participante_rol CHECK (rol IN ('TITULAR', 'COPROPIETARIO', 'FINANCIADOR'))
);

-- =====================================================================
-- MÓDULO 3: COBRANZA Y COMISIONES
-- =====================================================================

CREATE TABLE cuenta_bancaria (
    id_cuenta   SERIAL       PRIMARY KEY,
    banco       VARCHAR(40)  NOT NULL,
    nro_cuenta  VARCHAR(30)  NOT NULL,
    cci         VARCHAR(20),
    moneda      CHAR(3)      NOT NULL,
    estado      VARCHAR(10)  NOT NULL,
    CONSTRAINT uq_cuenta_bancaria UNIQUE (banco, nro_cuenta)
);

CREATE TABLE cuota (
    id_venta           INTEGER        NOT NULL REFERENCES venta (id_venta),
    nro_cuota          SMALLINT       NOT NULL,
    fecha_vencimiento  DATE           NOT NULL,
    monto              NUMERIC(12,2)  NOT NULL,
    estado_cuota       VARCHAR(12)    NOT NULL,
    PRIMARY KEY (id_venta, nro_cuota),
    CONSTRAINT ck_cuota_nro    CHECK (nro_cuota > 0),
    CONSTRAINT ck_cuota_monto  CHECK (monto > 0),
    CONSTRAINT ck_cuota_estado CHECK (estado_cuota IN ('PENDIENTE', 'PAGADA', 'PARCIAL', 'VENCIDA'))
);

CREATE TABLE pago (
    id_pago         SERIAL         PRIMARY KEY,
    codigo_oficina  VARCHAR(10)    NOT NULL REFERENCES oficina (codigo_oficina),
    nro_recibo      INTEGER        NOT NULL,
    id_venta        INTEGER        REFERENCES venta (id_venta),
    id_separacion   INTEGER        REFERENCES separacion (id_separacion),
    id_cuenta       INTEGER        REFERENCES cuenta_bancaria (id_cuenta),
    fecha_hora      TIMESTAMP      NOT NULL,
    concepto        VARCHAR(20)    NOT NULL,
    monto           NUMERIC(12,2)  NOT NULL,
    medio_pago      VARCHAR(15)    NOT NULL,
    nro_operacion   VARCHAR(30),
    estado_recibo   VARCHAR(10)    NOT NULL,
    CONSTRAINT uq_pago_recibo_oficina UNIQUE (codigo_oficina, nro_recibo),
    CONSTRAINT ck_pago_monto    CHECK (monto > 0),
    CONSTRAINT ck_pago_concepto CHECK (concepto IN ('SEPARACION', 'INICIAL', 'CUOTA',
                                                    'CANCELACION', 'GASTOS_ESCRITURA')),
    CONSTRAINT ck_pago_medio    CHECK (medio_pago IN ('EFECTIVO', 'DEPOSITO', 'TRANSFERENCIA')),
    CONSTRAINT ck_pago_estado   CHECK (estado_recibo IN ('EMITIDO', 'ANULADO')),
    CONSTRAINT ck_pago_arco CHECK (num_nonnulls(id_venta, id_separacion) = 1),
    CONSTRAINT ck_pago_no_efectivo CHECK (
        medio_pago = 'EFECTIVO' OR (id_cuenta IS NOT NULL AND nro_operacion IS NOT NULL)
    )
);

CREATE TABLE pago_cuota (
    id_pago         INTEGER        NOT NULL REFERENCES pago (id_pago),
    id_venta        INTEGER        NOT NULL,
    nro_cuota       SMALLINT       NOT NULL,
    monto_aplicado  NUMERIC(12,2)  NOT NULL,
    PRIMARY KEY (id_pago, id_venta, nro_cuota),
    CONSTRAINT fk_pago_cuota_cuota FOREIGN KEY (id_venta, nro_cuota)
        REFERENCES cuota (id_venta, nro_cuota),
    CONSTRAINT ck_pago_cuota_monto CHECK (monto_aplicado > 0)
);

CREATE TABLE comision (
    id_comision       SERIAL         PRIMARY KEY,
    id_venta          INTEGER        NOT NULL REFERENCES venta (id_venta),
    tramo             VARCHAR(6)     NOT NULL,
    base              NUMERIC(12,2)  NOT NULL,
    porcentaje        NUMERIC(4,2)   NOT NULL DEFAULT 8,
    monto             NUMERIC(12,2)  NOT NULL,
    fecha_generacion  DATE           NOT NULL,
    estado            VARCHAR(12)    NOT NULL,
    CONSTRAINT uq_comision_venta_tramo UNIQUE (id_venta, tramo),
    CONSTRAINT ck_comision_tramo      CHECK (tramo IN ('UNICO', 'TRAMO1', 'TRAMO2')),
    CONSTRAINT ck_comision_valores    CHECK (base >= 0 AND porcentaje >= 0 AND monto >= 0),
    CONSTRAINT ck_comision_estado     CHECK (estado IN ('PENDIENTE', 'PARCIAL', 'PAGADA'))
);

CREATE TABLE pago_comision (
    id_pago_comision  SERIAL         PRIMARY KEY,
    id_comision       INTEGER        NOT NULL REFERENCES comision (id_comision),
    fecha_pago        DATE           NOT NULL,
    monto             NUMERIC(12,2)  NOT NULL,
    medio_pago        VARCHAR(15)    NOT NULL,
    descripcion       VARCHAR(200),
    CONSTRAINT ck_pago_comision_monto CHECK (monto > 0)
);

-- =====================================================================
-- MÓDULO 4: PERSONAL Y SUELDOS
-- =====================================================================

CREATE TABLE empleado (
    id_empleado     SERIAL       PRIMARY KEY,
    id_persona      INTEGER      NOT NULL REFERENCES persona_natural (id_persona),
    codigo_oficina  VARCHAR(10)  NOT NULL REFERENCES oficina (codigo_oficina),
    id_proyecto     INTEGER      REFERENCES proyecto (id_proyecto),
    cargo           VARCHAR(40)  NOT NULL,
    fecha_ingreso   DATE         NOT NULL,
    fecha_cese      DATE,
    estado          VARCHAR(10)  NOT NULL,
    CONSTRAINT uq_empleado_persona UNIQUE (id_persona),
    CONSTRAINT ck_empleado_fechas  CHECK (fecha_cese IS NULL OR fecha_cese >= fecha_ingreso)
);

CREATE TABLE sueldo (
    id_sueldo      SERIAL         PRIMARY KEY,
    id_empleado    INTEGER        NOT NULL REFERENCES empleado (id_empleado),
    monto_mensual  NUMERIC(10,2)  NOT NULL,
    fecha_inicio   DATE           NOT NULL,
    fecha_fin      DATE,
    CONSTRAINT ck_sueldo_monto  CHECK (monto_mensual > 0),
    CONSTRAINT ck_sueldo_fechas CHECK (fecha_fin IS NULL OR fecha_fin >= fecha_inicio)
);

CREATE TABLE pago_sueldo (
    id_pago_sueldo  SERIAL         PRIMARY KEY,
    id_empleado     INTEGER        NOT NULL REFERENCES empleado (id_empleado),
    periodo         CHAR(7)        NOT NULL,
    fecha_pago      DATE           NOT NULL,
    monto           NUMERIC(10,2)  NOT NULL,
    medio_pago      VARCHAR(15)    NOT NULL,
    CONSTRAINT uq_pago_sueldo_periodo UNIQUE (id_empleado, periodo),
    CONSTRAINT ck_pago_sueldo_periodo CHECK (periodo ~ '^[0-9]{4}-(0[1-9]|1[0-2])$'),
    CONSTRAINT ck_pago_sueldo_monto   CHECK (monto > 0)
);

-- =====================================================================
-- ÍNDICES ÚNICOS PARCIALES
-- =====================================================================

CREATE UNIQUE INDEX uq_venta_lote_activa
    ON venta (id_lote) WHERE estado_venta IN ('ACTIVA', 'CANCELADA');
CREATE UNIQUE INDEX uq_separacion_lote_vigente
    ON separacion (id_lote) WHERE estado = 'VIGENTE';

CREATE UNIQUE INDEX uq_precio_lote_vigente
    ON precio_lote (id_lote) WHERE fecha_fin IS NULL;

CREATE UNIQUE INDEX uq_sueldo_vigente
    ON sueldo (id_empleado) WHERE fecha_fin IS NULL;

CREATE UNIQUE INDEX uq_venta_un_titular
    ON venta_participante (id_venta) WHERE rol = 'TITULAR';
CREATE UNIQUE INDEX uq_venta_un_financiador
    ON venta_participante (id_venta) WHERE rol = 'FINANCIADOR';

CREATE UNIQUE INDEX uq_oficina_central
    ON oficina (es_central) WHERE es_central;

-- =====================================================================
-- ÍNDICES DE APOYO (claves foráneas)
-- =====================================================================

CREATE INDEX ix_precio_lote_lote        ON precio_lote (id_lote);
CREATE INDEX ix_persona_juridica_repr   ON persona_juridica (id_representante);
CREATE INDEX ix_separacion_lote         ON separacion (id_lote);
CREATE INDEX ix_separacion_persona      ON separacion (id_persona);
CREATE INDEX ix_separacion_asesor       ON separacion (id_asesor);
CREATE INDEX ix_venta_lote              ON venta (id_lote);
CREATE INDEX ix_venta_asesor            ON venta (id_asesor);
CREATE INDEX ix_venta_oficina           ON venta (codigo_oficina);
CREATE INDEX ix_venta_participante_pers ON venta_participante (id_persona);
CREATE INDEX ix_cuota_vencimiento       ON cuota (fecha_vencimiento);
CREATE INDEX ix_pago_venta              ON pago (id_venta);
CREATE INDEX ix_pago_separacion         ON pago (id_separacion);
CREATE INDEX ix_pago_cuenta             ON pago (id_cuenta);
CREATE INDEX ix_pago_cuota_cuota        ON pago_cuota (id_venta, nro_cuota);
CREATE INDEX ix_pago_comision_comision  ON pago_comision (id_comision);
CREATE INDEX ix_empleado_oficina        ON empleado (codigo_oficina);
CREATE INDEX ix_empleado_proyecto       ON empleado (id_proyecto);
CREATE INDEX ix_sueldo_empleado         ON sueldo (id_empleado);

-- =====================================================================
-- TRIGGERS (reglas que no caben en una sola restricción)
-- =====================================================================

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

CREATE FUNCTION fn_persona_requiere_subtipo() RETURNS trigger AS $$
BEGIN
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
