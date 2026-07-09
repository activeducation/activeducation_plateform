import '../entities/chat_message.dart';

abstract class ChatRepository {
  /// Envoie un message et retourne la réponse d'AÏDA (mode JSON, fallback).
  Future<ChatMessage> sendMessage({
    required String message,
    required String sessionId,
    Map<String, dynamic>? orientationContext,
    List<Map<String, String>>? history,
  });

  /// Envoie un message et streame la réponse d'AÏDA fragment par fragment.
  Stream<String> streamMessage({
    required String message,
    required String sessionId,
    Map<String, dynamic>? orientationContext,
    List<Map<String, String>>? history,
  });

  /// Efface l'historique côté serveur pour une session.
  Future<void> clearSession(String sessionId);
}
