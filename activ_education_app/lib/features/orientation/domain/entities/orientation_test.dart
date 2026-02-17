import 'package:equatable/equatable.dart';

enum TestType { riasec, personality, skills, interests, aptitude }
enum QuestionType { likert, multipleChoice, boolean, scenario, thisOrThat, ranking, slider }

class OrientationTest extends Equatable {
  final String id;
  final String name;
  final String description;
  final TestType type;
  final int durationMinutes;
  final List<Question> questions;
  final String? imageUrl;

  const OrientationTest({
    required this.id,
    required this.name,
    required this.description,
    required this.type,
    required this.durationMinutes,
    required this.questions,
    this.imageUrl,
  });

  @override
  List<Object?> get props => [id, name, type, questions];
}

class Question extends Equatable {
  final String id;
  final String text;
  final QuestionType type;
  final String? category;
  final List<Option> options;
  final String? imageAsset;
  final String? sectionTitle;
  final String? sliderLeftLabel;
  final String? sliderRightLabel;

  const Question({
    required this.id,
    required this.text,
    required this.type,
    this.category,
    required this.options,
    this.imageAsset,
    this.sectionTitle,
    this.sliderLeftLabel,
    this.sliderRightLabel,
  });

  @override
  List<Object?> get props => [id, text, type, options];
}

class Option extends Equatable {
  final String id;
  final String text;
  final dynamic value;
  final String? icon;
  final String? emoji;

  const Option({
    required this.id,
    required this.text,
    required this.value,
    this.icon,
    this.emoji,
  });

  @override
  List<Object?> get props => [id, text, value];
}
