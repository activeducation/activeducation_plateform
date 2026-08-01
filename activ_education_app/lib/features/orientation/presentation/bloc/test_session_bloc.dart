import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter/material.dart';
import '../../domain/entities/orientation_test.dart';

// Events
abstract class TestSessionEvent extends Equatable {
  const TestSessionEvent();
  @override
  List<Object> get props => [];
}

class StartTestSession extends TestSessionEvent {
  final OrientationTest test;
  const StartTestSession(this.test);
  @override
  List<Object> get props => [test];
}

class AnswerQuestion extends TestSessionEvent {
  final String questionId;
  final dynamic value; // Can be int (Likert), String (Choice), List<String> (Ranking), double (Slider)

  const AnswerQuestion({required this.questionId, required this.value});

  @override
  List<Object> get props => [questionId, value];
}

class NextQuestion extends TestSessionEvent {}

class PreviousQuestion extends TestSessionEvent {}

class ContinueFromSection extends TestSessionEvent {}

// States
abstract class TestSessionState extends Equatable {
  const TestSessionState();
  @override
  List<Object?> get props => [];
}

class TestSessionInitial extends TestSessionState {}

class TestSessionInProgress extends TestSessionState {
  final OrientationTest test;
  final int currentQuestionIndex;
  final Map<String, dynamic> responses;
  final double progress; // 0.0 to 1.0
  final List<SectionInfo> sections;
  final int currentSectionIndex;

  const TestSessionInProgress({
    required this.test,
    required this.currentQuestionIndex,
    required this.responses,
    required this.progress,
    required this.sections,
    required this.currentSectionIndex,
  });

  Question get currentQuestion => test.questions[currentQuestionIndex];
  bool get isLastQuestion => currentQuestionIndex == test.questions.length - 1;
  bool get canGoBack => currentQuestionIndex > 0;
  bool get canGoNext => responses.containsKey(currentQuestion.id);

  SectionInfo get currentSection => sections[currentSectionIndex];

  TestSessionInProgress copyWith({
    OrientationTest? test,
    int? currentQuestionIndex,
    Map<String, dynamic>? responses,
    int? currentSectionIndex,
  }) {
    final newTest = test ?? this.test;
    final newIndex = currentQuestionIndex ?? this.currentQuestionIndex;
    final newResponses = responses ?? this.responses;

    return TestSessionInProgress(
      test: newTest,
      currentQuestionIndex: newIndex,
      responses: newResponses,
      progress: (newIndex) / newTest.questions.length,
      sections: sections,
      currentSectionIndex: currentSectionIndex ?? this.currentSectionIndex,
    );
  }

  @override
  List<Object?> get props => [test, currentQuestionIndex, responses, progress, currentSectionIndex];
}

class TestSessionSectionComplete extends TestSessionState {
  final OrientationTest test;
  final int completedSectionIndex;
  final Map<String, dynamic> responses;
  final List<SectionInfo> sections;
  final String sectionTitle;
  final String feedbackMessage;
  final int nextQuestionIndex;

  const TestSessionSectionComplete({
    required this.test,
    required this.completedSectionIndex,
    required this.responses,
    required this.sections,
    required this.sectionTitle,
    required this.feedbackMessage,
    required this.nextQuestionIndex,
  });

  @override
  List<Object?> get props => [test, completedSectionIndex, responses, sectionTitle];
}

class TestSessionReadyToSubmit extends TestSessionState {
  final OrientationTest test;
  final Map<String, dynamic> responses;

  const TestSessionReadyToSubmit({required this.test, required this.responses});

  @override
  List<Object?> get props => [test, responses];
}

class SectionInfo {
  final String title;
  final IconData emoji;
  final int startIndex;
  final int endIndex; // inclusive
  final String feedbackTemplate;

  const SectionInfo({
    required this.title,
    required this.emoji,
    required this.startIndex,
    required this.endIndex,
    required this.feedbackTemplate,
  });
}

class TestSessionBloc extends Bloc<TestSessionEvent, TestSessionState> {
  TestSessionBloc() : super(TestSessionInitial()) {
    on<StartTestSession>(_onStartSession);
    on<AnswerQuestion>(_onAnswerQuestion);
    on<NextQuestion>(_onNextQuestion);
    on<PreviousQuestion>(_onPreviousQuestion);
    on<ContinueFromSection>(_onContinueFromSection);
  }

  void _onStartSession(StartTestSession event, Emitter<TestSessionState> emit) {
    final sections = _buildSections(event.test);
    emit(TestSessionInProgress(
      test: event.test,
      currentQuestionIndex: 0,
      responses: const {},
      progress: 0.0,
      sections: sections,
      currentSectionIndex: 0,
    ));
  }

  void _onAnswerQuestion(AnswerQuestion event, Emitter<TestSessionState> emit) {
    final currentState = state;
    if (currentState is TestSessionInProgress) {
      final updatedResponses = Map<String, dynamic>.from(currentState.responses);
      updatedResponses[event.questionId] = event.value;

      emit(currentState.copyWith(responses: updatedResponses));
    }
  }

  void _onNextQuestion(NextQuestion event, Emitter<TestSessionState> emit) {
    final currentState = state;
    if (currentState is TestSessionInProgress) {
      if (currentState.isLastQuestion) {
        emit(TestSessionReadyToSubmit(
          test: currentState.test,
          responses: currentState.responses,
        ));
      } else {
        final nextIndex = currentState.currentQuestionIndex + 1;

        // Check if we're crossing a section boundary
        final currentSection = currentState.currentSection;
        if (currentState.currentQuestionIndex == currentSection.endIndex &&
            currentState.currentSectionIndex < currentState.sections.length - 1) {
          final nextSection = currentState.sections[currentState.currentSectionIndex + 1];
          final feedback = _generateSectionFeedback(
            currentState.test,
            currentState.responses,
            currentSection,
          );
          emit(TestSessionSectionComplete(
            test: currentState.test,
            completedSectionIndex: currentState.currentSectionIndex,
            responses: currentState.responses,
            sections: currentState.sections,
            sectionTitle: nextSection.title,
            feedbackMessage: feedback,
            nextQuestionIndex: nextIndex,
          ));
        } else {
          emit(currentState.copyWith(
            currentQuestionIndex: nextIndex,
          ));
        }
      }
    }
  }

  void _onContinueFromSection(ContinueFromSection event, Emitter<TestSessionState> emit) {
    final currentState = state;
    if (currentState is TestSessionSectionComplete) {
      emit(TestSessionInProgress(
        test: currentState.test,
        currentQuestionIndex: currentState.nextQuestionIndex,
        responses: currentState.responses,
        progress: currentState.nextQuestionIndex / currentState.test.questions.length,
        sections: currentState.sections,
        currentSectionIndex: currentState.completedSectionIndex + 1,
      ));
    }
  }

  void _onPreviousQuestion(PreviousQuestion event, Emitter<TestSessionState> emit) {
    final currentState = state;
    if (currentState is TestSessionInProgress && currentState.canGoBack) {
      final prevIndex = currentState.currentQuestionIndex - 1;
      // Find which section the previous question belongs to
      int sectionIdx = currentState.currentSectionIndex;
      for (int i = 0; i < currentState.sections.length; i++) {
        if (prevIndex >= currentState.sections[i].startIndex &&
            prevIndex <= currentState.sections[i].endIndex) {
          sectionIdx = i;
          break;
        }
      }
      emit(currentState.copyWith(
        currentQuestionIndex: prevIndex,
        currentSectionIndex: sectionIdx,
      ));
    }
  }

  List<SectionInfo> _buildSections(OrientationTest test) {
    // Group questions by their sectionTitle; consecutive questions with the same
    // sectionTitle (or null) form one section.
    final sections = <SectionInfo>[];
    if (test.questions.isEmpty) return sections;

    String? currentSectionTitle = test.questions.first.sectionTitle;
    int startIdx = 0;

    for (int i = 1; i < test.questions.length; i++) {
      final q = test.questions[i];
      if (q.sectionTitle != null && q.sectionTitle != currentSectionTitle) {
        sections.add(SectionInfo(
          title: currentSectionTitle ?? 'Section ${sections.length + 1}',
          emoji: _getSectionEmoji(currentSectionTitle),
          startIndex: startIdx,
          endIndex: i - 1,
          feedbackTemplate: _getSectionFeedbackTemplate(currentSectionTitle),
        ));
        currentSectionTitle = q.sectionTitle;
        startIdx = i;
      }
    }
    // Last section
    sections.add(SectionInfo(
      title: currentSectionTitle ?? 'Section ${sections.length + 1}',
      emoji: _getSectionEmoji(currentSectionTitle),
      startIndex: startIdx,
      endIndex: test.questions.length - 1,
      feedbackTemplate: _getSectionFeedbackTemplate(currentSectionTitle),
    ));

    return sections;
  }

  IconData _getSectionEmoji(String? title) {
    if (title == null) return Icons.assignment_rounded;
    final lower = title.toLowerCase();
    if (lower.contains('intérêt') || lower.contains('riasec')) return Icons.track_changes_rounded;
    if (lower.contains('intelligence')) return Icons.psychology_rounded;
    if (lower.contains('valeur')) return Icons.diamond_rounded;
    if (lower.contains('personnalité') || lower.contains('mbti')) return Icons.face_rounded;
    if (lower.contains('aptitude')) return Icons.menu_book_rounded;
    if (lower.contains('entrepreneur')) return Icons.rocket_launch_rounded;
    if (lower.contains('scénario')) return Icons.movie_rounded;
    if (lower.contains('préférence')) return Icons.bolt_rounded;
    if (lower.contains('style')) return Icons.palette_rounded;
    return Icons.assignment_rounded;
  }

  String _getSectionFeedbackTemplate(String? title) {
    if (title == null) return 'Bonne continuation !';
    final lower = title.toLowerCase();
    if (lower.contains('intérêt')) return 'Tes intérêts se dessinent ! Continue pour affiner ton profil.';
    if (lower.contains('intelligence')) return 'On découvre tes forces ! Encore quelques questions.';
    if (lower.contains('valeur')) return 'Tes valeurs sont claires ! Voyons la suite.';
    if (lower.contains('personnalité')) return 'Ta personnalité prend forme ! Presque fini.';
    if (lower.contains('aptitude')) return 'Tes aptitudes sont identifiées ! Continue.';
    if (lower.contains('entrepreneur')) return 'Ton profil entrepreneurial se dessine !';
    return 'Super ! Passons à la suite.';
  }

  String _generateSectionFeedback(
    OrientationTest test,
    Map<String, dynamic> responses,
    SectionInfo section,
  ) {
    return section.feedbackTemplate;
  }
}
