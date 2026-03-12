import '../entities/achievement.dart';

abstract class GamificationRepository {
  Future<List<Achievement>> getAchievements();

  Future<Achievement> createAchievement(Map<String, dynamic> data);

  Future<Achievement> updateAchievement(String id, Map<String, dynamic> data);

  Future<void> deleteAchievement(String id);

  Future<List<AdminChallenge>> getChallenges();

  Future<AdminChallenge> createChallenge(Map<String, dynamic> data);

  Future<AdminChallenge> updateChallenge(String id, Map<String, dynamic> data);

  Future<void> deleteChallenge(String id);
}
