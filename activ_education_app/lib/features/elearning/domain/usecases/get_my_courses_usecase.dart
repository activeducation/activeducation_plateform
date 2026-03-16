import 'package:dartz/dartz.dart';
import 'package:injectable/injectable.dart';
import '../entities/course.dart';
import '../repositories/elearning_repository.dart';

@lazySingleton
class GetMyCoursesUsecase {
  final ElearningRepository _repository;

  GetMyCoursesUsecase(this._repository);

  Future<Either<Exception, List<Course>>> call() async {
    return _repository.getMyCourses();
  }
}
