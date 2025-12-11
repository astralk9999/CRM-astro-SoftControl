# MarketMove App

**Aplicación móvil para gestión de pequeños comercios**

Desarrollado para **MarketMove S.L.** - Sistema integral de control de ventas, gastos y stock para dueños de tiendas.

---

## 📋 Descripción del Proyecto

MarketMove es una aplicación móvil desarrollada en Flutter que permite a los propietarios de pequeños comercios:

- **Registrar ventas diarias** con detalle de productos y cantidades
- **Controlar gastos** por categorías
- **Gestionar inventario** con alertas de stock bajo
- **Visualizar balance** de ganancias vs gastos en tiempo real
- **Sistema de roles** para gestión de usuarios (Usuario, Staff, Admin, Super Admin)

---

## 👥 Integrantes del Equipo

| Rol | Nombre |
|-----|--------|
| Desarrollador Principal | [Tu nombre] |
| Diseño UX/UI | [Nombre] |
| Backend/Supabase | [Nombre] |

---

## 🔧 Requisitos Técnicos

### Requisitos del Sistema
- **Flutter SDK**: ^3.9.2
- **Dart SDK**: ^3.9.2
- **Android**: SDK 21+ (Android 5.0 Lollipop o superior)
- **iOS**: 12.0+

### Dependencias Principales
```yaml
dependencies:
  supabase_flutter: ^2.8.0    # Backend y autenticación
  provider: ^6.1.2             # Gestión de estado
  go_router: ^14.6.0           # Navegación
  url_launcher: ^6.3.1         # Abrir URLs (Stripe)
  intl: ^0.19.0                # Formato de fechas y monedas
  fl_chart: ^0.69.2            # Gráficos
```

### Backend
- **Supabase** - Base de datos PostgreSQL + Autenticación
- **Stripe** - Procesamiento de pagos

---

## 🚀 Cómo Ejecutar el Proyecto

### 1. Clonar el repositorio
```bash
git clone https://github.com/tu-usuario/marketmove_app.git
cd marketmove_app
```

### 2. Instalar dependencias
```bash
flutter pub get
```

### 3. Configurar Supabase
Editar `lib/src/core/constants/app_constants.dart` con tus credenciales:
```dart
static const String supabaseUrl = 'TU_SUPABASE_URL';
static const String supabaseAnonKey = 'TU_ANON_KEY';
```

### 4. Ejecutar la base de datos
Ejecutar el script `database/schema.sql` en tu proyecto de Supabase.

### 5. Ejecutar la aplicación
```bash
flutter run
```

---

## 📁 Estructura del Proyecto

```
lib/
  src/
    core/
      constants/      # Constantes de la app (URLs, precios)
      theme/          # Tema visual de la aplicación
      routes/         # Configuración de navegación
    features/
      auth/           # Autenticación (login, registro)
      ventas/         # Módulo de ventas
      gastos/         # Módulo de gastos
      productos/      # Módulo de productos/stock
      resumen/        # Dashboard y resumen
      pricing/        # Pantalla de precios (pública)
      admin/          # Panel de administración
    shared/
      widgets/        # Componentes reutilizables
      models/         # Modelos de datos
      services/       # Servicios (Supabase, API)
      providers/      # Providers de estado
assets/
  images/             # Imágenes de la app
  icons/              # Iconos personalizados
database/
  schema.sql          # Esquema de base de datos
```

---

## 📊 Fases del Proyecto

| Fase | Descripción | Estado |
|------|-------------|--------|
| 1. Análisis | Toma de requisitos con el cliente | ✅ Completado |
| 2. Diseño UX/UI | Wireframes y diseño visual | ✅ Completado |
| 3. Arquitectura | Estructura de carpetas y servicios | ✅ Completado |
| 4. Frontend | Desarrollo de pantallas en Flutter | ✅ Completado |
| 5. Backend | Integración con Supabase | ✅ Completado |
| 6. Pruebas | Testing funcional | 🔄 En progreso |
| 7. Documentación | README y presupuesto | ✅ Completado |
| 8. Entrega | Publicación (mock) | ⏳ Pendiente |

---

## 💰 Planes de Precios

| Plan | Precio | Enlace |
|------|--------|--------|
| **Básico** | €9.99/mes | [Suscribirse](https://buy.stripe.com/test_9B6cMY6Oz9rqbYTcco08g00) |
| **Anual** | €99.99/año | [Suscribirse](https://buy.stripe.com/test_5kQ14g1uf476fb51xK08g02) |
| **Licencia Definitiva** | €199.99 (único) | [Comprar](https://buy.stripe.com/test_eVq14g7SD7ji6EzgsE08g01) |

---

## 🔐 Sistema de Roles

| Rol | Permisos |
|-----|----------|
| **Super Admin** | Control total del sistema, gestión de admins |
| **Admin** | Gestiona productos, staff y usuarios |
| **Staff** | Gestiona usuarios básicos |
| **Usuario** | Acceso a funciones de su comercio |

---

## 📝 Licencia

Este proyecto es privado y está desarrollado exclusivamente para MarketMove S.L.

---

## 📞 Contacto

Para soporte técnico o consultas:
- Email: soporte@marketmove.com
- Web: www.marketmove.com
