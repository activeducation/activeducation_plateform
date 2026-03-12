import '../entities/admin_career.dart';
import '../repositories/careers_repository.dart';

class GetCareersUseCase {
  final CareersRepository _repository;

  GetCareersUseCase(this._repository);

  Future<PaginatedCareers> call({
    int page = 1,
    int perPage = 20,
    String? search,
    String? sector,
  }) =>
      _repository.getCareers(
        page: page,
        perPage: perPage,
        search: search,
        sector: sector,
      );
}
