import '../../domain/entities/conversation_entity.dart';
import '../../domain/entities/member_entity.dart';

class MemberModel extends MemberEntity {
  const MemberModel({
    required super.userId,
    required super.username,
    required super.displayName,
    super.avatarUrl,
    required super.role,
    required super.joinedAt,
  });

  factory MemberModel.fromJson(Map<String, dynamic> json) {
    return MemberModel(
      userId: json['userId'] as String,
      username: json['username'] as String,
      displayName: json['displayName'] as String,
      avatarUrl: json['avatarUrl'] as String?,
      role: json['role'] as String? ?? 'MEMBER',
      joinedAt: json['joinedAt'] != null
          ? DateTime.parse(json['joinedAt'] as String)
          : DateTime.now(),
    );
  }
}

class ConversationModel extends ConversationEntity {
  const ConversationModel({
    required super.id,
    required super.type,
    required super.title,
    super.creatorId,
    required super.members,
    super.lastMessageContent,
    super.lastMessageSentAt,
    required super.updatedAt,
  });

  factory ConversationModel.fromJson(Map<String, dynamic> json) {
    final rawMembers = json['members'] as List<dynamic>? ?? [];
    final members = rawMembers
        .map((m) => MemberModel.fromJson(m as Map<String, dynamic>))
        .toList();

    String? lastContent;
    DateTime? lastSentAt;
    if (json['lastMessage'] != null && json['lastMessage'] is Map<String, dynamic>) {
      final msg = json['lastMessage'] as Map<String, dynamic>;
      lastContent = msg['content'] as String?;
      if (msg['sentAt'] != null) {
        lastSentAt = DateTime.parse(msg['sentAt'] as String);
      }
    }

    return ConversationModel(
      id: json['id'] as String,
      type: json['type'] as String,
      title: (json['title'] as String?) ?? 'Chat',
      creatorId: json['creatorId'] as String?,
      members: members,
      lastMessageContent: lastContent,
      lastMessageSentAt: lastSentAt,
      updatedAt: json['updatedAt'] != null
          ? DateTime.parse(json['updatedAt'] as String)
          : DateTime.now(),
    );
  }
}
