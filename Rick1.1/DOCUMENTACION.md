# Plataforma de autogestión y cotización para eventos

## Rick 1.1

La interfaz pública muestra el inventario real por categoría (equipos y unidades disponibles), métricas del catálogo y el detalle comercial de cada paquete. El valor por componentes se calcula desde `paquete_detalles` e `items`; `precio_base` continúa siendo la referencia comercial del paquete. No se publican clientes ni cotizaciones históricas.

## 1. Introducción y arquitectura

Aplicación web de una sola página para explorar equipos de sonido, iluminación, video y estructuras, personalizar uno de los paquetes registrados y solicitar una proforma. Está construida con Python 3.11+, Flask, psycopg2 y PostgreSQL; Jinja2 sirve la página y JavaScript Vanilla consume la API mediante `fetch`. Tailwind CSS se carga desde CDN.

Flujo: **cliente → navegador (catálogo y carrito) → API Flask → PostgreSQL**. El catálogo y paquetes se leen de la base; el carrito es temporal en el navegador. Al confirmar, Flask vuelve a consultar precios y stock y guarda cliente, cabecera y detalle dentro de una sola transacción. La disponibilidad comprobada corresponde al stock total actual, pues el esquema no tiene reservas, fechas de disponibilidad ni decremento de inventario.

El total de la proforma se calcula con la suma de cantidad × precio unitario vigente de cada ítem. `paquetes.precio_base` se muestra como referencia comercial; al seleccionar un paquete, sus componentes se convierten en el carrito editable y el estimado refleja sus ítems y cualquier personalización. El paquete no sustituye ni se suma a esos importes.

## 2. Modelo relacional

El esquema contiene siete tablas. Las claves primarias `SERIAL` generan identificadores; las claves foráneas y restricciones preservan la integridad referencial.

| Tabla | Propósito y reglas |
|---|---|
| `categorias` | Catálogo de categorías; `nombre` es obligatorio y único. El SQL precarga cinco categorías técnicas. |
| `clientes` | Contacto básico: `nombre_completo` y `telefono` obligatorios. El esquema no declara `telefono` único; la aplicación reutiliza el primer cliente coincidente. |
| `items` | Equipos/servicios, su categoría, descripción, precio y `stock_disponible`. `fk_items_categorias` referencia `categorias` con `ON DELETE RESTRICT`. |
| `paquetes` | Plantillas comerciales con nombre, descripción y `precio_base`. El SQL precarga Concierto Masivo, Estándar y Básico. |
| `paquete_detalles` | Composición de cada paquete; PK compuesta `(id_paquete, id_item)` y `cantidad > 0`. Paquete: `ON DELETE CASCADE`; ítem: `ON DELETE RESTRICT`. |
| `eventos_cotizaciones` | Cabecera vinculada obligatoriamente a cliente, con paquete opcional, fechas, dirección, total y estado. Cliente usa `ON DELETE RESTRICT`; paquete usa `ON DELETE SET NULL`. `estado` admite pendiente, confirmado, en_curso, finalizado o cancelado. |
| `cotizacion_detalles` | Ítems de la cotización; cantidad positiva y precio unitario registrado al cotizar. Cotización usa `ON DELETE CASCADE`; ítem usa `ON DELETE RESTRICT`. `subtotal` se genera como `cantidad * precio_unitario` y se almacena. |

Los ítems de los paquetes precargados no se modifican al seleccionarlos; sus cantidades se copian al carrito de la sesión del navegador. La API **no inserta `subtotal`**: PostgreSQL lo genera. Los `INSERT` de datos de ejemplo emplean `ON CONFLICT` donde el esquema define conflictos aplicables, pero no se asume unicidad adicional en nombres de ítems o paquetes.

## 3. Estructura de archivos

```text
.
├── .env.example                 # Variables de conexión de ejemplo
├── DOCUMENTACION.md              # Esta guía
├── app.py                        # Aplicación Flask y endpoints JSON
├── requirements.txt              # Dependencias Python
├── database/
│   └── esquema_tablas.sql        # Esquema y datos de ejemplo existentes
└── templates/
    └── index.html                # Interfaz Jinja2, Tailwind y JavaScript
```

## 4. API REST

Todos los endpoints de datos entregan JSON. Los errores usan un objeto `{"error":"…"}` y un código HTTP apropiado.

### `GET /`

Sirve `templates/index.html`.

### `GET /api/catalogo`

Entrega categorías e ítems con precio y stock.

```json
{
  "categorias": [{"id_categoria": 1, "nombre": "Sistema de Sonido Principal"}],
  "items": [{"id_item": 1, "id_categoria": 1, "categoria": "Sistema de Sonido Principal", "nombre": "Subwoofer…", "descripcion": "…", "precio_unitario": "350.00", "stock_disponible": 20}]
}
```

### `GET /api/paquetes`

Entrega cada paquete y la lista `items` que resulta de unir `paquete_detalles` con `items`. Cada componente incluye `id_item`, `nombre`, `cantidad`, `stock_disponible` y `precio_unitario`.

### `POST /api/cotizar`

Recibe `Content-Type: application/json`. Campos obligatorios: `nombre_completo`, `telefono`, `fecha_evento` (ISO `AAAA-MM-DD` no anterior al día actual), `direccion_evento` y un arreglo no vacío `items` con `id_item` y `cantidad` positiva. `id_paquete_base` es opcional y puede ser `null`.

```json
{
  "nombre_completo": "Ana Pérez",
  "telefono": "70000000",
  "fecha_evento": "2027-03-14",
  "direccion_evento": "La Paz",
  "id_paquete_base": 2,
  "items": [{"id_item": 1, "cantidad": 2}]
}
```

Respuesta exitosa, HTTP `201`:

```json
{"id_cotizacion": 42, "total_estimado": "700.00", "estado": "pendiente"}
```

Validación de datos devuelve `400`; ítems inexistentes o stock insuficiente devuelve `409`; un error inesperado de PostgreSQL devuelve `500`. Los precios y el stock enviados por el navegador no se aceptan como autoridad: Flask los vuelve a leer de la base y bloquea las filas correspondientes durante la operación. El cliente existente se identifica por teléfono; si hay coincidencia, se actualiza su nombre al enviado.

## 5. Guía funcional

1. Abre la página y revisa las tarjetas de paquetes. “Ver equipos incluidos” muestra la composición y el stock actual.
2. “Seleccionar paquete” copia al carrito las cantidades disponibles del paquete y guarda su referencia como paquete base. Los componentes sin stock suficiente se omiten con aviso.
3. Usa los filtros de categorías y los controles `+`/`−` para agregar, quitar o ajustar artículos. La interfaz impide superar el stock mostrado; el servidor vuelve a verificarlo al guardar.
4. El resumen en vivo muestra cantidades y total estimado. Completa nombre, teléfono, fecha y dirección y genera la proforma.
5. Al guardar, se presenta el identificador oficial de cotización y sus líneas. Imprime o usa el diálogo del navegador para guardar como PDF; el enlace de WhatsApp prepara un mensaje para compartir. La solicitud queda en estado `pendiente`.

La selección del carrito vive en memoria de la página y se pierde al recargar. El botón de WhatsApp genera un enlace `wa.me` sin enviar mensajes automáticamente.

## 6. Instalación y ejecución local

Requisitos: Python 3.11 o posterior y un servidor PostgreSQL accesible. La base debe existir previamente.

1. Crear y activar el entorno virtual:

   ```powershell
   py -3.11 -m venv .venv
   .\.venv\Scripts\Activate.ps1
   ```

2. Instalar dependencias:

   ```powershell
   pip install -r requirements.txt
   ```

3. Copiar `.env.example` a `.env` y establecer `DB_HOST`, `DB_PORT`, `DB_NAME`, `DB_USER` y `DB_PASSWORD` según el servidor PostgreSQL. No subir credenciales reales al repositorio.
4. Ejecutar `database/esquema_tablas.sql` conectado a la base configurada. El script crea tablas y carga categorías, ítems, paquetes y sus composiciones.
5. Iniciar el servidor local:

   ```powershell
   python app.py
   ```

6. Abrir `http://localhost:5000`. `PORT` puede cambiar el puerto. `FLASK_DEBUG=1` activa depuración local; mantenerlo desactivado en despliegues.

Para despliegue, configurar las variables de entorno en el servicio, usar un servidor WSGI adecuado y servir la aplicación tras HTTPS. El CDN de Tailwind necesita acceso a Internet en el navegador.
