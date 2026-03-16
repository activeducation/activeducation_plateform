import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:injectable/injectable.dart';

import '../../domain/entities/course.dart';
import '../../domain/usecases/enroll_course_usecase.dart';
import '../../domain/usecases/get_course_detail_usecase.dart';

// ─── Events ───────────────────────────────────────────────────────────────────

abstract class CourseEvent extends Equatable {
  const CourseEvent();

  @override
  List<Object?> get props => [];
}

class LoadCourse extends CourseEvent {
  final String id;

  const LoadCourse(this.id);

  @override
  List<Object?> get props => [id];
}

class EnrollCourse extends CourseEvent {
  final String id;

  const EnrollCourse(this.id);

  @override
  List<Object?> get props => [id];
}

// ─── States ───────────────────────────────────────────────────────────────────

abstract class CourseState extends Equatable {
  const CourseState();

  @override
  List<Object?> get props => [];
}

class CourseInitial extends CourseState {}

class CourseLoading extends CourseState {}

class CourseLoaded extends CourseState {
  final CourseDetail course;

  const CourseLoaded(this.course);

  @override
  List<Object?> get props => [course];
}

class CourseEnrolling extends CourseState {
  final CourseDetail course;

  const CourseEnrolling(this.course);

  @override
  List<Object?> get props => [course];
}

class CourseEnrolled extends CourseState {
  final CourseDetail course;

  const CourseEnrolled(this.course);

  @override
  List<Object?> get props => [course];
}

class CourseError extends CourseState {
  final String message;

  const CourseError(this.message);

  @override
  List<Object?> get props => [message];
}

// ─── BLoC ─────────────────────────────────────────────────────────────────────

@injectable
class CourseBloc extends Bloc<CourseEvent, CourseState> {
  final GetCourseDetailUsecase _getCourseDetailUsecase;
  final EnrollCourseUsecase _enrollCourseUsecase;

  CourseBloc(
    this._getCourseDetailUsecase,
    this._enrollCourseUsecase,
  ) : super(CourseInitial()) {
    on<LoadCourse>(_onLoadCourse);
    on<EnrollCourse>(_onEnrollCourse);
  }

  Future<void> _onLoadCourse(
    LoadCourse event,
    Emitter<CourseState> emit,
  ) async {
    emit(CourseLoading());

    final result = await _getCourseDetailUsecase(event.id);
    result.fold(
      (error) => emit(CourseError(error.toString())),
      (course) => emit(CourseLoaded(course)),
    );
  }

  Future<void> _onEnrollCourse(
    EnrollCourse event,
    Emitter<CourseState> emit,
  ) async {
    final currentState = state;
    if (currentState is CourseLoaded) {
      emit(CourseEnrolling(currentState.course));

      final result = await _enrollCourseUsecase(event.id);
      result.fold(
        (error) => emit(CourseError(error.toString())),
        (_) async {
          // Reload course detail to get updated enrollment status
          final reloadResult = await _getCourseDetailUsecase(event.id);
          reloadResult.fold(
            (error) => emit(CourseEnrolled(currentState.course)),
            (course) => emit(CourseEnrolled(course)),
          );
        },
      );
    }
  }
}
