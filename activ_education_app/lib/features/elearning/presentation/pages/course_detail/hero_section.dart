// Partie de course_detail_page.dart (refacto : page de 1454 lignes
// decoupee en parts pour la lisibilite). Widgets prives partages,
// imports herites de la librairie principale.
//
// Hero immersif (app bar, fond, contenu bas).
part of '../course_detail_page.dart';

// ─── Hero App Bar ─────────────────────────────────────────────────────────────

class _HeroAppBar extends StatelessWidget {
  final CourseDetail course;
  final Color color;

  const _HeroAppBar({required this.course, required this.color});

  @override
  Widget build(BuildContext context) {
    return SliverAppBar(
      expandedHeight: 200,
      pinned: true,
      backgroundColor: AppColors.darkBg,
      surfaceTintColor: Colors.transparent,
      leading: Padding(
        padding: const EdgeInsets.all(10),
        child: GestureDetector(
          onTap: () => context.pop(),
          child: Container(
            decoration: BoxDecoration(
              color: Colors.black.withValues(alpha: 0.3),
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(
              Icons.arrow_back_rounded,
              color: Colors.white,
              size: 20,
            ),
          ),
        ),
      ),
      flexibleSpace: FlexibleSpaceBar(
        collapseMode: CollapseMode.parallax,
        background: course.thumbnailUrl != null
            ? Stack(
                fit: StackFit.expand,
                children: [
                  CachedNetworkImage(
                    imageUrl: course.thumbnailUrl!,
                    fit: BoxFit.cover,
                    placeholder: (_, _) =>
                        _HeroBackground(color: color, course: course),
                    errorWidget: (_, _, _) =>
                        _HeroBackground(color: color, course: course),
                  ),
                  // Gradient overlay
                  Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          color.withValues(alpha: 0.3),
                          AppColors.darkBg.withValues(alpha: 0.85),
                        ],
                      ),
                    ),
                  ),
                  _HeroBottomContent(course: course, color: color),
                ],
              )
            : _HeroBackground(color: color, course: course),
      ),
    );
  }
}

class _HeroBackground extends StatelessWidget {
  final Color color;
  final CourseDetail course;

  const _HeroBackground({required this.color, required this.course});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            AppColors.darkBg,
            color.withValues(alpha: 0.65),
          ],
        ),
      ),
      child: Stack(
        children: [
          // Decorative circles
          Positioned(
            top: -40,
            right: -30,
            child: Container(
              width: 160,
              height: 160,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: color.withValues(alpha: 0.12),
              ),
            ),
          ),
          Positioned(
            bottom: -20,
            left: -20,
            child: Container(
              width: 100,
              height: 100,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white.withValues(alpha: 0.04),
              ),
            ),
          ),
          _HeroBottomContent(course: course, color: color),
        ],
      ),
    );
  }
}

class _HeroBottomContent extends StatelessWidget {
  final CourseDetail course;
  final Color color;

  const _HeroBottomContent({required this.course, required this.color});

  @override
  Widget build(BuildContext context) {
    return Positioned(
      bottom: 20,
      left: 20,
      right: 20,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.85),
                  borderRadius: BorderRadius.circular(7),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      iconForCategory(course.category),
                      size: 13,
                      color: Colors.white,
                    ),
                    const SizedBox(width: 5),
                    Text(
                      course.category,
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: Colors.white,
                        letterSpacing: 0.2,
                      ),
                    ),
                  ],
                ),
              ),
              if (course.isEnrolled) ...[
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                  decoration: BoxDecoration(
                    color: AppColors.success.withValues(alpha: 0.85),
                    borderRadius: BorderRadius.circular(7),
                  ),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.check_circle_rounded,
                          size: 12, color: Colors.white),
                      SizedBox(width: 4),
                      Text(
                        'Inscrit',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          color: Colors.white,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }
}
