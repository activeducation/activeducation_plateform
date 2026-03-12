import 'package:equatable/equatable.dart';

class AdminTest extends Equatable {
  final String id;
  final String name;
  final String? description;
  final String type;
  final int questionCount;
  final int durationMinutes;
  final bool isActive;
  final DateTime createdAt;

  const AdminTest({
    required this.id,
    required this.name,
    this.description,
    required this.type,
    required this.questionCount,
    required this.durationMinutes,
    required this.isActive,
    required this.createdAt,
  });

  @override
  List<Object?> get props => [id, name, type, isActive];
}

class PaginatedTests extends Equatable {
  final List<AdminTest> items;
  final int total;
  final int page;
  final int perPage;

  const PaginatedTests({
    required this.items,
    required this.total,
    required this.page,
    required this.perPage,
  });

  int get totalPages => (total / perPage).ceil();

  @override
  List<Object?> get props => [items, total, page, perPage];
}
