// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'course_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

CourseModel _$CourseModelFromJson(Map<String, dynamic> json) => CourseModel(
  id: json['id'] as String,
  title: json['title'] as String,
  description: json['description'] as String,
  thumbnailUrl: json['thumbnailUrl'] as String?,
  category: json['category'] as String,
  difficulty: $enumDecode(_$CourseDifficultyEnumMap, json['difficulty']),
  durationMinutes: (json['durationMinutes'] as num).toInt(),
  pointsReward: (json['pointsReward'] as num).toInt(),
  progressPct: (json['progressPct'] as num?)?.toInt(),
  isEnrolled: json['isEnrolled'] as bool? ?? false,
);

Map<String, dynamic> _$CourseModelToJson(CourseModel instance) =>
    <String, dynamic>{
      'id': instance.id,
      'title': instance.title,
      'description': instance.description,
      'thumbnailUrl': instance.thumbnailUrl,
      'category': instance.category,
      'difficulty': _$CourseDifficultyEnumMap[instance.difficulty]!,
      'durationMinutes': instance.durationMinutes,
      'pointsReward': instance.pointsReward,
      'progressPct': instance.progressPct,
      'isEnrolled': instance.isEnrolled,
    };

const _$CourseDifficultyEnumMap = {
  CourseDifficulty.debutant: 'debutant',
  CourseDifficulty.intermediaire: 'intermediaire',
  CourseDifficulty.avance: 'avance',
};

CourseModuleModel _$CourseModuleModelFromJson(Map<String, dynamic> json) =>
    CourseModuleModel(
      id: json['id'] as String,
      courseId: json['courseId'] as String,
      title: json['title'] as String,
      description: json['description'] as String?,
      displayOrder: (json['displayOrder'] as num).toInt(),
      isLocked: json['isLocked'] as bool,
      lessons: (json['lessons'] as List<dynamic>)
          .map((e) => LessonSummaryModel.fromJson(e as Map<String, dynamic>))
          .toList(),
    );

Map<String, dynamic> _$CourseModuleModelToJson(CourseModuleModel instance) =>
    <String, dynamic>{
      'id': instance.id,
      'courseId': instance.courseId,
      'title': instance.title,
      'description': instance.description,
      'displayOrder': instance.displayOrder,
      'isLocked': instance.isLocked,
      'lessons': instance.lessons,
    };

LessonSummaryModel _$LessonSummaryModelFromJson(Map<String, dynamic> json) =>
    LessonSummaryModel(
      id: json['id'] as String,
      moduleId: json['moduleId'] as String,
      title: json['title'] as String,
      lessonType: $enumDecode(_$LessonTypeEnumMap, json['lessonType']),
      durationMinutes: (json['durationMinutes'] as num).toInt(),
      pointsReward: (json['pointsReward'] as num).toInt(),
      isFree: json['isFree'] as bool,
      status: $enumDecodeNullable(_$LessonStatusEnumMap, json['status']),
    );

Map<String, dynamic> _$LessonSummaryModelToJson(LessonSummaryModel instance) =>
    <String, dynamic>{
      'id': instance.id,
      'moduleId': instance.moduleId,
      'title': instance.title,
      'lessonType': _$LessonTypeEnumMap[instance.lessonType]!,
      'durationMinutes': instance.durationMinutes,
      'pointsReward': instance.pointsReward,
      'isFree': instance.isFree,
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

LessonContentModel _$LessonContentModelFromJson(Map<String, dynamic> json) =>
    LessonContentModel(
      lessonType: $enumDecode(_$LessonTypeEnumMap, json['lessonType']),
      data: json['data'] as Map<String, dynamic>,
    );

Map<String, dynamic> _$LessonContentModelToJson(LessonContentModel instance) =>
    <String, dynamic>{
      'lessonType': _$LessonTypeEnumMap[instance.lessonType]!,
      'data': instance.data,
    };

LessonDetailModel _$LessonDetailModelFromJson(Map<String, dynamic> json) =>
    LessonDetailModel(
      id: json['id'] as String,
      moduleId: json['moduleId'] as String,
      title: json['title'] as String,
      lessonType: $enumDecode(_$LessonTypeEnumMap, json['lessonType']),
      durationMinutes: (json['durationMinutes'] as num).toInt(),
      pointsReward: (json['pointsReward'] as num).toInt(),
      isFree: json['isFree'] as bool,
      status: $enumDecodeNullable(_$LessonStatusEnumMap, json['status']),
      content: json['content'] == null
          ? null
          : LessonContentModel.fromJson(
              json['content'] as Map<String, dynamic>,
            ),
    );

Map<String, dynamic> _$LessonDetailModelToJson(LessonDetailModel instance) =>
    <String, dynamic>{
      'id': instance.id,
      'moduleId': instance.moduleId,
      'title': instance.title,
      'lessonType': _$LessonTypeEnumMap[instance.lessonType]!,
      'durationMinutes': instance.durationMinutes,
      'pointsReward': instance.pointsReward,
      'isFree': instance.isFree,
      'status': _$LessonStatusEnumMap[instance.status],
      'content': instance.content,
    };

CourseDetailModel _$CourseDetailModelFromJson(Map<String, dynamic> json) =>
    CourseDetailModel(
      id: json['id'] as String,
      title: json['title'] as String,
      description: json['description'] as String,
      thumbnailUrl: json['thumbnailUrl'] as String?,
      category: json['category'] as String,
      difficulty: $enumDecode(_$CourseDifficultyEnumMap, json['difficulty']),
      durationMinutes: (json['durationMinutes'] as num).toInt(),
      pointsReward: (json['pointsReward'] as num).toInt(),
      progressPct: (json['progressPct'] as num?)?.toInt(),
      isEnrolled: json['isEnrolled'] as bool? ?? false,
      modules: (json['modules'] as List<dynamic>)
          .map((e) => CourseModuleModel.fromJson(e as Map<String, dynamic>))
          .toList(),
    );

Map<String, dynamic> _$CourseDetailModelToJson(CourseDetailModel instance) =>
    <String, dynamic>{
      'id': instance.id,
      'title': instance.title,
      'description': instance.description,
      'thumbnailUrl': instance.thumbnailUrl,
      'category': instance.category,
      'difficulty': _$CourseDifficultyEnumMap[instance.difficulty]!,
      'durationMinutes': instance.durationMinutes,
      'pointsReward': instance.pointsReward,
      'progressPct': instance.progressPct,
      'isEnrolled': instance.isEnrolled,
      'modules': instance.modules,
    };
