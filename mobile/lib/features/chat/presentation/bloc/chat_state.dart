import 'package:equatable/equatable.dart';
import '../../domain/entities/message_entity.dart';

abstract class ChatState extends Equatable {
  const ChatState();
  @override
  List<Object?> get props => [];
}

class ChatInitial extends ChatState {}

class ChatLoading extends ChatState {}

class ChatLoaded extends ChatState {
  final String conversationId;
  final List<MessageEntity> messages;
  final Set<String> typingUsers; // Display names or usernames of people typing
  final String? error;

  const ChatLoaded({
    required this.conversationId,
    required this.messages,
    this.typingUsers = const {},
    this.error,
  });

  ChatLoaded copyWith({
    String? conversationId,
    List<MessageEntity>? messages,
    Set<String>? typingUsers,
    String? error,
  }) {
    return ChatLoaded(
      conversationId: conversationId ?? this.conversationId,
      messages: messages ?? this.messages,
      typingUsers: typingUsers ?? this.typingUsers,
      error: error,
    );
  }

  @override
  List<Object?> get props => [conversationId, messages, typingUsers, error];
}

class ChatError extends ChatState {
  final String errorMessage;
  const ChatError(this.errorMessage);

  @override
  List<Object?> get props => [errorMessage];
}
