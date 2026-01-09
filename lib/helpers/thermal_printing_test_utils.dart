import 'package:barber_casher/helpers/sunmi_printer_detector.dart';
import 'package:barber_casher/models/invoice_data.dart';
import 'package:barber_casher/services/image_based_thermal_printer.dart';
import 'package:barber_casher/widgets/thermal_receipt_image_widget.dart';
import 'package:logger/logger.dart';

/// Testing Utilities for Image-Based Thermal Printing
///
/// Use these functions to test the image-based printing implementation
/// without going through the full app flow.
class ThermalPrintingTestUtils {
  static final Logger _logger = Logger();

  /// Test Sunmi detection
  static Future<void> testSunmiDetection() async {
    _logger.i('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
    _logger.i('TEST: Sunmi Device Detection');
    _logger.i('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');

    final isSunmi = await SunmiPrinterDetector.isSunmiPrinter();

    _logger.i('Result: ${isSunmi ? "SUNMI DEVICE" : "NON-SUNMI DEVICE"}');
    _logger.i('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
  }

  /// Force Sunmi mode ON
  static void forceSunmiMode() {
    _logger.w('⚠️ FORCING SUNMI MODE: ON');
    SunmiPrinterDetector.setForceOverride(true);
  }

  /// Force Sunmi mode OFF
  static void forceNonSunmiMode() {
    _logger.w('⚠️ FORCING SUNMI MODE: OFF');
    SunmiPrinterDetector.setForceOverride(false);
  }

  /// Reset to auto-detect
  static void resetAutoDetect() {
    _logger.i('ℹ️ RESET TO AUTO-DETECT');
    SunmiPrinterDetector.setForceOverride(null);
  }

  /// Create a sample invoice with Arabic text
  static InvoiceData createSampleArabicInvoice() {
    return InvoiceData(
      orderNumber: '1001',
      branchName: 'الفرع الرئيسي',
      cashierName: 'أحمد محمد',
      dateTime: DateTime.now(),
      customerName: 'خالد العتيبي',
      customerPhone: '0501234567',
      items: [
        InvoiceItem(
          name: 'قص شعر',
          price: 50.0,
          quantity: 1,
          employeeName: 'محمد',
        ),
        InvoiceItem(
          name: 'حلاقة ذقن',
          price: 30.0,
          quantity: 1,
          employeeName: 'أحمد',
        ),
        InvoiceItem(
          name: 'صبغة شعر',
          price: 120.0,
          quantity: 1,
          employeeName: 'علي',
        ),
      ],
      subtotalBeforeTax: 200.0,
      discountPercentage: 10.0,
      discountAmount: 20.0,
      amountAfterDiscount: 180.0,
      taxRate: 15.0,
      taxAmount: 27.0,
      grandTotal: 207.0,
      paymentMethod: 'نقدي',
      paidAmount: 210.0,
      remainingAmount: 0.0,
      businessName: 'صالون النخبة',
      businessAddress: 'الرياض - حي العليا - شارع التحلية',
      businessPhone: '0112345678',
      taxNumber: '300123456700003',
      invoiceNotes: 'شكراً لزيارتكم - نسعد بخدمتكم',
    );
  }

  /// Test image-based receipt generation
  static Future<void> testImageBasedGeneration() async {
    _logger.i('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
    _logger.i('TEST: Image-Based Receipt Generation');
    _logger.i('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');

    try {
      final invoice = createSampleArabicInvoice();

      _logger.i('Generating image-based receipt...');
      final bytes = await ImageBasedThermalPrinter.generateImageBasedReceipt(
        invoice,
      );

      _logger.i('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
      _logger.i('✅ SUCCESS: Generated ${bytes.length} bytes');
      _logger.i('Ready to send to printer!');
      _logger.i('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
    } catch (e, stackTrace) {
      _logger.e('❌ FAILED: $e', error: e, stackTrace: stackTrace);
    }
  }

  /// Get sample widget for visual inspection
  static ThermalReceiptImageWidget getSampleWidget() {
    final invoice = createSampleArabicInvoice();
    return ThermalReceiptImageWidget(data: invoice);
  }

  /// Print usage instructions
  static void printUsageInstructions() {
    print('''
╔════════════════════════════════════════════════════════════════╗
║       Image-Based Thermal Printing - Testing Utilities        ║
╚════════════════════════════════════════════════════════════════╝

📋 AVAILABLE TESTS:

1. Test Device Detection:
   await ThermalPrintingTestUtils.testSunmiDetection();

2. Force Sunmi Mode (for testing on non-Sunmi devices):
   ThermalPrintingTestUtils.forceSunmiMode();

3. Force Non-Sunmi Mode:
   ThermalPrintingTestUtils.forceNonSunmiMode();

4. Reset to Auto-Detect:
   ThermalPrintingTestUtils.resetAutoDetect();

5. Test Image Generation:
   await ThermalPrintingTestUtils.testImageBasedGeneration();

6. Get Sample Widget (for preview):
   final widget = ThermalPrintingTestUtils.getSampleWidget();

7. Create Sample Invoice:
   final invoice = ThermalPrintingTestUtils.createSampleArabicInvoice();

╔════════════════════════════════════════════════════════════════╗
║                        EXAMPLE USAGE                           ║
╚════════════════════════════════════════════════════════════════╝

// In your test code:
void testImagePrinting() async {
  // Test 1: Check device
  await ThermalPrintingTestUtils.testSunmiDetection();
  
  // Test 2: Force Sunmi mode for testing
  ThermalPrintingTestUtils.forceSunmiMode();
  
  // Test 3: Generate receipt
  await ThermalPrintingTestUtils.testImageBasedGeneration();
  
  // Test 4: Reset
  ThermalPrintingTestUtils.resetAutoDetect();
}

╔════════════════════════════════════════════════════════════════╗
║                     TESTING ON SUNMI V2                        ║
╚════════════════════════════════════════════════════════════════╝

1. Install app on Sunmi V2 device
2. Run: await ThermalPrintingTestUtils.testSunmiDetection()
3. Check logs - should show "SUNMI DEVICE"
4. Create test invoice with Arabic text
5. Print and verify Arabic displays correctly

╔════════════════════════════════════════════════════════════════╗
║                  TESTING ON OTHER DEVICES                      ║
╚════════════════════════════════════════════════════════════════╝

1. Install app on non-Sunmi device
2. Run: ThermalPrintingTestUtils.forceSunmiMode()
3. This simulates Sunmi behavior for testing
4. Print test invoice
5. Reset with: ThermalPrintingTestUtils.resetAutoDetect()

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
''');
  }
}
