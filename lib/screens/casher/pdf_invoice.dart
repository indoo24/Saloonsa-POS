import 'dart:typed_data';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:flutter/services.dart' show rootBundle;
import 'models/service-model.dart';

Future<Uint8List> generateInvoicePdf(List<ServiceModel> cart) async {
  // تحميل الخط العربي (Cairo)
  final fontData = await rootBundle.load("assets/fonts/Cairo-Regular.ttf");
  final ttf = pw.Font.ttf(fontData);

  final pdf = pw.Document();

  double subtotal = cart.fold(0, (sum, item) => sum + item.price);
  double tax = subtotal * 0.15;
  double total = subtotal + tax;

  pdf.addPage(
    pw.Page(
      pageFormat: PdfPageFormat.a4,
      margin: const pw.EdgeInsets.all(24),
      build: (context) => pw.Directionality(
        // لإظهار العربي بشكل صحيح من اليمين لليسار
        textDirection: pw.TextDirection.rtl,
        child: pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            pw.Center(
              child: pw.Text(
                "فاتورة صالون الحلاقة ",
                style: pw.TextStyle(
                  font: ttf,
                  fontSize: 24,
                  fontWeight: pw.FontWeight.bold,
                ),
              ),
            ),
            pw.SizedBox(height: 20),

            pw.Text(
              " التاريخ: ${DateTime.now().toString().split(' ').first}",
              style: pw.TextStyle(font: ttf),
            ),
            pw.Text(
              " رقم الفاتورة: #${DateTime.now().millisecondsSinceEpoch}",
              style: pw.TextStyle(font: ttf),
            ),

            pw.SizedBox(height: 20),
            pw.Divider(),

            pw.Text(
              "الخدمات المختارة:",
              style: pw.TextStyle(
                font: ttf,
                fontWeight: pw.FontWeight.bold,
                fontSize: 18,
              ),
            ),
            pw.SizedBox(height: 10),

            pw.Table(
              border: pw.TableBorder.all(width: 0.5),
              children: [
                pw.TableRow(
                  decoration: const pw.BoxDecoration(color: PdfColors.amber100),
                  children: [
                    pw.Padding(
                      padding: const pw.EdgeInsets.all(8),
                      child: pw.Text(
                        "الخدمة",
                        style: pw.TextStyle(
                          font: ttf,
                          fontWeight: pw.FontWeight.bold,
                        ),
                      ),
                    ),
                    pw.Padding(
                      padding: const pw.EdgeInsets.all(8),
                      child: pw.Text(
                        "السعر",
                        style: pw.TextStyle(
                          font: ttf,
                          fontWeight: pw.FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
                ...cart.map(
                  (item) => pw.TableRow(
                    children: [
                      pw.Padding(
                        padding: const pw.EdgeInsets.all(8),
                        child: pw.Text(
                          item.name,
                          style: pw.TextStyle(font: ttf),
                        ),
                      ),
                      pw.Padding(
                        padding: const pw.EdgeInsets.all(8),
                        child: pw.Text(
                          "${item.price.toStringAsFixed(2)} ر.س",
                          style: pw.TextStyle(font: ttf),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),

            pw.SizedBox(height: 20),
            pw.Divider(),

            pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
              children: [
                pw.Text("الإجمالي الفرعي:", style: pw.TextStyle(font: ttf)),
                pw.Text(
                  "${subtotal.toStringAsFixed(2)} ر.س",
                  style: pw.TextStyle(font: ttf),
                ),
              ],
            ),
            pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
              children: [
                pw.Text("الضريبة (15%):", style: pw.TextStyle(font: ttf)),
                pw.Text(
                  "${tax.toStringAsFixed(2)} ر.س",
                  style: pw.TextStyle(font: ttf),
                ),
              ],
            ),
            pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
              children: [
                pw.Text(
                  "الإجمالي الكلي:",
                  style: pw.TextStyle(
                    font: ttf,
                    fontWeight: pw.FontWeight.bold,
                  ),
                ),
                pw.Text(
                  "${total.toStringAsFixed(2)} ر.س",
                  style: pw.TextStyle(
                    font: ttf,
                    fontWeight: pw.FontWeight.bold,
                  ),
                ),
              ],
            ),
            pw.Spacer(),
            pw.Center(
              child: pw.BarcodeWidget(
                data:
                    'https://your-salon-pos.com/invoice/${DateTime.now().millisecondsSinceEpoch}',
                barcode: pw.Barcode.qrCode(),
                width: 100,
                height: 100,
              ),
            ),
            pw.SizedBox(height: 10),
            pw.Center(
              child: pw.Text(
                "شكراً لزيارتكم ",
                style: pw.TextStyle(font: ttf, fontSize: 16),
              ),
            ),
          ],
        ),
      ),
    ),
  );

  return pdf.save();
}
