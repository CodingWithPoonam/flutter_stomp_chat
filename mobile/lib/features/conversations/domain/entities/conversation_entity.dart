import 'package:equatable/equatable.dart';
import 'member_entity.dart';

class ConversationEntity extends Equatable {
  final String id;
  final String type; // 'DIRECT' or 'GROUP'
  final String title;
  final String? creatorId;
  final List<MemberEntity> members;
  final String? lastMessageContent;
  final DateTime? lastMessageSentAt;
  final DateTime updatedAt;

  const ConversationEntity({
    required this.id,
    required this.type,
    required this.title,
    this.creatorId,
    required this.members,
    this.lastMessageContent,
    this.lastMessageSentAt,
    required this.updatedAt,
  });

  bool get isGroup => type == 'GROUP';

  @override
  List<Object?> get props => [
        id,
        type,
        title,
        creatorId,
        members,
        lastMessageContent,
        lastMessageSentAt,
        updatedAt,
      ];
}
