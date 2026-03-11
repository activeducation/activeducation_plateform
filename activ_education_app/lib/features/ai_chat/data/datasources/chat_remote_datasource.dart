import 'package:dio/dio.dart';

import '../../../../core/constants/api_endpoints.dart';
import '../models/chat_message_model.dart';

abstract class ChatRemoteDataSource {
  Future<ChatMessageModel> sendMessage({
    required String message,
    required String sessionId,
    Map<String, dynamic>? orientationContext,
    List<Map<String, String>>? history,
  });

  Future<void> clearSession(String sessionId);
}

class ChatApiException implements Exception {
  final String message;
  final int? statusCode;

  const ChatApiException(this.message, {this.statusCode});

  @override
  String toString() => 'ChatApiException($statusCode): $message';
}

class ChatRemoteDataSourceImpl implements ChatRemoteDataSource {
  final Dio _dio;

  const ChatRemoteDataSourceImpl(this._dio);

  @override
  Future<ChatMessageModel> sendMessage({
    required String message,
    required String sessionId,
    Map<String, dynamic>? orientationContext,
    List<Map<String, String>>? history,
  }) async {
    try {
      final body = <String, dynamic>{
        'message': message,
        'session_id': sessionId,
        if (orientationContext != null)
          'orientation_context': orientationContext,
        if (history != null && history.isNotEmpty)
          'history': history,
      };

      final response = await _dio.post(
        ApiEndpoints.chatMessage,
        data: body,
      );

      if (response.statusCode != 200 || response.data is! Map<String, dynamic>) {
        throw ChatApiException(
          'Réponse invalide du serveur',
          statusCode: response.statusCode,
        );
      }

      return ChatMessageModel.fromApiResponse(
        response.data as Map<String, dynamic>,
      );
    } on DioException catch (e) {
      final status = e.response?.statusCode;
      final data = e.response?.data;
      String detail = e.message ?? 'Erreur réseau';
      if (data is Map<String, dynamic>) {
        detail = (data['detail'] ?? data['message'] ?? detail).toString();
      }
      throw ChatApiException(detail, statusCode: status);
    }
  }

  @override
  Future<void> clearSession(String sessionId) async {
    try {
      await _dio.delete(ApiEndpoints.chatSession(sessionId));
    } on DioException catch (e) {
      throw ChatApiException(
        e.message ?? 'Erreur réseau',
        statusCode: e.response?.statusCode,
      );
    }
  }
}
