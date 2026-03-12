import 'package:dio/dio.dart';
import 'token_storage_interface.dart';

/// Interceptor Dio de base qui ajoute le header Authorization Bearer.
///
/// Les deux apps étendent cette classe :
/// - activ_education_app : ajoute le refresh proactif + retry sur 401
/// - admin_dashboard     : version simplifiée sans retry
///
/// Routes publiques communes aux deux apps (pas de token ajouté) :
/// - /auth/login, /auth/register, /auth/refresh
/// - /health
class AuthInterceptorBase extends Interceptor {
  final ITokenStorage tokenStorage;

  /// Routes publiques qui ne nécessitent pas de token d'authentification.
  final List<String> publicRoutes;

  static const List<String> defaultPublicRoutes = [
    '/auth/login',
    '/auth/register',
    '/auth/refresh',
    '/auth/forgot-password',
    '/auth/reset-password',
    '/admin/auth/login',
    '/health',
  ];

  AuthInterceptorBase(
    this.tokenStorage, {
    List<String>? additionalPublicRoutes,
  }) : publicRoutes = [
          ...defaultPublicRoutes,
          ...(additionalPublicRoutes ?? []),
        ];

  @override
  Future<void> onRequest(
    RequestOptions options,
    RequestInterceptorHandler handler,
  ) async {
    if (_isPublicRoute(options.path)) {
      handler.next(options);
      return;
    }

    final token = await tokenStorage.getAccessToken();
    if (token != null && token.isNotEmpty) {
      options.headers['Authorization'] = 'Bearer $token';
    }

    handler.next(options);
  }

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) {
    if (err.response?.statusCode == 401) {
      onUnauthorized(err);
    }
    handler.next(err);
  }

  /// Appelé quand le serveur retourne 401. Surcharger pour ajouter
  /// une logique de refresh/retry.
  void onUnauthorized(DioException err) {}

  bool _isPublicRoute(String path) {
    return publicRoutes.any((route) => path.contains(route));
  }
}
