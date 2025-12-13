import 'models/customer.dart';
import 'models/service-model.dart';
import 'services/printer_service.dart';
import 'receipt_generator.dart';

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
