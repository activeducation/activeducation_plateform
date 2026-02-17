import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../core/di/injection_container.dart';
import '../core/auth/token_storage.dart';
import '../shared/layouts/admin_shell_layout.dart';
import '../features/auth/presentation/login_page.dart';
import '../features/dashboard/presentation/dashboard_page.dart';
import '../features/users/presentation/users_list_page.dart';
import '../features/users/presentation/user_detail_page.dart';
import '../features/schools/presentation/schools_list_page.dart';
import '../features/schools/presentation/school_form_page.dart';
import '../features/careers/presentation/careers_list_page.dart';
import '../features/careers/presentation/career_form_page.dart';
import '../features/careers/presentation/sectors_page.dart';
import '../features/orientation_tests/presentation/tests_list_page.dart';
import '../features/orientation_tests/presentation/test_editor_page.dart';
import '../features/gamification/presentation/achievements_page.dart';
import '../features/gamification/presentation/challenges_page.dart';
import '../features/mentors/presentation/mentors_list_page.dart';
import '../features/settings/presentation/settings_page.dart';
import '../features/settings/presentation/announcements_page.dart';
import '../features/settings/presentation/audit_log_page.dart';

final _rootNavigatorKey = GlobalKey<NavigatorState>();
final _shellNavigatorKey = GlobalKey<NavigatorState>();

GoRouter createAdminRouter() {
  return GoRouter(
    navigatorKey: _rootNavigatorKey,
    initialLocation: '/dashboard',
    redirect: (context, state) {
      final tokenStorage = getIt<TokenStorage>();
      final isLoggedIn = tokenStorage.isLoggedIn;
      final isLoginRoute = state.matchedLocation == '/login';

      if (!isLoggedIn && !isLoginRoute) return '/login';
      if (isLoggedIn && isLoginRoute) return '/dashboard';
      return null;
    },
    routes: [
      GoRoute(
        path: '/login',
        builder: (context, state) => const LoginPage(),
      ),
      ShellRoute(
        navigatorKey: _shellNavigatorKey,
        builder: (context, state, child) => AdminShellLayout(child: child),
        routes: [
          GoRoute(
            path: '/dashboard',
            builder: (context, state) => const DashboardPage(),
          ),
          GoRoute(
            path: '/users',
            builder: (context, state) => const UsersListPage(),
          ),
          GoRoute(
            path: '/users/:id',
            builder: (context, state) =>
                UserDetailPage(userId: state.pathParameters['id']!),
          ),
          GoRoute(
            path: '/schools',
            builder: (context, state) => const SchoolsListPage(),
          ),
          GoRoute(
            path: '/schools/new',
            builder: (context, state) => const SchoolFormPage(),
          ),
          GoRoute(
            path: '/schools/:id/edit',
            builder: (context, state) =>
                SchoolFormPage(schoolId: state.pathParameters['id']),
          ),
          GoRoute(
            path: '/careers',
            builder: (context, state) => const CareersListPage(),
          ),
          GoRoute(
            path: '/careers/sectors',
            builder: (context, state) => const SectorsPage(),
          ),
          GoRoute(
            path: '/careers/new',
            builder: (context, state) => const CareerFormPage(),
          ),
          GoRoute(
            path: '/careers/:id/edit',
            builder: (context, state) =>
                CareerFormPage(careerId: state.pathParameters['id']),
          ),
          GoRoute(
            path: '/tests',
            builder: (context, state) => const TestsListPage(),
          ),
          GoRoute(
            path: '/tests/new',
            builder: (context, state) => const TestEditorPage(),
          ),
          GoRoute(
            path: '/tests/:id/edit',
            builder: (context, state) =>
                TestEditorPage(testId: state.pathParameters['id']),
          ),
          GoRoute(
            path: '/gamification/achievements',
            builder: (context, state) => const AchievementsPage(),
          ),
          GoRoute(
            path: '/gamification/challenges',
            builder: (context, state) => const ChallengesPage(),
          ),
          GoRoute(
            path: '/mentors',
            builder: (context, state) => const MentorsListPage(),
          ),
          GoRoute(
            path: '/settings',
            builder: (context, state) => const SettingsPage(),
          ),
          GoRoute(
            path: '/announcements',
            builder: (context, state) => const AnnouncementsPage(),
          ),
          GoRoute(
            path: '/audit-log',
            builder: (context, state) => const AuditLogPage(),
          ),
        ],
      ),
    ],
  );
}
