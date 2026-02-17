import 'package:dartz/dartz.dart';
import 'package:injectable/injectable.dart';
import '../repositories/auth_repository.dart';

/// Use case pour la deconnexion.
@injectable
class LogoutUseCase {
  final AuthRepository _repository;

  LogoutUseCase(this._repository);

  /// Execute la deconnexion.
  Future<Either<AuthFailure, void>> call() {
    return _repository.logout();
  }
}
