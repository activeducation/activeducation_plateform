import '../../../../core/error/failures.dart';
import '../../../../core/network/api_client.dart';
import '../../../../core/constants/api_endpoints.dart';
import '../../domain/entities/admin_career.dart';
import '../../domain/repositories/careers_repository.dart';
import '../models/admin_career_model.dart';

class CareersRepositoryImpl implements CareersRepository {
  final ApiClient _apiClient;

  CareersRepositoryImpl(this._apiClient);

  @override
  Future<PaginatedCareers> getCareers({
    int page = 1,
    int perPage = 20,
    String? search,
    String? sector,
  }) async {
    try {
      final params = <String, dynamic>{
        'page': page,
        'per_page': perPage,
        if (search != null && search.isNotEmpty) 'search': search,
        if (sector != null) 'sector': sector,
      };
      final response = await _apiClient.get<Map<String, dynamic>>(
        ApiEndpoints.adminCareers,
        queryParameters: params,
      );
      return PaginatedCareersModel.fromJson(
        response.data as Map<String, dynamic>,
        page,
        perPage,
      );
    } catch (e) {
      throw AdminFailure('Erreur lors du chargement des métiers : $e');
    }
  }

  @override
  Future<AdminCareer> getCareerById(String id) async {
    try {
      final response = await _apiClient.get<Map<String, dynamic>>(
        ApiEndpoints.adminCareerById(id),
      );
      return AdminCareerModel.fromJson(response.data as Map<String, dynamic>);
    } catch (e) {
      throw AdminFailure('Erreur lors du chargement du métier : $e');
    }
  }

  @override
  Future<AdminCareer> createCareer(Map<String, dynamic> data) async {
    try {
      final response = await _apiClient.post<Map<String, dynamic>>(
        ApiEndpoints.adminCareers,
        data: data,
      );
      return AdminCareerModel.fromJson(response.data as Map<String, dynamic>);
    } catch (e) {
      throw AdminFailure('Erreur lors de la création du métier : $e');
    }
  }

  @override
  Future<AdminCareer> updateCareer(String id, Map<String, dynamic> data) async {
    try {
      final response = await _apiClient.put<Map<String, dynamic>>(
        ApiEndpoints.adminCareerById(id),
        data: data,
      );
      return AdminCareerModel.fromJson(response.data as Map<String, dynamic>);
    } catch (e) {
      throw AdminFailure('Erreur lors de la mise à jour du métier : $e');
    }
  }

  @override
  Future<void> deleteCareer(String id) async {
    try {
      await _apiClient.delete<void>(ApiEndpoints.adminCareerById(id));
    } catch (e) {
      throw AdminFailure('Erreur lors de la suppression du métier : $e');
    }
  }

  @override
  Future<List<String>> getSectors() async {
    try {
      final response = await _apiClient.get<Map<String, dynamic>>(
        ApiEndpoints.adminSectors,
      );
      final data = response.data as Map<String, dynamic>;
      return (data['items'] as List<dynamic>? ?? [])
          .map((e) => (e as Map<String, dynamic>)['name'] as String)
          .toList();
    } catch (e) {
      throw AdminFailure('Erreur lors du chargement des secteurs : $e');
    }
  }
}
