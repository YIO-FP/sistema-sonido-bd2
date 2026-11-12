import os
from datetime import date
from decimal import Decimal

import psycopg2
from psycopg2.extras import RealDictCursor
from dotenv import load_dotenv
from flask import Flask, jsonify, render_template, request

load_dotenv()
app = Flask(__name__)
app.config["JSON_SORT_KEYS"] = False


def get_connection():
    return psycopg2.connect(
        host=os.getenv("DB_HOST", "localhost"),
        port=os.getenv("DB_PORT", "5432"),
        dbname=os.getenv("DB_NAME", "sonido"),
        user=os.getenv("DB_USER", "postgres"),
        password=os.getenv("DB_PASSWORD", ""),
        cursor_factory=RealDictCursor,
    )


def json_rows(rows):
    return [dict(row) for row in rows]


@app.get("/")
def index():
    return render_template("index.html")


@app.get("/api/catalogo")
def catalogo():
    conn = get_connection()
    try:
        with conn.cursor() as cur:
            cur.execute("SELECT id_categoria, nombre FROM categorias ORDER BY id_categoria")
            categorias = json_rows(cur.fetchall())
            cur.execute("""SELECT i.id_item, i.id_categoria, c.nombre AS categoria,
                i.nombre, i.descripcion, i.precio_unitario, i.stock_disponible
                FROM items i JOIN categorias c USING (id_categoria)
                ORDER BY c.id_categoria, i.nombre""")
            items = json_rows(cur.fetchall())
        return jsonify(categorias=categorias, items=items)
    finally:
        conn.close()


@app.get("/api/paquetes")
def paquetes():
    conn = get_connection()
    try:
        with conn.cursor() as cur:
            cur.execute("""SELECT p.id_paquete, p.nombre, p.descripcion, p.precio_base,
                COALESCE(json_agg(json_build_object('id_item', i.id_item, 'nombre', i.nombre,
                'cantidad', pd.cantidad, 'stock_disponible', i.stock_disponible,
                'precio_unitario', i.precio_unitario)) FILTER (WHERE i.id_item IS NOT NULL), '[]') AS items
                FROM paquetes p LEFT JOIN paquete_detalles pd USING (id_paquete)
                LEFT JOIN items i USING (id_item) GROUP BY p.id_paquete ORDER BY p.id_paquete""")
            return jsonify(json_rows(cur.fetchall()))
    finally:
        conn.close()


@app.post("/api/cotizar")
def cotizar():
    data = request.get_json(silent=True) or {}
    nombre = str(data.get("nombre_completo", "")).strip()
    telefono = str(data.get("telefono", "")).strip()
    direccion = str(data.get("direccion_evento", "")).strip()
    fecha = data.get("fecha_evento")
    detalle = data.get("items")
    paquete = data.get("id_paquete_base")
    if not nombre or not telefono or not direccion or not fecha or not isinstance(detalle, list) or not detalle:
        return jsonify(error="Completa tus datos, fecha, dirección y agrega al menos un artículo."), 400
    try:
        event_date = date.fromisoformat(fecha)
        if event_date < date.today():
            raise ValueError
        normalized = {}
        for row in detalle:
            item_id, quantity = int(row["id_item"]), int(row["cantidad"])
            if quantity < 1:
                raise ValueError
            normalized[item_id] = normalized.get(item_id, 0) + quantity
    except (ValueError, TypeError, KeyError):
        return jsonify(error="La fecha o las cantidades no son válidas."), 400
    except Exception:
        return jsonify(error="El formato de los artículos no es válido."), 400

    conn = get_connection()
    try:
        with conn:
            with conn.cursor() as cur:
                if paquete is not None:
                    cur.execute("SELECT 1 FROM paquetes WHERE id_paquete = %s", (paquete,))
                    if not cur.fetchone():
                        return jsonify(error="El paquete seleccionado ya no existe."), 400
                cur.execute("SELECT id_item, precio_unitario, stock_disponible FROM items WHERE id_item = ANY(%s) FOR UPDATE", (list(normalized),))
                inventory = {row["id_item"]: row for row in cur.fetchall()}
                if len(inventory) != len(normalized):
                    return jsonify(error="Uno o más artículos ya no están disponibles."), 409
                for item_id, quantity in normalized.items():
                    if quantity > inventory[item_id]["stock_disponible"]:
                        return jsonify(error=f"Stock insuficiente para el artículo {item_id}."), 409
                cur.execute("SELECT id_cliente FROM clientes WHERE telefono = %s ORDER BY id_cliente LIMIT 1", (telefono,))
                client = cur.fetchone()
                if client:
                    client_id = client["id_cliente"]
                else:
                    cur.execute("INSERT INTO clientes (nombre_completo, telefono) VALUES (%s, %s) RETURNING id_cliente", (nombre, telefono))
                    client_id = cur.fetchone()["id_cliente"]
                if client:
                    cur.execute("UPDATE clientes SET nombre_completo = %s WHERE id_cliente = %s", (nombre, client_id))
                total = sum((inventory[item_id]["precio_unitario"] * quantity for item_id, quantity in normalized.items()), Decimal("0"))
                cur.execute("""INSERT INTO eventos_cotizaciones
                    (id_cliente, id_paquete_base, fecha_evento, direccion_evento, total_estimado, estado)
                    VALUES (%s, %s, %s, %s, %s, 'pendiente') RETURNING id_cotizacion""",
                    (client_id, paquete, event_date, direccion, total))
                quote_id = cur.fetchone()["id_cotizacion"]
                for item_id, quantity in normalized.items():
                    cur.execute("INSERT INTO cotizacion_detalles (id_cotizacion, id_item, cantidad, precio_unitario) VALUES (%s, %s, %s, %s)",
                                (quote_id, item_id, quantity, inventory[item_id]["precio_unitario"]))
        return jsonify(id_cotizacion=quote_id, total_estimado=str(total), estado="pendiente"), 201
    except psycopg2.Error as exc:
        app.logger.exception("No se pudo guardar la cotización")
        return jsonify(error="No se pudo guardar la cotización. Revisa la conexión con la base de datos."), 500
    finally:
        conn.close()


if __name__ == "__main__":
    app.run(host="0.0.0.0", port=int(os.getenv("PORT", "5000")), debug=os.getenv("FLASK_DEBUG") == "1")
