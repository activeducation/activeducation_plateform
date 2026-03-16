import 'package:dartz/dartz.dart';
import 'package:injectable/injectable.dart';
import '../repositories/elearning_repository.dart';

@lazySingleton
class CompleteLessonUsecase {
  final ElearningRepository _repository;

  CompleteLessonUsecase(this._repository);

  Future<Either<Exception, Map<String, dynamic>>> call(
    String id, {
    int? score,
    Map<String, String>? answers,
  }) async {
    return _repository.completeLesson(id, score: score, answers: answers);
  }
}
