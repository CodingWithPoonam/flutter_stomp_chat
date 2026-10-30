import 'package:equatable/equatable.dart';

class MemberEntity extends Equatable {
  final String userId;
  final String username;
  final String displayName;
  final String? avatarUrl;
  final String role;
  final DateTime joinedAt;

  const MemberEntity({
    required this.userId,
    required this.username,
    required this.displayName,
    this.avatarUrl,
    required this.role,
    required this.joinedAt,
  });

  @override
  List<Object?> get props => [userId, username, displayName, avatarUrl, role, joinedAt];
}
