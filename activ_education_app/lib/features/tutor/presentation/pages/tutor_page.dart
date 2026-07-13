import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_typography.dart';
import '../../../../core/di/injection_container.dart';
import '../../data/datasources/tutor_remote_datasource.dart';
import '../bloc/quiz_bloc.dart';
import '../widgets/quiz_card.dart';

/// Page tuteur : l'élève choisit un sujet, AÏDA génère un quiz d'entraînement.
class TutorPage extends StatelessWidget {
  const TutorPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => QuizBloc(
        TutorRemoteDataSourceImpl(getIt<Dio>(instanceName: 'apiClient')),
      ),
      child: const _TutorView(),
    );
  }
}

class _TutorView extends StatefulWidget {
  const _TutorView();

  @override
  State<_TutorView> createState() => _TutorViewState();
}

class _TutorViewState extends State<_TutorView> {
  final _controller = TextEditingController();

  static const _suggestions = [
    'Les fractions',
    'La conjugaison du présent',
    'Le système solaire',
    'La photosynthèse',
    'Les triangles',
  ];

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _generate(String topic) {
    final t = topic.trim();
    if (t.isEmpty) return;
    FocusScope.of(context).unfocus();
    context.read<QuizBloc>().add(GenerateQuiz(t));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.card,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 20),
          color: AppColors.textSecondary,
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Row(
          children: [
            Container(
              width: 38,
              height: 38,
              decoration: BoxDecoration(
                gradient: AppColors.crossBrandGradient,
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(Icons.school_rounded, color: Colors.white, size: 22),
            ),
            const SizedBox(width: 10),
            Text(
              'Mon tuteur',
              style: AppTypography.titleSmall.copyWith(
                color: AppColors.textPrimary,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(height: 1, color: AppColors.border),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Text(
            'Sur quoi veux-tu t\'entraîner ?',
            style: AppTypography.titleSmall.copyWith(
              color: AppColors.textPrimary,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 12),
          _buildInput(),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: _suggestions.map((s) {
              return ActionChip(
                label: Text(
                  s,
                  style: AppTypography.labelSmall.copyWith(
                    color: AppColors.primary,
                    fontSize: 12,
                  ),
                ),
                backgroundColor: AppColors.primarySurface,
                side: BorderSide(color: AppColors.primary.withValues(alpha: 0.25)),
                onPressed: () {
                  _controller.text = s;
                  _generate(s);
                },
              );
            }).toList(),
          ),
          const SizedBox(height: 24),
          BlocBuilder<QuizBloc, QuizState>(
            builder: (context, state) {
              if (state is QuizLoading) {
                return _buildLoading();
              }
              if (state is QuizFailure) {
                return _buildError(state);
              }
              if (state is QuizReady) {
                return QuizCard(
                  quiz: state.quiz,
                  onRestart: () => context.read<QuizBloc>().add(const ResetQuiz()),
                );
              }
              return _buildEmpty();
            },
          ),
        ],
      ),
    );
  }

  Widget _buildInput() {
    return TextField(
      controller: _controller,
      textInputAction: TextInputAction.go,
      style: AppTypography.bodyMedium.copyWith(color: AppColors.textPrimary),
      decoration: InputDecoration(
        hintText: 'Un chapitre, une notion...',
        hintStyle: AppTypography.bodyMedium.copyWith(color: AppColors.textTertiary),
        filled: true,
        fillColor: AppColors.surface,
        prefixIcon: const Icon(Icons.edit_rounded, color: AppColors.textTertiary, size: 20),
        suffixIcon: IconButton(
          icon: const Icon(Icons.auto_awesome_rounded, color: AppColors.primary),
          tooltip: 'Générer un quiz',
          onPressed: () => _generate(_controller.text),
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: AppColors.border),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: AppColors.border),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: AppColors.primary, width: 1.5),
        ),
      ),
      onSubmitted: _generate,
    );
  }

  Widget _buildLoading() {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 40),
      alignment: Alignment.center,
      child: Column(
        children: [
          const CircularProgressIndicator(color: AppColors.primary),
          const SizedBox(height: 16),
          Text(
            'AÏDA prépare ton quiz...',
            style: AppTypography.bodyMedium.copyWith(color: AppColors.textSecondary),
          ),
        ],
      ),
    );
  }

  Widget _buildError(QuizFailure state) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.errorSurface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.error.withValues(alpha: 0.25)),
      ),
      child: Row(
        children: [
          const Icon(Icons.error_outline_rounded, color: AppColors.error),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              state.message,
              style: AppTypography.bodyMedium.copyWith(color: AppColors.textPrimary),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmpty() {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 40),
      alignment: Alignment.center,
      child: Column(
        children: [
          Icon(Icons.quiz_rounded, size: 56, color: AppColors.primary.withValues(alpha: 0.4)),
          const SizedBox(height: 12),
          Text(
            'Choisis un sujet pour commencer',
            style: AppTypography.bodyMedium.copyWith(color: AppColors.textTertiary),
          ),
        ],
      ),
    );
  }
}
