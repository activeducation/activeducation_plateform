import 'package:equatable/equatable.dart';

enum CourseDifficulty { debutant, intermediaire, avance }

enum LessonType { video, article, quiz, pdf, challenge }

enum LessonStatus { not_started, in_progress, completed }

/// Canonical list of course categories used in the catalog UI and the
/// admin seed (backend/database/seed_elearning_50_courses.sql).
///
/// The DB column is still a free STRING (allowing admins to introduce
/// new categories without a migration), but the front-end offers only
/// these 5 in the catalog filter chips and maps them to brand colors.
///
/// New categories from the backend that don't match any of these are
/// kept as raw strings via [CourseCategory.maybeFrom] returning null,
/// and the rendering helpers fall back to a neutral color + book icon.
enum CourseCategory {
  informatique('Informatique'),
  mathematiques('Mathématiques'),
  sciences('Sciences'),
  orientation('Orientation'),
  hackathons('Hackathons');

  final String label;
  const CourseCategory(this.label);

  /// Parse a backend category string into the canonical enum.
  /// Uses exact-match first, then a few well-known aliases.
  /// Returns null when the category is unknown so the rendering layer
  /// can apply a logged fallback instead of guessing.
  static CourseCategory? maybeFrom(String? raw) {
    if (raw == null) return null;
    final trimmed = raw.trim();
    for (final c in values) {
      if (c.label == trimmed) return c;
    }
    // A few legacy / French-with-accents aliases
    const aliases = {
      'mathematiques': mathematiques,
      'maths': mathematiques,
      'info': informatique,
      'tech': informatique,
      'technologie': informatique,
      'orientation scolaire': orientation,
      'hackathon': hackathons,
    };
    return aliases[trimmed.toLowerCase()];
  }
}

class Course extends Equatable {
  final String id;
  final String title;
  final String description;
  final String? thumbnailUrl;
  final String category;
  final CourseDifficulty difficulty;
  final int durationMinutes;
  final int pointsReward;
  final int? progressPct;
  final bool isEnrolled;

  const Course({
    required this.id,
    required this.title,
    required this.description,
    this.thumbnailUrl,
    required this.category,
    required this.difficulty,
    required this.durationMinutes,
    required this.pointsReward,
    this.progressPct,
    this.isEnrolled = false,
  });

  @override
  List<Object?> get props => [
        id,
        title,
        description,
        thumbnailUrl,
        category,
        difficulty,
        durationMinutes,
        pointsReward,
        progressPct,
        isEnrolled,
      ];
}

class CourseModule extends Equatable {
  final String id;
  final String courseId;
  final String title;
  final String? description;
  final int displayOrder;
  final bool isLocked;
  final List<LessonSummary> lessons;

  const CourseModule({
    required this.id,
    required this.courseId,
    required this.title,
    this.description,
    required this.displayOrder,
    required this.isLocked,
    required this.lessons,
  });

  @override
  List<Object?> get props => [id, courseId, title, displayOrder, isLocked, lessons];
}

class LessonSummary extends Equatable {
  final String id;
  final String moduleId;
  final String title;
  final LessonType lessonType;
  final int durationMinutes;
  final int pointsReward;
  final bool isFree;
  final LessonStatus? status;

  const LessonSummary({
    required this.id,
    required this.moduleId,
    required this.title,
    required this.lessonType,
    required this.durationMinutes,
    required this.pointsReward,
    required this.isFree,
    this.status,
  });

  @override
  List<Object?> get props => [id, moduleId, title, lessonType, durationMinutes, pointsReward, isFree, status];
}

class LessonContent extends Equatable {
  final LessonType lessonType;
  final Map<String, dynamic> data;

  const LessonContent({
    required this.lessonType,
    required this.data,
  });

  @override
  List<Object?> get props => [lessonType, data];
}

class LessonDetail extends LessonSummary {
  final LessonContent? content;

  const LessonDetail({
    required super.id,
    required super.moduleId,
    required super.title,
    required super.lessonType,
    required super.durationMinutes,
    required super.pointsReward,
    required super.isFree,
    super.status,
    this.content,
  });

  @override
  List<Object?> get props => [...super.props, content];
}

class CourseDetail extends Course {
  final List<CourseModule> modules;

  const CourseDetail({
    required super.id,
    required super.title,
    required super.description,
    super.thumbnailUrl,
    required super.category,
    required super.difficulty,
    required super.durationMinutes,
    required super.pointsReward,
    super.progressPct,
    super.isEnrolled,
    required this.modules,
  });

  @override
  List<Object?> get props => [...super.props, modules];
}
