import 'package:equatable/equatable.dart';

class AdminCareer extends Equatable {
  final String id;
  final String name;
  final String? sector;
  final String? description;
  final String? minEducationLevel;
  final bool isActive;
  final DateTime createdAt;

  const AdminCareer({
    required this.id,
    required this.name,
    this.sector,
    this.description,
    this.minEducationLevel,
    required this.isActive,
    required this.createdAt,
  });

  @override
  List<Object?> get props => [id, name, sector, isActive];
}

class PaginatedCareers extends Equatable {
  final List<AdminCareer> items;
  final int total;
  final int page;
  final int perPage;

  const PaginatedCareers({
    required this.items,
    required this.total,
    required this.page,
    required this.perPage,
  });

  int get totalPages => (total / perPage).ceil();

  @override
  List<Object?> get props => [items, total, page, perPage];
}
