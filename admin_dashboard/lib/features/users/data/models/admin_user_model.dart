import '../../domain/entities/admin_user.dart';

class AdminUserModel extends AdminUser {
  const AdminUserModel({
    required super.id,
    required super.email,
    super.firstName,
    super.lastName,
    required super.role,
    required super.isActive,
    required super.createdAt,
    super.lastLoginAt,
  });

  factory AdminUserModel.fromJson(Map<String, dynamic> json) {
    return AdminUserModel(
      id: json['id'] as String,
      email: json['email'] as String,
      firstName: json['first_name'] as String?,
      lastName: json['last_name'] as String?,
      role: json['role'] as String? ?? 'student',
      isActive: json['is_active'] as bool? ?? true,
      createdAt: DateTime.tryParse(json['created_at'] as String? ?? '') ??
          DateTime.now(),
      lastLoginAt: json['last_login_at'] != null
          ? DateTime.tryParse(json['last_login_at'] as String)
          : null,
    );
  }
}

class PaginatedUsersModel extends PaginatedUsers {
  const PaginatedUsersModel({
    required super.items,
    required super.total,
    required super.page,
    required super.perPage,
  });

  factory PaginatedUsersModel.fromJson(Map<String, dynamic> json, int page, int perPage) {
    final items = (json['items'] as List<dynamic>? ?? [])
        .map((e) => AdminUserModel.fromJson(e as Map<String, dynamic>))
        .toList();
    return PaginatedUsersModel(
      items: items,
      total: json['total'] as int? ?? 0,
      page: page,
      perPage: perPage,
    );
  }
}
