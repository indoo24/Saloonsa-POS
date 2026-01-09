import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/invoice_data.dart';

/// Thermal Receipt Preview Screen
///
/// This widget renders a visual preview matching the EXACT thermal receipt format.
/// It simulates how the receipt will look when printed on thermal paper.
///
/// IMPORTANT: This is a PREVIEW ONLY, not actual printing.
/// - Matches thermal_receipt_generator.dart format exactly
/// - Supports 58mm and 80mm paper widths
/// - Shows Arabic text correctly
/// - Does NOT require printer connection
class ThermalReceiptPreviewScreen extends StatelessWidget {
  final InvoiceData data;
  final PaperWidth paperWidth;
  final VoidCallback? onPrint;
  final VoidCallback? onClose;

  const ThermalReceiptPreviewScreen({
    Key? key,
    required this.data,
    this.paperWidth = PaperWidth.mm80,
    this.onPrint,
    this.onClose,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('معاينة الفاتورة'),
        backgroundColor: theme.primaryColor,
        actions: [
          if (onPrint != null)
            IconButton(
              icon: const Icon(Icons.print),
              onPressed: onPrint,
              tooltip: 'طباعة',
            ),
        ],
      ),
      body: Container(
        color: Colors.grey[300],
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: _ThermalReceiptWidget(data: data, paperWidth: paperWidth),
          ),
        ),
      ),
      bottomNavigationBar: _buildBottomBar(context),
    );
  }

  Widget _buildBottomBar(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 4,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: OutlinedButton.icon(
              icon: const Icon(Icons.close),
              label: const Text('إغلاق'),
              onPressed: onClose ?? () => Navigator.of(context).pop(),
            ),
          ),
          const SizedBox(width: 12),
          if (onPrint != null)
            Expanded(
              child: ElevatedButton.icon(
                icon: const Icon(Icons.print),
                label: const Text('طباعة'),
                onPressed: onPrint,
              ),
            ),
        ],
      ),
    );
  }
}

/// Internal widget that renders the actual receipt (EXACT thermal format)
class _ThermalReceiptWidget extends StatelessWidget {
  final InvoiceData data;
  final PaperWidth paperWidth;

  const _ThermalReceiptWidget({required this.data, required this.paperWidth});

  @override
  Widget build(BuildContext context) {
    // Paper width in logical pixels
    final width = paperWidth == PaperWidth.mm58 ? 220.0 : 320.0;

    return Container(
      width: width,
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.2),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // 1. Header - Logo + Business Info
            _buildHeader(),
            const SizedBox(height: 8),

            // 2. Title - "فاتورة ضريبية مبسطة"
            _buildTitle(),
            const SizedBox(height: 8),

            // 3. Order Info Table
            _buildOrderInfoTable(),
            const SizedBox(height: 8),

            // 4. Employee Section
            _buildEmployeeSection(),
            const SizedBox(height: 8),

            // 5. Financial Details Table
            _buildFinancialTable(),
            const SizedBox(height: 8),

            // 6. Totals Summary
            _buildTotalsSummary(),
            const SizedBox(height: 8),

            // 7. QR Code
            _buildQRPlaceholder(),

            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.end, // Right-aligned
      children: [
        // Logo placeholder
        if (data.logoPath != null)
          Center(
            child: Container(
              width: 80,
              height: 80,
              margin: const EdgeInsets.only(bottom: 8),
              decoration: BoxDecoration(
                color: Colors.grey[200],
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(Icons.image, size: 40, color: Colors.grey),
            ),
          ),

        // Business name (right-aligned, bold)
        Text(
          data.businessName,
          textAlign: TextAlign.right,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.bold,
            fontFamily: 'monospace',
          ),
        ),

        // Address (right-aligned)
        Text(
          data.businessAddress,
          textAlign: TextAlign.right,
          style: const TextStyle(fontSize: 11, fontFamily: 'monospace'),
        ),

        // Phone (right-aligned)
        Text(
          data.businessPhone,
          textAlign: TextAlign.right,
          style: const TextStyle(fontSize: 11, fontFamily: 'monospace'),
        ),
      ],
    );
  }

  Widget _buildTitle() {
    return Column(
      children: [
        _buildDivider(),
        const SizedBox(height: 4),
        const Text(
          'فاتورة ضريبية مبسطة',
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.bold,
            fontFamily: 'monospace',
          ),
        ),
        const SizedBox(height: 4),
        _buildDivider(),
      ],
    );
  }

  Widget _buildOrderInfoTable() {
    final dateStr = DateFormat('yyyy-MM-dd HH:mm').format(data.dateTime);
    final customerName = data.customerName ?? 'عميل كاش';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _buildBoxLine('┌────────────────────────────────────────────┐'),
        _buildTableRow('الفاتورة رقم', data.orderNumber),
        _buildBoxLine('├────────────────────────────────────────────┤'),
        _buildTableRow('العميل', customerName),
        _buildBoxLine('├────────────────────────────────────────────┤'),
        _buildTableRow('التاريخ', dateStr),
        _buildBoxLine('└────────────────────────────────────────────┘'),
      ],
    );
  }

  Widget _buildEmployeeSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _buildBoxLine('┌────────┬───────────────────────────────────┐'),
        const Text(
          '│ الموظف  │             الخدمة                │',
          style: TextStyle(fontSize: 11, fontFamily: 'monospace'),
        ),
        _buildBoxLine('╞════════╪═══════════════════════════════════╡'),
        ...data.items.map((item) {
          final employeeName = item.employeeName ?? 'موظف';
          final serviceName = item.name;
          return _buildEmployeeRow(employeeName, serviceName);
        }),
        _buildBoxLine('└────────┴───────────────────────────────────┘'),
      ],
    );
  }

  Widget _buildFinancialTable() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const Text(
          'تفاصير المبالغ',
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.bold,
            fontFamily: 'monospace',
          ),
        ),
        const SizedBox(height: 4),
        _buildBoxLine('┌────────────────────────┬───────────────────┐'),
        const Text(
          '│      اسم الحساب        │      المبلغ       │',
          style: TextStyle(fontSize: 11, fontFamily: 'monospace'),
        ),
        _buildBoxLine('╞════════════════════════╪═══════════════════╡'),

        // Service prices
        ...data.items.map(
          (item) => _buildFinancialRow(
            item.name,
            'ر.س ${item.price.toStringAsFixed(2)}',
          ),
        ),

        _buildBoxLine('├────────────────────────┼───────────────────┤'),

        // Subtotal before discount
        _buildFinancialRow(
          'مجموع السلع قبل الخصم',
          'ر.س ${data.subtotalBeforeTax.toStringAsFixed(2)}',
        ),

        _buildBoxLine('├────────────────────────┼───────────────────┤'),

        // Discount (if any)
        if (data.hasDiscount) ...[
          _buildFinancialRow(
            'الخصم (${data.discountPercentage.toStringAsFixed(0)}%)',
            'ر.س ${data.discountAmount.toStringAsFixed(2)}',
          ),
          _buildBoxLine('├────────────────────────┼───────────────────┤'),
        ],

        // Amount after discount
        _buildFinancialRow(
          'المجموع',
          'ر.س ${data.amountAfterDiscount.toStringAsFixed(2)}',
        ),

        _buildBoxLine('├────────────────────────┼───────────────────┤'),

        // Tax
        _buildFinancialRow(
          'الضريبة ${data.taxRate.toStringAsFixed(0)}%',
          'ر.س ${data.taxAmount.toStringAsFixed(2)}',
        ),

        _buildBoxLine('└────────────────────────┴───────────────────┘'),
      ],
    );
  }

  Widget _buildTotalsSummary() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const Text(
          'اجمالي المبلغات',
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.bold,
            fontFamily: 'monospace',
          ),
        ),
        const SizedBox(height: 4),

        // Grand total box
        _buildBoxLine('┌────────────────────────────────────────────┐'),
        const Text(
          '│ اجمالي المبلغ الشامل للضريبة              │',
          style: TextStyle(fontSize: 11, fontFamily: 'monospace'),
        ),
        Text(
          '│         ر.س ${data.grandTotal.toStringAsFixed(2)}          │',
          style: const TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.bold,
            fontFamily: 'monospace',
          ),
        ),
        _buildBoxLine('└────────────────────────────────────────────┘'),

        const SizedBox(height: 4),

        // Payment method and amounts
        _buildBoxLine('┌────────────────────────────────────────────┐'),
        Text(
          '│ طريقة الدفع: ${_padLeft(data.paymentMethod, 32)}│',
          style: const TextStyle(fontSize: 11, fontFamily: 'monospace'),
        ),
        _buildBoxLine('├────────────────────────────────────────────┤'),

        if (data.paidAmount != null)
          Text(
            '│ الرصيد       ${_padLeft('ر.س ${data.paidAmount!.toStringAsFixed(2)}', 30)}│',
            style: const TextStyle(fontSize: 11, fontFamily: 'monospace'),
          ),

        _buildBoxLine('└────────────────────────────────────────────┘'),
      ],
    );
  }

  Widget _buildQRPlaceholder() {
    return Container(
      width: 100,
      height: 100,
      margin: const EdgeInsets.symmetric(vertical: 8),
      decoration: BoxDecoration(
        color: Colors.grey[200],
        border: Border.all(color: Colors.grey),
        borderRadius: BorderRadius.circular(8),
      ),
      child: const Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.qr_code, size: 40, color: Colors.grey),
          SizedBox(height: 4),
          Text('QR Code', style: TextStyle(fontSize: 10, color: Colors.grey)),
        ],
      ),
    );
  }

  // Helper methods
  Widget _buildDivider() {
    return Container(height: 1, color: Colors.black);
  }

  Widget _buildBoxLine(String line) {
    return Text(
      line,
      style: const TextStyle(fontSize: 11, fontFamily: 'monospace'),
    );
  }

  Widget _buildTableRow(String label, String value) {
    return Text(
      '│ $label                 $value                 │',
      style: const TextStyle(fontSize: 11, fontFamily: 'monospace'),
    );
  }

  Widget _buildEmployeeRow(String employee, String service) {
    final empPad = _padRight(employee, 7);
    final svcPad = _padRight(service, 33);
    return Text(
      '│ $empPad│ $svcPad  │',
      style: const TextStyle(fontSize: 11, fontFamily: 'monospace'),
    );
  }

  Widget _buildFinancialRow(String label, String amount) {
    final labelPad = _padRight(label, 22);
    final amountPad = _padLeft(amount, 17);
    return Text(
      '│ $labelPad│ $amountPad │',
      style: const TextStyle(fontSize: 11, fontFamily: 'monospace'),
    );
  }

  String _padRight(String text, int width) {
    if (text.length >= width) return text.substring(0, width);
    return text + ' ' * (width - text.length);
  }

  String _padLeft(String text, int width) {
    if (text.length >= width) return text.substring(0, width);
    return ' ' * (width - text.length) + text;
  }
}

/// Paper width enum for preview
enum PaperWidth { mm58, mm80 }
