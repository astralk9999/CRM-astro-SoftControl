import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../../core/theme/app_theme.dart';
import '../../../shared/providers/auth_provider.dart';
import '../../../shared/services/ventas_service.dart';
import '../../../shared/services/gastos_service.dart';
import '../../../shared/services/productos_service.dart';

class ResumenScreen extends StatefulWidget {
  const ResumenScreen({super.key});

  @override
  State<ResumenScreen> createState() => _ResumenScreenState();
}

class _ResumenScreenState extends State<ResumenScreen> {
  bool _isLoading = true;
  double _totalVentas = 0;
  double _totalGastos = 0;
  double _ventasHoy = 0;
  double _gastosHoy = 0;
  int _totalProductos = 0;
  double _valorInventario = 0;
  int _productosStockBajo = 0;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    final authProvider = context.read<AuthProvider>();
    final userId = authProvider.user?.id;
    
    if (userId == null) return;

    setState(() => _isLoading = true);

    try {
      final results = await Future.wait([
        VentasService.getTotalVentas(userId),
        VentasService.getTotalVentasHoy(userId),
        GastosService.getTotalGastos(userId),
        GastosService.getTotalGastosHoy(userId),
        ProductosService.getTotalProductos(userId),
        ProductosService.getValorInventario(userId),
        ProductosService.getProductosBajoStock(userId),
      ]);

      setState(() {
        _totalVentas = results[0] as double;
        _ventasHoy = results[1] as double;
        _totalGastos = results[2] as double;
        _gastosHoy = results[3] as double;
        _totalProductos = results[4] as int;
        _valorInventario = results[5] as double;
        _productosStockBajo = (results[6] as List).length;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final currencyFormat = NumberFormat.currency(locale: 'es_ES', symbol: '€');
    final balance = _totalVentas - _totalGastos;
    final balanceHoy = _ventasHoy - _gastosHoy;

    return RefreshIndicator(
      onRefresh: _loadData,
      child: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Balance principal
                  _BalanceCard(
                    title: 'Balance Total',
                    amount: currencyFormat.format(balance),
                    isPositive: balance >= 0,
                    subtitle: 'Hoy: ${currencyFormat.format(balanceHoy)}',
                  ),
                  const SizedBox(height: 20),

                  // Fila de estadísticas
                  Row(
                    children: [
                      Expanded(
                        child: _StatCard(
                          title: 'Ventas Totales',
                          value: currencyFormat.format(_totalVentas),
                          icon: Icons.trending_up,
                          color: AppTheme.successColor,
                          subtitle: 'Hoy: ${currencyFormat.format(_ventasHoy)}',
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _StatCard(
                          title: 'Gastos Totales',
                          value: currencyFormat.format(_totalGastos),
                          icon: Icons.trending_down,
                          color: AppTheme.errorColor,
                          subtitle: 'Hoy: ${currencyFormat.format(_gastosHoy)}',
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),

                  // Estadísticas de inventario
                  Row(
                    children: [
                      Expanded(
                        child: _StatCard(
                          title: 'Productos',
                          value: _totalProductos.toString(),
                          icon: Icons.inventory_2,
                          color: AppTheme.primaryColor,
                          subtitle: 'En catálogo',
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _StatCard(
                          title: 'Valor Inventario',
                          value: currencyFormat.format(_valorInventario),
                          icon: Icons.account_balance_wallet,
                          color: AppTheme.secondaryColor,
                          subtitle: 'Stock actual',
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),

                  // Alertas
                  if (_productosStockBajo > 0)
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: AppTheme.warningColor.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: AppTheme.warningColor.withOpacity(0.3),
                        ),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            Icons.warning_amber_rounded,
                            color: AppTheme.warningColor,
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  'Stock bajo',
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                Text(
                                  '$_productosStockBajo productos necesitan reposición',
                                  style: TextStyle(
                                    color: AppTheme.textSecondary,
                                    fontSize: 13,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  const SizedBox(height: 20),

                  // Acciones rápidas
                  Text(
                    'Acciones Rápidas',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: _QuickActionButton(
                          icon: Icons.add_shopping_cart,
                          label: 'Nueva Venta',
                          color: AppTheme.successColor,
                          onTap: () {
                            // Navigate to add venta
                          },
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _QuickActionButton(
                          icon: Icons.receipt_long,
                          label: 'Nuevo Gasto',
                          color: AppTheme.errorColor,
                          onTap: () {
                            // Navigate to add gasto
                          },
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _QuickActionButton(
                          icon: Icons.add_box,
                          label: 'Nuevo Producto',
                          color: AppTheme.primaryColor,
                          onTap: () {
                            // Navigate to add producto
                          },
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
    );
  }
}

class _BalanceCard extends StatelessWidget {
  final String title;
  final String amount;
  final bool isPositive;
  final String subtitle;

  const _BalanceCard({
    required this.title,
    required this.amount,
    required this.isPositive,
    required this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: isPositive
              ? [AppTheme.primaryColor, AppTheme.primaryColor.withOpacity(0.8)]
              : [AppTheme.errorColor, AppTheme.errorColor.withOpacity(0.8)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: (isPositive ? AppTheme.primaryColor : AppTheme.errorColor)
                .withOpacity(0.3),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              color: Colors.white70,
              fontSize: 14,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            amount,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 32,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            subtitle,
            style: const TextStyle(
              color: Colors.white70,
              fontSize: 14,
            ),
          ),
        ],
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  final String title;
  final String value;
  final IconData icon;
  final Color color;
  final String subtitle;

  const _StatCard({
    required this.title,
    required this.value,
    required this.icon,
    required this.color,
    required this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(icon, color: color, size: 20),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            title,
            style: TextStyle(
              color: AppTheme.textSecondary,
              fontSize: 12,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 16,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            subtitle,
            style: TextStyle(
              color: AppTheme.textSecondary,
              fontSize: 11,
            ),
          ),
        ],
      ),
    );
  }
}

class _QuickActionButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;

  const _QuickActionButton({
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 16),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          children: [
            Icon(icon, color: color),
            const SizedBox(height: 8),
            Text(
              label,
              style: TextStyle(
                color: color,
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
