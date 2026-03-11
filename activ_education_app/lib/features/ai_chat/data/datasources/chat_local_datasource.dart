import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/chat_message_model.dart';

/// Persistance locale de l'historique AÏDA via SharedPreferences.
///
/// Clés par utilisateur :
///   - `aida_messages_{userId}` : liste JSON des messages
///   - `aida_session_{userId}` : UUID de la session en cours
class ChatLocalDataSource {
  final SharedPreferences _prefs;

  static const int maxStoredMessages = 50;
  static const String _messagesPrefix = 'aida_messages_';
  static const String _sessionPrefix = 'aida_session_';

  const ChatLocalDataSource(this._prefs);

  // ---- Messages ----

  /// Charge les messages sauvegardés pour un utilisateur.
  List<ChatMessageModel> loadMessages(String userId) {
    final raw = _prefs.getString('$_messagesPrefix$userId');
    if (raw == null || raw.isEmpty) return [];

    try {
      final List<dynamic> decoded = jsonDecode(raw) as List<dynamic>;
      return decoded
          .map((e) => ChatMessageModel.fromJson(e as Map<String, dynamic>))
          .toList();
    } catch (_) {
      _prefs.remove('$_messagesPrefix$userId');
      return [];
    }
  }

  /// Sauvegarde les messages (garde les derniers [maxStoredMessages]).
  Future<void> saveMessages(
    String userId,
    List<ChatMessageModel> messages,
  ) async {
    final trimmed = messages.length > maxStoredMessages
        ? messages.sublist(messages.length - maxStoredMessages)
        : messages;
    final encoded = jsonEncode(trimmed.map((m) => m.toJson()).toList());
    await _prefs.setString('$_messagesPrefix$userId', encoded);
  }

  // ---- Session ID ----

  /// Charge le session_id sauvegardé, ou null si aucun.
  String? loadSessionId(String userId) {
    return _prefs.getString('$_sessionPrefix$userId');
  }

  /// Sauvegarde le session_id.
  Future<void> saveSessionId(String userId, String sessionId) async {
    await _prefs.setString('$_sessionPrefix$userId', sessionId);
  }

  // ---- Clear ----

  /// Efface tout l'historique pour un utilisateur.
  Future<void> clearHistory(String userId) async {
    await Future.wait([
      _prefs.remove('$_messagesPrefix$userId'),
      _prefs.remove('$_sessionPrefix$userId'),
    ]);
  }
}
