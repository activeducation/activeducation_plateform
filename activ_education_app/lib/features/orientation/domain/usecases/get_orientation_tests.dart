import 'package:dartz/dartz.dart';
import 'package:injectable/injectable.dart';
import '../../domain/entities/orientation_test.dart';
import '../../domain/repositories/orientation_repository.dart';

@lazySingleton
class GetOrientationTests {
  final OrientationRepository _repository;

  GetOrientationTests(this._repository);

  Future<Either<Exception, List<OrientationTest>>> call() async {
    return _repository.getOrientationTests();
  }
}
