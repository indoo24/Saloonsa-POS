import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'dart:ui' as ui;
import '../models/invoice_data.dart';

/// Thermal Receipt Image Widget
/// 
/// Renders InvoiceData as a Flutter widget for off-screen rendering to image.
/// This is specifically designed for image-based thermal printing on Sunmi V2
/// to support Arabic text which the printer cannot render via ESC/POS text commands.
/// 
/// Specifications:
/// - Width: 384px (exact Sunmi V2 thermal printer width for 58mm paper)
/// - RTL layout for Arabic text
/// - Google Fonts Cairo for Arabic rendering
/// - Pure black text on white background for optimal thermal printing
/// - No scrolling (dynamic height wraps content)
/// - Layout matches existing receipt preview exactly
class ThermalReceiptImageWidget extends StatelessWidget {
  final InvoiceData data;

  const ThermalReceiptImageWidget({
    super.key,
    required this.data,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 384, // Sunmi V2 exact width for 58mm thermal paper
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
          
          // 4. EMPLOYEE & SERVICES
          _buildEmployeeSection(),
          const SizedBox(height: 16),
          
          // 5. FINANCIAL DETAILS
          _buildFinancialDetails(),
          const SizedBox(height: 16),
          
          // 6. TOTALS SUMMARY
          _buildTotalsSummary(),
          const SizedBox(height: 16),
          
          // 7. FOOTER
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
        Expanded(
          child: _buildText(label, fontSize: 12, bold: true),
        ),
        Expanded(
          child: _buildText(value, fontSize: 12, textAlign: TextAlign.left),
        ),
      ],
    );
  }

  /// Build employee and services section
  Widget _buildEmployeeSection() {
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
                Expanded(
                  flex: 2,
                  child: _buildText('الخدمة', fontSize: 12, bold: true),
                ),
                Expanded(
                  flex: 1,
                  child: _buildText('الموظف', fontSize: 12, bold: true, textAlign: TextAlign.center),
                ),
                Expanded(
                  flex: 1,
                  child: _buildText('السعر', fontSize: 12, bold: true, textAlign: TextAlign.left),
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
                  Expanded(
                    flex: 2,
                    child: _buildText(item.name, fontSize: 11),
                  ),
                  Expanded(
                    flex: 1,
                    child: _buildText(employeeName, fontSize: 11, textAlign: TextAlign.center),
                  ),
                  Expanded(
                    flex: 1,
                    child: _buildText(
                      'ر.س ${item.price.toStringAsFixed(2)}',
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
          _buildText('تفاصيل المبالغ', fontSize: 14, bold: true, textAlign: TextAlign.center),
          const SizedBox(height: 8),
          
          // Subtotal before discount
          _buildAmountRow(
            'مجموع السلع قبل الخصم',
            data.subtotalBeforeTax,
          ),
          
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
          _buildAmountRow(
            'المجموع',
            data.amountAfterDiscount,
            bold: true,
          ),
          
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
  Widget _buildAmountRow(String label, double amount, {bool bold = false, bool isNegative = false}) {
    final displayAmount = isNegative ? '-ر.س ${amount.toStringAsFixed(2)}' : 'ر.س ${amount.toStringAsFixed(2)}';
    
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Expanded(
          child: _buildText(label, fontSize: 12, bold: bold),
        ),
        _buildText(displayAmount, fontSize: 12, bold: bold),
      ],
    );
  }

  /// Build totals summary section
  Widget _buildTotalsSummary() {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        border: Border.all(color: Colors.black, width: 2),
        borderRadius: BorderRadius.circular(4),
        color: Colors.grey[100],
      ),
      child: Column(
        children: [
          _buildText(
            'اجمالي المبلغ الشامل للضريبة',
            fontSize: 14,
            bold: true,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          _buildText(
            'ر.س ${data.grandTotal.toStringAsFixed(2)}',
            fontSize: 20,
            bold: true,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 12),
          const Divider(color: Colors.black),
          const SizedBox(height: 8),
          
          // Payment method
          _buildInfoRow('طريقة الدفع', data.paymentMethod),
          
          // Payment details
          if (data.paidAmount != null) ...[
            const SizedBox(height: 4),
            _buildInfoRow('المدفوع', 'ر.س ${data.paidAmount!.toStringAsFixed(2)}'),
          ],
          
          if (data.remainingAmount != null && data.remainingAmount! != 0) ...[
            const SizedBox(height: 4),
            _buildInfoRow('الباقي', 'ر.س ${data.remainingAmount!.toStringAsFixed(2)}'),
          ],
        ],
      ),
    );
  }

  /// Build footer section
  Widget _buildFooter() {
    return Column(
      children: [
        if (data.invoiceNotes != null) ...[
          _buildText(
            data.invoiceNotes!,
            fontSize: 10,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
        ],
        _buildText(
          'شكراً لزيارتكم',
          fontSize: 12,
          bold: true,
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 4),
        _buildText(
          'نسعد بخدمتكم',
          fontSize: 10,
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  /// Build text with Cairo font (Arabic support)
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
