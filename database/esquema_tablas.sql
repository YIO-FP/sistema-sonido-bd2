
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
-- =====================================================
-- 1. ASEGURAR CATEGORÍAS TÉCNICAS
-- =====================================================
INSERT INTO categorias (nombre) VALUES
    ('Sistema de Sonido Principal'),
    ('Monitoreo de Escenario y Microfonía'),
    ('Iluminación y Efectos Visuales'),
    ('Pantallas LED y Circuito Visual'),
    ('Tarimas y Estructuras de Montaje')
ON CONFLICT (nombre) DO NOTHING;

-- =====================================================
-- 2. POBLAR / ACTUALIZAR EL STOCK TOTAL DE ITEMS
-- =====================================================
INSERT INTO items (id_categoria, nombre, descripcion, precio_unitario, stock_disponible)
VALUES
    -- Sistema de Sonido Principal
    ((SELECT id_categoria FROM categorias WHERE nombre = 'Sistema de Sonido Principal'),
     'Subwoofer BASSBOSS 18"', 'Subgrave activo de alta potencia y respuesta en frecuencias ultra-bajas', 350.00, 20),

    ((SELECT id_categoria FROM categorias WHERE nombre = 'Sistema de Sonido Principal'),
     'Cajas acústicas NEXO 10"', 'Sistema de medios/agudos de alta fidelidad para refuerzo sonoro principal (10 por lado)', 200.00, 20),

    ((SELECT id_categoria FROM categorias WHERE nombre = 'Sistema de Sonido Principal'),
     'Consola Digital Midas X32', 'Consola digital para mezcla en vivo FOH con procesamiento multicanal', 500.00, 1),

    ((SELECT id_categoria FROM categorias WHERE nombre = 'Sistema de Sonido Principal'),
     'Consola Digital Soundcraft Ui24R', 'Mezcladora digital en rack controlable por Wi-Fi para monitoreo y sala', 300.00, 1),

    -- Monitoreo de Escenario y Microfonía
    ((SELECT id_categoria FROM categorias WHERE nombre = 'Monitoreo de Escenario y Microfonía'),
     'Monitores de Piso RCF', 'Monitor de retorno autoamplificado RCF para escenario', 130.00, 6),

    ((SELECT id_categoria FROM categorias WHERE nombre = 'Monitoreo de Escenario y Microfonía'),
     'Monitores de Piso JBL', 'Monitor de retorno autoamplificado JBL para escenario', 120.00, 4),

    ((SELECT id_categoria FROM categorias WHERE nombre = 'Monitoreo de Escenario y Microfonía'),
     'Micrófonos Inalámbricos', 'Sistema de microfonía inalámbrica profesional para voces y animación', 80.00, 4),

    ((SELECT id_categoria FROM categorias WHERE nombre = 'Monitoreo de Escenario y Microfonía'),
     'Micrófono con Cable Shure Beta 58A / 57A', 'Micrófonos dinámicos supercardioides profesionales para voces e instrumentos', 50.00, 12),

    ((SELECT id_categoria FROM categorias WHERE nombre = 'Monitoreo de Escenario y Microfonía'),
     'Pedestales de alta gama Hércules', 'Soporte telescópico reforzado con agarre rápido para microfonía', 25.00, 12),

    -- Iluminación y Efectos Visuales
    ((SELECT id_categoria FROM categorias WHERE nombre = 'Iluminación y Efectos Visuales'),
     'Cabezas Móviles Weinas Beam', 'Luminarias robóticas de haz concentrado Beam para efectos aéreos', 150.00, 6),

    ((SELECT id_categoria FROM categorias WHERE nombre = 'Iluminación y Efectos Visuales'),
     'Barras LED RGB', 'Barra lineal LED para iluminación perimetral y baño de color', 70.00, 20),

    ((SELECT id_categoria FROM categorias WHERE nombre = 'Iluminación y Efectos Visuales'),
     'Estrobo 1000 W', 'Luz estroboscópica de alto impacto visual para remates de iluminación', 80.00, 8),

    ((SELECT id_categoria FROM categorias WHERE nombre = 'Iluminación y Efectos Visuales'),
     'Estrobo 1500 W', 'Luz estroboscópica de máxima potencia para conciertos masivos', 100.00, 8),

    ((SELECT id_categoria FROM categorias WHERE nombre = 'Iluminación y Efectos Visuales'),
     'Máquina lanzahumo Weinas', 'Generador de niebla DMX de alto caudal para realce de luces', 120.00, 2),

    ((SELECT id_categoria FROM categorias WHERE nombre = 'Iluminación y Efectos Visuales'),
     'Máquinas lanzallamas DMX', 'Efecto pirotécnico escénico de fuego controlado por DMX', 250.00, 2),

    -- Pantallas LED y Circuito Visual
    ((SELECT id_categoria FROM categorias WHERE nombre = 'Pantallas LED y Circuito Visual'),
     'Módulo Gabinete LED NovaStar Outdoor (1.00 m x 0.50 m)', 'Gabinete para pantalla LED gigante exterior de alta luminosidad P3.91', 180.00, 12),

    -- Tarimas y Estructuras de Montaje
    ((SELECT id_categoria FROM categorias WHERE nombre = 'Tarimas y Estructuras de Montaje'),
     'Tarima Principal 8.00m x 5.00m x 1.50m con escaleras', 'Plataforma escénica modular reforzada con escalera de acceso', 1800.00, 1),

    ((SELECT id_categoria FROM categorias WHERE nombre = 'Tarimas y Estructuras de Montaje'),
     'Tarima Mediana 5.00m x 3.50m x 1.00m', 'Plataforma escénica modular mediana con altura de 1 metro', 1100.00, 1),

    ((SELECT id_categoria FROM categorias WHERE nombre = 'Tarimas y Estructuras de Montaje'),
     'Puente de Iluminación Truss 9.00 m', 'Estructura truss de aluminio de alta resistencia para colgado de luces', 450.00, 3),

    ((SELECT id_categoria FROM categorias WHERE nombre = 'Tarimas y Estructuras de Montaje'),
     'Torres Elevadoras Telescópicas 3.00 m (Par)', 'Par de torres elevadoras con malacate manual y acople superior para truss', 350.00, 1),

    ((SELECT id_categoria FROM categorias WHERE nombre = 'Tarimas y Estructuras de Montaje'),
     'Torre de Andamio Reforzado 5.40 m', 'Torres de andamio reforzado de dos módulos por lado para colgado', 300.00, 4),

    ((SELECT id_categoria FROM categorias WHERE nombre = 'Tarimas y Estructuras de Montaje'),
     'Torre Multidireccional Layher 6.00 m', 'Torres multidireccionales de alta seguridad y soporte pesado para line array', 600.00, 2)
ON CONFLICT DO NOTHING;

-- =====================================================
-- 3. CABECERAS DE LOS 3 PAQUETES
-- =====================================================
INSERT INTO paquetes (nombre, descripcion, precio_base)
VALUES
    ('Paquete Concierto Masivo (Grande)', 
     'Montaje completo: 20 subs, 16 medios, Layher 6m, 2 truss 9m, 6 beam, 16 strobos, 12 pantallas y efectos', 
     14000.00),

    ('Paquete Concierto Estándar (Mediano)', 
     'Configuración mediana: 12 subs, 10 medios, andamios 5m, 6 pantallas, tarima 5x3.5m y 2 retornos JBL', 
     8000.00),

    ('Paquete Concierto Básico (Pequeño)', 
     'Montaje compacto: 4 subs, 4 medios, torres telescópicas, 1 truss 9m, 2 beam, 6 barras y 4 strobos 1500W', 
     4000.00)
ON CONFLICT DO NOTHING;

-- =====================================================
-- 4. DETALLE: PAQUETE CONCIERTO MASIVO (GRANDE)
-- =====================================================
INSERT INTO paquete_detalles (id_paquete, id_item, cantidad)
VALUES
    ((SELECT id_paquete FROM paquetes WHERE nombre = 'Paquete Concierto Masivo (Grande)'),
     (SELECT id_item FROM items WHERE nombre = 'Subwoofer BASSBOSS 18"'), 20),

    ((SELECT id_paquete FROM paquetes WHERE nombre = 'Paquete Concierto Masivo (Grande)'),
     (SELECT id_item FROM items WHERE nombre = 'Cajas acústicas NEXO 10"'), 16),

    ((SELECT id_paquete FROM paquetes WHERE nombre = 'Paquete Concierto Masivo (Grande)'),
     (SELECT id_item FROM items WHERE nombre = 'Monitores de Piso RCF'), 4),

    ((SELECT id_paquete FROM paquetes WHERE nombre = 'Paquete Concierto Masivo (Grande)'),
     (SELECT id_item FROM items WHERE nombre = 'Torre Multidireccional Layher 6.00 m'), 2),

    ((SELECT id_paquete FROM paquetes WHERE nombre = 'Paquete Concierto Masivo (Grande)'),
     (SELECT id_item FROM items WHERE nombre = 'Puente de Iluminación Truss 9.00 m'), 2),

    ((SELECT id_paquete FROM paquetes WHERE nombre = 'Paquete Concierto Masivo (Grande)'),
     (SELECT id_item FROM items WHERE nombre = 'Tarima Principal 8.00m x 5.00m x 1.50m con escaleras'), 1),

    ((SELECT id_paquete FROM paquetes WHERE nombre = 'Paquete Concierto Masivo (Grande)'),
     (SELECT id_item FROM items WHERE nombre = 'Cabezas Móviles Weinas Beam'), 6),

    ((SELECT id_paquete FROM paquetes WHERE nombre = 'Paquete Concierto Masivo (Grande)'),
     (SELECT id_item FROM items WHERE nombre = 'Estrobo 1500 W'), 8),

    ((SELECT id_paquete FROM paquetes WHERE nombre = 'Paquete Concierto Masivo (Grande)'),
     (SELECT id_item FROM items WHERE nombre = 'Estrobo 1000 W'), 8),

    ((SELECT id_paquete FROM paquetes WHERE nombre = 'Paquete Concierto Masivo (Grande)'),
     (SELECT id_item FROM items WHERE nombre = 'Barras LED RGB'), 20),

    ((SELECT id_paquete FROM paquetes WHERE nombre = 'Paquete Concierto Masivo (Grande)'),
     (SELECT id_item FROM items WHERE nombre = 'Máquinas lanzallamas DMX'), 2),

    ((SELECT id_paquete FROM paquetes WHERE nombre = 'Paquete Concierto Masivo (Grande)'),
     (SELECT id_item FROM items WHERE nombre = 'Máquina lanzahumo Weinas'), 2),

    ((SELECT id_paquete FROM paquetes WHERE nombre = 'Paquete Concierto Masivo (Grande)'),
     (SELECT id_item FROM items WHERE nombre = 'Módulo Gabinete LED NovaStar Outdoor (1.00 m x 0.50 m)'), 12);

-- =====================================================
-- 5. DETALLE: PAQUETE CONCIERTO ESTÁNDAR (MEDIANO)
-- =====================================================
INSERT INTO paquete_detalles (id_paquete, id_item, cantidad)
VALUES
    ((SELECT id_paquete FROM paquetes WHERE nombre = 'Paquete Concierto Estándar (Mediano)'),
     (SELECT id_item FROM items WHERE nombre = 'Subwoofer BASSBOSS 18"'), 12),

    ((SELECT id_paquete FROM paquetes WHERE nombre = 'Paquete Concierto Estándar (Mediano)'),
     (SELECT id_item FROM items WHERE nombre = 'Cajas acústicas NEXO 10"'), 10),

    ((SELECT id_paquete FROM paquetes WHERE nombre = 'Paquete Concierto Estándar (Mediano)'),
     (SELECT id_item FROM items WHERE nombre = 'Monitores de Piso JBL'), 2),

    ((SELECT id_paquete FROM paquetes WHERE nombre = 'Paquete Concierto Estándar (Mediano)'),
     (SELECT id_item FROM items WHERE nombre = 'Torre de Andamio Reforzado 5.40 m'), 2),

    ((SELECT id_paquete FROM paquetes WHERE nombre = 'Paquete Concierto Estándar (Mediano)'),
     (SELECT id_item FROM items WHERE nombre = 'Tarima Mediana 5.00m x 3.50m x 1.00m'), 1),

    ((SELECT id_paquete FROM paquetes WHERE nombre = 'Paquete Concierto Estándar (Mediano)'),
     (SELECT id_item FROM items WHERE nombre = 'Cabezas Móviles Weinas Beam'), 2),

    ((SELECT id_paquete FROM paquetes WHERE nombre = 'Paquete Concierto Estándar (Mediano)'),
     (SELECT id_item FROM items WHERE nombre = 'Estrobo 1000 W'), 8),

    ((SELECT id_paquete FROM paquetes WHERE nombre = 'Paquete Concierto Estándar (Mediano)'),
     (SELECT id_item FROM items WHERE nombre = 'Barras LED RGB'), 12),

    ((SELECT id_paquete FROM paquetes WHERE nombre = 'Paquete Concierto Estándar (Mediano)'),
     (SELECT id_item FROM items WHERE nombre = 'Máquinas lanzallamas DMX'), 2),

    ((SELECT id_paquete FROM paquetes WHERE nombre = 'Paquete Concierto Estándar (Mediano)'),
     (SELECT id_item FROM items WHERE nombre = 'Módulo Gabinete LED NovaStar Outdoor (1.00 m x 0.50 m)'), 6);

-- =====================================================
-- 6. DETALLE: PAQUETE CONCIERTO BÁSICO (PEQUEÑO)
-- =====================================================
INSERT INTO paquete_detalles (id_paquete, id_item, cantidad)
VALUES
    ((SELECT id_paquete FROM paquetes WHERE nombre = 'Paquete Concierto Básico (Pequeño)'),
     (SELECT id_item FROM items WHERE nombre = 'Subwoofer BASSBOSS 18"'), 4),

    ((SELECT id_paquete FROM paquetes WHERE nombre = 'Paquete Concierto Básico (Pequeño)'),
     (SELECT id_item FROM items WHERE nombre = 'Cajas acústicas NEXO 10"'), 4),

    ((SELECT id_paquete FROM paquetes WHERE nombre = 'Paquete Concierto Básico (Pequeño)'),
     (SELECT id_item FROM items WHERE nombre = 'Torres Elevadoras Telescópicas 3.00 m (Par)'), 1),

    ((SELECT id_paquete FROM paquetes WHERE nombre = 'Paquete Concierto Básico (Pequeño)'),
     (SELECT id_item FROM items WHERE nombre = 'Puente de Iluminación Truss 9.00 m'), 1),

    ((SELECT id_paquete FROM paquetes WHERE nombre = 'Paquete Concierto Básico (Pequeño)'),
     (SELECT id_item FROM items WHERE nombre = 'Cabezas Móviles Weinas Beam'), 2),

    ((SELECT id_paquete FROM paquetes WHERE nombre = 'Paquete Concierto Básico (Pequeño)'),
     (SELECT id_item FROM items WHERE nombre = 'Estrobo 1500 W'), 4),

    ((SELECT id_paquete FROM paquetes WHERE nombre = 'Paquete Concierto Básico (Pequeño)'),
     (SELECT id_item FROM items WHERE nombre = 'Barras LED RGB'), 6);
