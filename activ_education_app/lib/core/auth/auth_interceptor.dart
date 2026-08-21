import 'dart:async';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:injectable/injectable.dart';

import '../constants/api_endpoints.dart';
import 'token_storage.dart';

/// Intercepteur Dio pour gerer l'authentification automatiquement.
///
/// Fonctionnalites:
/// - Ajoute le token Bearer a toutes les requetes
/// - Rafraichit automatiquement les tokens expires
/// - Gere les erreurs 401 avec retry
@injectable
class AuthInterceptor extends Interceptor {
  final TokenStorage _tokenStorage;
  final Dio _refreshDio;

  /// Refresh en cours, partage entre tous les appelants concurrents.
  ///
  /// Quand plusieurs requetes tombent en meme temps sur un token expire, elles
  /// doivent TOUTES attendre le meme refresh puis repartir avec le nouveau
  /// token. Un simple booleen faisait echouer les appelants concurrents
  /// (return false), ce qui declenchait clearTokens() dans onRequest et
  /// deconnectait l'utilisateur alors que le refresh etait en train de reussir.
  Future<bool>? _refreshInFlight;

  // Routes qui ne necessitent pas d'authentification
  static const List<String> _publicRoutes = [
    '/auth/login',
    '/auth/register',
    '/auth/refresh',
    '/auth/forgot-password',
    '/auth/reset-password',
    '/health',
    '/orientation/mobile/',
    '/announcements',
    '/settings/public',
  ];

  /// Routes a authentification OPTIONNELLE : le backend les sert avec ou sans
  /// token (ex: get_optional_user_id). Si un token valide est present, on
  /// l'attache pour enrichir la reponse (progress_pct, is_enrolled...). Mais si
  /// le token est expire et que le refresh echoue, on procede SANS token au
  /// lieu de bloquer la requete avec un 401 — sinon le catalogue public casse
  /// des que la session expire.
  static const List<String> _optionalAuthRoutes = [
    '/elearning/courses',
    '/elearning/lessons',
    '/mentors',
    '/opportunities',
    '/schools',
    // Soumission d'un test d'orientation : le backend calcule TOUJOURS le
    // resultat (get_current_user_id_optional) et ne reserve a l'utilisateur
    // connecte que la sauvegarde de la session et l'attribution d'XP.
    // Bloquer la requete ici faisait perdre a l'eleve les 60 reponses qu'il
    // venait de saisir, alors que le serveur pouvait parfaitement lui rendre
    // son profil. Mieux vaut un resultat non sauvegarde qu'aucun resultat.
    '/orientation/sessions',
  ];

  AuthInterceptor(this._tokenStorage, @Named('refreshClient') this._refreshDio);

  @override
  Future<void> onRequest(
    RequestOptions options,
    RequestInterceptorHandler handler,
  ) async {
    if (_isPublicRoute(options.path)) {
      return handler.next(options);
    }

    final isOptionalAuth = _isOptionalAuthRoute(options.path);

    final isExpired = await _tokenStorage.isTokenExpired();
    if (isExpired) {
      if (kDebugMode) debugPrint('[AuthInterceptor] Token expired, proactively refreshing...');
      final refreshed = await _handleTokenRefresh();
      if (!refreshed) {
        if (kDebugMode) debugPrint('[AuthInterceptor] Proactive refresh failed — clearing tokens');
        await _tokenStorage.clearTokens();
        // Route a auth optionnelle : on laisse passer SANS token plutot que de
        // casser le contenu public (catalogue, mentors, opportunites, ecoles).
        if (isOptionalAuth) {
          return handler.next(options);
        }
        return handler.reject(
          DioException(
            requestOptions: options,
            type: DioExceptionType.badResponse,
            response: Response(requestOptions: options, statusCode: 401),
            message: 'Session expired',
          ),
        );
      }
    }

    final accessToken = await _tokenStorage.getAccessToken();
    if (accessToken != null) {
      options.headers['Authorization'] = 'Bearer $accessToken';
    } else {
      if (kDebugMode) debugPrint('[AuthInterceptor] No access token available for ${options.path}');
    }

    return handler.next(options);
  }

  @override
  Future<void> onError(
    DioException err,
    ErrorInterceptorHandler handler,
  ) async {
    // Handle 401 Unauthorized
    if (err.response?.statusCode == 401 &&
        !_isPublicRoute(err.requestOptions.path)) {
      // Try to refresh token
      final refreshed = await _handleTokenRefresh();

      if (refreshed) {
        // Retry the original request with new token
        try {
          final response = await _retryRequest(err.requestOptions);
          return handler.resolve(response);
        } catch (retryError) {
          if (kDebugMode) debugPrint('[AuthInterceptor] Retry failed: $retryError');
        }
      } else if (_isOptionalAuthRoute(err.requestOptions.path)) {
        // Le rafraichissement a echoue, mais cette route est servie avec ou
        // sans authentification : on retente SANS jeton plutot que de rendre
        // une erreur. Sans cela, un eleve dont la session expire perd les
        // reponses qu'il vient de saisir alors que le serveur peut lui rendre
        // son resultat.
        try {
          final response = await _retryRequestWithoutAuth(err.requestOptions);
          return handler.resolve(response);
        } catch (anonError) {
          if (kDebugMode) {
            debugPrint('[AuthInterceptor] Retry sans jeton echoue: $anonError');
          }
        }
      }
    }

    return handler.next(err);
  }

  /// Verifie si la route est publique (pas d'auth requise).
  bool _isPublicRoute(String path) {
    return _publicRoutes.any((route) => path.contains(route));
  }

  /// Verifie si la route accepte une auth optionnelle (token attache si valide,
  /// sinon requete envoyee sans token au lieu d'etre bloquee).
  bool _isOptionalAuthRoute(String path) {
    return _optionalAuthRoutes.any((route) => path.contains(route));
  }

  /// Gere le rafraichissement du token, en dedupliquant les appels concurrents.
  ///
  /// Si un refresh est deja en cours, on renvoie SA future : l'appelant attend
  /// le meme resultat au lieu d'echouer. Un seul appel reseau est effectue.
  Future<bool> _handleTokenRefresh() {
    final inFlight = _refreshInFlight;
    if (inFlight != null) {
      if (kDebugMode) debugPrint('[AuthInterceptor] Refresh deja en cours — attente du resultat');
      return inFlight;
    }

    final future = _performTokenRefresh();
    _refreshInFlight = future;
    // Liberer le verrou quoi qu'il arrive (succes, echec ou exception).
    future.whenComplete(() => _refreshInFlight = null);
    return future;
  }

  /// Effectue reellement l'appel de rafraichissement (un seul a la fois).
  Future<bool> _performTokenRefresh() async {
    try {
      final refreshToken = await _tokenStorage.getRefreshToken();
      if (refreshToken == null) {
        if (kDebugMode) debugPrint('[AuthInterceptor] No refresh token available');
        await _tokenStorage.clearTokens();
        return false;
      }

      if (kDebugMode) debugPrint('[AuthInterceptor] Refreshing access token...');

      final response = await _refreshDio.post(
        ApiEndpoints.refreshToken,
        data: {'refresh_token': refreshToken},
      );

      if (response.statusCode == 200) {
        final data = response.data;
        final newAccessToken = data['access_token'] as String;
        final expiresIn = data['expires_in'] as int?;

        DateTime? expiresAt;
        if (expiresIn != null) {
          expiresAt = DateTime.now().add(Duration(seconds: expiresIn));
        }

        await _tokenStorage.updateAccessToken(
          newAccessToken,
          expiresAt: expiresAt,
        );

        // Si un nouveau refresh token est fourni, le sauvegarder
        if (data['refresh_token'] != null) {
          await _tokenStorage.saveTokens(
            accessToken: newAccessToken,
            refreshToken: data['refresh_token'] as String,
            expiresAt: expiresAt,
          );
        }

        if (kDebugMode) debugPrint('[AuthInterceptor] Token refreshed successfully');
        return true;
      }
    } on DioException catch (e) {
      if (kDebugMode) debugPrint('[AuthInterceptor] Token refresh failed: ${e.message}');

      // Si le refresh echoue avec 401, les tokens sont invalides
      if (e.response?.statusCode == 401) {
        await _tokenStorage.clearTokens();
      }
    } catch (e) {
      if (kDebugMode) debugPrint('[AuthInterceptor] Token refresh error: $e');
    }

    return false;
  }

  /// Retente une requete SANS jeton, pour les routes a authentification
  /// optionnelle dont le rafraichissement a echoue.
  Future<Response<dynamic>> _retryRequestWithoutAuth(
    RequestOptions requestOptions,
  ) {
    final headers = Map<String, dynamic>.from(requestOptions.headers)
      ..remove('Authorization');

    return _refreshDio.request<dynamic>(
      requestOptions.path,
      data: requestOptions.data,
      queryParameters: requestOptions.queryParameters,
      options: Options(method: requestOptions.method, headers: headers),
    );
  }

  /// Retente une requete avec le nouveau token.
  Future<Response<dynamic>> _retryRequest(RequestOptions requestOptions) async {
    final accessToken = await _tokenStorage.getAccessToken();

    final options = Options(
      method: requestOptions.method,
      headers: {
        ...requestOptions.headers,
        'Authorization': 'Bearer $accessToken',
      },
    );

    return _refreshDio.request<dynamic>(
      requestOptions.path,
      data: requestOptions.data,
      queryParameters: requestOptions.queryParameters,
      options: options,
    );
  }
}

/// Extension pour creer un Dio configure pour le refresh.
extension AuthDioExtension on Dio {
  /// Cree un client Dio pour les requetes de refresh.
  static Dio createRefreshClient(String baseUrl) {
    return Dio(
      BaseOptions(
        baseUrl: baseUrl,
        connectTimeout: const Duration(seconds: 10),
        receiveTimeout: const Duration(seconds: 10),
      ),
    );
  }
}
