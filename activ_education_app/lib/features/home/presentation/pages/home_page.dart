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
import '../../../orientation/domain/entities/orientation_test.dart';
import '../../../orientation/domain/usecases/get_orientation_tests.dart';

/// Page d'accueil de l'application ActivEducation
class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  late final Future<List<OrientationTest>> _testsFuture;

  @override
  void initState() {
    super.initState();
    _testsFuture = _loadTests();
  }

  Future<List<OrientationTest>> _loadTests() async {
    final result = await getIt<GetOrientationTests>()();
    return result.fold((error) {
      debugPrint('[HomePage] Erreur chargement tests: $error');
      return <OrientationTest>[];
    }, (tests) => tests);
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
          child: Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.pagePaddingHorizontal,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: AppSpacing.md),
                _buildHeader(context),
                const SizedBox(height: AppSpacing.lg),
                const CustomSearchBar(
                  hintText: 'Chercher une \u00e9cole, un m\u00e9tier...',
                ),
                const SizedBox(height: AppSpacing.lg),
                _buildOrientationCTA(context),
                const SizedBox(height: AppSpacing.xl),
                _buildTestsSection(context),
                const SizedBox(height: AppSpacing.xl),
                _buildSchoolsSection(context),
                const SizedBox(height: AppSpacing.pagePaddingBottom),
              ],
            ),
          ),
        ),
      ),
    );
  }

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
                    'Bonjour, $firstName',
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
                // Notification icon with orange dot badge
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
                // Avatar with blue->orange gradient
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

  Widget _buildOrientationCTA(BuildContext context) {
    return Stack(
      children: [
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(AppSpacing.lg),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [Color(0xFF1060CF), Color(0xFF3B49DF)],
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
              const SizedBox(height: AppSpacing.md),
              Text(
                'R\u00e9ponds \u00e0 nos tests d\'orientation pour trouver la voie qui te correspond.',
                style: AppTypography.bodyMedium.copyWith(
                  color: Colors.white.withValues(alpha: 0.9),
                ),
              ),
              const SizedBox(height: AppSpacing.lg),
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
                      const Icon(Icons.arrow_forward, size: 18),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
        // "Nouveau" orange badge in top-right
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

  Widget _buildTestsSection(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Tests d\'orientation',
              style: AppTypography.titleLarge.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            TextButton(
              onPressed: () => context.go('/orientation'),
              child: Text(
                'Voir tout',
                style: AppTypography.labelMedium.copyWith(
                  color: AppColors.primary,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.md),
        FutureBuilder<List<OrientationTest>>(
          future: _testsFuture,
          builder: (context, snapshot) {
            if (!snapshot.hasData) {
              return const Padding(
                padding: EdgeInsets.symmetric(vertical: AppSpacing.lg),
                child: Center(child: CircularProgressIndicator()),
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
                  border: Border.all(color: AppColors.border),
                ),
                child: Text(
                  'Aucun test disponible pour le moment.',
                  style: AppTypography.bodyMedium.copyWith(
                    color: AppColors.textSecondary,
                  ),
                ),
              );
            }

            final cards = tests
                .take(4)
                .map(
                  (test) => _TestCardData(
                    test: test,
                    title: test.name,
                    subtitle: _subtitleFromType(test.type),
                    icon: _iconFromType(test.type),
                    color: _colorFromType(test.type),
                    duration: '${test.durationMinutes} min',
                  ),
                )
                .toList();

            return GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                crossAxisSpacing: 12,
                mainAxisSpacing: 12,
                childAspectRatio: 1.2,
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
        return AppColors.primary;
      case TestType.personality:
        return AppColors.secondary;
      case TestType.skills:
        return AppColors.success;
      case TestType.interests:
        return AppColors.categoryTechnology;
      case TestType.aptitude:
        return AppColors.warning;
    }
  }

  Widget _buildSchoolsSection(BuildContext context) {
    final schools = [
      _SchoolPreview(
        name: 'Universit\u00e9 de Lom\u00e9',
        location: 'Lom\u00e9, Togo',
        programs: '120+ fili\u00e8res',
      ),
      _SchoolPreview(
        name: 'UK (Kara)',
        location: 'Kara, Togo',
        programs: '85+ fili\u00e8res',
      ),
      _SchoolPreview(
        name: 'ESIBA',
        location: 'Lom\u00e9, Togo',
        programs: '25+ fili\u00e8res',
      ),
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              '\u00c9tablissements',
              style: AppTypography.titleLarge.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            TextButton(
              onPressed: () => context.go('/schools'),
              child: Text(
                'Voir tout',
                style: AppTypography.labelMedium.copyWith(
                  color: AppColors.primary,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.md),
        SizedBox(
          height: 170,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            itemCount: schools.length,
            separatorBuilder: (_, index) => const SizedBox(width: 12),
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
        child: Stack(
          children: [
            Container(
              padding: const EdgeInsets.only(
                left: AppSpacing.md + 3, // extra space for the color strip
                top: AppSpacing.md,
                right: AppSpacing.md,
                bottom: AppSpacing.md,
              ),
              decoration: BoxDecoration(
                color: data.color.withValues(alpha: 0.04),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppColors.border, width: 1),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: data.color.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Icon(data.icon, color: data.color, size: 22),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 3,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.surface,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          data.duration,
                          style: AppTypography.labelSmall.copyWith(
                            color: AppColors.textSecondary,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ],
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        data.title,
                        style: AppTypography.titleSmall.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      Text(
                        data.subtitle,
                        style: AppTypography.labelSmall.copyWith(
                          color: AppColors.textTertiary,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 6),
                      // Progress bar
                      ClipRRect(
                        borderRadius: BorderRadius.circular(4),
                        child: LinearProgressIndicator(
                          value: 0.0,
                          minHeight: 3,
                          backgroundColor: data.color.withValues(alpha: 0.1),
                          valueColor: AlwaysStoppedAnimation<Color>(data.color),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            // Left color accent strip
            Positioned(
              left: 0,
              top: 0,
              bottom: 0,
              child: Container(
                width: 4,
                decoration: BoxDecoration(
                  color: data.color,
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(16),
                    bottomLeft: Radius.circular(16),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SchoolPreview {
  final String name;
  final String location;
  final String programs;

  const _SchoolPreview({
    required this.name,
    required this.location,
    required this.programs,
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
          width: 220,
          padding: const EdgeInsets.all(AppSpacing.md),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [Colors.white, Color(0xFFF0F5FF)],
            ),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppColors.border),
            boxShadow: AppColors.cardShadow,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          AppColors.primarySurface,
                          AppColors.primary.withValues(alpha: 0.15),
                        ],
                      ),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(
                      Iconsax.building,
                      color: AppColors.primary,
                      size: 24,
                    ),
                  ),
                  // Orange badge for programs count
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 3,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.secondarySurface,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: AppColors.secondary.withValues(alpha: 0.3),
                      ),
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
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    school.name,
                    style: AppTypography.titleSmall.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 2),
                  Row(
                    children: [
                      const Icon(
                        Iconsax.location,
                        size: 12,
                        color: AppColors.textTertiary,
                      ),
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
            ],
          ),
        ),
      ),
    );
  }
}
