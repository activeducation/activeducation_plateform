// Partie de lesson_page.dart (refacto : page de 1231 lignes
// decoupee en parts pour la lisibilite). Widgets prives partages,
// imports herites de la librairie principale.
//
// Rendus par type : video, article, PDF, defi, markdown.
part of '../lesson_page.dart';


class _VideoContent extends StatelessWidget {
  final Map<String, dynamic> data;

  const _VideoContent({required this.data});

  @override
  Widget build(BuildContext context) {
    final videoUrl = data['url'] as String? ?? data['video_url'] as String?;
    final description =
        data['description'] as String? ?? data['content'] as String? ?? '';

    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (videoUrl != null) ...[
            Container(
              width: double.infinity,
              height: 200,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(14),
                gradient: AppColors.heroGradient,
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(14),
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    // Subtle pattern
                    Positioned.fill(
                      child: CustomPaint(
                        painter: _DotPatternPainter(),
                      ),
                    ),
                    Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Container(
                          width: 56,
                          height: 56,
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.2),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.play_arrow_rounded,
                            size: 32,
                            color: Colors.white,
                          ),
                        ),
                        const SizedBox(height: 14),
                        GradientButton(
                          text: 'Lire la vidéo',
                          icon: Iconsax.export_1,
                          isSmall: true,
                          width: 170,
                          showArrow: false,
                          useSecondaryColor: true,
                          onPressed: () async {
                            final uri = Uri.tryParse(videoUrl);
                            if (uri != null &&
                                await canLaunchUrl(uri)) {
                              await launchUrl(uri,
                                  mode: LaunchMode.externalApplication);
                            }
                          },
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 20),
          ],
          if (description.isNotEmpty) ...[
            Row(
              children: [
                Container(
                  width: 3,
                  height: 16,
                  decoration: BoxDecoration(
                    color: AppColors.primary,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  'Description',
                  style: AppTypography.titleSmall.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            _SimpleMarkdown(content: description),
          ],
        ],
      ),
    );
  }
}

class _ArticleContent extends StatelessWidget {
  final Map<String, dynamic> data;

  const _ArticleContent({required this.data});

  @override
  Widget build(BuildContext context) {
    final content = data['content'] as String? ??
        data['body'] as String? ??
        data['text'] as String? ??
        'Contenu non disponible.';

    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.all(20),
      child: SelectableRegion(
        focusNode: FocusNode(),
        selectionControls: materialTextSelectionControls,
        child: _SimpleMarkdown(content: content),
      ),
    );
  }
}

class _PdfContent extends StatelessWidget {
  final Map<String, dynamic> data;

  const _PdfContent({required this.data});

  @override
  Widget build(BuildContext context) {
    final pdfUrl =
        data['url'] as String? ?? data['pdf_url'] as String? ?? '';
    final description =
        data['description'] as String? ?? data['content'] as String? ?? '';

    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 32, horizontal: 20),
            decoration: BoxDecoration(
              color: AppColors.errorLight,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                  color: AppColors.error.withValues(alpha: 0.15)),
            ),
            child: Column(
              children: [
                Container(
                  width: 56,
                  height: 56,
                  decoration: BoxDecoration(
                    color: AppColors.error.withValues(alpha: 0.1),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Iconsax.document,
                      size: 28, color: AppColors.error),
                ),
                const SizedBox(height: 14),
                Text(
                  'Document PDF',
                  style: AppTypography.titleSmall.copyWith(
                    color: AppColors.errorDark,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 14),
                if (pdfUrl.isNotEmpty)
                  GradientButton(
                    text: 'Ouvrir le PDF',
                    icon: Iconsax.export_1,
                    showArrow: false,
                    isSmall: true,
                    width: 170,
                    onPressed: () async {
                      final uri = Uri.tryParse(pdfUrl);
                      if (uri != null && await canLaunchUrl(uri)) {
                        await launchUrl(uri,
                            mode: LaunchMode.externalApplication);
                      }
                    },
                  )
                else
                  Text(
                    'PDF non disponible.',
                    style: AppTypography.bodySmall.copyWith(
                      color: AppColors.textTertiary,
                    ),
                  ),
              ],
            ),
          ),
          if (description.isNotEmpty) ...[
            const SizedBox(height: 20),
            Row(
              children: [
                Container(
                  width: 3,
                  height: 16,
                  decoration: BoxDecoration(
                    color: AppColors.error,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  'Description',
                  style: AppTypography.titleSmall.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            _SimpleMarkdown(content: description),
          ],
        ],
      ),
    );
  }
}

class _ChallengeContent extends StatelessWidget {
  final Map<String, dynamic> data;

  const _ChallengeContent({required this.data});

  @override
  Widget build(BuildContext context) {
    final description =
        data['description'] as String? ?? data['content'] as String? ?? '';
    final objectives = (data['objectives'] as List<dynamic>?)
            ?.map((e) => e.toString())
            .toList() ??
        [];
    final submissionUrl =
        data['submission_url'] as String? ?? data['url'] as String?;

    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Challenge header
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 28, horizontal: 20),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  AppColors.categoryTechnology,
                  AppColors.primaryIndigo,
                ],
              ),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Column(
              children: [
                Container(
                  width: 56,
                  height: 56,
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.15),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Iconsax.cup,
                      size: 28, color: Colors.white),
                ),
                const SizedBox(height: 10),
                Text(
                  'Challenge',
                  style: AppTypography.titleMedium.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),

          if (description.isNotEmpty) ...[
            const SizedBox(height: 20),
            Row(
              children: [
                Container(
                  width: 3,
                  height: 16,
                  decoration: BoxDecoration(
                    color: AppColors.categoryTechnology,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  'Description',
                  style: AppTypography.titleSmall.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            _SimpleMarkdown(content: description),
          ],

          if (objectives.isNotEmpty) ...[
            const SizedBox(height: 20),
            Row(
              children: [
                Container(
                  width: 3,
                  height: 16,
                  decoration: BoxDecoration(
                    color: AppColors.categoryTechnology,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  'Objectifs',
                  style: AppTypography.titleSmall.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            ...objectives.asMap().entries.map((entry) => Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        width: 24,
                        height: 24,
                        margin: const EdgeInsets.only(right: 10),
                        decoration: BoxDecoration(
                          color: AppColors.categoryTechnology
                              .withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Center(
                          child: Text(
                            '${entry.key + 1}',
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                              color: AppColors.categoryTechnology,
                            ),
                          ),
                        ),
                      ),
                      Expanded(
                        child: Padding(
                          padding: const EdgeInsets.only(top: 3),
                          child: Text(
                            entry.value,
                            style: AppTypography.bodyMedium,
                          ),
                        ),
                      ),
                    ],
                  ),
                )),
          ],

          if (submissionUrl != null) ...[
            const SizedBox(height: 24),
            GradientButton(
              text: 'Soumettre ma solution',
              icon: Iconsax.export_1,
              onPressed: () async {
                final uri = Uri.tryParse(submissionUrl);
                if (uri != null && await canLaunchUrl(uri)) {
                  await launchUrl(uri,
                      mode: LaunchMode.externalApplication);
                }
              },
            ),
          ],
        ],
      ),
    );
  }
}

