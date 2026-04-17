import 'package:equatable/equatable.dart';

/// Représente une erreur dans le domaine admin.
class AdminFailure extends Equatable implements Exception {
  final String message;
  final int? statusCode;

  const AdminFailure(this.message, {this.statusCode});

  @override
  String toString() => 'AdminFailure($message)';

  @override
  List<Object?> get props => [message, statusCode];
}
