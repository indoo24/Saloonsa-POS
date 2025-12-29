import 'package:flutter/material.dart';
import '../models/invoice_data.dart';
import '../screens/thermal_receipt_preview_screen.dart';

/// Test page to preview thermal receipt format
/// 
/// This is a quick test page to see how the receipt looks
/// without needing to create a full invoice or connect to a printer.
class ThermalReceiptTestPage extends StatelessWidget {
  const ThermalReceiptTestPage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    // Create sample invoice data matching your receipt image
    final testData = InvoiceData(
      orderNumber: '104',
      branchName: 'الفرع الرئيسي',
      cashierName: 'Yousef',
      dateTime: DateTime.now(),
      customerName: 'عميل كاش',
      customerPhone: null,
      items: [
        InvoiceItem(
          name: 'قص',
          price: 25.00,
          quantity: 1,
          employeeName: 'محمد',
        ),
      ],
      subtotalBeforeTax: 25.00,
      discountPercentage: 0.0,
      discountAmount: 0.0,
      amountAfterDiscount: 25.00,
      taxRate: 15.0,
      taxAmount: 3.75,
      grandTotal: 28.75,
      paymentMethod: 'نقدي',
      paidAmount: 28.75,
      remainingAmount: 0.0,
      invoiceNotes: null,
      businessName: 'صالون الشباب',
      businessAddress: 'الصبخة البحرية',
      businessPhone: '0566666464',
      taxNumber: 'TAX123456789',
      logoPath: 'assets/images/logo.png',
    );

    return ThermalReceiptPreviewScreen(
      data: testData,
      paperWidth: PaperWidth.mm80,
      onPrint: () {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('هذا مجرد معاينة - الطباعة الفعلية ستحتاج طابعة حرارية'),
            backgroundColor: Colors.blue,
          ),
        );
      },
      onClose: () => Navigator.of(context).pop(),
    );
  }
}
