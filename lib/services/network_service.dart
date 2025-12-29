import 'dart:async';
import 'dart:io';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'logger_service.dart';

/// Network connectivity service with offline detection
class NetworkService {
  static final NetworkService _instance = NetworkService._internal();
  factory NetworkService() => _instance;
  NetworkService._internal();

  final Connectivity _connectivity = Connectivity();
  final StreamController<bool> _connectionStatusController =
      StreamController<bool>.broadcast();

  bool _isConnected = true;
  bool _hasCheckedInitialStatus = false;

  /// Stream of connectivity status
  Stream<bool> get connectionStatus => _connectionStatusController.stream;

  /// Current connectivity status
  bool get isConnected => _isConnected;

  /// Initialize network monitoring
  Future<void> initialize() async {
    // Check initial connectivity
    await _checkConnectivity();

    // Listen for connectivity changes
    _connectivity.onConnectivityChanged.listen((
      List<ConnectivityResult> results,
    ) {
      _handleConnectivityChange(results);
    });
  }

  /// Check connectivity and test actual internet access
  Future<void> _checkConnectivity() async {
    try {
      final results = await _connectivity.checkConnectivity();
      final hasConnection =
          results.isNotEmpty &&
          results.any((result) => result != ConnectivityResult.none);

      if (hasConnection) {
        // Double-check with actual internet test
        final hasInternet = await _testInternetConnection();
        _updateConnectionStatus(hasInternet);
      } else {
        _updateConnectionStatus(false);
      }

      _hasCheckedInitialStatus = true;
    } catch (e) {
      LoggerService.error('Failed to check connectivity', error: e);
      _updateConnectionStatus(false);
    }
  }

  /// Test actual internet connection (not just WiFi/mobile data being on)
  Future<bool> _testInternetConnection() async {
    try {
      final result = await InternetAddress.lookup(
        'google.com',
      ).timeout(const Duration(seconds: 5));
      return result.isNotEmpty && result[0].rawAddress.isNotEmpty;
    } catch (e) {
      return false;
    }
  }

  /// Handle connectivity changes
  void _handleConnectivityChange(List<ConnectivityResult> results) async {
    final hasConnection =
        results.isNotEmpty &&
        results.any((result) => result != ConnectivityResult.none);

    if (hasConnection) {
      // Wait a bit for connection to stabilize, then test
      await Future.delayed(const Duration(seconds: 1));
      final hasInternet = await _testInternetConnection();
      _updateConnectionStatus(hasInternet);
    } else {
      _updateConnectionStatus(false);
    }
  }

  /// Update and broadcast connection status
  void _updateConnectionStatus(bool isConnected) {
    if (_isConnected != isConnected || !_hasCheckedInitialStatus) {
      _isConnected = isConnected;
      _connectionStatusController.add(_isConnected);

      LoggerService.info(
        isConnected
            ? '✅ Internet connection available'
            : '❌ No internet connection',
      );
    }
  }

  /// Ensure we have internet before making API call
  Future<void> ensureConnected() async {
    if (!_isConnected) {
      // Try to check again in case status is stale
      await _checkConnectivity();

      if (!_isConnected) {
        throw NetworkException('لا يوجد اتصال بالإنترنت');
      }
    }
  }

  void dispose() {
    _connectionStatusController.close();
  }
}

/// Network exception
class NetworkException implements Exception {
  final String message;
  NetworkException(this.message);

  @override
  String toString() => 'NetworkException: $message';
}
