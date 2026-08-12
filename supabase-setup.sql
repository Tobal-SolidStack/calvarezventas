-- ═══════════════════════════════════════════════════════════════
--  CalvarezVentas — Supabase Setup
--  Ejecuta esto en tu proyecto Supabase:
--  SQL Editor → New Query → pegar todo → Run
-- ═══════════════════════════════════════════════════════════════

-- ── 1. TABLA DE PRODUCTOS ───────────────────────────────────────
CREATE TABLE IF NOT EXISTS products (
  id              SERIAL PRIMARY KEY,
  name            TEXT    NOT NULL,
  description     TEXT    DEFAULT '',
  price           INTEGER NOT NULL DEFAULT 0,
  wholesale_price INTEGER DEFAULT 0,
  wholesale_min   INTEGER DEFAULT 0,
  stock           INTEGER DEFAULT 0,
  emoji           TEXT    DEFAULT '📦',
  img_url         TEXT    DEFAULT '',
  video_url       TEXT    DEFAULT '',
  has_video       BOOLEAN DEFAULT FALSE,
  created_at      TIMESTAMPTZ DEFAULT NOW()
);

-- ── 2. TABLA DE PEDIDOS ─────────────────────────────────────────
CREATE TABLE IF NOT EXISTS orders (
  id             UUID    PRIMARY KEY DEFAULT gen_random_uuid(),
  order_num      TEXT    NOT NULL,
  order_idx      INTEGER NOT NULL,
  customer_name  TEXT    NOT NULL,
  customer_rut   TEXT    DEFAULT '',
  customer_email TEXT    NOT NULL,
  customer_phone TEXT    NOT NULL,
  delivery_type  TEXT    NOT NULL,   -- 'presencial' | 'envio'
  addr           TEXT    DEFAULT '',
  payment        TEXT    NOT NULL,   -- 'webpay' | 'transferencia'
  items          JSONB   NOT NULL DEFAULT '[]',
  total          INTEGER NOT NULL DEFAULT 0,
  status         TEXT    DEFAULT 'pendiente',
  created_at     TIMESTAMPTZ DEFAULT NOW()
);

-- ── 3. CONTADOR ATÓMICO PARA NÚMEROS DE PEDIDO ─────────────────
CREATE SEQUENCE IF NOT EXISTS order_counter START 1;

-- ── 4. FUNCIÓN: siguiente número de pedido (atómica y segura) ───
CREATE OR REPLACE FUNCTION get_next_order_idx()
RETURNS INTEGER LANGUAGE SQL AS $$
  SELECT nextval('order_counter')::INTEGER;
$$;

-- ── 5. FUNCIÓN: descontar stock (segura, sin valor negativo) ────
CREATE OR REPLACE FUNCTION decrement_stock(p_id INTEGER, p_qty INTEGER)
RETURNS VOID LANGUAGE SQL SECURITY DEFINER AS $$
  UPDATE products SET stock = GREATEST(0, stock - p_qty) WHERE id = p_id;
$$;

-- ── 6. ROW LEVEL SECURITY ───────────────────────────────────────
ALTER TABLE products ENABLE ROW LEVEL SECURITY;
ALTER TABLE orders   ENABLE ROW LEVEL SECURITY;

-- Productos: todos pueden leer; solo admin (autenticado) puede escribir
CREATE POLICY "products_public_read"  ON products FOR SELECT USING (true);
CREATE POLICY "products_auth_insert"  ON products FOR INSERT WITH CHECK (auth.role() = 'authenticated');
CREATE POLICY "products_auth_update"  ON products FOR UPDATE USING    (auth.role() = 'authenticated');
CREATE POLICY "products_auth_delete"  ON products FOR DELETE USING    (auth.role() = 'authenticated');

-- Pedidos: clientes pueden insertar sin login; admin lee/actualiza
CREATE POLICY "orders_public_insert"  ON orders FOR INSERT WITH CHECK (true);
CREATE POLICY "orders_auth_select"    ON orders FOR SELECT USING    (auth.role() = 'authenticated');
CREATE POLICY "orders_auth_update"    ON orders FOR UPDATE USING    (auth.role() = 'authenticated');

-- ── 7. STORAGE (ejecuta en dashboard: Storage → New Bucket) ────
--  Nombre del bucket: product-media
--  Public bucket: SÍ (para que las URLs sean públicas)
--  Políticas del bucket:
--    SELECT (public):     (true)
--    INSERT/UPDATE/DELETE (authenticated):  (auth.role() = 'authenticated')

-- ── 8. PRODUCTOS DE EJEMPLO ─────────────────────────────────────
INSERT INTO products (name, description, price, stock, emoji) VALUES
  ('Producto Ejemplo A', 'Edita este producto desde el panel Admin.', 9990,  20, '📱'),
  ('Producto Ejemplo B', 'Agrega imagen y precio personalizado.',      14990, 15, '👟'),
  ('Producto Ejemplo C', 'Gestiona tu catálogo completo.',             24990, 8,  '🎧')
ON CONFLICT DO NOTHING;

-- ── INSTRUCCIONES ADICIONALES ────────────────────────────────────
-- 1. Crea un usuario admin en: Authentication → Users → Add User
--    Email:    admin@calvarezventas.cl  (o el que prefieras)
--    Password: (elige una contraseña segura)
--
-- 2. Copia tu Project URL y anon key desde:
--    Settings → API → Project URL / Project API keys (anon public)
--
-- 3. Pégalos en index.html y admin.html donde dice:
--    const SUPABASE_URL = 'https://xxx.supabase.co';
--    const SUPABASE_KEY = 'eyJ...';
