import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../data/datasources/tutor_remote_datasource.dart';
import '../../data/models/quiz_model.dart';

// ===========================================================================
// Events
// ===========================================================================

abstract class QuizEvent extends Equatable {
  const QuizEvent();
  @override
  List<Object?> get props => [];
}

class GenerateQuiz extends QuizEvent {
  final String topic;
  final int numQuestions;
  const GenerateQuiz(this.topic, {this.numQuestions = 4});
  @override
  List<Object?> get props => [topic, numQuestions];
}

class ResetQuiz extends QuizEvent {
  const ResetQuiz();
}

/// Soumet les résultats d'un quiz rattaché à une compétence (alimente le BKT).
class SubmitQuizResults extends QuizEvent {
  final String skillId;
  final List<bool> answers;
  const SubmitQuizResults(this.skillId, this.answers);
  @override
  List<Object?> get props => [skillId, answers];
}

// ===========================================================================
// States
// ===========================================================================

abstract class QuizState extends Equatable {
  const QuizState();
  @override
  List<Object?> get props => [];
}

class QuizInitial extends QuizState {
  const QuizInitial();
}

class QuizLoading extends QuizState {
  const QuizLoading();
}

class QuizReady extends QuizState {
  final Quiz quiz;
  const QuizReady(this.quiz);
  @override
  List<Object?> get props => [quiz];
}

class QuizFailure extends QuizState {
  final String message;
  final bool unavailable;
  const QuizFailure(this.message, {this.unavailable = false});
  @override
  List<Object?> get props => [message, unavailable];
}

// ===========================================================================
// BLoC
// ===========================================================================

class QuizBloc extends Bloc<QuizEvent, QuizState> {
  final TutorRemoteDataSource _dataSource;

  QuizBloc(this._dataSource) : super(const QuizInitial()) {
    on<GenerateQuiz>(_onGenerate);
    on<ResetQuiz>((_, emit) => emit(const QuizInitial()));
    on<SubmitQuizResults>(_onSubmitResults);
  }

  Future<void> _onSubmitResults(
    SubmitQuizResults event,
    Emitter<QuizState> emit,
  ) async {
    // Best-effort : alimenter le BKT ne doit pas perturber l'écran de score.
    try {
      await _dataSource.submitQuiz(
        skillId: event.skillId,
        answers: event.answers,
      );
    } catch (_) {
      // silencieux : l'enregistrement de maîtrise est secondaire côté UX.
    }
  }

  Future<void> _onGenerate(GenerateQuiz event, Emitter<QuizState> emit) async {
    emit(const QuizLoading());
    try {
      final quiz = await _dataSource.generateQuiz(
        topic: event.topic,
        numQuestions: event.numQuestions,
      );
      if (quiz.isEmpty) {
        emit(const QuizFailure('Aucune question générée, réessaie.'));
        return;
      }
      emit(QuizReady(quiz));
    } on TutorApiException catch (e) {
      emit(QuizFailure(
        e.isUnavailable
            ? "Le tuteur n'est pas encore activé."
            : 'Impossible de générer le quiz pour le moment.',
        unavailable: e.isUnavailable,
      ));
    } catch (_) {
      emit(const QuizFailure('Impossible de générer le quiz pour le moment.'));
    }
  }
}
