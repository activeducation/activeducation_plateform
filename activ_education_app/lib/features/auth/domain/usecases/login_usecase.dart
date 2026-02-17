import 'package:dartz/dartz.dart';
import 'package:injectable/injectable.dart';
import '../entities/user.dart';
import '../repositories/auth_repository.dart';

/// Use case pour la connexion.
@injectable
class LoginUseCase {
  final AuthRepository _repository;

  LoginUseCase(this._repository);

  /// Execute le login avec les credentials.
  Future<Either<AuthFailure, AuthResult>> call({
    required String email,
    required String password,
  }) {
    return _repository.login(email: email, password: password);
  }
}
