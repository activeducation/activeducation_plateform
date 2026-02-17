import 'package:dartz/dartz.dart';
import 'package:injectable/injectable.dart';
import '../../domain/entities/orientation_test.dart';
import '../../domain/entities/test_result.dart';
import '../../domain/repositories/orientation_repository.dart';
import '../datasources/orientation_remote_data_source.dart';

@LazySingleton(as: OrientationRepository)
class OrientationRepositoryImpl implements OrientationRepository {
  final OrientationRemoteDataSource _remoteDataSource;

  OrientationRepositoryImpl(this._remoteDataSource);

  @override
  Future<Either<Exception, List<OrientationTest>>> getOrientationTests() async {
    try {
      final tests = await _remoteDataSource.getOrientationTests();
      return Right(tests);
    } catch (e) {
      return Left(Exception(e.toString()));
    }
  }

  @override
  Future<Either<Exception, OrientationTest>> getTestById(String id) async {
    try {
      final test = await _remoteDataSource.getTestById(id);
      return Right(test);
    } catch (e) {
      return Left(Exception(e.toString()));
    }
  }

  @override
  Future<Either<Exception, TestResult>> submitTest(String testId, Map<String, dynamic> responses) async {
     try {
      final result = await _remoteDataSource.submitTest(testId, responses);
      return Right(result);
    } catch (e) {
      return Left(Exception(e.toString()));
    }
  }
}
