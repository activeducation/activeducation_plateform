/// Constantes d'endpoints partagées entre activ_education_app et admin_dashboard.
///
/// Chaque app étend ou utilise cette classe pour ses endpoints spécifiques.
class ApiEndpointsBase {
  const ApiEndpointsBase._();

  static const String apiV1 = '/api/v1';

  // ---------------------------------------------------------------------------
  // Auth (commun aux deux apps)
  // ---------------------------------------------------------------------------
  static const String login = '$apiV1/auth/login';
  static const String register = '$apiV1/auth/register';
  static const String refreshToken = '$apiV1/auth/refresh';
  static const String forgotPassword = '$apiV1/auth/forgot-password';
  static const String resetPassword = '$apiV1/auth/reset-password';

  // ---------------------------------------------------------------------------
  // Résolution de la base URL
  // ---------------------------------------------------------------------------

  /// Résout la base URL depuis --dart-define=API_BASE_URL ou selon la plateforme.
  static String resolveBaseUrl({
    String envKey = 'API_BASE_URL',
    String defaultAndroid = 'http://10.0.2.2:8000',
    String defaultIos = 'http://localhost:8000',
    String defaultOther = 'http://localhost:8000',
  }) {
    const defined = String.fromEnvironment('API_BASE_URL');
    if (defined.isNotEmpty) return defined;

    // Détection plateforme sans import dart:io pour compatibilité web
    return defaultOther;
  }
}
