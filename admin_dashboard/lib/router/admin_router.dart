import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../core/di/injection_container.dart';
import '../core/auth/token_storage.dart';
import '../core/auth/auth_interceptor.dart';
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
import '../features/gamification/presentation/users_gamification_page.dart';
import '../features/mentors/presentation/mentors_list_page.dart';
import '../features/mentors/presentation/mentor_applications_page.dart';
import '../features/mentors/presentation/mentor_contact_requests_page.dart';
import '../features/settings/presentation/settings_page.dart';
import '../features/settings/presentation/announcements_page.dart';
import '../features/settings/presentation/audit_log_page.dart';
import '../features/elearning/presentation/courses_list_page.dart';
import '../features/elearning/presentation/course_editor_page.dart';
import '../features/opportunities/presentation/opportunities_list_page.dart';
import '../features/opportunities/presentation/opportunity_editor_page.dart';
import '../features/partner/presentation/organizations_list_page.dart';
import '../features/school_portal/presentation/school_login_page.dart';
import '../features/school_portal/presentation/school_shell_layout.dart';
import '../features/school_portal/presentation/school_dashboard_page.dart';
import '../features/school_portal/presentation/school_courses_page.dart';
import '../features/school_portal/presentation/school_course_editor_page.dart';
import '../features/school_portal/presentation/school_profile_page.dart';

final _shellNavigatorKey = GlobalKey<NavigatorState>();
final _schoolShellNavigatorKey = GlobalKey<NavigatorState>();

GoRouter createAdminRouter() {
  return GoRouter(
    navigatorKey: authNavigatorKey,
    initialLocation: '/dashboard',
    redirect: (context, state) {
      final path = state.matchedLocation;
      final tokenStorage = getIt<TokenStorage>();

      if (path.startsWith('/school-portal') && path != '/school-portal/login') {
        if (!tokenStorage.isLoggedIn || !tokenStorage.isSchoolAdmin) {
          return '/school-portal/login';
        }
      } else if (path != '/login' && path != '/school-portal/login') {
        if (!tokenStorage.isLoggedIn) return '/login';
        if (path == '/login') return '/dashboard';
      }

      if (path.startsWith('/school-portal')) return null;

      final superAdminOnlyRoutes = ['/settings', '/audit-log', '/announcements'];
      if (superAdminOnlyRoutes.contains(path) && !tokenStorage.isSuperAdmin) {
        return '/dashboard';
      }

      return null;
    },
    routes: [
      GoRoute(path: '/login', builder: (context, state) => const LoginPage()),
      GoRoute(path: '/school-portal/login', builder: (context, state) => const SchoolLoginPage()),
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
            path: '/gamification/users',
            builder: (context, state) => const UsersGamificationPage(),
          ),
          GoRoute(
            path: '/mentors',
            builder: (context, state) => const MentorsListPage(),
          ),
          GoRoute(
            path: '/mentors/applications',
            builder: (context, state) => const MentorApplicationsPage(),
          ),
          GoRoute(
            path: '/mentors/contact-requests',
            builder: (context, state) => const MentorContactRequestsPage(),
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
          GoRoute(
            path: '/elearning/courses',
            builder: (context, state) => const CoursesListPage(),
          ),
          GoRoute(
            path: '/elearning/courses/new',
            builder: (context, state) => const CourseEditorPage(),
          ),
          GoRoute(
            path: '/elearning/courses/:id/edit',
            builder: (context, state) =>
                CourseEditorPage(courseId: state.pathParameters['id']),
          ),
          GoRoute(
            path: '/opportunities',
            builder: (context, state) => const OpportunitiesListPage(),
          ),
          GoRoute(
            path: '/opportunities/new',
            builder: (context, state) => const OpportunityEditorPage(),
          ),
          GoRoute(
            path: '/opportunities/:id/edit',
            builder: (context, state) =>
                OpportunityEditorPage(opportunityId: state.pathParameters['id']),
          ),
          GoRoute(
            path: '/partner/organizations',
            builder: (context, state) => const OrganizationsListPage(),
          ),
        ],
      ),
      ShellRoute(
        navigatorKey: _schoolShellNavigatorKey,
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
