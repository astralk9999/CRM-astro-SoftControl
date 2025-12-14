-- =====================================================
-- SOFTCONTROL CRM - SCHEMA COMPLETO
-- Versión: 1.0
-- Base de datos: Supabase (PostgreSQL)
-- =====================================================

-- =====================================================
-- EXTENSIONES
-- =====================================================
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";

-- =====================================================
-- TIPOS ENUMERADOS
-- =====================================================

-- Tipos de suscripción
CREATE TYPE subscription_type AS ENUM ('monthly', 'annual', 'lifetime', 'trial');

-- Estados de suscripción
CREATE TYPE subscription_status AS ENUM ('active', 'inactive', 'cancelled', 'expired', 'pending', 'trial');

-- Estados de pago
CREATE TYPE payment_status AS ENUM ('pending', 'paid', 'failed', 'refunded');

-- Estados de licencia
CREATE TYPE license_status AS ENUM ('active', 'inactive', 'expired', 'revoked');

-- Roles de usuario staff
CREATE TYPE user_role AS ENUM ('super_admin', 'admin', 'staff');

-- =====================================================
-- TABLA: profiles (Staff de SoftControl)
-- =====================================================
CREATE TABLE IF NOT EXISTS public.profiles (
  id UUID PRIMARY KEY REFERENCES auth.users(id) ON DELETE CASCADE,
  full_name TEXT NOT NULL DEFAULT '',
  email TEXT,
  phone TEXT,
  avatar_url TEXT,
  role TEXT NOT NULL DEFAULT 'staff' CHECK (role IN ('super_admin', 'admin', 'staff')),
  is_active BOOLEAN NOT NULL DEFAULT true,
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- Índices
CREATE INDEX IF NOT EXISTS idx_profiles_email ON public.profiles(email);
CREATE INDEX IF NOT EXISTS idx_profiles_role ON public.profiles(role);
CREATE INDEX IF NOT EXISTS idx_profiles_is_active ON public.profiles(is_active);

-- =====================================================
-- TABLA: customers (Clientes que compran licencias)
-- =====================================================
CREATE TABLE IF NOT EXISTS public.customers (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  auth_user_id UUID REFERENCES auth.users(id) ON DELETE SET NULL,
  email TEXT NOT NULL,
  full_name TEXT NOT NULL,
  phone TEXT,
  company_name TEXT,
  address TEXT,
  city TEXT,
  country TEXT DEFAULT 'España',
  tax_id TEXT, -- NIF/CIF
  notes TEXT,
  is_active BOOLEAN NOT NULL DEFAULT true,
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW(),
  CONSTRAINT customers_email_unique UNIQUE (email)
);

-- Índices
CREATE INDEX IF NOT EXISTS idx_customers_email ON public.customers(email);
CREATE INDEX IF NOT EXISTS idx_customers_auth_user_id ON public.customers(auth_user_id);
CREATE INDEX IF NOT EXISTS idx_customers_company_name ON public.customers(company_name);
CREATE INDEX IF NOT EXISTS idx_customers_is_active ON public.customers(is_active);

-- =====================================================
-- TABLA: products (Productos/Planes de suscripción)
-- =====================================================
CREATE TABLE IF NOT EXISTS public.products (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  name TEXT NOT NULL,
  description TEXT,
  sku TEXT UNIQUE,
  subscription_type TEXT NOT NULL DEFAULT 'monthly' CHECK (subscription_type IN ('monthly', 'annual', 'lifetime', 'trial')),
  price DECIMAL(10,2) NOT NULL DEFAULT 0,
  currency TEXT NOT NULL DEFAULT 'EUR',
  duration_days INTEGER, -- NULL para lifetime
  features JSONB DEFAULT '[]'::jsonb,
  stripe_price_id TEXT,
  stripe_product_id TEXT,
  is_active BOOLEAN NOT NULL DEFAULT true,
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- Índices
CREATE INDEX IF NOT EXISTS idx_products_subscription_type ON public.products(subscription_type);
CREATE INDEX IF NOT EXISTS idx_products_is_active ON public.products(is_active);
CREATE INDEX IF NOT EXISTS idx_products_stripe_price_id ON public.products(stripe_price_id);

-- =====================================================
-- TABLA: subscriptions (Suscripciones de clientes)
-- =====================================================
CREATE TABLE IF NOT EXISTS public.subscriptions (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  customer_id UUID NOT NULL REFERENCES public.customers(id) ON DELETE CASCADE,
  product_id UUID REFERENCES public.products(id) ON DELETE SET NULL,
  subscription_type TEXT NOT NULL DEFAULT 'monthly' CHECK (subscription_type IN ('monthly', 'annual', 'lifetime', 'trial')),
  status TEXT NOT NULL DEFAULT 'pending' CHECK (status IN ('active', 'inactive', 'cancelled', 'expired', 'pending', 'trial')),
  start_date DATE,
  end_date DATE,
  trial_ends_at TIMESTAMPTZ,
  auto_renew BOOLEAN DEFAULT true,
  stripe_subscription_id TEXT,
  stripe_customer_id TEXT,
  payment_status TEXT DEFAULT 'pending' CHECK (payment_status IN ('pending', 'paid', 'failed', 'refunded')),
  last_payment_date DATE,
  next_payment_date DATE,
  amount DECIMAL(10,2),
  currency TEXT DEFAULT 'EUR',
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- Índices
CREATE INDEX IF NOT EXISTS idx_subscriptions_customer_id ON public.subscriptions(customer_id);
CREATE INDEX IF NOT EXISTS idx_subscriptions_product_id ON public.subscriptions(product_id);
CREATE INDEX IF NOT EXISTS idx_subscriptions_status ON public.subscriptions(status);
CREATE INDEX IF NOT EXISTS idx_subscriptions_stripe_subscription_id ON public.subscriptions(stripe_subscription_id);

-- =====================================================
-- TABLA: licenses (Licencias generadas)
-- =====================================================
CREATE TABLE IF NOT EXISTS public.licenses (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  customer_id UUID NOT NULL REFERENCES public.customers(id) ON DELETE CASCADE,
  subscription_id UUID REFERENCES public.subscriptions(id) ON DELETE SET NULL,
  product_id UUID REFERENCES public.products(id) ON DELETE SET NULL,
  license_key TEXT NOT NULL UNIQUE,
  status TEXT NOT NULL DEFAULT 'inactive' CHECK (status IN ('active', 'inactive', 'expired', 'revoked')),
  activation_date DATE,
  expiration_date DATE,
  max_activations INTEGER DEFAULT 1,
  current_activations INTEGER DEFAULT 0,
  hardware_id TEXT, -- Para vincular a un dispositivo específico
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- Índices
CREATE INDEX IF NOT EXISTS idx_licenses_customer_id ON public.licenses(customer_id);
CREATE INDEX IF NOT EXISTS idx_licenses_subscription_id ON public.licenses(subscription_id);
CREATE INDEX IF NOT EXISTS idx_licenses_license_key ON public.licenses(license_key);
CREATE INDEX IF NOT EXISTS idx_licenses_status ON public.licenses(status);

-- =====================================================
-- TABLA: sales (Registro de ventas)
-- =====================================================
CREATE TABLE IF NOT EXISTS public.sales (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  customer_id UUID REFERENCES public.customers(id) ON DELETE CASCADE,
  subscription_id UUID REFERENCES public.subscriptions(id) ON DELETE SET NULL,
  product_id UUID REFERENCES public.products(id) ON DELETE SET NULL,
  amount DECIMAL(10,2) NOT NULL DEFAULT 0,
  currency TEXT NOT NULL DEFAULT 'EUR',
  payment_status TEXT NOT NULL DEFAULT 'pending' CHECK (payment_status IN ('pending', 'paid', 'failed', 'refunded')),
  payment_method TEXT, -- card, transfer, cash, etc.
  stripe_payment_id TEXT,
  stripe_invoice_id TEXT,
  invoice_number TEXT,
  notes TEXT,
  sale_date DATE DEFAULT CURRENT_DATE,
  created_at TIMESTAMPTZ DEFAULT NOW()
);

-- Índices
CREATE INDEX IF NOT EXISTS idx_sales_customer_id ON public.sales(customer_id);
CREATE INDEX IF NOT EXISTS idx_sales_subscription_id ON public.sales(subscription_id);
CREATE INDEX IF NOT EXISTS idx_sales_payment_status ON public.sales(payment_status);
CREATE INDEX IF NOT EXISTS idx_sales_sale_date ON public.sales(sale_date);

-- =====================================================
-- VISTAS
-- =====================================================

-- Vista: sales_full (Ventas con información de cliente y producto)
CREATE OR REPLACE VIEW public.sales_full AS
SELECT 
  s.*,
  c.full_name as customer_name,
  c.email as customer_email,
  c.company_name as customer_company,
  COALESCE(p.name, 'N/A') as product_name,
  COALESCE(p.subscription_type, 'monthly') as subscription_type
FROM public.sales s
LEFT JOIN public.customers c ON s.customer_id = c.id
LEFT JOIN public.products p ON s.product_id = p.id;

-- Vista: subscriptions_full (Suscripciones con información completa)
CREATE OR REPLACE VIEW public.subscriptions_full AS
SELECT 
  s.*,
  c.full_name as customer_name,
  c.email as customer_email,
  c.company_name as customer_company,
  p.name as product_name,
  p.price as product_price,
  CASE 
    WHEN s.status = 'active' AND (s.end_date IS NULL OR s.end_date > CURRENT_DATE) THEN true
    WHEN s.status = 'trial' AND (s.trial_ends_at IS NULL OR s.trial_ends_at > NOW()) THEN true
    ELSE false
  END as is_valid
FROM public.subscriptions s
LEFT JOIN public.customers c ON s.customer_id = c.id
LEFT JOIN public.products p ON s.product_id = p.id;

-- Vista: licenses_full (Licencias con información completa)
CREATE OR REPLACE VIEW public.licenses_full AS
SELECT 
  l.*,
  c.full_name as customer_name,
  c.email as customer_email,
  c.company_name as customer_company,
  p.name as product_name,
  p.subscription_type,
  sub.status as subscription_status
FROM public.licenses l
LEFT JOIN public.customers c ON l.customer_id = c.id
LEFT JOIN public.products p ON l.product_id = p.id
LEFT JOIN public.subscriptions sub ON l.subscription_id = sub.id;

-- =====================================================
-- FUNCIONES
-- =====================================================

-- Función: Generar clave de licencia única
CREATE OR REPLACE FUNCTION generate_license_key()
RETURNS TEXT AS $$
DECLARE
  chars TEXT := 'ABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789';
  result TEXT := '';
  i INTEGER;
  section INTEGER;
BEGIN
  FOR section IN 1..4 LOOP
    IF section > 1 THEN
      result := result || '-';
    END IF;
    FOR i IN 1..4 LOOP
      result := result || substr(chars, floor(random() * length(chars) + 1)::integer, 1);
    END LOOP;
  END LOOP;
  RETURN result;
END;
$$ LANGUAGE plpgsql;

-- Función: Crear perfil automáticamente al registrar usuario
CREATE OR REPLACE FUNCTION public.handle_new_user()
RETURNS trigger AS $$
BEGIN
  INSERT INTO public.profiles (id, full_name, email, role, is_active, created_at, updated_at)
  VALUES (
    NEW.id,
    COALESCE(NEW.raw_user_meta_data->>'full_name', 'Usuario'),
    NEW.email,
    COALESCE(NEW.raw_user_meta_data->>'role', 'staff'),
    true,
    NOW(),
    NOW()
  )
  ON CONFLICT (id) DO UPDATE SET
    full_name = COALESCE(EXCLUDED.full_name, profiles.full_name),
    email = COALESCE(EXCLUDED.email, profiles.email),
    updated_at = NOW();
  RETURN NEW;
EXCEPTION WHEN OTHERS THEN
  RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Función: Actualizar timestamp updated_at automáticamente
CREATE OR REPLACE FUNCTION update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
  NEW.updated_at = NOW();
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- =====================================================
-- TRIGGERS
-- =====================================================

-- Trigger: Crear perfil al registrar usuario
DROP TRIGGER IF EXISTS on_auth_user_created ON auth.users;
CREATE TRIGGER on_auth_user_created
  AFTER INSERT ON auth.users
  FOR EACH ROW EXECUTE FUNCTION public.handle_new_user();

-- Triggers: Actualizar updated_at
CREATE TRIGGER update_profiles_updated_at
  BEFORE UPDATE ON public.profiles
  FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_customers_updated_at
  BEFORE UPDATE ON public.customers
  FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_products_updated_at
  BEFORE UPDATE ON public.products
  FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_subscriptions_updated_at
  BEFORE UPDATE ON public.subscriptions
  FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_licenses_updated_at
  BEFORE UPDATE ON public.licenses
  FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

-- =====================================================
-- ROW LEVEL SECURITY (RLS)
-- =====================================================

-- Habilitar RLS
ALTER TABLE public.profiles ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.customers ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.products ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.subscriptions ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.licenses ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.sales ENABLE ROW LEVEL SECURITY;

-- Políticas permisivas (ajustar según necesidades de seguridad)
CREATE POLICY "profiles_all" ON public.profiles FOR ALL USING (true) WITH CHECK (true);
CREATE POLICY "customers_all" ON public.customers FOR ALL USING (true) WITH CHECK (true);
CREATE POLICY "products_all" ON public.products FOR ALL USING (true) WITH CHECK (true);
CREATE POLICY "subscriptions_all" ON public.subscriptions FOR ALL USING (true) WITH CHECK (true);
CREATE POLICY "licenses_all" ON public.licenses FOR ALL USING (true) WITH CHECK (true);
CREATE POLICY "sales_all" ON public.sales FOR ALL USING (true) WITH CHECK (true);

-- =====================================================
-- PERMISOS
-- =====================================================

-- Permisos para tablas
GRANT ALL ON public.profiles TO authenticated, service_role;
GRANT ALL ON public.customers TO authenticated, service_role;
GRANT ALL ON public.products TO authenticated, service_role;
GRANT ALL ON public.subscriptions TO authenticated, service_role;
GRANT ALL ON public.licenses TO authenticated, service_role;
GRANT ALL ON public.sales TO authenticated, service_role;

-- Permisos para vistas
GRANT SELECT ON public.sales_full TO authenticated, anon, service_role;
GRANT SELECT ON public.subscriptions_full TO authenticated, anon, service_role;
GRANT SELECT ON public.licenses_full TO authenticated, anon, service_role;

-- Permisos de lectura para anon (productos públicos)
GRANT SELECT ON public.products TO anon;

-- =====================================================
-- DATOS INICIALES
-- =====================================================

-- Productos por defecto
INSERT INTO public.products (id, name, description, sku, subscription_type, price, currency, duration_days, features, is_active)
VALUES 
  ('11111111-1111-1111-1111-111111111111', 'Plan Mensual', 'Acceso completo por 1 mes', 'PLAN-MONTHLY', 'monthly', 29.99, 'EUR', 30, '["Soporte por email", "Actualizaciones incluidas", "1 licencia"]', true),
  ('22222222-2222-2222-2222-222222222222', 'Plan Anual', 'Acceso completo por 1 año (2 meses gratis)', 'PLAN-ANNUAL', 'annual', 299.99, 'EUR', 365, '["Soporte prioritario", "Actualizaciones incluidas", "3 licencias", "2 meses gratis"]', true),
  ('33333333-3333-3333-3333-333333333333', 'Plan Lifetime', 'Acceso de por vida', 'PLAN-LIFETIME', 'lifetime', 599.99, 'EUR', NULL, '["Soporte VIP", "Actualizaciones de por vida", "5 licencias", "Acceso beta"]', true)
ON CONFLICT (id) DO NOTHING;

-- Super Admin inicial (cambiar después de primera ejecución)
-- NOTA: Este usuario debe crearse primero en Supabase Auth
-- INSERT INTO public.profiles (id, full_name, email, role, is_active)
-- VALUES ('TU-USER-ID-AQUI', 'Super Admin', 'admin@tudominio.com', 'super_admin', true);

-- =====================================================
-- FIN DEL SCHEMA
-- =====================================================
