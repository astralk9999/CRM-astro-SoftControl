import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../../core/theme/app_theme.dart';
import '../../../shared/providers/auth_provider.dart';
import '../../../shared/services/gastos_service.dart';
import '../models/gasto_model.dart';

class GastosScreen extends StatefulWidget {
  const GastosScreen({super.key});

  @override
  State<GastosScreen> createState() => _GastosScreenState();
}

class _GastosScreenState extends State<GastosScreen> {
  List<GastoModel> _gastos = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadGastos();
  }

  Future<void> _loadGastos() async {
    final authProvider = context.read<AuthProvider>();
    final userId = authProvider.user?.id;
    
    if (userId == null) return;

    setState(() => _isLoading = true);

    try {
      final gastos = await GastosService.getGastos(userId);
      setState(() {
        _gastos = gastos;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
    }
  }

  void _showAddGastoDialog() {
    final formKey = GlobalKey<FormState>();
    final descripcionController = TextEditingController();
    final montoController = TextEditingController();
    String selectedCategoria = GastoModel.categorias.first;
    
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => StatefulBuilder(
        builder: (context, setModalState) => Padding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(context).viewInsets.bottom,
            left: 24,
            right: 24,
            top: 24,
          ),
          child: Form(
            key: formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Nuevo Gasto',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 20),
                DropdownButtonFormField<String>(
                  initialValue: selectedCategoria,
                  decoration: const InputDecoration(
                    labelText: 'Categoría',
                    prefixIcon: Icon(Icons.category_outlined),
                  ),
                  items: GastoModel.categorias.map((cat) => 
                    DropdownMenuItem(value: cat, child: Text(cat))
                  ).toList(),
                  onChanged: (value) {
                    setModalState(() => selectedCategoria = value!);
                  },
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: descripcionController,
                  decoration: const InputDecoration(
                    labelText: 'Descripción (opcional)',
                    prefixIcon: Icon(Icons.description_outlined),
                  ),
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: montoController,
                  keyboardType: TextInputType.numberWithOptions(decimal: true),
                  decoration: const InputDecoration(
                    labelText: 'Monto (€)',
                    prefixIcon: Icon(Icons.euro),
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Ingresa el monto';
                    }
                    if (double.tryParse(value) == null) {
                      return 'Monto inválido';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 24),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.errorColor,
                    ),
                    onPressed: () async {
                      if (formKey.currentState!.validate()) {
                        final authProvider = context.read<AuthProvider>();
                        final userId = authProvider.user?.id;
                        if (userId == null) return;

                        final gasto = GastoModel(
                          id: '',
                          userId: userId,
                          categoria: selectedCategoria,
                          monto: double.parse(montoController.text),
                          descripcion: descripcionController.text.isEmpty 
                              ? null 
                              : descripcionController.text,
                          fecha: DateTime.now(),
                          createdAt: DateTime.now(),
                        );

                        try {
                          await GastosService.createGasto(gasto);
                          Navigator.pop(context);
                          _loadGastos();
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Gasto registrado correctamente'),
                              backgroundColor: Colors.green,
                            ),
                          );
                        } catch (e) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text('Error: $e'),
                              backgroundColor: Colors.red,
                            ),
                          );
                        }
                      }
                    },
                    child: const Text('Guardar Gasto'),
                  ),
                ),
                const SizedBox(height: 24),
              ],
            ),
          ),
        ),
      ),
    );
  }

  IconData _getCategoryIcon(String categoria) {
    switch (categoria) {
      case 'Alquiler':
        return Icons.home;
      case 'Servicios':
        return Icons.build;
      case 'Suministros':
        return Icons.water_drop;
      case 'Salarios':
        return Icons.people;
      case 'Marketing':
        return Icons.campaign;
      case 'Mantenimiento':
        return Icons.handyman;
      case 'Transporte':
        return Icons.local_shipping;
      default:
        return Icons.receipt_long;
    }
  }

  @override
  Widget build(BuildContext context) {
    final currencyFormat = NumberFormat.currency(locale: 'es_ES', symbol: '€');
    final dateFormat = DateFormat('dd/MM/yyyy HH:mm');

    return Scaffold(
      body: RefreshIndicator(
        onRefresh: _loadGastos,
        child: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : _gastos.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.receipt_long_outlined,
                          size: 80,
                          color: Colors.grey.shade300,
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'No hay gastos registrados',
                          style: TextStyle(
                            color: AppTheme.textSecondary,
                            fontSize: 16,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Pulsa + para añadir un gasto',
                          style: TextStyle(
                            color: AppTheme.textSecondary,
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: _gastos.length,
                    itemBuilder: (context, index) {
                      final gasto = _gastos[index];
                      return Card(
                        margin: const EdgeInsets.only(bottom: 12),
                        child: ListTile(
                          contentPadding: const EdgeInsets.all(16),
                          leading: Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: AppTheme.errorColor.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Icon(
                              _getCategoryIcon(gasto.categoria),
                              color: AppTheme.errorColor,
                            ),
                          ),
                          title: Text(
                            gasto.categoria,
                            style: const TextStyle(fontWeight: FontWeight.w600),
                          ),
                          subtitle: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              if (gasto.descripcion != null) ...[
                                const SizedBox(height: 4),
                                Text(
                                  gasto.descripcion!,
                                  style: TextStyle(color: AppTheme.textSecondary),
                                ),
                              ],
                              Text(
                                dateFormat.format(gasto.fecha),
                                style: TextStyle(
                                  color: AppTheme.textSecondary,
                                  fontSize: 12,
                                ),
                              ),
                            ],
                          ),
                          trailing: Text(
                            '-${currencyFormat.format(gasto.monto)}',
                            style: TextStyle(
                              color: AppTheme.errorColor,
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                          ),
                        ),
                      );
                    },
                  ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _showAddGastoDialog,
        backgroundColor: AppTheme.errorColor,
        child: const Icon(Icons.add),
      ),
    );
  }
}
