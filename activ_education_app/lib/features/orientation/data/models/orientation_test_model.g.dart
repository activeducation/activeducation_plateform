// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'orientation_test_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

OrientationTestModel _$OrientationTestModelFromJson(
        Map<String, dynamic> json) =>
    OrientationTestModel(
      id: json['id'] as String,
      name: json['name'] as String,
      description: json['description'] as String,
      type: $enumDecode(_$TestTypeEnumMap, json['type']),
      durationMinutes: (json['durationMinutes'] as num).toInt(),
      questions: (json['questions'] as List<dynamic>)
          .map((e) => QuestionModel.fromJson(e as Map<String, dynamic>))
          .toList(),
      imageUrl: json['imageUrl'] as String?,
    );

Map<String, dynamic> _$OrientationTestModelToJson(
        OrientationTestModel instance) =>
    <String, dynamic>{
      'id': instance.id,
      'name': instance.name,
      'description': instance.description,
      'type': _$TestTypeEnumMap[instance.type]!,
      'durationMinutes': instance.durationMinutes,
      'imageUrl': instance.imageUrl,
      'questions': instance.questions,
    };

const _$TestTypeEnumMap = {
  TestType.riasec: 'riasec',
  TestType.personality: 'personality',
  TestType.skills: 'skills',
  TestType.interests: 'interests',
  TestType.aptitude: 'aptitude',
};

QuestionModel _$QuestionModelFromJson(Map<String, dynamic> json) =>
    QuestionModel(
      id: json['id'] as String,
      text: json['text'] as String,
      type: $enumDecode(_$QuestionTypeEnumMap, json['type']),
      category: json['category'] as String?,
      options: (json['options'] as List<dynamic>)
          .map((e) => OptionModel.fromJson(e as Map<String, dynamic>))
          .toList(),
      imageAsset: json['imageAsset'] as String?,
      sectionTitle: json['sectionTitle'] as String?,
      sliderLeftLabel: json['sliderLeftLabel'] as String?,
      sliderRightLabel: json['sliderRightLabel'] as String?,
    );

Map<String, dynamic> _$QuestionModelToJson(QuestionModel instance) =>
    <String, dynamic>{
      'id': instance.id,
      'text': instance.text,
      'type': _$QuestionTypeEnumMap[instance.type]!,
      'category': instance.category,
      'imageAsset': instance.imageAsset,
      'sectionTitle': instance.sectionTitle,
      'sliderLeftLabel': instance.sliderLeftLabel,
      'sliderRightLabel': instance.sliderRightLabel,
      'options': instance.options,
    };

const _$QuestionTypeEnumMap = {
  QuestionType.likert: 'likert',
  QuestionType.multipleChoice: 'multipleChoice',
  QuestionType.boolean: 'boolean',
  QuestionType.scenario: 'scenario',
  QuestionType.thisOrThat: 'thisOrThat',
  QuestionType.ranking: 'ranking',
  QuestionType.slider: 'slider',
};

OptionModel _$OptionModelFromJson(Map<String, dynamic> json) => OptionModel(
      id: json['id'] as String,
      text: json['text'] as String,
      value: json['value'],
      icon: json['icon'] as String?,
      emoji: json['emoji'] as String?,
    );

Map<String, dynamic> _$OptionModelToJson(OptionModel instance) =>
    <String, dynamic>{
      'id': instance.id,
      'text': instance.text,
      'value': instance.value,
      'icon': instance.icon,
      'emoji': instance.emoji,
    };
