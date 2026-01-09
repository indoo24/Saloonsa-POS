import 'package:permission_handler/permission_handler.dart';
import 'package:logger/logger.dart';
import 'package:device_info_plus/device_info_plus.dart';

/// Service to handle runtime permissions for Bluetooth Classic thermal printers
///
/// IMPORTANT: This is optimized for Bluetooth Classic (SPP/RFCOMM), NOT BLE
///
/// Permission Requirements by Android Version:
/// - Android 8-11 (API 26-30): Bluetooth permissions are auto-granted at install
/// - Android 12+ (API 31+): Runtime BLUETOOTH_CONNECT permission required
///
/// KEY INSIGHT: For bonded Bluetooth Classic devices, we do NOT need:
/// - BLUETOOTH_SCAN (only for BLE discovery)
/// - Location (only for BLE scanning on Android < 12)
class PermissionService {
  static final PermissionService _instance = PermissionService._internal();
  factory PermissionService() => _instance;
  PermissionService._internal();

  final Logger _logger = Logger();

  /// Request Bluetooth Classic permissions (Android version-aware)
  ///
  /// Android 8-11: No runtime permissions needed (auto-granted)
  /// Android 12+: Request BLUETOOTH_CONNECT for bonded device access
  ///
  /// Returns PermissionResult indicating grant status
  Future<PermissionResult> requestBluetoothPermissions() async {
    _logger.i('📋 Requesting Bluetooth Classic permissions...');

    // Get Android version
    final androidInfo = await DeviceInfoPlugin().androidInfo;
    final sdkInt = androidInfo.version.sdkInt;

    _logger.i('📱 Android SDK version: $sdkInt');

    // For Android 11 and below, Bluetooth permissions are auto-granted
    if (sdkInt < 31) {
      _logger.i('✅ Android < 12: Bluetooth permissions auto-granted');
      return PermissionResult.granted;
    }

    // For Android 12+, request BLUETOOTH_CONNECT
    _logger.i('📱 Android 12+: Requesting BLUETOOTH_CONNECT...');

    final status = await Permission.bluetoothConnect.request();

    _logger.i('Permission status: $status');

    if (status.isGranted) {
      _logger.i('✅ BLUETOOTH_CONNECT granted');
      return PermissionResult.granted;
    }

    if (status.isPermanentlyDenied) {
      _logger.w('⚠️ BLUETOOTH_CONNECT permanently denied');
      return PermissionResult.permanentlyDenied;
    }

    _logger.w('❌ BLUETOOTH_CONNECT denied');
    return PermissionResult.denied;
  }

  /// Check if Bluetooth Classic permissions are already granted
  /// Returns true if all necessary permissions are granted
  Future<bool> checkBluetoothPermissions() async {
    _logger.i('🔍 Checking Bluetooth Classic permissions...');

    // Get Android version
    final androidInfo = await DeviceInfoPlugin().androidInfo;
    final sdkInt = androidInfo.version.sdkInt;

    // For Android 11 and below, permissions are auto-granted
    if (sdkInt < 31) {
      _logger.i('✅ Android < 12: Permissions auto-granted');
      return true;
    }

    // For Android 12+, check BLUETOOTH_CONNECT
    final connectStatus = await Permission.bluetoothConnect.status;

    _logger.i('BLUETOOTH_CONNECT status: $connectStatus');

    if (connectStatus.isGranted) {
      _logger.i('✅ BLUETOOTH_CONNECT is granted');
      return true;
    }

    _logger.w('⚠️ BLUETOOTH_CONNECT not granted');
    return false;
  }

  /// Check if any permission is permanently denied
  Future<bool> isAnyPermissionPermanentlyDenied() async {
    // Get Android version
    final androidInfo = await DeviceInfoPlugin().androidInfo;
    final sdkInt = androidInfo.version.sdkInt;

    // For Android 11 and below, no runtime permissions
    if (sdkInt < 31) {
      return false;
    }

    // For Android 12+, check BLUETOOTH_CONNECT
    final connectStatus = await Permission.bluetoothConnect.status;
    return connectStatus.isPermanentlyDenied;
  }

  /// Open app settings so user can manually grant permissions
  Future<void> openSettings() async {
    _logger.i('🔧 Opening app settings...');
    await openAppSettings();
  }
}

/// Result of permission request
enum PermissionResult { granted, denied, permanentlyDenied }
