import '../../../../core/error/failures.dart';
import '../../../../core/network/api_client.dart';
import '../../../../core/constants/api_endpoints.dart';
import '../../domain/repositories/dashboard_repository.dart';

class DashboardRepositoryImpl implements DashboardRepository {
  final ApiClient _apiClient;

  DashboardRepositoryImpl(this._apiClient);

  @override
  Future<Map<String, dynamic>> getDashboardStats() async {
    try {
      final response = await _apiClient.get<Map<String, dynamic>>(
        ApiEndpoints.dashboardStats,
      );
      return response.data as Map<String, dynamic>;
    } catch (e) {
      throw AdminFailure('Erreur lors du chargement des statistiques : $e');
    }
  }
}
