import '../entities/message_entity.dart';
import '../entities/typing_entity.dart';
import '../repositories/chat_repository.dart';

class GetChatHistoryUseCase {
  final ChatRepository repository;
  GetChatHistoryUseCase(this.repository);

  Future<List<MessageEntity>> call({
    required String conversationId,
    int page = 0,
    int size = 50,
  }) {
    return repository.getChatHistory(
      conversationId: conversationId,
      page: page,
      size: size,
    );
  }
}

class SendMessageUseCase {
  final ChatRepository repository;
  SendMessageUseCase(this.repository);

  void call({
    required String conversationId,
    required String content,
    String type = 'CHAT',
  }) {
    repository.sendMessage(
      conversationId: conversationId,
      content: content,
      type: type,
    );
  }
}

class SendTypingIndicatorUseCase {
  final ChatRepository repository;
  SendTypingIndicatorUseCase(this.repository);

  void call({
    required String conversationId,
    required bool isTyping,
  }) {
    repository.sendTypingIndicator(
      conversationId: conversationId,
      isTyping: isTyping,
    );
  }
}

class SubscribeToMessagesUseCase {
  final ChatRepository repository;
  SubscribeToMessagesUseCase(this.repository);

  void Function() call({
    required String conversationId,
    required void Function(MessageEntity message) onMessageReceived,
  }) {
    return repository.subscribeToMessages(
      conversationId: conversationId,
      onMessageReceived: onMessageReceived,
    );
  }
}

class SubscribeToTypingUseCase {
  final ChatRepository repository;
  SubscribeToTypingUseCase(this.repository);

  void Function() call({
    required String conversationId,
    required void Function(TypingEntity typing) onTypingReceived,
  }) {
    return repository.subscribeToTyping(
      conversationId: conversationId,
      onTypingReceived: onTypingReceived,
    );
  }
}

class EditMessageUseCase {
  final ChatRepository repository;
  EditMessageUseCase(this.repository);

  Future<MessageEntity> call({
    required String conversationId,
    required String messageId,
    required String content,
  }) {
    return repository.editMessage(
      conversationId: conversationId,
      messageId: messageId,
      content: content,
    );
  }
}

class DeleteMessageUseCase {
  final ChatRepository repository;
  DeleteMessageUseCase(this.repository);

  Future<MessageEntity> call({
    required String conversationId,
    required String messageId,
    required bool forEveryone,
  }) {
    return repository.deleteMessage(
      conversationId: conversationId,
      messageId: messageId,
      forEveryone: forEveryone,
    );
  }
}

