import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../repositories/auth_repository.dart';
import 'auth_state.dart';

/// Authentication Cubit - Manages login/logout and auth state
/// 
/// HOW TO USE IN YOUR UI:
/// 1. Wrap MaterialApp with BlocProvider<AuthCubit>
/// 2. Call login method from login button
/// 3. Use BlocListener to navigate on auth state changes
class AuthCubit extends Cubit<AuthState> {
  final AuthRepository repository;

  AuthCubit({required this.repository}) : super(AuthInitial());

  /// Check if user is already logged in when app starts
  /// CALL THIS in main.dart or splash screen
  Future<void> checkAuthStatus() async {
    try {
      emit(AuthChecking());

      final isLoggedIn = await repository.isLoggedIn();
      
      if (isLoggedIn) {
        final userData = await repository.getUserData();
        if (userData != null) {
          emit(AuthAuthenticated(
            token: userData['token'] ?? '',
            userId: userData['userId'] ?? 0,
            username: userData['username'] ?? '',
            subdomain: userData['subdomain'] ?? '',
          ));
        } else {
          emit(AuthUnauthenticated());
        }
      } else {
        emit(AuthUnauthenticated());
      }
    } catch (e) {
      emit(AuthUnauthenticated());
    }
  }

  /// Login with credentials
  /// 
  /// HOW TO CALL FROM UI:
  /// ```dart
  /// ElevatedButton(
  ///   onPressed: () async {
  ///     await context.read<AuthCubit>().login(
  ///       username: usernameController.text,
  ///       password: passwordController.text,
  ///       subdomain: subdomainController.text,
  ///     );
  ///   },
  ///   child: Text('تسجيل الدخول'),
  /// )
  /// ```
  Future<void> login({
    required String username,
    required String password,
    required String subdomain,
  }) async {
    try {
      emit(AuthLoading());

      // Call repository to authenticate
      final userData = await repository.login(
        username: username,
        password: password,
        subdomain: subdomain,
      );

      // Save credentials to SharedPreferences for persistence
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('token', userData['token']);
      await prefs.setInt('userId', userData['userId']);
      await prefs.setString('username', userData['username']);
      await prefs.setString('subdomain', userData['subdomain']);

      // Emit authenticated state
      emit(AuthAuthenticated(
        token: userData['token'],
        userId: userData['userId'],
        username: userData['username'],
        subdomain: userData['subdomain'],
      ));
    } catch (e) {
      emit(AuthError(e.toString().replaceAll('Exception: ', '')));
      // Return to unauthenticated state after showing error
      await Future.delayed(const Duration(milliseconds: 100));
      emit(AuthUnauthenticated());
    }
  }

  /// Logout user
  /// 
  /// HOW TO CALL FROM UI:
  /// ```dart
  /// IconButton(
  ///   onPressed: () => context.read<AuthCubit>().logout(),
  ///   icon: Icon(Icons.logout),
  /// )
  /// ```
  Future<void> logout() async {
    try {
      emit(AuthLoggingOut());

      // Call repository logout
      await repository.logout();

      // Clear stored credentials
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove('token');
      await prefs.remove('userId');
      await prefs.remove('username');
      // Keep subdomain for next login

      emit(AuthUnauthenticated());
    } catch (e) {
      emit(AuthError('فشل في تسجيل الخروج: ${e.toString()}'));
      emit(AuthUnauthenticated());
    }
  }
}
