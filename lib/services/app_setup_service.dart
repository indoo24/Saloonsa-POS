import 'package:permission_handler/permission_handler.dart';
import 'package:logger/logger.dart';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:blue_thermal_printer/blue_thermal_printer.dart';

/// Service to manage first-launch setup and recurring validation
///
/// CRITICAL: This service ensures Bluetooth and Location are ALWAYS ready
/// before any printer operations. It follows Android best practices:
/// - Never attempts to enable Bluetooth/Location programmatically
/// - Always guides user to system settings
/// - Validates state on every app launch
class AppSetupService {
  static final AppSetupService _instance = AppSetupService._internal();
  factory AppSetupService() => _instance;
  AppSetupService._internal();

  final Logger _logger = Logger();
  final BlueThermalPrinter _bluetoothPrinter = BlueThermalPrinter.instance;

  // SharedPreferences key for setup completion flag
  static const String _setupCompletedKey = 'app_setup_completed';

  /// Check if first-launch setup has been completed
  Future<bool> isSetupCompleted() async {
    final prefs = await SharedPreferences.getInstance();
    final completed = prefs.getBool(_setupCompletedKey) ?? false;
    _logger.i('Setup completed status: $completed');
    return completed;
  }

  /// Mark setup as completed
  Future<void> markSetupCompleted() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_setupCompletedKey, true);
    _logger.i('✅ Setup marked as completed');
  }

  /// Reset setup (for testing purposes)
  Future<void> resetSetup() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_setupCompletedKey);
    _logger.i('🔄 Setup reset');
  }

  /// Perform complete validation check
  /// Returns ValidationResult with detailed status
  Future<ValidationResult> performValidation() async {
    _logger.i('🔍 Starting comprehensive validation...');

    final androidInfo = await DeviceInfoPlugin().androidInfo;
    final sdkInt = androidInfo.version.sdkInt;

    final result = ValidationResult(
      permissionsGranted: false,
      bluetoothEnabled: false,
      locationEnabled: false,
      missingItems: [],
    );

    // ========================================================================
    // STEP 1: CHECK PERMISSIONS
    // ========================================================================
    final permissionsStatus = await _checkPermissions(sdkInt);
    result.permissionsGranted = permissionsStatus.allGranted;
    result.missingItems.addAll(permissionsStatus.missingItems);

    // ========================================================================
    // STEP 2: CHECK BLUETOOTH STATE
    // ========================================================================
    try {
      final bluetoothAvailable = await _bluetoothPrinter.isAvailable;
      if (bluetoothAvailable != true) {
        _logger.e('❌ Bluetooth not available on device');
        result.missingItems.add(
          MissingItem(
            type: MissingItemType.bluetoothNotSupported,
            title: 'Bluetooth Not Supported',
            message: 'Your device does not support Bluetooth.',
            actionRequired: false,
          ),
        );
      } else {
        final bluetoothOn = await _bluetoothPrinter.isOn;
        result.bluetoothEnabled = bluetoothOn ?? false;

        if (!result.bluetoothEnabled) {
          _logger.w('⚠️ Bluetooth is OFF');
          result.missingItems.add(
            MissingItem(
              type: MissingItemType.bluetoothDisabled,
              title: 'Enable Bluetooth',
              message: 'Bluetooth must be enabled to use printer features.',
              actionRequired: true,
            ),
          );
        } else {
          _logger.i('✅ Bluetooth is ON');
        }
      }
    } catch (e) {
      _logger.e('❌ Failed to check Bluetooth: $e');
      result.missingItems.add(
        MissingItem(
          type: MissingItemType.bluetoothError,
          title: 'Bluetooth Error',
          message: 'Failed to check Bluetooth status: $e',
          actionRequired: false,
        ),
      );
    }

    // ========================================================================
    // STEP 3: CHECK LOCATION STATE (ONLY for Android < 12)
    // ========================================================================
    // CRITICAL: Location is NOT required on Android 12+ for Bluetooth Classic
    // We only scan bonded/paired devices which don't need Location
    if (sdkInt < 31) {
      try {
        final locationStatus = await Permission.location.serviceStatus;
        result.locationEnabled = locationStatus.isEnabled;

        if (!result.locationEnabled) {
          _logger.w('⚠️ Location is OFF (Android < 12 requires this)');
          result.missingItems.add(
            MissingItem(
              type: MissingItemType.locationDisabled,
              title: 'Enable Location',
              message:
                  'Location services must be enabled for Bluetooth scanning on Android 11 and below.',
              actionRequired: true,
            ),
          );
        } else {
          _logger.i('✅ Location is ON');
        }
      } catch (e) {
        _logger.e('❌ Failed to check Location: $e');
        result.missingItems.add(
          MissingItem(
            type: MissingItemType.locationError,
            title: 'Location Error',
            message: 'Failed to check location status: $e',
            actionRequired: false,
          ),
        );
      }
    } else {
      // Android 12+: Location not required, mark as enabled
      _logger.i('✅ Android 12+: Location check skipped (not required)');
      result.locationEnabled = true;
    }

    // ========================================================================
    // SUMMARY
    // ========================================================================
    if (result.isValid) {
      _logger.i('✅ Validation PASSED - All requirements met');
    } else {
      _logger.w(
        '⚠️ Validation FAILED - ${result.missingItems.length} issue(s) found',
      );
    }

    return result;
  }

  /// Check all required permissions based on Android version
  Future<PermissionsStatus> _checkPermissions(int sdkInt) async {
    final status = PermissionsStatus();

    if (sdkInt >= 31) {
      // ======================================================================
      // Android 12+ (API 31+): Only Bluetooth permissions required
      // ======================================================================
      // CRITICAL: Location permission is NOT required on Android 12+
      // We only scan bonded/paired Bluetooth Classic devices
      _logger.i('🔍 Android 12+: Checking Bluetooth permissions only');

      final bluetoothConnect = await Permission.bluetoothConnect.status;
      final bluetoothScan = await Permission.bluetoothScan.status;

      status.bluetoothConnectGranted = bluetoothConnect.isGranted;
      status.bluetoothScanGranted = bluetoothScan.isGranted;
      status.locationGranted = true; // Not required on Android 12+

      if (!bluetoothConnect.isGranted) {
        status.missingItems.add(
          MissingItem(
            type: MissingItemType.permissionBluetoothConnect,
            title: 'Nearby Devices Permission Required',
            message: 'Required to connect to paired Bluetooth printers.',
            actionRequired: true,
          ),
        );
      }

      if (!bluetoothScan.isGranted) {
        status.missingItems.add(
          MissingItem(
            type: MissingItemType.permissionBluetoothScan,
            title: 'Nearby Devices Permission Required',
            message: 'Required to discover paired Bluetooth printers.',
            actionRequired: true,
          ),
        );
      }

      _logger.i(
        'Bluetooth Connect: ${bluetoothConnect.isGranted}, '
        'Bluetooth Scan: ${bluetoothScan.isGranted}',
      );
    } else {
      // ======================================================================
      // Android 11 and below (API < 31): Location permission required
      // ======================================================================
      _logger.i('🔍 Android < 12: Checking Location permission');

      final location = await Permission.location.status;

      // Bluetooth permissions are auto-granted on older Android
      status.bluetoothConnectGranted = true;
      status.bluetoothScanGranted = true;
      status.locationGranted = location.isGranted;

      if (!location.isGranted) {
        status.missingItems.add(
          MissingItem(
            type: MissingItemType.permissionLocation,
            title: 'Location Permission Required',
            message:
                'Required for Bluetooth device discovery on Android 11 and below.',
            actionRequired: true,
          ),
        );
      }

      _logger.i('Location: ${location.isGranted}');
    }

    return status;
  }

  /// Request all required permissions based on Android version
  /// Returns true if all permissions were granted
  Future<PermissionRequestResult> requestPermissions() async {
    _logger.i('📋 Requesting required permissions...');

    final androidInfo = await DeviceInfoPlugin().androidInfo;
    final sdkInt = androidInfo.version.sdkInt;

    final result = PermissionRequestResult();

    if (sdkInt < 31) {
      // ======================================================================
      // Android 11 and below: Request Location permission only
      // ======================================================================
      _logger.i('📋 Android < 12: Requesting Location permission');

      final locationStatus = await Permission.location.request();

      result.bluetoothConnectGranted = true; // Auto-granted
      result.bluetoothScanGranted = true; // Auto-granted
      result.locationGranted = locationStatus.isGranted;
      result.locationDenied = locationStatus.isPermanentlyDenied;

      result.allGranted = result.locationGranted;

      if (result.allGranted) {
        _logger.i('✅ Location permission granted');
      } else {
        _logger.w('⚠️ Location permission denied');
      }
    } else {
      // ======================================================================
      // Android 12+: Request Bluetooth permissions only (NO Location)
      // ======================================================================
      _logger.i('📋 Android 12+: Requesting Bluetooth permissions');

      final permissions = [
        Permission.bluetoothConnect,
        Permission.bluetoothScan,
      ];

      final statuses = await permissions.request();

      result.bluetoothConnectGranted =
          statuses[Permission.bluetoothConnect]?.isGranted ?? false;
      result.bluetoothScanGranted =
          statuses[Permission.bluetoothScan]?.isGranted ?? false;
      result.locationGranted = true; // Not required on Android 12+

      result.bluetoothConnectDenied =
          statuses[Permission.bluetoothConnect]?.isPermanentlyDenied ?? false;
      result.bluetoothScanDenied =
          statuses[Permission.bluetoothScan]?.isPermanentlyDenied ?? false;
      result.locationDenied = false; // Not requested

      result.allGranted =
          result.bluetoothConnectGranted && result.bluetoothScanGranted;

      if (result.allGranted) {
        _logger.i('✅ All Bluetooth permissions granted');
      } else {
        _logger.w('⚠️ Some Bluetooth permissions were not granted');
      }
    }

    return result;
  }
}

// ============================================================================
// DATA CLASSES
// ============================================================================

/// Result of validation check
class ValidationResult {
  bool permissionsGranted;
  bool bluetoothEnabled;
  bool locationEnabled;
  List<MissingItem> missingItems;

  ValidationResult({
    required this.permissionsGranted,
    required this.bluetoothEnabled,
    required this.locationEnabled,
    required this.missingItems,
  });

  bool get isValid => missingItems.isEmpty;
}

/// Status of permissions check
class PermissionsStatus {
  bool bluetoothConnectGranted = false;
  bool bluetoothScanGranted = false;
  bool locationGranted = false;
  List<MissingItem> missingItems = [];

  /// All granted means different things based on Android version:
  /// - Android 12+: Bluetooth Connect + Scan (Location not required)
  /// - Android < 12: Location (Bluetooth auto-granted)
  bool get allGranted =>
      bluetoothConnectGranted && bluetoothScanGranted && locationGranted;
}

/// Result of permission request
class PermissionRequestResult {
  bool bluetoothConnectGranted = false;
  bool bluetoothScanGranted = false;
  bool locationGranted = false;

  bool bluetoothConnectDenied = false;
  bool bluetoothScanDenied = false;
  bool locationDenied = false;

  bool allGranted = false;

  bool get hasAnyPermanentlyDenied =>
      bluetoothConnectDenied || bluetoothScanDenied || locationDenied;
}

/// Represents a missing requirement
class MissingItem {
  final MissingItemType type;
  final String title;
  final String message;
  final bool actionRequired;

  MissingItem({
    required this.type,
    required this.title,
    required this.message,
    required this.actionRequired,
  });
}

/// Types of missing requirements
enum MissingItemType {
  permissionBluetoothConnect,
  permissionBluetoothScan,
  permissionLocation,
  bluetoothDisabled,
  bluetoothNotSupported,
  bluetoothError,
  locationDisabled,
  locationError,
}
