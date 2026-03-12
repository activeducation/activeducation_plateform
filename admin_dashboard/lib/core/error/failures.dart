/// Représente une erreur dans le domaine admin.
class AdminFailure {
  final String message;
  final int? statusCode;

  const AdminFailure(this.message, {this.statusCode});

  @override
  String toString() => 'AdminFailure($message)';
}
