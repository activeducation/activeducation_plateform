import '../entities/admin_school.dart';
import '../repositories/schools_repository.dart';

class GetSchoolsUseCase {
  final SchoolsRepository _repository;

  GetSchoolsUseCase(this._repository);

  Future<PaginatedSchools> call({
    int page = 1,
    int perPage = 20,
    String? search,
    bool? verified,
  }) =>
      _repository.getSchools(
        page: page,
        perPage: perPage,
        search: search,
        verified: verified,
      );
}
