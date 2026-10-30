import 'package:dio/dio.dart';
import '../../../../core/constants/api_constants.dart';
import '../../../../core/network/api_client.dart';
import '../../../../core/websocket/stomp_client_service.dart';
import '../models/message_model.dart';
import '../models/typing_model.dart';

abstract class ChatRemoteDataSource {
  Future<List<MessageModel>> getChatHistory({
    required String conversationId,
    int page = 0,
    int size = 50,
  });

  void sendMessageOverStomp({
    required String conversationId,
    required String content,
    String type = 'CHAT',
  });

  void sendTypingIndicatorOverStomp({
    required String conversationId,
    required bool isTyping,
  });

  void Function() subscribeToConversationTopic({
    required String conversationId,
    required void Function(MessageModel message) onMessage,
  });

  void Function() subscribeToTypingTopic({
    required String conversationId,
    required void Function(TypingModel typing) onTyping,
  });

  Future<MessageModel> editMessage({
    required String conversationId,
    required String messageId,
    required String content,
  });

  Future<MessageModel> deleteMessage({
    required String conversationId,
    required String messageId,
    required bool forEveryone,
  });
}

class ChatRemoteDataSourceImpl implements ChatRemoteDataSource {
  final ApiClient apiClient;
  final StompClientService stompService;

  ChatRemoteDataSourceImpl({
    required this.apiClient,
    required this.stompService,
  });

  @override
  Future<List<MessageModel>> getChatHistory({
    required String conversationId,
    int page = 0,
    int size = 50,
  }) async {
    try {
      final response = await apiClient.dio.get(
        ApiConstants.messagesEndpoint(conversationId),
        queryParameters: {'page': page, 'size': size},
      );

      final data = response.data;
      List<dynamic> contentList = [];
      if (data is Map<String, dynamic> && data['content'] is List) {
        contentList = data['content'] as List<dynamic>;
      } else if (data is List) {
        contentList = data;
      }

      return contentList
          .map((item) => MessageModel.fromJson(item as Map<String, dynamic>))
          .toList();
    } on DioException catch (e) {
      throw apiClient.handleError(e);
    }
  }

  @override
  void sendMessageOverStomp({
    required String conversationId,
    required String content,
    String type = 'CHAT',
  }) {
    stompService.sendMessage(
      conversationId: conversationId,
      content: content,
      type: type,
    );
  }

  @override
  void sendTypingIndicatorOverStomp({
    required String conversationId,
    required bool isTyping,
  }) {
    stompService.sendTypingIndicator(
      conversationId: conversationId,
      isTyping: isTyping,
    );
  }

  @override
  void Function() subscribeToConversationTopic({
    required String conversationId,
    required void Function(MessageModel message) onMessage,
  }) {
    return stompService.subscribeToConversation(
      conversationId,
      onMessageReceived: (json) {
        final model = MessageModel.fromJson(json);
        onMessage(model);
      },
    );
  }

  @override
  void Function() subscribeToTypingTopic({
    required String conversationId,
    required void Function(TypingModel typing) onTyping,
  }) {
    return stompService.subscribeToTyping(
      conversationId,
      onTypingReceived: (json) {
        final model = TypingModel.fromJson(json);
        onTyping(model);
      },
    );
  }

  @override
  Future<MessageModel> editMessage({
    required String conversationId,
    required String messageId,
    required String content,
  }) async {
    try {
      final response = await apiClient.dio.put(
        ApiConstants.editMessageEndpoint(conversationId, messageId),
        data: {'content': content},
      );
      return MessageModel.fromJson(response.data as Map<String, dynamic>);
    } on DioException catch (e) {
      throw apiClient.handleError(e);
    }
  }

  @override
  Future<MessageModel> deleteMessage({
    required String conversationId,
    required String messageId,
    required bool forEveryone,
  }) async {
    try {
      final response = await apiClient.dio.delete(
        ApiConstants.deleteMessageEndpoint(conversationId, messageId, forEveryone),
      );
      return MessageModel.fromJson(response.data as Map<String, dynamic>);
    } on DioException catch (e) {
      throw apiClient.handleError(e);
    }
  }
}
