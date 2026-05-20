import 'package:dio/dio.dart';
import 'package:injectable/injectable.dart';
import '../../../../core/constants/api_endpoints.dart';
import '../models/gamification_profile.dart';

@lazySingleton
class GamificationRemoteDataSource {
  final Dio _dio;

  GamificationRemoteDataSource(@Named('apiClient') this._dio);

  Future<GamificationProfile> getMyProfile() async {
    final response = await _dio.get(ApiEndpoints.gamificationProfile);
    return GamificationProfile.fromJson(response.data);
  }

  Future<List<LeaderboardEntry>> getLeaderboard({int limit = 10}) async {
    final response = await _dio.get(
      ApiEndpoints.leaderboard,
      queryParameters: {'limit': limit},
    );
    return (response.data as List)
        .map((e) => LeaderboardEntry.fromJson(e))
        .toList();
  }
}