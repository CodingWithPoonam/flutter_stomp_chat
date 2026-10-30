import 'package:flutter_bloc/flutter_bloc.dart';
import '../../domain/entities/conversation_entity.dart';
import '../../domain/usecases/conversation_usecases.dart';
import 'conversation_event.dart';
import 'conversation_state.dart';

class ConversationBloc extends Bloc<ConversationEvent, ConversationState> {
  final GetConversationsUseCase getConversationsUseCase;
  final CreateDirectConversationUseCase createDirectConversationUseCase;
  final CreateGroupConversationUseCase createGroupConversationUseCase;
  final DeleteConversationUseCase deleteConversationUseCase;

  ConversationBloc({
    required this.getConversationsUseCase,
    required this.createDirectConversationUseCase,
    required this.createGroupConversationUseCase,
    required this.deleteConversationUseCase,
  }) : super(ConversationInitial()) {
    on<FetchConversationsRequested>(_onFetchConversationsRequested);
    on<CreateDirectConversationRequested>(_onCreateDirectConversationRequested);
    on<CreateGroupConversationRequested>(_onCreateGroupConversationRequested);
    on<ConversationUpdatedFromWebSocket>(_onConversationUpdatedFromWebSocket);
    on<ConversationCreatedOrUpdatedFromStomp>(_onConversationCreatedOrUpdatedFromStomp);
    on<DeleteConversationRequested>(_onDeleteConversationRequested);
    on<ConversationDeletedFromStomp>(_onConversationDeletedFromStomp);
  }

  Future<void> _onFetchConversationsRequested(
    FetchConversationsRequested event,
    Emitter<ConversationState> emit,
  ) async {
    emit(ConversationLoading());
    try {
      final conversations = await getConversationsUseCase();
      emit(ConversationLoaded(conversations: conversations));
    } catch (e) {
      emit(ConversationError(e.toString()));
    }
  }

  Future<void> _onCreateDirectConversationRequested(
    CreateDirectConversationRequested event,
    Emitter<ConversationState> emit,
  ) async {
    try {
      final created = await createDirectConversationUseCase(event.targetUserId);
      final currentList = state is ConversationLoaded
          ? List<ConversationEntity>.from((state as ConversationLoaded).conversations)
          : <ConversationEntity>[];

      // Remove old instance if already in list, insert newly active at top
      currentList.removeWhere((c) => c.id == created.id);
      currentList.insert(0, created);

      emit(ConversationLoaded(
        conversations: currentList,
        newlyCreatedConversation: created,
      ));
    } catch (e) {
      emit(ConversationError(e.toString()));
    }
  }

  Future<void> _onCreateGroupConversationRequested(
    CreateGroupConversationRequested event,
    Emitter<ConversationState> emit,
  ) async {
    try {
      final created = await createGroupConversationUseCase(
        title: event.title,
        memberUserIds: event.memberUserIds,
      );
      final currentList = state is ConversationLoaded
          ? List<ConversationEntity>.from((state as ConversationLoaded).conversations)
          : <ConversationEntity>[];

      currentList.insert(0, created);

      emit(ConversationLoaded(
        conversations: currentList,
        newlyCreatedConversation: created,
      ));
    } catch (e) {
      emit(ConversationError(e.toString()));
    }
  }

  void _onConversationUpdatedFromWebSocket(
    ConversationUpdatedFromWebSocket event,
    Emitter<ConversationState> emit,
  ) {
    if (state is! ConversationLoaded) return;
    final currentState = state as ConversationLoaded;

    final updatedList = List<ConversationEntity>.from(currentState.conversations);
    final index = updatedList.indexWhere((c) => c.id == event.conversationId);

    if (index != -1) {
      final old = updatedList.removeAt(index);
      final updated = ConversationEntity(
        id: old.id,
        type: old.type,
        title: old.title,
        creatorId: old.creatorId,
        members: old.members,
        lastMessageContent: event.lastMessageContent,
        lastMessageSentAt: event.lastMessageSentAt,
        updatedAt: event.lastMessageSentAt,
      );
      updatedList.insert(0, updated);
      emit(currentState.copyWith(conversations: updatedList));
    }
  }

  void _onConversationCreatedOrUpdatedFromStomp(
    ConversationCreatedOrUpdatedFromStomp event,
    Emitter<ConversationState> emit,
  ) {
    final currentList = state is ConversationLoaded
        ? List<ConversationEntity>.from((state as ConversationLoaded).conversations)
        : <ConversationEntity>[];

    currentList.removeWhere((c) => c.id == event.conversation.id);
    currentList.insert(0, event.conversation);

    if (state is ConversationLoaded) {
      final currentState = state as ConversationLoaded;
      emit(currentState.copyWith(conversations: currentList));
    } else {
      emit(ConversationLoaded(conversations: currentList));
    }
  }

  Future<void> _onDeleteConversationRequested(
    DeleteConversationRequested event,
    Emitter<ConversationState> emit,
  ) async {
    try {
      await deleteConversationUseCase(event.conversationId);
      if (state is ConversationLoaded) {
        final currentList =
            List<ConversationEntity>.from((state as ConversationLoaded).conversations);
        currentList.removeWhere((c) => c.id == event.conversationId);
        emit((state as ConversationLoaded).copyWith(conversations: currentList));
      }
    } catch (e) {
      emit(ConversationError(e.toString()));
    }
  }

  void _onConversationDeletedFromStomp(
    ConversationDeletedFromStomp event,
    Emitter<ConversationState> emit,
  ) {
    if (state is ConversationLoaded) {
      final currentList =
          List<ConversationEntity>.from((state as ConversationLoaded).conversations);
      currentList.removeWhere((c) => c.id == event.conversationId);
      emit((state as ConversationLoaded).copyWith(conversations: currentList));
    }
  }
}

