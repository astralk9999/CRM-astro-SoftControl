class ProductoModel {
  final String id;
  final String userId;
  final String nombre;
  final String? descripcion;
  final double precio;
  final int stock;
  final int stockMinimo;
  final String? categoria;
  final String? codigoBarras;
  final DateTime createdAt;
  final DateTime? updatedAt;

  ProductoModel({
    required this.id,
    required this.userId,
    required this.nombre,
    this.descripcion,
    required this.precio,
    required this.stock,
    this.stockMinimo = 5,
    this.categoria,
    this.codigoBarras,
    required this.createdAt,
    this.updatedAt,
  });

  factory ProductoModel.fromJson(Map<String, dynamic> json) {
    return ProductoModel(
      id: json['id'] ?? '',
      userId: json['user_id'] ?? '',
      nombre: json['nombre'] ?? '',
      descripcion: json['descripcion'],
      precio: (json['precio'] ?? 0).toDouble(),
      stock: json['stock'] ?? 0,
      stockMinimo: json['stock_minimo'] ?? 5,
      categoria: json['categoria'],
      codigoBarras: json['codigo_barras'],
      createdAt: json['created_at'] != null 
          ? DateTime.parse(json['created_at']) 
          : DateTime.now(),
      updatedAt: json['updated_at'] != null 
          ? DateTime.parse(json['updated_at']) 
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'user_id': userId,
      'nombre': nombre,
      'descripcion': descripcion,
      'precio': precio,
      'stock': stock,
      'stock_minimo': stockMinimo,
      'categoria': categoria,
      'codigo_barras': codigoBarras,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt?.toIso8601String(),
    };
  }

  Map<String, dynamic> toInsertJson() {
    return {
      'user_id': userId,
      'nombre': nombre,
      'descripcion': descripcion,
      'precio': precio,
      'stock': stock,
      'stock_minimo': stockMinimo,
      'categoria': categoria,
      'codigo_barras': codigoBarras,
    };
  }

  ProductoModel copyWith({
    String? id,
    String? userId,
    String? nombre,
    String? descripcion,
    double? precio,
    int? stock,
    int? stockMinimo,
    String? categoria,
    String? codigoBarras,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return ProductoModel(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      nombre: nombre ?? this.nombre,
      descripcion: descripcion ?? this.descripcion,
      precio: precio ?? this.precio,
      stock: stock ?? this.stock,
      stockMinimo: stockMinimo ?? this.stockMinimo,
      categoria: categoria ?? this.categoria,
      codigoBarras: codigoBarras ?? this.codigoBarras,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  bool get stockBajo => stock <= stockMinimo;
  bool get sinStock => stock <= 0;

  static List<String> get categorias => [
    'Alimentos',
    'Bebidas',
    'Limpieza',
    'Electrónica',
    'Ropa',
    'Hogar',
    'Papelería',
    'Otros',
  ];
}
