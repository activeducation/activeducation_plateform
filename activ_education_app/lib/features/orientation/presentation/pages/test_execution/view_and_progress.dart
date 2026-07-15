// Partie de test_execution_page.dart (refacto : page de 1050 lignes
// decoupee en parts pour la lisibilite). Widgets prives partages,
// imports herites de la librairie principale.
//
// Vue principale du test + barre de progression segmentee + transition de section.
part of '../test_execution_page.dart';

class _TestExecutionView extends StatelessWidget {
  const _TestExecutionView();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.close),
          onPressed: () => _showQuitDialog(context),
        ),
        title: BlocBuilder<TestSessionBloc, TestSessionState>(
          builder: (context, state) {
            if (state is TestSessionInProgress) {
              return Column(
                children: [
                  Text(
                    'Question ${state.currentQuestionIndex + 1}/${state.test.questions.length}',
                    style: AppTypography.titleMedium,
                  ),
                  if (state.sections.length > 1)
                    Text(
                      state.currentSection.title,
                      style: AppTypography.labelSmall.copyWith(
                        color: AppColors.textTertiary,
                      ),
                    ),
                ],
              );
            }
            return const SizedBox.shrink();
          },
        ),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(8),
          child: BlocBuilder<TestSessionBloc, TestSessionState>(
            builder: (context, state) {
              if (state is TestSessionInProgress) {
                return _SegmentedProgressBar(
                  sections: state.sections,
                  currentIndex: state.currentQuestionIndex,
                  totalQuestions: state.test.questions.length,
                );
              }
              return const SizedBox.shrink();
            },
          ),
        ),
      ),
      body: Container(
        decoration: const BoxDecoration(
          gradient: AppColors.backgroundGradient,
        ),
        child: BlocConsumer<TestSessionBloc, TestSessionState>(
          listener: (context, state) {
            if (state is TestSessionReadyToSubmit) {
              context.read<OrientationBloc>().add(
                    SubmitTestEvent(state.test.id, state.responses),
                  );
            }
          },
          builder: (context, state) {
            return BlocListener<OrientationBloc, OrientationState>(
              listener: (context, state) {
                if (state is TestCompleted) {
                  context.pushReplacement('/orientation/results', extra: state.result);
                } else if (state is OrientationError) {
                  AppSnackbar.error(context, state.message);
                }
              },
              child: _buildBody(context, state),
            );
          },
        ),
      ),
    );
  }

  Widget _buildBody(BuildContext context, TestSessionState state) {
    if (state is TestSessionInProgress) {
      return SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.pagePaddingHorizontal),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: AppSpacing.md),
              Expanded(
                child: AnimatedSwitcher(
                  duration: AppSpacing.animationNormal,
                  switchInCurve: Curves.easeOutCubic,
                  switchOutCurve: Curves.easeInCubic,
                  transitionBuilder: (child, animation) {
                    return SlideTransition(
                      position: Tween<Offset>(
                        begin: const Offset(0.3, 0),
                        end: Offset.zero,
                      ).animate(animation),
                      child: FadeTransition(
                        opacity: animation,
                        child: child,
                      ),
                    );
                  },
                  child: _QuestionCard(
                    key: ValueKey(state.currentQuestionIndex),
                    question: state.currentQuestion,
                  ),
                ),
              ),
              const SizedBox(height: AppSpacing.md),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  if (state.canGoBack)
                    TextButton.icon(
                      onPressed: () {
                        context.read<TestSessionBloc>().add(PreviousQuestion());
                      },
                      icon: const Icon(Icons.arrow_back),
                      label: const Text('RETOUR'),
                    )
                  else
                    const SizedBox.shrink(),
                  GradientButton(
                    text: state.isLastQuestion ? 'Terminer' : 'Suivant',
                    onPressed: state.canGoNext
                        ? () {
                            context.read<TestSessionBloc>().add(NextQuestion());
                          }
                        : null,
                    showArrow: !state.isLastQuestion,
                    useSecondaryColor: state.isLastQuestion,
                    width: 140,
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.lg),
            ],
          ),
        ),
      );
    }

    if (state is TestSessionSectionComplete) {
      return _SectionTransition(
        sectionTitle: state.sectionTitle,
        feedbackMessage: state.feedbackMessage,
        sectionIndex: state.completedSectionIndex,
        totalSections: state.sections.length,
        onContinue: () {
          context.read<TestSessionBloc>().add(ContinueFromSection());
        },
      );
    }

    if (state is TestSessionReadyToSubmit) {
      // TestSessionReadyToSubmit est un etat TERMINAL du TestSessionBloc : il ne
      // changera plus. C'est donc l'OrientationBloc (via BlocBuilder, reactif)
      // qui doit decider ce qu'on affiche, sinon un echec de soumission laisse
      // l'eleve bloque indefiniment sur le spinner avec ses reponses perdues.
      return BlocBuilder<OrientationBloc, OrientationState>(
        builder: (context, submitState) {
          if (submitState is OrientationError) {
            return ErrorView(
              message: submitState.message,
              onRetry: () => context.read<OrientationBloc>().add(
                    SubmitTestEvent(state.test.id, state.responses),
                  ),
            );
          }
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const CircularProgressIndicator(color: AppColors.primary),
                const SizedBox(height: AppSpacing.lg),
                Text(
                  'Analyse de ton profil...',
                  style: AppTypography.titleMedium,
                ),
                const SizedBox(height: AppSpacing.sm),
                Text(
                  'On prépare tes résultats !',
                  style: AppTypography.bodyMedium.copyWith(color: AppColors.textTertiary),
                ),
              ],
            ).animate().fadeIn(duration: 400.ms).scale(begin: const Offset(0.8, 0.8)),
          );
        },
      );
    }

    return const SizedBox.shrink();
  }

  void _showQuitDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (c) => AlertDialog(
        title: const Text('Quitter le test ?'),
        content: const Text('Ta progression sera perdue.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(c),
            child: const Text('ANNULER'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(c);
              context.pop();
            },
            child: const Text('QUITTER'),
          ),
        ],
      ),
    );
  }
}

// ============================================
// SEGMENTED PROGRESS BAR
// ============================================
class _SegmentedProgressBar extends StatelessWidget {
  final List<SectionInfo> sections;
  final int currentIndex;
  final int totalQuestions;

  const _SegmentedProgressBar({
    required this.sections,
    required this.currentIndex,
    required this.totalQuestions,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
      child: Row(
        children: sections.asMap().entries.map((entry) {
          final i = entry.key;
          final section = entry.value;
          final sectionLength = section.endIndex - section.startIndex + 1;
          final flex = sectionLength;

          double sectionProgress;
          if (currentIndex > section.endIndex) {
            sectionProgress = 1.0;
          } else if (currentIndex < section.startIndex) {
            sectionProgress = 0.0;
          } else {
            sectionProgress = (currentIndex - section.startIndex + 1) / sectionLength;
          }

          return Expanded(
            flex: flex,
            child: Padding(
              padding: EdgeInsets.only(right: i < sections.length - 1 ? 3 : 0),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(4),
                child: LinearProgressIndicator(
                  value: sectionProgress,
                  backgroundColor: AppColors.surfaceLight,
                  color: _getSectionColor(i),
                  minHeight: 6,
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  Color _getSectionColor(int index) {
    const colors = [
      AppColors.primary,
      AppColors.accent,
      AppColors.secondary,
      AppColors.success,
      AppColors.warning,
      AppColors.info,
    ];
    return colors[index % colors.length];
  }
}

// ============================================
// SECTION TRANSITION SCREEN
// ============================================
class _SectionTransition extends StatelessWidget {
  final String sectionTitle;
  final String feedbackMessage;
  final int sectionIndex;
  final int totalSections;
  final VoidCallback onContinue;

  const _SectionTransition({
    required this.sectionTitle,
    required this.feedbackMessage,
    required this.sectionIndex,
    required this.totalSections,
    required this.onContinue,
  });

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.pagePaddingHorizontal),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(AppSpacing.cardPaddingLarge),
              decoration: BoxDecoration(
                gradient: AppColors.cardGradient,
                borderRadius: BorderRadius.circular(AppSpacing.cardRadiusLarge),
                border: Border.all(color: AppColors.primaryLight.withValues(alpha: 0.3)),
                boxShadow: AppColors.glowShadow,
              ),
              child: Column(
                children: [
                  Text(
                    _getSectionEmoji(),
                    style: const TextStyle(fontSize: 48),
                  ).animate().scale(
                    begin: const Offset(0, 0),
                    end: const Offset(1, 1),
                    duration: 600.ms,
                    curve: Curves.elasticOut,
                  ),
                  const SizedBox(height: AppSpacing.lg),
                  Text(
                    'Super !',
                    style: AppTypography.headlineMedium.copyWith(
                      color: AppColors.accent,
                    ),
                  ).animate().fadeIn(delay: 200.ms, duration: 400.ms),
                  const SizedBox(height: AppSpacing.md),
                  Text(
                    feedbackMessage,
                    style: AppTypography.bodyLarge.copyWith(
                      color: AppColors.textSecondary,
                    ),
                    textAlign: TextAlign.center,
                  ).animate().fadeIn(delay: 400.ms, duration: 400.ms),
                  const SizedBox(height: AppSpacing.xl),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.arrow_forward, color: AppColors.primary, size: 18),
                      const SizedBox(width: AppSpacing.xs),
                      Text(
                        'Passons à : $sectionTitle',
                        style: AppTypography.titleMedium.copyWith(
                          color: AppColors.primary,
                        ),
                      ),
                    ],
                  ).animate().fadeIn(delay: 600.ms, duration: 400.ms),
                  const SizedBox(height: AppSpacing.lg),
                  Text(
                    'Section ${sectionIndex + 2} / $totalSections',
                    style: AppTypography.labelSmall,
                  ).animate().fadeIn(delay: 700.ms, duration: 400.ms),
                ],
              ),
            ).animate().fadeIn(duration: 400.ms).slideY(begin: 0.1),
            const SizedBox(height: AppSpacing.xxl),
            GradientButton(
              text: 'Continuer',
              onPressed: onContinue,
              showArrow: true,
            ).animate().fadeIn(delay: 800.ms, duration: 400.ms).slideY(begin: 0.2),
          ],
        ),
      ),
    );
  }

  String _getSectionEmoji() {
    final emojis = ['🎯', '🧠', '💎', '🪞', '📚', '🚀', '⚡', '🎨'];
    return emojis[sectionIndex % emojis.length];
  }
}
