import '../repositories/users_repository.dart';

class DeactivateUserUseCase {
  final UsersRepository _repository;

  DeactivateUserUseCase(this._repository);

  Future<void> call(String userId) => _repository.deactivateUser(userId);
}
