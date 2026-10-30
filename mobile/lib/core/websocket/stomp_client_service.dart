import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:stomp_dart_client/stomp_dart_client.dart';
import '../constants/api_constants.dart';

enum StompConnectionStatus {
  disconnected,
  connecting,
  connected,
  error,
}

class StompClientService {
  StompClient? _stompClient;
  final _connectionStatusController = StreamController<StompConnectionStatus>.broadcast();
  StompConnectionStatus _currentStatus = StompConnectionStatus.disconnected;

  final Map<String, StompUnsubscribe> _activeSubscriptions = {};

  Stream<StompConnectionStatus> get connectionStatusStream => _connectionStatusController.stream;
  StompConnectionStatus get currentStatus => _currentStatus;
  bool get isConnected => _currentStatus == StompConnectionStatus.connected;

  void _setStatus(StompConnectionStatus status) {
    _currentStatus = status;
    if (!_connectionStatusController.isClosed) {
      _connectionStatusController.add(status);
    }
  }

  /// Initialize and connect STOMP over WebSocket with JWT authentication headers
  void connect(String token) {
    if (_stompClient != null && isConnected) {
      return;
    }

    _setStatus(StompConnectionStatus.connecting);

    final headers = {
      'Authorization': 'Bearer $token',
    };

    _stompClient = StompClient(
      config: StompConfig(
        url: ApiConstants.wsUrl,
        onConnect: _onConnect,
        onDisconnect: _onDisconnect,
        onStompError: _onStompError,
        onWebSocketError: _onWebSocketError,
        stompConnectHeaders: headers,
        webSocketConnectHeaders: headers,
        reconnectDelay: const Duration(seconds: 4),
        heartbeatOutgoing: const Duration(seconds: 10),
        heartbeatIncoming: const Duration(seconds: 10),
      ),
    );

    _stompClient?.activate();
  }

  void _onConnect(StompFrame frame) {
    debugPrint('[STOMP] Connected to WebSocket broker. Session: ${frame.headers['session']}');
    _setStatus(StompConnectionStatus.connected);
  }

  void _onDisconnect(StompFrame frame) {
    debugPrint('[STOMP] Disconnected from WebSocket broker');
    _setStatus(StompConnectionStatus.disconnected);
    _activeSubscriptions.clear();
  }

  void _onStompError(StompFrame frame) {
    debugPrint('[STOMP] Protocol Error: ${frame.body}');
    _setStatus(StompConnectionStatus.error);
  }

  void _onWebSocketError(dynamic error) {
    debugPrint('[STOMP] Underlying WebSocket Error: $error');
    _setStatus(StompConnectionStatus.error);
  }

  /// Subscribe to new chat messages for a specific conversation: /topic/conversation.{id}
  void Function() subscribeToConversation(
    String conversationId, {
    required void Function(Map<String, dynamic> messageJson) onMessageReceived,
  }) {
    final destination = ApiConstants.conversationTopic(conversationId);

    if (_stompClient == null || !isConnected) {
      debugPrint('[STOMP] Cannot subscribe: not connected yet.');
    }

    final unsubscribe = _stompClient?.subscribe(
      destination: destination,
      callback: (StompFrame frame) {
        if (frame.body != null) {
          try {
            final json = jsonDecode(frame.body!) as Map<String, dynamic>;
            onMessageReceived(json);
          } catch (e) {
            debugPrint('[STOMP] Error parsing message payload: $e');
          }
        }
      },
    );

    if (unsubscribe != null) {
      _activeSubscriptions[destination] = unsubscribe;
    }

    return () {
      _activeSubscriptions[destination]?.call();
      _activeSubscriptions.remove(destination);
    };
  }

  /// Subscribe to ephemeral typing indicator events: /topic/conversation.{id}.typing
  void Function() subscribeToTyping(
    String conversationId, {
    required void Function(Map<String, dynamic> typingJson) onTypingReceived,
  }) {
    final destination = ApiConstants.typingTopic(conversationId);

    final unsubscribe = _stompClient?.subscribe(
      destination: destination,
      callback: (StompFrame frame) {
        if (frame.body != null) {
          try {
            final json = jsonDecode(frame.body!) as Map<String, dynamic>;
            onTypingReceived(json);
          } catch (e) {
            debugPrint('[STOMP] Error parsing typing payload: $e');
          }
        }
      },
    );

    if (unsubscribe != null) {
      _activeSubscriptions[destination] = unsubscribe;
    }

    return () {
      _activeSubscriptions[destination]?.call();
      _activeSubscriptions.remove(destination);
    };
  }

  /// Subscribe to user-specific private topic: /topic/user.{userId}.conversations
  void Function() subscribeToUserConversations(
    String userId, {
    required void Function(Map<String, dynamic> conversationJson) onConversationReceived,
  }) {
    final destination = ApiConstants.userConversationsTopic(userId);

    final unsubscribe = _stompClient?.subscribe(
      destination: destination,
      callback: (StompFrame frame) {
        if (frame.body != null) {
          try {
            final json = jsonDecode(frame.body!) as Map<String, dynamic>;
            onConversationReceived(json);
          } catch (e) {
            debugPrint('[STOMP] Error parsing user conversation payload: $e');
          }
        }
      },
    );

    if (unsubscribe != null) {
      _activeSubscriptions[destination] = unsubscribe;
    }

    return () {
      _activeSubscriptions[destination]?.call();
      _activeSubscriptions.remove(destination);
    };
  }

  /// Send real-time chat message via STOMP to /app/chat.send
  void sendMessage({
    required String conversationId,
    required String content,
    String type = 'CHAT',
  }) {
    if (_stompClient == null || !isConnected) {
      throw StateError('Cannot send message: STOMP client is not connected.');
    }

    final payload = jsonEncode({
      'conversationId': conversationId,
      'content': content,
      'type': type,
    });

    _stompClient?.send(
      destination: ApiConstants.stompSendAppDestination,
      body: payload,
    );
  }

  /// Send ephemeral typing indicator via STOMP to /app/chat.typing
  void sendTypingIndicator({
    required String conversationId,
    required bool isTyping,
  }) {
    if (_stompClient == null || !isConnected) return;

    final payload = jsonEncode({
      'conversationId': conversationId,
      'typing': isTyping,
    });

    _stompClient?.send(
      destination: ApiConstants.stompTypingAppDestination,
      body: payload,
    );
  }

  /// Graceful disconnect
  void disconnect() {
    _activeSubscriptions.forEach((_, unsub) => unsub());
    _activeSubscriptions.clear();
    _stompClient?.deactivate();
    _stompClient = null;
    _setStatus(StompConnectionStatus.disconnected);
  }

  void dispose() {
    disconnect();
    _connectionStatusController.close();
  }
}
