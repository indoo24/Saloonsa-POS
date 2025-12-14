/// Environment configuration for different deployment stages
enum EnvironmentType { development, staging, production }

/// App configuration based on environment
class AppConfig {
  final EnvironmentType environment;
  final String apiBaseUrl;
  final bool enableLogging;
  final bool enableCrashReporting;
  final bool debugShowCheckedModeBanner;
  final Duration apiTimeout;
  final int maxRetryAttempts;

  const AppConfig._({
    required this.environment,
    required this.apiBaseUrl,
    required this.enableLogging,
    required this.enableCrashReporting,
    required this.debugShowCheckedModeBanner,
    required this.apiTimeout,
    required this.maxRetryAttempts,
  });

  /// Development configuration
  static const AppConfig development = AppConfig._(
    environment: EnvironmentType.development,
    apiBaseUrl: 'http://192.168.100.8:8000/api',
    enableLogging: true,
    enableCrashReporting: false,
    debugShowCheckedModeBanner: true,
    apiTimeout: Duration(seconds: 30),
    maxRetryAttempts: 3,
  );

  /// Staging configuration
  static const AppConfig staging = AppConfig._(
    environment: EnvironmentType.staging,
    apiBaseUrl: 'https://staging-api.yourdomain.com/api',
    enableLogging: true,
    enableCrashReporting: true,
    debugShowCheckedModeBanner: true,
    apiTimeout: Duration(seconds: 30),
    maxRetryAttempts: 3,
  );

  /// Production configuration
  static const AppConfig production = AppConfig._(
    environment: EnvironmentType.production,
    apiBaseUrl: 'https://api.yourdomain.com/api',
    enableLogging: false,
    enableCrashReporting: true,
    debugShowCheckedModeBanner: false,
    apiTimeout: Duration(seconds: 30),
    maxRetryAttempts: 3,
  );

  /// Current active configuration
  /// Change this to switch environments
  /// TODO: Use --dart-define for build-time configuration
  static AppConfig current = development;

  /// Check if in development mode
  static bool get isDevelopment =>
      current.environment == EnvironmentType.development;

  /// Check if in staging mode
  static bool get isStaging => current.environment == EnvironmentType.staging;

  /// Check if in production mode
  static bool get isProduction =>
      current.environment == EnvironmentType.production;

  /// App version information
  static const String appVersion = '1.0.0';
  static const String appBuildNumber = '1';

  /// Feature flags
  static const bool enableBiometricAuth = false; // Future feature
  static const bool enableOfflineMode = false; // Future feature
  static const bool enableAnalytics = false; // Future feature

  @override
  String toString() {
    return '''
AppConfig(
  environment: ${environment.name},
  apiBaseUrl: $apiBaseUrl,
  enableLogging: $enableLogging,
  enableCrashReporting: $enableCrashReporting,
  apiTimeout: $apiTimeout,
)
''';
  }
}
