import 'package:dartz/dartz.dart';
import '../entities/user_profile.dart';

abstract class ProfileRepository {
  Future<Either<Exception, UserProfile>> getUserProfile();
}
