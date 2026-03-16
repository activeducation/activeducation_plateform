import 'package:dartz/dartz.dart';
import 'package:injectable/injectable.dart';
import '../repositories/elearning_repository.dart';

@lazySingleton
class EnrollCourseUsecase {
  final ElearningRepository _repository;

  EnrollCourseUsecase(this._repository);

  Future<Either<Exception, bool>> call(String id) async {
    return _repository.enrollCourse(id);
  }
}
