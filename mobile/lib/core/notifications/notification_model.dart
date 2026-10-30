import 'package:equatable/equatable.dart';

class ChatNotification extends Equatable {
  final String conversationId;
  final String conversationTitle;
  final String senderId;
  final String senderDisplayName;
  final String? senderAvatarUrl;
  final String messageContent;
  final DateTime sentAt;
  final bool isGroup;

  const ChatNotification({
    required this.conversationId,
    required this.conversationTitle,
    required this.senderId,
    required this.senderDisplayName,
    this.senderAvatarUrl,
    required this.messageContent,
    required this.sentAt,
    this.isGroup = false,
  });

  @override
  List<Object?> get props => [
        conversationId,
        conversationTitle,
        senderId,
        senderDisplayName,
        senderAvatarUrl,
        messageContent,
        sentAt,
        isGroup,
      ];
}
