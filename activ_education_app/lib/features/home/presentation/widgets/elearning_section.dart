import 'package:flutter/material.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_spacing.dart';
import '../../../elearning/domain/entities/course.dart';
import '../../../elearning/presentation/widgets/course_card.dart';
import 'section_header.dart';
import 'elearning_cta_card.dart';

class ElearningSection extends StatelessWidget {
  final Future<List<Course>> coursesFuture;
  final VoidCallback onCatalog;
  final void Function(Course) onCourseTap;

  const ElearningSection({
    super.key,
    required this.coursesFuture,
    required this.onCatalog,
    required this.onCourseTap,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SectionHeader(
          title: 'Apprendre',
          badge: 'E-Learning',
          accentColor: AppColors.categoryTechnology,
          actionLabel: 'Catalogue',
          onAction: onCatalog,
        ),
        const SizedBox(height: 14),
        FutureBuilder<List<Course>>(
          future: coursesFuture,
          builder: (context, snapshot) {
            if (!snapshot.hasData) {
              return const SizedBox(
                height: 140,
                child: Center(
                  child: CircularProgressIndicator(
                    color: AppColors.categoryTechnology,
                    strokeWidth: 2.5,
                  ),
                ),
              );
            }

            final courses = snapshot.data ?? <Course>[];
            if (courses.isEmpty) {
              return Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.pagePaddingHorizontal,
                ),
                child: ElearningCTACard(onTap: onCatalog),
              );
            }

            return SizedBox(
              height: 162,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                physics: const BouncingScrollPhysics(),
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.pagePaddingHorizontal,
                ),
                itemCount: courses.take(5).length,
                separatorBuilder: (_, __) => const SizedBox(width: 12),
                itemBuilder: (context, index) {
                  final course = courses.elementAt(index);
                  return SizedBox(
                    width: 220,
                    child: CourseCard(
                      course: course,
                      mode: CourseCardMode.compact,
                      onTap: () => onCourseTap(course),
                    ),
                  );
                },
              ),
            );
          },
        ),
      ],
    );
  }
}
