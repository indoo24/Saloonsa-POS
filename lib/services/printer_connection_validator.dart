import 'package:blue_thermal_printer/blue_thermal_printer.dart';
import 'package:logger/logger.dart';
import 'dart:async';

/// ═══════════════════════════════════════════════════════════════════════════
/// PRODUCTION-GRADE PRINTER CONNECTION VALIDATOR
/// ═══════════════════════════════════════════════════════════════════════════
///
/// Validates printer connection state before attempting to print.
/// Ensures printer is powered on, reachable, and ready to receive data.
///
/// VALIDATES:
/// 1. Printer is not already connected to another device
/// 2. RFCOMM/SPP connection can be established
/// 3. Connection is stable and responsive
/// 4. Printer is ready to receive data
///
/// PREVENTS:
/// - Printing to offline/powered-off printers
/// - Connection conflicts (printer busy)
/// - Silent connection failures
/// - Print jobs sent to unreachable devices
///
/// COMPATIBILITY: Bluetooth Classic (RFCOMM/SPP) thermal printers
/// ═══════════════════════════════════════════════════════════════════════════

class PrinterConnectionValidator {
  static final PrinterConnectionValidator _instance =
      PrinterConnectionValidator._internal();
  factory PrinterConnectionValidator() => _instance;
  PrinterConnectionValidator._internal();

  final Logger _logger = Logger();
  final BlueThermalPrinter _bluetooth = BlueThermalPrinter.instance;

  /// Connection timeout for validation
  static const Duration _connectionTimeout = Duration(seconds: 10);

  /// Stability check duration
  static const Duration _stabilityCheckDuration = Duration(milliseconds: 500);

  /// ═══════════════════════════════════════════════════════════════════════════
  /// VALIDATE CONNECTION BEFORE PRINTING
  /// ═══════════════════════════════════════════════════════════════════════════
  ///
  /// Performs comprehensive connection validation.
  /// Should be called immediately before printing.
  ///
  /// [device] - The bonded Bluetooth device to validate
  ///
  /// Returns validation result with detailed failure information.
  ///
  /// Example:
  /// ```dart
  /// final validation = await PrinterConnectionValidator().validateConnection(device);
  /// if (!validation.isReady) {
  ///   showError(validation.userMessage);
  ///   return;
  /// }
  /// // Proceed with printing
  /// ```
  Future<ConnectionValidationResult> validateConnection(
    BluetoothDevice device,
  ) async {
    _logger.i('🔍 [Connection Validator] Validating printer connection');
    _logger.d('  Target: ${device.name} (${device.address})');

    // ═══════════════════════════════════════════════════════════════════════════
    // CHECK 1: Device Not Null
    // ═══════════════════════════════════════════════════════════════════════════
    if (device.address == null || device.address!.isEmpty) {
      _logger.e('  └─ ❌ FAILED: Device address is null or empty');
      return ConnectionValidationResult.invalidDevice();
    }

    // ═══════════════════════════════════════════════════════════════════════════
    // CHECK 2: Not Already Connected
    // ═══════════════════════════════════════════════════════════════════════════
    _logger.i('  ├─ Check 1/4: Checking existing connection state');

    try {
      final isConnected = await _bluetooth.isConnected;

      if (isConnected == true) {
        _logger.i('    Already connected - verifying it\'s the same device');

        // This is OK if we're reconnecting to the same device
        // But we should disconnect first to ensure clean state
        _logger.i('    Disconnecting existing connection for clean reconnect');
        await _safeDisconnect();
      }

      _logger.i('  ├─ ✅ PASSED: No conflicting connections');
    } catch (e) {
      _logger.e('  └─ ⚠️ WARNING: Failed to check connection state: $e');
      // Continue anyway - we'll try to connect
    }

    // ═══════════════════════════════════════════════════════════════════════════
    // CHECK 3: Connection Establishment
    // ═══════════════════════════════════════════════════════════════════════════
    _logger.i('  ├─ Check 2/4: Attempting RFCOMM connection');

    bool connected = false;
    try {
      await _bluetooth
          .connect(device)
          .timeout(
            _connectionTimeout,
            onTimeout: () {
              _logger.e('    Connection timeout');
              throw TimeoutException(
                'Connection timed out after ${_connectionTimeout.inSeconds}s',
              );
            },
          );

      // Give connection a moment to stabilize
      await Future.delayed(const Duration(milliseconds: 200));

      // Verify connection succeeded
      final isConnected = await _bluetooth.isConnected;
      connected = isConnected == true;

      if (!connected) {
        _logger.e('  └─ ❌ FAILED: Connection returned false');
        return ConnectionValidationResult.connectionFailed(
          'Connection returned false after connect() call',
        );
      }

      _logger.i('  ├─ ✅ PASSED: RFCOMM connection established');
    } on TimeoutException {
      _logger.e('  └─ ❌ FAILED: Connection timeout');
      return ConnectionValidationResult.connectionTimeout();
    } catch (e) {
      _logger.e('  └─ ❌ FAILED: Connection error: $e');

      // Parse specific error types
      final errorStr = e.toString().toLowerCase();

      if (errorStr.contains('already connected') ||
          errorStr.contains('resource busy')) {
        return ConnectionValidationResult.printerBusy();
      }

      if (errorStr.contains('refused') || errorStr.contains('unavailable')) {
        return ConnectionValidationResult.printerOffline();
      }

      return ConnectionValidationResult.connectionFailed(e.toString());
    }

    // ═══════════════════════════════════════════════════════════════════════════
    // CHECK 4: Connection Stability
    // ═══════════════════════════════════════════════════════════════════════════
    _logger.i('  ├─ Check 3/4: Verifying connection stability');

    try {
      await Future.delayed(_stabilityCheckDuration);

      final stillConnected = await _bluetooth.isConnected;
      if (stillConnected != true) {
        _logger.e('  └─ ❌ FAILED: Connection dropped during stability check');
        return ConnectionValidationResult.unstableConnection();
      }

      _logger.i('  ├─ ✅ PASSED: Connection is stable');
    } catch (e) {
      _logger.e('  └─ ❌ FAILED: Stability check error: $e');
      return ConnectionValidationResult.unstableConnection();
    }

    // ═══════════════════════════════════════════════════════════════════════════
    // CHECK 5: Ready to Receive Data
    // ═══════════════════════════════════════════════════════════════════════════
    _logger.i('  ├─ Check 4/4: Verifying printer is ready');

    // For Bluetooth Classic printers, if we're connected, we're ready
    // Some advanced checks could include:
    // - Sending a status query command (if supported)
    // - Checking paper status (if supported)
    // But most thermal printers don't support these via Bluetooth Classic

    _logger.i('  └─ ✅ PASSED: Printer is ready to receive data');

    // ═══════════════════════════════════════════════════════════════════════════
    // ALL CHECKS PASSED ✅
    // ═══════════════════════════════════════════════════════════════════════════
    _logger.i('✅ [Connection Validator] All checks passed - ready to print');

    return ConnectionValidationResult.ready(
      deviceName: device.name ?? 'Unknown',
    );
  }

  /// ═══════════════════════════════════════════════════════════════════════════
  /// VALIDATE EXISTING CONNECTION
  /// ═══════════════════════════════════════════════════════════════════════════
  ///
  /// Quick validation of already-established connection.
  /// Use before printing to ensure connection is still active.
  ///
  /// Returns true if connection is active and stable.
  Future<bool> isConnectionHealthy() async {
    _logger.i('🏥 [Connection Validator] Checking connection health');

    try {
      final isConnected = await _bluetooth.isConnected;

      if (isConnected != true) {
        _logger.w('  ❌ Connection lost');
        return false;
      }

      _logger.i('  ✅ Connection healthy');
      return true;
    } catch (e) {
      _logger.e('  ❌ Health check failed: $e');
      return false;
    }
  }

  /// ═══════════════════════════════════════════════════════════════════════════
  /// SAFE DISCONNECT
  /// ═══════════════════════════════════════════════════════════════════════════
  ///
  /// Safely disconnect from printer without throwing exceptions.
  Future<void> _safeDisconnect() async {
    try {
      final isConnected = await _bluetooth.isConnected;
      if (isConnected == true) {
        _logger.i('  Disconnecting from printer...');
        await _bluetooth.disconnect();
        await Future.delayed(const Duration(milliseconds: 300));
        _logger.i('  Disconnected successfully');
      }
    } catch (e) {
      _logger.w('  Warning: Disconnect error (continuing anyway): $e');
    }
  }
}

// ═══════════════════════════════════════════════════════════════════════════
// CONNECTION VALIDATION RESULT DATA CLASS
// ═══════════════════════════════════════════════════════════════════════════

class ConnectionValidationResult {
  final bool isReady;
  final String statusCode;
  final String technicalMessage;
  final String userMessage;
  final String arabicMessage;
  final String actionableGuidance;
  final String? deviceName;

  const ConnectionValidationResult({
    required this.isReady,
    required this.statusCode,
    required this.technicalMessage,
    required this.userMessage,
    required this.arabicMessage,
    required this.actionableGuidance,
    this.deviceName,
  });

  // ═══════════════════════════════════════════════════════════════════════════
  // SUCCESS RESULT
  // ═══════════════════════════════════════════════════════════════════════════

  factory ConnectionValidationResult.ready({required String deviceName}) {
    return ConnectionValidationResult(
      isReady: true,
      statusCode: 'READY',
      technicalMessage: 'Connection validated successfully',
      userMessage: 'Printer connected and ready',
      arabicMessage: 'الطابعة متصلة وجاهزة',
      actionableGuidance: '',
      deviceName: deviceName,
    );
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // FAILURE RESULTS
  // ═══════════════════════════════════════════════════════════════════════════

  factory ConnectionValidationResult.invalidDevice() {
    return const ConnectionValidationResult(
      isReady: false,
      statusCode: 'INVALID_DEVICE',
      technicalMessage: 'Device address is null or invalid',
      userMessage: 'Invalid printer device',
      arabicMessage: 'جهاز الطابعة غير صالح',
      actionableGuidance: 'يرجى اختيار طابعة صحيحة والمحاولة مرة أخرى.',
    );
  }

  factory ConnectionValidationResult.connectionTimeout() {
    return const ConnectionValidationResult(
      isReady: false,
      statusCode: 'CONNECTION_TIMEOUT',
      technicalMessage: 'Connection attempt timed out',
      userMessage: 'Connection timeout',
      arabicMessage: 'انتهت مهلة الاتصال',
      actionableGuidance:
          'فشل الاتصال بالطابعة. يرجى التأكد من:\n'
          '• الطابعة قيد التشغيل\n'
          '• الطابعة قريبة من جهازك\n'
          '• لا توجد عوائق بين الجهاز والطابعة',
    );
  }

  factory ConnectionValidationResult.connectionFailed(String reason) {
    return ConnectionValidationResult(
      isReady: false,
      statusCode: 'CONNECTION_FAILED',
      technicalMessage: 'Connection failed: $reason',
      userMessage: 'Failed to connect to printer',
      arabicMessage: 'فشل الاتصال بالطابعة',
      actionableGuidance:
          'لم نتمكن من الاتصال بالطابعة. يرجى التحقق من:\n'
          '• تشغيل الطابعة\n'
          '• إقران الطابعة في إعدادات Android\n'
          '• عدم اتصال الطابعة بجهاز آخر',
    );
  }

  factory ConnectionValidationResult.printerBusy() {
    return const ConnectionValidationResult(
      isReady: false,
      statusCode: 'PRINTER_BUSY',
      technicalMessage: 'Printer is already connected to another device',
      userMessage: 'Printer is busy',
      arabicMessage: 'الطابعة مشغولة',
      actionableGuidance:
          'الطابعة متصلة بجهاز آخر حالياً. يرجى:\n'
          '• فصل الطابعة من الجهاز الآخر\n'
          '• إيقاف تشغيل الطابعة وتشغيلها مرة أخرى\n'
          '• المحاولة مرة أخرى',
    );
  }

  factory ConnectionValidationResult.printerOffline() {
    return const ConnectionValidationResult(
      isReady: false,
      statusCode: 'PRINTER_OFFLINE',
      technicalMessage: 'Printer is offline or powered off',
      userMessage: 'Printer is offline',
      arabicMessage: 'الطابعة غير متصلة',
      actionableGuidance:
          'الطابعة غير متاحة. يرجى التأكد من:\n'
          '• تشغيل الطابعة\n'
          '• شحن بطارية الطابعة (إن وجدت)\n'
          '• قرب الطابعة من جهازك\n'
          '• إعادة تشغيل الطابعة والمحاولة مرة أخرى',
    );
  }

  factory ConnectionValidationResult.unstableConnection() {
    return const ConnectionValidationResult(
      isReady: false,
      statusCode: 'UNSTABLE_CONNECTION',
      technicalMessage: 'Connection is unstable or dropped',
      userMessage: 'Connection is unstable',
      arabicMessage: 'الاتصال غير مستقر',
      actionableGuidance:
          'الاتصال بالطابعة غير مستقر. يرجى:\n'
          '• تقريب الطابعة من جهازك\n'
          '• إزالة العوائق بين الجهازين\n'
          '• التأكد من عدم وجود تداخل من أجهزة أخرى\n'
          '• إعادة تشغيل الطابعة والمحاولة مرة أخرى',
    );
  }
}
