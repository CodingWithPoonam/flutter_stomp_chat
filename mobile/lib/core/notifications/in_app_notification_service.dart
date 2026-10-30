import 'dart:async';
import 'notification_model.dart';

class InAppNotificationService {
  final _controller = StreamController<ChatNotification>.broadcast();
  String? _activeConversationId;
  String? _currentUserId;

  Stream<ChatNotification> get notificationStream => _controller.stream;
  String? get activeConversationId => _activeConversationId;

  void setCurrentUserId(String? userId) {
    _currentUserId = userId;
  }

  void setActiveConversation(String? conversationId) {
    _activeConversationId = conversationId;
  }

  void handleIncomingMessage({
    required String conversationId,
    required String conversationTitle,
    required String senderId,
    required String senderDisplayName,
    String? senderAvatarUrl,
    required String messageContent,
    required DateTime sentAt,
    bool isGroup = false,
  }) {
    // 1. Never notify for messages sent by current user
    if (_currentUserId != null && senderId == _currentUserId) {
      return;
    }

    // 2. Do not notify if user is actively inside this conversation
    if (_activeConversationId == conversationId) {
      return;
    }

    final notification = ChatNotification(
      conversationId: conversationId,
      conversationTitle: conversationTitle,
      senderId: senderId,
      senderDisplayName: senderDisplayName,
      senderAvatarUrl: senderAvatarUrl,
      messageContent: messageContent,
      sentAt: sentAt,
      isGroup: isGroup,
    );

    if (!_controller.isClosed) {
      _controller.add(notification);
    }
  }

  void dispose() {
    _controller.close();
  }
}
