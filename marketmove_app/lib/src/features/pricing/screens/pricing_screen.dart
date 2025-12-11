import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/theme/app_theme.dart';

class PricingScreen extends StatelessWidget {
  const PricingScreen({super.key});

  Future<void> _launchUrl(String url) async {
    final uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              children: [
                const SizedBox(height: 20),
                // Logo y título
                Icon(
                  Icons.store_rounded,
                  size: 64,
                  color: AppTheme.primaryColor,
                ),
                const SizedBox(height: 16),
                Text(
                  'MarketMove',
                  style: Theme.of(context).textTheme.headlineLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: AppTheme.textPrimary,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Gestiona tu negocio de forma simple',
                  style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                    color: AppTheme.textSecondary,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 40),
                
                // Título de precios
                Text(
                  'Elige tu plan',
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Sin compromiso. Cancela cuando quieras.',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: AppTheme.textSecondary,
                  ),
                ),
                const SizedBox(height: 32),

                // Plan Básico Mensual
                _PricingCard(
                  title: 'Plan Básico',
                  price: '€${AppConstants.basicMonthlyPrice.toStringAsFixed(2)}',
                  period: '/mes',
                  description: 'Ideal para empezar',
                  features: const [
                    'Registro de ventas ilimitadas',
                    'Control de gastos',
                    'Gestión de productos',
                    'Panel de resumen',
                    'Soporte por email',
                  ],
                  buttonText: 'Comenzar Ahora',
                  onPressed: () => _launchUrl(AppConstants.stripeBasicPlan),
                  isPopular: false,
                ),
                const SizedBox(height: 20),

                // Plan Anual (Popular)
                _PricingCard(
                  title: 'Plan Anual',
                  price: '€${AppConstants.annualPrice.toStringAsFixed(2)}',
                  period: '/año',
                  description: 'Ahorra más de 2 meses',
                  features: const [
                    'Todo del plan básico',
                    'Ahorro del 17%',
                    'Estadísticas avanzadas',
                    'Exportación de datos',
                    'Soporte prioritario',
                  ],
                  buttonText: 'Mejor Oferta',
                  onPressed: () => _launchUrl(AppConstants.stripeAnnualPlan),
                  isPopular: true,
                ),
                const SizedBox(height: 20),

                // Licencia Definitiva
                _PricingCard(
                  title: 'Licencia Definitiva',
                  price: '€${AppConstants.lifetimePrice.toStringAsFixed(2)}',
                  period: ' pago único',
                  description: 'Para siempre, sin suscripción',
                  features: const [
                    'Todas las funcionalidades',
                    'Actualizaciones de por vida',
                    'Sin pagos recurrentes',
                    'Soporte VIP',
                    'Acceso anticipado a nuevas funciones',
                  ],
                  buttonText: 'Comprar Ahora',
                  onPressed: () => _launchUrl(AppConstants.stripeLifetimePlan),
                  isPopular: false,
                  isPremium: true,
                ),
                const SizedBox(height: 32),

                // Botón para ir al login
                TextButton(
                  onPressed: () {
                    Navigator.pushNamed(context, '/login');
                  },
                  child: Text(
                    '¿Ya tienes cuenta? Inicia sesión',
                    style: TextStyle(
                      color: AppTheme.primaryColor,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                const SizedBox(height: 20),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _PricingCard extends StatelessWidget {
  final String title;
  final String price;
  final String period;
  final String description;
  final List<String> features;
  final String buttonText;
  final VoidCallback onPressed;
  final bool isPopular;
  final bool isPremium;

  const _PricingCard({
    required this.title,
    required this.price,
    required this.period,
    required this.description,
    required this.features,
    required this.buttonText,
    required this.onPressed,
    this.isPopular = false,
    this.isPremium = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isPopular 
              ? AppTheme.primaryColor 
              : isPremium 
                  ? AppTheme.secondaryColor 
                  : Colors.grey.shade200,
          width: isPopular || isPremium ? 2 : 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 20,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Stack(
        children: [
          Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (isPopular) const SizedBox(height: 8),
                Text(
                  title,
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  description,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: AppTheme.textSecondary,
                  ),
                ),
                const SizedBox(height: 16),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      price,
                      style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: isPremium ? AppTheme.secondaryColor : AppTheme.primaryColor,
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.only(bottom: 4),
                      child: Text(
                        period,
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: AppTheme.textSecondary,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                const Divider(),
                const SizedBox(height: 16),
                ...features.map((feature) => Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: Row(
                    children: [
                      Icon(
                        Icons.check_circle_rounded,
                        color: AppTheme.successColor,
                        size: 20,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          feature,
                          style: Theme.of(context).textTheme.bodyMedium,
                        ),
                      ),
                    ],
                  ),
                )),
                const SizedBox(height: 20),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: onPressed,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: isPremium 
                          ? AppTheme.secondaryColor 
                          : AppTheme.primaryColor,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                    ),
                    child: Text(buttonText),
                  ),
                ),
              ],
            ),
          ),
          if (isPopular)
            Positioned(
              top: 0,
              right: 16,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: AppTheme.primaryColor,
                  borderRadius: const BorderRadius.only(
                    bottomLeft: Radius.circular(8),
                    bottomRight: Radius.circular(8),
                  ),
                ),
                child: const Text(
                  'MÁS POPULAR',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
