import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:iconsax/iconsax.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../../core/constants/constants.dart';
import '../../../../core/di/injection_container.dart';
import '../../../gamification/presentation/cubit/gamification_cubit.dart';
import '../../../../shared/widgets/buttons/gradient_button.dart';
import '../../../../shared/widgets/feedback/app_snackbar.dart';
import '../../domain/entities/course.dart';
import '../bloc/lesson_bloc.dart';
import '../widgets/lesson_type_badge.dart';
import '../widgets/quiz_widget.dart';

// Widgets prives extraits en parts (meme librairie, imports partages).
part 'lesson/content_section.dart';
part 'lesson/content_types.dart';
part 'lesson/completion_section.dart';

class LessonPage extends StatelessWidget {
  final String lessonId;

  const LessonPage({super.key, required this.lessonId});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) =>
          getIt<LessonBloc>()..add(LoadLesson(lessonId)),
      child: const _LessonView(),
    );
  }
}

class _LessonView extends StatelessWidget {
  const _LessonView();

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<LessonBloc, LessonState>(
      listener: (context, state) {
        if (state is LessonError) {
          AppSnackbar.error(context, state.message);
        }
      },
      builder: (context, state) {
        if (state is LessonLoading) {
          return Scaffold(
            backgroundColor: AppColors.background,
            appBar: AppBar(
              backgroundColor: AppColors.background,
              elevation: 0,
              leading: IconButton(
                icon: const Icon(Icons.arrow_back_rounded),
                onPressed: () => context.pop(),
              ),
            ),
            body: const Center(
              child: CircularProgressIndicator(
                color: AppColors.primary,
                strokeWidth: 2.5,
              ),
            ),
          );
        }

        if (state is LessonError) {
          return Scaffold(
            backgroundColor: AppColors.background,
            appBar: AppBar(
              backgroundColor: AppColors.background,
              elevation: 0,
              leading: IconButton(
                icon: const Icon(Icons.arrow_back_rounded),
                onPressed: () => context.pop(),
              ),
            ),
            body: Center(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 40),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      width: 72,
                      height: 72,
                      decoration: BoxDecoration(
                        color: AppColors.errorLight,
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Iconsax.warning_2,
                          size: 32, color: AppColors.error),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      state.message,
                      style: AppTypography.bodyMedium,
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
            ),
          );
        }

        if (state is LessonCompleted) {
          return _LessonCompletedView(
            pointsEarned: state.pointsEarned,
            courseProgressPct: state.courseProgressPct,
            onBack: () => context.pop(),
          );
        }

        LessonDetail? lesson;
        bool isCompleting = false;

        if (state is LessonLoaded) lesson = state.lesson;
        if (state is LessonCompleting) {
          lesson = state.lesson;
          isCompleting = true;
        }

        if (lesson == null) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        return _LessonContent(
          lesson: lesson,
          isCompleting: isCompleting,
        );
      },
    );
  }
}

