import 'package:supabase_flutter/supabase_flutter.dart';
import '../../features/productos/models/producto_model.dart';

class ProductosService {
  static SupabaseClient get _client => Supabase.instance.client;

  static Future<List<ProductoModel>> getProductos(String userId) async {
    final response = await _client
        .from('productos')
        .select()
        .eq('user_id', userId)
        .order('nombre', ascending: true);
    
    return (response as List)
        .map((json) => ProductoModel.fromJson(json))
        .toList();
  }

  static Future<List<ProductoModel>> getProductosBajoStock(String userId) async {
    final response = await _client
        .from('productos')
        .select()
        .eq('user_id', userId)
        .order('stock', ascending: true);
    
    final productos = (response as List)
        .map((json) => ProductoModel.fromJson(json))
        .toList();
    
    return productos.where((p) => p.stockBajo).toList();
  }

  static Future<ProductoModel?> getProductoById(String id) async {
    final response = await _client
        .from('productos')
        .select()
        .eq('id', id)
        .maybeSingle();
    
    if (response == null) return null;
    return ProductoModel.fromJson(response);
  }

  static Future<ProductoModel> createProducto(ProductoModel producto) async {
    final response = await _client
        .from('productos')
        .insert(producto.toInsertJson())
        .select()
        .single();
    
    return ProductoModel.fromJson(response);
  }

  static Future<void> updateProducto(ProductoModel producto) async {
    await _client
        .from('productos')
        .update({
          ...producto.toInsertJson(),
          'updated_at': DateTime.now().toIso8601String(),
        })
        .eq('id', producto.id);
  }

  static Future<void> deleteProducto(String id) async {
    await _client
        .from('productos')
        .delete()
        .eq('id', id);
  }

  static Future<void> updateStock(String productoId, int nuevoStock) async {
    await _client
        .from('productos')
        .update({
          'stock': nuevoStock,
          'updated_at': DateTime.now().toIso8601String(),
        })
        .eq('id', productoId);
  }

  static Future<void> decrementStock(String productoId, int cantidad) async {
    final producto = await getProductoById(productoId);
    if (producto != null) {
      final nuevoStock = producto.stock - cantidad;
      await updateStock(productoId, nuevoStock < 0 ? 0 : nuevoStock);
    }
  }

  static Future<void> incrementStock(String productoId, int cantidad) async {
    final producto = await getProductoById(productoId);
    if (producto != null) {
      await updateStock(productoId, producto.stock + cantidad);
    }
  }

  static Future<int> getTotalProductos(String userId) async {
    final response = await _client
        .from('productos')
        .select('id')
        .eq('user_id', userId);
    
    return (response as List).length;
  }

  static Future<double> getValorInventario(String userId) async {
    final response = await _client
        .from('productos')
        .select('precio, stock')
        .eq('user_id', userId);
    
    double total = 0;
    for (var item in response) {
      final precio = (item['precio'] ?? 0).toDouble();
      final stock = (item['stock'] ?? 0);
      total += precio * stock;
    }
    return total;
  }
}
