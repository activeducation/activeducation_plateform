import 'package:dartz/dartz.dart';
import 'package:injectable/injectable.dart';
import '../entities/course.dart';
import '../repositories/elearning_repository.dart';

@lazySingleton
class GetCourseDetailUsecase {
  final ElearningRepository _repository;

  GetCourseDetailUsecase(this._repository);

  Future<Either<Exception, CourseDetail>> call(String id) async {
    return _repository.getCourseDetail(id);
  }
}
