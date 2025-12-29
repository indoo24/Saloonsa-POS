import 'models/customer.dart';
import 'models/service-model.dart';
import 'services/printer_service.dart';
import 'receipt_generator.dart';
import '../../models/invoice_data.dart';
import '../../helpers/sunmi_printer_detector.dart';
import '../../services/image_based_thermal_printer.dart';
import 'package:logger/logger.dart';

final Logger _logger = Logger();

/// Generate ESC/POS bytes from InvoiceData (matches PDF format exactly)
/// This is the preferred method that ensures thermal receipt matches PDF preview
/// 
/// IMPORTANT: This uses the OLD text-based ESC/POS method.
/// For Sunmi printers, use generateImageBasedInvoiceBytes() instead.
Future<List<int>> generateInvoiceBytesFromData({
  required InvoiceData data,
}) async {
  _logger.i('[PRINT] Generating TEXT-BASED invoice bytes from InvoiceData');
  final receiptGenerator = ReceiptGenerator();
  return await receiptGenerator.generateReceiptBytesFromInvoiceData(data: data);
}

/// Generate IMAGE-BASED ESC/POS bytes for Sunmi and similar printers
/// This renders the receipt as a bitmap image to support Arabic text
Future<List<int>> generateImageBasedInvoiceBytes({
  required InvoiceData data,
}) async {
  _logger.i('[PRINT] Generating IMAGE-BASED invoice bytes from InvoiceData');
  return await ImageBasedThermalPrinter.generateImageBasedReceipt(data);
}

/// Print invoice from InvoiceData to connected printer
/// 
/// AUTOMATIC ROUTING:
/// - Sunmi printers → Image-based printing (supports Arabic)
/// - Other printers → Text-based ESC/POS printing
/// 
/// Uses the same format as PDF preview for consistency
Future<bool> printInvoiceDirectFromData({
  required InvoiceData data,
}) async {
  try {
    _logger.i('[PRINT] ═══════════════════════════════════════════════════════');
    _logger.i('[PRINT] START: Print Invoice Direct From Data');
    _logger.i('[PRINT] Time: ${DateTime.now()}');
    _logger.i('[PRINT] ═══════════════════════════════════════════════════════');

    // STEP 1: Detect printer type (Sunmi vs Others)
    _logger.i('[PRINT] Step 1: Detecting printer type...');
    final isSunmi = await SunmiPrinterDetector.isSunmiPrinter();
    
    if (isSunmi) {
      _logger.i('[PRINT] ✅ Sunmi printer detected');
      _logger.i('[PRINT] → Will use IMAGE-BASED printing for Arabic support');
    } else {
      _logger.i('[PRINT] ℹ️ Non-Sunmi printer detected');
      _logger.i('[PRINT] → Will use TEXT-BASED ESC/POS printing');
    }

    // STEP 2: Generate bytes based on printer type
    _logger.i('[PRINT] Step 2: Generating receipt bytes...');
    final List<int> bytes;
    
    if (isSunmi) {
      // IMAGE-BASED: Render widget → image → raster
      bytes = await generateImageBasedInvoiceBytes(data: data);
      _logger.i('[PRINT] ✅ Image-based bytes generated: ${bytes.length} bytes');
    } else {
      // TEXT-BASED: Traditional ESC/POS text encoding
      bytes = await generateInvoiceBytesFromData(data: data);
      _logger.i('[PRINT] ✅ Text-based bytes generated: ${bytes.length} bytes');
    }

    // STEP 3: Send to printer
    _logger.i('[PRINT] Step 3: Sending ${bytes.length} bytes to printer...');
    final printerService = PrinterService();
    final result = await printerService.printBytes(bytes);

    if (result) {
      _logger.i('[PRINT] ═══════════════════════════════════════════════════════');
      _logger.i('[PRINT] ✅ SUCCESS: Invoice printed successfully!');
      _logger.i('[PRINT] Method: ${isSunmi ? "IMAGE-BASED (Sunmi)" : "TEXT-BASED (Standard)"}');
      _logger.i('[PRINT] Time: ${DateTime.now()}');
      _logger.i('[PRINT] ═══════════════════════════════════════════════════════');
    } else {
      _logger.e('[PRINT] ═══════════════════════════════════════════════════════');
      _logger.e('[PRINT] ❌ FAILED: Printer returned failure');
      _logger.e('[PRINT] Time: ${DateTime.now()}');
      _logger.e('[PRINT] ═══════════════════════════════════════════════════════');
    }

    return result;
  } catch (e, stackTrace) {
    _logger.e('[PRINT] ═══════════════════════════════════════════════════════');
    _logger.e('[PRINT] ❌ ERROR: Exception during printing');
    _logger.e('[PRINT] Error: $e');
    _logger.e('[PRINT] Time: ${DateTime.now()}');
    _logger.e('[PRINT] ═══════════════════════════════════════════════════════', 
      error: e, stackTrace: stackTrace);
    return false;
  }
}


/// Generate ESC/POS bytes for invoice printing with enhanced format
/// This function creates the invoice format matching the reference image
/// Returns raw bytes that can be sent to any printer (WiFi/Bluetooth/USB)
/// Now supports API-calculated values
Future<List<int>> generateInvoiceBytes({
  required Customer? customer,
  required List<ServiceModel> services,
  required double discount,
  required String cashierName,
  required String paymentMethod,
  String? orderNumber,
  String? branchName,
  double? paid,
  double? remaining,
  // NEW: API-provided calculated values (preferred)
  double? apiSubtotal,
  double? apiTaxAmount,
  double? apiDiscountAmount,
  double? apiGrandTotal,
}) async {
  // Use the enhanced receipt generator
  final receiptGenerator = ReceiptGenerator();

  return await receiptGenerator.generateReceiptBytes(
    orderNumber: orderNumber ?? '${DateTime.now().millisecondsSinceEpoch}',
    customer: customer,
    services: services,
    discount: discount,
    cashierName: cashierName,
    paymentMethod: paymentMethod,
    branchName: branchName ?? 'الفرع الرئيسي',
    paid: paid,
    remaining: remaining,
    // Pass API values to receipt generator
    apiSubtotal: apiSubtotal,
    apiTaxAmount: apiTaxAmount,
    apiDiscountAmount: apiDiscountAmount,
    apiGrandTotal: apiGrandTotal,
  );
}

/// Print invoice to connected printer (WiFi/Bluetooth/USB)
/// Uses the universal PrinterService to send data to any printer type
Future<bool> printInvoiceDirect({
  required Customer? customer,
  required List<ServiceModel> services,
  required double discount,
  required String cashierName,
  required String paymentMethod,
  String? orderNumber,
  String? branchName,
  double? paid,
  double? remaining,
  // NEW: API-provided calculated values (preferred)
  double? apiSubtotal,
  double? apiTaxAmount,
  double? apiDiscountAmount,
  double? apiGrandTotal,
}) async {
  try {
    // Generate invoice bytes using enhanced receipt generator
    final bytes = await generateInvoiceBytes(
      customer: customer,
      services: services,
      discount: discount,
      cashierName: cashierName,
      paymentMethod: paymentMethod,
      orderNumber: orderNumber,
      branchName: branchName,
      paid: paid,
      remaining: remaining,
      // Pass API values through
      apiSubtotal: apiSubtotal,
      apiTaxAmount: apiTaxAmount,
      apiDiscountAmount: apiDiscountAmount,
      apiGrandTotal: apiGrandTotal,
    );

    // Send to connected printer via universal service
    final printerService = PrinterService();
    final success = await printerService.printBytes(bytes);

    if (!success) {
      print('❌ فشل الطباعة');
      return false;
    }

    print('✅ تمت الطباعة بنجاح');
    return true;
  } catch (e) {
    print('❌ خطأ في الطباعة: $e');
    return false;
  }
}
