import 'package:equatable/equatable.dart';

class AdminUser extends Equatable {
  final String id;
  final String email;
  final String? firstName;
  final String? lastName;
  final String role;
  final bool isActive;
  final DateTime createdAt;
  final DateTime? lastLoginAt;

  const AdminUser({
    required this.id,
    required this.email,
    this.firstName,
    this.lastName,
    required this.role,
    required this.isActive,
    required this.createdAt,
    this.lastLoginAt,
  });

  String get fullName {
    final name = '${firstName ?? ''} ${lastName ?? ''}'.trim();
    return name.isEmpty ? email : name;
  }

  @override
  List<Object?> get props => [id, email, role, isActive];
}

class PaginatedUsers extends Equatable {
  final List<AdminUser> items;
  final int total;
  final int page;
  final int perPage;

  const PaginatedUsers({
    required this.items,
    required this.total,
    required this.page,
    required this.perPage,
  });

  int get totalPages => (total / perPage).ceil();

  @override
  List<Object?> get props => [items, total, page, perPage];
}
