import 'package:equatable/equatable.dart';

class UserEntity extends Equatable {
  final String id;
  final String username;
  final String email;
  final String displayName;
  final String? avatarUrl;
  final String status;

  const UserEntity({
    required this.id,
    required this.username,
    required this.email,
    required this.displayName,
    this.avatarUrl,
    required this.status,
  });

  bool get isOnline => status == 'ONLINE';

  @override
  List<Object?> get props => [id, username, email, displayName, avatarUrl, status];
}
