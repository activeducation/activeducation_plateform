import 'package:dartz/dartz.dart';
import 'package:injectable/injectable.dart';
import '../entities/course.dart';
import '../repositories/elearning_repository.dart';

@lazySingleton
class GetLessonUsecase {
  final ElearningRepository _repository;

  GetLessonUsecase(this._repository);

  Future<Either<Exception, LessonDetail>> call(String id) async {
    return _repository.getLesson(id);
  }
}
