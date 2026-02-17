import 'package:dartz/dartz.dart';
import 'package:injectable/injectable.dart';
import '../../domain/entities/user_profile.dart';
import '../../domain/repositories/profile_repository.dart';

@lazySingleton
class GetUserProfile {
  final ProfileRepository _repository;

  GetUserProfile(this._repository);

  Future<Either<Exception, UserProfile>> call() async {
    return _repository.getUserProfile();
  }
}
