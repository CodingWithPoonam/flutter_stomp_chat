import 'dart:async';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../domain/entities/message_entity.dart';
import '../../domain/usecases/chat_usecases.dart';
import 'chat_event.dart';
import 'chat_state.dart';

class ChatBloc extends Bloc<ChatEvent, ChatState> {
  final GetChatHistoryUseCase getChatHistoryUseCase;
  final SendMessageUseCase sendMessageUseCase;
  final SendTypingIndicatorUseCase sendTypingIndicatorUseCase;
  final SubscribeToMessagesUseCase subscribeToMessagesUseCase;
  final SubscribeToTypingUseCase subscribeToTypingUseCase;
  final EditMessageUseCase editMessageUseCase;
  final DeleteMessageUseCase deleteMessageUseCase;
  final String currentUserId;

  void Function()? _unsubscribeMessages;
  void Function()? _unsubscribeTyping;
  final Map<String, Timer> _typingTimers = {};

  ChatBloc({
    required this.getChatHistoryUseCase,
    required this.sendMessageUseCase,
    required this.sendTypingIndicatorUseCase,
    required this.subscribeToMessagesUseCase,
    required this.subscribeToTypingUseCase,
    required this.editMessageUseCase,
    required this.deleteMessageUseCase,
    required this.currentUserId,
  }) : super(ChatInitial()) {
    on<LoadChatHistoryRequested>(_onLoadChatHistoryRequested);
    on<NewMessageReceivedFromStomp>(_onNewMessageReceivedFromStomp);
    on<TypingEventReceivedFromStomp>(_onTypingEventReceivedFromStomp);
    on<ClearTypingForUser>(_onClearTypingForUser);
    on<SendMessageRequested>(_onSendMessageRequested);
    on<SendTypingStatusRequested>(_onSendTypingStatusRequested);
    on<LeaveChatScreenRequested>(_onLeaveChatScreenRequested);
    on<EditMessageRequested>(_onEditMessageRequested);
    on<DeleteMessageRequested>(_onDeleteMessageRequested);
  }

  Future<void> _onLoadChatHistoryRequested(
    LoadChatHistoryRequested event,
    Emitter<ChatState> emit,
  ) async {
    emit(ChatLoading());

    // 1. Subscribe to STOMP Real-time topics
    _unsubscribeMessages?.call();
    _unsubscribeTyping?.call();

    _unsubscribeMessages = subscribeToMessagesUseCase(
      conversationId: event.conversationId,
      onMessageReceived: (message) {
        add(NewMessageReceivedFromStomp(message));
      },
    );

    _unsubscribeTyping = subscribeToTypingUseCase(
      conversationId: event.conversationId,
      onTypingReceived: (typing) {
        add(TypingEventReceivedFromStomp(typing));
      },
    );

    // 2. Fetch persistent chat history from REST API
    try {
      final history = await getChatHistoryUseCase(
        conversationId: event.conversationId,
        page: 0,
        size: 50,
      );
      emit(ChatLoaded(
        conversationId: event.conversationId,
        messages: history,
      ));
    } catch (e) {
      emit(ChatError(e.toString()));
    }
  }

  void _onNewMessageReceivedFromStomp(
    NewMessageReceivedFromStomp event,
    Emitter<ChatState> emit,
  ) {
    if (state is! ChatLoaded) return;
    final currentState = state as ChatLoaded;

    final updated = List<MessageEntity>.from(currentState.messages);
    final existingIndex = updated.indexWhere((m) => m.id == event.message.id);

    if (existingIndex != -1) {
      // Message already exists in list (update in-place for edit or delete-for-everyone live updates)
      updated[existingIndex] = event.message;
    } else {
      // Insert at index 0 (newest at bottom in reversed list)
      updated.insert(0, event.message);
    }

    // If the sender was in typingUsers, remove them now that message is sent
    final updatedTyping = Set<String>.from(currentState.typingUsers);
    updatedTyping.remove(event.message.senderDisplayName);

    emit(currentState.copyWith(
      messages: updated,
      typingUsers: updatedTyping,
    ));
  }

  void _onTypingEventReceivedFromStomp(
    TypingEventReceivedFromStomp event,
    Emitter<ChatState> emit,
  ) {
    if (state is! ChatLoaded) return;
    final currentState = state as ChatLoaded;

    // Ignore self-typing events
    if (event.typing.userId == currentUserId) return;

    final updatedTyping = Set<String>.from(currentState.typingUsers);
    final userLabel = event.typing.displayName.isNotEmpty
        ? event.typing.displayName
        : event.typing.username;

    if (event.typing.isTyping) {
      updatedTyping.add(userLabel);

      // Auto-clear after 3 seconds of no updates
      _typingTimers[userLabel]?.cancel();
      _typingTimers[userLabel] = Timer(const Duration(seconds: 3), () {
        if (!isClosed) {
          add(ClearTypingForUser(userLabel));
        }
      });
    } else {
      updatedTyping.remove(userLabel);
      _typingTimers[userLabel]?.cancel();
      _typingTimers.remove(userLabel);
    }

    emit(currentState.copyWith(typingUsers: updatedTyping));
  }

  void _onClearTypingForUser(
    ClearTypingForUser event,
    Emitter<ChatState> emit,
  ) {
    if (state is! ChatLoaded) return;
    final currentState = state as ChatLoaded;
    final updatedTyping = Set<String>.from(currentState.typingUsers);
    updatedTyping.remove(event.username);
    emit(currentState.copyWith(typingUsers: updatedTyping));
  }

  void _onSendMessageRequested(
    SendMessageRequested event,
    Emitter<ChatState> emit,
  ) {
    if (state is! ChatLoaded) return;
    final currentState = state as ChatLoaded;

    sendMessageUseCase(
      conversationId: currentState.conversationId,
      content: event.content,
    );
  }

  void _onSendTypingStatusRequested(
    SendTypingStatusRequested event,
    Emitter<ChatState> emit,
  ) {
    if (state is! ChatLoaded) return;
    final currentState = state as ChatLoaded;

    sendTypingIndicatorUseCase(
      conversationId: currentState.conversationId,
      isTyping: event.isTyping,
    );
  }

  void _onLeaveChatScreenRequested(
    LeaveChatScreenRequested event,
    Emitter<ChatState> emit,
  ) {
    _cleanUpSubscriptions();
  }

  Future<void> _onEditMessageRequested(
    EditMessageRequested event,
    Emitter<ChatState> emit,
  ) async {
    if (state is! ChatLoaded) return;
    final currentState = state as ChatLoaded;

    try {
      final edited = await editMessageUseCase(
        conversationId: currentState.conversationId,
        messageId: event.messageId,
        content: event.content,
      );

      final updated = List<MessageEntity>.from(currentState.messages);
      final index = updated.indexWhere((m) => m.id == event.messageId);
      if (index != -1) {
        updated[index] = edited;
        emit(currentState.copyWith(messages: updated));
      }
    } catch (e) {
      emit(ChatError(e.toString()));
    }
  }

  Future<void> _onDeleteMessageRequested(
    DeleteMessageRequested event,
    Emitter<ChatState> emit,
  ) async {
    if (state is! ChatLoaded) return;
    final currentState = state as ChatLoaded;

    try {
      final deletedMsg = await deleteMessageUseCase(
        conversationId: currentState.conversationId,
        messageId: event.messageId,
        forEveryone: event.forEveryone,
      );

      final updated = List<MessageEntity>.from(currentState.messages);
      final index = updated.indexWhere((m) => m.id == event.messageId);

      if (index != -1) {
        if (event.forEveryone) {
          updated[index] = deletedMsg;
        } else {
          // Delete for me: remove message completely from local list
          updated.removeAt(index);
        }
        emit(currentState.copyWith(messages: updated));
      }
    } catch (e) {
      emit(ChatError(e.toString()));
    }
  }

  void _cleanUpSubscriptions() {
    _unsubscribeMessages?.call();
    _unsubscribeMessages = null;
    _unsubscribeTyping?.call();
    _unsubscribeTyping = null;
    for (final timer in _typingTimers.values) {
      timer.cancel();
    }
    _typingTimers.clear();
  }

  @override
  Future<void> close() {
    _cleanUpSubscriptions();
    return super.close();
  }
}
