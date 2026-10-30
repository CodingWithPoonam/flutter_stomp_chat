import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import '../../../../core/theme/app_theme.dart';
import '../../domain/entities/message_entity.dart';

class MessageBubble extends StatelessWidget {
  final MessageEntity message;
  final bool isMe;
  final bool isGroup;
  final bool canDeleteForEveryone;
  final VoidCallback? onEdit;
  final VoidCallback? onDeleteForMe;
  final VoidCallback? onDeleteForEveryone;

  const MessageBubble({
    super.key,
    required this.message,
    required this.isMe,
    this.isGroup = false,
    this.canDeleteForEveryone = false,
    this.onEdit,
    this.onDeleteForMe,
    this.onDeleteForEveryone,
  });

  void _showOptionsSheet(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    showModalBottomSheet(
      context: context,
      backgroundColor: isDark ? AppTheme.darkSurface : Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 12),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 36,
                  height: 4,
                  margin: const EdgeInsets.only(bottom: 12),
                  decoration: BoxDecoration(
                    color: Colors.grey.withValues(alpha: 0.3),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                if (!message.isDeletedForEveryone) ...[
                  ListTile(
                    leading: const Icon(Icons.copy_rounded),
                    title: const Text('Copy Text'),
                    onTap: () {
                      Navigator.pop(ctx);
                      Clipboard.setData(ClipboardData(text: message.content));
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Copied to clipboard')),
                      );
                    },
                  ),
                  if (isMe && onEdit != null)
                    ListTile(
                      leading: const Icon(Icons.edit_outlined, color: AppTheme.primaryLight),
                      title: const Text('Edit Message'),
                      onTap: () {
                        Navigator.pop(ctx);
                        onEdit?.call();
                      },
                    ),
                  if ((isMe || canDeleteForEveryone) && onDeleteForEveryone != null)
                    ListTile(
                      leading: const Icon(Icons.delete_sweep_rounded, color: Colors.redAccent),
                      title: Text(
                        isMe ? 'Delete for Everyone' : 'Delete for Everyone (Admin)',
                        style: const TextStyle(color: Colors.redAccent),
                      ),
                      onTap: () {
                        Navigator.pop(ctx);
                        onDeleteForEveryone?.call();
                      },
                    ),
                ],
                if (onDeleteForMe != null)
                  ListTile(
                    leading: const Icon(Icons.delete_outline_rounded, color: Colors.orangeAccent),
                    title: const Text(
                      'Delete for Me',
                      style: TextStyle(color: Colors.orangeAccent),
                    ),
                    onTap: () {
                      Navigator.pop(ctx);
                      onDeleteForMe?.call();
                    },
                  ),
              ],
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final timeStr = DateFormat('h:mm a').format(message.sentAt);
    final isDeleted = message.isDeletedForEveryone;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Align(
      alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
      child: GestureDetector(
        onLongPress: () => _showOptionsSheet(context),
        child: Container(
          margin: EdgeInsets.only(
            top: 3,
            bottom: 3,
            left: isMe ? 64 : 16,
            right: isMe ? 16 : 64,
          ),
          child: Column(
            crossAxisAlignment: isMe ? CrossAxisAlignment.end : CrossAxisAlignment.start,
            children: [
              // In group chat, show sender's name above received bubbles
              if (!isMe && isGroup)
                Padding(
                  padding: const EdgeInsets.only(left: 8, bottom: 4),
                  child: Text(
                    message.senderDisplayName,
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: AppTheme.primaryLight,
                    ),
                  ),
                ),

              // Message Bubble Box
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 11),
                decoration: BoxDecoration(
                  gradient: isMe && !isDeleted
                      ? const LinearGradient(
                          colors: [AppTheme.primaryColor, AppTheme.primaryLight],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        )
                      : null,
                  color: isDeleted
                      ? (isDark ? const Color(0xFF1E212B) : const Color(0xFFF1F3F5))
                      : (isMe
                          ? null
                          : (isDark ? AppTheme.darkSurface : Colors.white)),
                  borderRadius: BorderRadius.only(
                    topLeft: const Radius.circular(18),
                    topRight: const Radius.circular(18),
                    bottomLeft: isMe ? const Radius.circular(18) : const Radius.circular(4),
                    bottomRight: isMe ? const Radius.circular(4) : const Radius.circular(18),
                  ),
                  border: isMe && !isDeleted
                      ? null
                      : Border.all(
                          color: isDeleted
                              ? (isDark ? Colors.white12 : Colors.black12)
                              : (isDark ? AppTheme.darkBorder : AppTheme.lightBorder),
                        ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.05),
                      blurRadius: 4,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: isMe ? CrossAxisAlignment.end : CrossAxisAlignment.start,
                  children: [
                    if (isDeleted)
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.block_rounded,
                            size: 15,
                            color: isDark ? Colors.white38 : Colors.black38,
                          ),
                          const SizedBox(width: 6),
                          Text(
                            'This message was deleted',
                            style: TextStyle(
                              fontSize: 14,
                              fontStyle: FontStyle.italic,
                              color: isDark ? Colors.white38 : Colors.black38,
                            ),
                          ),
                        ],
                      )
                    else
                      Text(
                        message.content,
                        style: TextStyle(
                          fontSize: 15,
                          color: isMe
                              ? Colors.white
                              : (isDark ? Colors.white : Colors.black87),
                          height: 1.3,
                        ),
                      ),
                    const SizedBox(height: 4),
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          timeStr,
                          style: TextStyle(
                            fontSize: 10.5,
                            color: isMe && !isDeleted
                                ? Colors.white.withValues(alpha: 0.75)
                                : Colors.grey.shade400,
                          ),
                        ),
                        if (message.isEdited && !isDeleted) ...[
                          const SizedBox(width: 4),
                          Text(
                            '• (edited)',
                            style: TextStyle(
                              fontSize: 10,
                              fontStyle: FontStyle.italic,
                              color: isMe
                                  ? Colors.white.withValues(alpha: 0.75)
                                  : Colors.grey.shade400,
                            ),
                          ),
                        ],
                        if (isMe && !isDeleted) ...[
                          const SizedBox(width: 4),
                          const Icon(
                            Icons.done_all_rounded,
                            size: 13,
                            color: Colors.white70,
                          ),
                        ],
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
