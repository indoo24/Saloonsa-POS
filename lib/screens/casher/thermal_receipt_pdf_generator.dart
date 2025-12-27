import 'dart:typed_data';
import 'package:flutter/services.dart' show rootBundle;
import 'package:intl/intl.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import '../../models/invoice_data.dart';

/// Generate a PDF for thermal receipt (80mm width)
/// This creates a PDF document that matches thermal receipt format
/// Perfect for preview before actual thermal printing
class ThermalReceiptPdfGenerator {
  // 80mm paper width in points (1mm = 2.83465 points)
  static const double PAPER_WIDTH_MM = 80.0;
  static const double PAPER_WIDTH_POINTS = PAPER_WIDTH_MM * 2.83465;
  
  /// Generate thermal receipt PDF
  /// Returns PDF bytes that can be displayed or printed
  static Future<Uint8List> generateThermalReceiptPdf({
    required InvoiceData data,
  }) async {
    final pdf = pw.Document();

    // Load Arabic font
    final font = await rootBundle.load("assets/fonts/Cairo-Regular.ttf");
    final ttf = pw.Font.ttf(font);
    final boldFont = ttf; // Use same font for bold (Cairo already looks good)

    // Try to load logo (optional)
    pw.MemoryImage? logoImage;
    try {
      if (data.logoPath != null && data.logoPath!.startsWith('assets/')) {
        final logoBytes = await rootBundle.load(data.logoPath!);
        logoImage = pw.MemoryImage(logoBytes.buffer.asUint8List());
      }
    } catch (e) {
      print('⚠️ Could not load logo: $e');
    }

    // Create custom page format for thermal receipt (80mm width, auto height)
    final pageFormat = PdfPageFormat(
      PAPER_WIDTH_POINTS,
      double.infinity, // Auto height based on content
      marginAll: 10,
    );

    pdf.addPage(
      pw.Page(
        pageFormat: pageFormat,
        theme: pw.ThemeData.withFont(base: ttf, bold: boldFont),
        build: (pw.Context context) {
          return pw.Directionality(
            textDirection: pw.TextDirection.rtl,
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.center,
              children: [
                // Logo (if available)
                if (logoImage != null) ...[
                  pw.Image(logoImage, width: 60, height: 60),
                  pw.SizedBox(height: 8),
                ],

                // Business Name
                pw.Text(
                  data.businessName,
                  style: pw.TextStyle(
                    font: boldFont,
                    fontSize: 14,
                    fontWeight: pw.FontWeight.bold,
                  ),
                  textAlign: pw.TextAlign.center,
                ),
                pw.SizedBox(height: 4),

                // Business Address
                pw.Text(
                  data.businessAddress,
                  style: pw.TextStyle(font: ttf, fontSize: 9),
                  textAlign: pw.TextAlign.center,
                ),
                pw.SizedBox(height: 2),

                // Business Phone
                pw.Text(
                  data.businessPhone,
                  style: pw.TextStyle(font: ttf, fontSize: 9),
                  textAlign: pw.TextAlign.center,
                ),
                pw.SizedBox(height: 2),

                // Tax Number (if available)
                if (data.taxNumber != null && data.taxNumber!.isNotEmpty) ...[
                  pw.Text(
                    'الرقم الضريبي: ${data.taxNumber}',
                    style: pw.TextStyle(font: ttf, fontSize: 9),
                    textAlign: pw.TextAlign.center,
                  ),
                  pw.SizedBox(height: 2),
                ],

                pw.SizedBox(height: 8),

                // Title
                pw.Container(
                  width: double.infinity,
                  padding: const pw.EdgeInsets.symmetric(vertical: 6),
                  decoration: pw.BoxDecoration(
                    border: pw.Border.all(width: 1),
                  ),
                  child: pw.Text(
                    'فاتورة ضريبية مبسطة',
                    style: pw.TextStyle(
                      font: boldFont,
                      fontSize: 12,
                      fontWeight: pw.FontWeight.bold,
                    ),
                    textAlign: pw.TextAlign.center,
                  ),
                ),

                pw.SizedBox(height: 8),

                // Order Information Table
                _buildInfoTable(ttf, boldFont, data),

                pw.SizedBox(height: 8),

                // Items Header
                pw.Container(
                  width: double.infinity,
                  padding: const pw.EdgeInsets.all(4),
                  decoration: pw.BoxDecoration(
                    border: pw.Border.all(width: 1),
                    color: PdfColors.grey300,
                  ),
                  child: pw.Text(
                    'تفاصيل الخدمات',
                    style: pw.TextStyle(
                      font: boldFont,
                      fontSize: 10,
                      fontWeight: pw.FontWeight.bold,
                    ),
                    textAlign: pw.TextAlign.center,
                  ),
                ),

                // Items Table
                _buildItemsTable(ttf, boldFont, data),

                pw.SizedBox(height: 8),

                // Totals Section
                _buildTotalsSection(ttf, boldFont, data),

                pw.SizedBox(height: 12),

                // Thank You Message
                if (data.invoiceNotes != null && data.invoiceNotes!.isNotEmpty) ...[
                  pw.Container(
                    width: double.infinity,
                    padding: const pw.EdgeInsets.all(6),
                    decoration: pw.BoxDecoration(
                      border: pw.Border.all(width: 1),
                    ),
                    child: pw.Text(
                      data.invoiceNotes!,
                      style: pw.TextStyle(font: ttf, fontSize: 10),
                      textAlign: pw.TextAlign.center,
                    ),
                  ),
                  pw.SizedBox(height: 8),
                ],

                // QR Code Placeholder
                pw.Container(
                  width: 80,
                  height: 80,
                  decoration: pw.BoxDecoration(
                    border: pw.Border.all(width: 1),
                  ),
                  child: pw.Center(
                    child: pw.Text(
                      'QR Code',
                      style: pw.TextStyle(font: ttf, fontSize: 8),
                    ),
                  ),
                ),

                pw.SizedBox(height: 8),
              ],
            ),
          );
        },
      ),
    );

    return pdf.save();
  }

  /// Build order information table
  static pw.Widget _buildInfoTable(
    pw.Font font,
    pw.Font boldFont,
    InvoiceData data,
  ) {
    final dateFormat = DateFormat('yyyy-MM-dd', 'ar');
    final timeFormat = DateFormat('HH:mm', 'ar');

    return pw.Table(
      border: pw.TableBorder.all(width: 1),
      children: [
        // Invoice Number & Customer
        pw.TableRow(
          children: [
            _buildTableCell('رقم الفاتورة', font, boldFont, isHeader: true),
            _buildTableCell(data.orderNumber, font, boldFont),
            _buildTableCell('العميل', font, boldFont, isHeader: true),
            _buildTableCell(data.customerName ?? 'عميل كاش', font, boldFont),
          ],
        ),
        // Date & Cashier
        pw.TableRow(
          children: [
            _buildTableCell('التاريخ', font, boldFont, isHeader: true),
            _buildTableCell(dateFormat.format(data.dateTime), font, boldFont),
            _buildTableCell('الكاشير', font, boldFont, isHeader: true),
            _buildTableCell(data.cashierName, font, boldFont),
          ],
        ),
        // Time & Branch
        pw.TableRow(
          children: [
            _buildTableCell('الوقت', font, boldFont, isHeader: true),
            _buildTableCell(timeFormat.format(data.dateTime), font, boldFont),
            _buildTableCell('الفرع', font, boldFont, isHeader: true),
            _buildTableCell(data.branchName, font, boldFont),
          ],
        ),
      ],
    );
  }

  /// Build items table
  static pw.Widget _buildItemsTable(
    pw.Font font,
    pw.Font boldFont,
    InvoiceData data,
  ) {
    return pw.Table(
      border: pw.TableBorder.all(width: 1),
      columnWidths: {
        0: const pw.FlexColumnWidth(3), // Description
        1: const pw.FlexColumnWidth(2), // Price
        2: const pw.FlexColumnWidth(1), // Qty
        3: const pw.FlexColumnWidth(2), // Total
      },
      children: [
        // Header
        pw.TableRow(
          decoration: const pw.BoxDecoration(color: PdfColors.grey300),
          children: [
            _buildTableCell('الوصف', font, boldFont, isHeader: true),
            _buildTableCell('السعر', font, boldFont, isHeader: true),
            _buildTableCell('الكمية', font, boldFont, isHeader: true),
            _buildTableCell('المجموع', font, boldFont, isHeader: true),
          ],
        ),
        // Items
        ...data.items.map((item) {
          return pw.TableRow(
            children: [
              _buildTableCell(
                item.employeeName != null
                    ? '${item.name}\n(${item.employeeName})'
                    : item.name,
                font,
                boldFont,
                alignment: pw.TextAlign.right,
              ),
              _buildTableCell(
                '${item.price.toStringAsFixed(2)} ر.س',
                font,
                boldFont,
              ),
              _buildTableCell('${item.quantity}', font, boldFont),
              _buildTableCell(
                '${item.total.toStringAsFixed(2)} ر.س',
                font,
                boldFont,
              ),
            ],
          );
        }).toList(),
      ],
    );
  }

  /// Build totals section
  static pw.Widget _buildTotalsSection(
    pw.Font font,
    pw.Font boldFont,
    InvoiceData data,
  ) {
    return pw.Container(
      width: double.infinity,
      decoration: pw.BoxDecoration(
        border: pw.Border.all(width: 1),
      ),
      child: pw.Column(
        children: [
          // Subtotal
          _buildTotalRow('المجموع الفرعي', data.subtotalBeforeTax, font, boldFont),
          
          // Discount (if any)
          if (data.hasDiscount) ...[
            pw.Divider(height: 1, thickness: 1),
            _buildTotalRow(
              'الخصم (${data.discountPercentage.toStringAsFixed(0)}%)',
              -data.discountAmount,
              font,
              boldFont,
            ),
            pw.Divider(height: 1, thickness: 1),
            _buildTotalRow(
              'المجموع بعد الخصم',
              data.amountAfterDiscount,
              font,
              boldFont,
            ),
          ],
          
          // Tax
          pw.Divider(height: 1, thickness: 1),
          _buildTotalRow(
            'ضريبة القيمة المضافة (${data.taxRate.toStringAsFixed(0)}%)',
            data.taxAmount,
            font,
            boldFont,
          ),
          
          // Grand Total
          pw.Divider(height: 1, thickness: 1),
          _buildTotalRow(
            'الإجمالي الكلي',
            data.grandTotal,
            font,
            boldFont,
            isBold: true,
          ),
          
          // Payment Info (if available)
          if (data.hasPaymentInfo) ...[
            pw.Divider(height: 1, thickness: 1),
            _buildTotalRow('طريقة الدفع', null, font, boldFont,
                valueText: data.paymentMethod),
            if (data.paidAmount != null) ...[
              pw.Divider(height: 1, thickness: 1),
              _buildTotalRow('المبلغ المدفوع', data.paidAmount, font, boldFont),
            ],
            if (data.hasRemaining) ...[
              pw.Divider(height: 1, thickness: 1),
              _buildTotalRow(
                data.remainingAmount! > 0 ? 'المتبقي' : 'المرتجع',
                data.remainingAmount!.abs(),
                font,
                boldFont,
              ),
            ],
          ],
        ],
      ),
    );
  }

  /// Build a table cell
  static pw.Widget _buildTableCell(
    String text,
    pw.Font font,
    pw.Font boldFont, {
    bool isHeader = false,
    pw.TextAlign alignment = pw.TextAlign.center,
  }) {
    return pw.Padding(
      padding: const pw.EdgeInsets.all(4),
      child: pw.Text(
        text,
        style: pw.TextStyle(
          font: isHeader ? boldFont : font,
          fontSize: isHeader ? 9 : 8,
          fontWeight: isHeader ? pw.FontWeight.bold : pw.FontWeight.normal,
        ),
        textAlign: alignment,
      ),
    );
  }

  /// Build a total row
  static pw.Widget _buildTotalRow(
    String label,
    double? value,
    pw.Font font,
    pw.Font boldFont, {
    bool isBold = false,
    String? valueText,
  }) {
    return pw.Padding(
      padding: const pw.EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      child: pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
        children: [
          pw.Expanded(
            child: pw.Text(
              label,
              style: pw.TextStyle(
                font: isBold ? boldFont : font,
                fontSize: isBold ? 10 : 9,
                fontWeight: isBold ? pw.FontWeight.bold : pw.FontWeight.normal,
              ),
              textAlign: pw.TextAlign.right,
            ),
          ),
          pw.Text(
            valueText ?? (value != null ? '${value.toStringAsFixed(2)} ر.س' : ''),
            style: pw.TextStyle(
              font: isBold ? boldFont : font,
              fontSize: isBold ? 10 : 9,
              fontWeight: isBold ? pw.FontWeight.bold : pw.FontWeight.normal,
            ),
          ),
        ],
      ),
    );
  }
}
