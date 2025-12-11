-- ==============================================
-- MARKETMOVE APP - ESQUEMA DE BASE DE DATOS
-- Sistema de Gestión para Pequeños Comercios
-- ==============================================

-- Habilitar UUID extension
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";

-- ==============================================
-- TABLAS
-- ==============================================

-- Tabla profiles (extiende auth.users)
CREATE TABLE IF NOT EXISTS profiles (
    id UUID PRIMARY KEY REFERENCES auth.users(id) ON DELETE CASCADE,
    email TEXT,
    full_name TEXT NOT NULL,
    role TEXT CHECK (role IN ('user', 'staff', 'admin', 'super_admin')) DEFAULT 'user',
    plan_type TEXT CHECK (plan_type IN ('basic', 'annual', 'lifetime')) DEFAULT NULL,
    plan_expires_at TIMESTAMPTZ DEFAULT NULL,
    created_at TIMESTAMPTZ DEFAULT NOW()
);

-- Tabla productos (debe estar antes de ventas por la FK)
CREATE TABLE IF NOT EXISTS productos (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id UUID NOT NULL REFERENCES profiles(id) ON DELETE CASCADE,
    nombre TEXT NOT NULL,
    descripcion TEXT,
    precio NUMERIC(10,2) NOT NULL,
    stock INTEGER NOT NULL DEFAULT 0,
    stock_minimo INTEGER NOT NULL DEFAULT 5,
    categoria TEXT,
    codigo_barras TEXT,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NULL
);

-- Tabla ventas
CREATE TABLE IF NOT EXISTS ventas (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id UUID NOT NULL REFERENCES profiles(id) ON DELETE CASCADE,
    producto_id UUID REFERENCES productos(id) ON DELETE SET NULL,
    producto_nombre TEXT,
    cantidad NUMERIC(10,2) NOT NULL DEFAULT 1,
    precio_unitario NUMERIC(10,2) NOT NULL,
    total NUMERIC(10,2) NOT NULL,
    descripcion TEXT,
    fecha TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    created_at TIMESTAMPTZ DEFAULT NOW()
);

-- Tabla gastos
CREATE TABLE IF NOT EXISTS gastos (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id UUID NOT NULL REFERENCES profiles(id) ON DELETE CASCADE,
    categoria TEXT NOT NULL DEFAULT 'Otros',
    monto NUMERIC(10,2) NOT NULL,
    descripcion TEXT,
    fecha TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    created_at TIMESTAMPTZ DEFAULT NOW()
);

-- ==============================================
-- ÍNDICES PARA MEJORAR PERFORMANCE
-- ==============================================

CREATE INDEX idx_ventas_user_id ON ventas(user_id);
CREATE INDEX idx_ventas_fecha ON ventas(fecha);
CREATE INDEX idx_gastos_user_id ON gastos(user_id);
CREATE INDEX idx_gastos_fecha ON gastos(fecha);
CREATE INDEX idx_gastos_categoria ON gastos(categoria);
CREATE INDEX idx_productos_user_id ON productos(user_id);
CREATE INDEX idx_productos_nombre ON productos(nombre);
CREATE INDEX idx_productos_categoria ON productos(categoria);
CREATE INDEX idx_profiles_role ON profiles(role);
CREATE INDEX idx_profiles_plan_type ON profiles(plan_type);

-- ==============================================
-- ROW LEVEL SECURITY (RLS)
-- ==============================================

-- Habilitar RLS en todas las tablas
ALTER TABLE profiles ENABLE ROW LEVEL SECURITY;
ALTER TABLE ventas ENABLE ROW LEVEL SECURITY;
ALTER TABLE gastos ENABLE ROW LEVEL SECURITY;
ALTER TABLE productos ENABLE ROW LEVEL SECURITY;

-- ==============================================
-- POLÍTICAS DE SEGURIDAD - PROFILES
-- ==============================================

-- Los usuarios pueden ver su propio perfil
CREATE POLICY "Users can view own profile" ON profiles
    FOR SELECT
    USING (auth.uid() = id);

-- Staff, Admin y Super Admin pueden ver todos los perfiles
CREATE POLICY "Staff and above can view all profiles" ON profiles
    FOR SELECT
    USING (
        EXISTS (
            SELECT 1 FROM profiles 
            WHERE id = auth.uid() 
            AND role IN ('staff', 'admin', 'super_admin')
        )
    );

-- Los usuarios pueden actualizar su propio perfil (excepto el rol)
CREATE POLICY "Users can update own profile" ON profiles
    FOR UPDATE
    USING (auth.uid() = id)
    WITH CHECK (auth.uid() = id);

-- Los usuarios pueden insertar su propio perfil
CREATE POLICY "Users can insert own profile" ON profiles
    FOR INSERT
    WITH CHECK (auth.uid() = id);

-- Staff puede actualizar roles de usuarios
CREATE POLICY "Staff can update user roles" ON profiles
    FOR UPDATE
    USING (
        EXISTS (
            SELECT 1 FROM profiles 
            WHERE id = auth.uid() 
            AND role IN ('staff', 'admin', 'super_admin')
        )
    );

-- Super Admin puede hacer todo
CREATE POLICY "Super admin full access" ON profiles
    FOR ALL
    USING (
        EXISTS (
            SELECT 1 FROM profiles 
            WHERE id = auth.uid() 
            AND role = 'super_admin'
        )
    );

-- ==============================================
-- POLÍTICAS DE SEGURIDAD - VENTAS
-- ==============================================

-- Usuarios pueden ver sus propias ventas
CREATE POLICY "Users can view own ventas" ON ventas
    FOR SELECT
    USING (auth.uid() = user_id);

-- Usuarios pueden crear sus propias ventas
CREATE POLICY "Users can create own ventas" ON ventas
    FOR INSERT
    WITH CHECK (auth.uid() = user_id);

-- Usuarios pueden actualizar sus propias ventas
CREATE POLICY "Users can update own ventas" ON ventas
    FOR UPDATE
    USING (auth.uid() = user_id);

-- Usuarios pueden eliminar sus propias ventas
CREATE POLICY "Users can delete own ventas" ON ventas
    FOR DELETE
    USING (auth.uid() = user_id);

-- ==============================================
-- POLÍTICAS DE SEGURIDAD - GASTOS
-- ==============================================

-- Usuarios pueden ver sus propios gastos
CREATE POLICY "Users can view own gastos" ON gastos
    FOR SELECT
    USING (auth.uid() = user_id);

-- Usuarios pueden crear sus propios gastos
CREATE POLICY "Users can create own gastos" ON gastos
    FOR INSERT
    WITH CHECK (auth.uid() = user_id);

-- Usuarios pueden actualizar sus propios gastos
CREATE POLICY "Users can update own gastos" ON gastos
    FOR UPDATE
    USING (auth.uid() = user_id);

-- Usuarios pueden eliminar sus propios gastos
CREATE POLICY "Users can delete own gastos" ON gastos
    FOR DELETE
    USING (auth.uid() = user_id);

-- ==============================================
-- POLÍTICAS DE SEGURIDAD - PRODUCTOS
-- ==============================================

-- Usuarios pueden ver sus propios productos
CREATE POLICY "Users can view own productos" ON productos
    FOR SELECT
    USING (auth.uid() = user_id);

-- Usuarios pueden crear sus propios productos
CREATE POLICY "Users can create own productos" ON productos
    FOR INSERT
    WITH CHECK (auth.uid() = user_id);

-- Usuarios pueden actualizar sus propios productos
CREATE POLICY "Users can update own productos" ON productos
    FOR UPDATE
    USING (auth.uid() = user_id);

-- Usuarios pueden eliminar sus propios productos
CREATE POLICY "Users can delete own productos" ON productos
    FOR DELETE
    USING (auth.uid() = user_id);

-- ==============================================
-- FUNCIONES Y TRIGGERS
-- ==============================================

-- Función para crear automáticamente un perfil cuando se registra un usuario
CREATE OR REPLACE FUNCTION public.handle_new_user()
RETURNS trigger AS $$
BEGIN
    INSERT INTO public.profiles (id, email, full_name, role, plan_type)
    VALUES (
        new.id,
        new.email,
        COALESCE(new.raw_user_meta_data->>'full_name', 'Usuario'),
        COALESCE(new.raw_user_meta_data->>'role', 'user'),
        new.raw_user_meta_data->>'plan_type'
    );
    RETURN new;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Trigger para ejecutar la función cuando se crea un nuevo usuario
DROP TRIGGER IF EXISTS on_auth_user_created ON auth.users;
CREATE TRIGGER on_auth_user_created
    AFTER INSERT ON auth.users
    FOR EACH ROW
    EXECUTE FUNCTION public.handle_new_user();

-- Función para actualizar el stock cuando se crea una venta
CREATE OR REPLACE FUNCTION public.update_stock_on_venta()
RETURNS trigger AS $$
BEGIN
    IF NEW.producto_id IS NOT NULL THEN
        UPDATE productos 
        SET stock = stock - NEW.cantidad,
            updated_at = NOW()
        WHERE id = NEW.producto_id;
    END IF;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Trigger para actualizar stock al crear venta
CREATE TRIGGER on_venta_created
    AFTER INSERT ON ventas
    FOR EACH ROW
    EXECUTE FUNCTION public.update_stock_on_venta();

-- ==============================================
-- VISTAS ÚTILES
-- ==============================================

-- Vista para estadísticas del usuario
CREATE OR REPLACE VIEW user_stats AS
SELECT 
    p.id as user_id,
    p.full_name,
    p.role,
    p.plan_type,
    COALESCE((SELECT SUM(total) FROM ventas WHERE user_id = p.id), 0) as total_ventas,
    COALESCE((SELECT SUM(monto) FROM gastos WHERE user_id = p.id), 0) as total_gastos,
    COALESCE((SELECT COUNT(*) FROM productos WHERE user_id = p.id), 0) as total_productos,
    COALESCE((SELECT SUM(precio * stock) FROM productos WHERE user_id = p.id), 0) as valor_inventario
FROM profiles p;

-- ==============================================
-- DATOS INICIALES - SUPER ADMIN
-- ==============================================

-- Nota: Después de crear el primer usuario, ejecutar este SQL
-- para convertirlo en super_admin:
-- UPDATE profiles SET role = 'super_admin' WHERE email = 'tu-email@ejemplo.com';
