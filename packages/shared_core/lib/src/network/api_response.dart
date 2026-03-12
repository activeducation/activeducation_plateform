import 'package:equatable/equatable.dart';

/// Résultat générique d'un appel API.
///
/// Permet d'unifier la gestion des succès et erreurs dans les repositories.
sealed class ApiResult<T> extends Equatable {
  const ApiResult();
}

final class ApiSuccess<T> extends ApiResult<T> {
  final T data;
  const ApiSuccess(this.data);

  @override
  List<Object?> get props => [data];
}

final class ApiError<T> extends ApiResult<T> {
  final String message;
  final int? statusCode;

  const ApiError(this.message, {this.statusCode});

  @override
  List<Object?> get props => [message, statusCode];
}

/// Types d'erreurs API courants.
enum ApiErrorType {
  unauthorized,
  forbidden,
  notFound,
  serverError,
  networkError,
  timeout,
  unknown,
}

/// Convertit un status code HTTP en [ApiErrorType].
ApiErrorType statusCodeToErrorType(int? code) {
  return switch (code) {
    401 => ApiErrorType.unauthorized,
    403 => ApiErrorType.forbidden,
    404 => ApiErrorType.notFound,
    >= 500 => ApiErrorType.serverError,
    _ => ApiErrorType.unknown,
  };
}
