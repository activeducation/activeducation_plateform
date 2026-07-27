import '../../../core/constants/api_endpoints.dart';
import '../../../core/network/api_client.dart';
import 'orientation_data_models.dart';

/// Acces aux donnees alimentant le moteur d'orientation multi-criteres :
/// matieres cles des metiers (critere "notes") et cout des formations
/// (critere "budget").
class OrientationDataRepository {
  final ApiClient _client;

  const OrientationDataRepository(this._client);

  Future<List<CareerSubjects>> getCareers() async {
    final resp = await _client.get(ApiEndpoints.adminOrientationCareers);
    final data = resp.data;
    final rows = data is Map ? (data['careers'] as List? ?? const []) : const [];
    return rows
        .whereType<Map<String, dynamic>>()
        .map(CareerSubjects.fromJson)
        .toList();
  }

  Future<List<ProgramCost>> getPrograms() async {
    final resp = await _client.get(ApiEndpoints.adminOrientationPrograms);
    final data = resp.data;
    final rows = data is Map ? (data['programs'] as List? ?? const []) : const [];
    return rows
        .whereType<Map<String, dynamic>>()
        .map(ProgramCost.fromJson)
        .toList();
  }

  Future<void> saveKeySubjects(String careerId, List<String> subjects) {
    return _client.patch(
      ApiEndpoints.adminOrientationCareer(careerId),
      data: {'key_subjects': subjects},
    );
  }

  Future<void> saveProgramCost(
    String programId, {
    int? tuitionAnnualFcfa,
    bool? isPublic,
  }) {
    return _client.patch(
      ApiEndpoints.adminOrientationProgram(programId),
      // Champ absent = inchange (semantique PATCH cote backend).
      data: {
        'tuition_annual_fcfa': ?tuitionAnnualFcfa,
        'is_public': ?isPublic,
      },
    );
  }
}
