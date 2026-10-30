import '../../domain/entities/message_entity.dart';
import '../../domain/entities/typing_entity.dart';
import '../../domain/repositories/chat_repository.dart';
import '../datasources/chat_remote_datasource.dart';

class ChatRepositoryImpl implements ChatRepository {
  final ChatRemoteDataSource remoteDataSource;

  ChatRepositoryImpl({required this.remoteDataSource});

  @override
  Future<List<MessageEntity>> getChatHistory({
    required String conversationId,
    int page = 0,
    int size = 50,
  }) {
    return remoteDataSource.getChatHistory(
      conversationId: conversationId,
      page: page,
      size: size,
    );
  }

  @override
  void sendMessage({
    required String conversationId,
    required String content,
    String type = 'CHAT',
  }) {
    remoteDataSource.sendMessageOverStomp(
      conversationId: conversationId,
      content: content,
      type: type,
    );
  }

  @override
  void sendTypingIndicator({
    required String conversationId,
    required bool isTyping,
  }) {
    remoteDataSource.sendTypingIndicatorOverStomp(
      conversationId: conversationId,
      isTyping: isTyping,
    );
  }

  @override
  void Function() subscribeToMessages({
    required String conversationId,
    required void Function(MessageEntity message) onMessageReceived,
  }) {
    return remoteDataSource.subscribeToConversationTopic(
      conversationId: conversationId,
      onMessage: onMessageReceived,
    );
  }

  @override
  void Function() subscribeToTyping({
    required String conversationId,
    required void Function(TypingEntity typing) onTypingReceived,
  }) {
    return remoteDataSource.subscribeToTypingTopic(
      conversationId: conversationId,
      onTyping: onTypingReceived,
    );
  }

  @override
  Future<MessageEntity> editMessage({
    required String conversationId,
    required String messageId,
    required String content,
  }) {
    return remoteDataSource.editMessage(
      conversationId: conversationId,
      messageId: messageId,
      content: content,
    );
  }

  @override
  Future<MessageEntity> deleteMessage({
    required String conversationId,
    required String messageId,
    required bool forEveryone,
  }) {
    return remoteDataSource.deleteMessage(
      conversationId: conversationId,
      messageId: messageId,
      forEveryone: forEveryone,
    );
  }
}
