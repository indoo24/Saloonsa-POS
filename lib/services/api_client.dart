import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'logger_service.dart';

/// API Client for handling all HTTP requests
/// Includes automatic token management and detailed logging
class ApiClient {
  // Base URL for API - Change this to match your server
  static const String baseUrl = 'http://10.0.2.2:8000/api';

  // Storage keys
  static const String _tokenKey = 'auth_token';
  static const String _userKey = 'user_data';
  static const String _salonIdKey = 'salon_id';

  // Singleton pattern
  static final ApiClient _instance = ApiClient._internal();
  factory ApiClient() => _instance;
  ApiClient._internal();

  String? _authToken;
  int? _salonId;

  /// Initialize the API client by loading stored token
  Future<void> initialize() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      _authToken = prefs.getString(_tokenKey);
      _salonId = prefs.getInt(_salonIdKey);
      
      if (_authToken != null) {
        LoggerService.info('API Client initialized with stored token');
      } else {
        LoggerService.info('API Client initialized without token');
      }
    } catch (e, stackTrace) {
      LoggerService.error('Failed to initialize API Client', error: e, stackTrace: stackTrace);
    }
  }

  /// Set authentication token
  Future<void> setAuthToken(String token) async {
    _authToken = token;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_tokenKey, token);
    LoggerService.authAction('Token stored');
  }

  /// Set salon ID
  Future<void> setSalonId(int salonId) async {
    _salonId = salonId;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_salonIdKey, salonId);
    LoggerService.info('Salon ID stored: $salonId');
  }

  /// Get stored salon ID
  int? getSalonId() => _salonId;

  /// Clear authentication data
  Future<void> clearAuth() async {
    _authToken = null;
    _salonId = null;
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_tokenKey);
    await prefs.remove(_userKey);
    await prefs.remove(_salonIdKey);
    LoggerService.authAction('Auth data cleared');
  }

  /// Get stored user data
  Future<Map<String, dynamic>?> getUserData() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final userData = prefs.getString(_userKey);
      if (userData != null) {
        return json.decode(userData) as Map<String, dynamic>;
      }
    } catch (e, stackTrace) {
      LoggerService.error('Failed to get user data', error: e, stackTrace: stackTrace);
    }
    return null;
  }

  /// Save user data
  Future<void> saveUserData(Map<String, dynamic> userData) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_userKey, json.encode(userData));
      LoggerService.info('User data saved');
    } catch (e, stackTrace) {
      LoggerService.error('Failed to save user data', error: e, stackTrace: stackTrace);
    }
  }

  /// Build headers for requests
  Map<String, String> _buildHeaders({bool includeAuth = true}) {
    final headers = {
      'Content-Type': 'application/json',
      'Accept': 'application/json',
    };

    if (includeAuth && _authToken != null) {
      headers['Authorization'] = 'Bearer $_authToken';
    }

    return headers;
  }

  /// GET request
  Future<Map<String, dynamic>> get(
    String endpoint, {
    Map<String, String>? queryParams,
    bool requiresAuth = true,
  }) async {
    try {
      final uri = Uri.parse('$baseUrl$endpoint').replace(queryParameters: queryParams);
      
      LoggerService.apiRequest('GET', endpoint, data: queryParams);

      final response = await http.get(
        uri,
        headers: _buildHeaders(includeAuth: requiresAuth),
      );

      return _handleResponse(response, endpoint);
    } catch (e, stackTrace) {
      LoggerService.apiError(endpoint, e, stackTrace: stackTrace);
      throw ApiException('Network error: ${e.toString()}');
    }
  }

  /// POST request
  Future<Map<String, dynamic>> post(
    String endpoint, {
    Map<String, dynamic>? body,
    bool requiresAuth = true,
  }) async {
    try {
      final uri = Uri.parse('$baseUrl$endpoint');
      
      LoggerService.apiRequest('POST', endpoint, data: body);

      final response = await http.post(
        uri,
        headers: _buildHeaders(includeAuth: requiresAuth),
        body: body != null ? json.encode(body) : null,
      );

      return _handleResponse(response, endpoint);
    } catch (e, stackTrace) {
      LoggerService.apiError(endpoint, e, stackTrace: stackTrace);
      throw ApiException('Network error: ${e.toString()}');
    }
  }

  /// PUT request
  Future<Map<String, dynamic>> put(
    String endpoint, {
    Map<String, dynamic>? body,
    bool requiresAuth = true,
  }) async {
    try {
      final uri = Uri.parse('$baseUrl$endpoint');
      
      LoggerService.apiRequest('PUT', endpoint, data: body);

      final response = await http.put(
        uri,
        headers: _buildHeaders(includeAuth: requiresAuth),
        body: body != null ? json.encode(body) : null,
      );

      return _handleResponse(response, endpoint);
    } catch (e, stackTrace) {
      LoggerService.apiError(endpoint, e, stackTrace: stackTrace);
      throw ApiException('Network error: ${e.toString()}');
    }
  }

  /// DELETE request
  Future<Map<String, dynamic>> delete(
    String endpoint, {
    bool requiresAuth = true,
  }) async {
    try {
      final uri = Uri.parse('$baseUrl$endpoint');
      
      LoggerService.apiRequest('DELETE', endpoint);

      final response = await http.delete(
        uri,
        headers: _buildHeaders(includeAuth: requiresAuth),
      );

      return _handleResponse(response, endpoint);
    } catch (e, stackTrace) {
      LoggerService.apiError(endpoint, e, stackTrace: stackTrace);
      throw ApiException('Network error: ${e.toString()}');
    }
  }

  /// Handle API response
  Map<String, dynamic> _handleResponse(http.Response response, String endpoint) {
    final statusCode = response.statusCode;
    
    try {
      final responseData = json.decode(response.body) as Map<String, dynamic>;
      
      LoggerService.apiResponse(endpoint, statusCode, responseData);

      // Success responses (2xx)
      if (statusCode >= 200 && statusCode < 300) {
        return responseData;
      }

      // Handle error responses
      final errorMessage = responseData['message'] as String? ?? 'Unknown error';
      
      switch (statusCode) {
        case 401:
          // Unauthorized - clear token and throw
          clearAuth();
          throw ApiException('غير مصرح: $errorMessage', statusCode: 401);
        
        case 403:
          throw ApiException('ممنوع: $errorMessage', statusCode: 403);
        
        case 404:
          throw ApiException('غير موجود: $errorMessage', statusCode: 404);
        
        case 422:
          // Validation error
          final errors = responseData['errors'] as Map<String, dynamic>?;
          if (errors != null) {
            final errorMessages = errors.values
                .expand((e) => e is List ? e : [e])
                .join(', ');
            throw ValidationException(errorMessages, errors: errors);
          }
          throw ValidationException(errorMessage);
        
        case 500:
          throw ApiException('خطأ في الخادم: $errorMessage', statusCode: 500);
        
        default:
          throw ApiException('خطأ: $errorMessage', statusCode: statusCode);
      }
    } catch (e) {
      if (e is ApiException || e is ValidationException) {
        rethrow;
      }
      LoggerService.apiError(endpoint, 'Failed to parse response: $e');
      throw ApiException('خطأ في معالجة الاستجابة: ${e.toString()}');
    }
  }
}

/// Custom exception for API errors
class ApiException implements Exception {
  final String message;
  final int? statusCode;

  ApiException(this.message, {this.statusCode});

  @override
  String toString() => 'ApiException: $message${statusCode != null ? ' (Status: $statusCode)' : ''}';
}

/// Custom exception for validation errors
class ValidationException implements Exception {
  final String message;
  final Map<String, dynamic>? errors;

  ValidationException(this.message, {this.errors});

  @override
  String toString() => 'ValidationException: $message';
}
