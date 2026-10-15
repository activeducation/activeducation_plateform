import 'package:dio/dio.dart';

import '../../../../core/constants/api_endpoints.dart';
import '../models/orientation_profile_model.dart';
import '../models/recommendation_model.dart';

class OrientationMatchException implements Exception {
  final String message;
  final int? statusCode;
  const OrientationMatchException(this.message, {this.statusCode});
  @override
  String toString() => 'OrientationMatchException($statusCode): $message';
}

abstract class OrientationMatchDataSource {
  Future<OrientationProfileModel> getProfile();
  Future<OrientationProfileModel> saveProfile(OrientationProfileModel profile);
  Future<RecommendationsResult> getRecommendations({int limit});
}

class OrientationMatchDataSourceImpl implements OrientationMatchDataSource {
  final Dio _dio;
  const OrientationMatchDataSourceImpl(this._dio);

  @override
  Future<OrientationProfileModel> getProfile() async {
    try {
      final resp = await _dio.get(ApiEndpoints.orientationProfile);
      final data = resp.data;
      final profile = data is Map<String, dynamic> ? data['profile'] : null;
      if (profile is Map<String, dynamic>) {
        return OrientationProfileModel.fromJson(profile);
      }
      return OrientationProfileModel.empty();
    } on DioException catch (e) {
      throw _mapError(e);
    }
  }

  @override
  Future<OrientationProfileModel> saveProfile(
    OrientationProfileModel profile,
  ) async {
    try {
      final resp = await _dio.put(
        ApiEndpoints.orientationProfile,
        data: profile.toJson(),
      );
      final data = resp.data;
      final saved = data is Map<String, dynamic> ? data['profile'] : null;
      if (saved is Map<String, dynamic>) {
        return OrientationProfileModel.fromJson(saved);
      }
      return profile;
    } on DioException catch (e) {
      throw _mapError(e);
    }
  }

  @override
  Future<RecommendationsResult> getRecommendations({int limit = 10}) async {
    try {
      final resp = await _dio.get(
        ApiEndpoints.orientationMultiFactor,
        queryParameters: {'limit': limit},
      );
      final data = resp.data;
      if (data is! Map<String, dynamic>) {
        throw const OrientationMatchException('Réponse invalide du serveur');
      }
      return RecommendationsResult.fromJson(data);
    } on DioException catch (e) {
      throw _mapError(e);
    }
  }

  OrientationMatchException _mapError(DioException e) {
    final status = e.response?.statusCode;
    final data = e.response?.data;
    String detail = e.message ?? 'Erreur réseau';
    if (data is Map<String, dynamic>) {
      detail = (data['detail'] ?? data['message'] ?? detail).toString();
    }
    return OrientationMatchException(detail, statusCode: status);
  }
}
