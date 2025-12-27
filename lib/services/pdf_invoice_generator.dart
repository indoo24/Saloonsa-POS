import 'dart:typed_data';
import 'package:flutter/services.dart' show rootBundle;
import 'package:intl/intl.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:http/http.dart' as http;
import '../models/invoice_data.dart';

/// A4 PDF Invoice Generator
///
/// This class generates professional A4 PDF invoices matching the website invoice format.
/// It is completely separate from thermal ESC/POS printing.
///
/// For thermal printing, use thermal_receipt_generator.dart instead.
class PdfInvoiceGenerator {
  /// Generate A4 PDF invoice
  ///
  /// [data] - All invoice information
  ///
  /// Returns PDF bytes ready for printing or saving
  static Future<Uint8List> generateA4Invoice(InvoiceData data) async {
    final pdf = pw.Document();

    // Load Arabic font
    final font = await rootBundle.load("assets/fonts/Cairo-Regular.ttf");
    final ttf = pw.Font.ttf(font);

    // Load logo
    pw.MemoryImage? logoImage;
    if (data.logoPath != null) {
      try {
        Uint8List logoBytes;

        // Check if network URL or asset path
        if (data.logoPath!.startsWith('http://') ||
            data.logoPath!.startsWith('https://')) {
          // Network image - download it
          final response = await http.get(Uri.parse(data.logoPath!));
          if (response.statusCode == 200) {
            logoBytes = response.bodyBytes;
          } else {
            throw Exception('Failed to load logo: HTTP ${response.statusCode}');
          }
        } else {
          // Asset image - load from bundle
          final logoData = await rootBundle.load(data.logoPath!);
          logoBytes = logoData.buffer.asUint8List();
        }

        logoImage = pw.MemoryImage(logoBytes);
      } catch (e) {
        print('Could not load logo for PDF: $e');
      }
    }

    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(40),
        theme: pw.ThemeData.withFont(base: ttf, bold: ttf),
        build: (pw.Context context) {
          return pw.Directionality(
            textDirection: pw.TextDirection.rtl,
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.stretch,
              children: [
                // Header with logo and business info
                _buildWebsiteHeader(data, logoImage, ttf),
                pw.SizedBox(height: 10),

                // Horizontal separator
                pw.Divider(thickness: 1),
                pw.SizedBox(height: 10),

                // Title
                _buildWebsiteTitle(ttf),
                pw.SizedBox(height: 20),

                // Invoice number section (right aligned)
                _buildInvoiceNumber(data, ttf),
                pw.SizedBox(height: 20),

                // Items table
                _buildWebsiteItemsTable(data, ttf),
                pw.SizedBox(height: 20),

                // Financial summary box
                _buildWebsiteFinancialSummary(data, ttf),
              ],
            ),
          );
        },
      ),
    );

    return pdf.save();
  }

  /// Build header matching website layout
  static pw.Widget _buildWebsiteHeader(
    InvoiceData data,
    pw.MemoryImage? logoImage,
    pw.Font ttf,
  ) {
    final dateStr = DateFormat('yyyy-MM-dd HH:mm', 'ar').format(data.dateTime);

    return pw.Row(
      mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        // Left side - Business info
        pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            pw.Text(
              'رقم الفاتورة : ${data.orderNumber}',
              style: pw.TextStyle(font: ttf, fontSize: 10),
            ),
            pw.Text(
              'العميل : ${data.customerName ?? "عميل كاش"}',
              style: pw.TextStyle(font: ttf, fontSize: 10),
            ),
            pw.Text(
              'المندوب : ${data.cashierName}',
              style: pw.TextStyle(font: ttf, fontSize: 10),
            ),
            pw.Text(
              'الدفع : ${data.paymentMethod}',
              style: pw.TextStyle(font: ttf, fontSize: 10),
            ),
            pw.Text(
              'التاريخ : $dateStr',
              style: pw.TextStyle(font: ttf, fontSize: 10),
            ),
          ],
        ),

        // Center - Logo
        if (logoImage != null)
          pw.Container(
            width: 100,
            height: 100,
            child: pw.Image(logoImage, fit: pw.BoxFit.contain),
          ),

        // Right side - Salon info
        pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.end,
          children: [
            pw.Text(
              data.businessName,
              style: pw.TextStyle(
                font: ttf,
                fontSize: 16,
                fontWeight: pw.FontWeight.bold,
              ),
            ),
            pw.SizedBox(height: 5),
            pw.Text(
              'الرقم الضريبي : ${data.taxNumber ?? "000000000"}',
              style: pw.TextStyle(font: ttf, fontSize: 10),
            ),
            pw.Text(
              'المدينة : ${data.branchName}',
              style: pw.TextStyle(font: ttf, fontSize: 10),
            ),
            pw.Text(
              data.businessPhone,
              style: pw.TextStyle(font: ttf, fontSize: 10),
            ),
            pw.Text(
              'تاريخ الطباعة : $dateStr',
              style: pw.TextStyle(font: ttf, fontSize: 10),
            ),
            pw.Text(
              'مسؤول الطباعة : ${data.cashierName}',
              style: pw.TextStyle(font: ttf, fontSize: 10),
            ),
          ],
        ),
      ],
    );
  }

  /// Build title matching website
  static pw.Widget _buildWebsiteTitle(pw.Font ttf) {
    return pw.Center(
      child: pw.Text(
        'فاتورة ضريبية',
        style: pw.TextStyle(
          font: ttf,
          fontSize: 20,
          fontWeight: pw.FontWeight.bold,
        ),
      ),
    );
  }

  /// Build invoice number section
  static pw.Widget _buildInvoiceNumber(InvoiceData data, pw.Font ttf) {
    return pw.Align(
      alignment: pw.Alignment.centerRight,
      child: pw.Text(
        'فاتورة مبيعات # ${data.orderNumber}',
        style: pw.TextStyle(
          font: ttf,
          fontSize: 14,
          fontWeight: pw.FontWeight.bold,
        ),
      ),
    );
  }

  /// Build items table matching website format
  static pw.Widget _buildWebsiteItemsTable(InvoiceData data, pw.Font ttf) {
    return pw.Table(
      border: pw.TableBorder.all(color: PdfColors.black, width: 1),
      columnWidths: {
        0: const pw.FlexColumnWidth(0.5), // #
        1: const pw.FlexColumnWidth(3), // الوصف
        2: const pw.FlexColumnWidth(1.5), // الموظف
        3: const pw.FlexColumnWidth(1), // وحدة
        4: const pw.FlexColumnWidth(1), // الكمية
        5: const pw.FlexColumnWidth(1.5), // البيع
        6: const pw.FlexColumnWidth(1.5), // الإجمالي
      },
      children: [
        // Header row
        pw.TableRow(
          children: [
            _buildTableCell('#', ttf, bold: true),
            _buildTableCell('الوصف', ttf, bold: true),
            _buildTableCell('الموظف', ttf, bold: true),
            _buildTableCell('وحدة', ttf, bold: true),
            _buildTableCell('الكمية', ttf, bold: true),
            _buildTableCell('البيع', ttf, bold: true),
            _buildTableCell('الإجمالي', ttf, bold: true),
          ],
        ),

        // Items
        ...data.items.asMap().entries.map((entry) {
          final index = entry.key + 1;
          final item = entry.value;

          return pw.TableRow(
            children: [
              _buildTableCell('✓ $index', ttf), // Checkmark + number
              _buildTableCell(item.name, ttf, align: pw.TextAlign.right),
              _buildTableCell(item.employeeName ?? '-', ttf),
              _buildTableCell('', ttf), // Unit (empty)
              _buildTableCell(item.quantity.toString(), ttf),
              _buildTableCell('${item.price.toStringAsFixed(2)} ريس', ttf),
              _buildTableCell('${item.total.toStringAsFixed(2)} ريس', ttf),
            ],
          );
        }).toList(),
      ],
    );
  }

  /// Build table cell
  static pw.Widget _buildTableCell(
    String text,
    pw.Font ttf, {
    pw.TextAlign align = pw.TextAlign.center,
    bool bold = false,
  }) {
    return pw.Padding(
      padding: const pw.EdgeInsets.all(8),
      child: pw.Text(
        text,
        textAlign: align,
        style: pw.TextStyle(
          font: ttf,
          fontSize: 10,
          fontWeight: bold ? pw.FontWeight.bold : pw.FontWeight.normal,
        ),
      ),
    );
  }

  /// Build financial summary box matching website
  static pw.Widget _buildWebsiteFinancialSummary(
    InvoiceData data,
    pw.Font ttf,
  ) {
    // Generate QR code data (you can customize this with actual tax invoice data)
    final qrData =
        'Invoice: ${data.orderNumber}\n'
        'Total: ${data.grandTotal.toStringAsFixed(2)} SAR\n'
        'Tax: ${data.taxAmount.toStringAsFixed(2)} SAR\n'
        'Date: ${DateFormat('yyyy-MM-dd').format(data.dateTime)}';

    return pw.Container(
      decoration: pw.BoxDecoration(
        border: pw.Border.all(color: PdfColors.black, width: 1),
      ),
      child: pw.Row(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          // Left side - Financial details
          pw.Expanded(
            flex: 2,
            child: pw.Column(
              children: [
                // Top section with totals
                pw.Container(
                  padding: const pw.EdgeInsets.all(10),
                  child: pw.Column(
                    children: [
                      _buildSummaryRow(
                        'الإجمالي قبل الضريبة :',
                        '${data.subtotalBeforeTax.toStringAsFixed(2)} ريس',
                        ttf,
                      ),
                      _buildSummaryRow(
                        'إجمالي قيمة الضريبة :',
                        '${data.taxAmount.toStringAsFixed(2)} ريس',
                        ttf,
                      ),
                      if (data.hasDiscount)
                        _buildSummaryRow(
                          'نسبة الضريبة : ${data.discountPercentage.toStringAsFixed(0)}',
                          '${data.discountAmount.toStringAsFixed(2)} ريس',
                          ttf,
                        ),
                      pw.Divider(thickness: 1),
                      _buildSummaryRow(
                        'الخصم : ${data.discountPercentage.toStringAsFixed(2)} ريس',
                        '0.00 ريس',
                        ttf,
                        bold: true,
                      ),
                      pw.Divider(thickness: 1),
                      _buildSummaryRow(
                        'الإجمالي : ${data.taxRate.toStringAsFixed(0)}',
                        '${data.grandTotal.toStringAsFixed(2)} ريس',
                        ttf,
                        bold: true,
                        fontSize: 12,
                      ),
                      pw.Divider(thickness: 1),
                      _buildSummaryRow(
                        'المدفوع : ${data.paidAmount?.toStringAsFixed(2) ?? data.grandTotal.toStringAsFixed(2)}',
                        '${data.paidAmount?.toStringAsFixed(2) ?? data.grandTotal.toStringAsFixed(2)} ريس',
                        ttf,
                      ),
                    ],
                  ),
                ),

                // Bottom section with quantity and payment info
                pw.Container(
                  decoration: const pw.BoxDecoration(
                    border: pw.Border(
                      top: pw.BorderSide(color: PdfColors.black, width: 1),
                    ),
                  ),
                  padding: const pw.EdgeInsets.all(10),
                  child: pw.Row(
                    mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                    children: [
                      pw.Column(
                        crossAxisAlignment: pw.CrossAxisAlignment.start,
                        children: [
                          pw.Text(
                            'إجمالي الكميات : ${data.items.fold<int>(0, (sum, item) => sum + item.quantity)}',
                            style: pw.TextStyle(font: ttf, fontSize: 10),
                          ),
                          pw.SizedBox(height: 5),
                          pw.Text(
                            'توقيع المندوب :',
                            style: pw.TextStyle(font: ttf, fontSize: 10),
                          ),
                        ],
                      ),
                      pw.Column(
                        crossAxisAlignment: pw.CrossAxisAlignment.end,
                        children: [
                          pw.Text(
                            'المتبقي : ${(data.remainingAmount ?? 0).toStringAsFixed(2)}',
                            style: pw.TextStyle(font: ttf, fontSize: 10),
                          ),
                          pw.SizedBox(height: 5),
                          pw.Text(
                            'توقيع المستلم :',
                            style: pw.TextStyle(font: ttf, fontSize: 10),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // Right side - QR code
          pw.Container(
            width: 150,
            padding: const pw.EdgeInsets.all(10),
            decoration: const pw.BoxDecoration(
              border: pw.Border(
                left: pw.BorderSide(color: PdfColors.black, width: 1),
              ),
            ),
            child: pw.Center(
              child: pw.BarcodeWidget(
                data: qrData,
                barcode: pw.Barcode.qrCode(),
                width: 130,
                height: 130,
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// Build summary row
  static pw.Widget _buildSummaryRow(
    String label,
    String value,
    pw.Font ttf, {
    bool bold = false,
    double fontSize = 10,
  }) {
    return pw.Padding(
      padding: const pw.EdgeInsets.symmetric(vertical: 2),
      child: pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
        children: [
          pw.Text(
            value,
            style: pw.TextStyle(
              font: ttf,
              fontSize: fontSize,
              fontWeight: bold ? pw.FontWeight.bold : pw.FontWeight.normal,
            ),
          ),
          pw.Text(
            label,
            style: pw.TextStyle(
              font: ttf,
              fontSize: fontSize,
              fontWeight: bold ? pw.FontWeight.bold : pw.FontWeight.normal,
            ),
          ),
        ],
      ),
    );
  }

  // Remove all old methods below this point
}
