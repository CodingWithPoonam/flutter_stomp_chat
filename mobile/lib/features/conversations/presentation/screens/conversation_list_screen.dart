import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/di/service_locator.dart';
import '../../../../core/notifications/in_app_notification_service.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/websocket/stomp_client_service.dart';
import '../../../auth/domain/entities/user_entity.dart';
import '../../../auth/presentation/bloc/auth_bloc.dart';
import '../../../auth/presentation/bloc/auth_event.dart';
import '../../../chat/presentation/screens/chat_screen.dart';
import '../../data/models/conversation_model.dart';
import '../../domain/entities/conversation_entity.dart';
import '../../domain/usecases/conversation_usecases.dart';
import '../bloc/conversation_bloc.dart';
import '../bloc/conversation_event.dart';
import '../bloc/conversation_state.dart';
import '../widgets/conversation_card.dart';
import '../widgets/create_group_dialog.dart';
import '../widgets/new_chat_dialog.dart';

class ConversationListScreen extends StatefulWidget {
  final UserEntity currentUser;

  const ConversationListScreen({super.key, required this.currentUser});

  @override
  State<ConversationListScreen> createState() => _ConversationListScreenState();
}

class _ConversationListScreenState extends State<ConversationListScreen> {
  final TextEditingController _searchController = TextEditingController();
  final Map<String, void Function()> _conversationSubscriptions = {};
  void Function()? _userConversationsUnsubscribe;
  StreamSubscription<StompConnectionStatus>? _connectionStatusSubscription;
  String _searchFilter = '';

  @override
  void initState() {
    super.initState();
    getIt<InAppNotificationService>().setCurrentUserId(widget.currentUser.id);
    context.read<ConversationBloc>().add(FetchConversationsRequested());

    final stompService = getIt<StompClientService>();
    if (stompService.isConnected) {
      _setupUserConversationsSubscription();
    }
    _connectionStatusSubscription = stompService.connectionStatusStream.listen((status) {
      if (status == StompConnectionStatus.connected) {
        _setupUserConversationsSubscription();
        if (mounted) {
          final state = context.read<ConversationBloc>().state;
          if (state is ConversationLoaded) {
            _syncWebSocketSubscriptions(state.conversations);
          }
        }
      }
    });
  }

  @override
  void dispose() {
    _connectionStatusSubscription?.cancel();
    _userConversationsUnsubscribe?.call();
    _conversationSubscriptions.forEach((_, unsub) => unsub());
    _conversationSubscriptions.clear();
    _searchController.dispose();
    super.dispose();
  }

  void _setupUserConversationsSubscription() {
    _userConversationsUnsubscribe?.call();
    final stompService = getIt<StompClientService>();
    if (!stompService.isConnected) return;

    _userConversationsUnsubscribe = stompService.subscribeToUserConversations(
      widget.currentUser.id,
      onConversationReceived: (json) {
        try {
          if (json['deleted'] == true) {
            final deletedId = json['id'] as String;
            _conversationSubscriptions[deletedId]?.call();
            _conversationSubscriptions.remove(deletedId);
            if (mounted) {
              context.read<ConversationBloc>().add(ConversationDeletedFromStomp(deletedId));
            }
            return;
          }
          final conv = ConversationModel.fromJson(json);
          if (mounted) {
            context.read<ConversationBloc>().add(ConversationCreatedOrUpdatedFromStomp(conv));
          }
          _subscribeToSingleConversation(conv.id, conv.title, conv.isGroup);

          if (json['lastMessage'] != null && json['lastMessage'] is Map<String, dynamic>) {
            final msg = json['lastMessage'] as Map<String, dynamic>;
            final senderId = (msg['senderId'] as String?) ?? '';
            if (senderId != widget.currentUser.id) {
              final content = (msg['content'] as String?) ?? '';
              final senderDisplayName = (msg['senderDisplayName'] as String?) ?? '';
              final senderAvatarUrl = msg['senderAvatarUrl'] as String?;
              final sentAt = msg['sentAt'] != null
                  ? DateTime.parse(msg['sentAt'] as String)
                  : DateTime.now();

              getIt<InAppNotificationService>().handleIncomingMessage(
                conversationId: conv.id,
                conversationTitle: conv.title,
                senderId: senderId,
                senderDisplayName: senderDisplayName,
                senderAvatarUrl: senderAvatarUrl,
                messageContent: content,
                sentAt: sentAt,
                isGroup: conv.isGroup,
              );
            }
          }
        } catch (e) {
          debugPrint('[STOMP] Error handling incoming user conversation: $e');
        }
      },
    );
  }

  void _subscribeToSingleConversation(
    String conversationId,
    String conversationTitle,
    bool isGroup,
  ) {
    if (_conversationSubscriptions.containsKey(conversationId)) return;
    final stompService = getIt<StompClientService>();
    if (!stompService.isConnected) return;

    final unsub = stompService.subscribeToConversation(
      conversationId,
      onMessageReceived: (json) {
        final sentAt = json['sentAt'] != null
            ? DateTime.parse(json['sentAt'] as String)
            : DateTime.now();
        final content = (json['content'] as String?) ?? '';
        final senderId = (json['senderId'] as String?) ?? '';
        final senderDisplayName = (json['senderDisplayName'] as String?) ?? '';
        final senderAvatarUrl = json['senderAvatarUrl'] as String?;

        if (mounted) {
          context.read<ConversationBloc>().add(
                ConversationUpdatedFromWebSocket(
                  conversationId: conversationId,
                  lastMessageContent: content,
                  lastMessageSentAt: sentAt,
                ),
              );
        }

        getIt<InAppNotificationService>().handleIncomingMessage(
          conversationId: conversationId,
          conversationTitle: conversationTitle,
          senderId: senderId,
          senderDisplayName: senderDisplayName,
          senderAvatarUrl: senderAvatarUrl,
          messageContent: content,
          sentAt: sentAt,
          isGroup: isGroup,
        );
      },
    );
    _conversationSubscriptions[conversationId] = unsub;
  }

  void _syncWebSocketSubscriptions(List<ConversationEntity> conversations) {
    for (final c in conversations) {
      _subscribeToSingleConversation(c.id, c.title, c.isGroup);
    }
  }

  void _openChat(ConversationEntity conversation) {
    getIt<InAppNotificationService>().setActiveConversation(conversation.id);
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => ChatScreen(
          conversation: conversation,
          currentUser: widget.currentUser,
        ),
      ),
    ).then((_) {
      getIt<InAppNotificationService>().setActiveConversation(null);
      // Refresh conversations when returning from chat
      if (mounted) {
        context.read<ConversationBloc>().add(FetchConversationsRequested());
      }
    });
  }

  void _showNewDirectChatDialog() {
    showDialog(
      context: context,
      builder: (_) => NewChatDialog(
        searchUsersUseCase: getIt<SearchUsersUseCase>(),
        onUserSelected: (targetUser) {
          context.read<ConversationBloc>().add(
                CreateDirectConversationRequested(targetUser.id),
              );
        },
      ),
    );
  }

  void _showCreateGroupDialog() {
    showDialog(
      context: context,
      builder: (_) => CreateGroupDialog(
        searchUsersUseCase: getIt<SearchUsersUseCase>(),
        onGroupCreated: (title, memberUserIds) {
          context.read<ConversationBloc>().add(
                CreateGroupConversationRequested(
                  title: title,
                  memberUserIds: memberUserIds,
                ),
              );
        },
      ),
    );
  }

  void _confirmDeleteConversation(ConversationEntity conv) {
    final isGroup = conv.isGroup;
    final title = isGroup ? 'Delete / Leave Group' : 'Delete Chat';
    final content = isGroup
        ? 'Are you sure you want to delete or leave "${conv.title}"?'
        : 'Are you sure you want to delete this chat with "${conv.title}"? This will remove the conversation and all its messages.';

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(title),
        content: Text(content),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Cancel'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: Colors.redAccent),
            onPressed: () {
              Navigator.of(ctx).pop();
              context.read<ConversationBloc>().add(DeleteConversationRequested(conv.id));
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(isGroup ? 'Left / deleted group' : 'Chat deleted'),
                  backgroundColor: Colors.redAccent,
                ),
              );
            },
            child: Text(isGroup ? 'Delete / Leave' : 'Delete'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final stompService = getIt<StompClientService>();

    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            CircleAvatar(
              radius: 18,
              backgroundColor: AppTheme.primaryColor.withValues(alpha: 0.2),
              child: Text(
                widget.currentUser.displayName.isNotEmpty
                    ? widget.currentUser.displayName[0].toUpperCase()
                    : 'U',
                style: const TextStyle(color: AppTheme.primaryLight, fontWeight: FontWeight.bold),
              ),
            ),
            const SizedBox(width: 12),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  widget.currentUser.displayName,
                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
                StreamBuilder<StompConnectionStatus>(
                  stream: stompService.connectionStatusStream,
                  initialData: stompService.currentStatus,
                  builder: (context, snapshot) {
                    final status = snapshot.data ?? StompConnectionStatus.disconnected;
                    final isConnected = status == StompConnectionStatus.connected;
                    final isConnecting = status == StompConnectionStatus.connecting;

                    return Row(
                      children: [
                        Container(
                          width: 8,
                          height: 8,
                          decoration: BoxDecoration(
                            color: isConnected
                                ? AppTheme.accentGreen
                                : (isConnecting ? Colors.amber : Colors.redAccent),
                            shape: BoxShape.circle,
                          ),
                        ),
                        const SizedBox(width: 5),
                        Text(
                          isConnected ? 'STOMP Connected' : (isConnecting ? 'Connecting...' : 'Offline'),
                          style: TextStyle(
                            fontSize: 11,
                            color: isConnected ? Colors.green.shade400 : Colors.grey.shade400,
                          ),
                        ),
                      ],
                    );
                  },
                ),
              ],
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            tooltip: 'Refresh',
            onPressed: () {
              context.read<ConversationBloc>().add(FetchConversationsRequested());
            },
          ),
          PopupMenuButton<String>(
            icon: const Icon(Icons.more_vert_rounded),
            onSelected: (val) {
              if (val == 'logout') {
                context.read<AuthBloc>().add(AuthLogoutRequested());
              }
            },
            itemBuilder: (context) => [
              PopupMenuItem(
                value: 'profile',
                child: Row(
                  children: [
                    const Icon(Icons.person_outline, size: 20),
                    const SizedBox(width: 8),
                    Text('@${widget.currentUser.username}'),
                  ],
                ),
              ),
              const PopupMenuDivider(),
              const PopupMenuItem(
                value: 'logout',
                child: Row(
                  children: [
                    Icon(Icons.logout_rounded, size: 20, color: Colors.redAccent),
                    SizedBox(width: 8),
                    Text('Logout', style: TextStyle(color: Colors.redAccent)),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
      body: BlocConsumer<ConversationBloc, ConversationState>(
        listener: (context, state) {
          if (state is ConversationLoaded) {
            _syncWebSocketSubscriptions(state.conversations);
            if (state.newlyCreatedConversation != null) {
              _openChat(state.newlyCreatedConversation!);
            }
          } else if (state is ConversationError) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text(state.errorMessage), backgroundColor: Colors.redAccent),
            );
          }
        },
        builder: (context, state) {
          return Column(
            children: [
              // Search input
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
                child: TextField(
                  controller: _searchController,
                  decoration: InputDecoration(
                    hintText: 'Search chats...',
                    prefixIcon: const Icon(Icons.search_rounded),
                    suffixIcon: _searchFilter.isNotEmpty
                        ? IconButton(
                            icon: const Icon(Icons.clear, size: 18),
                            onPressed: () {
                              _searchController.clear();
                              setState(() => _searchFilter = '');
                            },
                          )
                        : null,
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  ),
                  onChanged: (val) => setState(() => _searchFilter = val.trim().toLowerCase()),
                ),
              ),

              // Conversation list
              Expanded(
                child: Builder(
                  builder: (context) {
                    if (state is ConversationLoading) {
                      return const Center(child: CircularProgressIndicator());
                    }

                    if (state is ConversationLoaded) {
                      final filtered = state.conversations.where((c) {
                        if (_searchFilter.isEmpty) return true;
                        return c.title.toLowerCase().contains(_searchFilter) ||
                            (c.lastMessageContent?.toLowerCase().contains(_searchFilter) ?? false);
                      }).toList();

                      if (filtered.isEmpty) {
                        return Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.chat_bubble_outline_rounded, size: 64, color: Colors.grey.shade600),
                              const SizedBox(height: 16),
                              Text(
                                _searchFilter.isEmpty
                                    ? 'No conversations yet'
                                    : 'No chats match "$_searchFilter"',
                                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                'Tap the + button below to start a chat',
                                style: TextStyle(color: Colors.grey.shade400, fontSize: 13),
                              ),
                            ],
                          ),
                        );
                      }

                      return RefreshIndicator(
                        onRefresh: () async {
                          context.read<ConversationBloc>().add(FetchConversationsRequested());
                        },
                        child: ListView.builder(
                          padding: const EdgeInsets.only(top: 6, bottom: 80),
                          itemCount: filtered.length,
                          itemBuilder: (context, index) {
                            final conv = filtered[index];
                            return ConversationCard(
                              conversation: conv,
                              onTap: () => _openChat(conv),
                              onLongPress: () => _confirmDeleteConversation(conv),
                            );
                          },
                        ),
                      );
                    }

                    return Center(
                      child: ElevatedButton.icon(
                        icon: const Icon(Icons.refresh),
                        label: const Text('Retry Loading Chats'),
                        onPressed: () {
                          context.read<ConversationBloc>().add(FetchConversationsRequested());
                        },
                      ),
                    );
                  },
                ),
              ),
            ],
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: AppTheme.primaryColor,
        child: const Icon(Icons.add_comment_rounded, color: Colors.white),
        onPressed: () {
          showModalBottomSheet(
            context: context,
            backgroundColor: Theme.of(context).cardTheme.color,
            shape: const RoundedRectangleBorder(
              borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
            ),
            builder: (ctx) => SafeArea(
              child: Wrap(
                children: [
                  ListTile(
                    leading: const Icon(Icons.person_add_alt_1_rounded, color: AppTheme.primaryLight),
                    title: const Text('New Direct Message'),
                    subtitle: const Text('Start private 1-on-1 chat'),
                    onTap: () {
                      Navigator.pop(ctx);
                      _showNewDirectChatDialog();
                    },
                  ),
                  ListTile(
                    leading: const Icon(Icons.group_add_rounded, color: AppTheme.secondaryColor),
                    title: const Text('New Group Chat'),
                    subtitle: const Text('Create a multi-member group'),
                    onTap: () {
                      Navigator.pop(ctx);
                      _showCreateGroupDialog();
                    },
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
