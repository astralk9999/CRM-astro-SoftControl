# SoftControl CRM

Sistema de gestión de clientes, suscripciones y licencias para empresas de software.

![SoftControl CRM](https://img.shields.io/badge/version-1.0.0-blue.svg)
![Astro](https://img.shields.io/badge/Astro-4.x-orange.svg)
![Supabase](https://img.shields.io/badge/Supabase-PostgreSQL-green.svg)
![Stripe](https://img.shields.io/badge/Stripe-Payments-purple.svg)

## 📋 Tabla de Contenidos

- [Descripción](#-descripción)
- [Características](#-características)
- [Roles y Permisos](#-roles-y-permisos)
- [Instalación](#-instalación)
- [Configuración](#-configuración)
- [Estructura del Proyecto](#-estructura-del-proyecto)
- [Base de Datos](#-base-de-datos)
- [API Endpoints](#-api-endpoints)
- [Chatbot de Soporte](#-chatbot-de-soporte)
- [Integración con Stripe](#-integración-con-stripe)
- [Despliegue](#-despliegue)

---

## 📝 Descripción

SoftControl CRM es una plataforma completa para gestionar:
- **Clientes**: Registro, seguimiento y comunicación
- **Suscripciones**: Planes mensuales, anuales y lifetime
- **Licencias**: Generación, activación y control de uso
- **Ventas**: Registro de transacciones y estadísticas
- **Equipo**: Gestión de staff con roles diferenciados

---

## ✨ Características

### Para Clientes
- Portal de autoservicio para gestionar suscripciones
- Visualización de licencias activas
- Historial de pagos
- Soporte vía chatbot de Telegram

### Para el Equipo
- Dashboard con métricas en tiempo real
- Gestión completa de clientes
- Control de suscripciones y renovaciones
- Generación y revocación de licencias
- Registro de ventas

### Técnicas
- Autenticación segura con Supabase Auth
- Pagos integrados con Stripe
- Interfaz moderna con TailwindCSS
- Modo oscuro nativo
- Responsive design

---

## 👥 Roles y Permisos

El sistema implementa un control de acceso basado en roles (RBAC):

### Super Admin (`super_admin`)
| Acción | Permitido |
|--------|-----------|
| Ver todo el sistema | ✅ |
| Crear/Editar/Eliminar cualquier usuario | ✅ |
| Crear otros Super Admins | ✅ |
| Gestionar productos y precios | ✅ |
| Ver estadísticas globales | ✅ |
| Configuración del sistema | ✅ |

### Administrador (`admin`)
| Acción | Permitido |
|--------|-----------|
| Ver clientes, ventas, suscripciones | ✅ |
| Crear/Editar/Eliminar clientes | ✅ |
| Crear usuarios Staff | ✅ |
| Crear otros Admins | ❌ |
| Crear Super Admins | ❌ |
| Gestionar productos | ✅ |
| Ver sección "Equipo" | ✅ |

### Staff (`staff`)
| Acción | Permitido |
|--------|-----------|
| Ver clientes, ventas, suscripciones | ✅ (solo lectura) |
| Crear/Editar/Eliminar datos | ❌ |
| Ver sección "Equipo" | ❌ |
| Acceso a configuración | ❌ |

### Cliente (`customer`)
| Acción | Permitido |
|--------|-----------|
| Ver su propia cuenta | ✅ |
| Ver sus suscripciones | ✅ |
| Ver sus licencias | ✅ |
| Gestionar su suscripción | ✅ |
| Acceder al dashboard admin | ❌ |

---

## 🚀 Instalación

### Requisitos Previos
- Node.js 18+ 
- npm o pnpm
- Cuenta en [Supabase](https://supabase.com)
- Cuenta en [Stripe](https://stripe.com) (para pagos)

### Pasos

1. **Clonar el repositorio**
```bash
git clone https://github.com/tu-usuario/softcontrol-crm.git
cd softcontrol-crm
```

2. **Instalar dependencias**
```bash
npm install
```

3. **Configurar variables de entorno**
```bash
cp .env.example .env
```
Edita `.env` con tus credenciales (ver sección Configuración).

4. **Configurar base de datos**
- Ve a tu proyecto en Supabase
- Abre el SQL Editor
- Ejecuta el contenido de `database/schema.sql`

5. **Iniciar servidor de desarrollo**
```bash
npm run dev
```

6. **Abrir en el navegador**
```
http://localhost:4321
```

---

## ⚙️ Configuración

### Variables de Entorno (.env)

```env
# Supabase
PUBLIC_SUPABASE_URL=https://tu-proyecto.supabase.co
PUBLIC_SUPABASE_ANON_KEY=tu-anon-key
SUPABASE_SERVICE_ROLE_KEY=tu-service-role-key

# Stripe
STRIPE_PUBLIC_KEY=pk_test_xxx
STRIPE_SECRET_KEY=sk_test_xxx
STRIPE_WEBHOOK_SECRET=whsec_xxx

# App
PUBLIC_APP_NAME=SoftControl CRM
PUBLIC_APP_URL=http://localhost:4321
```

### Obtener Credenciales

#### Supabase
1. Ve a [app.supabase.com](https://app.supabase.com)
2. Selecciona tu proyecto
3. Settings → API
4. Copia `URL`, `anon key` y `service_role key`

#### Stripe
1. Ve a [dashboard.stripe.com](https://dashboard.stripe.com)
2. Developers → API Keys
3. Copia `Publishable key` y `Secret key`
4. Para webhooks: Developers → Webhooks → Add endpoint

---

## 📁 Estructura del Proyecto

```
CRM-ASTRO/
├── src/
│   ├── components/        # Componentes reutilizables
│   ├── layouts/           # Layouts (Dashboard, Auth)
│   ├── lib/               # Lógica de negocio
│   │   ├── supabase.ts    # Cliente y funciones de BD
│   │   └── auth.ts        # Autenticación
│   ├── pages/             # Páginas de la aplicación
│   │   ├── api/           # Endpoints API
│   │   ├── customers.astro
│   │   ├── dashboard.astro
│   │   ├── licenses.astro
│   │   ├── login.astro
│   │   ├── mi-cuenta.astro
│   │   ├── products.astro
│   │   ├── register.astro
│   │   ├── sales.astro
│   │   ├── staff.astro
│   │   ├── subscriptions.astro
│   │   └── usuarios.astro
│   └── styles/            # Estilos globales
├── database/
│   └── schema.sql         # Schema completo de BD
├── public/                # Archivos estáticos
├── .env.example           # Plantilla de variables
├── astro.config.mjs       # Configuración de Astro
├── tailwind.config.mjs    # Configuración de Tailwind
└── package.json
```

---

## 🗄️ Base de Datos

### Tablas Principales

| Tabla | Descripción |
|-------|-------------|
| `profiles` | Staff de SoftControl (admin, super_admin, staff) |
| `customers` | Clientes que compran licencias |
| `products` | Planes de suscripción disponibles |
| `subscriptions` | Suscripciones de clientes |
| `licenses` | Licencias generadas |
| `sales` | Registro de ventas/transacciones |

### Vistas

| Vista | Descripción |
|-------|-------------|
| `sales_full` | Ventas con datos de cliente y producto |
| `subscriptions_full` | Suscripciones con datos completos |
| `licenses_full` | Licencias con datos de cliente |

### Diagrama Relacional

```
┌──────────────┐     ┌──────────────┐
│   profiles   │     │   products   │
│  (staff)     │     │  (planes)    │
└──────────────┘     └──────┬───────┘
                           │
                           │
┌──────────────┐     ┌─────▼────────┐     ┌──────────────┐
│  customers   │────▶│subscriptions │────▶│   licenses   │
│  (clientes)  │     │              │     │              │
└──────┬───────┘     └──────┬───────┘     └──────────────┘
       │                    │
       │              ┌─────▼────────┐
       └─────────────▶│    sales     │
                      │  (ventas)    │
                      └──────────────┘
```

---

## 🔌 API Endpoints

### Autenticación
- `POST /api/create-staff` - Crear usuario staff (requiere admin)

### Stripe Webhook
- `POST /api/stripe-webhook` - Recibe eventos de Stripe
  - `checkout.session.completed` - Activa suscripción tras pago
  - `payment_intent.succeeded` - Confirma pago
  - `payment_intent.payment_failed` - Marca pago fallido

---

## 🤖 Chatbot de Soporte

El sistema incluye integración con un bot de Telegram para soporte automatizado.

### Configuración
El botón de contacto en la landing page redirige a:
```
https://t.me/softcontrol_support_bot
```

### Funcionalidades del Bot
- Respuestas automáticas a preguntas frecuentes
- Creación de tickets de soporte
- Notificaciones de estado de suscripción
- Recordatorios de renovación

### Personalización
Para cambiar el bot, edita el enlace en `src/pages/index.astro`:
```javascript
const telegramBotUrl = 'https://t.me/tu_bot';
```

---

## 💳 Integración con Stripe

### Flujo de Pago

1. **Cliente selecciona plan** → Crea suscripción con estado `pending`
2. **Redirección a Stripe** → Checkout session
3. **Pago exitoso** → Webhook actualiza estado a `active`
4. **Licencia generada** → Se activa automáticamente

### Estados de Suscripción

| Estado | Descripción |
|--------|-------------|
| `pending` | Esperando pago |
| `active` | Activa y válida |
| `trial` | En período de prueba |
| `cancelled` | Cancelada por el usuario |
| `expired` | Expirada por tiempo |
| `inactive` | Desactivada manualmente |

### Configurar Webhooks en Stripe

1. Ve a Stripe Dashboard → Developers → Webhooks
2. Add endpoint: `https://tu-dominio.com/api/stripe-webhook`
3. Eventos a escuchar:
   - `checkout.session.completed`
   - `payment_intent.succeeded`
   - `payment_intent.payment_failed`
   - `customer.subscription.updated`
   - `customer.subscription.deleted`

---

## 🌐 Despliegue

### Netlify (Recomendado)

1. Conecta tu repositorio en Netlify
2. Configura las variables de entorno
3. Build command: `npm run build`
4. Publish directory: `dist`

### Vercel

1. Importa el proyecto en Vercel
2. Framework preset: Astro
3. Añade variables de entorno
4. Deploy

### Variables de Producción

Asegúrate de cambiar:
- `PUBLIC_APP_URL` a tu dominio real
- Claves de Stripe a modo producción (`pk_live_`, `sk_live_`)
- Configurar webhook de Stripe con URL de producción

---

## 🔒 Seguridad

### Recomendaciones

1. **Nunca expongas** `SUPABASE_SERVICE_ROLE_KEY` en el cliente
2. **Usa HTTPS** en producción
3. **Configura RLS** en Supabase según tus necesidades
4. **Valida** todos los inputs en el servidor
5. **Limita** intentos de login para prevenir fuerza bruta

### Row Level Security (RLS)

El schema incluye políticas RLS permisivas. Para producción, considera restringirlas:

```sql
-- Ejemplo: Staff solo ve sus propios datos
CREATE POLICY "staff_own_data" ON public.profiles
  FOR SELECT USING (auth.uid() = id);
```

---

## 📞 Soporte

- **Email**: soporte@softcontrol.com
- **Telegram**: [@softcontrol_support_bot](https://t.me/softcontrol_support_bot)
- **Documentación**: [docs.softcontrol.com](https://docs.softcontrol.com)

---

## 📄 Licencia

Este proyecto está bajo la licencia MIT. Ver `LICENSE` para más detalles.

---

Desarrollado con ❤️ por SoftControl Team
