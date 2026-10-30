import '../entities/user_entity.dart';

abstract class AuthRepository {
  Future<UserEntity> login(String usernameOrEmail, String password);
  Future<UserEntity> register({
    required String username,
    required String email,
    required String password,
    required String displayName,
  });
  Future<UserEntity?> getCurrentUser();
  Future<void> logout();
  Future<bool> isAuthenticated();
}
