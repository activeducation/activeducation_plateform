import 'package:json_annotation/json_annotation.dart';
import '../../domain/entities/orientation_test.dart';

part 'orientation_test_model.g.dart';

@JsonSerializable()
class OrientationTestModel extends OrientationTest {
  @override
  final List<QuestionModel> questions;

  const OrientationTestModel({
    required super.id,
    required super.name,
    required super.description,
    required super.type,
    required super.durationMinutes,
    required this.questions,
    super.imageUrl,
  }) : super(questions: questions);

  factory OrientationTestModel.fromJson(Map<String, dynamic> json) =>
      _$OrientationTestModelFromJson(json);

  Map<String, dynamic> toJson() => _$OrientationTestModelToJson(this);
}

@JsonSerializable()
class QuestionModel extends Question {
  @override
  final List<OptionModel> options;

  const QuestionModel({
    required super.id,
    required super.text,
    required super.type,
    super.category,
    required this.options,
    super.imageAsset,
    super.sectionTitle,
    super.sliderLeftLabel,
    super.sliderRightLabel,
  }) : super(options: options);

  factory QuestionModel.fromJson(Map<String, dynamic> json) =>
      _$QuestionModelFromJson(json);

  Map<String, dynamic> toJson() => _$QuestionModelToJson(this);
}

@JsonSerializable()
class OptionModel extends Option {
  const OptionModel({
    required super.id,
    required super.text,
    required super.value,
    super.icon,
    super.emoji,
  });

  factory OptionModel.fromJson(Map<String, dynamic> json) =>
      _$OptionModelFromJson(json);

  Map<String, dynamic> toJson() => _$OptionModelToJson(this);
}
