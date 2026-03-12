import '../../domain/entities/admin_test.dart';

class AdminTestModel extends AdminTest {
  const AdminTestModel({
    required super.id,
    required super.name,
    super.description,
    required super.type,
    required super.questionCount,
    required super.durationMinutes,
    required super.isActive,
    required super.createdAt,
  });

  factory AdminTestModel.fromJson(Map<String, dynamic> json) {
    return AdminTestModel(
      id: json['id'] as String,
      name: json['name'] as String,
      description: json['description'] as String?,
      type: json['type'] as String? ?? 'riasec',
      questionCount: json['question_count'] as int? ?? 0,
      durationMinutes: json['duration_minutes'] as int? ?? 20,
      isActive: json['is_active'] as bool? ?? true,
      createdAt: DateTime.tryParse(json['created_at'] as String? ?? '') ??
          DateTime.now(),
    );
  }
}

class PaginatedTestsModel extends PaginatedTests {
  const PaginatedTestsModel({
    required super.items,
    required super.total,
    required super.page,
    required super.perPage,
  });

  factory PaginatedTestsModel.fromJson(
    Map<String, dynamic> json,
    int page,
    int perPage,
  ) {
    final items = (json['items'] as List<dynamic>? ?? [])
        .map((e) => AdminTestModel.fromJson(e as Map<String, dynamic>))
        .toList();
    return PaginatedTestsModel(
      items: items,
      total: json['total'] as int? ?? 0,
      page: page,
      perPage: perPage,
    );
  }
}
