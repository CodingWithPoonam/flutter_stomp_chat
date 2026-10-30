import 'package:equatable/equatable.dart';

class MessageEntity extends Equatable {
  final String id;
  final String conversationId;
  final String senderId;
  final String senderUsername;
  final String senderDisplayName;
  final String? senderAvatarUrl;
  final String content;
  final String type; // 'CHAT', 'JOIN', 'LEAVE'
  final DateTime sentAt;
  final bool isEdited;
  final DateTime? editedAt;
  final bool isDeletedForEveryone;

  const MessageEntity({
    required this.id,
    required this.conversationId,
    required this.senderId,
    required this.senderUsername,
    required this.senderDisplayName,
    this.senderAvatarUrl,
    required this.content,
    required this.type,
    required this.sentAt,
    this.isEdited = false,
    this.editedAt,
    this.isDeletedForEveryone = false,
  });

  @override
  List<Object?> get props => [
        id,
        conversationId,
        senderId,
        senderUsername,
        senderDisplayName,
        senderAvatarUrl,
        content,
        type,
        sentAt,
        isEdited,
        editedAt,
        isDeletedForEveryone,
      ];
}
