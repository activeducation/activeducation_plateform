// Modèles du quiz TutorAI (miroir de la réponse de /tutor/quiz/generate).

class QuizOption {
  final String text;
  final bool isCorrect;

  const QuizOption({required this.text, required this.isCorrect});

  factory QuizOption.fromJson(Map<String, dynamic> json) {
    return QuizOption(
      text: json['text'] as String? ?? '',
      isCorrect: json['is_correct'] as bool? ?? false,
    );
  }
}

class QuizQuestion {
  final String question;
  final List<QuizOption> options;
  final String explanation;

  const QuizQuestion({
    required this.question,
    required this.options,
    this.explanation = '',
  });

  factory QuizQuestion.fromJson(Map<String, dynamic> json) {
    final rawOptions = (json['options'] as List?) ?? const [];
    return QuizQuestion(
      question: json['question'] as String? ?? '',
      options: rawOptions
          .whereType<Map<String, dynamic>>()
          .map(QuizOption.fromJson)
          .toList(),
      explanation: json['explanation'] as String? ?? '',
    );
  }

  /// Index de la bonne réponse (-1 si aucune, ne devrait pas arriver).
  int get correctIndex => options.indexWhere((o) => o.isCorrect);
}

class Quiz {
  final List<QuizQuestion> questions;

  /// Compétence ciblée (si le quiz est rattaché à une compétence connue) :
  /// permet de soumettre les réponses pour alimenter le BKT.
  final String? skillId;

  const Quiz({required this.questions, this.skillId});

  factory Quiz.fromJson(Map<String, dynamic> json) {
    final rawQuestions = (json['questions'] as List?) ?? const [];
    return Quiz(
      questions: rawQuestions
          .whereType<Map<String, dynamic>>()
          .map(QuizQuestion.fromJson)
          .toList(),
      skillId: json['skill_id'] as String?,
    );
  }

  bool get isEmpty => questions.isEmpty;
  int get length => questions.length;
  bool get isSkillBound => skillId != null && skillId!.isNotEmpty;
}
