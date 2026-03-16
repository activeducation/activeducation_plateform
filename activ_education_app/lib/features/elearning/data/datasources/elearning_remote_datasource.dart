import 'package:dio/dio.dart';
import 'package:injectable/injectable.dart';

import '../../../../core/constants/api_endpoints.dart';
import '../models/course_model.dart';

abstract class ElearningRemoteDataSource {
  Future<List<CourseModel>> getCourses();
  Future<CourseDetailModel> getCourseDetail(String id);
  Future<LessonDetailModel> getLesson(String id);
  Future<bool> enrollCourse(String id);
  Future<List<CourseModel>> getMyCourses();
  Future<Map<String, dynamic>> completeLesson(
    String id, {
    int? score,
    Map<String, String>? answers,
  });
}

class ElearningApiException implements Exception {
  final String message;
  final int? statusCode;

  const ElearningApiException(this.message, {this.statusCode});

  @override
  String toString() =>
      'ElearningApiException(statusCode: $statusCode, message: $message)';
}

@LazySingleton(as: ElearningRemoteDataSource)
class ElearningRemoteDataSourceImpl implements ElearningRemoteDataSource {
  final Dio _dio;

  ElearningRemoteDataSourceImpl(@Named('apiClient') this._dio);

  @override
  Future<List<CourseModel>> getCourses() async {
    try {
      final response = await _dio.get(ApiEndpoints.elearningCourses);
      final data = response.data;

      if (response.statusCode != 200 || data is! List) {
        throw ElearningApiException(
          'Format de reponse invalide pour la liste des cours',
          statusCode: response.statusCode,
        );
      }

      return data
          .map((json) => CourseModel.fromJson(json as Map<String, dynamic>))
          .toList();
    } on DioException catch (e) {
      throw ElearningApiException(
        _buildDioMessage('chargement des cours', e),
        statusCode: e.response?.statusCode,
      );
    }
  }

  @override
  Future<CourseDetailModel> getCourseDetail(String id) async {
    try {
      final response = await _dio.get('${ApiEndpoints.elearningCourses}/$id');
      final data = response.data;

      if (response.statusCode != 200 || data is! Map<String, dynamic>) {
        throw ElearningApiException(
          'Format de reponse invalide pour le detail du cours',
          statusCode: response.statusCode,
        );
      }

      return CourseDetailModel.fromJson(data);
    } on DioException catch (e) {
      throw ElearningApiException(
        _buildDioMessage('chargement du cours', e),
        statusCode: e.response?.statusCode,
      );
    }
  }

  @override
  Future<LessonDetailModel> getLesson(String id) async {
    try {
      final response = await _dio.get('${ApiEndpoints.elearningLessons}/$id');
      final data = response.data;

      if (response.statusCode != 200 || data is! Map<String, dynamic>) {
        throw ElearningApiException(
          'Format de reponse invalide pour la lecon',
          statusCode: response.statusCode,
        );
      }

      return LessonDetailModel.fromJson(data);
    } on DioException catch (e) {
      throw ElearningApiException(
        _buildDioMessage('chargement de la lecon', e),
        statusCode: e.response?.statusCode,
      );
    }
  }

  @override
  Future<bool> enrollCourse(String id) async {
    try {
      final response = await _dio.post(
        '${ApiEndpoints.elearningCourses}/$id/enroll',
      );

      if (response.statusCode != 200 && response.statusCode != 201) {
        throw ElearningApiException(
          'Echec de l\'inscription au cours',
          statusCode: response.statusCode,
        );
      }

      return true;
    } on DioException catch (e) {
      throw ElearningApiException(
        _buildDioMessage('inscription au cours', e),
        statusCode: e.response?.statusCode,
      );
    }
  }

  @override
  Future<List<CourseModel>> getMyCourses() async {
    try {
      final response = await _dio.get(ApiEndpoints.elearningMyCourses);
      final data = response.data;

      // API may return {courses: [...]} or directly a list
      List<dynamic> coursesList;
      if (data is List) {
        coursesList = data;
      } else if (data is Map<String, dynamic> && data['courses'] is List) {
        coursesList = data['courses'] as List;
      } else {
        throw ElearningApiException(
          'Format de reponse invalide pour mes cours',
          statusCode: response.statusCode,
        );
      }

      return coursesList
          .map((json) => CourseModel.fromJson(json as Map<String, dynamic>))
          .toList();
    } on DioException catch (e) {
      throw ElearningApiException(
        _buildDioMessage('chargement de mes cours', e),
        statusCode: e.response?.statusCode,
      );
    }
  }

  @override
  Future<Map<String, dynamic>> completeLesson(
    String id, {
    int? score,
    Map<String, String>? answers,
  }) async {
    try {
      final body = <String, dynamic>{};
      if (score != null) body['score'] = score;
      if (answers != null) body['answers'] = answers;

      final response = await _dio.post(
        '${ApiEndpoints.elearningLessons}/$id/complete',
        data: body.isNotEmpty ? body : null,
      );
      final data = response.data;

      if (response.statusCode != 200 || data is! Map<String, dynamic>) {
        throw ElearningApiException(
          'Format de reponse invalide pour la completion de la lecon',
          statusCode: response.statusCode,
        );
      }

      return data;
    } on DioException catch (e) {
      throw ElearningApiException(
        _buildDioMessage('completion de la lecon', e),
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
