class VentaModel {
  final String id;
  final String userId;
  final String? productoId;
  final String? productoNombre;
  final double cantidad;
  final double precioUnitario;
  final double total;
  final String? descripcion;
  final DateTime fecha;
  final DateTime createdAt;

  VentaModel({
    required this.id,
    required this.userId,
    this.productoId,
    this.productoNombre,
    required this.cantidad,
    required this.precioUnitario,
    required this.total,
    this.descripcion,
    required this.fecha,
    required this.createdAt,
  });

  factory VentaModel.fromJson(Map<String, dynamic> json) {
    return VentaModel(
      id: json['id'] ?? '',
      userId: json['user_id'] ?? '',
      productoId: json['producto_id'],
      productoNombre: json['producto_nombre'],
      cantidad: (json['cantidad'] ?? 0).toDouble(),
      precioUnitario: (json['precio_unitario'] ?? 0).toDouble(),
      total: (json['total'] ?? 0).toDouble(),
      descripcion: json['descripcion'],
      fecha: json['fecha'] != null 
          ? DateTime.parse(json['fecha']) 
          : DateTime.now(),
      createdAt: json['created_at'] != null 
          ? DateTime.parse(json['created_at']) 
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'user_id': userId,
      'producto_id': productoId,
      'producto_nombre': productoNombre,
      'cantidad': cantidad,
      'precio_unitario': precioUnitario,
      'total': total,
      'descripcion': descripcion,
      'fecha': fecha.toIso8601String(),
      'created_at': createdAt.toIso8601String(),
    };
  }

  Map<String, dynamic> toInsertJson() {
    return {
      'user_id': userId,
      'producto_id': productoId,
      'producto_nombre': productoNombre,
      'cantidad': cantidad,
      'precio_unitario': precioUnitario,
      'total': total,
      'descripcion': descripcion,
      'fecha': fecha.toIso8601String(),
    };
  }
}
