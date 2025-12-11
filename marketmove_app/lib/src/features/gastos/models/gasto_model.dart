class GastoModel {
  final String id;
  final String userId;
  final String categoria;
  final double monto;
  final String? descripcion;
  final DateTime fecha;
  final DateTime createdAt;

  GastoModel({
    required this.id,
    required this.userId,
    required this.categoria,
    required this.monto,
    this.descripcion,
    required this.fecha,
    required this.createdAt,
  });

  factory GastoModel.fromJson(Map<String, dynamic> json) {
    return GastoModel(
      id: json['id'] ?? '',
      userId: json['user_id'] ?? '',
      categoria: json['categoria'] ?? 'Otros',
      monto: (json['monto'] ?? 0).toDouble(),
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
      'categoria': categoria,
      'monto': monto,
      'descripcion': descripcion,
      'fecha': fecha.toIso8601String(),
      'created_at': createdAt.toIso8601String(),
    };
  }

  Map<String, dynamic> toInsertJson() {
    return {
      'user_id': userId,
      'categoria': categoria,
      'monto': monto,
      'descripcion': descripcion,
      'fecha': fecha.toIso8601String(),
    };
  }

  static List<String> get categorias => [
    'Alquiler',
    'Servicios',
    'Suministros',
    'Salarios',
    'Marketing',
    'Mantenimiento',
    'Transporte',
    'Otros',
  ];
}
