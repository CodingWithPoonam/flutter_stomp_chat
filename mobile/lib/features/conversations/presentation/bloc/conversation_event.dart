import 'package:equatable/equatable.dart';
import '../../domain/entities/conversation_entity.dart';

abstract class ConversationEvent extends Equatable {
  const ConversationEvent();
  @override
  List<Object?> get props => [];
}

class FetchConversationsRequested extends ConversationEvent {}

class CreateDirectConversationRequested extends ConversationEvent {
  final String targetUserId;
  const CreateDirectConversationRequested(this.targetUserId);

  @override
  List<Object?> get props => [targetUserId];
}

class CreateGroupConversationRequested extends ConversationEvent {
  final String title;
  final List<String> memberUserIds;

  const CreateGroupConversationRequested({
    required this.title,
    required this.memberUserIds,
  });

  @override
  List<Object?> get props => [title, memberUserIds];
}

class ConversationUpdatedFromWebSocket extends ConversationEvent {
  final String conversationId;
  final String lastMessageContent;
  final DateTime lastMessageSentAt;

  const ConversationUpdatedFromWebSocket({
    required this.conversationId,
    required this.lastMessageContent,
    required this.lastMessageSentAt,
  });

  @override
  List<Object?> get props => [conversationId, lastMessageContent, lastMessageSentAt];
}

class ConversationCreatedOrUpdatedFromStomp extends ConversationEvent {
  final ConversationEntity conversation;
  const ConversationCreatedOrUpdatedFromStomp(this.conversation);

  @override
  List<Object?> get props => [conversation];
}

class DeleteConversationRequested extends ConversationEvent {
  final String conversationId;
  const DeleteConversationRequested(this.conversationId);

  @override
  List<Object?> get props => [conversationId];
}

class ConversationDeletedFromStomp extends ConversationEvent {
  final String conversationId;
  const ConversationDeletedFromStomp(this.conversationId);

  @override
  List<Object?> get props => [conversationId];
}

