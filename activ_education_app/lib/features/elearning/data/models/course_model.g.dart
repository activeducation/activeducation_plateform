// GENERATED CODE - DO NOT MODIFY BY HAND

// ignore_for_file: type=lint

part of 'course_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

CourseModel _$CourseModelFromJson(Map<String, dynamic> json) => CourseModel(
      id: json['id'] as String,
      title: json['title'] as String,
      description: json['description'] as String,
      thumbnailUrl: json['thumbnail_url'] as String?,
      category: json['category'] as String,
      difficulty: $enumDecode(_$CourseDifficultyEnumMap, json['difficulty']),
      durationMinutes: (json['duration_minutes'] as num).toInt(),
      pointsReward: (json['points_reward'] as num).toInt(),
      progressPct: (json['progress_pct'] as num?)?.toInt(),
      isEnrolled: json['is_enrolled'] as bool? ?? false,
    );

Map<String, dynamic> _$CourseModelToJson(CourseModel instance) =>
    <String, dynamic>{
      'id': instance.id,
      'title': instance.title,
      'description': instance.description,
      'thumbnail_url': instance.thumbnailUrl,
      'category': instance.category,
      'difficulty': _$CourseDifficultyEnumMap[instance.difficulty]!,
      'duration_minutes': instance.durationMinutes,
      'points_reward': instance.pointsReward,
      'progress_pct': instance.progressPct,
      'is_enrolled': instance.isEnrolled,
    };

const _$CourseDifficultyEnumMap = {
  CourseDifficulty.debutant: 'debutant',
  CourseDifficulty.intermediaire: 'intermediaire',
  CourseDifficulty.avance: 'avance',
};

LessonSummaryModel _$LessonSummaryModelFromJson(Map<String, dynamic> json) =>
    LessonSummaryModel(
      id: json['id'] as String,
      moduleId: json['module_id'] as String,
      title: json['title'] as String,
      lessonType: $enumDecode(_$LessonTypeEnumMap, json['lesson_type']),
      durationMinutes: (json['duration_minutes'] as num).toInt(),
      pointsReward: (json['points_reward'] as num).toInt(),
      isFree: json['is_free'] as bool? ?? false,
      status: $enumDecodeNullable(_$LessonStatusEnumMap, json['status']),
    );

Map<String, dynamic> _$LessonSummaryModelToJson(LessonSummaryModel instance) =>
    <String, dynamic>{
      'id': instance.id,
      'module_id': instance.moduleId,
      'title': instance.title,
      'lesson_type': _$LessonTypeEnumMap[instance.lessonType]!,
      'duration_minutes': instance.durationMinutes,
      'points_reward': instance.pointsReward,
      'is_free': instance.isFree,
      'status': _$LessonStatusEnumMap[instance.status],
    };

const _$LessonTypeEnumMap = {
  LessonType.video: 'video',
  LessonType.article: 'article',
  LessonType.quiz: 'quiz',
  LessonType.pdf: 'pdf',
  LessonType.challenge: 'challenge',
};

const _$LessonStatusEnumMap = {
  LessonStatus.not_started: 'not_started',
  LessonStatus.in_progress: 'in_progress',
  LessonStatus.completed: 'completed',
};

CourseModuleModel _$CourseModuleModelFromJson(Map<String, dynamic> json) =>
    CourseModuleModel(
      id: json['id'] as String,
      courseId: json['course_id'] as String,
      title: json['title'] as String,
      description: json['description'] as String,
      displayOrder: (json['display_order'] as num).toInt(),
      isLocked: json['is_locked'] as bool? ?? false,
      lessons: (json['lessons'] as List<dynamic>)
          .map((e) => LessonSummaryModel.fromJson(e as Map<String, dynamic>))
          .toList(),
    );

Map<String, dynamic> _$CourseModuleModelToJson(CourseModuleModel instance) =>
    <String, dynamic>{
      'id': instance.id,
      'course_id': instance.courseId,
      'title': instance.title,
      'description': instance.description,
      'display_order': instance.displayOrder,
      'is_locked': instance.isLocked,
      'lessons': instance.lessons.map((e) => (e as LessonSummaryModel).toJson()).toList(),
    };

LessonContentModel _$LessonContentModelFromJson(Map<String, dynamic> json) =>
    LessonContentModel(
      lessonType: $enumDecode(_$LessonTypeEnumMap, json['lesson_type']),
      data: json['data'] as Map<String, dynamic>,
    );

Map<String, dynamic> _$LessonContentModelToJson(LessonContentModel instance) =>
    <String, dynamic>{
      'lesson_type': _$LessonTypeEnumMap[instance.lessonType]!,
      'data': instance.data,
    };

LessonDetailModel _$LessonDetailModelFromJson(Map<String, dynamic> json) =>
    LessonDetailModel(
      id: json['id'] as String,
      moduleId: json['module_id'] as String,
      title: json['title'] as String,
      lessonType: $enumDecode(_$LessonTypeEnumMap, json['lesson_type']),
      durationMinutes: (json['duration_minutes'] as num).toInt(),
      pointsReward: (json['points_reward'] as num).toInt(),
      isFree: json['is_free'] as bool? ?? false,
      status: $enumDecodeNullable(_$LessonStatusEnumMap, json['status']),
      content: json['content'] == null
          ? null
          : LessonContentModel.fromJson(json['content'] as Map<String, dynamic>),
    );

Map<String, dynamic> _$LessonDetailModelToJson(LessonDetailModel instance) =>
    <String, dynamic>{
      'id': instance.id,
      'module_id': instance.moduleId,
      'title': instance.title,
      'lesson_type': _$LessonTypeEnumMap[instance.lessonType]!,
      'duration_minutes': instance.durationMinutes,
      'points_reward': instance.pointsReward,
      'is_free': instance.isFree,
      'status': _$LessonStatusEnumMap[instance.status],
      'content': instance.content == null
          ? null
          : (instance.content! as LessonContentModel).toJson(),
    };

CourseDetailModel _$CourseDetailModelFromJson(Map<String, dynamic> json) =>
    CourseDetailModel(
      id: json['id'] as String,
      title: json['title'] as String,
      description: json['description'] as String,
      thumbnailUrl: json['thumbnail_url'] as String?,
      category: json['category'] as String,
      difficulty: $enumDecode(_$CourseDifficultyEnumMap, json['difficulty']),
      durationMinutes: (json['duration_minutes'] as num).toInt(),
      pointsReward: (json['points_reward'] as num).toInt(),
      progressPct: (json['progress_pct'] as num?)?.toInt(),
      isEnrolled: json['is_enrolled'] as bool? ?? false,
      modules: (json['modules'] as List<dynamic>)
          .map((e) => CourseModuleModel.fromJson(e as Map<String, dynamic>))
          .toList(),
    );

Map<String, dynamic> _$CourseDetailModelToJson(CourseDetailModel instance) =>
    <String, dynamic>{
      'id': instance.id,
      'title': instance.title,
      'description': instance.description,
      'thumbnail_url': instance.thumbnailUrl,
      'category': instance.category,
      'difficulty': _$CourseDifficultyEnumMap[instance.difficulty]!,
      'duration_minutes': instance.durationMinutes,
      'points_reward': instance.pointsReward,
      'progress_pct': instance.progressPct,
      'is_enrolled': instance.isEnrolled,
      'modules': instance.modules.map((e) => (e as CourseModuleModel).toJson()).toList(),
    };

