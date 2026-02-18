import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../features/auth/presentation/pages/splash_page.dart';
import '../features/auth/presentation/pages/login_page.dart';
import '../features/auth/presentation/pages/register_page.dart';
import '../features/home/presentation/pages/home_page.dart';
import '../features/schools/presentation/pages/school_directory_page.dart';
import '../features/orientation/presentation/pages/test_selection_page.dart';
import '../features/orientation/presentation/pages/test_execution_page.dart';
import '../features/orientation/presentation/pages/results_page.dart';
import '../features/orientation/presentation/pages/career_detail_page.dart';
import '../features/orientation/domain/entities/orientation_test.dart';
import '../features/orientation/domain/entities/test_result.dart';
import '../features/orientation/domain/entities/career.dart';
import '../features/profile/presentation/pages/profile_page.dart';
import '../core/constants/app_colors.dart';
import '../core/constants/app_typography.dart';
import 'auth_guard.dart';

final GlobalKey<NavigatorState> _rootNavigatorKey = GlobalKey<NavigatorState>(
  debugLabel: 'root',
);
final GlobalKey<NavigatorState> _shellNavigatorKey = GlobalKey<NavigatorState>(
  debugLabel: 'shell',
);

class AppRouter {
  static final GoRouter router = GoRouter(
    navigatorKey: _rootNavigatorKey,
    initialLocation: '/',
    debugLogDiagnostics: true,
    redirect: AuthGuard.redirect,
    routes: <RouteBase>[
      // Splash Screen
      GoRoute(
        path: '/',
        builder: (BuildContext context, GoRouterState state) {
          return const SplashPage();
        },
      ),
      // Login
      GoRoute(
        path: '/login',
        builder: (BuildContext context, GoRouterState state) {
          return const LoginPage();
        },
      ),
      // Register
      GoRoute(
        path: '/register',
        builder: (BuildContext context, GoRouterState state) {
          return const RegisterPage();
        },
      ),
      // Main App with Bottom Navigation - 4 tabs
      ShellRoute(
        navigatorKey: _shellNavigatorKey,
        builder: (context, state, child) {
          return _MainShellWrapper(child: child);
        },
        routes: [
          GoRoute(
            path: '/home',
            pageBuilder: (context, state) =>
                const NoTransitionPage(child: HomePage()),
          ),
          GoRoute(
            path: '/orientation',
            pageBuilder: (context, state) =>
                const NoTransitionPage(child: TestSelectionPage()),
          ),
          GoRoute(
            path: '/schools',
            pageBuilder: (context, state) =>
                const NoTransitionPage(child: SchoolDirectoryPage()),
          ),
          GoRoute(
            path: '/profile',
            pageBuilder: (context, state) =>
                const NoTransitionPage(child: ProfilePage()),
          ),
        ],
      ),
      // Orientation Test Flow
      GoRoute(
        path: '/orientation/test',
        builder: (BuildContext context, GoRouterState state) {
          final test = state.extra as OrientationTest;
          return TestExecutionPage(test: test);
        },
      ),
      GoRoute(
        path: '/orientation/results',
        builder: (BuildContext context, GoRouterState state) {
          final result = state.extra as TestResult;
          return ResultsPage(result: result);
        },
      ),
      GoRoute(
        path: '/orientation/career',
        builder: (BuildContext context, GoRouterState state) {
          final career = state.extra as Career;
          return CareerDetailPage(career: career);
        },
      ),
    ],
  );
}

class _MainShellWrapper extends StatefulWidget {
  final Widget child;

  const _MainShellWrapper({required this.child});

  @override
  State<_MainShellWrapper> createState() => _MainShellWrapperState();
}

class _MainShellWrapperState extends State<_MainShellWrapper> {
  int _currentIndex = 0;

  final List<String> _routes = [
    '/home',
    '/orientation',
    '/schools',
    '/profile',
  ];

  static const double _desktopBreakpoint = 768;

  @override
  Widget build(BuildContext context) {
    // Determine current index from route
    final String location = GoRouterState.of(context).uri.toString();
    for (int i = 0; i < _routes.length; i++) {
      if (location.startsWith(_routes[i])) {
        _currentIndex = i;
        break;
      }
    }

    final isDesktop = MediaQuery.sizeOf(context).width >= _desktopBreakpoint;

    if (isDesktop) {
      return Scaffold(
        backgroundColor: AppColors.background,
        body: Row(
          children: [
            _buildSideNav(context),
            Expanded(
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 960),
                  child: widget.child,
                ),
              ),
            ),
          ],
        ),
      );
    }

    return Scaffold(
      backgroundColor: AppColors.background,
      body: widget.child,
      bottomNavigationBar: _buildBottomNav(context),
    );
  }

  Widget _buildSideNav(BuildContext context) {
    return Container(
      width: 240,
      decoration: BoxDecoration(
        color: AppColors.card,
        border: const Border(
          right: BorderSide(color: AppColors.border, width: 1),
        ),
      ),
      child: SafeArea(
        child: Column(
          children: [
            const SizedBox(height: 24),
            // Logo / Brand
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Row(
                children: [
                  ClipRRect(
                    borderRadius: const BorderRadius.all(Radius.circular(10)),
                    child: Image.asset(
                      'assets/images/logo.png',
                      width: 36,
                      height: 36,
                      fit: BoxFit.contain,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Text(
                    'ActivEducation',
                    style: AppTypography.titleMedium.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 32),
            _SideNavItem(
              icon: Icons.home_outlined,
              activeIcon: Icons.home_rounded,
              label: 'Accueil',
              isActive: _currentIndex == 0,
              onTap: () => context.go('/home'),
            ),
            _SideNavItem(
              icon: Icons.school_outlined,
              activeIcon: Icons.school_rounded,
              label: 'Orientation',
              isActive: _currentIndex == 1,
              onTap: () => context.go('/orientation'),
            ),
            _SideNavItem(
              icon: Icons.business_outlined,
              activeIcon: Icons.business_rounded,
              label: '\u00c9coles',
              isActive: _currentIndex == 2,
              onTap: () => context.go('/schools'),
            ),
            const Spacer(),
            const Divider(height: 1),
            _SideNavItem(
              icon: Icons.person_outline,
              activeIcon: Icons.person_rounded,
              label: 'Profil',
              isActive: _currentIndex == 3,
              onTap: () => context.go('/profile'),
            ),
            const SizedBox(height: 12),
          ],
        ),
      ),
    );
  }

  Widget _buildBottomNav(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.card,
        border: const Border(
          top: BorderSide(color: AppColors.border, width: 1),
        ),
      ),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _NavItem(
                icon: Icons.home_outlined,
                activeIcon: Icons.home_rounded,
                label: 'Accueil',
                isActive: _currentIndex == 0,
                onTap: () => context.go('/home'),
              ),
              _NavItem(
                icon: Icons.school_outlined,
                activeIcon: Icons.school_rounded,
                label: 'Orientation',
                isActive: _currentIndex == 1,
                onTap: () => context.go('/orientation'),
              ),
              _NavItem(
                icon: Icons.business_outlined,
                activeIcon: Icons.business_rounded,
                label: '\u00c9coles',
                isActive: _currentIndex == 2,
                onTap: () => context.go('/schools'),
              ),
              _NavItem(
                icon: Icons.person_outline,
                activeIcon: Icons.person_rounded,
                label: 'Profil',
                isActive: _currentIndex == 3,
                onTap: () => context.go('/profile'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _NavItem extends StatelessWidget {
  final IconData icon;
  final IconData activeIcon;
  final String label;
  final bool isActive;
  final VoidCallback onTap;

  const _NavItem({
    required this.icon,
    required this.activeIcon,
    required this.label,
    required this.isActive,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 6),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Active icon with blue pale background circle
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: isActive
                      ? AppColors.primarySurface
                      : Colors.transparent,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  isActive ? activeIcon : icon,
                  color: isActive
                      ? AppColors.primaryDark
                      : AppColors.textTertiary,
                  size: 24,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                label,
                style: AppTypography.labelSmall.copyWith(
                  color: isActive
                      ? AppColors.primaryDark
                      : AppColors.textTertiary,
                  fontWeight: isActive ? FontWeight.w600 : FontWeight.normal,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 2),
              // Orange indicator bar under active tab
              Container(
                width: isActive ? 20 : 0,
                height: 3,
                decoration: BoxDecoration(
                  color: isActive ? AppColors.secondary : Colors.transparent,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SideNavItem extends StatelessWidget {
  final IconData icon;
  final IconData activeIcon;
  final String label;
  final bool isActive;
  final VoidCallback onTap;

  const _SideNavItem({
    required this.icon,
    required this.activeIcon,
    required this.label,
    required this.isActive,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 2),
      child: Material(
        color: isActive ? AppColors.primarySurface : Colors.transparent,
        borderRadius: BorderRadius.circular(12),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(12),
          hoverColor: AppColors.surface,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Row(
              children: [
                Icon(
                  isActive ? activeIcon : icon,
                  color: isActive ? AppColors.primaryDark : AppColors.textSecondary,
                  size: 22,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    label,
                    style: AppTypography.labelLarge.copyWith(
                      color: isActive ? AppColors.primaryDark : AppColors.textSecondary,
                      fontWeight: isActive ? FontWeight.w600 : FontWeight.w500,
                    ),
                  ),
                ),
                if (isActive)
                  Container(
                    width: 4,
                    height: 20,
                    decoration: BoxDecoration(
                      color: AppColors.secondary,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
