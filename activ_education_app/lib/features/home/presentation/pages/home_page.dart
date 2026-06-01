import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_spacing.dart';
import '../../../../core/di/injection_container.dart';
import '../../../../shared/widgets/inputs/custom_search_bar.dart';
import '../../../ai_chat/presentation/pages/chat_page.dart';
import '../../../gamification/presentation/cubit/gamification_cubit.dart';
import '../../../orientation/domain/entities/orientation_test.dart';
import '../../../orientation/domain/usecases/get_orientation_tests.dart';
import '../../../elearning/domain/entities/course.dart';
import '../../../elearning/domain/usecases/get_courses_usecase.dart';
import '../widgets/hero_header.dart';
import '../widgets/announcements_section.dart';
import '../widgets/orientation_cta.dart';
import '../widgets/aida_card.dart';
import '../widgets/tests_section.dart';
import '../widgets/elearning_section.dart';
import '../widgets/schools_section.dart';
import '../widgets/opportunities_section.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  late final Future<List<OrientationTest>> _testsFuture;
  late final Future<List<Course>> _coursesFuture;
  late final GamificationCubit _gamificationCubit;

  @override
  void initState() {
    super.initState();
    _testsFuture = _loadTests();
    _coursesFuture = _loadCourses();
    _gamificationCubit = getIt<GamificationCubit>()..load();
  }

  // NB: GamificationCubit est un @lazySingleton partage (recharge via
  // refresh() depuis l'e-learning). On ne le close() PAS ici, sinon son
  // StreamController serait ferme definitivement et tout getIt<GamificationCubit>()
  // ulterieur (retour sur l'accueil, refresh apres lecon) crasherait
  // ("Cannot add new events after calling close"). Le singleton vit toute la
  // session ; il est reinitialise au logout (AuthBloc._onLogoutRequested).

  Future<List<OrientationTest>> _loadTests() async {
    final result = await getIt<GetOrientationTests>()();
    return result.fold((_) => <OrientationTest>[], (tests) => tests);
  }

  Future<List<Course>> _loadCourses() async {
    final result = await getIt<GetCoursesUsecase>()();
    return result.fold((_) => <Course>[], (courses) => courses);
  }

  void _openTest(BuildContext context, OrientationTest test) {
    context.push('/orientation/test', extra: test);
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider.value(
      value: _gamificationCubit,
      child: Scaffold(
        backgroundColor: AppColors.background,
        body: CustomScrollView(
        physics: const BouncingScrollPhysics(),
        slivers: [
          // ── Hero Header ──
          SliverToBoxAdapter(
            child: HeroHeader(
              onNotification: () {},
              onProfile: () => context.go('/profile'),
            ),
          ),

          // ── Search bar ──
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.pagePaddingHorizontal,
                20,
                AppSpacing.pagePaddingHorizontal,
                0,
              ),
              child: const CustomSearchBar(
                hintText: 'Chercher une école, un métier...',
              ),
            ),
          ),

          // ── Announcements ──
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.only(top: 24),
              child: const AnnouncementsSection(),
            ),
          ),

          // ── Orientation CTA ──
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.pagePaddingHorizontal,
                20,
                AppSpacing.pagePaddingHorizontal,
                0,
              ),
              child: OrientationCTA(onTap: () => context.go('/orientation')),
            ),
          ),

          // ── AÏDA Card ──
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.pagePaddingHorizontal,
                16,
                AppSpacing.pagePaddingHorizontal,
                0,
              ),
              child: AidaCard(
                onTap: () => context.push('/chat', extra: const ChatPageArgs()),
              ),
            ),
          ),

          // ── Tests section ──
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.only(top: 32),
              child: TestsSection(
                testsFuture: _testsFuture,
                onTestTap: (test) => _openTest(context, test),
                onViewAll: () => context.go('/orientation'),
              ),
            ),
          ),

          // ── E-Learning section ──
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.only(top: 32),
              child: ElearningSection(
                coursesFuture: _coursesFuture,
                onCatalog: () => context.push('/elearning'),
                onCourseTap: (course) =>
                    context.push('/elearning/course/${course.id}'),
              ),
            ),
          ),

          // ── Établissements section ──
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.only(top: 32),
              child: SchoolsSection(onViewAll: () => context.go('/schools')),
            ),
          ),

          // ── Opportunities section ──
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.only(top: 32),
              child: const OpportunitiesSection(),
            ),
          ),

          const SliverToBoxAdapter(
            child: SizedBox(height: AppSpacing.pagePaddingBottom),
          ),
        ],
      ),
    ),
    );
  }
}
