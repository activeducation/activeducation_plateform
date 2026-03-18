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
    return Scaffold(
      backgroundColor: AppColors.background,
      body: CustomScrollView(
        physics: const BouncingScrollPhysics(),
        slivers: [
          // ── Hero Header ──
          SliverToBoxAdapter(
            child: _HeroHeader(
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

          // ── Orientation CTA ──
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.pagePaddingHorizontal,
                20,
                AppSpacing.pagePaddingHorizontal,
                0,
              ),
              child: _OrientationCTA(
                onTap: () => context.go('/orientation'),
              ),
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
              child: _AidaCard(
                onTap: () => context.push(
                  '/chat',
                  extra: const ChatPageArgs(),
                ),
              ),
            ),
          ),

          // ── Tests section ──
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.only(top: 32),
              child: _TestsSection(
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
              child: _ElearningSection(
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
              child: _SchoolsSection(
                onViewAll: () => context.go('/schools'),
              ),
            ),
          ),

          const SliverToBoxAdapter(
            child: SizedBox(height: AppSpacing.pagePaddingBottom),
          ),
        ],
      ),
    );
  }
}

// ─── HERO HEADER ──────────────────────────────────────────────────────────────

class _HeroHeader extends StatelessWidget {
  final VoidCallback onNotification;
  final VoidCallback onProfile;

  const _HeroHeader({
    required this.onNotification,
    required this.onProfile,
  });

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<AuthBloc, AuthState>(
      builder: (context, state) {
        String firstName = 'Explorer';
        String initials = 'E';
        if (state is AuthAuthenticated) {
          firstName =
              state.user.firstName ?? state.user.displayName ?? 'Explorer';
          initials = state.user.initials;
        }

        return Container(
          decoration: const BoxDecoration(
            gradient: AppColors.heroGradient,
          ),
          child: SafeArea(
            bottom: false,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Top bar
                  Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Bonjour, $firstName 👋',
                              style: AppTypography.heroTitle.copyWith(
                                fontSize: 22,
                              ),
                            ),
                            const SizedBox(height: 3),
                            Text(
                              'Prêt à jouer ton avenir ?',
                              style: AppTypography.heroSubtitle,
                            ),
                          ],
                        ),
                      ),
                      // Notification
                      _IconButton(
                        icon: Iconsax.notification,
                        badgeActive: true,
                        onTap: onNotification,
                      ),
                      const SizedBox(width: 10),
                      // Avatar
                      GestureDetector(
                        onTap: onProfile,
                        child: Container(
                          width: 42,
                          height: 42,
                          decoration: BoxDecoration(
                            gradient: const LinearGradient(
                              colors: [
                                AppColors.primary,
                                AppColors.secondary,
                              ],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ),
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: AppColors.darkBorder2,
                              width: 2,
                            ),
                          ),
                          child: Center(
                            child: Text(
                              initials,
                              style: AppTypography.labelLarge.copyWith(
                                color: Colors.white,
                                fontWeight: FontWeight.w700,
                                fontSize: 14,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 24),

                  // ── Gamification stats bar ──
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: AppColors.darkSurface.withValues(alpha: 0.7),
                      borderRadius: BorderRadius.circular(18),
                      border: Border.all(
                        color: AppColors.darkBorder2,
                      ),
                    ),
                    child: Column(
                      children: [
                        // Stats row
                        Row(
                          children: [
                            _StatChip(
                              icon: '⭐',
                              value: 'Niv. 3',
                              label: 'NIVEAU',
                              valueColor: AppColors.xpGold,
                            ),
                            _StatDivider(),
                            _StatChip(
                              icon: '🔥',
                              value: '7',
                              label: 'STREAK',
                              valueColor: AppColors.streakFire,
                            ),
                            _StatDivider(),
                            _StatChip(
                              icon: '⚡',
                              value: '850',
                              label: 'XP',
                              valueColor: AppColors.xpBar,
                            ),
                          ],
                        ),
                        const SizedBox(height: 14),
                        // XP progress bar
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  'Progression vers Niveau 4',
                                  style: AppTypography.statLabel.copyWith(
                                    fontSize: 10.5,
                                    letterSpacing: 0.3,
                                  ),
                                ),
                                Text(
                                  '850 / 1 000 XP',
                                  style: AppTypography.statLabel.copyWith(
                                    color: AppColors.xpBar,
                                    fontWeight: FontWeight.w600,
                                    fontSize: 10.5,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            ClipRRect(
                              borderRadius: BorderRadius.circular(6),
                              child: Stack(
                                children: [
                                  Container(
                                    height: 7,
                                    color: AppColors.darkBorder,
                                  ),
                                  FractionallySizedBox(
                                    widthFactor: 0.85,
                                    child: Container(
                                      height: 7,
                                      decoration: const BoxDecoration(
                                        gradient: AppColors.xpBarGradient,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

class _IconButton extends StatelessWidget {
  final IconData icon;
  final bool badgeActive;
  final VoidCallback onTap;

  const _IconButton({
    required this.icon,
    this.badgeActive = false,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: AppColors.darkSurface,
            shape: BoxShape.circle,
            border: Border.all(color: AppColors.darkBorder),
          ),
          child: IconButton(
            padding: EdgeInsets.zero,
            icon: Icon(icon, size: 19),
            color: AppColors.darkTextSecondary,
            onPressed: onTap,
          ),
        ),
        if (badgeActive)
          Positioned(
            right: 6,
            top: 6,
            child: Container(
              width: 9,
              height: 9,
              decoration: BoxDecoration(
                color: AppColors.secondary,
                shape: BoxShape.circle,
                border: Border.all(
                  color: AppColors.darkBg,
                  width: 1.5,
                ),
              ),
            ),
          ),
      ],
    );
  }
}

class _StatChip extends StatelessWidget {
  final String icon;
  final String value;
  final String label;
  final Color valueColor;

  const _StatChip({
    required this.icon,
    required this.value,
    required this.label,
    required this.valueColor,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(icon, style: const TextStyle(fontSize: 14)),
              const SizedBox(width: 5),
              Text(
                value,
                style: AppTypography.statValueSmall.copyWith(
                  color: valueColor,
                  fontSize: 17,
                ),
              ),
            ],
          ),
          const SizedBox(height: 3),
          Text(
            label,
            style: AppTypography.statLabel,
          ),
        ],
      ),
    );
  }
}

class _StatDivider extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      width: 1,
      height: 32,
      margin: const EdgeInsets.symmetric(horizontal: 4),
      color: AppColors.darkBorder,
    );
  }
}

// ─── ORIENTATION CTA ──────────────────────────────────────────────────────────

class _OrientationCTA extends StatelessWidget {
  final VoidCallback onTap;
  const _OrientationCTA({required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Material(
          color: Colors.transparent,
          borderRadius: BorderRadius.circular(20),
          child: InkWell(
            onTap: onTap,
            borderRadius: BorderRadius.circular(20),
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.fromLTRB(22, 22, 22, 18),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [AppColors.primary, AppColors.primaryIndigo],
                ),
                borderRadius: BorderRadius.circular(20),
                boxShadow: AppColors.primaryShadow,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.18),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Icon(
                          Iconsax.discover,
                          color: Colors.white,
                          size: 22,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          'Découvre ton profil',
                          style: AppTypography.titleLarge.copyWith(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Text(
                    'Réponds à nos tests d\'orientation pour trouver la voie qui te correspond.',
                    style: AppTypography.bodyMedium.copyWith(
                      color: Colors.white.withValues(alpha: 0.85),
                      height: 1.5,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Container(
                    padding: const EdgeInsets.symmetric(
                        vertical: 12, horizontal: 16),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          'Commencer les tests',
                          style: AppTypography.labelLarge.copyWith(
                            color: AppColors.primary,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(width: 8),
                        const Icon(
                          Icons.arrow_forward_rounded,
                          size: 17,
                          color: AppColors.primary,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
        // Badge
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
              style: AppTypography.badgeText.copyWith(
                color: Colors.white,
              ),
            ),
          ),
        ),
      ],
    );
  }
}

// ─── AÏDA CARD ────────────────────────────────────────────────────────────────

class _AidaCard extends StatelessWidget {
  final VoidCallback onTap;
  const _AidaCard({required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
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
            Row(
              children: [
                // AÏDA avatar
                Stack(
                  children: [
                    Container(
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [AppColors.primary, AppColors.primaryIndigo],
                        ),
                        borderRadius: BorderRadius.circular(13),
                      ),
                      child: const Icon(
                        Icons.smart_toy_rounded,
                        color: Colors.white,
                        size: 22,
                      ),
                    ),
                    Positioned(
                      right: -2,
                      bottom: -2,
                      child: Container(
                        width: 14,
                        height: 14,
                        decoration: BoxDecoration(
                          color: AppColors.success,
                          shape: BoxShape.circle,
                          border: Border.all(color: Colors.white, width: 2),
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
                        'AÏDA',
                        style: AppTypography.titleSmall.copyWith(
                          fontWeight: FontWeight.w800,
                          color: AppColors.textPrimary,
                          letterSpacing: 0.5,
                        ),
                      ),
                      Text(
                        'Ta conseillère IA · En ligne',
                        style: AppTypography.labelSmall.copyWith(
                          color: AppColors.success,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 10, vertical: 5),
                  decoration: BoxDecoration(
                    color: AppColors.primarySurface,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    'Discuter →',
                    style: AppTypography.labelSmall.copyWith(
                      color: AppColors.primary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
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
                'Salut ! Je suis là pour t\'aider à trouver ta voie. Pose-moi tes questions 💬',
                style: AppTypography.bodySmall.copyWith(
                  color: AppColors.primaryDark,
                  height: 1.5,
                ),
              ),
            ),
            const SizedBox(height: 10),
            Wrap(
              spacing: 6,
              runSpacing: 6,
              children: const [
                _AidaChip(label: 'Quelles filières ?'),
                _AidaChip(label: 'Métiers pour moi'),
                _AidaChip(label: 'Écoles au Togo'),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _AidaChip extends StatelessWidget {
  final String label;
  const _AidaChip({required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 5),
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
        ),
      ),
    );
  }
}

// ─── SECTION HEADER ───────────────────────────────────────────────────────────

class _SectionHeader extends StatelessWidget {
  final String title;
  final String? badge;
  final Color accentColor;
  final String? actionLabel;
  final VoidCallback? onAction;

  const _SectionHeader({
    required this.title,
    this.badge,
    required this.accentColor,
    this.actionLabel,
    this.onAction,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.pagePaddingHorizontal,
      ),
      child: Row(
        children: [
          Container(
            width: 3,
            height: 20,
            decoration: BoxDecoration(
              color: accentColor,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(width: 10),
          Text(
            title,
            style: AppTypography.titleLarge.copyWith(
              fontWeight: FontWeight.w700,
              letterSpacing: -0.2,
            ),
          ),
          if (badge != null) ...[
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(
                color: accentColor.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(6),
              ),
              child: Text(
                badge!,
                style: AppTypography.badgeText.copyWith(
                  color: accentColor,
                ),
              ),
            ),
          ],
          const Spacer(),
          if (actionLabel != null && onAction != null)
            GestureDetector(
              onTap: onAction,
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    actionLabel!,
                    style: AppTypography.labelMedium.copyWith(
                      color: accentColor,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(width: 2),
                  Icon(
                    Icons.chevron_right_rounded,
                    size: 18,
                    color: accentColor,
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}

// ─── TESTS SECTION ────────────────────────────────────────────────────────────

class _TestsSection extends StatelessWidget {
  final Future<List<OrientationTest>> testsFuture;
  final void Function(OrientationTest) onTestTap;
  final VoidCallback onViewAll;

  const _TestsSection({
    required this.testsFuture,
    required this.onTestTap,
    required this.onViewAll,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _SectionHeader(
          title: 'Explore tes talents',
          accentColor: AppColors.primary,
          actionLabel: 'Tout voir',
          onAction: onViewAll,
        ),
        const SizedBox(height: 14),
        Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.pagePaddingHorizontal,
          ),
          child: FutureBuilder<List<OrientationTest>>(
            future: testsFuture,
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

              final tests = snapshot.data ?? <OrientationTest>[];
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
                    style: AppTypography.bodyMedium,
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
                  childAspectRatio: 1.4,
                ),
                itemCount: cards.length,
                itemBuilder: (context, index) => _TestCard(
                  data: cards[index],
                  onTap: () => onTestTap(cards[index].test),
                ),
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
        return 'Intérêts professionnels';
      case TestType.personality:
        return 'Traits de caractère';
      case TestType.skills:
        return 'Points forts';
      case TestType.interests:
        return 'Tes priorités';
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
        return AppColors.primary;
      case TestType.personality:
        return AppColors.secondary;
      case TestType.skills:
        return AppColors.categoryTechnology;
      case TestType.interests:
        return AppColors.streakFire;
      case TestType.aptitude:
        return AppColors.categoryScience;
    }
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
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: AppColors.card,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppColors.border),
            boxShadow: AppColors.cardShadow,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Top: icon + duration
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Container(
                    padding: const EdgeInsets.all(9),
                    decoration: BoxDecoration(
                      color: data.color.withValues(alpha: 0.10),
                      borderRadius: BorderRadius.circular(11),
                    ),
                    child: Icon(data.icon, color: data.color, size: 18),
                  ),
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: AppColors.surface,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: AppColors.border),
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
                            fontSize: 10,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const Spacer(),
              // Title + subtitle
              Text(
                data.title,
                style: AppTypography.titleSmall.copyWith(
                  fontWeight: FontWeight.w700,
                  height: 1.3,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 3),
              Text(
                data.subtitle,
                style: AppTypography.labelSmall.copyWith(
                  color: data.color,
                  fontWeight: FontWeight.w600,
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

// ─── E-LEARNING SECTION ───────────────────────────────────────────────────────

class _ElearningSection extends StatelessWidget {
  final Future<List<Course>> coursesFuture;
  final VoidCallback onCatalog;
  final void Function(Course) onCourseTap;

  const _ElearningSection({
    required this.coursesFuture,
    required this.onCatalog,
    required this.onCourseTap,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _SectionHeader(
          title: 'Apprendre',
          badge: 'E-Learning',
          accentColor: AppColors.categoryTechnology,
          actionLabel: 'Catalogue',
          onAction: onCatalog,
        ),
        const SizedBox(height: 14),
        FutureBuilder<List<Course>>(
          future: coursesFuture,
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
                child: _ElearningCTACard(onTap: onCatalog),
              );
            }

            return SizedBox(
              height: 162,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                physics: const BouncingScrollPhysics(),
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.pagePaddingHorizontal,
                ),
                itemCount: courses.take(5).length,
                separatorBuilder: (_, __) => const SizedBox(width: 12),
                itemBuilder: (context, index) {
                  final course = courses.elementAt(index);
                  return SizedBox(
                    width: 220,
                    child: CourseCard(
                      course: course,
                      mode: CourseCardMode.compact,
                      onTap: () => onCourseTap(course),
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
                AppColors.primary.withValues(alpha: 0.05),
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
                  color: AppColors.categoryTechnology.withValues(alpha: 0.12),
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
                      'Découvrez nos cours',
                      style: AppTypography.titleSmall.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Vidéos, quiz, articles & hackathons',
                      style: AppTypography.bodySmall,
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

// ─── SCHOOLS SECTION ──────────────────────────────────────────────────────────

class _SchoolsSection extends StatelessWidget {
  final VoidCallback onViewAll;
  const _SchoolsSection({required this.onViewAll});

  @override
  Widget build(BuildContext context) {
    final schools = [
      _SchoolPreview(
        name: 'Université de Lomé',
        shortName: 'UL',
        location: 'Lomé, Togo',
        programs: '120+ filières',
        color: AppColors.primary,
      ),
      _SchoolPreview(
        name: 'UK (Kara)',
        shortName: 'UK',
        location: 'Kara, Togo',
        programs: '85+ filières',
        color: AppColors.categoryTechnology,
      ),
      _SchoolPreview(
        name: 'ESIBA',
        shortName: 'ES',
        location: 'Lomé, Togo',
        programs: '25+ filières',
        color: AppColors.secondary,
      ),
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _SectionHeader(
          title: 'Établissements',
          accentColor: AppColors.success,
          actionLabel: 'Annuaire',
          onAction: onViewAll,
        ),
        const SizedBox(height: 14),
        SizedBox(
          height: 150,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            physics: const BouncingScrollPhysics(),
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.pagePaddingHorizontal,
            ),
            itemCount: schools.length,
            separatorBuilder: (_, __) => const SizedBox(width: 12),
            itemBuilder: (context, index) => _SchoolCard(
              school: schools[index],
              onTap: onViewAll,
            ),
          ),
        ),
      ],
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
              Row(
                children: [
                  Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color: school.color.withValues(alpha: 0.10),
                      shape: BoxShape.circle,
                    ),
                    child: Center(
                      child: Text(
                        school.shortName,
                        style: AppTypography.titleSmall.copyWith(
                          fontWeight: FontWeight.w800,
                          color: school.color,
                          fontSize: 14,
                        ),
                      ),
                    ),
                  ),
                  const Spacer(),
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: AppColors.secondarySurface,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      school.programs,
                      style: AppTypography.badgeText.copyWith(
                        color: AppColors.secondaryDark,
                      ),
                    ),
                  ),
                ],
              ),
              const Spacer(),
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
                  Icon(Iconsax.location, size: 11, color: school.color),
                  const SizedBox(width: 4),
                  Expanded(
                    child: Text(
                      school.location,
                      style: AppTypography.labelSmall,
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
