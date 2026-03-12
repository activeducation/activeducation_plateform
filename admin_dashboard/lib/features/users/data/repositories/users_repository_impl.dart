import '../../../../core/error/failures.dart';
import '../../../../core/network/api_client.dart';
import '../../../../core/constants/api_endpoints.dart';
import '../../domain/entities/admin_user.dart';
import '../../domain/repositories/users_repository.dart';
import '../models/admin_user_model.dart';

class UsersRepositoryImpl implements UsersRepository {
  final ApiClient _apiClient;

  UsersRepositoryImpl(this._apiClient);

  @override
  Future<PaginatedUsers> getUsers({
    int page = 1,
    int perPage = 20,
    String? search,
    String? role,
  }) async {
    try {
      final params = <String, dynamic>{
        'page': page,
        'per_page': perPage,
        if (search != null && search.isNotEmpty) 'search': search,
        if (role != null) 'role': role,
      };
      final response = await _apiClient.get<Map<String, dynamic>>(
        ApiEndpoints.adminUsers,
        queryParameters: params,
      );
      return PaginatedUsersModel.fromJson(
        response.data as Map<String, dynamic>,
        page,
        perPage,
      );
    } catch (e) {
      throw AdminFailure('Erreur lors du chargement des utilisateurs : $e');
    }
  }

  @override
  Future<AdminUser> getUserById(String id) async {
    try {
      final response = await _apiClient.get<Map<String, dynamic>>(
        ApiEndpoints.adminUserById(id),
      );
      return AdminUserModel.fromJson(response.data as Map<String, dynamic>);
    } catch (e) {
      throw AdminFailure('Erreur lors du chargement de l\'utilisateur : $e');
    }
  }

  @override
  Future<void> deactivateUser(String id) async {
    try {
      await _apiClient.patch<void>(ApiEndpoints.adminUserDeactivate(id));
    } catch (e) {
      throw AdminFailure('Erreur lors de la désactivation : $e');
    }
  }

  @override
  Future<void> activateUser(String id) async {
    try {
      await _apiClient.patch<void>(ApiEndpoints.adminUserActivate(id));
    } catch (e) {
      throw AdminFailure('Erreur lors de l\'activation : $e');
    }
  }

  @override
  Future<void> updateUserRole(String id, String role) async {
    try {
      await _apiClient.patch<void>(
        ApiEndpoints.adminUserRole(id),
        data: {'role': role},
      );
    } catch (e) {
      throw AdminFailure('Erreur lors du changement de rôle : $e');
    }
  }
}
