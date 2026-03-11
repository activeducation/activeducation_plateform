import '../../domain/entities/chat_message.dart';
import '../../domain/repositories/chat_repository.dart';
import '../datasources/chat_remote_datasource.dart';

class ChatRepositoryImpl implements ChatRepository {
  final ChatRemoteDataSource _datasource;

  const ChatRepositoryImpl(this._datasource);

  @override
  Future<ChatMessage> sendMessage({
    required String message,
    required String sessionId,
    Map<String, dynamic>? orientationContext,
    List<Map<String, String>>? history,
  }) async {
    return _datasource.sendMessage(
      message: message,
      sessionId: sessionId,
      orientationContext: orientationContext,
      history: history,
    );
  }

  @override
  Future<void> clearSession(String sessionId) async {
    return _datasource.clearSession(sessionId);
  }
}
