import '../../../auth/domain/entities/user_entity.dart';
import '../entities/conversation_entity.dart';
import '../repositories/conversation_repository.dart';

class GetConversationsUseCase {
  final ConversationRepository repository;
  GetConversationsUseCase(this.repository);

  Future<List<ConversationEntity>> call() => repository.getConversations();
}

class CreateDirectConversationUseCase {
  final ConversationRepository repository;
  CreateDirectConversationUseCase(this.repository);

  Future<ConversationEntity> call(String targetUserId) =>
      repository.createOrGetDirectConversation(targetUserId);
}

class CreateGroupConversationUseCase {
  final ConversationRepository repository;
  CreateGroupConversationUseCase(this.repository);

  Future<ConversationEntity> call({
    required String title,
    required List<String> memberUserIds,
  }) =>
      repository.createGroupConversation(
        title: title,
        memberUserIds: memberUserIds,
      );
}

class SearchUsersUseCase {
  final ConversationRepository repository;
  SearchUsersUseCase(this.repository);

  Future<List<UserEntity>> call(String? query) => repository.searchUsers(query);
}

class AddGroupMembersUseCase {
  final ConversationRepository repository;
  AddGroupMembersUseCase(this.repository);

  Future<ConversationEntity> call({
    required String conversationId,
    required List<String> memberUserIds,
  }) =>
      repository.addMembersToGroup(
        conversationId: conversationId,
        memberUserIds: memberUserIds,
      );
}

class UpdateMemberRoleUseCase {
  final ConversationRepository repository;
  UpdateMemberRoleUseCase(this.repository);

  Future<ConversationEntity> call({
    required String conversationId,
    required String userId,
    required String role,
  }) =>
      repository.updateMemberRole(
        conversationId: conversationId,
        userId: userId,
        role: role,
      );
}

class RemoveGroupMemberUseCase {
  final ConversationRepository repository;
  RemoveGroupMemberUseCase(this.repository);

  Future<ConversationEntity> call({
    required String conversationId,
    required String userId,
  }) =>
      repository.removeMemberFromGroup(
        conversationId: conversationId,
        userId: userId,
      );
}

class DeleteConversationUseCase {
  final ConversationRepository repository;
  DeleteConversationUseCase(this.repository);

  Future<void> call(String conversationId) =>
      repository.deleteConversation(conversationId);
}
