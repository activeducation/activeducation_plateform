import '../models/gamification_profile.dart';
import '../datasources/gamification_remote_datasource.dart';

abstract class GamificationRepository {
  Future<GamificationProfile> getMyProfile();
  Future<List<LeaderboardEntry>> getLeaderboard({int limit = 10});
}

class GamificationRepositoryImpl implements GamificationRepository {
  final GamificationRemoteDataSource _remoteDataSource;

  GamificationRepositoryImpl(this._remoteDataSource);

  @override
  Future<GamificationProfile> getMyProfile() async {
    return await _remoteDataSource.getMyProfile();
  }

  @override
  Future<List<LeaderboardEntry>> getLeaderboard({int limit = 10}) async {
    return await _remoteDataSource.getLeaderboard(limit: limit);
  }
}