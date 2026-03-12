import 'package:dio/dio.dart';

/// Configuration Dio partagée entre les deux apps.
///
/// Fournit les timeouts et headers standards. Chaque app crée son propre
/// Dio en appelant [createDio] et en ajoutant ses interceptors spécifiques.
class ApiBaseClient {
  static const Duration connectTimeout = Duration(seconds: 15);
  static const Duration receiveTimeout = Duration(seconds: 30);

  /// Crée une instance Dio préconfigurée avec les defaults standards.
  static Dio createDio(String baseUrl) {
    return Dio(
      BaseOptions(
        baseUrl: baseUrl,
        connectTimeout: connectTimeout,
        receiveTimeout: receiveTimeout,
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
      ),
    );
  }

  /// Crée un Dio secondaire pour le refresh de token (sans interceptor d'auth
  /// pour éviter les boucles infinies).
  static Dio createRefreshDio(String baseUrl) {
    return Dio(
      BaseOptions(
        baseUrl: baseUrl,
        connectTimeout: connectTimeout,
        receiveTimeout: connectTimeout,
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
      ),
    );
  }
}
