import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:iconsax/iconsax.dart';

import '../../../../core/constants/constants.dart';
import '../../../../core/di/injection_container.dart';
import '../../../../shared/widgets/buttons/gradient_button.dart';
import '../../../../shared/widgets/feedback/app_snackbar.dart';

/// Ecran d'examen QCM d'un cours. Charge l'examen, recueille les reponses,
/// soumet et affiche le resultat (badge si >= score de passage).
class CourseExamPage extends StatefulWidget {
  final String courseId;
  const CourseExamPage({super.key, required this.courseId});

  @override
  State<CourseExamPage> createState() => _CourseExamPageState();
}

class _CourseExamPageState extends State<CourseExamPage> {
  Map<String, dynamic>? _exam;
  final Map<String, int> _answers = {}; // questionId -> option index
  bool _loading = true;
  bool _submitting = false;
  String? _error;
  Map<String, dynamic>? _result;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() { _loading = true; _error = null; });
    try {
      final dio = getIt<Dio>(instanceName: 'apiClient');
      final res = await dio.get(ApiEndpoints.elearningCourseExam(widget.courseId));
      setState(() { _exam = Map<String, dynamic>.from(res.data); _loading = false; });
    } on DioException catch (e) {
      setState(() {
        _loading = false;
        _error = e.response?.statusCode == 404
            ? "Aucun examen n'est disponible pour ce cours."
            : "Impossible de charger l'examen.";
      });
    } catch (_) {
      setState(() { _loading = false; _error = "Impossible de charger l'examen."; });
    }
  }

  Future<void> _submit() async {
    final questions = (_exam?['questions'] as List?) ?? [];
    if (_answers.length < questions.length) {
      AppSnackbar.info(context, 'Répondez à toutes les questions.');
      return;
    }
    setState(() => _submitting = true);
    try {
      final dio = getIt<Dio>(instanceName: 'apiClient');
      final res = await dio.post(
        ApiEndpoints.elearningCourseExamSubmit(widget.courseId),
        data: {'answers': _answers},
      );
      setState(() => _result = Map<String, dynamic>.from(res.data));
    } catch (e) {
      if (mounted) {
        AppSnackbar.error(context, 'Échec de la soumission. Réessayez.');
      }
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

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
        title: Text(_exam?['title'] ?? 'Examen', style: AppTypography.titleMedium),
      ),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (_loading) return const Center(child: CircularProgressIndicator());
    if (_error != null) return _buildError();
    if (_result != null) return _buildResult();
    return _buildQuiz();
  }

  Widget _buildError() => Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Iconsax.info_circle, size: 48, color: AppColors.textTertiary),
              const SizedBox(height: 16),
              Text(_error!, style: AppTypography.bodyMedium, textAlign: TextAlign.center),
              const SizedBox(height: 20),
              GradientButton(text: 'Retour', showArrow: false, width: 160, onPressed: () => context.pop()),
            ],
          ),
        ),
      );

  Widget _buildQuiz() {
    final questions = (_exam?['questions'] as List?) ?? [];
    final passing = _exam?['passing_score'] ?? 80;
    return SingleChildScrollView(
      padding: const EdgeInsets.all(AppSpacing.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(children: [
              const Icon(Iconsax.medal_star, color: AppColors.primary),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  'Obtenez $passing% ou plus pour réussir et gagner votre badge.',
                  style: AppTypography.bodySmall,
                ),
              ),
            ]),
          ),
          const SizedBox(height: 16),
          ...questions.asMap().entries.map((e) => _buildQuestion(e.key, e.value)),
          const SizedBox(height: 8),
          GradientButton(
            text: _submitting ? 'Soumission...' : 'Soumettre mes réponses',
            icon: Iconsax.tick_circle,
            showArrow: false,
            onPressed: _submitting ? null : _submit,
          ),
          const SizedBox(height: 32),
        ],
      ),
    );
  }

  Widget _buildQuestion(int index, dynamic q) {
    final qid = q['id'].toString();
    final options = (q['options'] as List?) ?? [];
    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('${index + 1}. ${q['question']}',
              style: AppTypography.titleSmall.copyWith(fontWeight: FontWeight.w700)),
          const SizedBox(height: 10),
          ...options.asMap().entries.map((e) {
            final selected = _answers[qid] == e.key;
            return InkWell(
              onTap: () => setState(() => _answers[qid] = e.key),
              borderRadius: BorderRadius.circular(10),
              child: Container(
                margin: const EdgeInsets.only(bottom: 8),
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                decoration: BoxDecoration(
                  color: selected ? AppColors.primary.withValues(alpha: 0.1) : AppColors.surface,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                    color: selected ? AppColors.primary : AppColors.border,
                    width: selected ? 1.5 : 1,
                  ),
                ),
                child: Row(children: [
                  Icon(
                    selected ? Icons.radio_button_checked : Icons.radio_button_unchecked,
                    size: 20,
                    color: selected ? AppColors.primary : AppColors.textTertiary,
                  ),
                  const SizedBox(width: 10),
                  Expanded(child: Text(e.value['text'] ?? '', style: AppTypography.bodyMedium)),
                ]),
              ),
            );
          }),
        ],
      ),
    );
  }

  Widget _buildResult() {
    final r = _result!;
    final passed = r['passed'] == true;
    final score = r['score'] ?? 0;
    final badge = r['badge_earned'] == true;
    final xp = r['xp_awarded'] ?? 0;
    final color = passed ? AppColors.success : AppColors.error;

    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 110, height: 110,
              decoration: BoxDecoration(color: color.withValues(alpha: 0.12), shape: BoxShape.circle),
              child: Icon(
                passed ? Icons.emoji_events_rounded : Icons.refresh_rounded,
                size: 56, color: color,
              ),
            ),
            const SizedBox(height: 20),
            Text(passed ? 'Félicitations !' : 'Pas encore réussi',
                style: AppTypography.headlineSmall, textAlign: TextAlign.center),
            const SizedBox(height: 8),
            Text('Votre score : $score%',
                style: AppTypography.titleMedium.copyWith(color: color, fontWeight: FontWeight.w800)),
            const SizedBox(height: 16),
            if (passed && badge) ...[
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                decoration: BoxDecoration(
                  color: AppColors.xpGoldSurface,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: AppColors.xpGold.withValues(alpha: 0.4)),
                ),
                child: Row(mainAxisSize: MainAxisSize.min, children: [
                  Text(r['badge_icon'] ?? '🏅', style: const TextStyle(fontSize: 24)),
                  const SizedBox(width: 10),
                  Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisSize: MainAxisSize.min, children: [
                    Text('Badge débloqué', style: AppTypography.labelSmall.copyWith(color: AppColors.xpGoldDark)),
                    Text(r['badge_title'] ?? 'Cours réussi',
                        style: AppTypography.titleSmall.copyWith(fontWeight: FontWeight.w800)),
                  ]),
                ]),
              ),
              if (xp > 0) ...[
                const SizedBox(height: 10),
                Text('+$xp XP', style: AppTypography.titleSmall.copyWith(
                    color: AppColors.xpBar, fontWeight: FontWeight.w800)),
              ],
            ],
            if (!passed) ...[
              const SizedBox(height: 8),
              Text('Il faut ${r['passing_score'] ?? 80}% pour réussir. Révisez et réessayez !',
                  style: AppTypography.bodyMedium.copyWith(color: AppColors.textSecondary),
                  textAlign: TextAlign.center),
            ],
            const SizedBox(height: 28),
            Row(mainAxisAlignment: MainAxisAlignment.center, children: [
              if (!passed)
                OutlinedButton(
                  onPressed: () => setState(() { _result = null; _answers.clear(); }),
                  child: const Text('Réessayer'),
                ),
              if (!passed) const SizedBox(width: 12),
              GradientButton(
                text: passed ? 'Terminer' : 'Retour au cours',
                showArrow: false,
                width: 180,
                onPressed: () => context.pop(),
              ),
            ]),
          ],
        ),
      ),
    );
  }
}
