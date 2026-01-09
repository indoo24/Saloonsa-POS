import 'dart:io';
import 'package:permission_handler/permission_handler.dart';
import 'package:logger/logger.dart';
import 'package:android_intent_plus/android_intent.dart';

/// Helper to open system settings screens
///
/// CRITICAL: The app CANNOT enable Bluetooth or Location programmatically.
/// This helper provides methods to guide users to the correct system settings.
class SystemSettingsHelper {
  static final Logger _logger = Logger();

  /// Open Bluetooth settings (device Bluetooth settings, not app settings)
  static Future<void> openBluetoothSettings() async {
    _logger.i('🔧 Opening Bluetooth settings...');

    if (Platform.isAndroid) {
      // Android: Open device Bluetooth settings directly
      try {
        const intent = AndroidIntent(
          action: 'android.settings.BLUETOOTH_SETTINGS',
        );
        await intent.launch();
        _logger.i('✅ Opened Bluetooth settings');
      } catch (e) {
        _logger.e('❌ Failed to open Bluetooth settings: $e');
        // Fallback to app settings if Android intent fails
        await openAppSettings();
      }
    }
  }

  /// Open Location settings (device location settings, not app settings)
  static Future<void> openLocationSettings() async {
    _logger.i('🔧 Opening Location settings...');

    if (Platform.isAndroid) {
      // Android: Open device Location settings directly
      try {
        const intent = AndroidIntent(
          action: 'android.settings.LOCATION_SOURCE_SETTINGS',
        );
        await intent.launch();
        _logger.i('✅ Opened Location settings');
      } catch (e) {
        _logger.e('❌ Failed to open Location settings: $e');
        // Fallback to app settings if Android intent fails
        await openAppSettings();
      }
    }
  }

  /// Open app-specific permission settings
  static Future<void> openAppPermissionSettings() async {
    _logger.i('🔧 Opening app permission settings...');

    try {
      await openAppSettings();
      _logger.i('✅ Opened app settings');
    } catch (e) {
      _logger.e('❌ Failed to open app settings: $e');
    }
  }
}
