import '../../domain/entities/message_entity.dart';

class MessageModel extends MessageEntity {
  const MessageModel({
    required super.id,
    required super.conversationId,
    required super.senderId,
    required super.senderUsername,
    required super.senderDisplayName,
    super.senderAvatarUrl,
    required super.content,
    required super.type,
    required super.sentAt,
    super.isEdited = false,
    super.editedAt,
    super.isDeletedForEveryone = false,
  });

  factory MessageModel.fromJson(Map<String, dynamic> json) {
    return MessageModel(
      id: json['id'] as String,
      conversationId: json['conversationId'] as String,
      senderId: json['senderId'] as String,
      senderUsername: json['senderUsername'] as String,
      senderDisplayName: json['senderDisplayName'] as String,
      senderAvatarUrl: json['senderAvatarUrl'] as String?,
      content: json['content'] as String,
      type: (json['type'] as String?) ?? 'CHAT',
      sentAt: json['sentAt'] != null
          ? DateTime.parse(json['sentAt'] as String)
          : DateTime.now(),
      isEdited: (json['edited'] as bool?) ?? false,
      editedAt: json['editedAt'] != null
          ? DateTime.parse(json['editedAt'] as String)
          : null,
      isDeletedForEveryone: (json['deletedForEveryone'] as bool?) ?? false,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'conversationId': conversationId,
      'senderId': senderId,
      'senderUsername': senderUsername,
      'senderDisplayName': senderDisplayName,
      'senderAvatarUrl': senderAvatarUrl,
      'content': content,
      'type': type,
      'sentAt': sentAt.toIso8601String(),
      'edited': isEdited,
      'editedAt': editedAt?.toIso8601String(),
      'deletedForEveryone': isDeletedForEveryone,
    };
  }
}
