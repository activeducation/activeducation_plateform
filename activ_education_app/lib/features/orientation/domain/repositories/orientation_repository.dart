import 'package:dartz/dartz.dart';
import '../entities/orientation_test.dart';
import '../entities/test_result.dart';

abstract class OrientationRepository {
  Future<Either<Exception, List<OrientationTest>>> getOrientationTests();
  Future<Either<Exception, OrientationTest>> getTestById(String id);
  Future<Either<Exception, TestResult>> submitTest(String testId, Map<String, dynamic> responses);
}
