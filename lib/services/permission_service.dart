import 'package:permission_handler/permission_handler.dart';
import 'package:logger/logger.dart';

/// Service to handle runtime permissions for Bluetooth and Location
class PermissionService {
  static final PermissionService _instance = PermissionService._internal();
  factory PermissionService() => _instance;
  PermissionService._internal();

  final Logger _logger = Logger();

  /// Request all necessary permissions for Bluetooth scanning
  /// Returns true if all permissions are granted
  Future<PermissionResult> requestBluetoothPermissions() async {
    _logger.i('Requesting Bluetooth permissions...');

    // Check Android version to determine which permissions to request
    final bluetoothScan = Permission.bluetoothScan;
    final bluetoothConnect = Permission.bluetoothConnect;
    final location = Permission.location;

    // Request permissions
    Map<Permission, PermissionStatus> statuses = await [
      bluetoothScan,
      bluetoothConnect,
      location,
    ].request();

    _logger.i('Permission statuses:');
    _logger.i('  Bluetooth Scan: ${statuses[bluetoothScan]}');
    _logger.i('  Bluetooth Connect: ${statuses[bluetoothConnect]}');
    _logger.i('  Location: ${statuses[location]}');

    // Check if all permissions are granted
    final allGranted = statuses.values.every((status) => status.isGranted);

    if (allGranted) {
      _logger.i('✅ All Bluetooth permissions granted');
      return PermissionResult.granted;
    }

    // Check if any permission is permanently denied
    final anyPermanentlyDenied = statuses.values.any((status) => status.isPermanentlyDenied);

    if (anyPermanentlyDenied) {
      _logger.w('⚠️ Some permissions are permanently denied');
      return PermissionResult.permanentlyDenied;
    }

    _logger.w('❌ Some permissions were denied');
    return PermissionResult.denied;
  }

  /// Check if Bluetooth permissions are already granted
  /// Returns true if all necessary permissions are granted
  Future<bool> checkBluetoothPermissions() async {
    _logger.i('Checking Bluetooth permissions...');

    final bluetoothScan = await Permission.bluetoothScan.status;
    final bluetoothConnect = await Permission.bluetoothConnect.status;
    final location = await Permission.location.status;

    _logger.i('Current permission states:');
    _logger.i('  Bluetooth Scan: $bluetoothScan');
    _logger.i('  Bluetooth Connect: $bluetoothConnect');
    _logger.i('  Location: $location');

    final allGranted = bluetoothScan.isGranted && 
                       bluetoothConnect.isGranted && 
                       location.isGranted;

    if (allGranted) {
      _logger.i('✅ All Bluetooth permissions are granted');
    } else {
      _logger.w('⚠️ Some Bluetooth permissions are missing');
    }

    return allGranted;
  }

  /// Check if any permission is permanently denied
  Future<bool> isAnyPermissionPermanentlyDenied() async {
    final bluetoothScan = await Permission.bluetoothScan.status;
    final bluetoothConnect = await Permission.bluetoothConnect.status;
    final location = await Permission.location.status;

    return bluetoothScan.isPermanentlyDenied ||
           bluetoothConnect.isPermanentlyDenied ||
           location.isPermanentlyDenied;
  }

  /// Open app settings so user can manually grant permissions
  Future<void> openSettings() async {
    _logger.i('Opening app settings...');
    await openAppSettings();
  }
}

/// Result of permission request
enum PermissionResult {
  granted,
  denied,
  permanentlyDenied,
}
