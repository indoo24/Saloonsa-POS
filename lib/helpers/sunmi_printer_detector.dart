import 'dart:io';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:logger/logger.dart';

/// Sunmi Printer Detector
///
/// Detects if the current device is a Sunmi POS device (specifically Sunmi V2).
/// Sunmi devices have built-in thermal printers that DO NOT support Arabic
/// text via ESC/POS encoding (CP1256/CP864), but DO support bitmap/raster printing.
///
/// This detector helps us route to image-based printing for Sunmi devices
/// while using text-based ESC/POS for other thermal printers.
class SunmiPrinterDetector {
  static final Logger _logger = Logger();
  static final DeviceInfoPlugin _deviceInfo = DeviceInfoPlugin();

  // Known Sunmi device models and identifiers
  static const List<String> _sunmiModels = [
    'SUNMI',
    'V2',
    'V2 PRO',
    'V2s',
    'V2 PLUS',
    'P2',
    'P2 PRO',
    'P2 LITE',
    'T2',
    'T2s',
    'T2 LITE',
    'M2',
    'D2',
    'D2s',
  ];

  static const List<String> _sunmiManufacturers = ['SUNMI', 'Sunmi', 'sunmi'];

  static const List<String> _sunmiBrands = ['SUNMI', 'Sunmi', 'sunmi'];

  /// Check if the current device is a Sunmi POS device
  /// Returns true if Sunmi is detected, false otherwise
  static Future<bool> isSunmiDevice() async {
    try {
      // Only Android devices can be Sunmi
      if (!Platform.isAndroid) {
        _logger.d('[PRINT] Not Android - cannot be Sunmi');
        return false;
      }

      // Get Android device info
      final androidInfo = await _deviceInfo.androidInfo;

      final model = androidInfo.model;
      final manufacturer = androidInfo.manufacturer;
      final brand = androidInfo.brand;
      final product = androidInfo.product;
      final device = androidInfo.device;

      _logger.i('[PRINT] Device detection:');
      _logger.i('  - Model: $model');
      _logger.i('  - Manufacturer: $manufacturer');
      _logger.i('  - Brand: $brand');
      _logger.i('  - Product: $product');
      _logger.i('  - Device: $device');

      // Check if any identifier matches Sunmi
      final isSunmi =
          _matchesSunmi(model) ||
          _matchesSunmi(manufacturer) ||
          _matchesSunmi(brand) ||
          _matchesSunmi(product) ||
          _matchesSunmi(device);

      if (isSunmi) {
        _logger.i(
          '[PRINT] ✅ Sunmi printer detected! Will use image-based printing for Arabic.',
        );
      } else {
        _logger.i(
          '[PRINT] ℹ️ Non-Sunmi device. Will use text-based ESC/POS printing.',
        );
      }

      return isSunmi;
    } catch (e, stackTrace) {
      _logger.w(
        '[PRINT] Failed to detect Sunmi device: $e',
        error: e,
        stackTrace: stackTrace,
      );
      // Default to false (use text-based printing) if detection fails
      return false;
    }
  }

  /// Check if a string matches any Sunmi identifier
  static bool _matchesSunmi(String value) {
    final upperValue = value.toUpperCase();

    // Check against known models
    for (final model in _sunmiModels) {
      if (upperValue.contains(model.toUpperCase())) {
        return true;
      }
    }

    // Check against manufacturers
    for (final manufacturer in _sunmiManufacturers) {
      if (upperValue.contains(manufacturer.toUpperCase())) {
        return true;
      }
    }

    // Check against brands
    for (final brand in _sunmiBrands) {
      if (upperValue.contains(brand.toUpperCase())) {
        return true;
      }
    }

    return false;
  }

  /// Force override for testing
  /// Set to true to force Sunmi mode, false to force non-Sunmi, null for auto-detect
  static bool? _forceOverride;

  static void setForceOverride(bool? value) {
    _forceOverride = value;
    if (value != null) {
      _logger.w(
        '[PRINT] ⚠️ Sunmi detection OVERRIDE: $value (for testing only)',
      );
    }
  }

  /// Get the current detection result (with override support)
  static Future<bool> isSunmiPrinter() async {
    if (_forceOverride != null) {
      _logger.w('[PRINT] Using forced override: $_forceOverride');
      return _forceOverride!;
    }

    return await isSunmiDevice();
  }
}
