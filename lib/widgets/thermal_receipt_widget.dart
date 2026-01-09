import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'dart:ui' as ui;
import '../models/invoice_data.dart';

/// THE SINGLE THERMAL RECEIPT WIDGET (NON-NEGOTIABLE)
///
/// This widget is the ONLY source of truth for receipt rendering.
/// It is used for:
/// 1. On-screen preview (ThermalPreviewScreen)
/// 2. Image-based thermal printing
/// 3. PDF fallback rendering
///
/// ANY VISUAL CHANGE HERE affects all three outputs equally.
///
/// SPECIFICATIONS:
/// - Fixed width: 384px (58mm) or 576px (80mm)
/// - Dynamic height (content-based)
/// - RTL layout for Arabic
/// - White background, black text
/// - NO MediaQuery, NO LayoutBuilder, NO screen-based sizing
/// - NO Expanded/Flexible (explicit sizing only)
/// - NO double.infinity
///
/// This represents the FINAL receipt that will be printed.
class ThermalReceiptWidget extends StatelessWidget {
  final InvoiceData data;
  final double paperWidthPx;

  /// Paper size constants
  static const double width58mm = 384.0;
  static const double width80mm = 576.0;

  const ThermalReceiptWidget({
    super.key,
    required this.data,
    this.paperWidthPx = width58mm,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: paperWidthPx,
      color: Colors.white,
      padding: const EdgeInsets.all(16),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // 1. HEADER - Business Info
          _buildHeader(),
          const SizedBox(height: 16),

          // 2. TITLE - "فاتورة ضريبية مبسطة"
          _buildTitle(),
          const SizedBox(height: 16),

          // 3. ORDER INFO
          _buildOrderInfo(),
          const SizedBox(height: 16),

          // 4. SERVICES TABLE
          _buildServicesTable(),
          const SizedBox(height: 16),

          // 5. FINANCIAL DETAILS
          _buildFinancialDetails(),
          const SizedBox(height: 16),

          // 6. TOTALS SUMMARY (GRAND TOTAL)
          _buildTotalsSummary(),
          const SizedBox(height: 16),

          // 7. PAYMENT INFO
          if (data.hasPaymentInfo) ...[
            _buildPaymentInfo(),
            const SizedBox(height: 16),
          ],

          // 8. FOOTER
          _buildFooter(),
        ],
      ),
    );
  }

  /// Build header with business information
  Widget _buildHeader() {
    return Column(
      children: [
        _buildText(
          data.businessName,
          fontSize: 18,
          bold: true,
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 4),
        _buildText(
          data.businessAddress,
          fontSize: 12,
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 2),
        _buildText(
          data.businessPhone,
          fontSize: 12,
          textAlign: TextAlign.center,
        ),
        if (data.taxNumber != null) ...[
          const SizedBox(height: 2),
          _buildText(
            'الرقم الضريبي: ${data.taxNumber}',
            fontSize: 10,
            textAlign: TextAlign.center,
          ),
        ],
      ],
    );
  }

  /// Build title section
  Widget _buildTitle() {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 8),
      decoration: BoxDecoration(
        border: Border(
          top: BorderSide(color: Colors.black, width: 1),
          bottom: BorderSide(color: Colors.black, width: 1),
        ),
      ),
      child: _buildText(
        'فاتورة ضريبية مبسطة',
        fontSize: 16,
        bold: true,
        textAlign: TextAlign.center,
      ),
    );
  }

  /// Build order information
  Widget _buildOrderInfo() {
    final dateStr = DateFormat('yyyy-MM-dd HH:mm').format(data.dateTime);
    final customerName = data.customerName ?? 'عميل كاش';

    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        border: Border.all(color: Colors.black),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Column(
        children: [
          _buildInfoRow('الفاتورة رقم', data.orderNumber),
          const Divider(color: Colors.black, height: 12),
          _buildInfoRow('العميل', customerName),
          const Divider(color: Colors.black, height: 12),
          _buildInfoRow('التاريخ', dateStr),
          const Divider(color: Colors.black, height: 12),
          _buildInfoRow('الفرع', data.branchName),
          const Divider(color: Colors.black, height: 12),
          _buildInfoRow('الكاشير', data.cashierName),
        ],
      ),
    );
  }

  /// Build info row helper
  Widget _buildInfoRow(String label, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        SizedBox(
          width: (paperWidthPx - 48) / 2,
          child: _buildText(label, fontSize: 12, bold: true),
        ),
        SizedBox(
          width: (paperWidthPx - 48) / 2,
          child: _buildText(value, fontSize: 12, textAlign: TextAlign.left),
        ),
      ],
    );
  }

  /// Build services table
  Widget _buildServicesTable() {
    return Container(
      decoration: BoxDecoration(
        border: Border.all(color: Colors.black),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Column(
        children: [
          // Header
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.grey[200],
              border: Border(bottom: BorderSide(color: Colors.black)),
            ),
            child: Row(
              children: [
                SizedBox(
                  width: (paperWidthPx - 32) * 0.5,
                  child: _buildText('الخدمة', fontSize: 12, bold: true),
                ),
                SizedBox(
                  width: (paperWidthPx - 32) * 0.25,
                  child: _buildText(
                    'الموظف',
                    fontSize: 12,
                    bold: true,
                    textAlign: TextAlign.center,
                  ),
                ),
                SizedBox(
                  width: (paperWidthPx - 32) * 0.25,
                  child: _buildText(
                    'السعر',
                    fontSize: 12,
                    bold: true,
                    textAlign: TextAlign.left,
                  ),
                ),
              ],
            ),
          ),
          // Items
          ...data.items.asMap().entries.map((entry) {
            final index = entry.key;
            final item = entry.value;
            final employeeName = item.employeeName ?? 'موظف';

            return Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                border: index < data.items.length - 1
                    ? Border(bottom: BorderSide(color: Colors.grey[300]!))
                    : null,
              ),
              child: Row(
                children: [
                  SizedBox(
                    width: (paperWidthPx - 32) * 0.5,
                    child: _buildText(item.name, fontSize: 11),
                  ),
                  SizedBox(
                    width: (paperWidthPx - 32) * 0.25,
                    child: _buildText(
                      employeeName,
                      fontSize: 11,
                      textAlign: TextAlign.center,
                    ),
                  ),
                  SizedBox(
                    width: (paperWidthPx - 32) * 0.25,
                    child: _buildText(
                      '${item.price.toStringAsFixed(2)} ر.س',
                      fontSize: 11,
                      textAlign: TextAlign.left,
                    ),
                  ),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }

  /// Build financial details section
  Widget _buildFinancialDetails() {
    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        border: Border.all(color: Colors.black),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Column(
        children: [
          _buildText(
            'تفاصيل المبالغ',
            fontSize: 14,
            bold: true,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),

          // Subtotal before discount
          _buildAmountRow('مجموع السلع قبل الخصم', data.subtotalBeforeTax),

          // Discount (if any)
          if (data.hasDiscount) ...[
            const Divider(color: Colors.black, height: 12),
            _buildAmountRow(
              'الخصم (${data.discountPercentage.toStringAsFixed(0)}%)',
              data.discountAmount,
              isNegative: true,
            ),
          ],

          // Total after discount
          const Divider(color: Colors.black, height: 12),
          _buildAmountRow('المجموع', data.amountAfterDiscount, bold: true),

          // Tax
          const Divider(color: Colors.black, height: 12),
          _buildAmountRow(
            'الضريبة ${data.taxRate.toStringAsFixed(0)}%',
            data.taxAmount,
          ),
        ],
      ),
    );
  }

  /// Build amount row helper
  Widget _buildAmountRow(
    String label,
    double amount, {
    bool bold = false,
    bool isNegative = false,
  }) {
    final displayAmount = isNegative
        ? '-${amount.toStringAsFixed(2)}'
        : amount.toStringAsFixed(2);

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        SizedBox(
          width: (paperWidthPx - 48) * 0.6,
          child: _buildText(label, fontSize: 12, bold: bold),
        ),
        SizedBox(
          width: (paperWidthPx - 48) * 0.4,
          child: _buildText(
            '$displayAmount ر.س',
            fontSize: 12,
            bold: bold,
            textAlign: TextAlign.left,
          ),
        ),
      ],
    );
  }

  /// Build totals summary (Grand Total)
  Widget _buildTotalsSummary() {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.grey[200],
        border: Border.all(color: Colors.black, width: 2),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          SizedBox(
            width: (paperWidthPx - 56) * 0.5,
            child: _buildText('الإجمالي النهائي', fontSize: 16, bold: true),
          ),
          SizedBox(
            width: (paperWidthPx - 56) * 0.5,
            child: _buildText(
              '${data.grandTotal.toStringAsFixed(2)} ر.س',
              fontSize: 16,
              bold: true,
              textAlign: TextAlign.left,
            ),
          ),
        ],
      ),
    );
  }

  /// Build payment information
  Widget _buildPaymentInfo() {
    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        border: Border.all(color: Colors.black),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Column(
        children: [
          _buildText(
            'معلومات الدفع',
            fontSize: 14,
            bold: true,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          _buildAmountRow('طريقة الدفع', 0, bold: true),
          Padding(
            padding: const EdgeInsets.only(top: 4),
            child: _buildText(
              data.paymentMethod,
              fontSize: 12,
              textAlign: TextAlign.center,
            ),
          ),
          if (data.paidAmount != null) ...[
            const Divider(color: Colors.black, height: 12),
            _buildAmountRow('المبلغ المدفوع', data.paidAmount!),
          ],
          if (data.hasRemaining) ...[
            const Divider(color: Colors.black, height: 12),
            _buildAmountRow(
              'المبلغ المتبقي',
              data.remainingAmount!,
              bold: true,
            ),
          ],
          if (data.isPaidInFull) ...[
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.green[100],
                borderRadius: BorderRadius.circular(4),
              ),
              child: _buildText(
                '✓ مدفوع بالكامل',
                fontSize: 12,
                bold: true,
                textAlign: TextAlign.center,
              ),
            ),
          ],
        ],
      ),
    );
  }

  /// Build footer
  Widget _buildFooter() {
    return Column(
      children: [
        Container(height: 1, color: Colors.black),
        const SizedBox(height: 8),
        _buildText(
          'شكراً لزيارتكم',
          fontSize: 14,
          bold: true,
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 4),
        _buildText(
          'نسعد بخدمتكم دائماً',
          fontSize: 12,
          textAlign: TextAlign.center,
        ),
        if (data.invoiceNotes != null && data.invoiceNotes!.isNotEmpty) ...[
          const SizedBox(height: 8),
          Container(height: 1, color: Colors.grey),
          const SizedBox(height: 8),
          _buildText(
            data.invoiceNotes!,
            fontSize: 10,
            textAlign: TextAlign.center,
          ),
        ],
      ],
    );
  }

  /// Build styled text with Arabic font support
  Widget _buildText(
    String text, {
    double fontSize = 12,
    bool bold = false,
    TextAlign textAlign = TextAlign.right,
  }) {
    return Directionality(
      textDirection: ui.TextDirection.rtl,
      child: Text(
        text,
        textAlign: textAlign,
        style: GoogleFonts.cairo(
          fontSize: fontSize,
          fontWeight: bold ? FontWeight.bold : FontWeight.normal,
          color: Colors.black,
          height: 1.3,
        ),
      ),
    );
  }
}
