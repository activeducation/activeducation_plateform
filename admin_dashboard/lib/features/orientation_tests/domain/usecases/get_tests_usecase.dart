import '../entities/admin_test.dart';
import '../repositories/tests_repository.dart';

class GetTestsUseCase {
  final TestsRepository _repository;

  GetTestsUseCase(this._repository);

  Future<PaginatedTests> call({int page = 1, int perPage = 20}) =>
      _repository.getTests(page: page, perPage: perPage);
}
