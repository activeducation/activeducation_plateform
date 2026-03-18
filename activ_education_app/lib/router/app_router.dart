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
import '../features/ai_chat/presentation/pages/chat_page.dart';
import '../features/elearning/presentation/pages/elearning_catalog_page.dart';
import '../features/elearning/presentation/pages/course_detail_page.dart';
import '../features/elearning/presentation/pages/lesson_page.dart';
import '../core/constants/app_colors.dart';
import '../core/constants/app_spacing.dart';
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
      GoRoute(
        path: '/',
        builder: (BuildContext context, GoRouterState state) {
          return const SplashPage();
        },
      ),
      GoRoute(
        path: '/login',
        builder: (BuildContext context, GoRouterState state) {
          return const LoginPage();
        },
      ),
      GoRoute(
        path: '/register',
        builder: (BuildContext context, GoRouterState state) {
          return const RegisterPage();
        },
      ),
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
            path: '/elearning',
            pageBuilder: (context, state) =>
                const NoTransitionPage(child: ElearningCatalogPage()),
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
      GoRoute(
        path: '/chat',
        builder: (BuildContext context, GoRouterState state) {
          final args = state.extra as ChatPageArgs? ?? const ChatPageArgs();
          return ChatPage(args: args);
        },
      ),
      GoRoute(
        path: '/elearning/course/:id',
        builder: (BuildContext context, GoRouterState state) {
          return CourseDetailPage(courseId: state.pathParameters['id']!);
        },
      ),
      GoRoute(
        path: '/elearning/lesson/:id',
        builder: (BuildContext context, GoRouterState state) {
          return LessonPage(lessonId: state.pathParameters['id']!);
        },
      ),
    ],
  );
}

// ─── Shell Wrapper ──────────────────────────────────────────────────────────

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
    '/elearning',
    '/schools',
    '/profile',
  ];

  static const double _desktopBreakpoint = 768;

  static const _navItems = [
    _NavItemData(
      icon: Icons.home_outlined,
      activeIcon: Icons.home_rounded,
      label: 'Accueil',
      route: '/home',
    ),
    _NavItemData(
      icon: Icons.school_outlined,
      activeIcon: Icons.school_rounded,
      label: 'Orientation',
      route: '/orientation',
    ),
    _NavItemData(
      icon: Icons.play_lesson_outlined,
      activeIcon: Icons.play_lesson_rounded,
      label: 'Cours',
      route: '/elearning',
    ),
    _NavItemData(
      icon: Icons.business_outlined,
      activeIcon: Icons.business_rounded,
      label: 'Écoles',
      route: '/schools',
    ),
    _NavItemData(
      icon: Icons.person_outline,
      activeIcon: Icons.person_rounded,
      label: 'Profil',
      route: '/profile',
    ),
  ];

  @override
  Widget build(BuildContext context) {
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
            _DarkSidebar(
              currentIndex: _currentIndex,
              navItems: _navItems,
              onTap: (route) => context.go(route),
              onAida: () => context.push('/chat'),
            ),
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
        floatingActionButton: _AidaFab(onTap: () => context.push('/chat')),
      );
    }

    return Scaffold(
      backgroundColor: AppColors.background,
      body: widget.child,
      bottomNavigationBar: _BottomNav(
        currentIndex: _currentIndex,
        navItems: _navItems,
        onTap: (route) => context.go(route),
      ),
      floatingActionButton: _AidaFab(onTap: () => context.push('/chat')),
      floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
    );
  }
}

// ─── Dark Sidebar (Desktop) ─────────────────────────────────────────────────

class _DarkSidebar extends StatelessWidget {
  final int currentIndex;
  final List<_NavItemData> navItems;
  final void Function(String route) onTap;
  final VoidCallback onAida;

  const _DarkSidebar({
    required this.currentIndex,
    required this.navItems,
    required this.onTap,
    required this.onAida,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 252,
      decoration: BoxDecoration(
        color: AppColors.darkBg,
        boxShadow: AppColors.darkNavShadow,
      ),
      child: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Brand ──
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 24, 20, 32),
              child: Row(
                children: [
                  Container(
                    width: 38,
                    height: 38,
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [AppColors.primary, AppColors.primaryLight],
                      ),
                      borderRadius: BorderRadius.circular(11),
                    ),
                    child: const Icon(
                      Icons.school_rounded,
                      color: Colors.white,
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: 11),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'ActivEdu',
                        style: AppTypography.titleMedium.copyWith(
                          color: AppColors.darkTextPrimary,
                          fontWeight: FontWeight.w700,
                          fontSize: 15,
                        ),
                      ),
                      Text(
                        'Orientation · E-Learning',
                        style: AppTypography.labelSmall.copyWith(
                          color: AppColors.darkTextMuted,
                          fontSize: 10,
                          letterSpacing: 0.3,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            // ── Section principale ──
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              child: Text(
                'MENU',
                style: AppTypography.overline.copyWith(
                  color: AppColors.darkTextMuted,
                  fontSize: 10,
                ),
              ),
            ),
            const SizedBox(height: 8),

            // ── Nav items (sans Profil) ──
            ...navItems.take(4).toList().asMap().entries.map((entry) {
              final i = entry.key;
              final item = entry.value;
              return _SidebarItem(
                item: item,
                isActive: currentIndex == i,
                onTap: () => onTap(item.route),
              );
            }),

            const Spacer(),

            // ── AÏDA CTA ──
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              child: _AidaSidebarButton(onTap: onAida),
            ),

            const SizedBox(height: 8),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              child: Container(
                height: 1,
                color: AppColors.darkBorder,
              ),
            ),
            const SizedBox(height: 8),

            // ── Profil ──
            _SidebarItem(
              item: navItems[4],
              isActive: currentIndex == 4,
              onTap: () => onTap(navItems[4].route),
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }
}

class _SidebarItem extends StatefulWidget {
  final _NavItemData item;
  final bool isActive;
  final VoidCallback onTap;

  const _SidebarItem({
    required this.item,
    required this.isActive,
    required this.onTap,
  });

  @override
  State<_SidebarItem> createState() => _SidebarItemState();
}

class _SidebarItemState extends State<_SidebarItem> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 2),
      child: MouseRegion(
        onEnter: (_) => setState(() => _hovered = true),
        onExit: (_) => setState(() => _hovered = false),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          decoration: BoxDecoration(
            color: widget.isActive
                ? AppColors.darkSurface2
                : _hovered
                    ? AppColors.darkSurface
                    : Colors.transparent,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: widget.onTap,
              borderRadius: BorderRadius.circular(12),
              splashColor: AppColors.darkBorder2.withValues(alpha: 0.5),
              highlightColor: Colors.transparent,
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 11,
                ),
                child: Row(
                  children: [
                    AnimatedContainer(
                      duration: const Duration(milliseconds: 180),
                      padding: const EdgeInsets.all(7),
                      decoration: BoxDecoration(
                        color: widget.isActive
                            ? AppColors.primary.withValues(alpha: 0.25)
                            : Colors.transparent,
                        borderRadius: BorderRadius.circular(9),
                      ),
                      child: Icon(
                        widget.isActive
                            ? widget.item.activeIcon
                            : widget.item.icon,
                        color: widget.isActive
                            ? AppColors.darkAccentBlue
                            : AppColors.darkTextSecondary,
                        size: 20,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        widget.item.label,
                        style: AppTypography.navLabel.copyWith(
                          color: widget.isActive
                              ? AppColors.darkTextPrimary
                              : AppColors.darkTextSecondary,
                          fontWeight: widget.isActive
                              ? FontWeight.w600
                              : FontWeight.w400,
                          fontSize: 13.5,
                        ),
                      ),
                    ),
                    if (widget.isActive)
                      Container(
                        width: 3,
                        height: 20,
                        decoration: BoxDecoration(
                          color: AppColors.primary,
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _AidaSidebarButton extends StatelessWidget {
  final VoidCallback onTap;
  const _AidaSidebarButton({required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                AppColors.primary.withValues(alpha: 0.30),
                AppColors.primaryIndigo.withValues(alpha: 0.20),
              ],
            ),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: AppColors.primary.withValues(alpha: 0.35),
            ),
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(7),
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.30),
                  borderRadius: BorderRadius.circular(9),
                ),
                child: const Icon(
                  Icons.smart_toy_rounded,
                  color: Colors.white,
                  size: 18,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'AÏDA',
                      style: AppTypography.titleSmall.copyWith(
                        color: AppColors.darkTextPrimary,
                        fontWeight: FontWeight.w700,
                        fontSize: 13,
                      ),
                    ),
                    Text(
                      'Conseillère IA',
                      style: AppTypography.labelSmall.copyWith(
                        color: AppColors.darkAccentBlue,
                        fontSize: 10,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                width: 8,
                height: 8,
                decoration: const BoxDecoration(
                  color: AppColors.xpBar,
                  shape: BoxShape.circle,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ─── Bottom Navigation (Mobile) ─────────────────────────────────────────────

class _BottomNav extends StatelessWidget {
  final int currentIndex;
  final List<_NavItemData> navItems;
  final void Function(String route) onTap;

  const _BottomNav({
    required this.currentIndex,
    required this.navItems,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.card,
        border: const Border(
          top: BorderSide(color: AppColors.border, width: 1),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.06),
            blurRadius: 16,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: navItems.asMap().entries.map((entry) {
              final i = entry.key;
              final item = entry.value;
              return _MobileNavItem(
                item: item,
                isActive: currentIndex == i,
                onTap: () => onTap(item.route),
              );
            }).toList(),
          ),
        ),
      ),
    );
  }
}

class _MobileNavItem extends StatelessWidget {
  final _NavItemData item;
  final bool isActive;
  final VoidCallback onTap;

  const _MobileNavItem({
    required this.item,
    required this.isActive,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        behavior: HitTestBehavior.opaque,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 4),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                curve: Curves.easeOut,
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 7,
                ),
                decoration: BoxDecoration(
                  color: isActive
                      ? AppColors.primarySurface
                      : Colors.transparent,
                  borderRadius: BorderRadius.circular(24),
                ),
                child: Icon(
                  isActive ? item.activeIcon : item.icon,
                  color: isActive
                      ? AppColors.primaryDark
                      : AppColors.textTertiary,
                  size: 22,
                ),
              ),
              const SizedBox(height: 3),
              Text(
                item.label,
                style: AppTypography.navLabel.copyWith(
                  color: isActive
                      ? AppColors.primaryDark
                      : AppColors.textTertiary,
                  fontWeight:
                      isActive ? FontWeight.w600 : FontWeight.w400,
                  fontSize: 10.5,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ─── AÏDA FAB ───────────────────────────────────────────────────────────────

class _AidaFab extends StatelessWidget {
  final VoidCallback onTap;
  const _AidaFab({required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withValues(alpha: 0.35),
            blurRadius: 20,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: FloatingActionButton(
        heroTag: 'aida_fab',
        onPressed: onTap,
        backgroundColor: AppColors.primary,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(18),
        ),
        child: const Icon(
          Icons.smart_toy_rounded,
          color: Colors.white,
          size: 26,
        ),
      ),
    );
  }
}

// ─── Data model ─────────────────────────────────────────────────────────────

class _NavItemData {
  final IconData icon;
  final IconData activeIcon;
  final String label;
  final String route;

  const _NavItemData({
    required this.icon,
    required this.activeIcon,
    required this.label,
    required this.route,
  });
}
