import 'package:flutter/material.dart';
import '../../../../core/di/service_locator.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../auth/domain/entities/user_entity.dart';
import '../../../conversations/domain/entities/conversation_entity.dart';
import '../../../conversations/domain/entities/member_entity.dart';
import '../../../conversations/domain/usecases/conversation_usecases.dart';

class GroupDetailsSheet extends StatefulWidget {
  final ConversationEntity conversation;
  final UserEntity currentUser;
  final void Function(ConversationEntity updatedConversation) onConversationUpdated;
  final VoidCallback? onDeleteOrLeave;

  const GroupDetailsSheet({
    super.key,
    required this.conversation,
    required this.currentUser,
    required this.onConversationUpdated,
    this.onDeleteOrLeave,
  });

  @override
  State<GroupDetailsSheet> createState() => _GroupDetailsSheetState();
}

class _GroupDetailsSheetState extends State<GroupDetailsSheet> {
  late ConversationEntity _conversation;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _conversation = widget.conversation;
  }

  bool get _isCurrentUserAdmin {
    return _conversation.members.any(
      (m) => m.userId == widget.currentUser.id && m.role == 'ADMIN',
    );
  }

  Future<void> _showAddMembersDialog() async {
    final searchUsersUseCase = getIt<SearchUsersUseCase>();
    final addGroupMembersUseCase = getIt<AddGroupMembersUseCase>();

    List<UserEntity> availableUsers = [];
    final selectedUserIds = <String>{};
    bool isSearching = true;
    String searchQuery = '';

    await showDialog(
      context: context,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (dialogCtx, setDialogState) {
            void loadUsers(String q) async {
              setDialogState(() => isSearching = true);
              try {
                final users = await searchUsersUseCase(q.isEmpty ? null : q);
                final existingMemberIds = _conversation.members.map((m) => m.userId).toSet();
                setDialogState(() {
                  availableUsers = users.where((u) => !existingMemberIds.contains(u.id)).toList();
                  isSearching = false;
                });
              } catch (_) {
                setDialogState(() => isSearching = false);
              }
            }

            if (isSearching && availableUsers.isEmpty && searchQuery.isEmpty) {
              loadUsers('');
            }

            return AlertDialog(
              backgroundColor: Theme.of(context).cardTheme.color,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
              title: const Row(
                children: [
                  Icon(Icons.person_add_alt_1_rounded, color: AppTheme.primaryLight),
                  SizedBox(width: 10),
                  Text('Add Members', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                ],
              ),
              content: SizedBox(
                width: 380,
                height: 420,
                child: Column(
                  children: [
                    TextField(
                      decoration: InputDecoration(
                        hintText: 'Search by username or name...',
                        prefixIcon: const Icon(Icons.search, size: 20),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      onChanged: (val) {
                        searchQuery = val.trim();
                        loadUsers(searchQuery);
                      },
                    ),
                    const SizedBox(height: 12),
                    Expanded(
                      child: isSearching
                          ? const Center(child: CircularProgressIndicator())
                          : availableUsers.isEmpty
                              ? Center(
                                  child: Text(
                                    searchQuery.isEmpty
                                        ? 'All registered users are already in this group'
                                        : 'No users found matching "$searchQuery"',
                                    textAlign: TextAlign.center,
                                    style: TextStyle(color: Colors.grey.shade400, fontSize: 13),
                                  ),
                                )
                              : ListView.builder(
                                  itemCount: availableUsers.length,
                                  itemBuilder: (context, index) {
                                    final user = availableUsers[index];
                                    final isSelected = selectedUserIds.contains(user.id);

                                    return CheckboxListTile(
                                      value: isSelected,
                                      activeColor: AppTheme.primaryColor,
                                      title: Text(user.displayName, style: const TextStyle(fontWeight: FontWeight.w600)),
                                      subtitle: Text('@${user.username}', style: TextStyle(color: Colors.grey.shade400, fontSize: 12)),
                                      secondary: CircleAvatar(
                                        radius: 18,
                                        backgroundColor: AppTheme.primaryColor.withValues(alpha: 0.2),
                                        child: Text(
                                          user.displayName.isNotEmpty ? user.displayName[0].toUpperCase() : '?',
                                          style: const TextStyle(color: AppTheme.primaryLight, fontWeight: FontWeight.bold),
                                        ),
                                      ),
                                      onChanged: (checked) {
                                        setDialogState(() {
                                          if (checked == true) {
                                            selectedUserIds.add(user.id);
                                          } else {
                                            selectedUserIds.remove(user.id);
                                          }
                                        });
                                      },
                                    );
                                  },
                                ),
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(dialogCtx),
                  child: const Text('Cancel'),
                ),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.primaryColor,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                  onPressed: selectedUserIds.isEmpty
                      ? null
                      : () async {
                          Navigator.pop(dialogCtx);
                          setState(() => _isLoading = true);
                          try {
                            final updated = await addGroupMembersUseCase(
                              conversationId: _conversation.id,
                              memberUserIds: selectedUserIds.toList(),
                            );
                            setState(() {
                              _conversation = updated;
                              _isLoading = false;
                            });
                            widget.onConversationUpdated(updated);
                            if (mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text('Added ${selectedUserIds.length} members to group!'),
                                  backgroundColor: AppTheme.accentGreen,
                                ),
                              );
                            }
                          } catch (e) {
                            setState(() => _isLoading = false);
                            if (mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(content: Text('Failed to add members: $e'), backgroundColor: Colors.redAccent),
                              );
                            }
                          }
                        },
                  child: Text('Add (${selectedUserIds.length})'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  Future<void> _updateMemberRole(MemberEntity member, String newRole) async {
    setState(() => _isLoading = true);
    try {
      final updateRoleUseCase = getIt<UpdateMemberRoleUseCase>();
      final updated = await updateRoleUseCase(
        conversationId: _conversation.id,
        userId: member.userId,
        role: newRole,
      );
      setState(() {
        _conversation = updated;
        _isLoading = false;
      });
      widget.onConversationUpdated(updated);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${member.displayName} is now an ${newRole == "ADMIN" ? "Admin" : "Member"}'),
            backgroundColor: AppTheme.accentGreen,
          ),
        );
      }
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to update role: $e'), backgroundColor: Colors.redAccent),
        );
      }
    }
  }

  Future<void> _removeMember(MemberEntity member) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: Theme.of(context).cardTheme.color,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text('Remove ${member.displayName}?'),
        content: Text('Are you sure you want to remove @${member.username} from this group?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.redAccent),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Remove', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    setState(() => _isLoading = true);
    try {
      final removeMemberUseCase = getIt<RemoveGroupMemberUseCase>();
      final updated = await removeMemberUseCase(
        conversationId: _conversation.id,
        userId: member.userId,
      );
      setState(() {
        _conversation = updated;
        _isLoading = false;
      });
      widget.onConversationUpdated(updated);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Removed ${member.displayName} from the group'),
            backgroundColor: Colors.orangeAccent,
          ),
        );
      }
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to remove member: $e'), backgroundColor: Colors.redAccent),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isAdmin = _isCurrentUserAdmin;

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Row(
              children: [
                CircleAvatar(
                  radius: 26,
                  backgroundColor: Colors.purpleAccent.withValues(alpha: 0.2),
                  child: const Icon(Icons.group_rounded, color: Colors.purpleAccent, size: 28),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _conversation.title,
                        style: const TextStyle(fontSize: 19, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 3),
                      Row(
                        children: [
                          Text(
                            '${_conversation.members.length} members',
                            style: TextStyle(color: Colors.grey.shade400, fontSize: 13),
                          ),
                          if (isAdmin) ...[
                            const SizedBox(width: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                              decoration: BoxDecoration(
                                color: Colors.amber.withValues(alpha: 0.2),
                                borderRadius: BorderRadius.circular(6),
                                border: Border.all(color: Colors.amber.shade700, width: 0.8),
                              ),
                              child: const Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(Icons.shield_rounded, size: 12, color: Colors.amber),
                                  SizedBox(width: 3),
                                  Text(
                                    'You are Admin',
                                    style: TextStyle(color: Colors.amber, fontSize: 11, fontWeight: FontWeight.bold),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Admin Action Buttons
            if (isAdmin)
              Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.primaryColor,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    icon: const Icon(Icons.person_add_rounded, size: 19),
                    label: const Text('Add Members to Group', style: TextStyle(fontWeight: FontWeight.bold)),
                    onPressed: _isLoading ? null : _showAddMembersDialog,
                  ),
                ),
              ),

            const Divider(),
            const SizedBox(height: 6),

            // Members Header
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Group Members',
                  style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
                ),
                Text(
                  '${_conversation.members.length} Total',
                  style: TextStyle(color: Colors.grey.shade400, fontSize: 12),
                ),
              ],
            ),
            const SizedBox(height: 8),

            // Members List
            Flexible(
              child: _isLoading
                  ? const Center(child: Padding(padding: EdgeInsets.all(20), child: CircularProgressIndicator()))
                  : ListView.separated(
                      shrinkWrap: true,
                      itemCount: _conversation.members.length,
                      separatorBuilder: (_, _) => const Divider(height: 1, indent: 48),
                      itemBuilder: (context, index) {
                        final member = _conversation.members[index];
                        final isSelf = member.userId == widget.currentUser.id;
                        final isMemberAdmin = member.role == 'ADMIN';

                        return ListTile(
                          contentPadding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                          leading: CircleAvatar(
                            radius: 18,
                            backgroundColor: isMemberAdmin
                                ? Colors.amber.withValues(alpha: 0.2)
                                : AppTheme.primaryColor.withValues(alpha: 0.2),
                            child: Text(
                              member.displayName.isNotEmpty ? member.displayName[0].toUpperCase() : '?',
                              style: TextStyle(
                                color: isMemberAdmin ? Colors.amber : AppTheme.primaryLight,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                          title: Row(
                            children: [
                              Flexible(
                                child: Text(
                                  member.displayName + (isSelf ? ' (You)' : ''),
                                  overflow: TextOverflow.ellipsis,
                                  style: TextStyle(
                                    fontWeight: isMemberAdmin ? FontWeight.bold : FontWeight.w500,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 6),
                              if (isMemberAdmin)
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1.5),
                                  decoration: BoxDecoration(
                                    color: Colors.amber.withValues(alpha: 0.15),
                                    borderRadius: BorderRadius.circular(4),
                                    border: Border.all(color: Colors.amber.shade700, width: 0.6),
                                  ),
                                  child: const Text(
                                    'ADMIN',
                                    style: TextStyle(color: Colors.amber, fontSize: 9.5, fontWeight: FontWeight.bold),
                                  ),
                                ),
                            ],
                          ),
                          subtitle: Text(
                            '@${member.username}',
                            style: TextStyle(color: Colors.grey.shade400, fontSize: 12),
                          ),
                          trailing: (isAdmin && !isSelf)
                              ? PopupMenuButton<String>(
                                  icon: const Icon(Icons.more_vert_rounded, size: 20),
                                  onSelected: (action) {
                                    if (action == 'make_admin') {
                                      _updateMemberRole(member, 'ADMIN');
                                    } else if (action == 'dismiss_admin') {
                                      _updateMemberRole(member, 'MEMBER');
                                    } else if (action == 'remove') {
                                      _removeMember(member);
                                    }
                                  },
                                  itemBuilder: (ctx) => [
                                    if (!isMemberAdmin)
                                      const PopupMenuItem(
                                        value: 'make_admin',
                                        child: Row(
                                          children: [
                                            Icon(Icons.shield_rounded, size: 18, color: Colors.amber),
                                            SizedBox(width: 8),
                                            Text('Make Group Admin'),
                                          ],
                                        ),
                                      )
                                    else
                                      const PopupMenuItem(
                                        value: 'dismiss_admin',
                                        child: Row(
                                          children: [
                                            Icon(Icons.remove_moderator_rounded, size: 18, color: Colors.orangeAccent),
                                            SizedBox(width: 8),
                                            Text('Dismiss as Admin'),
                                          ],
                                        ),
                                      ),
                                    const PopupMenuItem(
                                      value: 'remove',
                                      child: Row(
                                        children: [
                                          Icon(Icons.person_remove_rounded, size: 18, color: Colors.redAccent),
                                          SizedBox(width: 8),
                                          Text('Remove from Group', style: TextStyle(color: Colors.redAccent)),
                                        ],
                                      ),
                                    ),
                                  ],
                                )
                              : null,
                        );
                      },
                    ),
            ),
            if (widget.onDeleteOrLeave != null) ...[
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.redAccent,
                    side: const BorderSide(color: Colors.redAccent),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  icon: Icon(_isCurrentUserAdmin ? Icons.delete_outline_rounded : Icons.logout_rounded),
                  label: Text(_isCurrentUserAdmin ? 'Delete Group' : 'Leave Group'),
                  onPressed: () {
                    Navigator.pop(context);
                    widget.onDeleteOrLeave?.call();
                  },
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
