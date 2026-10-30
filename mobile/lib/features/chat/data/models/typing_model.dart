import '../../domain/entities/typing_entity.dart';

class TypingModel extends TypingEntity {
  const TypingModel({
    required super.conversationId,
    required super.userId,
    required super.username,
    required super.displayName,
    required super.isTyping,
  });

  factory TypingModel.fromJson(Map<String, dynamic> json) {
    return TypingModel(
      conversationId: json['conversationId'] as String,
      userId: json['userId'] as String,
      username: (json['username'] as String?) ?? '',
      displayName: (json['displayName'] as String?) ?? '',
      isTyping: (json['typing'] as bool?) ?? false,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'conversationId': conversationId,
      'userId': userId,
      'username': username,
      'displayName': displayName,
      'typing': isTyping,
    };
  }
}
