import '../entities/achievement.dart';
import '../repositories/gamification_repository.dart';

class GetAchievementsUseCase {
  final GamificationRepository _repository;

  GetAchievementsUseCase(this._repository);

  Future<List<Achievement>> call() => _repository.getAchievements();
}

class GetChallengesUseCase {
  final GamificationRepository _repository;

  GetChallengesUseCase(this._repository);

  Future<List<AdminChallenge>> call() => _repository.getChallenges();
}
