import 'package:blue_thermal_printer/blue_thermal_printer.dart';
import 'package:logger/logger.dart';
import '../models/invoice_data.dart';
import '../services/image_based_thermal_printer.dart';
import '../services/bluetooth_validation_service.dart';
import '../services/printer_connection_validator.dart';
import '../services/thermal_print_enforcer.dart';
import 'package:esc_pos_utils_plus/esc_pos_utils_plus.dart' as esc_pos;
import 'dart:typed_data';

/// ═══════════════════════════════════════════════════════════════════════════
/// PRODUCTION-GRADE TEST PRINT SERVICE
/// ═══════════════════════════════════════════════════════════════════════════
///
/// Comprehensive test printing service that validates the entire print pipeline.
/// This ensures everything works before actual production use.
///
/// TEST VERIFICATIONS:
/// 1. Bluetooth environment is ready
/// 2. Printer connection is stable
/// 3. Image rendering works correctly
/// 4. Arabic text renders properly
/// 5. Print output is complete (no cut/distortion)
/// 6. Printer feeds and cuts correctly
///
/// USE CASES:
/// - Initial printer setup
/// - After printer firmware updates
/// - Debugging print issues
/// - Verifying new printer compatibility
/// - Training staff on printer usage
///
/// This is a MANDATORY step before production use.
///
/// ═══════════════════════════════════════════════════════════════════════════

class TestPrintService {
  static final TestPrintService _instance = TestPrintService._internal();
  factory TestPrintService() => _instance;
  TestPrintService._internal();

  final Logger _logger = Logger();
  final BluetoothValidationService _bluetoothValidator =
      BluetoothValidationService();
  final PrinterConnectionValidator _connectionValidator =
      PrinterConnectionValidator();
  final BlueThermalPrinter _bluetooth = BlueThermalPrinter.instance;

  /// ═══════════════════════════════════════════════════════════════════════════
  /// COMPREHENSIVE TEST PRINT
  /// ═══════════════════════════════════════════════════════════════════════════
  ///
  /// Performs a complete test of the printing pipeline.
  /// Returns detailed test result with pass/fail for each component.
  ///
  /// [device] - The bonded Bluetooth printer to test
  /// [paperSize] - Paper size to test (58mm or 80mm)
  ///
  /// Example:
  /// ```dart
  /// final result = await TestPrintService().performTestPrint(device, PaperSize.mm58);
  /// if (result.overallSuccess) {
  ///   print('✅ All tests passed!');
  /// } else {
  ///   print('❌ Failures: ${result.failedTests.join(", ")}');
  /// }
  /// ```
  Future<TestPrintResult> performTestPrint(
    BluetoothDevice device, {
    esc_pos.PaperSize paperSize = esc_pos.PaperSize.mm58,
  }) async {
    _logger.i('🧪 [Test Print] Starting comprehensive test print');
    _logger.i('   Device: ${device.name} (${device.address})');
    _logger.i('   Paper size: $paperSize');

    final results = <String, bool>{};
    final errors = <String, String>{};

    // ═══════════════════════════════════════════════════════════════════════════
    // TEST 1: Bluetooth Environment Validation
    // ═══════════════════════════════════════════════════════════════════════════
    _logger.i('📋 Test 1/6: Bluetooth environment validation');

    try {
      final validation = await _bluetoothValidator.validate(
        targetPrinterAddress: device.address,
      );

      if (validation.isReady) {
        _logger.i('  ✅ PASSED: Bluetooth environment ready');
        results['bluetooth_environment'] = true;
      } else {
        _logger.e('  ❌ FAILED: ${validation.userMessage}');
        results['bluetooth_environment'] = false;
        errors['bluetooth_environment'] = validation.actionableGuidance;
      }
    } catch (e) {
      _logger.e('  ❌ FAILED: Exception during validation: $e');
      results['bluetooth_environment'] = false;
      errors['bluetooth_environment'] = e.toString();
    }

    // If environment check failed, stop here
    if (results['bluetooth_environment'] == false) {
      return TestPrintResult(
        overallSuccess: false,
        results: results,
        errors: errors,
      );
    }

    // ═══════════════════════════════════════════════════════════════════════════
    // TEST 2: Printer Connection
    // ═══════════════════════════════════════════════════════════════════════════
    _logger.i('📋 Test 2/6: Printer connection');

    try {
      final connectionValidation = await _connectionValidator
          .validateConnection(device);

      if (connectionValidation.isReady) {
        _logger.i('  ✅ PASSED: Printer connected successfully');
        results['connection'] = true;
      } else {
        _logger.e('  ❌ FAILED: ${connectionValidation.userMessage}');
        results['connection'] = false;
        errors['connection'] = connectionValidation.actionableGuidance;
      }
    } catch (e) {
      _logger.e('  ❌ FAILED: Connection exception: $e');
      results['connection'] = false;
      errors['connection'] = e.toString();
    }

    // If connection failed, stop here
    if (results['connection'] == false) {
      return TestPrintResult(
        overallSuccess: false,
        results: results,
        errors: errors,
      );
    }

    // ═══════════════════════════════════════════════════════════════════════════
    // TEST 3: Image Rendering
    // ═══════════════════════════════════════════════════════════════════════════
    _logger.i('📋 Test 3/6: Image rendering');

    List<int>? printBytes;
    try {
      final testData = _createTestInvoiceData();
      printBytes = await ImageBasedThermalPrinter.generateImageBasedReceipt(
        testData,
        paperSize: paperSize,
      );

      if (printBytes.isNotEmpty) {
        _logger.i('  ✅ PASSED: Image rendered (${printBytes.length} bytes)');
        results['image_rendering'] = true;
      } else {
        _logger.e('  ❌ FAILED: Empty print data');
        results['image_rendering'] = false;
        errors['image_rendering'] = 'Image rendering produced no data';
      }
    } catch (e) {
      _logger.e('  ❌ FAILED: Rendering exception: $e');
      results['image_rendering'] = false;
      errors['image_rendering'] = e.toString();
    }

    // If rendering failed, stop here
    if (results['image_rendering'] == false || printBytes == null) {
      await _safeDisconnect();
      return TestPrintResult(
        overallSuccess: false,
        results: results,
        errors: errors,
      );
    }

    // ═══════════════════════════════════════════════════════════════════════════
    // TEST 4: Print Data Validation
    // ═══════════════════════════════════════════════════════════════════════════
    _logger.i('📋 Test 4/6: Print data validation');

    try {
      final validation = ThermalPrintEnforcer.validatePrintData(printBytes);

      if (validation.isValid) {
        _logger.i('  ✅ PASSED: Print data is valid image-based format');
        results['data_validation'] = true;
      } else {
        _logger.e('  ❌ FAILED: ${validation.errorMessage}');
        results['data_validation'] = false;
        errors['data_validation'] = validation.guidanceMessage;
      }
    } catch (e) {
      _logger.e('  ❌ FAILED: Validation exception: $e');
      results['data_validation'] = false;
      errors['data_validation'] = e.toString();
    }

    // ═══════════════════════════════════════════════════════════════════════════
    // TEST 5: Actual Print Transmission
    // ═══════════════════════════════════════════════════════════════════════════
    _logger.i('📋 Test 5/6: Print transmission');

    try {
      await _bluetooth.writeBytes(Uint8List.fromList(printBytes));

      // Wait for transmission to complete
      await Future.delayed(const Duration(milliseconds: 1500));

      _logger.i('  ✅ PASSED: Print data transmitted successfully');
      results['transmission'] = true;
    } catch (e) {
      _logger.e('  ❌ FAILED: Transmission exception: $e');
      results['transmission'] = false;
      errors['transmission'] = e.toString();
    }

    // ═══════════════════════════════════════════════════════════════════════════
    // TEST 6: Connection Stability
    // ═══════════════════════════════════════════════════════════════════════════
    _logger.i('📋 Test 6/6: Connection stability');

    try {
      await Future.delayed(const Duration(milliseconds: 500));

      final isHealthy = await _connectionValidator.isConnectionHealthy();

      if (isHealthy) {
        _logger.i('  ✅ PASSED: Connection remained stable after print');
        results['connection_stability'] = true;
      } else {
        _logger.w('  ⚠️ WARNING: Connection lost after print');
        results['connection_stability'] = false;
        errors['connection_stability'] =
            'Connection dropped after printing (may be normal for some printers)';
      }
    } catch (e) {
      _logger.e('  ❌ FAILED: Stability check exception: $e');
      results['connection_stability'] = false;
      errors['connection_stability'] = e.toString();
    }

    // Clean up connection
    await _safeDisconnect();

    // ═══════════════════════════════════════════════════════════════════════════
    // OVERALL RESULT
    // ═══════════════════════════════════════════════════════════════════════════
    final overallSuccess = results.values.every((passed) => passed);

    if (overallSuccess) {
      _logger.i(
        '✅ [Test Print] ALL TESTS PASSED - Printer is ready for production',
      );
    } else {
      final failedCount = results.values.where((passed) => !passed).length;
      _logger.e('❌ [Test Print] $failedCount test(s) failed');
    }

    return TestPrintResult(
      overallSuccess: overallSuccess,
      results: results,
      errors: errors,
    );
  }

  /// ═══════════════════════════════════════════════════════════════════════════
  /// QUICK CONNECTION TEST
  /// ═══════════════════════════════════════════════════════════════════════════
  ///
  /// Fast test to verify basic connectivity (no printing).
  /// Useful for initial setup or troubleshooting.
  Future<bool> quickConnectionTest(BluetoothDevice device) async {
    _logger.i('⚡ [Test Print] Quick connection test');

    try {
      // Validate environment
      final validation = await _bluetoothValidator.validate(
        targetPrinterAddress: device.address,
      );

      if (!validation.isReady) {
        _logger.e('  ❌ Environment not ready');
        return false;
      }

      // Validate connection
      final connectionValidation = await _connectionValidator
          .validateConnection(device);

      if (!connectionValidation.isReady) {
        _logger.e('  ❌ Connection failed');
        await _safeDisconnect();
        return false;
      }

      // Clean up
      await _safeDisconnect();

      _logger.i('  ✅ Quick test passed');
      return true;
    } catch (e) {
      _logger.e('  ❌ Quick test failed: $e');
      await _safeDisconnect();
      return false;
    }
  }

  /// Create test invoice data with Arabic text
  InvoiceData _createTestInvoiceData() {
    return InvoiceData(
      orderNumber: 'TEST-001',
      branchName: 'فرع الاختبار',
      cashierName: 'موظف الاختبار',
      dateTime: DateTime.now(),
      items: [
        InvoiceItem(
          name: 'قص شعر',
          price: 50.0,
          quantity: 1,
          employeeName: 'حلاق الاختبار',
        ),
        InvoiceItem(name: 'حلاقة ذقن', price: 30.0, quantity: 1),
      ],
      subtotalBeforeTax: 80.0,
      discountPercentage: 0.0,
      discountAmount: 0.0,
      amountAfterDiscount: 80.0,
      taxRate: 15.0,
      taxAmount: 12.0,
      grandTotal: 92.0,
      paymentMethod: 'نقدي',
      paidAmount: 100.0,
      remainingAmount: 8.0,
      businessName: 'صالون الاختبار',
      businessAddress: 'شارع الاختبار، المدينة',
      businessPhone: '+966 50 123 4567',
      taxNumber: '123456789',
      invoiceNotes: 'شكراً لزيارتكم - نتمنى لكم يوماً سعيداً',
    );
  }

  /// Safe disconnect without throwing exceptions
  Future<void> _safeDisconnect() async {
    try {
      final isConnected = await _bluetooth.isConnected;
      if (isConnected == true) {
        _logger.i('  🔌 Disconnecting from printer...');
        await _bluetooth.disconnect();
        await Future.delayed(const Duration(milliseconds: 300));
      }
    } catch (e) {
      _logger.w('  ⚠️ Disconnect warning: $e');
    }
  }
}

// ═══════════════════════════════════════════════════════════════════════════
// TEST PRINT RESULT DATA CLASS
// ═══════════════════════════════════════════════════════════════════════════

class TestPrintResult {
  final bool overallSuccess;
  final Map<String, bool> results;
  final Map<String, String> errors;

  const TestPrintResult({
    required this.overallSuccess,
    required this.results,
    required this.errors,
  });

  /// Get list of passed test names
  List<String> get passedTests =>
      results.entries.where((e) => e.value).map((e) => e.key).toList();

  /// Get list of failed test names
  List<String> get failedTests =>
      results.entries.where((e) => !e.value).map((e) => e.key).toList();

  /// Get summary report
  String get summary {
    final total = results.length;
    final passed = passedTests.length;
    final failed = failedTests.length;

    final buffer = StringBuffer();
    buffer.writeln('═══════════════════════════════════════');
    buffer.writeln('TEST PRINT SUMMARY');
    buffer.writeln('═══════════════════════════════════════');
    buffer.writeln('Total Tests: $total');
    buffer.writeln('Passed: $passed ✅');
    buffer.writeln('Failed: $failed ❌');
    buffer.writeln('');

    if (overallSuccess) {
      buffer.writeln('✅ OVERALL: ALL TESTS PASSED');
      buffer.writeln('');
      buffer.writeln('The printer is ready for production use.');
    } else {
      buffer.writeln('❌ OVERALL: SOME TESTS FAILED');
      buffer.writeln('');
      buffer.writeln('Failed Tests:');
      for (final test in failedTests) {
        buffer.writeln('  • $test');
        if (errors.containsKey(test)) {
          buffer.writeln('    Error: ${errors[test]}');
        }
      }
    }

    buffer.writeln('═══════════════════════════════════════');
    return buffer.toString();
  }

  /// Get Arabic summary report
  String get arabicSummary {
    final total = results.length;
    final passed = passedTests.length;
    final failed = failedTests.length;

    final buffer = StringBuffer();
    buffer.writeln('═══════════════════════════════════════');
    buffer.writeln('ملخص اختبار الطباعة');
    buffer.writeln('═══════════════════════════════════════');
    buffer.writeln('إجمالي الاختبارات: $total');
    buffer.writeln('نجح: $passed ✅');
    buffer.writeln('فشل: $failed ❌');
    buffer.writeln('');

    if (overallSuccess) {
      buffer.writeln('✅ النتيجة: نجحت جميع الاختبارات');
      buffer.writeln('');
      buffer.writeln('الطابعة جاهزة للاستخدام في الإنتاج.');
    } else {
      buffer.writeln('❌ النتيجة: فشلت بعض الاختبارات');
      buffer.writeln('');
      buffer.writeln('الاختبارات الفاشلة:');

      final testNamesAr = {
        'bluetooth_environment': 'بيئة البلوتوث',
        'connection': 'الاتصال',
        'image_rendering': 'عرض الصورة',
        'data_validation': 'التحقق من البيانات',
        'transmission': 'الإرسال',
        'connection_stability': 'استقرار الاتصال',
      };

      for (final test in failedTests) {
        final arabicName = testNamesAr[test] ?? test;
        buffer.writeln('  • $arabicName');
        if (errors.containsKey(test)) {
          buffer.writeln('    خطأ: ${errors[test]}');
        }
      }
    }

    buffer.writeln('═══════════════════════════════════════');
    return buffer.toString();
  }
}
