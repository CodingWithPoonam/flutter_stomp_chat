import '../../../auth/domain/entities/user_entity.dart';
import '../../domain/entities/conversation_entity.dart';
import '../../domain/repositories/conversation_repository.dart';
import '../datasources/conversation_remote_datasource.dart';

class ConversationRepositoryImpl implements ConversationRepository {
  final ConversationRemoteDataSource remoteDataSource;

  ConversationRepositoryImpl({required this.remoteDataSource});

  @override
  Future<List<ConversationEntity>> getConversations() {
    return remoteDataSource.getConversations();
  }

  @override
  Future<ConversationEntity> createOrGetDirectConversation(String targetUserId) {
    return remoteDataSource.createOrGetDirectConversation(targetUserId);
  }

  @override
  Future<ConversationEntity> createGroupConversation({
    required String title,
    required List<String> memberUserIds,
  }) {
    return remoteDataSource.createGroupConversation(
      title: title,
      memberUserIds: memberUserIds,
    );
  }

  @override
  Future<List<UserEntity>> searchUsers(String? query) {
    return remoteDataSource.searchUsers(query);
  }

  @override
  Future<ConversationEntity> addMembersToGroup({
    required String conversationId,
    required List<String> memberUserIds,
  }) {
    return remoteDataSource.addMembersToGroup(
      conversationId: conversationId,
      memberUserIds: memberUserIds,
    );
  }

  @override
  Future<ConversationEntity> updateMemberRole({
    required String conversationId,
    required String userId,
    required String role,
  }) {
    return remoteDataSource.updateMemberRole(
      conversationId: conversationId,
      userId: userId,
      role: role,
    );
  }

  @override
  Future<ConversationEntity> removeMemberFromGroup({
    required String conversationId,
    required String userId,
  }) {
    return remoteDataSource.removeMemberFromGroup(
      conversationId: conversationId,
      userId: userId,
    );
  }

  @override
  Future<void> deleteConversation(String conversationId) {
    return remoteDataSource.deleteConversation(conversationId);
  }
}
