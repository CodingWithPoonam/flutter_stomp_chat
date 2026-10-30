import 'package:flutter/material.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../auth/domain/entities/user_entity.dart';
import '../../domain/usecases/conversation_usecases.dart';

class CreateGroupDialog extends StatefulWidget {
  final SearchUsersUseCase searchUsersUseCase;
  final void Function(String title, List<String> memberUserIds) onGroupCreated;

  const CreateGroupDialog({
    super.key,
    required this.searchUsersUseCase,
    required this.onGroupCreated,
  });

  @override
  State<CreateGroupDialog> createState() => _CreateGroupDialogState();
}

class _CreateGroupDialogState extends State<CreateGroupDialog> {
  final _titleController = TextEditingController();
  final Set<String> _selectedUserIds = {};
  List<UserEntity> _availableUsers = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadUsers();
  }

  Future<void> _loadUsers() async {
    try {
      final users = await widget.searchUsersUseCase(null);
      setState(() {
        _availableUsers = users;
        _isLoading = false;
      });
    } catch (_) {
      setState(() => _isLoading = false);
    }
  }

  void _submit() {
    final title = _titleController.text.trim();
    if (title.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a group title')),
      );
      return;
    }
    if (_selectedUserIds.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select at least one member')),
      );
      return;
    }

    Navigator.pop(context);
    widget.onGroupCreated(title, _selectedUserIds.toList());
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      child: Container(
        padding: const EdgeInsets.all(20),
        constraints: const BoxConstraints(maxHeight: 560, maxWidth: 440),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'New Group Chat',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _titleController,
              decoration: const InputDecoration(
                hintText: 'Group Name (e.g., Engineering Team)',
                prefixIcon: Icon(Icons.group_outlined),
              ),
            ),
            const SizedBox(height: 14),
            Text(
              'Select Members (${_selectedUserIds.length} selected):',
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: Colors.grey.shade400,
              ),
            ),
            const SizedBox(height: 8),
            Expanded(
              child: _isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : _availableUsers.isEmpty
                      ? Center(
                          child: Text(
                            'No users available to add',
                            style: TextStyle(color: Colors.grey.shade500),
                          ),
                        )
                      : ListView.builder(
                          itemCount: _availableUsers.length,
                          itemBuilder: (context, index) {
                            final user = _availableUsers[index];
                            final isSelected = _selectedUserIds.contains(user.id);

                            return CheckboxListTile(
                              value: isSelected,
                              activeColor: AppTheme.primaryColor,
                              onChanged: (val) {
                                setState(() {
                                  if (val == true) {
                                    _selectedUserIds.add(user.id);
                                  } else {
                                    _selectedUserIds.remove(user.id);
                                  }
                                });
                              },
                              title: Text(user.displayName),
                              subtitle: Text('@${user.username}'),
                              secondary: CircleAvatar(
                                backgroundColor: AppTheme.primaryColor.withValues(alpha: 0.15),
                                child: Text(
                                  user.displayName.isNotEmpty
                                      ? user.displayName[0].toUpperCase()
                                      : '?',
                                  style: const TextStyle(color: AppTheme.primaryLight),
                                ),
                              ),
                            );
                          },
                        ),
            ),
            const SizedBox(height: 12),
            ElevatedButton(
              onPressed: _submit,
              child: const Text('Create Group'),
            ),
          ],
        ),
      ),
    );
  }
}
