```sql
-- ==========================================
-- SISTEMA DE GESTION DE VENTA DE LOTES
-- MODULO 1: PROYECTOS Y LOTES
-- ==========================================

PRAGMA foreign_keys = ON;

-- ==========================================
-- TABLA 1: PROYECTO
-- ==========================================

CREATE TABLE IF NOT EXISTS PROYECTO (
    id_proyecto INTEGER PRIMARY KEY AUTOINCREMENT,
    codigo TEXT NOT NULL UNIQUE,
    nombre TEXT NOT NULL,
    tipo_proyecto TEXT NOT NULL,
    departamento TEXT NOT NULL,
    provincia TEXT NOT NULL,
    distrito TEXT NOT NULL,
    partida_registral TEXT,
    hectareas REAL CHECK (hectareas > 0),
    estado TEXT NOT NULL
);

-- ==========================================
-- TABLA 2: SECTOR
-- ==========================================

CREATE TABLE IF NOT EXISTS SECTOR (
    id_sector INTEGER PRIMARY KEY AUTOINCREMENT,
    id_proyecto INTEGER NOT NULL,
    tipo_sector TEXT NOT NULL
        CHECK (tipo_sector IN ('zona', 'etapa')),
    nombre TEXT NOT NULL,

    FOREIGN KEY (id_proyecto)
        REFERENCES PROYECTO(id_proyecto),

    UNIQUE(id_proyecto, tipo_sector, nombre)
);

-- ==========================================
-- TABLA 3: MANZANA
-- ==========================================

CREATE TABLE IF NOT EXISTS MANZANA (
    id_manzana INTEGER PRIMARY KEY AUTOINCREMENT,
    id_sector INTEGER NOT NULL,
    codigo TEXT NOT NULL,

    FOREIGN KEY (id_sector)
        REFERENCES SECTOR(id_sector),

    UNIQUE(id_sector, codigo)
);

-- ==========================================
-- TABLA 4: LOTE
-- ==========================================

CREATE TABLE IF NOT EXISTS LOTE (
    id_lote INTEGER PRIMARY KEY AUTOINCREMENT,
    id_manzana INTEGER NOT NULL,
    numero TEXT NOT NULL,

    tipo_lote TEXT NOT NULL
        CHECK (tipo_lote IN
        ('vendible', 'area verde', 'aporte', 'FCMP')),

    estado TEXT NOT NULL
        CHECK (estado IN
        ('disponible', 'separado', 'reservado',
         'bloqueado', 'en cuotas', 'cancelado',
         'escriturado')),

    area_m2 REAL NOT NULL CHECK (area_m2 > 0),
    perimetro REAL CHECK (perimetro > 0),
    frente REAL CHECK (frente > 0),
    fondo REAL CHECK (fondo > 0),
    lado_izquierdo REAL CHECK (lado_izquierdo > 0),
    lado_derecho REAL CHECK (lado_derecho > 0),

    colindante_frente TEXT,
    colindante_fondo TEXT,
    colindante_izquierdo TEXT,
    colindante_derecho TEXT,

    partida_registral TEXT,

    es_esquina INTEGER NOT NULL DEFAULT 0
        CHECK (es_esquina IN (0, 1)),

    frente_parque INTEGER NOT NULL DEFAULT 0
        CHECK (frente_parque IN (0, 1)),

    sobre_avenida INTEGER NOT NULL DEFAULT 0
        CHECK (sobre_avenida IN (0, 1)),

    FOREIGN KEY (id_manzana)
        REFERENCES MANZANA(id_manzana),

    UNIQUE(id_manzana, numero)
);

-- ==========================================
-- TABLA 5: PRECIO_LOTE
-- ==========================================

CREATE TABLE IF NOT EXISTS PRECIO_LOTE (
    id_precio INTEGER PRIMARY KEY AUTOINCREMENT,
    id_lote INTEGER NOT NULL,

    precio REAL NOT NULL CHECK (precio > 0),
    fecha_inicio TEXT NOT NULL,
    fecha_fin TEXT,
    motivo TEXT,

    FOREIGN KEY (id_lote)
        REFERENCES LOTE(id_lote),

    CHECK (
        fecha_fin IS NULL
        OR fecha_fin >= fecha_inicio
    )
);

-- ==========================================
-- REGLA: UN SOLO PRECIO VIGENTE POR LOTE
-- ==========================================

CREATE UNIQUE INDEX IF NOT EXISTS
idx_precio_lote_vigente
ON PRECIO_LOTE(id_lote)
WHERE fecha_fin IS NULL;

-- ==========================================
-- FIN DEL MODULO 1
-- ==========================================
```
