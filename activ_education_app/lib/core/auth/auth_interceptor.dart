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

  // Lock pour eviter les rafraichissements multiples
  bool _isRefreshing = false;
  final List<ErrorInterceptorHandler> _pendingRequests = [];

  // Routes qui ne necessitent pas d'authentification
  static const List<String> _publicRoutes = [
    '/auth/login',
    '/auth/register',
    '/auth/refresh',
    '/auth/forgot-password',
    '/auth/reset-password',
    '/health',
    '/orientation/mobile/',
  ];

  AuthInterceptor(
    this._tokenStorage,
    @Named('refreshClient') this._refreshDio,
  );

  @override
  Future<void> onRequest(
    RequestOptions options,
    RequestInterceptorHandler handler,
  ) async {
    // Skip auth for public routes
    if (_isPublicRoute(options.path)) {
      return handler.next(options);
    }

    // Proactive token refresh: check expiry BEFORE sending the request
    final isExpired = await _tokenStorage.isTokenExpired();
    if (isExpired) {
      debugPrint('[AuthInterceptor] Token expired, proactively refreshing...');
      final refreshed = await _handleTokenRefresh();
      if (!refreshed) {
        debugPrint('[AuthInterceptor] Proactive refresh failed — proceeding without token');
      }
    }

    // Add auth header
    final accessToken = await _tokenStorage.getAccessToken();
    if (accessToken != null) {
      options.headers['Authorization'] = 'Bearer $accessToken';
    } else {
      debugPrint('[AuthInterceptor] No access token available for ${options.path}');
    }

    return handler.next(options);
  }

  @override
  Future<void> onError(
    DioException err,
    ErrorInterceptorHandler handler,
  ) async {
    // Handle 401 Unauthorized
    if (err.response?.statusCode == 401 && !_isPublicRoute(err.requestOptions.path)) {
      // Try to refresh token
      final refreshed = await _handleTokenRefresh();

      if (refreshed) {
        // Retry the original request with new token
        try {
          final response = await _retryRequest(err.requestOptions);
          return handler.resolve(response);
        } catch (retryError) {
          debugPrint('[AuthInterceptor] Retry failed: $retryError');
        }
      }
    }

    return handler.next(err);
  }

  /// Verifie si la route est publique (pas d'auth requise).
  bool _isPublicRoute(String path) {
    return _publicRoutes.any((route) => path.contains(route));
  }

  /// Gere le rafraichissement du token.
  Future<bool> _handleTokenRefresh() async {
    // Eviter les rafraichissements multiples simultanes
    if (_isRefreshing) {
      debugPrint('[AuthInterceptor] Token refresh already in progress');
      return false;
    }

    _isRefreshing = true;

    try {
      final refreshToken = await _tokenStorage.getRefreshToken();
      if (refreshToken == null) {
        debugPrint('[AuthInterceptor] No refresh token available');
        await _tokenStorage.clearTokens();
        return false;
      }

      debugPrint('[AuthInterceptor] Refreshing access token...');

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

        await _tokenStorage.updateAccessToken(newAccessToken, expiresAt: expiresAt);

        // Si un nouveau refresh token est fourni, le sauvegarder
        if (data['refresh_token'] != null) {
          await _tokenStorage.saveTokens(
            accessToken: newAccessToken,
            refreshToken: data['refresh_token'] as String,
            expiresAt: expiresAt,
          );
        }

        debugPrint('[AuthInterceptor] Token refreshed successfully');
        return true;
      }
    } on DioException catch (e) {
      debugPrint('[AuthInterceptor] Token refresh failed: ${e.message}');

      // Si le refresh echoue avec 401, les tokens sont invalides
      if (e.response?.statusCode == 401) {
        await _tokenStorage.clearTokens();
      }
    } catch (e) {
      debugPrint('[AuthInterceptor] Token refresh error: $e');
    } finally {
      _isRefreshing = false;
    }

    return false;
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
    return Dio(BaseOptions(
      baseUrl: baseUrl,
      connectTimeout: const Duration(seconds: 10),
      receiveTimeout: const Duration(seconds: 10),
    ));
  }
}
