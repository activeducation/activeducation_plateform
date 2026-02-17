import 'package:flutter/foundation.dart';
import 'package:dio/dio.dart';
import '../constants/api_endpoints.dart';
import '../auth/token_storage.dart';
import '../auth/auth_interceptor.dart';

class ApiClient {
  late final Dio dio;
  final TokenStorage _tokenStorage;

  ApiClient(this._tokenStorage) {
    dio = Dio(
      BaseOptions(
        baseUrl: ApiEndpoints.baseUrl,
        connectTimeout: const Duration(seconds: 15),
        receiveTimeout: const Duration(seconds: 15),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
      ),
    );

    dio.interceptors.add(AuthInterceptor(_tokenStorage));
    dio.interceptors.add(LogInterceptor(
      requestBody: true,
      responseBody: true,
      logPrint: (o) => debugPrint('[API] $o'),
    ));
  }

  Future<Response<T>> get<T>(
    String path, {
    Map<String, dynamic>? queryParameters,
  }) =>
      dio.get<T>(path, queryParameters: queryParameters);

  Future<Response<T>> post<T>(
    String path, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
  }) =>
      dio.post<T>(path, data: data, queryParameters: queryParameters);

  Future<Response<T>> put<T>(
    String path, {
    dynamic data,
  }) =>
      dio.put<T>(path, data: data);

  Future<Response<T>> patch<T>(
    String path, {
    dynamic data,
  }) =>
      dio.patch<T>(path, data: data);

  Future<Response<T>> delete<T>(String path) => dio.delete<T>(path);
}
