class UserModel {
  final String id;
  final String email;
  final String fullName;
  final String role;
  final String? planType;
  final DateTime? planExpiresAt;
  final DateTime createdAt;

  UserModel({
    required this.id,
    required this.email,
    required this.fullName,
    required this.role,
    this.planType,
    this.planExpiresAt,
    required this.createdAt,
  });

  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      id: json['id'] ?? '',
      email: json['email'] ?? '',
      fullName: json['full_name'] ?? '',
      role: json['role'] ?? 'user',
      planType: json['plan_type'],
      planExpiresAt: json['plan_expires_at'] != null 
          ? DateTime.parse(json['plan_expires_at']) 
          : null,
      createdAt: json['created_at'] != null 
          ? DateTime.parse(json['created_at']) 
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'email': email,
      'full_name': fullName,
      'role': role,
      'plan_type': planType,
      'plan_expires_at': planExpiresAt?.toIso8601String(),
      'created_at': createdAt.toIso8601String(),
    };
  }

  UserModel copyWith({
    String? id,
    String? email,
    String? fullName,
    String? role,
    String? planType,
    DateTime? planExpiresAt,
    DateTime? createdAt,
  }) {
    return UserModel(
      id: id ?? this.id,
      email: email ?? this.email,
      fullName: fullName ?? this.fullName,
      role: role ?? this.role,
      planType: planType ?? this.planType,
      planExpiresAt: planExpiresAt ?? this.planExpiresAt,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  bool get isUser => role == 'user';
  bool get isStaff => role == 'staff';
  bool get isAdmin => role == 'admin';
  bool get isSuperAdmin => role == 'super_admin';
  
  bool get canManageUsers => isStaff || isAdmin || isSuperAdmin;
  bool get canManageProducts => isAdmin || isSuperAdmin;
  bool get canManageAdmins => isSuperAdmin;
}
