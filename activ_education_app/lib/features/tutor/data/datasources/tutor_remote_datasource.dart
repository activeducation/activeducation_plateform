import 'package:dio/dio.dart';

import '../../../../core/constants/api_endpoints.dart';
import '../models/quiz_model.dart';
import '../models/mastery_model.dart';

class TutorApiException implements Exception {
  final String message;
  final int? statusCode;

  const TutorApiException(this.message, {this.statusCode});

  /// True quand la fonctionnalité tuteur n'est pas activée côté backend (404).
  bool get isUnavailable => statusCode == 404;

  @override
  String toString() => 'TutorApiException($statusCode): $message';
}

abstract class TutorRemoteDataSource {
  Future<Quiz> generateQuiz({required String topic, int numQuestions});
  Future<Map<String, dynamic>> recordAnswer({
    required String skillId,
    required bool correct,
  });
  Future<List<MasterySkill>> getMastery();
  Future<Recommendation> getNextStep();
}

class TutorRemoteDataSourceImpl implements TutorRemoteDataSource {
  final Dio _dio;

  const TutorRemoteDataSourceImpl(this._dio);

  @override
  Future<Quiz> generateQuiz({
    required String topic,
    int numQuestions = 3,
  }) async {
    final data = await _post(
      ApiEndpoints.tutorQuizGenerate,
      {'topic': topic, 'num_questions': numQuestions},
    );
    return Quiz.fromJson(data);
  }

  @override
  Future<Map<String, dynamic>> recordAnswer({
    required String skillId,
    required bool correct,
  }) async {
    return _post(ApiEndpoints.tutorSkillAnswer(skillId), {'correct': correct});
  }

  @override
  Future<List<MasterySkill>> getMastery() async {
    final data = await _get(ApiEndpoints.tutorMastery);
    final rows = (data['mastery'] as List?) ?? const [];
    return rows
        .whereType<Map<String, dynamic>>()
        .map(MasterySkill.fromJson)
        .toList();
  }

  @override
  Future<Recommendation> getNextStep() async {
    final data = await _get(ApiEndpoints.tutorNextStep);
    return Recommendation.fromJson(data);
  }

  // ---- helpers ----

  Future<Map<String, dynamic>> _post(String path, Map<String, dynamic> body) async {
    try {
      final resp = await _dio.post(path, data: body);
      final data = resp.data;
      if (resp.statusCode != 200 || data is! Map<String, dynamic>) {
        throw TutorApiException('Réponse invalide du serveur',
            statusCode: resp.statusCode);
      }
      return data;
    } on DioException catch (e) {
      throw _mapError(e);
    }
  }

  Future<Map<String, dynamic>> _get(String path) async {
    try {
      final resp = await _dio.get(path);
      final data = resp.data;
      if (resp.statusCode != 200 || data is! Map<String, dynamic>) {
        throw TutorApiException('Réponse invalide du serveur',
            statusCode: resp.statusCode);
      }
      return data;
    } on DioException catch (e) {
      throw _mapError(e);
    }
  }

  TutorApiException _mapError(DioException e) {
    final status = e.response?.statusCode;
    final data = e.response?.data;
    String detail = e.message ?? 'Erreur réseau';
    if (data is Map<String, dynamic>) {
      detail = (data['detail'] ?? data['message'] ?? detail).toString();
    }
    return TutorApiException(detail, statusCode: status);
  }
}
