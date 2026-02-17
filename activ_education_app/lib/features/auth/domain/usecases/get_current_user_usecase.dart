import 'package:dartz/dartz.dart';
import 'package:injectable/injectable.dart';
import '../entities/user.dart';
import '../repositories/auth_repository.dart';

/// Use case pour recuperer l'utilisateur courant.
@injectable
class GetCurrentUserUseCase {
  final AuthRepository _repository;

  GetCurrentUserUseCase(this._repository);

  /// Recupere le profil de l'utilisateur courant.
  Future<Either<AuthFailure, UserProfile>> call() {
    return _repository.getCurrentUserProfile();
  }

  /// Verifie si l'utilisateur est authentifie.
  Future<bool> isAuthenticated() {
    return _repository.isAuthenticated();
  }

  /// Recupere l'utilisateur depuis le cache.
  Future<User?> getCachedUser() {
    return _repository.getCachedUser();
  }
}
