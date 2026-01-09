import 'dart:async';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import '../../services/logger_service.dart';

/// Global Error Handler for Production
/// Catches all errors and prevents crashes
class GlobalErrorHandler {
  static bool _isInitialized = false;

  /// Initialize global error handling
  /// Call this in main() before runApp()
  static void initialize() {
    if (_isInitialized) return;
    _isInitialized = true;

    // Catch Flutter framework errors
    FlutterError.onError = (FlutterErrorDetails details) {
      if (kReleaseMode) {
        // In production: log silently, don't show red screen
        _logError(
          'Flutter Error',
          details.exception,
          details.stack,
          details.context?.toString(),
        );
      } else {
        // In debug mode: show error details for developers
        FlutterError.presentError(details);
      }
    };

    // Catch errors outside Flutter framework (async errors)
    PlatformDispatcher.instance.onError = (error, stack) {
      _logError('Platform Error', error, stack);
      return true; // Handled
    };
  }

  /// Run app with error zone to catch all async errors
  static Future<void> runAppWithErrorHandling(Widget app) async {
    await runZonedGuarded(
      () async {
        initialize();
        runApp(app);
      },
      (error, stack) {
        _logError('Uncaught Zone Error', error, stack);
      },
    );
  }

  /// Log error with context
  static void _logError(
    String type,
    Object error,
    StackTrace? stack, [
    String? context,
  ]) {
    // Log to console/file/crash reporting service
    final message = context != null
        ? '$type: ${error.toString()}\nContext: $context'
        : '$type: ${error.toString()}';

    LoggerService.error(message, error: error, stackTrace: stack);

    // TODO: Send to crash reporting service (Firebase Crashlytics, Sentry, etc.)
    // Example: FirebaseCrashlytics.instance.recordError(error, stack);
  }

  /// Get user-friendly error message
  static String getUserFriendlyMessage(Object error) {
    if (error is SocketException) {
      return 'لا يوجد اتصال بالإنترنت. تحقق من اتصالك وحاول مرة أخرى.';
    }
    if (error is TimeoutException) {
      return 'انتهت مهلة الطلب. يرجى المحاولة مرة أخرى.';
    }
    if (error is FormatException) {
      return 'حدث خطأ في معالجة البيانات. يرجى المحاولة لاحقاً.';
    }
    if (error is HttpException) {
      return 'حدث خطأ في الاتصال بالخادم. يرجى المحاولة لاحقاً.';
    }
    // Generic fallback
    return 'حدث خطأ غير متوقع. يرجى المحاولة مرة أخرى.';
  }
}

/// App-level error widget
/// Shows user-friendly error UI instead of red error screen
class AppErrorWidget extends StatelessWidget {
  final String? message;
  final VoidCallback? onRetry;
  final bool showDetails;

  const AppErrorWidget({
    super.key,
    this.message,
    this.onRetry,
    this.showDetails = false,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Theme.of(context).scaffoldBackgroundColor,
      child: Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.error_outline,
                size: 80,
                color: Theme.of(context).colorScheme.error,
              ),
              const SizedBox(height: 24),
              Text(
                message ?? 'حدث خطأ ما',
                style: Theme.of(context).textTheme.headlineSmall,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              Text(
                'نعتذر عن الإزعاج. يرجى المحاولة مرة أخرى.',
                style: Theme.of(
                  context,
                ).textTheme.bodyMedium?.copyWith(color: Colors.grey),
                textAlign: TextAlign.center,
              ),
              if (onRetry != null) ...[
                const SizedBox(height: 32),
                ElevatedButton.icon(
                  onPressed: onRetry,
                  icon: const Icon(Icons.refresh),
                  label: const Text('إعادة المحاولة'),
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 32,
                      vertical: 16,
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

/// Error boundary widget - wraps widgets to catch and handle their errors
class ErrorBoundary extends StatefulWidget {
  final Widget child;
  final Widget Function(Object error, VoidCallback retry)? errorBuilder;

  const ErrorBoundary({super.key, required this.child, this.errorBuilder});

  @override
  State<ErrorBoundary> createState() => _ErrorBoundaryState();
}

class _ErrorBoundaryState extends State<ErrorBoundary> {
  Object? _error;

  @override
  void initState() {
    super.initState();
    // Set up error handling for this subtree
    FlutterError.onError = (details) {
      if (mounted) {
        setState(() {
          _error = details.exception;
        });
      }
      GlobalErrorHandler._logError(
        'Widget Error',
        details.exception,
        details.stack,
      );
    };
  }

  void _retry() {
    setState(() {
      _error = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_error != null) {
      if (widget.errorBuilder != null) {
        return widget.errorBuilder!(_error!, _retry);
      }
      return AppErrorWidget(
        message: GlobalErrorHandler.getUserFriendlyMessage(_error!),
        onRetry: _retry,
      );
    }
    return widget.child;
  }
}
