import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../core/constants/app_colors.dart';
import '../features/auth/presentation/pages/splash_page.dart';
import '../features/auth/presentation/pages/login_page.dart';
import '../features/auth/presentation/pages/register_page.dart';
import '../features/onboarding/presentation/pages/onboarding_intro_page.dart';
import '../features/onboarding/presentation/pages/onboarding_profile_page.dart';
import '../features/onboarding/presentation/pages/onboarding_interests_page.dart';
import '../features/onboarding/presentation/pages/onboarding_goals_page.dart';
import '../features/onboarding/presentation/pages/onboarding_complete_page.dart';
import '../features/home/presentation/pages/home_page.dart';
import '../features/mentors/presentation/become_mentor_page.dart';
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
import '../features/elearning/presentation/pages/course_exam_page.dart';
import '../features/mentors/presentation/pages/mentors_page.dart';
import '../features/partner/presentation/pages/create_organization_page.dart';
import '../features/partner/presentation/pages/organization_dashboard_page.dart';
import '../features/partner/presentation/pages/beneficiary_form_page.dart';
import '../features/opportunities/presentation/pages/opportunities_page.dart';
import 'auth_guard.dart' show AuthGuard, RoleGuard;
import 'widgets/main_shell.dart';

/// Centre et limite la largeur d'une page plein écran (hors shell) sur grand
/// écran / web, tout en laissant le plein écran sur mobile. Les marges latérales
/// prennent la couleur de fond de l'app pour un rendu propre sur desktop.
Widget _responsive(Widget page, {double maxWidth = 520}) {
  return ColoredBox(
    color: AppColors.background,
    child: Center(
      child: ConstrainedBox(
        constraints: BoxConstraints(maxWidth: maxWidth),
        child: page,
      ),
    ),
  );
}

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
    redirect: (context, state) async {
      final authRedirect = await AuthGuard.redirect(context, state);
      if (authRedirect != null) return authRedirect;
      // GoRouter garantit que context reste valide dans le redirect callback
      // (pas une vraie async gap UX) â€” c'est le contrat de l'API.
      // ignore: use_build_context_synchronously
      return RoleGuard.redirect(context, state);
    },
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
          return _responsive(const RegisterPage(), maxWidth: 520);
        },
      ),
      GoRoute(
        path: '/onboarding',
        builder: (BuildContext context, GoRouterState state) {
          return _responsive(const OnboardingIntroPage(), maxWidth: 480);
        },
      ),
      GoRoute(
        path: '/onboarding/profile',
        builder: (BuildContext context, GoRouterState state) {
          return _responsive(const OnboardingProfilePage(), maxWidth: 480);
        },
      ),
      GoRoute(
        path: '/onboarding/interests',
        builder: (BuildContext context, GoRouterState state) {
          return _responsive(const OnboardingInterestsPage(), maxWidth: 480);
        },
      ),
      GoRoute(
        path: '/onboarding/goals',
        builder: (BuildContext context, GoRouterState state) {
          return _responsive(const OnboardingGoalsPage(), maxWidth: 480);
        },
      ),
      GoRoute(
        path: '/onboarding/complete',
        builder: (BuildContext context, GoRouterState state) {
          return _responsive(const OnboardingCompletePage(), maxWidth: 480);
        },
      ),
      ShellRoute(
        navigatorKey: _shellNavigatorKey,
        builder: (context, state, child) {
          return MainShellWrapper(child: child);
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
            path: '/mentors',
            pageBuilder: (context, state) =>
                const NoTransitionPage(child: MentorsPage()),
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
          GoRoute(
            path: '/elearning/course/:id',
            builder: (context, state) =>
                CourseDetailPage(courseId: state.pathParameters['id']!),
          ),
          GoRoute(
            path: '/elearning/lesson/:id',
            builder: (context, state) =>
                LessonPage(lessonId: state.pathParameters['id']!),
          ),
          GoRoute(
            path: '/elearning/course/:id/exam',
            builder: (context, state) =>
                CourseExamPage(courseId: state.pathParameters['id']!),
          ),
          GoRoute(
            path: '/opportunities',
            builder: (context, state) => const OpportunitiesListPage(),
          ),
          GoRoute(
            path: '/partner',
            redirect: (context, state) => '/partner/organization/create',
          ),
          GoRoute(
            path: '/partner/organization/create',
            builder: (context, state) => const CreateOrganizationPage(),
          ),
          GoRoute(
            path: '/partner/organization/:orgId',
            builder: (context, state) => OrganizationDashboardPage(
              organizationId: state.pathParameters['orgId']!,
            ),
          ),
          GoRoute(
            path: '/partner/beneficiary/create/:orgId',
            builder: (context, state) => BeneficiaryFormPage(
              organizationId: state.pathParameters['orgId']!,
            ),
          ),
          GoRoute(
            path: '/partner/beneficiary/:id',
            builder: (context, state) {
              final orgId = state.uri.queryParameters['orgId'] ?? '';
              return BeneficiaryFormPage(
                organizationId: orgId,
                beneficiaryId: state.pathParameters['id']!,
              );
            },
          ),
        ],
      ),
      GoRoute(
        path: '/orientation/test',
        builder: (BuildContext context, GoRouterState state) {
          final test = state.extra as OrientationTest;
          return _responsive(TestExecutionPage(test: test), maxWidth: 720);
        },
      ),
      GoRoute(
        path: '/orientation/results',
        builder: (BuildContext context, GoRouterState state) {
          final result = state.extra as TestResult;
          return _responsive(ResultsPage(result: result), maxWidth: 760);
        },
      ),
      GoRoute(
        path: '/orientation/career',
        builder: (BuildContext context, GoRouterState state) {
          final career = state.extra as Career;
          return _responsive(CareerDetailPage(career: career), maxWidth: 760);
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
        path: '/mentors/apply',
        builder: (BuildContext context, GoRouterState state) =>
            _responsive(const BecomeMentorPage(), maxWidth: 560),
      ),
    ],
  );
}
