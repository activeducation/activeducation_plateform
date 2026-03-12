import '../entities/admin_user.dart';

abstract class UsersRepository {
  Future<PaginatedUsers> getUsers({
    int page = 1,
    int perPage = 20,
    String? search,
    String? role,
  });

  Future<AdminUser> getUserById(String id);

  Future<void> deactivateUser(String id);

  Future<void> activateUser(String id);

  Future<void> updateUserRole(String id, String role);
}
