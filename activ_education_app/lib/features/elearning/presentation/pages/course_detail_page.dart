import 'dart:ui';
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

    // Flatten modules into nodes for roadmap
    final nodes = <dynamic>[];
    for (int i = 0; i < course.modules.length; i++) {
      nodes.add({'type': 'module', 'module': course.modules[i], 'index': i});
      for (int j = 0; j < course.modules[i].lessons.length; j++) {
        nodes.add({
          'type': 'lesson', 
          'lesson': course.modules[i].lessons[j], 
          'index': j, 
          'isLocked': course.modules[i].isLocked
        });
      }
    }

    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 800),
        child: Stack(
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
                              'Feuille de route',
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
                                '${course.modules.length} étapes',
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

                // ── Gamified Roadmap ──
                SliverList(
                  delegate: SliverChildBuilderDelegate(
                    (context, index) {
                      final node = nodes[index];
                      if (node['type'] == 'module') {
                        return _RoadmapModuleNode(
                          module: node['module'] as CourseModule,
                          index: node['index'] as int,
                          color: color,
                        );
                      } else {
                        final lesson = node['lesson'] as LessonSummary;
                        final isModuleLocked = node['isLocked'] as bool;
                        final isLast = index == nodes.length - 1 || nodes[index + 1]['type'] == 'module';
                        
                        return _RoadmapLessonNode(
                          lesson: lesson,
                          index: node['index'] as int,
                          isModuleLocked: isModuleLocked,
                          color: color,
                          isLast: isLast,
                          onTap: () async {
                            if (!isModuleLocked || lesson.isFree) {
                              await context.push('/elearning/lesson/${lesson.id}');
                              if (context.mounted) {
                                context.read<CourseBloc>().add(LoadCourse(course.id));
                              }
                            }
                          },
                        );
                      }
                    },
                    childCount: nodes.length,
                  ),
                ),

                // Space for fixed bottom button (+ inset bas, cf. SafeArea de la carte)
                SliverToBoxAdapter(
                  child: SizedBox(
                    height: _kBottomActionReservedHeight +
                        MediaQuery.paddingOf(context).bottom,
                  ),
                ),
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
        ),
      ),
    );
  }
}
