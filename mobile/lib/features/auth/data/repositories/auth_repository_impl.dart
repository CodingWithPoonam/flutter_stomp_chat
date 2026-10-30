import '../../../../core/storage/secure_storage_service.dart';
import '../../domain/entities/user_entity.dart';
import '../../domain/repositories/auth_repository.dart';
import '../datasources/auth_remote_datasource.dart';
import '../models/user_model.dart';

class AuthRepositoryImpl implements AuthRepository {
  final AuthRemoteDataSource remoteDataSource;
  final SecureStorageService storageService;

  AuthRepositoryImpl({
    required this.remoteDataSource,
    required this.storageService,
  });

  @override
  Future<UserEntity> login(String usernameOrEmail, String password) {
    return remoteDataSource.login(usernameOrEmail, password);
  }

  @override
  Future<UserEntity> register({
    required String username,
    required String email,
    required String password,
    required String displayName,
  }) {
    return remoteDataSource.register(
      username: username,
      email: email,
      password: password,
      displayName: displayName,
    );
  }

  @override
  Future<UserEntity?> getCurrentUser() async {
    // 1. Try cached local user data first
    final cached = await storageService.getUserData();
    if (cached != null) {
      try {
        // Asynchronously refresh in background
        remoteDataSource.getMe().catchError((_) => null);
        return UserModel.fromJson(cached);
      } catch (_) {}
    }

    // 2. If token exists, fetch from backend
    final token = await storageService.getToken();
    if (token != null && token.isNotEmpty) {
      try {
        return await remoteDataSource.getMe();
      } catch (_) {
        return null;
      }
    }
    return null;
  }

  @override
  Future<void> logout() async {
    await storageService.clearAll();
  }

  @override
  Future<bool> isAuthenticated() async {
    final token = await storageService.getToken();
    return token != null && token.isNotEmpty;
  }
}
