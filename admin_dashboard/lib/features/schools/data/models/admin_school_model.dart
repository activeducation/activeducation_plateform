import '../../domain/entities/admin_school.dart';

class AdminSchoolModel extends AdminSchool {
  const AdminSchoolModel({
    required super.id,
    required super.name,
    super.city,
    super.type,
    required super.isVerified,
    required super.isActive,
    super.programCount,
    super.logoUrl,
    required super.createdAt,
  });

  factory AdminSchoolModel.fromJson(Map<String, dynamic> json) {
    return AdminSchoolModel(
      id: json['id'] as String,
      name: json['name'] as String,
      city: json['city'] as String?,
      type: json['type'] as String?,
      isVerified: json['is_verified'] as bool? ?? false,
      isActive: json['is_active'] as bool? ?? true,
      programCount: json['program_count'] as int?,
      logoUrl: json['logo_url'] as String?,
      createdAt: DateTime.tryParse(json['created_at'] as String? ?? '') ??
          DateTime.now(),
    );
  }
}

class PaginatedSchoolsModel extends PaginatedSchools {
  const PaginatedSchoolsModel({
    required super.items,
    required super.total,
    required super.page,
    required super.perPage,
  });

  factory PaginatedSchoolsModel.fromJson(
    Map<String, dynamic> json,
    int page,
    int perPage,
  ) {
    final items = (json['items'] as List<dynamic>? ?? [])
        .map((e) => AdminSchoolModel.fromJson(e as Map<String, dynamic>))
        .toList();
    return PaginatedSchoolsModel(
      items: items,
      total: json['total'] as int? ?? 0,
      page: page,
      perPage: perPage,
    );
  }
}
