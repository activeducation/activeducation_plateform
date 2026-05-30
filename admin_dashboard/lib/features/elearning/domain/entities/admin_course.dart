class AdminCourse {
  final String id;
  final String title;
  final String? description;
  final String? thumbnailUrl;
  final bool isPublished;
  final String? schoolId;
  final String? schoolName;
  final int? modulesCount;
  final int? lessonsCount;
  final String? difficulty;
  final int? durationMinutes;
  final int? displayOrder;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  AdminCourse({
    required this.id,
    required this.title,
    this.description,
    this.thumbnailUrl,
    required this.isPublished,
    this.schoolId,
    this.schoolName,
    this.modulesCount,
    this.lessonsCount,
    this.difficulty,
    this.durationMinutes,
    this.displayOrder,
    this.createdAt,
    this.updatedAt,
  });

  factory AdminCourse.fromJson(Map<String, dynamic> json) {
    return AdminCourse(
      id: json['id'] as String,
      title: json['title'] as String,
      description: json['description'] as String?,
      thumbnailUrl: json['thumbnail_url'] as String?,
      isPublished: json['is_published'] as bool? ?? false,
      schoolId: json['school_id'] as String?,
      schoolName: json['school_name'] as String?,
      modulesCount: json['modules_count'] as int?,
      lessonsCount: json['lessons_count'] as int?,
      difficulty: json['difficulty'] as String?,
      durationMinutes: json['duration_minutes'] as int?,
      displayOrder: json['display_order'] as int?,
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'] as String)
          : null,
      updatedAt: json['updated_at'] != null
          ? DateTime.parse(json['updated_at'] as String)
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'thumbnail_url': thumbnailUrl,
      'is_published': isPublished,
      'school_id': schoolId,
      'school_name': schoolName,
      'modules_count': modulesCount,
      'lessons_count': lessonsCount,
      'difficulty': difficulty,
      'duration_minutes': durationMinutes,
      'display_order': displayOrder,
      'created_at': createdAt?.toIso8601String(),
      'updated_at': updatedAt?.toIso8601String(),
    };
  }
}

class PaginatedCourses {
  final List<AdminCourse> items;
  final int total;
  final int page;
  final int perPage;
  final int totalPages;

  PaginatedCourses({
    required this.items,
    required this.total,
    required this.page,
    required this.perPage,
    required this.totalPages,
  });

  factory PaginatedCourses.fromJson(
    Map<String, dynamic> json,
    int page,
    int perPage,
  ) {
    return PaginatedCourses(
      items: (json['items'] as List<dynamic>?)
              ?.map((e) => AdminCourse.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
      total: json['total'] as int? ?? 0,
      page: json['page'] as int? ?? page,
      perPage: json['per_page'] as int? ?? perPage,
      totalPages: json['total_pages'] as int? ?? 0,
    );
  }
}