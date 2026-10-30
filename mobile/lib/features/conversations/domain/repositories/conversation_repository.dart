import '../../../auth/domain/entities/user_entity.dart';
import '../entities/conversation_entity.dart';

abstract class ConversationRepository {
  Future<List<ConversationEntity>> getConversations();
  Future<ConversationEntity> createOrGetDirectConversation(String targetUserId);
  Future<ConversationEntity> createGroupConversation({
    required String title,
    required List<String> memberUserIds,
  });
  Future<List<UserEntity>> searchUsers(String? query);
  Future<ConversationEntity> addMembersToGroup({
    required String conversationId,
    required List<String> memberUserIds,
  });
  Future<ConversationEntity> updateMemberRole({
    required String conversationId,
    required String userId,
    required String role,
  });
  Future<ConversationEntity> removeMemberFromGroup({
    required String conversationId,
    required String userId,
  });
  Future<void> deleteConversation(String conversationId);
}
