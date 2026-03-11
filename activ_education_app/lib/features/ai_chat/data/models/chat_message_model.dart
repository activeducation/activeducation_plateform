import 'package:uuid/uuid.dart';
import '../../domain/entities/chat_message.dart';

class ChatMessageModel extends ChatMessage {
  const ChatMessageModel({
    required super.id,
    required super.content,
    required super.role,
    required super.timestamp,
  });

  factory ChatMessageModel.fromApiResponse(Map<String, dynamic> json) {
    return ChatMessageModel(
      id: const Uuid().v4(),
      content: json['reply'] as String? ?? '',
      role: MessageRole.assistant,
      timestamp: json['timestamp'] != null
          ? DateTime.tryParse(json['timestamp'] as String) ?? DateTime.now()
          : DateTime.now(),
    );
  }

  factory ChatMessageModel.fromUser(String content) {
    return ChatMessageModel(
      id: const Uuid().v4(),
      content: content,
      role: MessageRole.user,
      timestamp: DateTime.now(),
    );
  }

  /// Désérialise depuis JSON (persistance locale).
  factory ChatMessageModel.fromJson(Map<String, dynamic> json) {
    return ChatMessageModel(
      id: json['id'] as String,
      content: json['content'] as String,
      role: json['role'] == 'user' ? MessageRole.user : MessageRole.assistant,
      timestamp: DateTime.parse(json['timestamp'] as String),
    );
  }

  /// Sérialise vers JSON (persistance locale).
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'content': content,
      'role': role == MessageRole.user ? 'user' : 'assistant',
      'timestamp': timestamp.toIso8601String(),
    };
  }
}
