import 'package:equatable/equatable.dart';
import '../../domain/entities/conversation_entity.dart';

abstract class ConversationState extends Equatable {
  const ConversationState();
  @override
  List<Object?> get props => [];
}

class ConversationInitial extends ConversationState {}

class ConversationLoading extends ConversationState {}

class ConversationLoaded extends ConversationState {
  final List<ConversationEntity> conversations;
  final ConversationEntity? newlyCreatedConversation;

  const ConversationLoaded({
    required this.conversations,
    this.newlyCreatedConversation,
  });

  ConversationLoaded copyWith({
    List<ConversationEntity>? conversations,
    ConversationEntity? newlyCreatedConversation,
  }) {
    return ConversationLoaded(
      conversations: conversations ?? this.conversations,
      newlyCreatedConversation: newlyCreatedConversation,
    );
  }

  @override
  List<Object?> get props => [conversations, newlyCreatedConversation];
}

class ConversationError extends ConversationState {
  final String errorMessage;
  const ConversationError(this.errorMessage);

  @override
  List<Object?> get props => [errorMessage];
}
