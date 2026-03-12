import '../../../../core/error/failures.dart';
import '../../../../core/network/api_client.dart';
import '../../../../core/constants/api_endpoints.dart';
import '../../domain/entities/admin_test.dart';
import '../../domain/repositories/tests_repository.dart';
import '../models/admin_test_model.dart';

class TestsRepositoryImpl implements TestsRepository {
  final ApiClient _apiClient;

  TestsRepositoryImpl(this._apiClient);

  @override
  Future<PaginatedTests> getTests({int page = 1, int perPage = 20}) async {
    try {
      final response = await _apiClient.get<Map<String, dynamic>>(
        ApiEndpoints.adminTests,
        queryParameters: {'page': page, 'per_page': perPage},
      );
      return PaginatedTestsModel.fromJson(
        response.data as Map<String, dynamic>,
        page,
        perPage,
      );
    } catch (e) {
      throw AdminFailure('Erreur lors du chargement des tests : $e');
    }
  }

  @override
  Future<AdminTest> getTestById(String id) async {
    try {
      final response = await _apiClient.get<Map<String, dynamic>>(
        ApiEndpoints.adminTestById(id),
      );
      return AdminTestModel.fromJson(response.data as Map<String, dynamic>);
    } catch (e) {
      throw AdminFailure('Erreur lors du chargement du test : $e');
    }
  }

  @override
  Future<AdminTest> createTest(Map<String, dynamic> data) async {
    try {
      final response = await _apiClient.post<Map<String, dynamic>>(
        ApiEndpoints.adminTests,
        data: data,
      );
      return AdminTestModel.fromJson(response.data as Map<String, dynamic>);
    } catch (e) {
      throw AdminFailure('Erreur lors de la création du test : $e');
    }
  }

  @override
  Future<AdminTest> updateTest(String id, Map<String, dynamic> data) async {
    try {
      final response = await _apiClient.put<Map<String, dynamic>>(
        ApiEndpoints.adminTestById(id),
        data: data,
      );
      return AdminTestModel.fromJson(response.data as Map<String, dynamic>);
    } catch (e) {
      throw AdminFailure('Erreur lors de la mise à jour du test : $e');
    }
  }

  @override
  Future<AdminTest> duplicateTest(String id) async {
    try {
      final response = await _apiClient.post<Map<String, dynamic>>(
        ApiEndpoints.adminTestDuplicate(id),
      );
      return AdminTestModel.fromJson(response.data as Map<String, dynamic>);
    } catch (e) {
      throw AdminFailure('Erreur lors de la duplication du test : $e');
    }
  }

  @override
  Future<void> deleteTest(String id) async {
    try {
      await _apiClient.delete<void>(ApiEndpoints.adminTestById(id));
    } catch (e) {
      throw AdminFailure('Erreur lors de la suppression du test : $e');
    }
  }
}
