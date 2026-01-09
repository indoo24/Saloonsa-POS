import 'dart:async';
import 'dart:io';
import 'package:blue_thermal_printer/blue_thermal_printer.dart';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:logger/logger.dart';
import 'package:permission_handler/permission_handler.dart';
import '../screens/casher/models/printer_device.dart';
import '../helpers/sunmi_printer_detector.dart';

/// Unified Printer Discovery Service
///
/// This service implements a comprehensive, user-proof printer discovery flow that:
/// 1. ALWAYS shows built-in printers (Sunmi) immediately if device supports them
/// 2. ALWAYS shows ALL bonded (paired) Bluetooth Classic devices
/// 3. Optionally runs a time-limited discovery scan for NEW devices
/// 4. Handles Android version-specific permissions gracefully
///
/// KEY PRINCIPLES:
/// - NEVER rely on Bluetooth discovery scan alone
/// - ALWAYS display bonded devices even if scan fails
/// - NEVER show "No printers found" when bonded devices exist
/// - Gracefully handle denied permissions
///
/// COMPATIBILITY: Android 8-14+
class UnifiedPrinterDiscoveryService {
  static final UnifiedPrinterDiscoveryService _instance =
      UnifiedPrinterDiscoveryService._internal();
  factory UnifiedPrinterDiscoveryService() => _instance;
  UnifiedPrinterDiscoveryService._internal();

  final Logger _logger = Logger();
  final BlueThermalPrinter _bluetooth = BlueThermalPrinter.instance;
  final DeviceInfoPlugin _deviceInfo = DeviceInfoPlugin();

  // Discovery scan timeout (5 seconds max as per requirements)
  static const Duration _discoveryScanTimeout = Duration(seconds: 5);

  // Bonded device retrieval timeout (should be instant, but safety limit)
  static const Duration _bondedRetrievalTimeout = Duration(seconds: 3);

  // ============================================================================
  // MAIN DISCOVERY METHOD
  // ============================================================================

  /// Discover ALL available printers using unified flow
  ///
  /// This method combines:
  /// 1. Built-in printers (Sunmi InnerPrinter) - shown immediately
  /// 2. Bonded Bluetooth Classic devices - MANDATORY, always shown
  /// 3. Optional discovery scan for new unpaired devices
  ///
  /// Returns [UnifiedDiscoveryResult] containing all discovered printers
  /// organized by source type
  ///
  /// PRODUCTION FIX: ALWAYS show ALL bonded devices regardless of filtering
  Future<UnifiedDiscoveryResult> discoverAllPrinters({
    bool includeDiscoveryScan = true,
    bool filterThermalOnly =
        false, // ALWAYS false - never filter bonded devices
  }) async {
    _logger.i(
      '🔍 [UnifiedDiscovery] Starting comprehensive printer discovery...',
    );

    // Log device info for diagnostics
    try {
      if (Platform.isAndroid) {
        final androidInfo = await _deviceInfo.androidInfo;
        _logger.i(
          '📱 Device: ${androidInfo.manufacturer} ${androidInfo.model}',
        );
        _logger.i(
          '📱 Android: ${androidInfo.version.release} (SDK ${androidInfo.version.sdkInt})',
        );
        _logger.i('📱 ABI: ${androidInfo.supportedAbis.join(', ')}');
      }
    } catch (e) {
      _logger.w('⚠️ Failed to log device info: $e');
    }

    final result = UnifiedDiscoveryResult();

    // ========================================================================
    // STEP 1: Check built-in printers (Sunmi InnerPrinter)
    // Always runs first - no permissions needed
    // ========================================================================
    try {
      final builtInPrinters = await _discoverBuiltInPrinters();
      result.builtInPrinters.addAll(builtInPrinters);
      _logger.i('✅ Found ${builtInPrinters.length} built-in printer(s)');
    } catch (e) {
      _logger.w('⚠️ Failed to detect built-in printers: $e');
      result.errors.add('فشل اكتشاف الطابعة المدمجة: $e');
    }

    // ========================================================================
    // STEP 2: Check and request permissions
    // ========================================================================
    final permissionResult = await _checkAndRequestPermissions();
    result.permissionsGranted = permissionResult.granted;

    if (!permissionResult.granted) {
      _logger.w('⚠️ Bluetooth permissions not fully granted');
      result.errors.add(permissionResult.message);
      result.permissionMessage = permissionResult.message;

      // Even without permissions, return what we have (built-in printers)
      // User can still use built-in printers if available
      if (result.builtInPrinters.isNotEmpty) {
        _logger.i('ℹ️ Returning built-in printers despite permission issues');
        return result;
      }

      // No printers available without permissions
      return result;
    }

    // ========================================================================
    // STEP 3: Check Bluetooth state
    // ========================================================================
    final bluetoothState = await _checkBluetoothState();
    if (!bluetoothState.isEnabled) {
      _logger.w('⚠️ Bluetooth is not enabled');
      result.errors.add(bluetoothState.message);
      result.bluetoothEnabled = false;

      // Return built-in printers if available
      if (result.builtInPrinters.isNotEmpty) {
        _logger.i('ℹ️ Returning built-in printers - Bluetooth disabled');
        return result;
      }
      return result;
    }
    result.bluetoothEnabled = true;

    // ========================================================================
    // STEP 4: Get ALL bonded (paired) Bluetooth Classic devices
    // THIS IS MANDATORY - We ALWAYS show bonded devices
    // PRODUCTION FIX: NEVER filter bonded devices - show ALL of them
    // ========================================================================
    try {
      // CRITICAL: Always pass filterThermalOnly = false for bonded devices
      // We MUST show ALL bonded devices regardless of name patterns
      final bondedPrinters = await _discoverBondedDevices(
        filterThermalOnly: false, // ALWAYS false - never filter bonded devices
      );
      result.pairedPrinters.addAll(bondedPrinters);

      // Log each bonded device clearly
      _logger.i('✅ Found ${bondedPrinters.length} bonded Bluetooth device(s):');
      for (final printer in bondedPrinters) {
        _logger.i('   📱 ${printer.name} (${printer.address})');
      }

      if (bondedPrinters.isEmpty) {
        _logger.w('⚠️ NO bonded Bluetooth devices found');
        _logger.w(
          '💡 User must pair printer in Android Bluetooth Settings first',
        );
      }
    } catch (e) {
      _logger.e('❌ CRITICAL: Failed to get bonded devices: $e');
      result.errors.add('فشل الحصول على الأجهزة المقترنة: $e');
      // Continue anyway - we might still find devices via discovery
    }

    // ========================================================================
    // STEP 5: Optional discovery scan for NEW unpaired devices
    // Time-limited (max 5 seconds) - used only to find new printers
    // NEVER blocks UI or printing
    // ========================================================================
    if (includeDiscoveryScan) {
      try {
        final discoveredPrinters = await _runDiscoveryScan();

        // Filter out already bonded devices
        final newPrinters = discoveredPrinters.where((discovered) {
          return !result.pairedPrinters.any(
            (bonded) => bonded.address == discovered.address,
          );
        }).toList();

        result.discoveredPrinters.addAll(newPrinters);
        _logger.i('✅ Found ${newPrinters.length} new unpaired device(s)');
      } catch (e) {
        _logger.w('⚠️ Discovery scan failed or timed out: $e');
        // This is NOT critical - bonded devices are more important
        // Don't add to errors - this is expected behavior in some cases
      }
    }

    _logger.i('═══════════════════════════════════════════════════════');
    _logger.i('📊 [UnifiedDiscovery] Discovery Complete');
    _logger.i('═══════════════════════════════════════════════════════');
    _logger.i('   Built-in:   ${result.builtInPrinters.length}');
    _logger.i('   Paired:     ${result.pairedPrinters.length}');
    _logger.i('   Discovered: ${result.discoveredPrinters.length}');
    _logger.i('   ─────────────────────────────────────────────────────');
    _logger.i('   TOTAL:      ${result.allPrinters.length}');
    _logger.i(
      '   Permissions: ${result.permissionsGranted ? "✅ Granted" : "❌ Denied"}',
    );
    _logger.i(
      '   Bluetooth:   ${result.bluetoothEnabled ? "✅ Enabled" : "❌ Disabled"}',
    );
    _logger.i('═══════════════════════════════════════════════════════');

    if (result.allPrinters.isEmpty) {
      _logger.w('⚠️ NO PRINTERS FOUND');
      if (!result.permissionsGranted) {
        _logger.w('   Reason: Missing Bluetooth permissions');
      } else if (!result.bluetoothEnabled) {
        _logger.w('   Reason: Bluetooth is disabled');
      } else {
        _logger.w('   Reason: No devices paired in Android Settings');
        _logger.w('   Action: User must pair printer via:');
        _logger.w('           Settings → Bluetooth → Pair new device');
      }
    } else if (result.pairedPrinters.isEmpty &&
        result.discoveredPrinters.isEmpty) {
      _logger.i('ℹ️ Only built-in printers available (Sunmi device)');
    } else {
      _logger.i('✅ SUCCESS: ${result.allPrinters.length} printer(s) available');
    }

    return result;
  }

  // ============================================================================
  // BUILT-IN PRINTER DETECTION
  // ============================================================================

  /// Detect built-in printers (Sunmi InnerPrinter)
  /// Always show immediately if device supports them
  Future<List<PrinterDevice>> _discoverBuiltInPrinters() async {
    final printers = <PrinterDevice>[];

    try {
      // Check if device is Sunmi
      final isSunmi = await SunmiPrinterDetector.isSunmiPrinter();

      if (isSunmi) {
        _logger.i('✅ Sunmi device detected - adding built-in printer');

        // Get device model for display name
        String modelName = 'Sunmi InnerPrinter';
        if (Platform.isAndroid) {
          final androidInfo = await _deviceInfo.androidInfo;
          modelName = 'Sunmi ${androidInfo.model} InnerPrinter';
        }

        printers.add(
          PrinterDevice(
            id: 'builtin_sunmi_inner',
            name: modelName,
            address: 'inner_printer',
            type: PrinterConnectionType
                .bluetooth, // Treat as Bluetooth for connection logic
            isConnected: false,
            sourceType: PrinterSourceType.builtIn,
          ),
        );
      }
    } catch (e) {
      _logger.w('⚠️ Failed to detect Sunmi device: $e');
    }

    return printers;
  }

  // ============================================================================
  // PERMISSION HANDLING
  // ============================================================================

  /// Check and request Bluetooth permissions based on Android version
  ///
  /// Android < 12: BLUETOOTH + BLUETOOTH_ADMIN + LOCATION
  /// Android 12+: BLUETOOTH_SCAN + BLUETOOTH_CONNECT
  ///
  /// Gracefully handles denied permissions
  Future<PermissionCheckResult> _checkAndRequestPermissions() async {
    _logger.i('🔐 Checking Bluetooth permissions...');

    try {
      // Get Android version
      int sdkInt = 31; // Default to Android 12+ behavior
      if (Platform.isAndroid) {
        final androidInfo = await _deviceInfo.androidInfo;
        sdkInt = androidInfo.version.sdkInt;
      }

      _logger.i('📱 Android SDK version: $sdkInt');

      if (sdkInt >= 31) {
        // Android 12+ (API 31+)
        return await _checkAndroid12PlusPermissions();
      } else {
        // Android 11 and below (API 30-)
        return await _checkLegacyPermissions();
      }
    } catch (e) {
      _logger.e('❌ Permission check failed: $e');
      return PermissionCheckResult(
        granted: false,
        message: 'فشل التحقق من الصلاحيات: $e',
      );
    }
  }

  /// Check permissions for Android 12+ (API 31+)
  ///
  /// PRODUCTION FIX: BLUETOOTH_SCAN is REQUIRED for getBondedDevices() on some devices
  /// Even though documentation says it's only for discovery, some OEMs require it
  Future<PermissionCheckResult> _checkAndroid12PlusPermissions() async {
    _logger.i('🔐 Checking Android 12+ permissions...');

    // Check BLUETOOTH_CONNECT (required for bonded devices)
    var connectStatus = await Permission.bluetoothConnect.status;

    if (!connectStatus.isGranted) {
      _logger.i('📋 Requesting BLUETOOTH_CONNECT...');
      connectStatus = await Permission.bluetoothConnect.request();
    }

    if (!connectStatus.isGranted) {
      if (connectStatus.isPermanentlyDenied) {
        return PermissionCheckResult(
          granted: false,
          message:
              'صلاحية الاتصال بالبلوتوث مرفوضة نهائياً. يرجى تفعيلها من إعدادات التطبيق.',
          permanentlyDenied: true,
        );
      }
      return PermissionCheckResult(
        granted: false,
        message: 'صلاحية الاتصال بالبلوتوث مطلوبة للوصول إلى الطابعات.',
      );
    }

    // Check BLUETOOTH_SCAN (REQUIRED despite what docs say)
    // PRODUCTION FIX: Some Android 12+ devices (especially Samsung, Xiaomi)
    // require BLUETOOTH_SCAN even for getBondedDevices()
    var scanStatus = await Permission.bluetoothScan.status;

    if (!scanStatus.isGranted) {
      _logger.i(
        '📋 Requesting BLUETOOTH_SCAN (required for bonded devices)...',
      );
      scanStatus = await Permission.bluetoothScan.request();
    }

    // CRITICAL: If BLUETOOTH_SCAN is denied, we may not see bonded devices
    if (!scanStatus.isGranted) {
      _logger.w('⚠️ BLUETOOTH_SCAN denied - bonded devices may not be visible');
      _logger.w('⚠️ This is a CRITICAL permission on Android 12+');

      if (scanStatus.isPermanentlyDenied) {
        return PermissionCheckResult(
          granted: false,
          message:
              'صلاحية البحث عن البلوتوث مرفوضة نهائياً. مطلوبة لعرض الطابعات المقترنة.',
          permanentlyDenied: true,
        );
      }

      return PermissionCheckResult(
        granted: false,
        message: 'صلاحية البحث عن البلوتوث مطلوبة لعرض الطابعات المقترنة.',
      );
    }

    _logger.i('✅ Android 12+ permissions granted (CONNECT + SCAN)');
    return PermissionCheckResult(granted: true, message: '');
  }

  /// Check permissions for Android 11 and below (API 30-)
  Future<PermissionCheckResult> _checkLegacyPermissions() async {
    _logger.i('🔐 Checking legacy Android permissions...');

    // On Android < 12, Bluetooth permissions are usually auto-granted
    // But Location permission is required for Bluetooth scanning

    var locationStatus = await Permission.locationWhenInUse.status;

    if (!locationStatus.isGranted) {
      _logger.i('📋 Requesting location permission for Bluetooth...');
      locationStatus = await Permission.locationWhenInUse.request();
    }

    if (!locationStatus.isGranted) {
      if (locationStatus.isPermanentlyDenied) {
        return PermissionCheckResult(
          granted: false,
          message:
              'صلاحية الموقع مطلوبة للبحث عن أجهزة البلوتوث. يرجى تفعيلها من إعدادات التطبيق.',
          permanentlyDenied: true,
        );
      }
      return PermissionCheckResult(
        granted: false,
        message: 'صلاحية الموقع مطلوبة للبحث عن أجهزة البلوتوث.',
      );
    }

    _logger.i('✅ Legacy permissions granted');
    return PermissionCheckResult(granted: true, message: '');
  }

  // ============================================================================
  // BLUETOOTH STATE CHECK
  // ============================================================================

  /// Check if Bluetooth is enabled
  Future<BluetoothStateResult> _checkBluetoothState() async {
    _logger.i('📡 Checking Bluetooth state...');

    try {
      // Check if Bluetooth hardware is available
      final isAvailable = await _bluetooth.isAvailable ?? false;

      if (!isAvailable) {
        return BluetoothStateResult(
          isEnabled: false,
          message: 'هذا الجهاز لا يدعم البلوتوث.',
        );
      }

      // Check if Bluetooth is turned on
      final isOn = await _bluetooth.isOn ?? false;

      if (!isOn) {
        return BluetoothStateResult(
          isEnabled: false,
          message: 'البلوتوث مغلق. يرجى تشغيل البلوتوث من الإعدادات.',
        );
      }

      _logger.i('✅ Bluetooth is enabled');
      return BluetoothStateResult(isEnabled: true, message: '');
    } catch (e) {
      _logger.e('❌ Failed to check Bluetooth state: $e');
      return BluetoothStateResult(
        isEnabled: false,
        message: 'فشل التحقق من حالة البلوتوث: $e',
      );
    }
  }

  // ============================================================================
  // BONDED DEVICES RETRIEVAL (MANDATORY)
  // ============================================================================

  /// Get ALL bonded (paired) Bluetooth Classic devices
  ///
  /// CRITICAL: This is the MANDATORY source of printers
  /// - Include ALL bonded devices (NO filtering)
  /// - Display them immediately even if scan fails
  /// - User can print directly to any bonded printer
  ///
  /// PRODUCTION FIX: NEVER filter bonded devices - always show ALL
  Future<List<PrinterDevice>> _discoverBondedDevices({
    bool filterThermalOnly = false, // Ignored - we NEVER filter bonded devices
  }) async {
    _logger.i('🔍 Retrieving ALL bonded Bluetooth Classic devices...');

    try {
      // Wrap in timeout for safety (should be instant, but can hang on some devices)
      final bondedDevices = await Future.any([
        _bluetooth.getBondedDevices(),
        Future.delayed(
          _bondedRetrievalTimeout,
          () => throw TimeoutException(
            'Bonded device retrieval timed out',
            _bondedRetrievalTimeout,
          ),
        ),
      ]);

      _logger.i(
        '📱 Raw getBondedDevices() returned: ${bondedDevices.length} device(s)',
      );

      if (bondedDevices.isEmpty) {
        _logger.w('⚠️ NO bonded Bluetooth devices found');
        _logger.w('💡 User must pair printer in Android Settings:');
        _logger.w('   1. Open Android Settings → Bluetooth');
        _logger.w('   2. Turn on printer');
        _logger.w('   3. Tap "Pair new device"');
        _logger.w('   4. Select printer from list');
        _logger.w('   5. Return to app and scan again');
        return [];
      }

      // Convert ALL bonded devices to PrinterDevice format
      // PRODUCTION FIX: NO filtering - show EVERY bonded device
      final allDevices = bondedDevices.map((device) {
        return PrinterDevice(
          id: 'bt_classic_${device.address}',
          name: device.name ?? 'Unknown Device (${device.address})',
          address: device.address,
          type: PrinterConnectionType.bluetooth,
          isConnected: false,
          sourceType: PrinterSourceType.paired, // Mark as PAIRED
        );
      }).toList();

      // Log ALL devices clearly
      _logger.i('📱 Bonded Bluetooth devices (ALL will be shown):');
      for (final device in allDevices) {
        _logger.i('   ✅ ${device.name} (${device.address}) [PAIRED]');
      }

      // CRITICAL: Return ALL bonded devices without any filtering
      // This ensures printers are ALWAYS visible if paired in Android Settings
      _logger.i(
        '✅ Returning ALL ${allDevices.length} bonded device(s) without filtering',
      );
      return allDevices;
    } on TimeoutException catch (e) {
      _logger.e('❌ CRITICAL: Timeout retrieving bonded devices: $e');
      _logger.e(
        '   This should never happen - getBondedDevices() should be instant',
      );
      rethrow;
    } catch (e) {
      _logger.e('❌ CRITICAL: Failed to retrieve bonded devices: $e');
      _logger.e('   Possible causes:');
      _logger.e('   - Missing BLUETOOTH_SCAN permission (Android 12+)');
      _logger.e('   - Missing BLUETOOTH_CONNECT permission (Android 12+)');
      _logger.e('   - Bluetooth is disabled');
      _logger.e('   - Platform exception from native code');
      rethrow;
    }
  }

  // ============================================================================
  // DISCOVERY SCAN (OPTIONAL)
  // ============================================================================

  /// Run a time-limited discovery scan for NEW unpaired devices
  ///
  /// - Maximum 5 seconds
  /// - Used only to find NEW printers not yet paired
  /// - Never blocks UI or printing
  Future<List<PrinterDevice>> _runDiscoveryScan() async {
    _logger.i('🔍 Starting discovery scan (max $_discoveryScanTimeout)...');

    StreamSubscription? subscription;

    try {
      // Start discovery
      final isDiscovering = await _bluetooth.isOn ?? false;

      if (!isDiscovering) {
        _logger.w('⚠️ Bluetooth not enabled - skipping discovery');
        return [];
      }

      // Listen for discovered devices with timeout
      subscription = _bluetooth.onStateChanged().listen((state) {
        // Handle state changes during discovery
        _logger.d('Bluetooth state: $state');
      });

      // Note: blue_thermal_printer doesn't have a direct discovery API
      // This is a placeholder for future BLE discovery implementation
      // For now, we rely on bonded devices which is more reliable

      _logger.i(
        'ℹ️ Discovery scan not implemented in current Bluetooth library',
      );
      _logger.i('ℹ️ Users should pair printers via Android Settings');

      return [];
    } catch (e) {
      _logger.e('❌ Discovery scan failed: $e');
      return [];
    } finally {
      await subscription?.cancel();
    }
  }

  // ============================================================================
  // UTILITY METHODS
  // ============================================================================

  /// Check if Bluetooth is currently enabled
  Future<bool> isBluetoothEnabled() async {
    try {
      return await _bluetooth.isOn ?? false;
    } catch (e) {
      _logger.e('Failed to check Bluetooth state: $e');
      return false;
    }
  }

  /// Get count of bonded devices (for quick check)
  Future<int> getBondedDeviceCount() async {
    try {
      final devices = await _bluetooth.getBondedDevices();
      return devices.length;
    } catch (e) {
      _logger.e('Failed to get bonded device count: $e');
      return 0;
    }
  }
}

// ============================================================================
// RESULT CLASSES
// ============================================================================

/// Result of unified printer discovery
class UnifiedDiscoveryResult {
  /// Built-in printers (Sunmi InnerPrinter)
  final List<PrinterDevice> builtInPrinters = [];

  /// Paired/bonded Bluetooth Classic devices
  final List<PrinterDevice> pairedPrinters = [];

  /// Newly discovered devices (not yet paired)
  final List<PrinterDevice> discoveredPrinters = [];

  /// Any errors that occurred during discovery
  final List<String> errors = [];

  /// Whether Bluetooth permissions were granted
  bool permissionsGranted = false;

  /// Permission-related message for user
  String? permissionMessage;

  /// Whether Bluetooth is enabled
  bool bluetoothEnabled = false;

  /// Get ALL printers in order of priority:
  /// 1. Built-in (most reliable)
  /// 2. Paired (ready to use)
  /// 3. Discovered (needs pairing)
  List<PrinterDevice> get allPrinters {
    return [...builtInPrinters, ...pairedPrinters, ...discoveredPrinters];
  }

  /// Check if any printers were found
  bool get hasPrinters => allPrinters.isNotEmpty;

  /// Check if we have any bonded printers (which can print directly)
  bool get hasBondedPrinters =>
      builtInPrinters.isNotEmpty || pairedPrinters.isNotEmpty;

  /// Check if there were any errors
  bool get hasErrors => errors.isNotEmpty;

  /// Get a summary message
  String get summaryMessage {
    if (hasPrinters) {
      final total = allPrinters.length;
      final bonded = builtInPrinters.length + pairedPrinters.length;

      if (bonded > 0) {
        return 'تم العثور على $total طابعة ($bonded جاهزة للطباعة)';
      } else {
        return 'تم العثور على $total طابعة (يجب إقرانها أولاً)';
      }
    }

    if (!permissionsGranted) {
      return permissionMessage ?? 'صلاحيات البلوتوث مطلوبة للوصول إلى الطابعات';
    }

    if (!bluetoothEnabled) {
      return 'البلوتوث مغلق. يرجى تشغيل البلوتوث من الإعدادات.';
    }

    return 'لم يتم العثور على طابعات مقترنة.\n'
        'يرجى إقران الطابعة في إعدادات البلوتوث أولاً:\n'
        '1. إعدادات → بلوتوث\n'
        '2. البحث عن أجهزة جديدة\n'
        '3. اختر طابعتك وأدخل PIN (0000 أو 1234)';
  }
}

/// Result of permission check
class PermissionCheckResult {
  final bool granted;
  final String message;
  final bool permanentlyDenied;

  PermissionCheckResult({
    required this.granted,
    required this.message,
    this.permanentlyDenied = false,
  });
}

/// Result of Bluetooth state check
class BluetoothStateResult {
  final bool isEnabled;
  final String message;

  BluetoothStateResult({required this.isEnabled, required this.message});
}
