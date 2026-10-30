import 'package:flutter/material.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../auth/domain/entities/user_entity.dart';
import '../../domain/usecases/conversation_usecases.dart';

class NewChatDialog extends StatefulWidget {
  final SearchUsersUseCase searchUsersUseCase;
  final void Function(UserEntity selectedUser) onUserSelected;

  const NewChatDialog({
    super.key,
    required this.searchUsersUseCase,
    required this.onUserSelected,
  });

  @override
  State<NewChatDialog> createState() => _NewChatDialogState();
}

class _NewChatDialogState extends State<NewChatDialog> {
  final _searchController = TextEditingController();
  List<UserEntity> _users = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchUsers(null);
  }

  Future<void> _fetchUsers(String? query) async {
    setState(() => _isLoading = true);
    try {
      final results = await widget.searchUsersUseCase(query);
      setState(() {
        _users = results;
        _isLoading = false;
      });
    } catch (_) {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      child: Container(
        padding: const EdgeInsets.all(20),
        constraints: const BoxConstraints(maxHeight: 500, maxWidth: 420),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Start Direct Chat',
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
              controller: _searchController,
              decoration: const InputDecoration(
                hintText: 'Search by username or name...',
                prefixIcon: Icon(Icons.search),
              ),
              onChanged: (val) => _fetchUsers(val.trim()),
            ),
            const SizedBox(height: 16),
            Expanded(
              child: _isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : _users.isEmpty
                      ? Center(
                          child: Text(
                            'No users found',
                            style: TextStyle(color: Colors.grey.shade500),
                          ),
                        )
                      : ListView.separated(
                          itemCount: _users.length,
                          separatorBuilder: (context, index) => const Divider(height: 1),
                          itemBuilder: (context, index) {
                            final user = _users[index];
                            return ListTile(
                              leading: CircleAvatar(
                                backgroundColor: AppTheme.primaryColor.withValues(alpha: 0.2),
                                child: Text(
                                  user.displayName.isNotEmpty
                                      ? user.displayName[0].toUpperCase()
                                      : '?',
                                  style: const TextStyle(
                                    color: AppTheme.primaryLight,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                              title: Text(user.displayName),
                              subtitle: Text('@${user.username}'),
                              trailing: Container(
                                width: 10,
                                height: 10,
                                decoration: BoxDecoration(
                                  color: user.isOnline ? AppTheme.accentGreen : Colors.grey,
                                  shape: BoxShape.circle,
                                ),
                              ),
                              onTap: () {
                                Navigator.pop(context);
                                widget.onUserSelected(user);
                              },
                            );
                          },
                        ),
            ),
          ],
        ),
      ),
    );
  }
}
