import '../entities/admin_user.dart';
import '../repositories/users_repository.dart';

class GetUsersUseCase {
  final UsersRepository _repository;

  GetUsersUseCase(this._repository);

  Future<PaginatedUsers> call({
    int page = 1,
    int perPage = 20,
    String? search,
    String? role,
  }) =>
      _repository.getUsers(
        page: page,
        perPage: perPage,
        search: search,
        role: role,
      );
}
