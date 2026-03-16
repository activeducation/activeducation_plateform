import 'package:dartz/dartz.dart';
import 'package:injectable/injectable.dart';

import '../../domain/entities/course.dart';
import '../../domain/repositories/elearning_repository.dart';
import '../datasources/elearning_remote_datasource.dart';

@LazySingleton(as: ElearningRepository)
class ElearningRepositoryImpl implements ElearningRepository {
  final ElearningRemoteDataSource _remoteDataSource;

  ElearningRepositoryImpl(this._remoteDataSource);

  @override
  Future<Either<Exception, List<Course>>> getCourses() async {
    try {
      final courses = await _remoteDataSource.getCourses();
      return Right(courses);
    } catch (e) {
      return Left(Exception(e.toString()));
    }
  }

  @override
  Future<Either<Exception, CourseDetail>> getCourseDetail(String id) async {
    try {
      final course = await _remoteDataSource.getCourseDetail(id);
      return Right(course);
    } catch (e) {
      return Left(Exception(e.toString()));
    }
  }

  @override
  Future<Either<Exception, LessonDetail>> getLesson(String id) async {
    try {
      final lesson = await _remoteDataSource.getLesson(id);
      return Right(lesson);
    } catch (e) {
      return Left(Exception(e.toString()));
    }
  }

  @override
  Future<Either<Exception, bool>> enrollCourse(String id) async {
    try {
      final result = await _remoteDataSource.enrollCourse(id);
      return Right(result);
    } catch (e) {
      return Left(Exception(e.toString()));
    }
  }

  @override
  Future<Either<Exception, List<Course>>> getMyCourses() async {
    try {
      final courses = await _remoteDataSource.getMyCourses();
      return Right(courses);
    } catch (e) {
      return Left(Exception(e.toString()));
    }
  }

  @override
  Future<Either<Exception, Map<String, dynamic>>> completeLesson(
    String id, {
    int? score,
    Map<String, String>? answers,
  }) async {
    try {
      final result = await _remoteDataSource.completeLesson(
        id,
        score: score,
        answers: answers,
      );
      return Right(result);
    } catch (e) {
      return Left(Exception(e.toString()));
    }
  }
}
