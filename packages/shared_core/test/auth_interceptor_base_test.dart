import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:dio/dio.dart';
import 'package:shared_core/shared_core.dart';

class MockTokenStorage extends Mock implements ITokenStorage {}

class TestInterceptor extends AuthInterceptorBase {
  bool unauthorizedCalled = false;

  TestInterceptor(super.tokenStorage);

  @override
  void onUnauthorized(DioException err) {
    unauthorizedCalled = true;
  }
}

void main() {
  late MockTokenStorage tokenStorage;
  late TestInterceptor interceptor;

  setUp(() {
    tokenStorage = MockTokenStorage();
    interceptor = TestInterceptor(tokenStorage);
  });

  group('AuthInterceptorBase', () {
    test('ajoute le header Authorization sur les routes protégées', () async {
      when(() => tokenStorage.getAccessToken())
          .thenAnswer((_) async => 'test_token_123');

      final options = RequestOptions(path: '/api/v1/orientation/tests');
      var nextCalled = false;
      RequestOptions? capturedOptions;

      await interceptor.onRequest(
        options,
        _MockRequestHandler((opts) {
          nextCalled = true;
          capturedOptions = opts;
        }),
      );

      expect(nextCalled, isTrue);
      expect(capturedOptions?.headers['Authorization'], 'Bearer test_token_123');
    });

    test('ne ajoute pas de header sur les routes publiques', () async {
      final options = RequestOptions(path: '/api/v1/auth/login');
      var nextCalled = false;
      RequestOptions? capturedOptions;

      await interceptor.onRequest(
        options,
        _MockRequestHandler((opts) {
          nextCalled = true;
          capturedOptions = opts;
        }),
      );

      expect(nextCalled, isTrue);
      expect(capturedOptions?.headers['Authorization'], isNull);
      verifyNever(() => tokenStorage.getAccessToken());
    });

    test('ne ajoute pas de header si token absent', () async {
      when(() => tokenStorage.getAccessToken()).thenAnswer((_) async => null);

      final options = RequestOptions(path: '/api/v1/users/me');
      RequestOptions? capturedOptions;

      await interceptor.onRequest(
        options,
        _MockRequestHandler((opts) => capturedOptions = opts),
      );

      expect(capturedOptions?.headers['Authorization'], isNull);
    });

    test('appelle onUnauthorized sur erreur 401', () {
      final error = DioException(
        requestOptions: RequestOptions(path: '/api/v1/users/me'),
        response: Response(
          requestOptions: RequestOptions(path: '/api/v1/users/me'),
          statusCode: 401,
        ),
        type: DioExceptionType.badResponse,
      );

      interceptor.onError(
        error,
        _MockErrorHandler((_) {}),
      );

      expect(interceptor.unauthorizedCalled, isTrue);
    });
  });
}

// Helpers pour les handlers Dio
class _MockRequestHandler extends RequestInterceptorHandler {
  final void Function(RequestOptions) callback;
  _MockRequestHandler(this.callback);

  @override
  void next(RequestOptions options) => callback(options);
}

class _MockErrorHandler extends ErrorInterceptorHandler {
  final void Function(DioException) callback;
  _MockErrorHandler(this.callback);

  @override
  void next(DioException err) => callback(err);
}
