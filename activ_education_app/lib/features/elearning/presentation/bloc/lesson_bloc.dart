import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:injectable/injectable.dart';

import '../../data/datasources/elearning_remote_datasource.dart'
    show ElearningApiException;
import '../../domain/entities/course.dart';
import '../../domain/usecases/complete_lesson_usecase.dart';
import '../../domain/usecases/get_lesson_usecase.dart';

// ─── Events ───────────────────────────────────────────────────────────────────

abstract class LessonEvent extends Equatable {
  const LessonEvent();

  @override
  List<Object?> get props => [];
}

class LoadLesson extends LessonEvent {
  final String id;

  const LoadLesson(this.id);

  @override
  List<Object?> get props => [id];
}

class CompleteLesson extends LessonEvent {
  final String id;
  final int? score;
  final Map<String, String>? answers;

  const CompleteLesson(this.id, {this.score, this.answers});

  @override
  List<Object?> get props => [id, score, answers];
}

// ─── States ───────────────────────────────────────────────────────────────────

abstract class LessonState extends Equatable {
  const LessonState();

  @override
  List<Object?> get props => [];
}

class LessonInitial extends LessonState {}

class LessonLoading extends LessonState {}

class LessonLoaded extends LessonState {
  final LessonDetail lesson;

  const LessonLoaded(this.lesson);

  @override
  List<Object?> get props => [lesson];
}

class LessonCompleting extends LessonState {
  final LessonDetail lesson;

  const LessonCompleting(this.lesson);

  @override
  List<Object?> get props => [lesson];
}

class LessonCompleted extends LessonState {
  final int pointsEarned;
  final int? courseProgressPct;

  const LessonCompleted({
    required this.pointsEarned,
    this.courseProgressPct,
  });

  @override
  List<Object?> get props => [pointsEarned, courseProgressPct];
}

/// 401 : non connecte ou session expiree -> la page invite a se connecter.
class LessonAuthRequired extends LessonState {}

/// [message] est destine a l'eleve (jamais le toString() technique).
class LessonError extends LessonState {
  final String message;

  const LessonError(this.message);

  @override
  List<Object?> get props => [message];
}

// ─── BLoC ─────────────────────────────────────────────────────────────────────

@injectable
class LessonBloc extends Bloc<LessonEvent, LessonState> {
  final GetLessonUsecase _getLessonUsecase;
  final CompleteLessonUsecase _completeLessonUsecase;

  LessonBloc(
    this._getLessonUsecase,
    this._completeLessonUsecase,
  ) : super(LessonInitial()) {
    on<LoadLesson>(_onLoadLesson);
    on<CompleteLesson>(_onCompleteLesson);
  }

  Future<void> _onLoadLesson(
    LoadLesson event,
    Emitter<LessonState> emit,
  ) async {
    emit(LessonLoading());

    final result = await _getLessonUsecase(event.id);
    result.fold(
      (error) => emit(_stateForError(
        error,
        fallback:
            'Impossible de charger la leçon. Vérifiez votre connexion et réessayez.',
      )),
      (lesson) => emit(LessonLoaded(lesson)),
    );
  }

  Future<void> _onCompleteLesson(
    CompleteLesson event,
    Emitter<LessonState> emit,
  ) async {
    final currentState = state;
    if (currentState is LessonLoaded) {
      emit(LessonCompleting(currentState.lesson));

      final result = await _completeLessonUsecase(
        event.id,
        score: event.score,
        answers: event.answers,
      );

      result.fold(
        (error) => emit(_stateForError(
          error,
          fallback: 'Impossible d\'enregistrer votre progression. Réessayez.',
        )),
        (data) {
          final pointsEarned = (data['points_earned'] as num?)?.toInt() ??
              currentState.lesson.pointsReward;
          final courseProgressPct =
              (data['course_progress_pct'] as num?)?.toInt();

          emit(LessonCompleted(
            pointsEarned: pointsEarned,
            courseProgressPct: courseProgressPct,
          ));
        },
      );
    }
  }

  /// Codes renvoyes par GET/POST /elearning/lessons/{id} : 401 sans token,
  /// 403 si la lecon n'est pas gratuite et que l'eleve n'est pas inscrit,
  /// 404 si la lecon n'existe pas.
  LessonState _stateForError(Exception error, {required String fallback}) {
    if (error is ElearningApiException) {
      switch (error.statusCode) {
        case 401:
          return LessonAuthRequired();
        case 403:
          return const LessonError(
            'Inscrivez-vous au cours pour accéder à cette leçon.',
          );
        case 404:
          return const LessonError('Cette leçon est introuvable.');
      }
    }
    return LessonError(fallback);
  }
}
