import 'package:supabase_flutter/supabase_flutter.dart';
import '../../features/ventas/models/venta_model.dart';

class VentasService {
  static SupabaseClient get _client => Supabase.instance.client;

  static Future<List<VentaModel>> getVentas(String userId) async {
    final response = await _client
        .from('ventas')
        .select()
        .eq('user_id', userId)
        .order('fecha', ascending: false);
    
    return (response as List)
        .map((json) => VentaModel.fromJson(json))
        .toList();
  }

  static Future<List<VentaModel>> getVentasByDateRange(
    String userId,
    DateTime startDate,
    DateTime endDate,
  ) async {
    final response = await _client
        .from('ventas')
        .select()
        .eq('user_id', userId)
        .gte('fecha', startDate.toIso8601String())
        .lte('fecha', endDate.toIso8601String())
        .order('fecha', ascending: false);
    
    return (response as List)
        .map((json) => VentaModel.fromJson(json))
        .toList();
  }

  static Future<VentaModel> createVenta(VentaModel venta) async {
    final response = await _client
        .from('ventas')
        .insert(venta.toInsertJson())
        .select()
        .single();
    
    return VentaModel.fromJson(response);
  }

  static Future<void> updateVenta(VentaModel venta) async {
    await _client
        .from('ventas')
        .update(venta.toInsertJson())
        .eq('id', venta.id);
  }

  static Future<void> deleteVenta(String id) async {
    await _client
        .from('ventas')
        .delete()
        .eq('id', id);
  }

  static Future<double> getTotalVentas(String userId) async {
    final response = await _client
        .from('ventas')
        .select('total')
        .eq('user_id', userId);
    
    double total = 0;
    for (var item in response) {
      total += (item['total'] ?? 0).toDouble();
    }
    return total;
  }

  static Future<double> getTotalVentasHoy(String userId) async {
    final today = DateTime.now();
    final startOfDay = DateTime(today.year, today.month, today.day);
    final endOfDay = startOfDay.add(const Duration(days: 1));

    final response = await _client
        .from('ventas')
        .select('total')
        .eq('user_id', userId)
        .gte('fecha', startOfDay.toIso8601String())
        .lt('fecha', endOfDay.toIso8601String());
    
    double total = 0;
    for (var item in response) {
      total += (item['total'] ?? 0).toDouble();
    }
    return total;
  }
}
