import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:iconsax/iconsax.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_spacing.dart';
import '../../../../core/constants/app_typography.dart';
import '../../../../core/di/injection_container.dart';
import '../../../../shared/widgets/inputs/custom_search_bar.dart';
import '../../../auth/presentation/bloc/auth_bloc.dart';
import '../../../ai_chat/presentation/pages/chat_page.dart';
import '../../../orientation/domain/entities/orientation_test.dart';
import '../../../orientation/domain/usecases/get_orientation_tests.dart';
import '../../../elearning/domain/entities/course.dart';
import '../../../elearning/domain/usecases/get_courses_usecase.dart';
import '../../../elearning/presentation/widgets/course_card.dart';

/// Page d'accueil de l'application ActivEducation
class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  late final Future<List<OrientationTest>> _testsFuture;
  late final Future<List<Course>> _coursesFuture;

  @override
  void initState() {
    super.initState();
    _testsFuture = _loadTests();
    _coursesFuture = _loadCourses();
  }

  Future<List<OrientationTest>> _loadTests() async {
    final result = await getIt<GetOrientationTests>()();
    return result.fold((error) {
      debugPrint('[HomePage] Erreur chargement tests: $error');
      return <OrientationTest>[];
    }, (tests) => tests);
  }

  Future<List<Course>> _loadCourses() async {
    final result = await getIt<GetCoursesUsecase>()();
    return result.fold((error) {
      debugPrint('[HomePage] Erreur chargement cours: $error');
      return <Course>[];
    }, (courses) => courses);
  }

  void _openTest(BuildContext context, OrientationTest test) {
    context.push('/orientation/test', extra: test);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header + Search — avec padding
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.pagePaddingHorizontal,
                ),
                child: Column(
                  children: [
                    const SizedBox(height: AppSpacing.md),
                    _buildHeader(context),
                    const SizedBox(height: AppSpacing.lg),
                    const CustomSearchBar(
                      hintText: 'Chercher une \u00e9cole, un m\u00e9tier...',
                    ),
                  ],
                ),
              ),

              const SizedBox(height: AppSpacing.lg),

              // Orientation CTA — avec padding
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.pagePaddingHorizontal,
                ),
                child: _buildOrientationCTA(context),
              ),

              const SizedBox(height: 20),

              // AÏDA — avec padding
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.pagePaddingHorizontal,
                ),
                child: _buildAidaCard(context),
              ),

              const SizedBox(height: 36),

              // Tests — titre avec padding, grille avec padding
              _buildTestsSection(context),

              const SizedBox(height: 36),

              // E-learning — pleine largeur pour le scroll horizontal
              _buildElearningSection(context),

              const SizedBox(height: 36),

              // Établissements — en bas
              _buildSchoolsSection(context),

              const SizedBox(height: AppSpacing.pagePaddingBottom),
            ],
          ),
        ),
      ),
    );
  }

  // ─── HEADER ──────────────────────────────────────────────────────────────────

  Widget _buildHeader(BuildContext context) {
    return BlocBuilder<AuthBloc, AuthState>(
      builder: (context, state) {
        String firstName = 'Utilisateur';
        String initials = 'U';
        if (state is AuthAuthenticated) {
          firstName =
              state.user.firstName ?? state.user.displayName ?? 'Utilisateur';
          initials = state.user.initials;
        }

        return Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Bonjour, $firstName \u{1F44B}',
                    style: AppTypography.headlineSmall.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    'Pr\u00eat \u00e0 d\u00e9couvrir ton avenir ?',
                    style: AppTypography.bodyMedium.copyWith(
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
            Row(
              children: [
                Stack(
                  children: [
                    Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: AppColors.surface,
                        shape: BoxShape.circle,
                        border: Border.all(color: AppColors.border),
                      ),
                      child: IconButton(
                        padding: EdgeInsets.zero,
                        icon: const Icon(Iconsax.notification, size: 20),
                        color: AppColors.textSecondary,
                        onPressed: () {},
                      ),
                    ),
                    Positioned(
                      right: 6,
                      top: 6,
                      child: Container(
                        width: 10,
                        height: 10,
                        decoration: BoxDecoration(
                          color: AppColors.secondary,
                          shape: BoxShape.circle,
                          border: Border.all(color: Colors.white, width: 1.5),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(width: AppSpacing.sm),
                Container(
                  width: 44,
                  height: 44,
                  decoration: const BoxDecoration(
                    gradient: LinearGradient(
                      colors: [AppColors.primary, AppColors.secondary],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    shape: BoxShape.circle,
                  ),
                  child: Center(
                    child: Text(
                      initials,
                      style: AppTypography.labelLarge.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        );
      },
    );
  }

  // ─── ORIENTATION CTA ────────────────────────────────────────────────────────

  Widget _buildOrientationCTA(BuildContext context) {
    return Stack(
      children: [
        Container(
          width: double.infinity,
          padding: const EdgeInsets.fromLTRB(24, 24, 24, 20),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [AppColors.primary, AppColors.primaryIndigo],
            ),
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: AppColors.primary.withValues(alpha: 0.3),
                blurRadius: 16,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Decorative circles
              Stack(
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.2),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: const Icon(
                              Iconsax.discover,
                              color: Colors.white,
                              size: 24,
                            ),
                          ),
                          const SizedBox(width: AppSpacing.sm),
                          Expanded(
                            child: Text(
                              'D\u00e9couvre ton profil',
                              style: AppTypography.titleLarge.copyWith(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Text(
                        'R\u00e9ponds \u00e0 nos tests d\'orientation\npour trouver la voie qui te correspond.',
                        style: AppTypography.bodyMedium.copyWith(
                          color: Colors.white.withValues(alpha: 0.85),
                          height: 1.5,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 18),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () => context.go('/orientation'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.white,
                    foregroundColor: AppColors.primary,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    elevation: 0,
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        'Commencer les tests',
                        style: AppTypography.labelLarge.copyWith(
                          color: AppColors.primary,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(width: 8),
                      const Icon(Icons.arrow_forward_rounded, size: 18),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
        // "Nouveau" orange badge
        Positioned(
          top: 0,
          right: 0,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
            decoration: const BoxDecoration(
              color: AppColors.secondary,
              borderRadius: BorderRadius.only(
                topRight: Radius.circular(20),
                bottomLeft: Radius.circular(12),
              ),
            ),
            child: Text(
              'Nouveau',
              style: AppTypography.labelSmall.copyWith(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 10,
              ),
            ),
          ),
        ),
      ],
    );
  }

  // ─── AÏDA — CHAT PREVIEW STYLE ─────────────────────────────────────────────

  Widget _buildAidaCard(BuildContext context) {
    return GestureDetector(
      onTap: () => context.push('/chat', extra: const ChatPageArgs()),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.card,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: AppColors.border),
          boxShadow: AppColors.cardShadow,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header avec avatar + nom + statut en ligne
            Row(
              children: [
                // Avatar AÏDA avec indicateur "en ligne"
                Stack(
                  children: [
                    Container(
                      width: 42,
                      height: 42,
                      decoration: BoxDecoration(
                        gradient: AppColors.primaryGradient,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(
                        Icons.smart_toy_rounded,
                        color: Colors.white,
                        size: 22,
                      ),
                    ),
                    Positioned(
                      right: -1,
                      bottom: -1,
                      child: Container(
                        width: 14,
                        height: 14,
                        decoration: BoxDecoration(
                          color: AppColors.success,
                          shape: BoxShape.circle,
                          border: Border.all(color: Colors.white, width: 2.5),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'A\u00cfDA',
                        style: AppTypography.titleSmall.copyWith(
                          fontWeight: FontWeight.bold,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      Text(
                        'Ta conseill\u00e8re \u00b7 En ligne',
                        style: AppTypography.labelSmall.copyWith(
                          color: AppColors.success,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
                Icon(
                  Icons.arrow_forward_ios_rounded,
                  size: 14,
                  color: AppColors.textTertiary,
                ),
              ],
            ),

            const SizedBox(height: 12),

            // Bulle de message "aperçu"
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: BoxDecoration(
                color: AppColors.primarySurface,
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(16),
                  topRight: Radius.circular(16),
                  bottomLeft: Radius.circular(4),
                  bottomRight: Radius.circular(16),
                ),
              ),
              child: Text(
                'Salut ! Je suis l\u00e0 pour t\u0027aider \u00e0 trouver ta voie. Pose-moi tes questions \u{1F4AC}',
                style: AppTypography.bodySmall.copyWith(
                  color: AppColors.primaryDark,
                  height: 1.4,
                ),
              ),
            ),

            const SizedBox(height: 10),

            // Suggestion chips
            Wrap(
              spacing: 6,
              runSpacing: 6,
              children: [
                _AidaChip(label: 'Quelles fili\u00e8res ?'),
                _AidaChip(label: 'M\u00e9tiers pour moi'),
                _AidaChip(label: '\u00c9coles au Togo'),
              ],
            ),
          ],
        ),
      ),
    );
  }

  // ─── TESTS D'ORIENTATION ────────────────────────────────────────────────────

  Widget _buildTestsSection(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.pagePaddingHorizontal,
          ),
          child: Row(
            children: [
              Container(
                width: 3,
                height: 20,
                decoration: BoxDecoration(
                  color: AppColors.primary,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(width: 10),
              Text(
                'Explore tes talents',
                style: AppTypography.titleLarge.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const Spacer(),
              TextButton(
                onPressed: () => context.go('/orientation'),
                style: TextButton.styleFrom(
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      'Tout voir',
                      style: AppTypography.labelMedium.copyWith(
                        color: AppColors.primary,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(width: 2),
                    const Icon(Icons.chevron_right_rounded,
                        size: 18, color: AppColors.primary),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 14),
        Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.pagePaddingHorizontal,
          ),
          child: FutureBuilder<List<OrientationTest>>(
            future: _testsFuture,
            builder: (context, snapshot) {
              if (!snapshot.hasData) {
                return const Padding(
                  padding: EdgeInsets.symmetric(vertical: AppSpacing.lg),
                  child: Center(
                    child: CircularProgressIndicator(
                      color: AppColors.primary,
                      strokeWidth: 2.5,
                    ),
                  ),
                );
              }

              final tests = snapshot.data ?? const <OrientationTest>[];
              if (tests.isEmpty) {
                return Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(AppSpacing.lg),
                  decoration: BoxDecoration(
                    color: AppColors.surface,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Text(
                    'Aucun test disponible pour le moment.',
                    style: AppTypography.bodyMedium.copyWith(
                      color: AppColors.textSecondary,
                    ),
                  ),
                );
              }

              final cards = tests.take(4).map((test) => _TestCardData(
                    test: test,
                    title: test.name,
                    subtitle: _subtitleFromType(test.type),
                    icon: _iconFromType(test.type),
                    color: _colorFromType(test.type),
                    duration: '${test.durationMinutes} min',
                  )).toList();

              return GridView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  crossAxisSpacing: 12,
                  mainAxisSpacing: 12,
                  childAspectRatio: 1.45,
                ),
                itemCount: cards.length,
                itemBuilder: (context, index) {
                  final card = cards[index];
                  return _TestCard(
                    data: card,
                    onTap: () => _openTest(context, card.test),
                  );
                },
              );
            },
          ),
        ),
      ],
    );
  }

  String _subtitleFromType(TestType type) {
    switch (type) {
      case TestType.riasec:
        return 'Int\u00e9r\u00eats professionnels';
      case TestType.personality:
        return 'Traits de caract\u00e8re';
      case TestType.skills:
        return 'Points forts';
      case TestType.interests:
        return 'Tes priorit\u00e9s';
      case TestType.aptitude:
        return 'Aptitudes naturelles';
    }
  }

  IconData _iconFromType(TestType type) {
    switch (type) {
      case TestType.riasec:
        return Iconsax.chart;
      case TestType.personality:
        return Iconsax.user;
      case TestType.skills:
        return Iconsax.medal_star;
      case TestType.interests:
        return Iconsax.heart;
      case TestType.aptitude:
        return Iconsax.flash;
    }
  }

  Color _colorFromType(TestType type) {
    switch (type) {
      case TestType.riasec:
        return AppColors.primary; // bleu
      case TestType.personality:
        return AppColors.secondary; // orange
      case TestType.skills:
        return AppColors.primary; // bleu
      case TestType.interests:
        return AppColors.secondary; // orange
      case TestType.aptitude:
        return AppColors.primary; // bleu
    }
  }

  // ─── E-LEARNING ─────────────────────────────────────────────────────────────

  Widget _buildElearningSection(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.pagePaddingHorizontal,
          ),
          child: Row(
            children: [
              Container(
                width: 3,
                height: 20,
                decoration: BoxDecoration(
                  color: AppColors.categoryTechnology,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(width: 10),
              Text(
                'Apprendre',
                style: AppTypography.titleLarge.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(width: 8),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: AppColors.categoryTechnology.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  'E-Learning',
                  style: AppTypography.labelSmall.copyWith(
                    color: AppColors.categoryTechnology,
                    fontWeight: FontWeight.w600,
                    fontSize: 10,
                  ),
                ),
              ),
              const Spacer(),
              TextButton(
                onPressed: () => context.push('/elearning'),
                style: TextButton.styleFrom(
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      'Catalogue',
                      style: AppTypography.labelMedium.copyWith(
                        color: AppColors.categoryTechnology,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(width: 2),
                    const Icon(Icons.chevron_right_rounded,
                        size: 18, color: AppColors.categoryTechnology),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 14),
        FutureBuilder<List<Course>>(
          future: _coursesFuture,
          builder: (context, snapshot) {
            if (!snapshot.hasData) {
              return const SizedBox(
                height: 140,
                child: Center(
                  child: CircularProgressIndicator(
                    color: AppColors.categoryTechnology,
                    strokeWidth: 2.5,
                  ),
                ),
              );
            }

            final courses = snapshot.data ?? <Course>[];

            if (courses.isEmpty) {
              return Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.pagePaddingHorizontal,
                ),
                child: _ElearningCTACard(
                  onTap: () => context.push('/elearning'),
                ),
              );
            }

            return SizedBox(
              height: 160,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.pagePaddingHorizontal,
                ),
                itemCount: courses.take(4).length,
                separatorBuilder: (_, __) => const SizedBox(width: 12),
                itemBuilder: (context, index) {
                  final course = courses.elementAt(index);
                  return SizedBox(
                    width: 220,
                    child: CourseCard(
                      course: course,
                      mode: CourseCardMode.compact,
                      onTap: () => context.push(
                        '/elearning/course/${course.id}',
                      ),
                    ),
                  );
                },
              ),
            );
          },
        ),
      ],
    );
  }

  // ─── ÉTABLISSEMENTS ─────────────────────────────────────────────────────────

  Widget _buildSchoolsSection(BuildContext context) {
    final schools = [
      _SchoolPreview(
        name: 'Universit\u00e9 de Lom\u00e9',
        shortName: 'UL',
        location: 'Lom\u00e9, Togo',
        programs: '120+ fili\u00e8res',
        color: AppColors.primary,
      ),
      _SchoolPreview(
        name: 'UK (Kara)',
        shortName: 'UK',
        location: 'Kara, Togo',
        programs: '85+ fili\u00e8res',
        color: AppColors.categoryTechnology,
      ),
      _SchoolPreview(
        name: 'ESIBA',
        shortName: 'ES',
        location: 'Lom\u00e9, Togo',
        programs: '25+ fili\u00e8res',
        color: AppColors.secondary,
      ),
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.pagePaddingHorizontal,
          ),
          child: Row(
            children: [
              Container(
                width: 3,
                height: 20,
                decoration: BoxDecoration(
                  color: AppColors.success,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(width: 10),
              Text(
                '\u00c9tablissements',
                style: AppTypography.titleLarge.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const Spacer(),
              TextButton(
                onPressed: () => context.go('/schools'),
                style: TextButton.styleFrom(
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      'Annuaire',
                      style: AppTypography.labelMedium.copyWith(
                        color: AppColors.success,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(width: 2),
                    const Icon(Icons.chevron_right_rounded,
                        size: 18, color: AppColors.success),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 14),
        SizedBox(
          height: 150,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.pagePaddingHorizontal,
            ),
            itemCount: schools.length,
            separatorBuilder: (_, __) => const SizedBox(width: 12),
            itemBuilder: (context, index) {
              final school = schools[index];
              return _SchoolCard(
                school: school,
                onTap: () => context.go('/schools'),
              );
            },
          ),
        ),
      ],
    );
  }
}

// ─── WIDGETS PRIVÉS ───────────────────────────────────────────────────────────

class _AidaChip extends StatelessWidget {
  final String label;
  const _AidaChip({required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.border),
      ),
      child: Text(
        label,
        style: AppTypography.labelSmall.copyWith(
          color: AppColors.textSecondary,
          fontWeight: FontWeight.w500,
          fontSize: 11,
        ),
      ),
    );
  }
}

class _ElearningCTACard extends StatelessWidget {
  final VoidCallback? onTap;

  const _ElearningCTACard({this.onTap});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.all(AppSpacing.lg),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                AppColors.categoryTechnology.withValues(alpha: 0.08),
                AppColors.primary.withValues(alpha: 0.06),
              ],
            ),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: AppColors.categoryTechnology.withValues(alpha: 0.25),
            ),
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color:
                      AppColors.categoryTechnology.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  Icons.play_lesson_rounded,
                  color: AppColors.categoryTechnology,
                  size: 26,
                ),
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'D\u00e9couvrez nos cours',
                      style: AppTypography.titleSmall.copyWith(
                        fontWeight: FontWeight.bold,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Vid\u00e9os, quiz, articles & hackathons',
                      style: AppTypography.bodySmall.copyWith(
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
              const Icon(
                Icons.arrow_forward_ios_rounded,
                color: AppColors.categoryTechnology,
                size: 14,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _TestCardData {
  final OrientationTest test;
  final String title;
  final String subtitle;
  final IconData icon;
  final Color color;
  final String duration;

  const _TestCardData({
    required this.test,
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.color,
    required this.duration,
  });
}

class _TestCard extends StatelessWidget {
  final _TestCardData data;
  final VoidCallback? onTap;

  const _TestCard({required this.data, this.onTap});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: AppColors.card,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: AppColors.border),
            boxShadow: AppColors.cardShadow,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              // Icone et durée
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: data.color.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(data.icon, color: data.color, size: 18),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 7,
                      vertical: 3,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.surface,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Iconsax.timer_1,
                            size: 10, color: AppColors.textTertiary),
                        const SizedBox(width: 3),
                        Text(
                          data.duration,
                          style: AppTypography.labelSmall.copyWith(
                            color: AppColors.textSecondary,
                            fontWeight: FontWeight.w500,
                            fontSize: 10,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              // Titre et sous-titre
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    data.title,
                    style: AppTypography.bodyMedium.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 2),
                  Text(
                    data.subtitle,
                    style: AppTypography.labelSmall.copyWith(
                      color: data.color,
                      fontWeight: FontWeight.w500,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SchoolPreview {
  final String name;
  final String shortName;
  final String location;
  final String programs;
  final Color color;

  const _SchoolPreview({
    required this.name,
    required this.shortName,
    required this.location,
    required this.programs,
    required this.color,
  });
}

class _SchoolCard extends StatelessWidget {
  final _SchoolPreview school;
  final VoidCallback? onTap;

  const _SchoolCard({required this.school, this.onTap});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          width: 200,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppColors.card,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppColors.border),
            boxShadow: AppColors.cardShadow,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Initiale stylisée + badge filières
              Row(
                children: [
                  // Lettre initiale en grand dans un cercle coloré
                  Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color: school.color.withValues(alpha: 0.1),
                      shape: BoxShape.circle,
                    ),
                    child: Center(
                      child: Text(
                        school.shortName,
                        style: AppTypography.titleSmall.copyWith(
                          fontWeight: FontWeight.w800,
                          color: school.color,
                          fontSize: 15,
                        ),
                      ),
                    ),
                  ),
                  const Spacer(),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 3,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.secondarySurface,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      school.programs,
                      style: AppTypography.labelSmall.copyWith(
                        color: AppColors.secondaryDark,
                        fontWeight: FontWeight.w600,
                        fontSize: 9,
                      ),
                    ),
                  ),
                ],
              ),
              const Spacer(),
              // Nom + localisation
              Text(
                school.name,
                style: AppTypography.titleSmall.copyWith(
                  fontWeight: FontWeight.bold,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 4),
              Row(
                children: [
                  Icon(Iconsax.location, size: 12, color: school.color),
                  const SizedBox(width: 4),
                  Expanded(
                    child: Text(
                      school.location,
                      style: AppTypography.labelSmall.copyWith(
                        color: AppColors.textTertiary,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
