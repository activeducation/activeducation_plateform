import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';
import '../../domain/entities/admin_course.dart';
import '../../domain/repositories/elearning_repository.dart';

// Events
abstract class CoursesEvent extends Equatable {
  const CoursesEvent();
  @override
  List<Object?> get props => [];
}

class LoadCourses extends CoursesEvent {
  final int page;
  final String? search;
  final String? schoolId;
  final bool? isPublished;

  const LoadCourses({
    this.page = 1,
    this.search,
    this.schoolId,
    this.isPublished,
  });

  @override
  List<Object?> get props => [page, search, schoolId, isPublished];
}

class DeleteCourse extends CoursesEvent {
  final String courseId;
  const DeleteCourse(this.courseId);
  @override
  List<Object?> get props => [courseId];
}

class LoadSchoolsWithCourses extends CoursesEvent {}

// State
abstract class CoursesState extends Equatable {
  const CoursesState();
  @override
  List<Object?> get props => [];
}

class CoursesInitial extends CoursesState {}

class CoursesLoading extends CoursesState {}

class CoursesLoaded extends CoursesState {
  final PaginatedCourses courses;
  final List<SchoolWithCourses> schools;

  const CoursesLoaded({
    required this.courses,
    this.schools = const [],
  });

  @override
  List<Object?> get props => [courses, schools];
}

class CoursesError extends CoursesState {
  final String message;
  const CoursesError(this.message);
  @override
  List<Object?> get props => [message];
}

class CourseDeleted extends CoursesState {}

// BLoC
class CoursesBloc extends Bloc<CoursesEvent, CoursesState> {
  final ElearningRepository _repository;

  CoursesBloc(this._repository) : super(CoursesInitial()) {
    on<LoadCourses>(_onLoadCourses);
    on<DeleteCourse>(_onDeleteCourse);
    on<LoadSchoolsWithCourses>(_onLoadSchools);
  }

  Future<void> _onLoadCourses(LoadCourses event, Emitter<CoursesState> emit) async {
    emit(CoursesLoading());
    try {
      final courses = await _repository.getCourses(
        page: event.page,
        search: event.search,
        schoolId: event.schoolId,
        isPublished: event.isPublished,
      );
      emit(CoursesLoaded(courses: courses));
    } catch (e) {
      emit(CoursesError(e.toString()));
    }
  }

  Future<void> _onDeleteCourse(DeleteCourse event, Emitter<CoursesState> emit) async {
    try {
      await _repository.deleteCourse(event.courseId);
      emit(CourseDeleted());
      add(const LoadCourses());
    } catch (e) {
      emit(CoursesError(e.toString()));
    }
  }

  Future<void> _onLoadSchools(LoadSchoolsWithCourses event, Emitter<CoursesState> emit) async {
    final currentState = state;
    try {
      final schools = await _repository.getSchoolsWithCourses();
      if (currentState is CoursesLoaded) {
        emit(CoursesLoaded(courses: currentState.courses, schools: schools));
      }
    } catch (e) {
      emit(CoursesError(e.toString()));
    }
  }
}