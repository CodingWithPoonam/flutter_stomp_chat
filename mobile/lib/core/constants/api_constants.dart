import 'dart:io' show Platform;
import 'package:flutter/foundation.dart' show kIsWeb;

class ApiConstants {
  // Automatically select the correct loopback host for Android emulator vs Web/Desktop/iOS
  static String get defaultHost {
    if (kIsWeb) return 'localhost';
    if (Platform.isAndroid) return '10.0.2.2'; // Standard Android emulator loopback to host PC
    return 'localhost';
  }

  static const int port = 8080;

  static String get baseUrl => 'http://$defaultHost:$port/api/v1';
  static String get wsUrl => 'ws://$defaultHost:$port/ws';

  // REST Auth Endpoints
  static const String registerEndpoint = '/auth/register';
  static const String loginEndpoint = '/auth/login';
  static const String meEndpoint = '/auth/me';

  // REST Conversations & Messages
  static const String conversationsEndpoint = '/conversations';
  static const String directConversationEndpoint = '/conversations/direct';
  static const String groupConversationEndpoint = '/conversations/group';
  static const String usersEndpoint = '/users';

  static String conversationEndpoint(String conversationId) => '/conversations/$conversationId';
  static String messagesEndpoint(String conversationId) => '/conversations/$conversationId/messages';
  static String editMessageEndpoint(String conversationId, String messageId) => '/conversations/$conversationId/messages/$messageId';
  static String deleteMessageEndpoint(String conversationId, String messageId, bool forEveryone) =>
      '/conversations/$conversationId/messages/$messageId?forEveryone=$forEveryone';
  static String conversationMembersEndpoint(String conversationId) => '/conversations/$conversationId/members';
  static String memberRoleEndpoint(String conversationId, String userId) => '/conversations/$conversationId/members/$userId/role';
  static String removeMemberEndpoint(String conversationId, String userId) => '/conversations/$conversationId/members/$userId';

  // STOMP WebSocket Application Destination Endpoints
  static const String stompSendAppDestination = '/app/chat.send';
  static const String stompTypingAppDestination = '/app/chat.typing';

  // STOMP Topic Subscriptions
  static String conversationTopic(String conversationId) => '/topic/conversation.$conversationId';
  static String typingTopic(String conversationId) => '/topic/conversation.$conversationId.typing';
  static String userConversationsTopic(String userId) => '/topic/user.$userId.conversations';

  // Secure Storage Keys
  static const String tokenKey = 'jwt_access_token';
  static const String userKey = 'cached_user_profile';
}
