import '../entities/chat_message.dart';
import '../repositories/chat_repository.dart';

class SendMessageUseCase {
  final ChatRepository _repository;

  const SendMessageUseCase(this._repository);

  Future<ChatMessage> call({
    required String message,
    required String sessionId,
    Map<String, dynamic>? orientationContext,
    List<Map<String, String>>? history,
  }) {
    return _repository.sendMessage(
      message: message,
      sessionId: sessionId,
      orientationContext: orientationContext,
      history: history,
    );
  }
}
