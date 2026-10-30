import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/di/service_locator.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../auth/domain/entities/user_entity.dart';
import '../../../conversations/domain/entities/conversation_entity.dart';
import '../../../conversations/presentation/bloc/conversation_bloc.dart';
import '../../../conversations/presentation/bloc/conversation_event.dart';
import '../../domain/entities/message_entity.dart';
import '../../domain/usecases/chat_usecases.dart';
import '../bloc/chat_bloc.dart';
import '../bloc/chat_event.dart';
import '../bloc/chat_state.dart';
import '../widgets/chat_input_bar.dart';
import '../widgets/group_details_sheet.dart';
import '../widgets/message_bubble.dart';
import '../widgets/typing_indicator_widget.dart';

class ChatScreen extends StatelessWidget {
  final ConversationEntity conversation;
  final UserEntity currentUser;

  const ChatScreen({
    super.key,
    required this.conversation,
    required this.currentUser,
  });

  @override
  Widget build(BuildContext context) {
    return BlocProvider<ChatBloc>(
      create: (_) => ChatBloc(
        getChatHistoryUseCase: getIt<GetChatHistoryUseCase>(),
        sendMessageUseCase: getIt<SendMessageUseCase>(),
        sendTypingIndicatorUseCase: getIt<SendTypingIndicatorUseCase>(),
        subscribeToMessagesUseCase: getIt<SubscribeToMessagesUseCase>(),
        subscribeToTypingUseCase: getIt<SubscribeToTypingUseCase>(),
        editMessageUseCase: getIt<EditMessageUseCase>(),
        deleteMessageUseCase: getIt<DeleteMessageUseCase>(),
        currentUserId: currentUser.id,
      )..add(LoadChatHistoryRequested(conversation.id)),
      child: _ChatView(conversation: conversation, currentUser: currentUser),
    );
  }
}

class _ChatView extends StatefulWidget {
  final ConversationEntity conversation;
  final UserEntity currentUser;

  const _ChatView({required this.conversation, required this.currentUser});

  @override
  State<_ChatView> createState() => _ChatViewState();
}

class _ChatViewState extends State<_ChatView> {
  final ScrollController _scrollController = ScrollController();
  late ConversationEntity _conversation;

  @override
  void initState() {
    super.initState();
    _conversation = widget.conversation;
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  bool get _isCurrentUserAdmin {
    if (!_conversation.isGroup) return false;
    return _conversation.members.any(
      (m) => m.userId == widget.currentUser.id && m.role == 'ADMIN',
    );
  }

  void _showEditMessageDialog(MessageEntity msg) {
    final textController = TextEditingController(text: msg.content);
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Edit Message'),
        content: TextField(
          controller: textController,
          autofocus: true,
          decoration: const InputDecoration(
            hintText: 'Edit your message...',
          ),
          maxLines: null,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () {
              final newContent = textController.text.trim();
              if (newContent.isNotEmpty && newContent != msg.content) {
                context.read<ChatBloc>().add(
                      EditMessageRequested(
                        messageId: msg.id,
                        content: newContent,
                      ),
                    );
              }
              Navigator.of(ctx).pop();
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  void _confirmDeleteMessage(MessageEntity msg, bool forEveryone) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(forEveryone ? 'Delete for Everyone?' : 'Delete for Me?'),
        content: Text(
          forEveryone
              ? 'This will delete the message for everyone in this chat.'
              : 'This message will be removed from your view only.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Cancel'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: forEveryone ? Colors.redAccent : Colors.orangeAccent,
            ),
            onPressed: () {
              context.read<ChatBloc>().add(
                    DeleteMessageRequested(
                      messageId: msg.id,
                      forEveryone: forEveryone,
                    ),
                  );
              Navigator.of(ctx).pop();
            },
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  void _confirmDeleteConversation() {
    final isGroup = _conversation.isGroup;
    final title = isGroup ? (_isCurrentUserAdmin ? 'Delete Group' : 'Leave Group') : 'Delete Chat';
    final content = isGroup
        ? (_isCurrentUserAdmin
            ? 'Are you sure you want to delete "${_conversation.title}"? All members and messages will be removed.'
            : 'Are you sure you want to leave "${_conversation.title}"?')
        : 'Are you sure you want to delete this chat with "${_conversation.title}"? All messages will be permanently deleted.';

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
              context.read<ConversationBloc>().add(DeleteConversationRequested(_conversation.id));
              Navigator.of(context).pop(); // Go back to conversation list
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(isGroup ? (_isCurrentUserAdmin ? 'Group deleted' : 'Left group') : 'Chat deleted'),
                  backgroundColor: Colors.redAccent,
                ),
              );
            },
            child: Text(isGroup ? (_isCurrentUserAdmin ? 'Delete Group' : 'Leave Group') : 'Delete'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isGroup = _conversation.isGroup;

    return PopScope(
      onPopInvokedWithResult: (didPop, _) {
        context.read<ChatBloc>().add(LeaveChatScreenRequested());
      },
      child: Scaffold(
        appBar: AppBar(
          titleSpacing: 0,
          title: Row(
            children: [
              CircleAvatar(
                radius: 19,
                backgroundColor: isGroup ? Colors.purpleAccent : AppTheme.primaryColor,
                child: Center(
                  child: isGroup
                      ? const Icon(Icons.group_rounded, color: Colors.white, size: 20)
                      : Text(
                          _conversation.title.isNotEmpty
                              ? _conversation.title[0].toUpperCase()
                              : '?',
                          style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                        ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _conversation.title,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                    ),
                    Text(
                      isGroup
                          ? '${_conversation.members.length} members'
                          : 'Online',
                      style: TextStyle(
                        fontSize: 12,
                        color: isGroup ? Colors.grey.shade400 : AppTheme.accentGreen,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          actions: [
            IconButton(
              icon: const Icon(Icons.info_outline_rounded),
              onPressed: () {
                _showConversationDetails(context);
              },
            ),
            PopupMenuButton<String>(
              icon: const Icon(Icons.more_vert_rounded),
              onSelected: (value) {
                if (value == 'delete') {
                  _confirmDeleteConversation();
                }
              },
              itemBuilder: (ctx) => [
                PopupMenuItem(
                  value: 'delete',
                  child: Row(
                    children: [
                      const Icon(Icons.delete_outline_rounded, color: Colors.redAccent, size: 20),
                      const SizedBox(width: 8),
                      Text(
                        isGroup
                            ? (_isCurrentUserAdmin ? 'Delete Group' : 'Leave Group')
                            : 'Delete Chat',
                        style: const TextStyle(color: Colors.redAccent),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),
        body: Column(
          children: [
            // Messages list
            Expanded(
              child: BlocBuilder<ChatBloc, ChatState>(
                builder: (context, state) {
                  if (state is ChatLoading) {
                    return const Center(child: CircularProgressIndicator());
                  }

                  if (state is ChatError) {
                    return Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.error_outline_rounded, size: 48, color: Colors.redAccent.shade200),
                          const SizedBox(height: 12),
                          Text('Failed to load chat history: ${state.errorMessage}'),
                          const SizedBox(height: 12),
                          ElevatedButton(
                            onPressed: () {
                              context.read<ChatBloc>().add(LoadChatHistoryRequested(widget.conversation.id));
                            },
                            child: const Text('Retry'),
                          ),
                        ],
                      ),
                    );
                  }

                  if (state is ChatLoaded) {
                    if (state.messages.isEmpty) {
                      return Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.waving_hand_rounded, size: 48, color: Colors.amber.shade400),
                            const SizedBox(height: 16),
                            const Text(
                              'Say hello!',
                              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
                            ),
                            const SizedBox(height: 6),
                            Text(
                              'Messages are transmitted in real-time over STOMP WebSocket',
                              style: TextStyle(color: Colors.grey.shade400, fontSize: 13),
                            ),
                          ],
                        ),
                      );
                    }

                    return ListView.builder(
                      controller: _scrollController,
                      reverse: true, // Reverse list: index 0 is newest message at bottom
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      itemCount: state.messages.length,
                      itemBuilder: (context, index) {
                        final msg = state.messages[index];
                        final isMe = msg.senderId == widget.currentUser.id;

                        return MessageBubble(
                          message: msg,
                          isMe: isMe,
                          isGroup: isGroup,
                          canDeleteForEveryone: isMe || _isCurrentUserAdmin,
                          onEdit: isMe ? () => _showEditMessageDialog(msg) : null,
                          onDeleteForMe: () => _confirmDeleteMessage(msg, false),
                          onDeleteForEveryone: () => _confirmDeleteMessage(msg, true),
                        );
                      },
                    );
                  }

                  return const SizedBox.shrink();
                },
              ),
            ),

            // Ephemeral Typing indicator
            BlocBuilder<ChatBloc, ChatState>(
              buildWhen: (prev, curr) {
                if (prev is ChatLoaded && curr is ChatLoaded) {
                  return prev.typingUsers != curr.typingUsers;
                }
                return true;
              },
              builder: (context, state) {
                if (state is ChatLoaded && state.typingUsers.isNotEmpty) {
                  return Align(
                    alignment: Alignment.centerLeft,
                    child: TypingIndicatorWidget(typingUsers: state.typingUsers),
                  );
                }
                return const SizedBox.shrink();
              },
            ),

            // Bottom Chat Input Bar
            ChatInputBar(
              onSendMessage: (content) {
                context.read<ChatBloc>().add(SendMessageRequested(content));
              },
              onTypingChanged: (isTyping) {
                context.read<ChatBloc>().add(SendTypingStatusRequested(isTyping));
              },
            ),
          ],
        ),
      ),
    );
  }

  void _showConversationDetails(BuildContext context) {
    if (_conversation.isGroup) {
      showModalBottomSheet(
        context: context,
        isScrollControlled: true,
        backgroundColor: Theme.of(context).cardTheme.color,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        builder: (ctx) => GroupDetailsSheet(
          conversation: _conversation,
          currentUser: widget.currentUser,
          onConversationUpdated: (updated) {
            setState(() {
              _conversation = updated;
            });
          },
          onDeleteOrLeave: _confirmDeleteConversation,
        ),
      );
    } else {
      showModalBottomSheet(
        context: context,
        backgroundColor: Theme.of(context).cardTheme.color,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        builder: (ctx) => SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _conversation.title,
                  style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 6),
                Text(
                  'Direct Chat • ${_conversation.members.length} participants',
                  style: TextStyle(color: Colors.grey.shade400, fontSize: 13),
                ),
                const Divider(height: 24),
                const Text(
                  'Participants:',
                  style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 8),
                Flexible(
                  child: ListView.builder(
                    shrinkWrap: true,
                    itemCount: _conversation.members.length,
                    itemBuilder: (context, index) {
                      final member = _conversation.members[index];
                      return ListTile(
                        dense: true,
                        contentPadding: EdgeInsets.zero,
                        leading: CircleAvatar(
                          radius: 16,
                          child: Text(member.displayName.isNotEmpty ? member.displayName[0] : '?'),
                        ),
                        title: Text(member.displayName),
                        subtitle: Text('@${member.username}'),
                      );
                    },
                  ),
                ),
                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton.icon(
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.redAccent,
                      side: const BorderSide(color: Colors.redAccent),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    icon: const Icon(Icons.delete_outline_rounded),
                    label: const Text('Delete Chat'),
                    onPressed: () {
                      Navigator.pop(ctx);
                      _confirmDeleteConversation();
                    },
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }
  }
}
