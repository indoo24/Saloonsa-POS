import 'dart:async';
import 'package:blue_thermal_printer/blue_thermal_printer.dart';
import 'package:logger/logger.dart';
import 'package:permission_handler/permission_handler.dart';
import '../screens/casher/models/printer_device.dart';

/// Production-grade Bluetooth Classic thermal printer discovery service
///
/// This service handles ONLY Bluetooth Classic (SPP/RFCOMM) printers,
/// NOT Bluetooth Low Energy (BLE) devices.
///
/// KEY CONCEPTS:
/// - Thermal printers use Bluetooth Classic, not BLE
/// - Classic devices must be paired at system level first
/// - We retrieve bonded (paired) devices, not scan for new ones
/// - No BLE scanning is performed - it would never find thermal printers
///
/// COMPATIBILITY: Android 8-14
class BluetoothClassicPrinterService {
  static final BluetoothClassicPrinterService _instance =
      BluetoothClassicPrinterService._internal();
  factory BluetoothClassicPrinterService() => _instance;
  BluetoothClassicPrinterService._internal();

  final Logger _logger = Logger();
  final BlueThermalPrinter _bluetooth = BlueThermalPrinter.instance;

  /// Comprehensive pre-flight check for Bluetooth Classic operations
  ///
  /// Verifies:
  /// 1. Bluetooth hardware availability
  /// 2. Bluetooth enabled state
  /// 3. Required permissions (version-specific)
  ///
  /// Returns detailed check result with user-friendly error messages
  Future<BluetoothClassicCheck> performPreFlightCheck() async {
    _logger.i('🔍 [Bluetooth Classic] Starting pre-flight check...');

    final errors = <String>[];

    // ========================================================================
    // CHECK 1: Bluetooth Hardware Availability
    // ========================================================================
    bool isAvailable = false;
    try {
      final available = await _bluetooth.isAvailable;
      isAvailable = available ?? false;

      if (!isAvailable) {
        _logger.e('❌ Bluetooth hardware not available on this device');
        errors.add('HARDWARE_NOT_AVAILABLE');
        return BluetoothClassicCheck(
          isReady: false,
          isBluetoothAvailable: false,
          isBluetoothEnabled: false,
          hasRequiredPermissions: false,
          errorCode: 'BLUETOOTH_NOT_SUPPORTED',
          errorMessage: 'هذا الجهاز لا يدعم البلوتوث',
          userGuidance:
              'جهازك لا يحتوي على Bluetooth. يرجى استخدام طابعة WiFi بدلاً من ذلك.',
        );
      }

      _logger.i('✅ Bluetooth hardware available');
    } catch (e) {
      _logger.e('❌ Failed to check Bluetooth availability: $e');
      errors.add('AVAILABILITY_CHECK_FAILED');
      return BluetoothClassicCheck(
        isReady: false,
        isBluetoothAvailable: false,
        isBluetoothEnabled: false,
        hasRequiredPermissions: false,
        errorCode: 'BLUETOOTH_CHECK_FAILED',
        errorMessage: 'فشل التحقق من البلوتوث: $e',
        userGuidance: 'حدث خطأ عند فحص البلوتوث. يرجى إعادة تشغيل التطبيق.',
      );
    }

    // ========================================================================
    // CHECK 2: Bluetooth Enabled State
    // ========================================================================
    bool isEnabled = false;
    try {
      final enabled = await _bluetooth.isOn;
      isEnabled = enabled ?? false;

      if (!isEnabled) {
        _logger.w('⚠️ Bluetooth is disabled');
        return BluetoothClassicCheck(
          isReady: false,
          isBluetoothAvailable: true,
          isBluetoothEnabled: false,
          hasRequiredPermissions: false,
          errorCode: 'BLUETOOTH_DISABLED',
          errorMessage: 'البلوتوث مغلق',
          userGuidance:
              'يرجى تشغيل البلوتوث من إعدادات الجهاز والمحاولة مرة أخرى.',
          canOpenSettings: true,
        );
      }

      _logger.i('✅ Bluetooth is enabled');
    } catch (e) {
      _logger.e('❌ Failed to check Bluetooth state: $e');
      errors.add('STATE_CHECK_FAILED');
      return BluetoothClassicCheck(
        isReady: false,
        isBluetoothAvailable: true,
        isBluetoothEnabled: false,
        hasRequiredPermissions: false,
        errorCode: 'BLUETOOTH_STATE_UNKNOWN',
        errorMessage: 'لا يمكن تحديد حالة البلوتوث',
        userGuidance: 'تأكد من تشغيل البلوتوث وأعد المحاولة.',
      );
    }

    // ========================================================================
    // CHECK 3: Required Permissions (Android version-specific)
    // ========================================================================
    bool hasPermissions = false;
    try {
      hasPermissions = await _checkBluetoothPermissions();

      if (!hasPermissions) {
        _logger.w('⚠️ Missing required Bluetooth permissions');
        return BluetoothClassicCheck(
          isReady: false,
          isBluetoothAvailable: true,
          isBluetoothEnabled: true,
          hasRequiredPermissions: false,
          errorCode: 'PERMISSIONS_REQUIRED',
          errorMessage: 'صلاحيات البلوتوث مطلوبة',
          userGuidance:
              'يحتاج التطبيق صلاحية الاتصال بالبلوتوث للوصول إلى الطابعات.',
          canRequestPermissions: true,
        );
      }

      _logger.i('✅ All required permissions granted');
    } catch (e) {
      _logger.e('❌ Failed to check permissions: $e');
      return BluetoothClassicCheck(
        isReady: false,
        isBluetoothAvailable: true,
        isBluetoothEnabled: true,
        hasRequiredPermissions: false,
        errorCode: 'PERMISSION_CHECK_FAILED',
        errorMessage: 'فشل التحقق من الصلاحيات',
        userGuidance:
            'حدث خطأ عند فحص الصلاحيات. يرجى منح صلاحيات البلوتوث يدوياً من الإعدادات.',
        canOpenSettings: true,
      );
    }

    // ========================================================================
    // ALL CHECKS PASSED ✅
    // ========================================================================
    _logger.i(
      '✅ Pre-flight check PASSED - Ready for Bluetooth Classic operations',
    );

    return BluetoothClassicCheck(
      isReady: true,
      isBluetoothAvailable: true,
      isBluetoothEnabled: true,
      hasRequiredPermissions: true,
      errorCode: null,
      errorMessage: null,
      userGuidance: null,
    );
  }

  /// Check Bluetooth permissions (Android version-aware)
  ///
  /// Android 8-11 (API 26-30): Checks legacy permissions
  /// Android 12+ (API 31+): Checks BLUETOOTH_CONNECT
  Future<bool> _checkBluetoothPermissions() async {
    _logger.i('🔐 Checking Bluetooth permissions...');

    // For Android 12+ (API 31+), we need BLUETOOTH_CONNECT
    // For earlier versions, permissions are automatically granted at install time
    final connectStatus = await Permission.bluetoothConnect.status;

    _logger.i('  BLUETOOTH_CONNECT: $connectStatus');

    // Note: We do NOT check BLUETOOTH_SCAN or Location here because:
    // - BLUETOOTH_SCAN is only needed for BLE discovery (we use bonded devices)
    // - Location is only needed for BLE scanning on Android < 12
    // - For Classic bonded devices on Android 12+, BLUETOOTH_CONNECT is sufficient

    return connectStatus.isGranted;
  }

  /// Request required Bluetooth permissions
  ///
  /// Returns true if permissions granted
  /// Returns false if denied (can retry)
  /// Throws exception if permanently denied (must open settings)
  Future<bool> requestBluetoothPermissions() async {
    _logger.i('📋 Requesting Bluetooth permissions...');

    final status = await Permission.bluetoothConnect.request();

    if (status.isGranted) {
      _logger.i('✅ BLUETOOTH_CONNECT permission granted');
      return true;
    } else if (status.isPermanentlyDenied) {
      _logger.e('❌ BLUETOOTH_CONNECT permanently denied - must open settings');
      throw BluetoothPermissionPermanentlyDeniedException();
    } else {
      _logger.w('⚠️ BLUETOOTH_CONNECT permission denied');
      return false;
    }
  }

  /// Discover bonded Bluetooth Classic thermal printers
  ///
  /// This retrieves devices already paired in Android Settings.
  /// NO BLE scanning is performed - Bluetooth Classic devices must be
  /// paired at system level before they can be used.
  ///
  /// PRODUCTION FIX: Hard timeout of 3 seconds for bonded device retrieval
  /// Bluetooth Classic paired device lookup should be instant (< 100ms)
  /// If it takes longer, something is wrong - fail fast with timeout
  ///
  /// Returns list of discovered printers with thermal printer filtering
  Future<List<PrinterDevice>> discoverBondedPrinters({
    bool filterThermalOnly = true,
  }) async {
    _logger.i('🔍 Discovering bonded Bluetooth Classic devices...');

    try {
      // CRITICAL FIX: Wrap bonded device retrieval in timeout
      // getBondedDevices() should be instant but can hang on some devices
      final bondedDevices = await Future.any([
        _bluetooth.getBondedDevices(),
        Future.delayed(
          const Duration(seconds: 3),
          () => throw TimeoutException(
            'Bonded device retrieval timed out',
            const Duration(seconds: 3),
          ),
        ),
      ]);

      _logger.i('📱 Found ${bondedDevices.length} bonded Bluetooth device(s)');

      if (bondedDevices.isEmpty) {
        _logger.w('⚠️ No bonded Bluetooth devices found');
        _logger.i('💡 User guidance: Pair printer in Android Settings first');
        return [];
      }

      // Convert to PrinterDevice format
      final allDevices = bondedDevices.map((device) {
        final printerDevice = PrinterDevice(
          id: 'bt_classic_${device.address}',
          name: device.name ?? 'Unknown Device (${device.address})',
          address: device.address,
          type: PrinterConnectionType.bluetooth,
          isConnected: false,
        );

        _logger.d('  📱 ${printerDevice.name} (${printerDevice.address})');
        return printerDevice;
      }).toList();

      // PRODUCTION FIX: Return ALL bonded devices without filtering
      // This ensures any paired printer appears in the app
      _logger.i(
        '✅ Returning ALL ${allDevices.length} bonded device(s) without filtering',
      );
      _logger.i('   Note: User can connect to any bonded device');

      return allDevices;
    } on TimeoutException catch (e) {
      _logger.e('❌ Timeout retrieving bonded devices: $e');
      // Return empty list on timeout - this will trigger "no printers found" UI
      return [];
    } catch (e) {
      _logger.e('❌ Failed to discover bonded devices: $e');
      rethrow;
    }
  }

  /// Get count of bonded devices (for UI display)
  Future<int> getBondedDeviceCount() async {
    try {
      final devices = await _bluetooth.getBondedDevices();
      return devices.length;
    } catch (e) {
      _logger.e('Failed to get bonded device count: $e');
      return 0;
    }
  }

  /// Check if Bluetooth is currently enabled
  Future<bool> isBluetoothEnabled() async {
    try {
      final enabled = await _bluetooth.isOn;
      return enabled ?? false;
    } catch (e) {
      _logger.e('Failed to check Bluetooth state: $e');
      return false;
    }
  }
}

// ============================================================================
// Data Classes
// ============================================================================

/// Result of Bluetooth Classic pre-flight check
class BluetoothClassicCheck {
  final bool isReady;
  final bool isBluetoothAvailable;
  final bool isBluetoothEnabled;
  final bool hasRequiredPermissions;
  final String? errorCode;
  final String? errorMessage;
  final String? userGuidance;
  final bool canOpenSettings;
  final bool canRequestPermissions;

  const BluetoothClassicCheck({
    required this.isReady,
    required this.isBluetoothAvailable,
    required this.isBluetoothEnabled,
    required this.hasRequiredPermissions,
    this.errorCode,
    this.errorMessage,
    this.userGuidance,
    this.canOpenSettings = false,
    this.canRequestPermissions = false,
  });

  /// Get a user-friendly Arabic message for the current state
  String get arabicMessage {
    if (isReady) return 'جاهز للبحث عن الطابعات';
    return errorMessage ?? 'حدث خطأ غير معروف';
  }

  /// Get actionable user guidance
  String get actionableGuidance {
    if (isReady) return '';
    return userGuidance ?? 'يرجى المحاولة مرة أخرى';
  }
}

/// Exception thrown when Bluetooth permissions are permanently denied
class BluetoothPermissionPermanentlyDeniedException implements Exception {
  final String message;

  BluetoothPermissionPermanentlyDeniedException({
    this.message = 'Bluetooth permission permanently denied',
  });

  @override
  String toString() => message;
}
