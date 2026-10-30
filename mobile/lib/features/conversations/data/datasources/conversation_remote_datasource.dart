import 'package:dio/dio.dart';
import '../../../../core/constants/api_constants.dart';
import '../../../../core/network/api_client.dart';
import '../../../auth/data/models/user_model.dart';
import '../models/conversation_model.dart';

abstract class ConversationRemoteDataSource {
  Future<List<ConversationModel>> getConversations();
  Future<ConversationModel> createOrGetDirectConversation(String targetUserId);
  Future<ConversationModel> createGroupConversation({
    required String title,
    required List<String> memberUserIds,
  });
  Future<List<UserModel>> searchUsers(String? query);
  Future<ConversationModel> addMembersToGroup({
    required String conversationId,
    required List<String> memberUserIds,
  });
  Future<ConversationModel> updateMemberRole({
    required String conversationId,
    required String userId,
    required String role,
  });
  Future<ConversationModel> removeMemberFromGroup({
    required String conversationId,
    required String userId,
  });
  Future<void> deleteConversation(String conversationId);
}

class ConversationRemoteDataSourceImpl implements ConversationRemoteDataSource {
  final ApiClient apiClient;

  ConversationRemoteDataSourceImpl({required this.apiClient});

  @override
  Future<List<ConversationModel>> getConversations() async {
    try {
      final response = await apiClient.dio.get(ApiConstants.conversationsEndpoint);
      final list = response.data as List<dynamic>;
      return list
          .map((item) => ConversationModel.fromJson(item as Map<String, dynamic>))
          .toList();
    } on DioException catch (e) {
      throw apiClient.handleError(e);
    }
  }

  @override
  Future<ConversationModel> createOrGetDirectConversation(String targetUserId) async {
    try {
      final response = await apiClient.dio.post(
        ApiConstants.directConversationEndpoint,
        data: {'targetUserId': targetUserId},
      );
      return ConversationModel.fromJson(response.data as Map<String, dynamic>);
    } on DioException catch (e) {
      throw apiClient.handleError(e);
    }
  }

  @override
  Future<ConversationModel> createGroupConversation({
    required String title,
    required List<String> memberUserIds,
  }) async {
    try {
      final response = await apiClient.dio.post(
        ApiConstants.groupConversationEndpoint,
        data: {
          'title': title,
          'memberUserIds': memberUserIds,
        },
      );
      return ConversationModel.fromJson(response.data as Map<String, dynamic>);
    } on DioException catch (e) {
      throw apiClient.handleError(e);
    }
  }

  @override
  Future<List<UserModel>> searchUsers(String? query) async {
    try {
      final response = await apiClient.dio.get(
        ApiConstants.usersEndpoint,
        queryParameters: query != null && query.isNotEmpty ? {'query': query} : null,
      );
      final list = response.data as List<dynamic>;
      return list
          .map((item) => UserModel.fromJson(item as Map<String, dynamic>))
          .toList();
    } on DioException catch (e) {
      throw apiClient.handleError(e);
    }
  }

  @override
  Future<ConversationModel> addMembersToGroup({
    required String conversationId,
    required List<String> memberUserIds,
  }) async {
    try {
      final response = await apiClient.dio.post(
        ApiConstants.conversationMembersEndpoint(conversationId),
        data: {'memberUserIds': memberUserIds},
      );
      return ConversationModel.fromJson(response.data as Map<String, dynamic>);
    } on DioException catch (e) {
      throw apiClient.handleError(e);
    }
  }

  @override
  Future<ConversationModel> updateMemberRole({
    required String conversationId,
    required String userId,
    required String role,
  }) async {
    try {
      final response = await apiClient.dio.put(
        ApiConstants.memberRoleEndpoint(conversationId, userId),
        data: {'role': role},
      );
      return ConversationModel.fromJson(response.data as Map<String, dynamic>);
    } on DioException catch (e) {
      throw apiClient.handleError(e);
    }
  }

  @override
  Future<ConversationModel> removeMemberFromGroup({
    required String conversationId,
    required String userId,
  }) async {
    try {
      final response = await apiClient.dio.delete(
        ApiConstants.removeMemberEndpoint(conversationId, userId),
      );
      return ConversationModel.fromJson(response.data as Map<String, dynamic>);
    } on DioException catch (e) {
      throw apiClient.handleError(e);
    }
  }

  @override
  Future<void> deleteConversation(String conversationId) async {
    try {
      await apiClient.dio.delete(ApiConstants.conversationEndpoint(conversationId));
    } on DioException catch (e) {
      throw apiClient.handleError(e);
    }
  }
}
