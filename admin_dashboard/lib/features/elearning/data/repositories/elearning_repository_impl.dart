import '../../../../core/error/failures.dart';
import '../../../../core/network/api_client.dart';
import '../../../../core/constants/api_endpoints.dart';
import '../../domain/entities/admin_course.dart';
import '../../domain/repositories/elearning_repository.dart';

class ElearningRepositoryImpl implements ElearningRepository {
  final ApiClient _apiClient;

  ElearningRepositoryImpl(this._apiClient);

  @override
  Future<PaginatedCourses> getCourses({
    int page = 1,
    int perPage = 20,
    String? search,
    String? schoolId,
    bool? isPublished,
  }) async {
    try {
      final params = <String, dynamic>{
        'page': page,
        'per_page': perPage,
        if (search?.isNotEmpty == true) 'search': search,
        if (schoolId != null) 'school_id': schoolId,
        if (isPublished != null) 'is_published': isPublished,
      };
      final response = await _apiClient.get<Map<String, dynamic>>(
        ApiEndpoints.adminElearningCourses,
        queryParameters: params,
      );
      return PaginatedCourses.fromJson(
        response.data as Map<String, dynamic>,
        page,
        perPage,
      );
    } catch (e) {
      throw AdminFailure('Erreur lors du chargement des cours : $e');
    }
  }

  @override
  Future<AdminCourse> getCourseById(String id) async {
    try {
      final response = await _apiClient.get<Map<String, dynamic>>(
        ApiEndpoints.adminElearningCourseById(id),
      );
      return AdminCourse.fromJson(response.data as Map<String, dynamic>);
    } catch (e) {
      throw AdminFailure('Erreur lors du chargement du cours : $e');
    }
  }

  @override
  Future<void> deleteCourse(String id) async {
    try {
      await _apiClient.delete(ApiEndpoints.adminElearningCourseById(id));
    } catch (e) {
      throw AdminFailure('Erreur lors de la suppression du cours : $e');
    }
  }

  @override
  Future<List<SchoolWithCourses>> getSchoolsWithCourses({
    String? search,
    int page = 1,
    int perPage = 50,
  }) async {
    try {
      final response = await _apiClient.get<Map<String, dynamic>>(
        ApiEndpoints.adminElearningSchools,
        queryParameters: {
          if (search != null && search.isNotEmpty) 'search': search,
          'page': page,
          'per_page': perPage,
        },
      );
      final data = response.data ?? const {};
      final items = (data['items'] as List?) ?? const [];
      return items
          .map((e) => SchoolWithCourses.fromJson(e as Map<String, dynamic>))
          .toList();
    } catch (e) {
      throw AdminFailure('Erreur lors du chargement des écoles : $e');
    }
  }
}