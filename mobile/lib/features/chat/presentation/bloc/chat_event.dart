import 'package:equatable/equatable.dart';
import '../../domain/entities/message_entity.dart';
import '../../domain/entities/typing_entity.dart';

abstract class ChatEvent extends Equatable {
  const ChatEvent();
  @override
  List<Object?> get props => [];
}

class LoadChatHistoryRequested extends ChatEvent {
  final String conversationId;
  const LoadChatHistoryRequested(this.conversationId);

  @override
  List<Object?> get props => [conversationId];
}

class NewMessageReceivedFromStomp extends ChatEvent {
  final MessageEntity message;
  const NewMessageReceivedFromStomp(this.message);

  @override
  List<Object?> get props => [message];
}

class TypingEventReceivedFromStomp extends ChatEvent {
  final TypingEntity typing;
  const TypingEventReceivedFromStomp(this.typing);

  @override
  List<Object?> get props => [typing];
}

class ClearTypingForUser extends ChatEvent {
  final String username;
  const ClearTypingForUser(this.username);

  @override
  List<Object?> get props => [username];
}

class SendMessageRequested extends ChatEvent {
  final String content;
  const SendMessageRequested(this.content);

  @override
  List<Object?> get props => [content];
}

class SendTypingStatusRequested extends ChatEvent {
  final bool isTyping;
  const SendTypingStatusRequested(this.isTyping);

  @override
  List<Object?> get props => [isTyping];
}

class LeaveChatScreenRequested extends ChatEvent {}

class EditMessageRequested extends ChatEvent {
  final String messageId;
  final String content;

  const EditMessageRequested({
    required this.messageId,
    required this.content,
  });

  @override
  List<Object?> get props => [messageId, content];
}

class DeleteMessageRequested extends ChatEvent {
  final String messageId;
  final bool forEveryone;

  const DeleteMessageRequested({
    required this.messageId,
    required this.forEveryone,
  });

  @override
  List<Object?> get props => [messageId, forEveryone];
}

