import 'package:flutter/widgets.dart';
import 'package:go_router/go_router.dart';
import 'package:dio/dio.dart';
import 'token_storage.dart';

final GlobalKey<NavigatorState> authNavigatorKey = GlobalKey<NavigatorState>();

class AuthInterceptor extends Interceptor {
  final TokenStorage _tokenStorage;

  AuthInterceptor(this._tokenStorage);

  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) {
    final token = _tokenStorage.accessToken;
    if (token != null && token.isNotEmpty) {
      options.headers['Authorization'] = 'Bearer $token';
    }
    handler.next(options);
  }

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) {
    if (err.response?.statusCode == 401) {
      _tokenStorage.clear();
      final context = authNavigatorKey.currentContext;
      if (context != null) {
        context.go('/login');
      }
    }
    handler.next(err);
  }
}
