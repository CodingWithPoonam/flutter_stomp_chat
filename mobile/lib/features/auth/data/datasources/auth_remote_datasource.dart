import 'package:dio/dio.dart';
import '../../../../core/constants/api_constants.dart';
import '../../../../core/network/api_client.dart';
import '../../../../core/storage/secure_storage_service.dart';
import '../models/user_model.dart';

abstract class AuthRemoteDataSource {
  Future<UserModel> login(String usernameOrEmail, String password);
  Future<UserModel> register({
    required String username,
    required String email,
    required String password,
    required String displayName,
  });
  Future<UserModel?> getMe();
}

class AuthRemoteDataSourceImpl implements AuthRemoteDataSource {
  final ApiClient apiClient;
  final SecureStorageService storageService;

  AuthRemoteDataSourceImpl({
    required this.apiClient,
    required this.storageService,
  });

  @override
  Future<UserModel> login(String usernameOrEmail, String password) async {
    try {
      final response = await apiClient.dio.post(
        ApiConstants.loginEndpoint,
        data: {
          'usernameOrEmail': usernameOrEmail,
          'password': password,
        },
      );

      final data = response.data as Map<String, dynamic>;
      final token = data['token'] as String;
      final userJson = data['user'] as Map<String, dynamic>;
      final user = UserModel.fromJson(userJson);

      await storageService.saveToken(token);
      await storageService.saveUserData(user.toJson());

      return user;
    } on DioException catch (e) {
      throw apiClient.handleError(e);
    }
  }

  @override
  Future<UserModel> register({
    required String username,
    required String email,
    required String password,
    required String displayName,
  }) async {
    try {
      final response = await apiClient.dio.post(
        ApiConstants.registerEndpoint,
        data: {
          'username': username,
          'email': email,
          'password': password,
          'displayName': displayName,
        },
      );

      final data = response.data as Map<String, dynamic>;
      final token = data['token'] as String;
      final userJson = data['user'] as Map<String, dynamic>;
      final user = UserModel.fromJson(userJson);

      await storageService.saveToken(token);
      await storageService.saveUserData(user.toJson());

      return user;
    } on DioException catch (e) {
      throw apiClient.handleError(e);
    }
  }

  @override
  Future<UserModel?> getMe() async {
    try {
      final response = await apiClient.dio.get(ApiConstants.meEndpoint);
      final userJson = response.data as Map<String, dynamic>;
      final user = UserModel.fromJson(userJson);
      await storageService.saveUserData(user.toJson());
      return user;
    } on DioException catch (e) {
      throw apiClient.handleError(e);
    }
  }
}
