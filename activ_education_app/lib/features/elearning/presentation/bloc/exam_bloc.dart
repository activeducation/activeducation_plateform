import 'package:dio/dio.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/constants/api_endpoints.dart';
import '../../../../core/di/injection_container.dart';

abstract class ExamEvent extends Equatable {
  const ExamEvent();
  @override
  List<Object?> get props => [];
}

class LoadExam extends ExamEvent {
  final String courseId;
  const LoadExam(this.courseId);
  @override
  List<Object?> get props => [courseId];
}

class SubmitExam extends ExamEvent {
  final String courseId;
  final Map<String, dynamic> answers;
  const SubmitExam(this.courseId, this.answers);
  @override
  List<Object?> get props => [courseId, answers];
}

class ResetExam extends ExamEvent {}

class ExamState extends Equatable {
  final Map<String, dynamic>? exam;
  final bool isLoading;
  final String? error;
  final bool isSubmitting;
  final Map<String, dynamic>? result;

  const ExamState({
    this.exam,
    this.isLoading = true,
    this.error,
    this.isSubmitting = false,
    this.result,
  });

  ExamState copyWith({
    Map<String, dynamic>? exam,
    bool? isLoading,
    String? error,
    bool? isSubmitting,
    Map<String, dynamic>? result,
  }) {
    return ExamState(
      exam: exam ?? this.exam,
      isLoading: isLoading ?? this.isLoading,
      error: error,
      isSubmitting: isSubmitting ?? this.isSubmitting,
      result: result,
    );
  }

  @override
  List<Object?> get props => [exam, isLoading, error, isSubmitting, result];
}

class ExamBloc extends Bloc<ExamEvent, ExamState> {
  ExamBloc() : super(const ExamState()) {
    on<LoadExam>(_onLoadExam);
    on<SubmitExam>(_onSubmitExam);
    on<ResetExam>(_onResetExam);
  }

  Dio get _dio => getIt<Dio>(instanceName: 'apiClient');

  Future<void> _onLoadExam(LoadExam event, Emitter<ExamState> emit) async {
    emit(state.copyWith(isLoading: true, error: null));
    try {
      final res = await _dio.get(ApiEndpoints.elearningCourseExam(event.courseId));
      emit(state.copyWith(isLoading: false, exam: Map<String, dynamic>.from(res.data)));
    } on DioException catch (e) {
      final msg = e.response?.statusCode == 404
          ? "Aucun examen n'est disponible pour ce cours."
          : "Impossible de charger l'examen.";
      emit(state.copyWith(isLoading: false, error: msg));
    } catch (_) {
      emit(state.copyWith(isLoading: false, error: "Impossible de charger l'examen."));
    }
  }

  Future<void> _onSubmitExam(SubmitExam event, Emitter<ExamState> emit) async {
    emit(state.copyWith(isSubmitting: true, error: null));
    try {
      final res = await _dio.post(
        ApiEndpoints.elearningCourseExamSubmit(event.courseId),
        data: {'answers': event.answers},
      );
      emit(state.copyWith(
        isSubmitting: false,
        result: Map<String, dynamic>.from(res.data),
      ));
    } catch (_) {
      emit(state.copyWith(isSubmitting: false, error: "Échec de la soumission. Réessayez."));
    }
  }

  void _onResetExam(ResetExam event, Emitter<ExamState> emit) {
    emit(const ExamState(isLoading: false));
  }
}
