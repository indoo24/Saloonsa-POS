import 'services/printer_service.dart';
import '../../models/invoice_data.dart';
import 'package:logger/logger.dart';

final Logger _logger = Logger();

/// Print invoice from InvoiceData to connected printer
///
/// UNIFIED IMAGE-BASED PRINTING:
/// - All thermal printers use image-based printing
/// - No text encoding, no charset converter
/// - Arabic renders perfectly on ALL printer brands
/// - Predictable, stable, production-ready
///
/// This is the ONLY thermal printing method in the application.
Future<bool> printInvoiceDirectFromData({required InvoiceData data}) async {
  try {
    _logger.i(
      '[PRINT] ═══════════════════════════════════════════════════════',
    );
    _logger.i('[PRINT] Print Invoice Direct From Data');
    _logger.i('[PRINT] Time: ${DateTime.now()}');
    _logger.i(
      '[PRINT] ═══════════════════════════════════════════════════════',
    );

    final printerService = PrinterService();
    final result = await printerService.printInvoiceDirectFromData(data);

    if (result) {
      _logger.i(
        '[PRINT] ═══════════════════════════════════════════════════════',
      );
      _logger.i('[PRINT] ✅ SUCCESS: Invoice printed successfully!');
      _logger.i('[PRINT] Method: IMAGE-BASED (Universal)');
      _logger.i('[PRINT] Time: ${DateTime.now()}');
      _logger.i(
        '[PRINT] ═══════════════════════════════════════════════════════',
      );
    } else {
      _logger.e(
        '[PRINT] ═══════════════════════════════════════════════════════',
      );
      _logger.e('[PRINT] ❌ FAILED: Printer returned failure');
      _logger.e('[PRINT] Time: ${DateTime.now()}');
      _logger.e(
        '[PRINT] ═══════════════════════════════════════════════════════',
      );
    }

    return result;
  } catch (e, stackTrace) {
    _logger.e(
      '[PRINT] ═══════════════════════════════════════════════════════',
    );
    _logger.e('[PRINT] ❌ ERROR: Exception during printing');
    _logger.e('[PRINT] Error: $e');
    _logger.e('[PRINT] Time: ${DateTime.now()}');
    _logger.e(
      '[PRINT] ═══════════════════════════════════════════════════════',
      error: e,
      stackTrace: stackTrace,
    );
    return false;
  }
}

// ============================================================================
// DEPRECATED LEGACY FUNCTIONS
// ============================================================================
// The functions below use OLD text-based ESC/POS printing with encoding issues.
// They are kept for backwards compatibility but should NOT be used.
// Use printInvoiceDirectFromData() instead for all thermal printing.
// ============================================================================

/// ⚠️ DEPRECATED: Use printInvoiceDirectFromData() instead
/// This uses OLD text-based ESC/POS with Arabic encoding issues
@Deprecated('Use printInvoiceDirectFromData() with InvoiceData instead')
Future<List<int>> generateInvoiceBytes({
  required dynamic customer,
  required List<dynamic> services,
  required double discount,
  required String cashierName,
  required String paymentMethod,
  String? orderNumber,
  String? branchName,
  double? paid,
  double? remaining,
  double? apiSubtotal,
  double? apiTaxAmount,
  double? apiDiscountAmount,
  double? apiGrandTotal,
}) async {
  throw UnimplementedError(
    'Text-based ESC/POS printing is deprecated. '
    'Use printInvoiceDirectFromData() with InvoiceData instead.',
  );
}

/// ⚠️ DEPRECATED: Use printInvoiceDirectFromData() instead
/// This uses OLD text-based ESC/POS with Arabic encoding issues
@Deprecated('Use printInvoiceDirectFromData() with InvoiceData instead')
Future<bool> printInvoiceDirect({
  required dynamic customer,
  required List<dynamic> services,
  required double discount,
  required String cashierName,
  required String paymentMethod,
  String? orderNumber,
  String? branchName,
  double? paid,
  double? remaining,
  double? apiSubtotal,
  double? apiTaxAmount,
  double? apiDiscountAmount,
  double? apiGrandTotal,
}) async {
  throw UnimplementedError(
    'Text-based ESC/POS printing is deprecated. '
    'Use printInvoiceDirectFromData() with InvoiceData instead.',
  );
}
