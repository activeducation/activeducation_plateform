import 'package:json_annotation/json_annotation.dart';
import '../../domain/entities/course.dart';

part 'course_model.g.dart';

@JsonSerializable(fieldRename: FieldRename.snake)
class CourseModel extends Course {
  const CourseModel({
    required super.id,
    required super.title,
    @JsonKey(defaultValue: '') required super.description,
    super.thumbnailUrl,
    @JsonKey(defaultValue: '') required super.category,
    required super.difficulty,
    @JsonKey(defaultValue: 0) required super.durationMinutes,
    @JsonKey(defaultValue: 0) required super.pointsReward,
    super.progressPct,
    super.isEnrolled,
  });

  factory CourseModel.fromJson(Map<String, dynamic> json) =>
      _$CourseModelFromJson(json);

  Map<String, dynamic> toJson() => _$CourseModelToJson(this);
}

@JsonSerializable(fieldRename: FieldRename.snake)
class CourseModuleModel extends CourseModule {
  @override
  final List<LessonSummaryModel> lessons;

  const CourseModuleModel({
    required super.id,
    required super.courseId,
    required super.title,
    super.description,
    @JsonKey(defaultValue: 0) required super.displayOrder,
    required super.isLocked,
    required this.lessons,
  }) : super(lessons: lessons);

  factory CourseModuleModel.fromJson(Map<String, dynamic> json) =>
      _$CourseModuleModelFromJson(json);

  Map<String, dynamic> toJson() => _$CourseModuleModelToJson(this);
}

@JsonSerializable(fieldRename: FieldRename.snake)
class LessonSummaryModel extends LessonSummary {
  const LessonSummaryModel({
    required super.id,
    required super.moduleId,
    required super.title,
    required super.lessonType,
    @JsonKey(defaultValue: 0) required super.durationMinutes,
    @JsonKey(defaultValue: 0) required super.pointsReward,
    required super.isFree,
    super.status,
  });

  factory LessonSummaryModel.fromJson(Map<String, dynamic> json) =>
      _$LessonSummaryModelFromJson(json);

  Map<String, dynamic> toJson() => _$LessonSummaryModelToJson(this);
}

@JsonSerializable(fieldRename: FieldRename.snake)
class LessonContentModel extends LessonContent {
  const LessonContentModel({
    required super.lessonType,
    required super.data,
  });

  factory LessonContentModel.fromJson(Map<String, dynamic> json) =>
      _$LessonContentModelFromJson(json);

  Map<String, dynamic> toJson() => _$LessonContentModelToJson(this);
}

@JsonSerializable(fieldRename: FieldRename.snake)
class LessonDetailModel extends LessonDetail {
  @override
  final LessonContentModel? content;

  const LessonDetailModel({
    required super.id,
    required super.moduleId,
    required super.title,
    required super.lessonType,
    @JsonKey(defaultValue: 0) required super.durationMinutes,
    @JsonKey(defaultValue: 0) required super.pointsReward,
    required super.isFree,
    super.status,
    this.content,
  }) : super(content: content);

  factory LessonDetailModel.fromJson(Map<String, dynamic> json) =>
      _$LessonDetailModelFromJson(json);

  Map<String, dynamic> toJson() => _$LessonDetailModelToJson(this);
}

@JsonSerializable(fieldRename: FieldRename.snake)
class CourseDetailModel extends CourseDetail {
  @override
  final List<CourseModuleModel> modules;

  const CourseDetailModel({
    required super.id,
    required super.title,
    @JsonKey(defaultValue: '') required super.description,
    super.thumbnailUrl,
    @JsonKey(defaultValue: '') required super.category,
    required super.difficulty,
    @JsonKey(defaultValue: 0) required super.durationMinutes,
    @JsonKey(defaultValue: 0) required super.pointsReward,
    super.progressPct,
    super.isEnrolled,
    required this.modules,
  }) : super(modules: modules);

  factory CourseDetailModel.fromJson(Map<String, dynamic> json) =>
      _$CourseDetailModelFromJson(json);

  Map<String, dynamic> toJson() => _$CourseDetailModelToJson(this);
}
