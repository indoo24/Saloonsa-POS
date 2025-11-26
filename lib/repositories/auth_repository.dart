import '../services/api_client.dart';
import '../services/logger_service.dart';
import '../models/user.dart';
import '../models/salon.dart';

/// Repository for authentication operations with real API integration
class AuthRepository {
  final ApiClient _apiClient = ApiClient();

  /// Login with email and password
  /// Returns user data and token on success
  Future<Map<String, dynamic>> login({
    required String username,
    required String password,
    required String subdomain,
  }) async {
    try {
      LoggerService.authAction('Attempting login', data: {
        'username': username,
        'subdomain': subdomain,
      });

      // Step 1: Get salon by subdomain
      final salonResponse = await _apiClient.get(
        '/salons/by-domain/$subdomain',
        requiresAuth: false,
      );

      if (!salonResponse['success']) {
        throw Exception(salonResponse['message'] ?? 'فشل في العثور على الصالون');
      }

      final salon = Salon.fromJson(salonResponse['data']);
      LoggerService.info('Salon found', data: salon.toJson());

      // Step 2: Authenticate user
      final loginResponse = await _apiClient.post(
        '/auth/login',
        body: {
          'email': username,
          'password': password,
        },
        requiresAuth: false,
      );

      if (!loginResponse['success']) {
        throw Exception(loginResponse['message'] ?? 'فشل تسجيل الدخول');
      }

      final loginData = loginResponse['data'];
      final user = User.fromJson(loginData['user']);
      final token = loginData['token'] as String;

      // Step 3: Store token and salon ID
      await _apiClient.setAuthToken(token);
      await _apiClient.setSalonId(salon.id);
      await _apiClient.saveUserData(user.toJson());

      LoggerService.authAction('Login successful', data: {
        'userId': user.id,
        'userName': user.name,
        'salonId': salon.id,
      });

      return {
        'token': token,
        'userId': user.id,
        'username': user.name,
        'email': user.email,
        'subdomain': subdomain,
        'salonId': salon.id,
        'salonName': salon.name,
        'user': user.toJson(),
        'salon': salon.toJson(),
      };
    } on ApiException catch (e) {
      LoggerService.error('Login API error', error: e);
      // Provide user-friendly error messages
      if (e.statusCode == 404) {
        throw Exception('الصالون غير موجود. تأكد من اسم النطاق الفرعي');
      }
      throw Exception(e.message);
    } on ValidationException catch (e) {
      LoggerService.error('Login validation error', error: e);
      throw Exception(e.message);
    } catch (e, stackTrace) {
      LoggerService.error('Login failed', error: e, stackTrace: stackTrace);
      throw Exception('فشل تسجيل الدخول: ${e.toString()}');
    }
  }

  /// Logout the current user
  Future<void> logout() async {
    try {
      LoggerService.authAction('Attempting logout');

      // Call logout API
      final response = await _apiClient.post('/auth/logout');

      LoggerService.authAction('Logout API response', data: response);

      // Clear local auth data
      await _apiClient.clearAuth();

      LoggerService.authAction('Logout successful');
    } on ApiException catch (e) {
      LoggerService.error('Logout API error', error: e);
      // Even if API fails, clear local data
      await _apiClient.clearAuth();
    } catch (e, stackTrace) {
      LoggerService.error('Logout failed', error: e, stackTrace: stackTrace);
      // Even if API fails, clear local data
      await _apiClient.clearAuth();
    }
  }

  /// Check if user is logged in
  Future<bool> isLoggedIn() async {
    try {
      final userData = await _apiClient.getUserData();
      final isLoggedIn = userData != null;
      
      LoggerService.authAction('Check login status', data: {'isLoggedIn': isLoggedIn});
      
      return isLoggedIn;
    } catch (e, stackTrace) {
      LoggerService.error('Failed to check login status', error: e, stackTrace: stackTrace);
      return false;
    }
  }

  /// Get stored user data
  Future<Map<String, dynamic>?> getUserData() async {
    try {
      final userData = await _apiClient.getUserData();
      
      if (userData != null) {
        LoggerService.authAction('User data retrieved', data: userData);
      }
      
      return userData;
    } catch (e, stackTrace) {
      LoggerService.error('Failed to get user data', error: e, stackTrace: stackTrace);
      return null;
    }
  }

  /// Get current user from API
  Future<User?> getCurrentUser() async {
    try {
      LoggerService.authAction('Fetching current user from API');

      final response = await _apiClient.get('/user');

      if (!response['success']) {
        throw Exception(response['message'] ?? 'فشل في جلب بيانات المستخدم');
      }

      final user = User.fromJson(response['data']);
      
      // Update stored user data
      await _apiClient.saveUserData(user.toJson());

      LoggerService.authAction('Current user fetched', data: user.toJson());

      return user;
    } on ApiException catch (e) {
      LoggerService.error('Get current user API error', error: e);
      return null;
    } catch (e, stackTrace) {
      LoggerService.error('Failed to get current user', error: e, stackTrace: stackTrace);
      return null;
    }
  }
}

