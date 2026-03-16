import 'package:json_annotation/json_annotation.dart';
import '../../domain/entities/course.dart';

part 'course_model.g.dart';

@JsonSerializable()
class CourseModel extends Course {
  const CourseModel({
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
  });

  factory CourseModel.fromJson(Map<String, dynamic> json) =>
      _$CourseModelFromJson(json);

  Map<String, dynamic> toJson() => _$CourseModelToJson(this);
}

@JsonSerializable()
class CourseModuleModel extends CourseModule {
  @override
  final List<LessonSummaryModel> lessons;

  const CourseModuleModel({
    required super.id,
    required super.courseId,
    required super.title,
    required super.description,
    required super.displayOrder,
    required super.isLocked,
    required this.lessons,
  }) : super(lessons: lessons);

  factory CourseModuleModel.fromJson(Map<String, dynamic> json) =>
      _$CourseModuleModelFromJson(json);

  Map<String, dynamic> toJson() => _$CourseModuleModelToJson(this);
}

@JsonSerializable()
class LessonSummaryModel extends LessonSummary {
  const LessonSummaryModel({
    required super.id,
    required super.moduleId,
    required super.title,
    required super.lessonType,
    required super.durationMinutes,
    required super.pointsReward,
    required super.isFree,
    super.status,
  });

  factory LessonSummaryModel.fromJson(Map<String, dynamic> json) =>
      _$LessonSummaryModelFromJson(json);

  Map<String, dynamic> toJson() => _$LessonSummaryModelToJson(this);
}

@JsonSerializable()
class LessonContentModel extends LessonContent {
  const LessonContentModel({
    required super.lessonType,
    required super.data,
  });

  factory LessonContentModel.fromJson(Map<String, dynamic> json) =>
      _$LessonContentModelFromJson(json);

  Map<String, dynamic> toJson() => _$LessonContentModelToJson(this);
}

@JsonSerializable()
class LessonDetailModel extends LessonDetail {
  @override
  final LessonContentModel? content;

  const LessonDetailModel({
    required super.id,
    required super.moduleId,
    required super.title,
    required super.lessonType,
    required super.durationMinutes,
    required super.pointsReward,
    required super.isFree,
    super.status,
    this.content,
  }) : super(content: content);

  factory LessonDetailModel.fromJson(Map<String, dynamic> json) =>
      _$LessonDetailModelFromJson(json);

  Map<String, dynamic> toJson() => _$LessonDetailModelToJson(this);
}

@JsonSerializable()
class CourseDetailModel extends CourseDetail {
  @override
  final List<CourseModuleModel> modules;

  const CourseDetailModel({
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
  }) : super(modules: modules);

  factory CourseDetailModel.fromJson(Map<String, dynamic> json) =>
      _$CourseDetailModelFromJson(json);

  Map<String, dynamic> toJson() => _$CourseDetailModelToJson(this);
}
