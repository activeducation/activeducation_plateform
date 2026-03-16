import 'package:dartz/dartz.dart';
import 'package:injectable/injectable.dart';
import '../entities/course.dart';
import '../repositories/elearning_repository.dart';

@lazySingleton
class GetCoursesUsecase {
  final ElearningRepository _repository;

  GetCoursesUsecase(this._repository);

  Future<Either<Exception, List<Course>>> call() async {
    return _repository.getCourses();
  }
}
