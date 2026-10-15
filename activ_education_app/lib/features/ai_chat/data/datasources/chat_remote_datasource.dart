import 'dart:async';
import 'dart:convert';

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

  /// Envoie un message et streame la réponse d'AÏDA mot par mot (SSE).
  /// Yield chaque fragment de texte au fur et à mesure. Lève
  /// [ChatApiException] en cas d'erreur réseau ou serveur.
  Stream<String> streamMessage({
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
        'orientation_context': ?orientationContext,
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
  Stream<String> streamMessage({
    required String message,
    required String sessionId,
    Map<String, dynamic>? orientationContext,
    List<Map<String, String>>? history,
  }) async* {
    final body = <String, dynamic>{
      'message': message,
      'session_id': sessionId,
      'orientation_context': ?orientationContext,
      if (history != null && history.isNotEmpty) 'history': history,
    };

    final Response<ResponseBody> response;
    try {
      response = await _dio.post<ResponseBody>(
        ApiEndpoints.chatMessageStream,
        data: body,
        options: Options(
          responseType: ResponseType.stream,
          headers: {'Accept': 'text/event-stream'},
        ),
      );
    } on DioException catch (e) {
      throw ChatApiException(
        e.message ?? 'Erreur réseau',
        statusCode: e.response?.statusCode,
      );
    }

    final stream = response.data?.stream;
    if (stream == null) {
      throw const ChatApiException('Flux SSE indisponible');
    }

    // Décodage UTF-8 incrémental (gère les caractères multi-octets coupés
    // entre deux paquets réseau), puis découpage en lignes SSE.
    var buffer = '';
    await for (final decoded in utf8.decoder.bind(stream)) {
      buffer += decoded;

      int newlineIndex;
      while ((newlineIndex = buffer.indexOf('\n')) != -1) {
        final line = buffer.substring(0, newlineIndex).trimRight();
        buffer = buffer.substring(newlineIndex + 1);

        if (!line.startsWith('data:')) continue;
        final payload = line.substring(5).trim();
        if (payload.isEmpty) continue;

        final Map<String, dynamic> event;
        try {
          event = json.decode(payload) as Map<String, dynamic>;
        } catch (_) {
          continue; // ligne partielle/non-JSON, on ignore
        }

        if (event['error'] != null) {
          throw ChatApiException(event['error'].toString());
        }
        if (event['done'] == true) {
          return;
        }
        final chunk = event['chunk'];
        if (chunk is String && chunk.isNotEmpty) {
          yield chunk;
        }
      }
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
