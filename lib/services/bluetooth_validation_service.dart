import 'package:blue_thermal_printer/blue_thermal_printer.dart';
import 'package:logger/logger.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:device_info_plus/device_info_plus.dart';

/// ═══════════════════════════════════════════════════════════════════════════
/// PRODUCTION-GRADE BLUETOOTH VALIDATION SERVICE
/// ═══════════════════════════════════════════════════════════════════════════
///
/// Comprehensive pre-flight validation for Bluetooth Classic thermal printers.
/// This is a STRICT validation layer that must pass before any Bluetooth operation.
///
/// VALIDATES (in order):
/// 1. Bluetooth hardware availability
/// 2. Bluetooth enabled state
/// 3. Runtime permissions (Android version-aware)
/// 4. Bonded device availability
/// 5. Target printer bonding status
///
/// GUARANTEES:
/// - No silent failures
/// - No crashes from missing permissions
/// - Clear, actionable error messages in Arabic and English
/// - User-safe guidance for fixing issues
/// - Production-ready defensive programming
///
/// COMPATIBILITY: Android 8-14 (API 26-34)
/// ═══════════════════════════════════════════════════════════════════════════

class BluetoothValidationService {
  static final BluetoothValidationService _instance =
      BluetoothValidationService._internal();
  factory BluetoothValidationService() => _instance;
  BluetoothValidationService._internal();

  final Logger _logger = Logger();
  final BlueThermalPrinter _bluetooth = BlueThermalPrinter.instance;

  /// ═══════════════════════════════════════════════════════════════════════════
  /// COMPREHENSIVE PRE-FLIGHT VALIDATION
  /// ═══════════════════════════════════════════════════════════════════════════
  ///
  /// Performs ALL validation checks in the correct order.
  /// Returns detailed result with specific failure reason if not ready.
  ///
  /// This should be called:
  /// - Before scanning for devices
  /// - Before connecting to a printer
  /// - Before printing
  ///
  /// Example:
  /// ```dart
  /// final validation = await BluetoothValidationService().validate();
  /// if (!validation.isReady) {
  ///   showError(validation.userMessage);
  ///   if (validation.canOpenSettings) {
  ///     openSettings();
  ///   }
  ///   return;
  /// }
  /// // Proceed with Bluetooth operations
  /// ```
  Future<BluetoothValidationResult> validate({
    String? targetPrinterAddress,
  }) async {
    _logger.i(
      '🔍 [Bluetooth Validation] Starting comprehensive pre-flight check',
    );

    // ═══════════════════════════════════════════════════════════════════════════
    // CHECK 1: Hardware Availability
    // ═══════════════════════════════════════════════════════════════════════════
    _logger.i('  ├─ Check 1/5: Bluetooth hardware availability');

    bool isAvailable = false;
    try {
      final available = await _bluetooth.isAvailable;
      isAvailable = available ?? false;

      if (!isAvailable) {
        _logger.e('  └─ ❌ FAILED: Bluetooth hardware not available');
        return BluetoothValidationResult.hardwareNotAvailable();
      }

      _logger.i('  ├─ ✅ PASSED: Bluetooth hardware available');
    } catch (e) {
      _logger.e('  └─ ❌ FAILED: Exception checking hardware: $e');
      return BluetoothValidationResult.hardwareCheckFailed(e.toString());
    }

    // ═══════════════════════════════════════════════════════════════════════════
    // CHECK 2: Bluetooth Enabled State
    // ═══════════════════════════════════════════════════════════════════════════
    _logger.i('  ├─ Check 2/5: Bluetooth enabled state');

    bool isEnabled = false;
    try {
      final enabled = await _bluetooth.isOn;
      isEnabled = enabled ?? false;

      if (!isEnabled) {
        _logger.w('  └─ ⚠️ FAILED: Bluetooth is disabled');
        return BluetoothValidationResult.bluetoothDisabled();
      }

      _logger.i('  ├─ ✅ PASSED: Bluetooth is enabled');
    } catch (e) {
      _logger.e('  └─ ❌ FAILED: Exception checking Bluetooth state: $e');
      return BluetoothValidationResult.stateCheckFailed(e.toString());
    }

    // ═══════════════════════════════════════════════════════════════════════════
    // CHECK 3: Runtime Permissions (Android version-aware)
    // ═══════════════════════════════════════════════════════════════════════════
    _logger.i('  ├─ Check 3/5: Runtime permissions');

    bool hasPermissions = false;
    try {
      final androidInfo = await DeviceInfoPlugin().androidInfo;
      final sdkInt = androidInfo.version.sdkInt;

      _logger.d('    Android SDK: $sdkInt');

      if (sdkInt < 31) {
        // Android 8-11: Bluetooth permissions auto-granted at install time
        _logger.i('    Android < 12: Permissions auto-granted');
        hasPermissions = true;
      } else {
        // Android 12+: BLUETOOTH_CONNECT required
        final connectStatus = await Permission.bluetoothConnect.status;
        hasPermissions = connectStatus.isGranted;

        if (!hasPermissions) {
          _logger.w('  └─ ⚠️ FAILED: BLUETOOTH_CONNECT not granted');

          // Check if permanently denied
          if (connectStatus.isPermanentlyDenied) {
            return BluetoothValidationResult.permissionsPermanentlyDenied();
          }

          return BluetoothValidationResult.permissionsNotGranted();
        }

        _logger.i('    BLUETOOTH_CONNECT: granted');
      }

      _logger.i('  ├─ ✅ PASSED: All required permissions granted');
    } catch (e) {
      _logger.e('  └─ ❌ FAILED: Exception checking permissions: $e');
      return BluetoothValidationResult.permissionCheckFailed(e.toString());
    }

    // ═══════════════════════════════════════════════════════════════════════════
    // CHECK 4: Bonded Devices Availability
    // ═══════════════════════════════════════════════════════════════════════════
    _logger.i('  ├─ Check 4/5: Bonded devices availability');

    List<BluetoothDevice> bondedDevices = [];
    try {
      bondedDevices = await _bluetooth.getBondedDevices();

      if (bondedDevices.isEmpty) {
        _logger.w('  └─ ⚠️ WARNING: No bonded Bluetooth devices found');
        return BluetoothValidationResult.noBondedDevices();
      }

      _logger.i(
        '  ├─ ✅ PASSED: Found ${bondedDevices.length} bonded device(s)',
      );
    } catch (e) {
      _logger.e('  └─ ❌ FAILED: Exception getting bonded devices: $e');
      return BluetoothValidationResult.bondedDevicesCheckFailed(e.toString());
    }

    // ═══════════════════════════════════════════════════════════════════════════
    // CHECK 5: Target Printer Bonding (if specified)
    // ═══════════════════════════════════════════════════════════════════════════
    if (targetPrinterAddress != null) {
      _logger.i('  ├─ Check 5/5: Target printer bonding status');

      final targetDevice = bondedDevices.firstWhere(
        (device) => device.address == targetPrinterAddress,
        orElse: () => BluetoothDevice('', ''),
      );

      if (targetDevice.address?.isEmpty ?? true) {
        _logger.w('  └─ ⚠️ FAILED: Target printer not bonded');
        return BluetoothValidationResult.printerNotBonded(targetPrinterAddress);
      }

      _logger.i(
        '  ├─ ✅ PASSED: Target printer is bonded: ${targetDevice.name}',
      );
    }

    // ═══════════════════════════════════════════════════════════════════════════
    // ALL CHECKS PASSED ✅
    // ═══════════════════════════════════════════════════════════════════════════
    _logger.i('  └─ ✅ ALL CHECKS PASSED - Bluetooth environment ready');

    return BluetoothValidationResult.ready(
      bondedDeviceCount: bondedDevices.length,
    );
  }

  /// Request required Bluetooth permissions (Android 12+ only)
  ///
  /// Returns result of permission request.
  /// Throws exception if permanently denied (must open settings).
  Future<PermissionRequestResult> requestPermissions() async {
    _logger.i('📋 [Bluetooth Validation] Requesting permissions');

    try {
      final androidInfo = await DeviceInfoPlugin().androidInfo;
      final sdkInt = androidInfo.version.sdkInt;

      if (sdkInt < 31) {
        _logger.i('  Android < 12: No runtime permissions needed');
        return PermissionRequestResult.granted;
      }

      _logger.i('  Requesting BLUETOOTH_CONNECT...');
      final status = await Permission.bluetoothConnect.request();

      if (status.isGranted) {
        _logger.i('  ✅ Permission granted');
        return PermissionRequestResult.granted;
      } else if (status.isPermanentlyDenied) {
        _logger.e('  ❌ Permission permanently denied');
        return PermissionRequestResult.permanentlyDenied;
      } else {
        _logger.w('  ⚠️ Permission denied');
        return PermissionRequestResult.denied;
      }
    } catch (e) {
      _logger.e('  ❌ Exception requesting permissions: $e');
      return PermissionRequestResult.error;
    }
  }

  /// Get Android SDK version for logging/debugging
  Future<int> getAndroidSdkVersion() async {
    try {
      final androidInfo = await DeviceInfoPlugin().androidInfo;
      return androidInfo.version.sdkInt;
    } catch (e) {
      _logger.w('Failed to get Android SDK version: $e');
      return 0;
    }
  }
}

// ═══════════════════════════════════════════════════════════════════════════
// VALIDATION RESULT DATA CLASS
// ═══════════════════════════════════════════════════════════════════════════

/// Result of Bluetooth validation with detailed failure information
class BluetoothValidationResult {
  final bool isReady;
  final String statusCode;
  final String technicalMessage;
  final String userMessage;
  final String arabicMessage;
  final String actionableGuidance;
  final bool canRequestPermissions;
  final bool canOpenSettings;
  final int? bondedDeviceCount;

  const BluetoothValidationResult({
    required this.isReady,
    required this.statusCode,
    required this.technicalMessage,
    required this.userMessage,
    required this.arabicMessage,
    required this.actionableGuidance,
    this.canRequestPermissions = false,
    this.canOpenSettings = false,
    this.bondedDeviceCount,
  });

  // ═══════════════════════════════════════════════════════════════════════════
  // SUCCESS RESULT
  // ═══════════════════════════════════════════════════════════════════════════

  factory BluetoothValidationResult.ready({required int bondedDeviceCount}) {
    return BluetoothValidationResult(
      isReady: true,
      statusCode: 'READY',
      technicalMessage: 'Bluetooth environment validated successfully',
      userMessage: 'Ready to connect to Bluetooth printers',
      arabicMessage: 'جاهز للاتصال بطابعات البلوتوث',
      actionableGuidance: '',
      bondedDeviceCount: bondedDeviceCount,
    );
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // HARDWARE FAILURES
  // ═══════════════════════════════════════════════════════════════════════════

  factory BluetoothValidationResult.hardwareNotAvailable() {
    return const BluetoothValidationResult(
      isReady: false,
      statusCode: 'HARDWARE_NOT_AVAILABLE',
      technicalMessage: 'Bluetooth hardware not available on this device',
      userMessage: 'This device does not support Bluetooth',
      arabicMessage: 'هذا الجهاز لا يدعم البلوتوث',
      actionableGuidance:
          'جهازك لا يحتوي على Bluetooth. يرجى استخدام طابعة WiFi بدلاً من ذلك.',
    );
  }

  factory BluetoothValidationResult.hardwareCheckFailed(String error) {
    return BluetoothValidationResult(
      isReady: false,
      statusCode: 'HARDWARE_CHECK_FAILED',
      technicalMessage: 'Failed to check Bluetooth hardware: $error',
      userMessage: 'Failed to verify Bluetooth availability',
      arabicMessage: 'فشل التحقق من البلوتوث',
      actionableGuidance: 'حدث خطأ عند فحص البلوتوث. يرجى إعادة تشغيل التطبيق.',
    );
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // STATE FAILURES
  // ═══════════════════════════════════════════════════════════════════════════

  factory BluetoothValidationResult.bluetoothDisabled() {
    return const BluetoothValidationResult(
      isReady: false,
      statusCode: 'BLUETOOTH_DISABLED',
      technicalMessage: 'Bluetooth is turned off',
      userMessage: 'Please enable Bluetooth',
      arabicMessage: 'البلوتوث مغلق',
      actionableGuidance:
          'يرجى تشغيل البلوتوث من إعدادات الجهاز والمحاولة مرة أخرى.',
      canOpenSettings: true,
    );
  }

  factory BluetoothValidationResult.stateCheckFailed(String error) {
    return BluetoothValidationResult(
      isReady: false,
      statusCode: 'STATE_CHECK_FAILED',
      technicalMessage: 'Failed to check Bluetooth state: $error',
      userMessage: 'Cannot determine Bluetooth status',
      arabicMessage: 'لا يمكن تحديد حالة البلوتوث',
      actionableGuidance: 'تأكد من تشغيل البلوتوث وأعد المحاولة.',
    );
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // PERMISSION FAILURES
  // ═══════════════════════════════════════════════════════════════════════════

  factory BluetoothValidationResult.permissionsNotGranted() {
    return const BluetoothValidationResult(
      isReady: false,
      statusCode: 'PERMISSIONS_NOT_GRANTED',
      technicalMessage: 'BLUETOOTH_CONNECT permission not granted',
      userMessage: 'Bluetooth permission required',
      arabicMessage: 'صلاحيات البلوتوث مطلوبة',
      actionableGuidance:
          'يحتاج التطبيق صلاحية الاتصال بالبلوتوث للوصول إلى الطابعات.',
      canRequestPermissions: true,
    );
  }

  factory BluetoothValidationResult.permissionsPermanentlyDenied() {
    return const BluetoothValidationResult(
      isReady: false,
      statusCode: 'PERMISSIONS_PERMANENTLY_DENIED',
      technicalMessage: 'BLUETOOTH_CONNECT permission permanently denied',
      userMessage: 'Bluetooth permission denied permanently',
      arabicMessage: 'تم رفض صلاحيات البلوتوث نهائياً',
      actionableGuidance:
          'يرجى فتح إعدادات التطبيق وتفعيل صلاحية البلوتوث يدوياً.',
      canOpenSettings: true,
    );
  }

  factory BluetoothValidationResult.permissionCheckFailed(String error) {
    return BluetoothValidationResult(
      isReady: false,
      statusCode: 'PERMISSION_CHECK_FAILED',
      technicalMessage: 'Failed to check permissions: $error',
      userMessage: 'Failed to verify permissions',
      arabicMessage: 'فشل التحقق من الصلاحيات',
      actionableGuidance:
          'حدث خطأ عند فحص الصلاحيات. يرجى منح صلاحيات البلوتوث يدوياً من الإعدادات.',
      canOpenSettings: true,
    );
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // DEVICE DISCOVERY FAILURES
  // ═══════════════════════════════════════════════════════════════════════════

  factory BluetoothValidationResult.noBondedDevices() {
    return const BluetoothValidationResult(
      isReady: false,
      statusCode: 'NO_BONDED_DEVICES',
      technicalMessage: 'No bonded Bluetooth devices found',
      userMessage: 'No paired Bluetooth devices',
      arabicMessage: 'لا توجد أجهزة بلوتوث مقترنة',
      actionableGuidance:
          'يرجى إقران طابعة البلوتوث من إعدادات Android أولاً، ثم حاول مرة أخرى.\n\n'
          'الخطوات:\n'
          '1. افتح إعدادات Android\n'
          '2. اذهب إلى Bluetooth\n'
          '3. قم بإقران طابعتك\n'
          '4. ارجع إلى التطبيق',
      canOpenSettings: true,
    );
  }

  factory BluetoothValidationResult.bondedDevicesCheckFailed(String error) {
    return BluetoothValidationResult(
      isReady: false,
      statusCode: 'BONDED_DEVICES_CHECK_FAILED',
      technicalMessage: 'Failed to retrieve bonded devices: $error',
      userMessage: 'Failed to scan for paired devices',
      arabicMessage: 'فشل البحث عن الأجهزة المقترنة',
      actionableGuidance:
          'حدث خطأ عند البحث عن الأجهزة. يرجى التأكد من تفعيل البلوتوث والمحاولة مرة أخرى.',
    );
  }

  factory BluetoothValidationResult.printerNotBonded(String address) {
    return BluetoothValidationResult(
      isReady: false,
      statusCode: 'PRINTER_NOT_BONDED',
      technicalMessage: 'Target printer ($address) is not bonded',
      userMessage: 'Printer is not paired',
      arabicMessage: 'الطابعة غير مقترنة',
      actionableGuidance:
          'الطابعة المطلوبة غير مقترنة في إعدادات Android. يرجى إقرانها أولاً.\n\n'
          'العنوان: $address',
      canOpenSettings: true,
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════
// PERMISSION REQUEST RESULT ENUM
// ═══════════════════════════════════════════════════════════════════════════

enum PermissionRequestResult { granted, denied, permanentlyDenied, error }
