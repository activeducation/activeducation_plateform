import '../../../../core/error/failures.dart';
import '../../../../core/network/api_client.dart';
import '../../../../core/constants/api_endpoints.dart';
import '../../domain/entities/admin_school.dart';
import '../../domain/repositories/schools_repository.dart';
import '../models/admin_school_model.dart';

class SchoolsRepositoryImpl implements SchoolsRepository {
  final ApiClient _apiClient;

  SchoolsRepositoryImpl(this._apiClient);

  @override
  Future<PaginatedSchools> getSchools({
    int page = 1,
    int perPage = 20,
    String? search,
    bool? verified,
  }) async {
    try {
      final params = <String, dynamic>{
        'page': page,
        'per_page': perPage,
        if (search?.isNotEmpty == true) 'search': search,
        'verified': verified,
      };
      final response = await _apiClient.get<Map<String, dynamic>>(
        ApiEndpoints.adminSchools,
        queryParameters: params,
      );
      return PaginatedSchoolsModel.fromJson(
        response.data as Map<String, dynamic>,
        page,
        perPage,
      );
    } catch (e) {
      throw AdminFailure('Erreur lors du chargement des écoles : $e');
    }
  }

  @override
  Future<AdminSchool> getSchoolById(String id) async {
    try {
      final response = await _apiClient.get<Map<String, dynamic>>(
        ApiEndpoints.adminSchoolById(id),
      );
      return AdminSchoolModel.fromJson(response.data as Map<String, dynamic>);
    } catch (e) {
      throw AdminFailure('Erreur lors du chargement de l\'école : $e');
    }
  }

  @override
  Future<AdminSchool> createSchool(Map<String, dynamic> data) async {
    try {
      final response = await _apiClient.post<Map<String, dynamic>>(
        ApiEndpoints.adminSchools,
        data: data,
      );
      return AdminSchoolModel.fromJson(response.data as Map<String, dynamic>);
    } catch (e) {
      throw AdminFailure('Erreur lors de la création de l\'école : $e');
    }
  }

  @override
  Future<AdminSchool> updateSchool(String id, Map<String, dynamic> data) async {
    try {
      final response = await _apiClient.put<Map<String, dynamic>>(
        ApiEndpoints.adminSchoolById(id),
        data: data,
      );
      return AdminSchoolModel.fromJson(response.data as Map<String, dynamic>);
    } catch (e) {
      throw AdminFailure('Erreur lors de la mise à jour de l\'école : $e');
    }
  }

  @override
  Future<void> verifySchool(String id) async {
    try {
      await _apiClient.patch<void>(ApiEndpoints.adminSchoolVerify(id));
    } catch (e) {
      throw AdminFailure('Erreur lors de la vérification de l\'école : $e');
    }
  }

  @override
  Future<void> toggleSchoolActive(String id) async {
    try {
      await _apiClient.patch<void>(ApiEndpoints.adminSchoolToggleActive(id));
    } catch (e) {
      throw AdminFailure('Erreur lors du changement d\'état de l\'école : $e');
    }
  }

  @override
  Future<void> deleteSchool(String id) async {
    try {
      await _apiClient.delete<void>(ApiEndpoints.adminSchoolById(id));
    } catch (e) {
      throw AdminFailure('Erreur lors de la suppression de l\'école : $e');
    }
  }
}
