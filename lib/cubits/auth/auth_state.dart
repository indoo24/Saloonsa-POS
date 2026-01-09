import 'package:equatable/equatable.dart';

/// Base state for Authentication
abstract class AuthState extends Equatable {
  const AuthState();

  @override
  List<Object?> get props => [];
}

/// Initial state - not logged in
class AuthInitial extends AuthState {}

/// State when checking if user is already logged in
class AuthChecking extends AuthState {}

/// State when logging in
class AuthLoading extends AuthState {}

/// State when successfully authenticated
class AuthAuthenticated extends AuthState {
  final String token;
  final int userId;
  final String username;
  final String subdomain;

  const AuthAuthenticated({
    required this.token,
    required this.userId,
    required this.username,
    required this.subdomain,
  });

  @override
  List<Object?> get props => [token, userId, username, subdomain];
}

/// State when user is not authenticated
class AuthUnauthenticated extends AuthState {}

/// State when authentication fails
class AuthError extends AuthState {
  final String message;

  const AuthError(this.message);

  @override
  List<Object?> get props => [message];
}

/// State when logging out
class AuthLoggingOut extends AuthState {}
