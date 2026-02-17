import 'package:dio/dio.dart';
import 'package:injectable/injectable.dart';
import '../../../../core/constants/api_endpoints.dart';
import '../models/user_model.dart';

/// Data source pour les operations d'authentification distantes.
abstract class AuthRemoteDataSource {
  Future<AuthResultModel> login(String email, String password);
  Future<AuthResultModel> register({
    required String email,
    required String password,
    required String firstName,
    required String lastName,
    String? phoneNumber,
  });
  Future<void> logout();
  Future<AuthTokensModel> refreshTokens(String refreshToken);
  Future<void> forgotPassword(String email);
  Future<void> resetPassword(String token, String newPassword);
  Future<void> changePassword(String currentPassword, String newPassword);
  Future<UserProfileModel> getCurrentUserProfile();
  Future<UserProfileModel> updateProfile(Map<String, dynamic> data);
}

@LazySingleton(as: AuthRemoteDataSource)
class AuthRemoteDataSourceImpl implements AuthRemoteDataSource {
  final Dio _dio;

  AuthRemoteDataSourceImpl(@Named('apiClient') this._dio);

  @override
  Future<AuthResultModel> login(String email, String password) async {
    try {
      final response = await _dio.post(
        ApiEndpoints.login,
        data: {
          'email': email,
          'password': password,
        },
      );
      return AuthResultModel.fromJson(response.data);
    } on DioException catch (e) {
      throw _handleDioError(e);
    }
  }

  @override
  Future<AuthResultModel> register({
    required String email,
    required String password,
    required String firstName,
    required String lastName,
    String? phoneNumber,
  }) async {
    try {
      final response = await _dio.post(
        ApiEndpoints.register,
        data: {
          'email': email,
          'password': password,
          'first_name': firstName,
          'last_name': lastName,
          if (phoneNumber != null) 'phone_number': phoneNumber,
        },
      );
      return AuthResultModel.fromJson(response.data);
    } on DioException catch (e) {
      throw _handleDioError(e);
    }
  }

  @override
  Future<void> logout() async {
    try {
      await _dio.post(ApiEndpoints.logout);
    } on DioException catch (e) {
      throw _handleDioError(e);
    }
  }

  @override
  Future<AuthTokensModel> refreshTokens(String refreshToken) async {
    try {
      final response = await _dio.post(
        ApiEndpoints.refreshToken,
        data: {'refresh_token': refreshToken},
      );
      return AuthTokensModel.fromJson(response.data);
    } on DioException catch (e) {
      throw _handleDioError(e);
    }
  }

  @override
  Future<void> forgotPassword(String email) async {
    try {
      await _dio.post(
        ApiEndpoints.forgotPassword,
        data: {'email': email},
      );
    } on DioException catch (e) {
      throw _handleDioError(e);
    }
  }

  @override
  Future<void> resetPassword(String token, String newPassword) async {
    try {
      await _dio.post(
        ApiEndpoints.resetPassword,
        data: {
          'token': token,
          'new_password': newPassword,
        },
      );
    } on DioException catch (e) {
      throw _handleDioError(e);
    }
  }

  @override
  Future<void> changePassword(
    String currentPassword,
    String newPassword,
  ) async {
    try {
      await _dio.post(
        '${ApiEndpoints.auth}/change-password',
        data: {
          'current_password': currentPassword,
          'new_password': newPassword,
        },
      );
    } on DioException catch (e) {
      throw _handleDioError(e);
    }
  }

  @override
  Future<UserProfileModel> getCurrentUserProfile() async {
    try {
      final response = await _dio.get('${ApiEndpoints.auth}/me');
      return UserProfileModel.fromJson(response.data);
    } on DioException catch (e) {
      throw _handleDioError(e);
    }
  }

  @override
  Future<UserProfileModel> updateProfile(Map<String, dynamic> data) async {
    try {
      final response = await _dio.patch(
        '${ApiEndpoints.auth}/me',
        data: data,
      );
      return UserProfileModel.fromJson(response.data);
    } on DioException catch (e) {
      throw _handleDioError(e);
    }
  }

  Exception _handleDioError(DioException e) {
    if (e.response != null) {
      final statusCode = e.response!.statusCode;
      final data = e.response!.data;

      String message = 'Erreur serveur';
      if (data is Map && data['message'] != null) {
        message = data['message'];
      } else if (data is Map && data['detail'] != null) {
        if (data['detail'] is Map) {
          message = data['detail']['message'] ?? message;
        } else {
          message = data['detail'].toString();
        }
      }

      switch (statusCode) {
        case 401:
          return AuthException(AuthExceptionType.unauthorized, message);
        case 403:
          return AuthException(AuthExceptionType.forbidden, message);
        case 404:
          return AuthException(AuthExceptionType.notFound, message);
        case 409:
          return AuthException(AuthExceptionType.conflict, message);
        case 422:
          return AuthException(AuthExceptionType.validation, message);
        default:
          return AuthException(AuthExceptionType.server, message);
      }
    }

    if (e.type == DioExceptionType.connectionTimeout ||
        e.type == DioExceptionType.receiveTimeout ||
        e.type == DioExceptionType.sendTimeout) {
      return AuthException(AuthExceptionType.timeout, 'Connexion timeout');
    }

    if (e.type == DioExceptionType.connectionError) {
      return AuthException(AuthExceptionType.network, 'Erreur de connexion');
    }

    return AuthException(AuthExceptionType.unknown, e.message ?? 'Erreur inconnue');
  }
}

enum AuthExceptionType {
  unauthorized,
  forbidden,
  notFound,
  conflict,
  validation,
  server,
  network,
  timeout,
  unknown,
}

class AuthException implements Exception {
  final AuthExceptionType type;
  final String message;

  AuthException(this.type, this.message);

  @override
  String toString() => 'AuthException($type): $message';
}
