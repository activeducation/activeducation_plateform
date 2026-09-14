import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:iconsax/iconsax.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../../core/constants/constants.dart';
import '../../../../core/di/injection_container.dart';
import '../../../gamification/presentation/cubit/gamification_cubit.dart';
import '../../../../shared/widgets/buttons/gradient_button.dart';
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
      child: _LessonView(lessonId: lessonId),
    );
  }
}

/// Lecon inaccessible (connexion requise ou erreur) : message lisible et une
/// action principale, plutot que le toString() technique de l'exception.
class _LessonBlockedView extends StatelessWidget {
  final IconData icon;
  final bool isError;
  final String title;
  final String message;
  final String actionLabel;
  final IconData actionIcon;
  final VoidCallback onAction;

  const _LessonBlockedView({
    required this.icon,
    required this.isError,
    required this.title,
    required this.message,
    required this.actionLabel,
    required this.actionIcon,
    required this.onAction,
  });

  @override
  Widget build(BuildContext context) {
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
                  color:
                      isError ? AppColors.errorLight : AppColors.primarySurface,
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  icon,
                  size: 32,
                  color: isError ? AppColors.error : AppColors.primary,
                ),
              ),
              const SizedBox(height: 16),
              Text(
                title,
                style: AppTypography.titleSmall.copyWith(
                  fontWeight: FontWeight.w600,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 6),
              Text(
                message,
                style: AppTypography.bodyMedium
                    .copyWith(color: AppColors.textSecondary),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 20),
              GradientButton(
                text: actionLabel,
                icon: actionIcon,
                showArrow: false,
                isSmall: true,
                width: 180,
                onPressed: onAction,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _LessonView extends StatelessWidget {
  final String lessonId;

  const _LessonView({required this.lessonId});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<LessonBloc, LessonState>(
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

        if (state is LessonAuthRequired) {
          return _LessonBlockedView(
            icon: Iconsax.lock_1,
            isError: false,
            title: 'Connexion requise',
            message:
                'Connectez-vous pour accéder à cette leçon et suivre votre progression.',
            actionLabel: 'Se connecter',
            actionIcon: Iconsax.login,
            onAction: () => context.go('/login'),
          );
        }

        if (state is LessonError) {
          return _LessonBlockedView(
            icon: Iconsax.warning_2,
            isError: true,
            title: 'Leçon indisponible',
            message: state.message,
            actionLabel: 'Réessayer',
            actionIcon: Iconsax.refresh,
            onAction: () =>
                context.read<LessonBloc>().add(LoadLesson(lessonId)),
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

