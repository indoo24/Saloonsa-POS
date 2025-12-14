import 'dart:convert';
import 'dart:async';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'logger_service.dart';
import 'network_service.dart';
import '../core/config/app_config.dart';

/// API Client for handling all HTTP requests
/// Includes automatic token management and detailed logging
class ApiClient {
  // Base URL for API - from environment configuration
  String get baseUrl => AppConfig.current.apiBaseUrl;

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
      LoggerService.error(
        'Failed to initialize API Client',
        error: e,
        stackTrace: stackTrace,
      );
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
      LoggerService.error(
        'Failed to get user data',
        error: e,
        stackTrace: stackTrace,
      );
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
      LoggerService.error(
        'Failed to save user data',
        error: e,
        stackTrace: stackTrace,
      );
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
      // Check network connectivity first
      await NetworkService().ensureConnected();

      final uri = Uri.parse(
        '$baseUrl$endpoint',
      ).replace(queryParameters: queryParams);

      LoggerService.apiRequest('GET', endpoint, data: queryParams);

      final response = await http
          .get(uri, headers: _buildHeaders(includeAuth: requiresAuth))
          .timeout(
            AppConfig.current.apiTimeout,
            onTimeout: () => throw TimeoutException('Request timeout'),
          );

      return _handleResponse(response, endpoint);
    } on SocketException catch (e, stackTrace) {
      LoggerService.apiError(endpoint, e, stackTrace: stackTrace);
      throw NetworkException('لا يوجد اتصال بالإنترنت');
    } on TimeoutException catch (e, stackTrace) {
      LoggerService.apiError(endpoint, e, stackTrace: stackTrace);
      throw NetworkException('انتهت مهلة الطلب. يرجى المحاولة مرة أخرى');
    } catch (e, stackTrace) {
      LoggerService.apiError(endpoint, e, stackTrace: stackTrace);
      throw ApiException('خطأ في الشبكة: ${e.toString()}');
    }
  }

  /// POST request
  Future<Map<String, dynamic>> post(
    String endpoint, {
    Map<String, dynamic>? body,
    bool requiresAuth = true,
  }) async {
    try {
      // Check network connectivity first
      await NetworkService().ensureConnected();

      final uri = Uri.parse('$baseUrl$endpoint');

      LoggerService.apiRequest('POST', endpoint, data: body);

      final response = await http
          .post(
            uri,
            headers: _buildHeaders(includeAuth: requiresAuth),
            body: body != null ? json.encode(body) : null,
          )
          .timeout(
            AppConfig.current.apiTimeout,
            onTimeout: () => throw TimeoutException('Request timeout'),
          );

      return _handleResponse(response, endpoint);
    } on SocketException catch (e, stackTrace) {
      LoggerService.apiError(endpoint, e, stackTrace: stackTrace);
      throw NetworkException('لا يوجد اتصال بالإنترنت');
    } on TimeoutException catch (e, stackTrace) {
      LoggerService.apiError(endpoint, e, stackTrace: stackTrace);
      throw NetworkException('انتهت مهلة الطلب. يرجى المحاولة مرة أخرى');
    } catch (e, stackTrace) {
      LoggerService.apiError(endpoint, e, stackTrace: stackTrace);
      throw ApiException('خطأ في الشبكة: ${e.toString()}');
    }
  }

  /// PUT request
  Future<Map<String, dynamic>> put(
    String endpoint, {
    Map<String, dynamic>? body,
    bool requiresAuth = true,
  }) async {
    try {
      // Check network connectivity first
      await NetworkService().ensureConnected();

      final uri = Uri.parse('$baseUrl$endpoint');

      LoggerService.apiRequest('PUT', endpoint, data: body);

      final response = await http
          .put(
            uri,
            headers: _buildHeaders(includeAuth: requiresAuth),
            body: body != null ? json.encode(body) : null,
          )
          .timeout(
            AppConfig.current.apiTimeout,
            onTimeout: () => throw TimeoutException('Request timeout'),
          );

      return _handleResponse(response, endpoint);
    } on SocketException catch (e, stackTrace) {
      LoggerService.apiError(endpoint, e, stackTrace: stackTrace);
      throw NetworkException('لا يوجد اتصال بالإنترنت');
    } on TimeoutException catch (e, stackTrace) {
      LoggerService.apiError(endpoint, e, stackTrace: stackTrace);
      throw NetworkException('انتهت مهلة الطلب. يرجى المحاولة مرة أخرى');
    } catch (e, stackTrace) {
      LoggerService.apiError(endpoint, e, stackTrace: stackTrace);
      throw ApiException('خطأ في الشبكة: ${e.toString()}');
    }
  }

  /// DELETE request
  Future<Map<String, dynamic>> delete(
    String endpoint, {
    bool requiresAuth = true,
  }) async {
    try {
      // Check network connectivity first
      await NetworkService().ensureConnected();

      final uri = Uri.parse('$baseUrl$endpoint');

      LoggerService.apiRequest('DELETE', endpoint);

      final response = await http
          .delete(uri, headers: _buildHeaders(includeAuth: requiresAuth))
          .timeout(
            AppConfig.current.apiTimeout,
            onTimeout: () => throw TimeoutException('Request timeout'),
          );

      return _handleResponse(response, endpoint);
    } on SocketException catch (e, stackTrace) {
      LoggerService.apiError(endpoint, e, stackTrace: stackTrace);
      throw NetworkException('لا يوجد اتصال بالإنترنت');
    } on TimeoutException catch (e, stackTrace) {
      LoggerService.apiError(endpoint, e, stackTrace: stackTrace);
      throw NetworkException('انتهت مهلة الطلب. يرجى المحاولة مرة أخرى');
    } catch (e, stackTrace) {
      LoggerService.apiError(endpoint, e, stackTrace: stackTrace);
      throw ApiException('خطأ في الشبكة: ${e.toString()}');
    }
  }

  /// Handle API response
  Map<String, dynamic> _handleResponse(
    http.Response response,
    String endpoint,
  ) {
    final statusCode = response.statusCode;

    try {
      // Log raw response for debugging truncation issues
      if (response.body.isEmpty) {
        LoggerService.error('Empty response body from $endpoint');
        throw ApiException('الاستجابة فارغة من الخادم');
      }

      // Try to sanitize common JSON issues from backend
      String sanitizedBody = response.body;

      // Fix common backend JSON errors:
      // 1. Missing quotes before property names like: ,commision": -> ,"commision":
      sanitizedBody = sanitizedBody.replaceAllMapped(
        RegExp(r',([a-zA-Z_][a-zA-Z0-9_]*)"(:)'),
        (match) => ',"${match.group(1)}"${match.group(2)}',
      );

      // If we made changes, log it
      if (sanitizedBody != response.body) {
        LoggerService.warning(
          'Sanitized malformed JSON from backend',
          data: {'endpoint': endpoint, 'changes': 'Fixed missing quotes'},
        );
      }

      final responseData = json.decode(sanitizedBody) as Map<String, dynamic>;

      LoggerService.apiResponse(endpoint, statusCode, responseData);

      // Success responses (2xx)
      if (statusCode >= 200 && statusCode < 300) {
        return responseData;
      }

      // Handle error responses
      final errorMessage =
          responseData['message'] as String? ?? 'Unknown error';

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

      // Enhanced error logging for JSON parsing issues
      String errorContext = '';
      if (e is FormatException) {
        // Extract character position from error message
        final match = RegExp(r'character (\d+)').firstMatch(e.toString());
        if (match != null) {
          final position = int.parse(match.group(1)!);
          final start = (position - 50).clamp(0, response.body.length);
          final end = (position + 50).clamp(0, response.body.length);
          errorContext =
              '\n\nContext around error position:\n'
              '...${response.body.substring(start, end)}...\n'
              '${' ' * (position - start - 3)}^\n'
              'Check backend JSON formatting at this location.';
        }
      }

      // Log the actual response body for debugging
      final bodyPreview = response.body.length > 500
          ? '${response.body.substring(0, 500)}...[truncated]'
          : response.body;

      LoggerService.error(
        'Failed to parse response from $endpoint. '
        'Status: $statusCode, Body length: ${response.body.length}, '
        'Preview: $bodyPreview$errorContext',
        error: e,
      );

      throw ApiException(
        'خطأ في معالجة الاستجابة: ${e.toString()}\n'
        'يوجد خطأ في تنسيق البيانات من الخادم. تواصل مع الدعم الفني.',
      );
    }
  }
}

/// Custom exception for API errors
class ApiException implements Exception {
  final String message;
  final int? statusCode;

  ApiException(this.message, {this.statusCode});

  @override
  String toString() =>
      'ApiException: $message${statusCode != null ? ' (Status: $statusCode)' : ''}';
}

/// Custom exception for validation errors
class ValidationException implements Exception {
  final String message;
  final Map<String, dynamic>? errors;

  ValidationException(this.message, {this.errors});

  @override
  String toString() => 'ValidationException: $message';
}
