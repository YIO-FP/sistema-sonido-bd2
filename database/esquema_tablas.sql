
-- 1. Categorías
CREATE TABLE IF NOT EXISTS categorias (
    id_categoria SERIAL PRIMARY KEY,
    nombre VARCHAR(60) NOT NULL UNIQUE
);

-- 2. Clientes (Contacto básico sin NIT)
CREATE TABLE IF NOT EXISTS clientes (
    id_cliente SERIAL PRIMARY KEY,
    nombre_completo VARCHAR(150) NOT NULL,
    telefono VARCHAR(20) NOT NULL
);

-- 3. Catálogo maestro de equipos y servicios
CREATE TABLE IF NOT EXISTS items (
    id_item SERIAL PRIMARY KEY,
    id_categoria INT NOT NULL,
    nombre VARCHAR(120) NOT NULL,
    descripcion TEXT,
    precio_unitario NUMERIC(10, 2) NOT NULL DEFAULT 0.00,
    stock_disponible INT NOT NULL DEFAULT 1,
    CONSTRAINT fk_items_categorias FOREIGN KEY (id_categoria) 
        REFERENCES categorias(id_categoria) ON DELETE RESTRICT
);

-- 4. Plantillas de paquetes comerciales
CREATE TABLE IF NOT EXISTS paquetes (
    id_paquete SERIAL PRIMARY KEY,
    nombre VARCHAR(100) NOT NULL,
    descripcion TEXT,
    precio_base NUMERIC(10, 2) NOT NULL DEFAULT 0.00
);

-- 5. Composición estándar del paquete
CREATE TABLE IF NOT EXISTS paquete_detalles (
    id_paquete INT NOT NULL,
    id_item INT NOT NULL,
    cantidad INT NOT NULL CHECK (cantidad > 0),
    PRIMARY KEY (id_paquete, id_item),
    CONSTRAINT fk_pd_paquetes FOREIGN KEY (id_paquete) 
        REFERENCES paquetes(id_paquete) ON DELETE CASCADE,
    CONSTRAINT fk_pd_items FOREIGN KEY (id_item) 
        REFERENCES items(id_item) ON DELETE RESTRICT
);

-- 6. Eventos o cotizaciones solicitadas
CREATE TABLE IF NOT EXISTS eventos_cotizaciones (
    id_cotizacion SERIAL PRIMARY KEY,
    id_cliente INT NOT NULL,
    id_paquete_base INT NULL,
    fecha_solicitud TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    fecha_evento DATE NOT NULL,
    direccion_evento VARCHAR(255) NOT NULL,
    total_estimado NUMERIC(10, 2) NOT NULL DEFAULT 0.00,
    estado VARCHAR(20) NOT NULL DEFAULT 'pendiente' 
        CHECK (estado IN ('pendiente', 'confirmado', 'en_curso', 'finalizado', 'cancelado')),
    CONSTRAINT fk_eventos_clientes FOREIGN KEY (id_cliente) 
        REFERENCES clientes(id_cliente) ON DELETE RESTRICT,
    CONSTRAINT fk_eventos_paquetes FOREIGN KEY (id_paquete_base) 
        REFERENCES paquetes(id_paquete) ON DELETE SET NULL
);

-- 7. Desglose detallado del evento (carrito personalizado)
CREATE TABLE IF NOT EXISTS cotizacion_detalles (
    id_detalle SERIAL PRIMARY KEY,
    id_cotizacion INT NOT NULL,
    id_item INT NOT NULL,
    cantidad INT NOT NULL CHECK (cantidad > 0),
    precio_unitario NUMERIC(10, 2) NOT NULL,
    subtotal NUMERIC(10, 2) GENERATED ALWAYS AS (cantidad * precio_unitario) STORED,
    CONSTRAINT fk_cd_cotizacion FOREIGN KEY (id_cotizacion) 
        REFERENCES eventos_cotizaciones(id_cotizacion) ON DELETE CASCADE,
    CONSTRAINT fk_cd_items FOREIGN KEY (id_item) 
        REFERENCES items(id_item) ON DELETE RESTRICT
);

-- Inserción de datos iniciales
INSERT INTO categorias (nombre) VALUES 
('Tarimas y Estructuras'),
('Iluminación Móvil'),
('Efectos y Estrobos'),
('Personal')
ON CONFLICT (nombre) DO NOTHING;

INSERT INTO items (id_categoria, nombre, descripcion, precio_unitario, stock_disponible) VALUES
(1, 'Tarima modular 2m x 3m', 'Módulos antideslizantes con estructura', 600.00, 4),
(1, 'Torre elevadora (Catraca) 3m', 'Torre telescópica con winche', 250.00, 6),
(3, 'Luz Estrobo LED', 'Panel estroboscópico de alta potencia', 150.00, 16),
(2, 'Cabeza Móvil Beam 360', 'Luminaria robotizada Beam 360', 350.00, 8),
(4, 'Servicio de DJ', 'Operador de cabina por 6 horas', 800.00, 2)
ON CONFLICT DO NOTHING;

INSERT INTO paquetes (nombre, descripcion, precio_base) VALUES
('Paquete Básico', 'Tarima 2x3m, torres catraca de 3m, 8 estrobos y 2 cabezas móviles Beam 360', 3500.00)
ON CONFLICT DO NOTHING;

INSERT INTO paquete_detalles (id_paquete, id_item, cantidad) VALUES
(1, 1, 1),
(1, 2, 2),
(1, 3, 8),
(1, 4, 2)
ON CONFLICT DO NOTHING;