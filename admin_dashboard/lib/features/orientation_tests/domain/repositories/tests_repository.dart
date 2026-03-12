import '../entities/admin_test.dart';

abstract class TestsRepository {
  Future<PaginatedTests> getTests({int page = 1, int perPage = 20});

  Future<AdminTest> getTestById(String id);

  Future<AdminTest> createTest(Map<String, dynamic> data);

  Future<AdminTest> updateTest(String id, Map<String, dynamic> data);

  Future<AdminTest> duplicateTest(String id);

  Future<void> deleteTest(String id);
}
