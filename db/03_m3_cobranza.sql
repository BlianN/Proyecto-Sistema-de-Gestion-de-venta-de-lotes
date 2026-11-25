-- =====================================================================
-- MÓDULO 3: COBRANZA Y COMISIONES
-- Responsable: Mijael Pol Escobar
-- Tablas: oficina, cuenta_bancaria, cuota, pago, pago_cuota,
--         comision, pago_comision
-- Funciones: fn_generar_cronograma, fn_recalcular_estado_cuotas
--
-- Integridad referencial (entregable 3):
--   * Si cambia el código de una oficina, el cambio se propaga a ventas,
--     pagos y empleados (ON UPDATE CASCADE).
--   * Borrar una venta borra su cronograma de cuotas (ON DELETE CASCADE),
--     pero una venta con pagos no se puede borrar: pago -> venta no tiene
--     CASCADE, así que la base lo impide.
--   * Borrar un pago borra su aplicación a las cuotas (ON DELETE CASCADE).
-- =====================================================================

BEGIN;

CREATE TABLE oficina (
    codigo_oficina     VARCHAR(10)   PRIMARY KEY,
    nombre             VARCHAR(60)   NOT NULL,
    distrito           VARCHAR(40)   NOT NULL,
    direccion          VARCHAR(150)  NOT NULL,
    es_central         BOOLEAN       NOT NULL DEFAULT FALSE,
    ultimo_nro_recibo  INTEGER       NOT NULL DEFAULT 0,
    CONSTRAINT uq_oficina_nombre        UNIQUE (nombre),
    CONSTRAINT ck_oficina_codigo        CHECK (codigo_oficina ~ '^[A-Z0-9-]{2,10}$'),
    CONSTRAINT ck_oficina_ultimo_recibo CHECK (ultimo_nro_recibo >= 0)
);

-- Solo una oficina puede ser la central.
CREATE UNIQUE INDEX uq_oficina_central ON oficina (es_central) WHERE es_central;

-- La tabla venta (módulo 2) se creó antes que oficina; aquí se agrega su FK.
ALTER TABLE venta
    ADD CONSTRAINT fk_venta_oficina FOREIGN KEY (codigo_oficina)
        REFERENCES oficina (codigo_oficina) ON UPDATE CASCADE;

CREATE TABLE cuenta_bancaria (
    id_cuenta   SERIAL       PRIMARY KEY,
    banco       VARCHAR(40)  NOT NULL,
    nro_cuenta  VARCHAR(30)  NOT NULL,
    cci         VARCHAR(20),
    moneda      CHAR(3)      NOT NULL DEFAULT 'PEN',
    estado      VARCHAR(10)  NOT NULL DEFAULT 'ACTIVA',
    CONSTRAINT uq_cuenta_bancaria        UNIQUE (banco, nro_cuenta),
    CONSTRAINT uq_cuenta_bancaria_cci    UNIQUE (cci),
    CONSTRAINT ck_cuenta_bancaria_cci    CHECK (cci IS NULL OR cci ~ '^[0-9]{20}$'),
    CONSTRAINT ck_cuenta_bancaria_moneda CHECK (moneda IN ('PEN', 'USD')),
    CONSTRAINT ck_cuenta_bancaria_estado CHECK (estado IN ('ACTIVA', 'INACTIVA'))
);

CREATE TABLE cuota (
    id_venta           INTEGER        NOT NULL
                       REFERENCES venta (id_venta) ON DELETE CASCADE,
    nro_cuota          SMALLINT       NOT NULL,
    fecha_vencimiento  DATE           NOT NULL,
    monto              NUMERIC(12,2)  NOT NULL,
    estado_cuota       VARCHAR(12)    NOT NULL DEFAULT 'PENDIENTE',
    PRIMARY KEY (id_venta, nro_cuota),
    CONSTRAINT ck_cuota_nro    CHECK (nro_cuota > 0),
    CONSTRAINT ck_cuota_monto  CHECK (monto > 0),
    CONSTRAINT ck_cuota_estado CHECK (estado_cuota IN ('PENDIENTE', 'PAGADA', 'PARCIAL', 'VENCIDA'))
);

CREATE TABLE pago (
    id_pago         SERIAL         PRIMARY KEY,
    codigo_oficina  VARCHAR(10)    NOT NULL
                    REFERENCES oficina (codigo_oficina) ON UPDATE CASCADE,
    nro_recibo      INTEGER        NOT NULL,
    id_venta        INTEGER        REFERENCES venta (id_venta),
    id_separacion   INTEGER        REFERENCES separacion (id_separacion),
    id_cuenta       INTEGER        REFERENCES cuenta_bancaria (id_cuenta),
    fecha_hora      TIMESTAMP      NOT NULL DEFAULT now(),
    concepto        VARCHAR(20)    NOT NULL,
    monto           NUMERIC(12,2)  NOT NULL,
    medio_pago      VARCHAR(15)    NOT NULL,
    nro_operacion   VARCHAR(30),
    estado_recibo   VARCHAR(10)    NOT NULL DEFAULT 'EMITIDO',
    -- Cada oficina tiene su propia numeración de recibos.
    CONSTRAINT uq_pago_recibo_oficina UNIQUE (codigo_oficina, nro_recibo),
    CONSTRAINT ck_pago_nro_recibo CHECK (nro_recibo > 0),
    CONSTRAINT ck_pago_monto      CHECK (monto > 0),
    CONSTRAINT ck_pago_concepto   CHECK (concepto IN ('SEPARACION', 'INICIAL', 'CUOTA',
                                                      'CANCELACION', 'GASTOS_ESCRITURA')),
    CONSTRAINT ck_pago_medio      CHECK (medio_pago IN ('EFECTIVO', 'DEPOSITO', 'TRANSFERENCIA')),
    CONSTRAINT ck_pago_estado     CHECK (estado_recibo IN ('EMITIDO', 'ANULADO')),
    -- Un pago corresponde a una venta o a una separación, nunca a las dos (arco exclusivo).
    CONSTRAINT ck_pago_arco       CHECK (num_nonnulls(id_venta, id_separacion) = 1),
    CONSTRAINT ck_pago_concepto_separacion
        CHECK ((concepto = 'SEPARACION') = (id_separacion IS NOT NULL)),
    -- Si no es efectivo, se sabe a qué cuenta entró y con qué operación.
    CONSTRAINT ck_pago_no_efectivo CHECK (
        medio_pago = 'EFECTIVO' OR (id_cuenta IS NOT NULL AND nro_operacion IS NOT NULL)
    )
);

CREATE TABLE pago_cuota (
    id_pago         INTEGER        NOT NULL
                    REFERENCES pago (id_pago) ON DELETE CASCADE,
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
    fecha_generacion  DATE           NOT NULL DEFAULT CURRENT_DATE,
    estado            VARCHAR(12)    NOT NULL DEFAULT 'PENDIENTE',
    CONSTRAINT uq_comision_venta_tramo UNIQUE (id_venta, tramo),
    CONSTRAINT ck_comision_tramo      CHECK (tramo IN ('UNICO', 'TRAMO1', 'TRAMO2')),
    CONSTRAINT ck_comision_valores    CHECK (base >= 0 AND porcentaje BETWEEN 0 AND 100 AND monto >= 0),
    CONSTRAINT ck_comision_estado     CHECK (estado IN ('PENDIENTE', 'PARCIAL', 'PAGADA'))
);

CREATE TABLE pago_comision (
    id_pago_comision  SERIAL         PRIMARY KEY,
    id_comision       INTEGER        NOT NULL REFERENCES comision (id_comision),
    fecha_pago        DATE           NOT NULL DEFAULT CURRENT_DATE,
    monto             NUMERIC(12,2)  NOT NULL,
    medio_pago        VARCHAR(15)    NOT NULL,
    descripcion       VARCHAR(200),
    CONSTRAINT ck_pago_comision_monto CHECK (monto > 0),
    CONSTRAINT ck_pago_comision_medio CHECK (medio_pago IN ('EFECTIVO', 'DEPOSITO',
                                                             'TRANSFERENCIA', 'INTERNO'))
);

-- ---------------------------------------------------------------------
-- Índices de apoyo para claves foráneas
-- ---------------------------------------------------------------------
CREATE INDEX ix_pago_venta             ON pago (id_venta);
CREATE INDEX ix_pago_separacion        ON pago (id_separacion);
CREATE INDEX ix_pago_cuenta            ON pago (id_cuenta);
CREATE INDEX ix_pago_cuota_cuota       ON pago_cuota (id_venta, nro_cuota);
CREATE INDEX ix_comision_venta         ON comision (id_venta);
CREATE INDEX ix_pago_comision_comision ON pago_comision (id_comision);

-- ---------------------------------------------------------------------
-- fn_generar_cronograma(id_venta)
-- Crea las cuotas de una venta en cuotas:
--   saldo = precio_lista - descuento - inicial, repartido en plazo_meses.
--   La primera cuota vence en fecha_primera_cuota; las siguientes, cada
--   mes en el día de pago (o el último día del mes si ese día no existe).
--   La última cuota absorbe la diferencia del redondeo.
-- La usa el endpoint de registro de ventas del módulo 2.
-- ---------------------------------------------------------------------
CREATE FUNCTION fn_generar_cronograma(p_id_venta INTEGER) RETURNS INTEGER AS $$
DECLARE
    v        venta%ROWTYPE;
    v_saldo  NUMERIC(12,2);
    v_cuota  NUMERIC(12,2);
    v_mes    DATE;
    v_fecha  DATE;
    i        INTEGER;
BEGIN
    SELECT * INTO v FROM venta WHERE id_venta = p_id_venta;
    IF NOT FOUND THEN
        RAISE EXCEPTION 'La venta % no existe', p_id_venta;
    END IF;
    IF v.modalidad <> 'CUOTAS' THEN
        RAISE EXCEPTION 'La venta % es al contado y no tiene cronograma', p_id_venta;
    END IF;
    IF EXISTS (SELECT 1 FROM cuota WHERE id_venta = p_id_venta) THEN
        RAISE EXCEPTION 'La venta % ya tiene cronograma', p_id_venta;
    END IF;

    v_saldo := v.precio_lista - v.descuento - v.inicial;
    IF v_saldo <= 0 THEN
        RAISE EXCEPTION 'La venta % no tiene saldo por financiar', p_id_venta;
    END IF;
    v_cuota := round(v_saldo / v.plazo_meses, 2);

    FOR i IN 1 .. v.plazo_meses LOOP
        IF i = 1 THEN
            v_fecha := v.fecha_primera_cuota;
        ELSE
            v_mes   := (date_trunc('month', v.fecha_primera_cuota) + (i - 1) * INTERVAL '1 month')::date;
            v_fecha := v_mes + (LEAST(v.dia_pago,
                         EXTRACT(DAY FROM (v_mes + INTERVAL '1 month - 1 day'))::int) - 1);
        END IF;

        INSERT INTO cuota (id_venta, nro_cuota, fecha_vencimiento, monto, estado_cuota)
        VALUES (p_id_venta, i, v_fecha,
                CASE WHEN i < v.plazo_meses THEN v_cuota
                     ELSE v_saldo - v_cuota * (v.plazo_meses - 1) END,
                'PENDIENTE');
    END LOOP;

    RETURN v.plazo_meses;
END;
$$ LANGUAGE plpgsql;

-- ---------------------------------------------------------------------
-- fn_recalcular_estado_cuotas(id_venta)
-- Pone el estado de cada cuota según lo pagado (solo recibos EMITIDOS):
--   PAGADA si se cubrió el monto, PARCIAL si se pagó algo,
--   VENCIDA si no se pagó nada y ya pasó su fecha, y si no PENDIENTE.
-- ---------------------------------------------------------------------
CREATE FUNCTION fn_recalcular_estado_cuotas(p_id_venta INTEGER) RETURNS VOID AS $$
BEGIN
    UPDATE cuota c
    SET    estado_cuota = CASE
               WHEN x.pagado >= c.monto                 THEN 'PAGADA'
               WHEN x.pagado > 0                        THEN 'PARCIAL'
               WHEN c.fecha_vencimiento < CURRENT_DATE  THEN 'VENCIDA'
               ELSE 'PENDIENTE'
           END
    FROM  (SELECT cu.nro_cuota,
                  COALESCE(SUM(pc.monto_aplicado)
                           FILTER (WHERE p.estado_recibo = 'EMITIDO'), 0) AS pagado
           FROM   cuota cu
           LEFT JOIN pago_cuota pc ON pc.id_venta = cu.id_venta AND pc.nro_cuota = cu.nro_cuota
           LEFT JOIN pago p        ON p.id_pago = pc.id_pago
           WHERE  cu.id_venta = p_id_venta
           GROUP BY cu.nro_cuota) AS x
    WHERE  c.id_venta = p_id_venta
      AND  c.nro_cuota = x.nro_cuota;
END;
$$ LANGUAGE plpgsql;

COMMIT;
