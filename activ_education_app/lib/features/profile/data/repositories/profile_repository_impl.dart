import 'package:dartz/dartz.dart';
import 'package:injectable/injectable.dart';
import '../../domain/entities/user_profile.dart';
import '../../domain/repositories/profile_repository.dart';

@LazySingleton(as: ProfileRepository)
class ProfileRepositoryImpl implements ProfileRepository {
  @override
  Future<Either<Exception, UserProfile>> getUserProfile() async {
    // Mock Data
    await Future.delayed(const Duration(milliseconds: 500));
    return const Right(UserProfile(
      id: 'mock-user-id',
      fullName: 'Jean Dupont',
      email: 'jean.dupont@example.com',
      level: 5,
      xp: 450,
      currentStreak: 3,
      avatarUrl: null, // Could add a placeholder URL
    ));
  }
}
