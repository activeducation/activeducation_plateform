import 'package:dio/dio.dart';
import 'package:injectable/injectable.dart';

import '../../../../core/constants/api_endpoints.dart';
import '../models/orientation_test_model.dart';
import '../models/test_result_model.dart';

abstract class OrientationRemoteDataSource {
  Future<List<OrientationTestModel>> getOrientationTests();
  Future<OrientationTestModel> getTestById(String id);
  Future<TestResultModel> submitTest(
    String testId,
    Map<String, dynamic> responses,
  );
}

class OrientationApiException implements Exception {
  final String message;
  final int? statusCode;

  const OrientationApiException(this.message, {this.statusCode});

  @override
  String toString() =>
      'OrientationApiException(statusCode: $statusCode, message: $message)';
}

@LazySingleton(as: OrientationRemoteDataSource)
class OrientationRemoteDataSourceImpl implements OrientationRemoteDataSource {
  final Dio _dio;

  OrientationRemoteDataSourceImpl(@Named('apiClient') this._dio);

  @override
  Future<List<OrientationTestModel>> getOrientationTests() async {
    try {
      final response = await _dio.get('${ApiEndpoints.orientation}/mobile/tests');
      final data = response.data;

      if (response.statusCode != 200 || data is! List) {
        throw OrientationApiException(
          'Format de reponse invalide pour la liste des tests',
          statusCode: response.statusCode,
        );
      }

      return data
          .map((json) =>
              OrientationTestModel.fromJson(json as Map<String, dynamic>))
          .toList();
    } on DioException catch (e) {
      throw OrientationApiException(
        _buildDioMessage('chargement des tests', e),
        statusCode: e.response?.statusCode,
      );
    }
  }

  @override
  Future<OrientationTestModel> getTestById(String id) async {
    try {
      final response = await _dio.get('${ApiEndpoints.orientation}/mobile/tests/$id');
      final data = response.data;

      if (response.statusCode != 200 || data is! Map<String, dynamic>) {
        throw OrientationApiException(
          'Format de reponse invalide pour le test',
          statusCode: response.statusCode,
        );
      }

      return OrientationTestModel.fromJson(data);
    } on DioException catch (e) {
      throw OrientationApiException(
        _buildDioMessage('chargement du test', e),
        statusCode: e.response?.statusCode,
      );
    }
  }

  @override
  Future<TestResultModel> submitTest(
    String testId,
    Map<String, dynamic> responses,
  ) async {
    try {
      final stringResponses = responses.map(
        (key, value) => MapEntry(key, value.toString()),
      );

      final response = await _dio.post(
        '${ApiEndpoints.orientation}/sessions/$testId/submit',
        data: {'responses': stringResponses},
      );
      final data = response.data;

      if (response.statusCode != 200 || data is! Map<String, dynamic>) {
        throw OrientationApiException(
          'Format de reponse invalide pour la soumission du test',
          statusCode: response.statusCode,
        );
      }

      final adaptedData = <String, dynamic>{
        'testId': data['test_id']?.toString(),
        'scores': data['scores'],
        'dominantTraits': data['dominant_traits'],
        'recommendations': data['recommendations'],
        'interpretation': data['interpretation'],
        'matchingPrograms': data['matching_programs'],
      };

      return TestResultModel.fromJson(adaptedData);
    } on DioException catch (e) {
      throw OrientationApiException(
        _buildDioMessage('soumission du test', e),
        statusCode: e.response?.statusCode,
      );
    }
  }

  String _buildDioMessage(String context, DioException e) {
    final status = e.response?.statusCode;
    final data = e.response?.data;

    var serverMessage = e.message ?? 'Erreur reseau';
    if (data is Map<String, dynamic>) {
      if (data['message'] is String) {
        serverMessage = data['message'] as String;
      } else if (data['detail'] is String) {
        serverMessage = data['detail'] as String;
      } else if (data['error'] is String) {
        serverMessage = data['error'] as String;
      }
    }

    final statusLabel = status != null ? ' (HTTP $status)' : '';
    return 'Erreur lors du $context$statusLabel: $serverMessage';
  }
}
