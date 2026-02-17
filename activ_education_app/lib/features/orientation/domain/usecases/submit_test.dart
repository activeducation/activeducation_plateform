import 'package:dartz/dartz.dart';
import 'package:injectable/injectable.dart';
import '../../domain/entities/test_result.dart';
import '../../domain/repositories/orientation_repository.dart';

@lazySingleton
class SubmitTest {
  final OrientationRepository _repository;

  SubmitTest(this._repository);

  Future<Either<Exception, TestResult>> call(String testId, Map<String, dynamic> responses) async {
    return _repository.submitTest(testId, responses);
  }
}
