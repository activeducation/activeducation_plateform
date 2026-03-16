import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:injectable/injectable.dart';

import '../../domain/entities/course.dart';
import '../../domain/usecases/get_courses_usecase.dart';
import '../../domain/usecases/get_my_courses_usecase.dart';

// ─── Events ───────────────────────────────────────────────────────────────────

abstract class CatalogEvent extends Equatable {
  const CatalogEvent();

  @override
  List<Object?> get props => [];
}

class LoadCatalog extends CatalogEvent {}

class LoadMyCourses extends CatalogEvent {}

// ─── States ───────────────────────────────────────────────────────────────────

abstract class CatalogState extends Equatable {
  const CatalogState();

  @override
  List<Object?> get props => [];
}

class CatalogInitial extends CatalogState {}

class CatalogLoading extends CatalogState {}

class CatalogLoaded extends CatalogState {
  final List<Course> courses;
  final List<Course> myCourses;

  const CatalogLoaded({
    required this.courses,
    required this.myCourses,
  });

  @override
  List<Object?> get props => [courses, myCourses];
}

class CatalogError extends CatalogState {
  final String message;

  const CatalogError(this.message);

  @override
  List<Object?> get props => [message];
}

// ─── BLoC ─────────────────────────────────────────────────────────────────────

@injectable
class CatalogBloc extends Bloc<CatalogEvent, CatalogState> {
  final GetCoursesUsecase _getCoursesUsecase;
  final GetMyCoursesUsecase _getMyCoursesUsecase;

  CatalogBloc(
    this._getCoursesUsecase,
    this._getMyCoursesUsecase,
  ) : super(CatalogInitial()) {
    on<LoadCatalog>(_onLoadCatalog);
    on<LoadMyCourses>(_onLoadMyCourses);
  }

  Future<void> _onLoadCatalog(
    LoadCatalog event,
    Emitter<CatalogState> emit,
  ) async {
    emit(CatalogLoading());

    final coursesResult = await _getCoursesUsecase();
    final myCoursesResult = await _getMyCoursesUsecase();

    coursesResult.fold(
      (error) => emit(CatalogError(error.toString())),
      (courses) {
        final myCourses = myCoursesResult.fold(
          (_) => <Course>[],
          (my) => my,
        );
        emit(CatalogLoaded(courses: courses, myCourses: myCourses));
      },
    );
  }

  Future<void> _onLoadMyCourses(
    LoadMyCourses event,
    Emitter<CatalogState> emit,
  ) async {
    final currentState = state;
    if (currentState is CatalogLoaded) {
      final result = await _getMyCoursesUsecase();
      result.fold(
        (error) => emit(CatalogError(error.toString())),
        (myCourses) => emit(
          CatalogLoaded(courses: currentState.courses, myCourses: myCourses),
        ),
      );
    }
  }
}
