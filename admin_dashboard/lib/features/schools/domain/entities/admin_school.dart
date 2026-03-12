import 'package:equatable/equatable.dart';

class AdminSchool extends Equatable {
  final String id;
  final String name;
  final String? city;
  final String? type;
  final bool isVerified;
  final bool isActive;
  final int? programCount;
  final String? logoUrl;
  final DateTime createdAt;

  const AdminSchool({
    required this.id,
    required this.name,
    this.city,
    this.type,
    required this.isVerified,
    required this.isActive,
    this.programCount,
    this.logoUrl,
    required this.createdAt,
  });

  @override
  List<Object?> get props => [id, name, isVerified, isActive];
}

class PaginatedSchools extends Equatable {
  final List<AdminSchool> items;
  final int total;
  final int page;
  final int perPage;

  const PaginatedSchools({
    required this.items,
    required this.total,
    required this.page,
    required this.perPage,
  });

  int get totalPages => (total / perPage).ceil();

  @override
  List<Object?> get props => [items, total, page, perPage];
}
