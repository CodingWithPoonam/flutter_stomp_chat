import 'package:equatable/equatable.dart';

class TypingEntity extends Equatable {
  final String conversationId;
  final String userId;
  final String username;
  final String displayName;
  final bool isTyping;

  const TypingEntity({
    required this.conversationId,
    required this.userId,
    required this.username,
    required this.displayName,
    required this.isTyping,
  });

  @override
  List<Object?> get props => [conversationId, userId, username, displayName, isTyping];
}
