import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../core/auth/token_storage.dart';
import '../core/di/injection_container.dart';

/// Guard d'authentification pour les routes protegees.
///
/// Utilise avec GoRouter pour rediriger les utilisateurs
/// non authentifies vers la page de connexion.
class AuthGuard {
  static final TokenStorage _tokenStorage = getIt<TokenStorage>();

  /// Routes publiques accessibles sans authentification.
  static const List<String> publicRoutes = [
    '/',           // Splash
    '/login',
    '/register',
    '/forgot-password',
    '/reset-password',
  ];

  /// Routes d'authentification (rediriger vers home si deja connecte).
  static const List<String> authRoutes = [
    '/login',
    '/register',
  ];

  /// Verifie si la route est publique.
  static bool isPublicRoute(String location) {
    return publicRoutes.any((route) => location == route || location.startsWith('$route?'));
  }

  /// Verifie si c'est une route d'authentification.
  static bool isAuthRoute(String location) {
    return authRoutes.any((route) => location == route || location.startsWith('$route?'));
  }

  /// Fonction de redirection pour GoRouter.
  ///
  /// Retourne null si aucune redirection n'est necessaire,
  /// sinon retourne le chemin vers lequel rediriger.
  static Future<String?> redirect(
    BuildContext context,
    GoRouterState state,
  ) async {
    final location = state.uri.toString();
    final isPublic = isPublicRoute(location);
    final isAuth = isAuthRoute(location);

    // Verifier l'etat d'authentification
    bool isAuthenticated;
    try {
      isAuthenticated = await _tokenStorage.hasValidTokens();
    } catch (e) {
      debugPrint('[AuthGuard] Error checking auth: $e');
      isAuthenticated = false;
    }

    debugPrint('[AuthGuard] Location: $location, isPublic: $isPublic, isAuth: $isAuth, isAuthenticated: $isAuthenticated');

    // Si non authentifie et route protegee -> login
    if (!isAuthenticated && !isPublic) {
      debugPrint('[AuthGuard] Redirecting to /login');
      return '/login';
    }

    // Si authentifie et sur une route d'auth -> home
    if (isAuthenticated && isAuth) {
      debugPrint('[AuthGuard] Redirecting to /home');
      return '/home';
    }

    // Si sur splash et authentifie -> home
    if (location == '/' && isAuthenticated) {
      return '/home';
    }

    // Pas de redirection necessaire
    return null;
  }

  /// Version synchrone du guard (pour les cas simples).
  ///
  /// Utilise une valeur en cache si disponible.
  static String? redirectSync(
    BuildContext context,
    GoRouterState state,
    bool? isAuthenticated,
  ) {
    if (isAuthenticated == null) return null;

    final location = state.uri.toString();
    final isPublic = isPublicRoute(location);
    final isAuth = isAuthRoute(location);

    if (!isAuthenticated && !isPublic) {
      return '/login';
    }

    if (isAuthenticated && isAuth) {
      return '/home';
    }

    if (location == '/' && isAuthenticated) {
      return '/home';
    }

    return null;
  }
}

/// Mixin pour ajouter le guard a un StatefulWidget.
mixin AuthGuardMixin<T extends StatefulWidget> on State<T> {
  bool _isCheckingAuth = true;
  bool _isAuthenticated = false;

  @override
  void initState() {
    super.initState();
    _checkAuth();
  }

  Future<void> _checkAuth() async {
    final tokenStorage = getIt<TokenStorage>();
    final hasTokens = await tokenStorage.hasValidTokens();

    if (mounted) {
      setState(() {
        _isAuthenticated = hasTokens;
        _isCheckingAuth = false;
      });

      if (!hasTokens) {
        context.go('/login');
      }
    }
  }

  bool get isCheckingAuth => _isCheckingAuth;
  bool get isAuthenticated => _isAuthenticated;

  Widget buildAuthGuarded({
    required Widget child,
    Widget? loadingWidget,
  }) {
    if (_isCheckingAuth) {
      return loadingWidget ?? const Center(child: CircularProgressIndicator());
    }
    return child;
  }
}
