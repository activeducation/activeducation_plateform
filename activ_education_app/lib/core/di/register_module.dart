import 'package:dio/dio.dart';
import 'package:injectable/injectable.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../auth/token_storage.dart';
import '../auth/auth_interceptor.dart';
import '../constants/api_endpoints.dart';

@module
abstract class RegisterModule {
  /// SharedPreferences pour le stockage local.
  @preResolve
  Future<SharedPreferences> get prefs => SharedPreferences.getInstance();

  /// Client Dio pour les requetes de refresh (sans intercepteur auth).
  @Named('refreshClient')
  @lazySingleton
  Dio get refreshDio => Dio(BaseOptions(
        baseUrl: ApiEndpoints.baseUrl,
        connectTimeout: const Duration(seconds: 10),
        receiveTimeout: const Duration(seconds: 10),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
      ));

  /// Client Dio principal pour les requetes API.
  @Named('apiClient')
  @lazySingleton
  Dio apiDio(
    TokenStorage tokenStorage,
    @Named('refreshClient') Dio refreshDio,
  ) {
    final dio = Dio(BaseOptions(
      baseUrl: ApiEndpoints.baseUrl,
      connectTimeout: const Duration(seconds: 30),
      receiveTimeout: const Duration(seconds: 30),
      headers: {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
      },
    ));

    // Ajouter l'intercepteur d'authentification
    dio.interceptors.add(AuthInterceptor(tokenStorage, refreshDio));

    // Ajouter un intercepteur de logging en debug
    dio.interceptors.add(LogInterceptor(
      request: true,
      requestHeader: false,
      requestBody: true,
      responseHeader: false,
      responseBody: true,
      error: true,
      logPrint: (object) => print('[Dio] $object'),
    ));

    return dio;
  }
}
