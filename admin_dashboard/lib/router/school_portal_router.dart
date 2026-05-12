import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../core/di/injection_container.dart';
import '../core/auth/token_storage.dart';
import '../core/auth/auth_interceptor.dart';
import '../features/school_portal/presentation/school_login_page.dart';
import '../features/school_portal/presentation/school_shell_layout.dart';
import '../features/school_portal/presentation/school_dashboard_page.dart';
import '../features/school_portal/presentation/school_courses_page.dart';
import '../features/school_portal/presentation/school_course_editor_page.dart';
import '../features/school_portal/presentation/school_profile_page.dart';

final _shellNavigatorKey = GlobalKey<NavigatorState>();

GoRouter createSchoolPortalRouter() {
  return GoRouter(
    navigatorKey: authNavigatorKey,
    initialLocation: '/school-portal/login',
    redirect: (context, state) {
      final tokenStorage = getIt<TokenStorage>();
      final isLoggedIn = tokenStorage.isLoggedIn && tokenStorage.isSchoolAdmin;
      final isLoginRoute = state.matchedLocation == '/school-portal/login';

      if (!isLoggedIn && !isLoginRoute) return '/school-portal/login';
      if (isLoggedIn && isLoginRoute) return '/school-portal/dashboard';

      return null;
    },
    routes: [
      GoRoute(path: '/school-portal/login', builder: (context, state) => const SchoolLoginPage()),
      ShellRoute(
        navigatorKey: _shellNavigatorKey,
        builder: (context, state, child) => SchoolShellLayout(child: child),
        routes: [
          GoRoute(
            path: '/school-portal/dashboard',
            builder: (context, state) => const SchoolDashboardPage(),
          ),
          GoRoute(
            path: '/school-portal/courses',
            builder: (context, state) => const SchoolCoursesPage(),
          ),
          GoRoute(
            path: '/school-portal/courses/new',
            builder: (context, state) => const SchoolCourseEditorPage(),
          ),
          GoRoute(
            path: '/school-portal/courses/:id/edit',
            builder: (context, state) => SchoolCourseEditorPage(courseId: state.pathParameters['id']),
          ),
          GoRoute(
            path: '/school-portal/profile',
            builder: (context, state) => const SchoolProfilePage(),
          ),
        ],
      ),
    ],
  );
}