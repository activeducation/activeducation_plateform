import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../core/auth/token_storage.dart';
import '../core/di/injection_container.dart';

/// Rôles autorisés pour les routes partenaires.
const List<String> _partnerAllowedRoles = [
  'partner_admin',
  'admin',
  'super_admin',
];

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
    '/onboarding',
    '/onboarding/profile',
    '/onboarding/interests',
    '/onboarding/goals',
    '/onboarding/complete',
  ];

  /// Routes d'authentification (rediriger vers home si deja connecte).
  static const List<String> authRoutes = [
    '/login',
    '/register',
  ];

  /// Prefixes de routes publiques (toutes les sous-routes sont accessibles).
  /// Seul /profile necessite une authentification.
  static const List<String> publicPrefixes = [
    '/home',
    '/orientation',
    '/elearning',
    '/schools',
    '/chat',
  ];

  /// Verifie si la route est publique.
  static bool isPublicRoute(String location) {
    // Verifier les routes exactes
    if (publicRoutes.any((route) => location == route || location.startsWith('$route?'))) {
      return true;
    }
    // Verifier les prefixes (orientation et sous-routes)
    return publicPrefixes.any((prefix) => location.startsWith(prefix));
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
      if (kDebugMode) debugPrint('[AuthGuard] Error checking auth: $e');
      isAuthenticated = false;
    }

    if (kDebugMode) debugPrint('[AuthGuard] Location: $location, isPublic: $isPublic, isAuth: $isAuth, isAuthenticated: $isAuthenticated');

    // Si non authentifie et route protegee -> login
    if (!isAuthenticated && !isPublic) {
      if (kDebugMode) debugPrint('[AuthGuard] Redirecting to /login');
      return '/login';
    }

    // Si authentifie et sur une route d'auth -> home
    if (isAuthenticated && isAuth) {
      if (kDebugMode) debugPrint('[AuthGuard] Redirecting to /home');
      return '/home';
    }

    // Si sur splash et authentifie -> home
    if (location == '/' && isAuthenticated) {
      return '/home';
    }

    // Si sur splash et non authentifie -> onboarding
    if (location == '/' && !isAuthenticated) {
      return '/onboarding';
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

    if (location == '/' && isAuthenticated == false) {
      return '/onboarding';
    }

    return null;
  }
}

/// Guard de vérification des rôles pour les routes protégées.
class RoleGuard {
  static final TokenStorage _tokenStorage = getIt<TokenStorage>();

  /// Routes nécessitant un rôle spécifique (prefix → rôles autorisés).
  static const Map<String, List<String>> _roleProtectedPrefixes = {
    '/partner': _partnerAllowedRoles,
  };

  /// Vérifie si la route nécessite un rôle spécifique et si l'utilisateur
  /// possède ce rôle. Retourne un chemin de redirection ou null.
  static Future<String?> redirect(
    BuildContext context,
    GoRouterState state,
  ) async {
    final location = state.uri.toString();

    for (final entry in _roleProtectedPrefixes.entries) {
      if (location.startsWith(entry.key)) {
        final role = await _tokenStorage.getUserRole();
        if (role == null || !entry.value.contains(role)) {
          if (kDebugMode) {
            debugPrint('[RoleGuard] Redirecting from $location: role=$role not in ${entry.value}');
          }
          return '/home';
        }
        break;
      }
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
