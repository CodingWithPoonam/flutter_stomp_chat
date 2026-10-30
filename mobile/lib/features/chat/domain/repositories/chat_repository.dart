import '../entities/message_entity.dart';
import '../entities/typing_entity.dart';

abstract class ChatRepository {
  Future<List<MessageEntity>> getChatHistory({
    required String conversationId,
    int page = 0,
    int size = 50,
  });

  void sendMessage({
    required String conversationId,
    required String content,
    String type = 'CHAT',
  });

  void sendTypingIndicator({
    required String conversationId,
    required bool isTyping,
  });

  void Function() subscribeToMessages({
    required String conversationId,
    required void Function(MessageEntity message) onMessageReceived,
  });

  void Function() subscribeToTyping({
    required String conversationId,
    required void Function(TypingEntity typing) onTypingReceived,
  });

  Future<MessageEntity> editMessage({
    required String conversationId,
    required String messageId,
    required String content,
  });

  Future<MessageEntity> deleteMessage({
    required String conversationId,
    required String messageId,
    required bool forEveryone,
  });
}
