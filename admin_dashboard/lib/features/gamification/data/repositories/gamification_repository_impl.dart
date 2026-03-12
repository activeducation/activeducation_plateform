import '../../../../core/error/failures.dart';
import '../../../../core/network/api_client.dart';
import '../../../../core/constants/api_endpoints.dart';
import '../../domain/entities/achievement.dart';
import '../../domain/repositories/gamification_repository.dart';
import '../models/achievement_model.dart';

class GamificationRepositoryImpl implements GamificationRepository {
  final ApiClient _apiClient;

  GamificationRepositoryImpl(this._apiClient);

  @override
  Future<List<Achievement>> getAchievements() async {
    try {
      final response = await _apiClient.get<Map<String, dynamic>>(
        ApiEndpoints.adminAchievements,
      );
      final data = response.data as Map<String, dynamic>;
      return (data['items'] as List<dynamic>? ?? [])
          .map((e) => AchievementModel.fromJson(e as Map<String, dynamic>))
          .toList();
    } catch (e) {
      throw AdminFailure('Erreur lors du chargement des succès : $e');
    }
  }

  @override
  Future<Achievement> createAchievement(Map<String, dynamic> data) async {
    try {
      final response = await _apiClient.post<Map<String, dynamic>>(
        ApiEndpoints.adminAchievements,
        data: data,
      );
      return AchievementModel.fromJson(response.data as Map<String, dynamic>);
    } catch (e) {
      throw AdminFailure('Erreur lors de la création du succès : $e');
    }
  }

  @override
  Future<Achievement> updateAchievement(
    String id,
    Map<String, dynamic> data,
  ) async {
    try {
      final response = await _apiClient.put<Map<String, dynamic>>(
        ApiEndpoints.adminAchievementById(id),
        data: data,
      );
      return AchievementModel.fromJson(response.data as Map<String, dynamic>);
    } catch (e) {
      throw AdminFailure('Erreur lors de la mise à jour du succès : $e');
    }
  }

  @override
  Future<void> deleteAchievement(String id) async {
    try {
      await _apiClient.delete<void>(ApiEndpoints.adminAchievementById(id));
    } catch (e) {
      throw AdminFailure('Erreur lors de la suppression du succès : $e');
    }
  }

  @override
  Future<List<AdminChallenge>> getChallenges() async {
    try {
      final response = await _apiClient.get<Map<String, dynamic>>(
        ApiEndpoints.adminChallenges,
      );
      final data = response.data as Map<String, dynamic>;
      return (data['items'] as List<dynamic>? ?? [])
          .map((e) => AdminChallengeModel.fromJson(e as Map<String, dynamic>))
          .toList();
    } catch (e) {
      throw AdminFailure('Erreur lors du chargement des défis : $e');
    }
  }

  @override
  Future<AdminChallenge> createChallenge(Map<String, dynamic> data) async {
    try {
      final response = await _apiClient.post<Map<String, dynamic>>(
        ApiEndpoints.adminChallenges,
        data: data,
      );
      return AdminChallengeModel.fromJson(
          response.data as Map<String, dynamic>);
    } catch (e) {
      throw AdminFailure('Erreur lors de la création du défi : $e');
    }
  }

  @override
  Future<AdminChallenge> updateChallenge(
    String id,
    Map<String, dynamic> data,
  ) async {
    try {
      final response = await _apiClient.put<Map<String, dynamic>>(
        ApiEndpoints.adminChallengeById(id),
        data: data,
      );
      return AdminChallengeModel.fromJson(
          response.data as Map<String, dynamic>);
    } catch (e) {
      throw AdminFailure('Erreur lors de la mise à jour du défi : $e');
    }
  }

  @override
  Future<void> deleteChallenge(String id) async {
    try {
      await _apiClient.delete<void>(ApiEndpoints.adminChallengeById(id));
    } catch (e) {
      throw AdminFailure('Erreur lors de la suppression du défi : $e');
    }
  }
}
