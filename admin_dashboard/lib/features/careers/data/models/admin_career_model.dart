import '../../domain/entities/admin_career.dart';

class AdminCareerModel extends AdminCareer {
  const AdminCareerModel({
    required super.id,
    required super.name,
    super.sector,
    super.description,
    super.minEducationLevel,
    required super.isActive,
    required super.createdAt,
  });

  factory AdminCareerModel.fromJson(Map<String, dynamic> json) {
    return AdminCareerModel(
      id: json['id'] as String,
      name: json['name'] as String,
      sector: json['sector'] as String?,
      description: json['description'] as String?,
      minEducationLevel: json['min_education_level'] as String?,
      isActive: json['is_active'] as bool? ?? true,
      createdAt: DateTime.tryParse(json['created_at'] as String? ?? '') ??
          DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() => {
        'name': name,
        'sector': sector,
        'description': description,
        'min_education_level': minEducationLevel,
        'is_active': isActive,
      };
}

class PaginatedCareersModel extends PaginatedCareers {
  const PaginatedCareersModel({
    required super.items,
    required super.total,
    required super.page,
    required super.perPage,
  });

  factory PaginatedCareersModel.fromJson(
    Map<String, dynamic> json,
    int page,
    int perPage,
  ) {
    final items = (json['items'] as List<dynamic>? ?? [])
        .map((e) => AdminCareerModel.fromJson(e as Map<String, dynamic>))
        .toList();
    return PaginatedCareersModel(
      items: items,
      total: json['total'] as int? ?? 0,
      page: page,
      perPage: perPage,
    );
  }
}
