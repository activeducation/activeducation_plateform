import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:dartz/dartz.dart';

import '../../domain/entities/course.dart';
import '../../domain/usecases/get_my_courses_usecase.dart';

abstract class SagaEvent extends Equatable {
  const SagaEvent();

  @override
  List<Object?> get props => [];
}

class LoadSaga extends SagaEvent {}

class SagaState extends Equatable {
  final List<Course> myCourses;
  final bool isLoading;
  final String? error;

  const SagaState({
    this.myCourses = const [],
    this.isLoading = true,
    this.error,
  });

  SagaState copyWith({
    List<Course>? myCourses,
    bool? isLoading,
    String? error,
  }) {
    return SagaState(
      myCourses: myCourses ?? this.myCourses,
      isLoading: isLoading ?? this.isLoading,
      error: error,
    );
  }

  @override
  List<Object?> get props => [myCourses, isLoading, error];
}

class SagaBloc extends Bloc<SagaEvent, SagaState> {
  final GetMyCoursesUsecase _getMyCourses;

  SagaBloc(this._getMyCourses) : super(const SagaState()) {
    on<LoadSaga>(_onLoadSaga);
  }

  Future<void> _onLoadSaga(LoadSaga event, Emitter<SagaState> emit) async {
    emit(state.copyWith(isLoading: true, error: null));
    final result = await _getMyCourses();
    result.fold(
      (error) => emit(state.copyWith(isLoading: false, error: error.toString())),
      (courses) => emit(state.copyWith(isLoading: false, myCourses: courses)),
    );
  }
}
