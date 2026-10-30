import 'package:equatable/equatable.dart';

abstract class AuthEvent extends Equatable {
  const AuthEvent();
  @override
  List<Object?> get props => [];
}

class AuthCheckRequested extends AuthEvent {}

class AuthLoginRequested extends AuthEvent {
  final String usernameOrEmail;
  final String password;

  const AuthLoginRequested({required this.usernameOrEmail, required this.password});

  @override
  List<Object?> get props => [usernameOrEmail, password];
}

class AuthRegisterRequested extends AuthEvent {
  final String username;
  final String email;
  final String password;
  final String displayName;

  const AuthRegisterRequested({
    required this.username,
    required this.email,
    required this.password,
    required this.displayName,
  });

  @override
  List<Object?> get props => [username, email, password, displayName];
}

class AuthLogoutRequested extends AuthEvent {}
