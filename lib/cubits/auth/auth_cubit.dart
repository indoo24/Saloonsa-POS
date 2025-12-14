import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../repositories/auth_repository.dart';
import '../../services/api_client.dart';
import '../../services/logger_service.dart';
import 'auth_state.dart';

/// Authentication Cubit - Manages login/logout and auth state
/// Integrated with API client for real authentication
///
/// HOW TO USE IN YOUR UI:
/// 1. Wrap MaterialApp with BlocProvider<AuthCubit>
/// 2. Call login method from login button
/// 3. Use BlocListener to navigate on auth state changes
class AuthCubit extends Cubit<AuthState> {
  final AuthRepository repository;
  final ApiClient _apiClient = ApiClient();

  AuthCubit({required this.repository}) : super(AuthInitial());

  /// Check if user is already logged in when app starts
  /// CALL THIS in main.dart or splash screen
  Future<void> checkAuthStatus() async {
    try {
      emit(AuthChecking());

      LoggerService.authAction('Checking authentication status');

      // Start timer to ensure minimum splash screen display time (2.5 seconds)
      final startTime = DateTime.now();
      const minSplashDuration = Duration(milliseconds: 2500);

      // Initialize API client
      await _apiClient.initialize();

      final isLoggedIn = await repository.isLoggedIn();

      // Calculate remaining time to show splash screen
      final elapsed = DateTime.now().difference(startTime);
      final remainingTime = minSplashDuration - elapsed;

      // Wait for remaining time if needed (ensures splash screen is visible)
      if (remainingTime.inMilliseconds > 0) {
        await Future.delayed(remainingTime);
      }

      if (isLoggedIn) {
        final userData = await repository.getUserData();
        if (userData != null) {
          LoggerService.authAction(
            'User is authenticated',
            data: {'userId': userData['id'], 'username': userData['name']},
          );

          emit(
            AuthAuthenticated(
              token: '', // Token is stored in ApiClient
              userId: userData['id'] ?? 0,
              username: userData['name'] ?? '',
              subdomain: '', // Loaded from prefs in ApiClient
            ),
          );
        } else {
          LoggerService.authAction('No user data found');
          emit(AuthUnauthenticated());
        }
      } else {
        LoggerService.authAction('User not authenticated');
        emit(AuthUnauthenticated());
      }
    } catch (e, stackTrace) {
      LoggerService.error(
        'Error checking auth status',
        error: e,
        stackTrace: stackTrace,
      );
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

      LoggerService.authAction(
        'Login attempt',
        data: {'username': username, 'subdomain': subdomain},
      );

      // Call repository to authenticate
      final userData = await repository.login(
        username: username,
        password: password,
        subdomain: subdomain,
      );

      // Save subdomain to SharedPreferences for persistence
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('subdomain', subdomain);

      LoggerService.authAction(
        'Login successful',
        data: {
          'userId': userData['userId'],
          'username': userData['username'],
          'salonId': userData['salonId'],
        },
      );

      // Emit authenticated state
      emit(
        AuthAuthenticated(
          token: userData['token'],
          userId: userData['userId'],
          username: userData['username'],
          subdomain: subdomain,
        ),
      );
    } on Exception catch (e) {
      final errorMessage = e.toString().replaceAll('Exception: ', '');
      LoggerService.error('Login failed', error: e);
      emit(AuthError(errorMessage));
      // Return to unauthenticated state after showing error
      await Future.delayed(const Duration(milliseconds: 100));
      emit(AuthUnauthenticated());
    } catch (e, stackTrace) {
      LoggerService.error('Login error', error: e, stackTrace: stackTrace);
      emit(AuthError('حدث خطأ غير متوقع'));
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

      LoggerService.authAction('Logout attempt');

      // Call repository logout (clears API token)
      await repository.logout();

      // Keep subdomain for next login - only clear user-specific data
      final prefs = await SharedPreferences.getInstance();
      final subdomain = prefs.getString('subdomain');

      await prefs.clear();

      if (subdomain != null) {
        await prefs.setString('subdomain', subdomain);
      }

      LoggerService.authAction('Logout successful');

      emit(AuthUnauthenticated());
    } catch (e, stackTrace) {
      LoggerService.error('Logout failed', error: e, stackTrace: stackTrace);
      emit(AuthError('فشل في تسجيل الخروج: ${e.toString()}'));
      emit(AuthUnauthenticated());
    }
  }
}
