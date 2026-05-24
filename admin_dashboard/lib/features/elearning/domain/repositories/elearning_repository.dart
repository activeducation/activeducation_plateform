import '../entities/admin_course.dart';

abstract class ElearningRepository {
  Future<PaginatedCourses> getCourses({
    int page = 1,
    int perPage = 20,
    String? search,
    String? schoolId,
    bool? isPublished,
  });

  Future<AdminCourse> getCourseById(String id);

  Future<void> deleteCourse(String id);

  Future<List<SchoolWithCourses>> getSchoolsWithCourses();
}

class SchoolWithCourses {
  final String id;
  final String name;
  final String? city;
  final int coursesCount;

  SchoolWithCourses({
    required this.id,
    required this.name,
    this.city,
    required this.coursesCount,
  });

  factory SchoolWithCourses.fromJson(Map<String, dynamic> json) {
    return SchoolWithCourses(
      id: json['id'] as String,
      name: json['name'] as String,
      city: json['city'] as String?,
      coursesCount: json['courses_count'] as int? ?? 0,
    );
  }
}