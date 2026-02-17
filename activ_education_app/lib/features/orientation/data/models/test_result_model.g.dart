// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'test_result_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

TestResultModel _$TestResultModelFromJson(Map<String, dynamic> json) =>
    TestResultModel(
      testId: json['testId'] as String?,
      scores: (json['scores'] as Map<String, dynamic>).map(
        (k, e) => MapEntry(k, (e as num).toDouble()),
      ),
      dominantTraits: (json['dominantTraits'] as List<dynamic>)
          .map((e) => e as String)
          .toList(),
      recommendations:
          _recommendationsFromJson(json['recommendations'] as List),
    );

Map<String, dynamic> _$TestResultModelToJson(TestResultModel instance) =>
    <String, dynamic>{
      'testId': instance.testId,
      'scores': instance.scores,
      'dominantTraits': instance.dominantTraits,
      'recommendations': instance.recommendations,
    };
