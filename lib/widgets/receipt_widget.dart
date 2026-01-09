import 'package:flutter/material.dart';
import '../../core/utils/paper_size_helper.dart';
import '../../models/app_settings.dart';
import '../screens/casher/models/customer.dart';
import '../screens/casher/models/service-model.dart';

/// Reusable Receipt Widget that mimics ESC/POS thermal printing
/// Matches exact layout and formatting of thermal printers
class ReceiptWidget extends StatelessWidget {
  final String paperSize;
  final String orderNumber;
  final Customer? customer;
  final List<ServiceModel> services;
  final double discount;
  final String cashierName;
  final String paymentMethod;
  final String branchName;
  final double? paid;
  final double? remaining;
  final AppSettings settings;

  const ReceiptWidget({
    Key? key,
    required this.paperSize,
    required this.orderNumber,
    required this.customer,
    required this.services,
    required this.discount,
    required this.cashierName,
    required this.paymentMethod,
    required this.branchName,
    this.paid,
    this.remaining,
    required this.settings,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final fontSize = PaperSizeHelper.getFontSize(paperSize);

    // Calculate totals
    final subtotal = services.fold<double>(
      0.0,
      (sum, item) => sum + item.price,
    );
    final discountAmount = discount > 0 ? subtotal * (discount / 100) : 0.0;
    final amountAfterDiscount = subtotal - discountAmount;
    final taxAmount = amountAfterDiscount * settings.taxMultiplier;
    final grandTotal = amountAfterDiscount + taxAmount;

    return Container(
      color: Colors.white,
      padding: const EdgeInsets.all(16),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          _buildHeader(fontSize),

          SizedBox(height: fontSize),
          _buildSeparator(
            PaperSizeHelper.generateDoubleSeparator(paperSize),
            fontSize,
          ),
          SizedBox(height: fontSize),

          // Title
          _buildTitle(fontSize),

          SizedBox(height: fontSize),
          _buildSeparator(
            PaperSizeHelper.generateDoubleSeparator(paperSize),
            fontSize,
          ),
          SizedBox(height: fontSize),

          // Order Info
          _buildOrderInfo(fontSize),

          SizedBox(height: fontSize),
          _buildSeparator(
            PaperSizeHelper.generateSeparator(paperSize),
            fontSize,
          ),
          SizedBox(height: fontSize),

          // Items
          _buildItems(fontSize),

          SizedBox(height: fontSize),
          _buildSeparator(
            PaperSizeHelper.generateSeparator(paperSize),
            fontSize,
          ),
          SizedBox(height: fontSize),

          // Totals
          _buildTotals(
            fontSize,
            subtotal,
            taxAmount,
            grandTotal,
            discountAmount,
          ),

          SizedBox(height: fontSize),
          _buildSeparator(
            PaperSizeHelper.generateDoubleSeparator(paperSize),
            fontSize,
          ),
          SizedBox(height: fontSize * 2),

          // Footer
          _buildFooter(fontSize),
        ],
      ),
    );
  }

  Widget _buildHeader(double fontSize) {
    return Column(
      children: [
        _buildCenteredText(settings.businessName, fontSize * 1.5, bold: true),
        SizedBox(height: fontSize * 0.5),
        _buildCenteredText(settings.address, fontSize),
        _buildCenteredText('هاتف: ${settings.phoneNumber}', fontSize),
        if (settings.taxNumber.isNotEmpty)
          _buildCenteredText('الرقم الضريبي: ${settings.taxNumber}', fontSize),
      ],
    );
  }

  Widget _buildTitle(double fontSize) {
    return _buildCenteredText(
      'فاتورة ضريبية مبسطة',
      fontSize * 1.3,
      bold: true,
    );
  }

  Widget _buildOrderInfo(double fontSize) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildInfoRow('رقم الطلب', orderNumber, fontSize),
        _buildInfoRow('العميل', customer?.name ?? 'عميل كاش', fontSize),
        _buildInfoRow(
          'التاريخ',
          DateTime.now().toString().substring(0, 16),
          fontSize,
        ),
        _buildInfoRow('الكاشير', cashierName, fontSize),
        _buildInfoRow('الفرع', branchName, fontSize),
      ],
    );
  }

  Widget _buildInfoRow(String label, String value, double fontSize) {
    final line = PaperSizeHelper.alignLeftRight(
      '$label: $value',
      '',
      paperSize,
    );
    return _buildMonoText(line, fontSize);
  }

  Widget _buildItems(double fontSize) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Header
        _buildMonoText(
          PaperSizeHelper.alignLeftRight('الخدمة', 'السعر', paperSize),
          fontSize,
          bold: true,
        ),
        _buildSeparator(
          PaperSizeHelper.generateSeparator(paperSize, char: '┄'),
          fontSize * 0.8,
        ),
        SizedBox(height: fontSize * 0.5),

        // Items
        ...services.map((service) {
          final priceText = '${service.price.toStringAsFixed(2)} ر.س';
          final line = PaperSizeHelper.alignLeftRight(
            service.name,
            priceText,
            paperSize,
          );
          return Padding(
            padding: EdgeInsets.only(bottom: fontSize * 0.3),
            child: _buildMonoText(line, fontSize),
          );
        }),
      ],
    );
  }

  Widget _buildTotals(
    double fontSize,
    double subtotal,
    double taxAmount,
    double grandTotal,
    double discountAmount,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Subtotal
        _buildTotalRow(
          'الإجمالي قبل الضريبة',
          '${subtotal.toStringAsFixed(2)} ر.س',
          fontSize,
        ),

        // Discount
        if (discountAmount > 0) ...[
          _buildTotalRow(
            'الخصم',
            '-${discountAmount.toStringAsFixed(2)} ر.س',
            fontSize,
          ),
        ],

        // Tax
        _buildTotalRow(
          'ضريبة القيمة المضافة',
          '${taxAmount.toStringAsFixed(2)} ر.س',
          fontSize,
        ),

        SizedBox(height: fontSize * 0.5),
        _buildSeparator(
          PaperSizeHelper.generateDoubleSeparator(paperSize),
          fontSize,
        ),
        SizedBox(height: fontSize * 0.5),

        // Grand Total
        _buildTotalRow(
          'الإجمالي شامل الضريبة',
          '${grandTotal.toStringAsFixed(2)} ر.س',
          fontSize * 1.1,
          bold: true,
        ),

        SizedBox(height: fontSize * 0.5),
        _buildSeparator(
          PaperSizeHelper.generateDoubleSeparator(paperSize),
          fontSize,
        ),
        SizedBox(height: fontSize * 0.5),

        // Payment info
        _buildTotalRow('طريقة الدفع', paymentMethod, fontSize),

        if (paid != null) ...[
          _buildTotalRow(
            'المبلغ المدفوع',
            '${paid!.toStringAsFixed(2)} ر.س',
            fontSize,
            bold: true,
          ),
        ],

        if (remaining != null && remaining != 0)
          Builder(
            builder: (context) {
              final isChange = (remaining ?? 0) < 0;
              final absRemaining = (remaining ?? 0).abs();
              return _buildTotalRow(
                isChange ? 'الباقي (للعميل)' : 'المتبقي',
                '${absRemaining.toStringAsFixed(2)} ر.س',
                fontSize,
                bold: true,
              );
            },
          )
        else if (paid != null && (paid ?? 0) >= grandTotal)
          _buildCenteredText('✓ مدفوع بالكامل', fontSize, bold: true),
      ],
    );
  }

  Widget _buildTotalRow(
    String label,
    String value,
    double fontSize, {
    bool bold = false,
  }) {
    final line = PaperSizeHelper.alignLeftRight(label, value, paperSize);
    return _buildMonoText(line, fontSize, bold: bold);
  }

  Widget _buildFooter(double fontSize) {
    return Column(
      children: [
        if (settings.invoiceNotes.isNotEmpty)
          _buildCenteredText(settings.invoiceNotes, fontSize, bold: true),
        SizedBox(height: fontSize),
        _buildCenteredText('شكراً لزيارتكم', fontSize),
      ],
    );
  }

  Widget _buildCenteredText(String text, double fontSize, {bool bold = false}) {
    final centeredText = PaperSizeHelper.centerText(text, paperSize);
    return _buildMonoText(centeredText, fontSize, bold: bold);
  }

  Widget _buildMonoText(String text, double fontSize, {bool bold = false}) {
    return Text(
      text,
      style: TextStyle(
        fontFamily: 'Courier', // Monospaced font
        fontSize: fontSize,
        fontWeight: bold ? FontWeight.bold : FontWeight.normal,
        height: 1.2,
        letterSpacing: 0,
      ),
    );
  }

  Widget _buildSeparator(String separator, double fontSize) {
    return _buildMonoText(separator, fontSize);
  }
}
