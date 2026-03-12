import '../entities/admin_school.dart';

abstract class SchoolsRepository {
  Future<PaginatedSchools> getSchools({
    int page = 1,
    int perPage = 20,
    String? search,
    bool? verified,
  });

  Future<AdminSchool> getSchoolById(String id);

  Future<AdminSchool> createSchool(Map<String, dynamic> data);

  Future<AdminSchool> updateSchool(String id, Map<String, dynamic> data);

  Future<void> verifySchool(String id);

  Future<void> toggleSchoolActive(String id);

  Future<void> deleteSchool(String id);
}
