import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:iconsax/iconsax.dart';
import 'package:shimmer/shimmer.dart';

import '../../../../core/constants/constants.dart';
import '../../../../core/di/injection_container.dart';
import '../../../../shared/widgets/buttons/gradient_button.dart';
import '../../../../shared/widgets/feedback/app_snackbar.dart';
import '../../domain/entities/course.dart';
import '../bloc/course_bloc.dart';
import '../widgets/course_card.dart' show colorForCategory, iconForCategory;
import '../widgets/lesson_type_badge.dart';

// Widgets prives extraits en parts (meme librairie, imports partages).
part 'course_detail/hero_section.dart';
part 'course_detail/info_sections.dart';
part 'course_detail/module_section.dart';
part 'course_detail/bottom_and_states.dart';

class CourseDetailPage extends StatelessWidget {
  final String courseId;
  final Course? initialCourse;

  const CourseDetailPage({
    super.key,
    required this.courseId,
    this.initialCourse,
  });

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => getIt<CourseBloc>()..add(LoadCourse(courseId)),
      child: _CourseDetailView(
        courseId: courseId,
        initialCourse: initialCourse,
      ),
    );
  }
}

class _CourseDetailView extends StatelessWidget {
  final String courseId;
  final Course? initialCourse;

  const _CourseDetailView({required this.courseId, this.initialCourse});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: BlocConsumer<CourseBloc, CourseState>(
        listener: (context, state) {
          if (state is CourseEnrolled) {
            AppSnackbar.success(context, 'Inscription réussie !');
          }
          if (state is CourseAuthRequired) {
            AppSnackbar.info(
              context,
              'Connectez-vous pour vous inscrire à ce cours',
              actionLabel: 'Se connecter',
              onAction: () => context.go('/login'),
            );
          }
          if (state is CourseError) {
            AppSnackbar.error(context, state.message);
          }
        },
        builder: (context, state) {
          if (state is CourseLoading) return const _DetailShimmer();

          if (state is CourseError && state is! CourseLoaded) {
            return _DetailError(
              message: state.message,
              // Fix : on relance avec le VRAI courseId, pas le message d'erreur
              // (l'ancien code passait state.message → /courses/{erreur} → 422).
              onRetry: () =>
                  context.read<CourseBloc>().add(LoadCourse(courseId)),
              onBack: () => context.pop(),
            );
          }

          CourseDetail? course;
          bool isEnrolling = false;

          if (state is CourseLoaded) course = state.course;
          if (state is CourseEnrolling) {
            course = state.course;
            isEnrolling = true;
          }
          if (state is CourseEnrolled) course = state.course;
          // Auth requise : on garde le detail affiche derriere le snackbar.
          if (state is CourseAuthRequired) course = state.course;

          if (course == null) return const _DetailShimmer();

          return _CourseBody(course: course, isEnrolling: isEnrolling);
        },
      ),
    );
  }
}

// ─── Main Body ────────────────────────────────────────────────────────────────

class _CourseBody extends StatelessWidget {
  final CourseDetail course;
  final bool isEnrolling;

  const _CourseBody({required this.course, required this.isEnrolling});

  @override
  Widget build(BuildContext context) {
    final color = colorForCategory(course.category);

    return Stack(
      children: [
        CustomScrollView(
          physics: const BouncingScrollPhysics(),
          slivers: [
            // ── Immersive Hero App Bar ──
            _HeroAppBar(course: course, color: color),

            // ── Content ──
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 24, 20, 0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Stats strip
                    _StatsStrip(course: course, color: color),
                    const SizedBox(height: 20),

                    // Title
                    Text(
                      course.title,
                      style: AppTypography.headlineSmall.copyWith(
                        fontWeight: FontWeight.w800,
                        letterSpacing: -0.4,
                        height: 1.2,
                      ),
                    ),
                    const SizedBox(height: 18),

                    // Description
                    _DescriptionSection(description: course.description),

                    // Progression si inscrit
                    if (course.isEnrolled && course.progressPct != null) ...[
                      const SizedBox(height: 16),
                      _ProgressBanner(
                        progressPct: course.progressPct!,
                        color: color,
                      ),
                    ],

                    const SizedBox(height: 28),

                    // Programme header
                    Row(
                      children: [
                        Text(
                          'Programme',
                          style: AppTypography.titleLarge.copyWith(
                            fontWeight: FontWeight.w800,
                            letterSpacing: -0.3,
                          ),
                        ),
                        const Spacer(),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 9, vertical: 4),
                          decoration: BoxDecoration(
                            color: color.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            '${course.modules.length} modules',
                            style: TextStyle(
                              fontSize: 11.5,
                              fontWeight: FontWeight.w700,
                              color: color,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 14),
                  ],
                ),
              ),
            ),

            // ── Modules ──
            SliverList(
              delegate: SliverChildBuilderDelegate(
                (context, index) {
                  final module = course.modules[index];
                  return _ModuleCard(
                    module: module,
                    moduleIndex: index,
                    totalModules: course.modules.length,
                    color: color,
                    onLessonTap: (lesson) {
                      if (!module.isLocked || lesson.isFree) {
                        context.push('/elearning/lesson/${lesson.id}');
                      }
                    },
                  );
                },
                childCount: course.modules.length,
              ),
            ),

            // Space for fixed bottom button
            const SliverToBoxAdapter(child: SizedBox(height: 108)),
          ],
        ),

        // ── Fixed bottom action ──
        Positioned(
          left: 0,
          right: 0,
          bottom: 0,
          child: _BottomAction(
            course: course,
            isEnrolling: isEnrolling,
            color: color,
            onEnroll: () =>
                context.read<CourseBloc>().add(EnrollCourse(course.id)),
          ),
        ),
      ],
    );
  }
}
