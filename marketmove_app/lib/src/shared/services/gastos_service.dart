import 'package:supabase_flutter/supabase_flutter.dart';
import '../../features/gastos/models/gasto_model.dart';

class GastosService {
  static SupabaseClient get _client => Supabase.instance.client;

  static Future<List<GastoModel>> getGastos(String userId) async {
    final response = await _client
        .from('gastos')
        .select()
        .eq('user_id', userId)
        .order('fecha', ascending: false);
    
    return (response as List)
        .map((json) => GastoModel.fromJson(json))
        .toList();
  }

  static Future<List<GastoModel>> getGastosByDateRange(
    String userId,
    DateTime startDate,
    DateTime endDate,
  ) async {
    final response = await _client
        .from('gastos')
        .select()
        .eq('user_id', userId)
        .gte('fecha', startDate.toIso8601String())
        .lte('fecha', endDate.toIso8601String())
        .order('fecha', ascending: false);
    
    return (response as List)
        .map((json) => GastoModel.fromJson(json))
        .toList();
  }

  static Future<GastoModel> createGasto(GastoModel gasto) async {
    final response = await _client
        .from('gastos')
        .insert(gasto.toInsertJson())
        .select()
        .single();
    
    return GastoModel.fromJson(response);
  }

  static Future<void> updateGasto(GastoModel gasto) async {
    await _client
        .from('gastos')
        .update(gasto.toInsertJson())
        .eq('id', gasto.id);
  }

  static Future<void> deleteGasto(String id) async {
    await _client
        .from('gastos')
        .delete()
        .eq('id', id);
  }

  static Future<double> getTotalGastos(String userId) async {
    final response = await _client
        .from('gastos')
        .select('monto')
        .eq('user_id', userId);
    
    double total = 0;
    for (var item in response) {
      total += (item['monto'] ?? 0).toDouble();
    }
    return total;
  }

  static Future<double> getTotalGastosHoy(String userId) async {
    final today = DateTime.now();
    final startOfDay = DateTime(today.year, today.month, today.day);
    final endOfDay = startOfDay.add(const Duration(days: 1));

    final response = await _client
        .from('gastos')
        .select('monto')
        .eq('user_id', userId)
        .gte('fecha', startOfDay.toIso8601String())
        .lt('fecha', endOfDay.toIso8601String());
    
    double total = 0;
    for (var item in response) {
      total += (item['monto'] ?? 0).toDouble();
    }
    return total;
  }

  static Future<Map<String, double>> getGastosPorCategoria(String userId) async {
    final response = await _client
        .from('gastos')
        .select('categoria, monto')
        .eq('user_id', userId);
    
    Map<String, double> gastosPorCategoria = {};
    for (var item in response) {
      final categoria = item['categoria'] ?? 'Otros';
      final monto = (item['monto'] ?? 0).toDouble();
      gastosPorCategoria[categoria] = (gastosPorCategoria[categoria] ?? 0) + monto;
    }
    return gastosPorCategoria;
  }
}
