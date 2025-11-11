import 'package:esc_pos_printer_plus/esc_pos_printer_plus.dart';
import 'package:esc_pos_utils_plus/esc_pos_utils_plus.dart';
import 'package:intl/intl.dart';
import 'models/customer.dart';
import 'models/service-model.dart';

Future<void> printInvoiceDirect({
  required Customer? customer,
  required List<ServiceModel> services,
  required double discount,
  required String cashierName,
  required String paymentMethod,
}) async {
  final profile = await CapabilityProfile.load();
  final printer = NetworkPrinter(PaperSize.mm80, profile);

  // ✅ غيّر IP و Port حسب الطابعة عندك
  final res = await printer.connect('192.168.1.123', port: 9100);

  if (res == PosPrintResult.success) {
    final subtotal = services.fold<double>(0, (sum, item) => sum + item.price);
    final tax = subtotal * 0.15;
    final totalBeforeDiscount = subtotal + tax;
    final discountAmount = totalBeforeDiscount * (discount / 100);
    final finalTotal = totalBeforeDiscount - discountAmount;

    printer.text('صالون الشباب',
        styles: PosStyles(align: PosAlign.center, bold: true, height: PosTextSize.size2));
    printer.text('المدينة المنورة', styles: PosStyles(align: PosAlign.center));
    printer.text('0565656565', styles: PosStyles(align: PosAlign.center));
    printer.hr();

    printer.text('فاتورة ضريبية مبسطة',
        styles: PosStyles(bold: true, align: PosAlign.center));
    printer.hr();

    printer.text('رقم الفاتورة: 77');
    printer.text('طريقة الدفع: $paymentMethod');
    printer.text('التاريخ: ${DateFormat('yyyy-MM-dd').format(DateTime.now())}');
    printer.text('الكاشير: $cashierName');
    printer.text('العميل: ${customer?.name ?? 'عميل كاش'}');
    printer.hr();

    // جدول الخدمات
    printer.row([
      PosColumn(text: 'الوصف', width: 5, styles: PosStyles(bold: true)),
      PosColumn(text: 'السعر', width: 2, styles: PosStyles(bold: true)),
      PosColumn(text: 'الموظف', width: 5, styles: PosStyles(bold: true, align: PosAlign.right)),
    ]);
    printer.hr(ch: '-');

    for (final s in services) {
      printer.row([
        PosColumn(text: s.name, width: 5),
        PosColumn(text: s.price.toStringAsFixed(2), width: 2, styles: PosStyles(align: PosAlign.right)),
        PosColumn(text: s.barber ?? '-', width: 5, styles: PosStyles(align: PosAlign.right)),
      ]);
    }

    printer.hr();

    printer.text('عدد الخدمات: ${services.length}');
    printer.text('الإجمالي: ${subtotal.toStringAsFixed(2)} ر.س');
    printer.text('الإجمالي قبل الضريبة: ${totalBeforeDiscount.toStringAsFixed(2)} ر.س');
    printer.text('الضريبة 15%: ${tax.toStringAsFixed(2)} ر.س');
    printer.text('الخصم: ${discountAmount.toStringAsFixed(2)} ر.س');
    printer.hr();
    printer.text('المجموع: ${finalTotal.toStringAsFixed(2)} ر.س',
        styles: PosStyles(bold: true, align: PosAlign.right));

    printer.hr(ch: '=');

    printer.text('إجمالي المستحقات: ${finalTotal.toStringAsFixed(2)} ر.س',
        styles: PosStyles(bold: true, align: PosAlign.right));

    printer.hr();

    printer.text('المديونية السابقة: 0.00 ر.س');
    printer.text('الرصيد: ${finalTotal.toStringAsFixed(2)} ر.س');

    printer.hr();
    printer.text('شكراً لزيارتكم ... نتطلع لرؤيتكم مرة أخرى',
        styles: PosStyles(align: PosAlign.center));

    // QR code (optional)
    printer.qrcode('Invoice Total: ${finalTotal.toStringAsFixed(2)} SAR');

    printer.feed(2);
    printer.cut();
    printer.disconnect();
  } else {
    print('❌ فشل الاتصال بالطابعة: $res');
  }
}