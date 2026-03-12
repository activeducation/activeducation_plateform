import '../entities/admin_career.dart';

abstract class CareersRepository {
  Future<PaginatedCareers> getCareers({
    int page = 1,
    int perPage = 20,
    String? search,
    String? sector,
  });

  Future<AdminCareer> getCareerById(String id);

  Future<AdminCareer> createCareer(Map<String, dynamic> data);

  Future<AdminCareer> updateCareer(String id, Map<String, dynamic> data);

  Future<void> deleteCareer(String id);

  Future<List<String>> getSectors();
}
