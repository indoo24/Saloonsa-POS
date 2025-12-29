import 'package:logger/logger.dart';

/// Centralized logging service for the application
/// Provides detailed logging for debugging and monitoring
class LoggerService {
  static final Logger _logger = Logger(
    printer: PrettyPrinter(
      methodCount: 2,
      errorMethodCount: 8,
      lineLength: 120,
      colors: true,
      printEmojis: true,
      dateTimeFormat: DateTimeFormat.onlyTimeAndSinceStart,
    ),
  );

  // API Logging
  static void apiRequest(
    String method,
    String endpoint, {
    Map<String, dynamic>? data,
  }) {
    _logger.i(
      '🌐 API REQUEST: $method $endpoint${data != null ? '\nData: $data' : ''}',
    );
  }

  static void apiResponse(String endpoint, int statusCode, dynamic data) {
    _logger.d('✅ API RESPONSE: $endpoint\nStatus: $statusCode\nData: $data');
  }

  static void apiError(
    String endpoint,
    dynamic error, {
    StackTrace? stackTrace,
  }) {
    _logger.e(
      '❌ API ERROR: $endpoint\nError: $error',
      error: error,
      stackTrace: stackTrace,
    );
  }

  // General Logging
  static void debug(String message, {dynamic data}) {
    _logger.d('$message${data != null ? '\nData: $data' : ''}');
  }

  static void info(String message, {dynamic data}) {
    _logger.i('$message${data != null ? '\nData: $data' : ''}');
  }

  static void warning(String message, {dynamic data}) {
    _logger.w('$message${data != null ? '\nData: $data' : ''}');
  }

  static void error(String message, {dynamic error, StackTrace? stackTrace}) {
    _logger.e(message, error: error, stackTrace: stackTrace);
  }

  // Business Logic Logging
  static void authAction(String action, {dynamic data}) {
    _logger.i('🔐 AUTH: $action${data != null ? '\nData: $data' : ''}');
  }

  static void cartAction(String action, {dynamic data}) {
    _logger.i('🛒 CART: $action${data != null ? '\nData: $data' : ''}');
  }

  static void invoiceAction(String action, {dynamic data}) {
    _logger.i('🧾 INVOICE: $action${data != null ? '\nData: $data' : ''}');
  }

  static void printerAction(String action, {dynamic data}) {
    _logger.i('🖨️ PRINTER: $action${data != null ? '\nData: $data' : ''}');
  }
}
