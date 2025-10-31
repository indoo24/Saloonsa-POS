import 'dart:typed_data';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'models/service-model.dart';

Future<Uint8List> generateInvoicePdf(List<ServiceModel> cart) async {
  final pdf = pw.Document();

  double subtotal = cart.fold(0, (sum, item) => sum + item.price);
  double tax = subtotal * 0.15;
  double total = subtotal + tax;

  pdf.addPage(
    pw.Page(
      pageFormat: PdfPageFormat.a4,
      margin: const pw.EdgeInsets.all(24),
      build: (context) => pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Center(
            child: pw.Text(
              "Salon POS Invoice 💈",
              style: pw.TextStyle(
                fontSize: 24,
                fontWeight: pw.FontWeight.bold,
              ),
            ),
          ),
          pw.SizedBox(height: 20),

          pw.Text("📅 التاريخ: ${DateTime.now().toString().split(' ').first}"),
          pw.Text("🧾 رقم الفاتورة: #${DateTime.now().millisecondsSinceEpoch}"),

          pw.SizedBox(height: 20),
          pw.Divider(),

          pw.Text("الخدمات المختارة:",
              style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 18)),
          pw.SizedBox(height: 10),

          pw.Table(
            border: pw.TableBorder.all(width: 0.5),
            children: [
              pw.TableRow(
                decoration: const pw.BoxDecoration(color: PdfColors.amber100),
                children: [
                  pw.Padding(
                      padding: const pw.EdgeInsets.all(8),
                      child: pw.Text("الخدمة",
                          style: pw.TextStyle(fontWeight: pw.FontWeight.bold))),
                  pw.Padding(
                      padding: const pw.EdgeInsets.all(8),
                      child: pw.Text("السعر",
                          style: pw.TextStyle(fontWeight: pw.FontWeight.bold))),
                ],
              ),
              ...cart.map(
                    (item) => pw.TableRow(children: [
                  pw.Padding(
                      padding: const pw.EdgeInsets.all(8),
                      child: pw.Text(item.name)),
                  pw.Padding(
                      padding: const pw.EdgeInsets.all(8),
                      child: pw.Text("${item.price.toStringAsFixed(2)} ج.م")),
                ]),
              ),
            ],
          ),

          pw.SizedBox(height: 20),
          pw.Divider(),

          pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
              children: [
                pw.Text("الإجمالي الفرعي:"),
                pw.Text("${subtotal.toStringAsFixed(2)} ج.م"),
              ]),
          pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
              children: [
                pw.Text("الضريبة (15%):"),
                pw.Text("${tax.toStringAsFixed(2)} ج.م"),
              ]),
          pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
              children: [
                pw.Text("الإجمالي الكلي:",
                    style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
                pw.Text("${total.toStringAsFixed(2)} ج.م",
                    style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
              ]),
          pw.Spacer(),
          pw.Center(
            child: pw.Text(
              "شكراً لزيارتكم ❤",
              style: pw.TextStyle(fontSize: 16),
            ),
          ),
        ],
      ),
    ),
  );

  return pdf.save();
}