import 'dart:typed_data';
import 'package:flutter/services.dart';
import 'package:image/image.dart' as img;
import 'package:esc_pos_utils_plus/esc_pos_utils_plus.dart';
import 'package:intl/intl.dart';
import 'models/customer.dart';
import 'models/service-model.dart';

/// Enhanced receipt generator that matches the reference image exactly
/// This generates a professional tax invoice with:
/// - Logo at top center
/// - Store info (name, address, phone)
/// - Title: "فاتورة ضريبية مبسطة"
/// - Order info table with borders (Order#, Customer, Date, Cashier, Branch)
/// - Items table with borders (Description, Price, Quantity, Total)
/// - Totals section (Subtotal, Tax, Total)
/// - Thank you message
/// - QR code centered
class ReceiptGenerator {
  static const int PAPER_WIDTH = 48; // 80mm paper = ~48 characters

  /// Generate image-based receipt bytes that match the reference exactly
  /// Now accepts optional tax and discount amounts from API
  /// If not provided, will calculate using default rates (for backward compatibility)
  Future<List<int>> generateReceiptBytes({
    required String orderNumber,
    required Customer? customer,
    required List<ServiceModel> services,
    required double discount, // Can be discount percentage or amount
    required String cashierName,
    required String paymentMethod,
    required String branchName,
    double? paid,
    double? remaining,
    // NEW: API-provided calculated values (preferred)
    double? apiSubtotal,
    double? apiTaxAmount,
    double? apiDiscountAmount,
    double? apiGrandTotal,
  }) async {
    final profile = await CapabilityProfile.load();
    final generator = Generator(PaperSize.mm80, profile);
    List<int> bytes = [];

    // Calculate totals - prefer API values if provided
    // CRITICAL: Correct calculation order per business rules:
    // 1. subtotal_before_tax = sum(service prices)
    // 2. discount_amount = subtotal * discount_percent (discount applied BEFORE tax)
    // 3. amount_after_discount = subtotal - discount_amount
    // 4. tax_amount = amount_after_discount * tax_percent (tax calculated AFTER discount)
    // 5. final_total = amount_after_discount + tax_amount

    final subtotal =
        apiSubtotal ??
        services.fold<double>(0, (sum, item) => sum + item.price);

    // Discount applied to subtotal (BEFORE tax)
    final discountAmount =
        apiDiscountAmount ?? (discount > 0 ? subtotal * (discount / 100) : 0);

    // Amount after discount (before adding tax)
    final amountAfterDiscount = subtotal - discountAmount;

    // Tax calculated on discounted amount (AFTER discount)
    final taxAmount = apiTaxAmount ?? (amountAfterDiscount * 0.15);

    // Grand total = amount after discount + tax
    final grandTotal = apiGrandTotal ?? (amountAfterDiscount + taxAmount);

    print('📄 Receipt Generation (Correct Calculation Order):');
    print('  Using API values: ${apiSubtotal != null}');
    print('  1. Subtotal before tax: $subtotal');
    print('  2. Discount % input: $discount');
    print('  3. Discount amount: $discountAmount');
    print('  4. Amount after discount: $amountAfterDiscount');
    print('  5. Tax (15% on discounted amount): $taxAmount');
    print('  6. Grand Total: $grandTotal');

    try {
      // 1. HEADER SECTION - Logo + Store Info
      await _addHeader(generator, bytes);

      // 2. TITLE - "فاتورة ضريبية مبسطة"
      _addTitle(generator, bytes);

      // 3. ORDER INFO TABLE (with borders)
      _addOrderInfoTable(
        generator,
        bytes,
        orderNumber: orderNumber,
        customer: customer,
        cashierName: cashierName,
        branchName: branchName,
      );

      // 4. ITEMS TABLE (with borders)
      _addItemsTable(generator, bytes, services: services);

      // 5. TOTALS SECTION - use calculated/API values
      _addTotalsSection(
        generator,
        bytes,
        subtotal: subtotal,
        taxAmount: taxAmount,
        finalTotal: grandTotal,
        discount: discountAmount,
        paid: paid,
        remaining: remaining,
        paymentMethod: paymentMethod,
      );

      // 6. FOOTER - Thank you message
      _addFooter(generator, bytes);

      // 7. QR CODE
      _addQRCode(generator, bytes, grandTotal);

      // Feed and cut
      bytes += generator.feed(2);
      bytes += generator.cut();
    } catch (e) {
      print('Error generating receipt: $e');
      // Fallback to simple receipt
      bytes = await _generateFallbackReceipt(
        generator,
        orderNumber,
        customer,
        services,
        cashierName,
        branchName,
        grandTotal,
      );
    }

    return bytes;
  }

  /// Add header with logo and store information
  Future<void> _addHeader(Generator generator, List<int> bytes) async {
    try {
      // Load and print logo
      final ByteData data = await rootBundle.load('assets/images/logo.png');
      final Uint8List logoBytes = data.buffer.asUint8List();
      final img.Image? image = img.decodeImage(logoBytes);

      if (image != null) {
        // Resize logo to fit receipt width (max 380 pixels for 80mm)
        final resizedImage = img.copyResize(image, width: 380);
        bytes += generator.imageRaster(resizedImage, align: PosAlign.center);
        bytes += generator.feed(1);
      }
    } catch (e) {
      print('Could not load logo: $e');
      // Continue without logo
    }

    // Store name
    bytes += generator.text(
      'صالون الشباب',
      styles: const PosStyles(
        align: PosAlign.center,
        bold: true,
        height: PosTextSize.size2,
        width: PosTextSize.size2,
      ),
    );

    // Address
    bytes += generator.text(
      'المدينة المنورة، حي النخيل',
      styles: const PosStyles(
        align: PosAlign.center,
        height: PosTextSize.size1,
      ),
    );

    // Phone
    bytes += generator.text(
      'هاتف: 0565656565',
      styles: const PosStyles(align: PosAlign.center),
    );

    bytes += generator.feed(1);
    bytes += generator.hr(ch: '═', len: PAPER_WIDTH);
    bytes += generator.feed(1);
  }

  /// Add title "فاتورة ضريبية مبسطة"
  void _addTitle(Generator generator, List<int> bytes) {
    bytes += generator.text(
      'فاتورة ضريبية ',
      styles: const PosStyles(
        align: PosAlign.center,
        bold: true,
        height: PosTextSize.size2,
        width: PosTextSize.size1,
      ),
    );
    bytes += generator.feed(1);
    bytes += generator.hr(ch: '═', len: PAPER_WIDTH);
  }

  /// Add order information table with borders (RTL layout)
  void _addOrderInfoTable(
    Generator generator,
    List<int> bytes, {
    required String orderNumber,
    required Customer? customer,
    required String cashierName,
    required String branchName,
  }) {
    bytes += generator.feed(1);

    final dateNow = DateFormat('yyyy-MM-dd HH:mm', 'ar').format(DateTime.now());
    final customerName = customer?.name ?? 'عميل كاش';

    // Table border top
    bytes += generator.text('┌' + '─' * (PAPER_WIDTH - 2) + '┐');

    // Order number
    _addTableRow(generator, bytes, 'رقم الطلب', orderNumber);

    // Customer
    _addTableRow(generator, bytes, 'العميل', customerName);

    // Date
    _addTableRow(generator, bytes, 'التاريخ', dateNow);

    // Cashier
    _addTableRow(generator, bytes, 'الكاشير', cashierName);

    // Branch
    _addTableRow(generator, bytes, 'الفرع', branchName);

    // Table border bottom
    bytes += generator.text('└' + '─' * (PAPER_WIDTH - 2) + '┘');
    bytes += generator.feed(1);
  }

  /// Add a single table row with label and value
  void _addTableRow(
    Generator generator,
    List<int> bytes,
    String label,
    String value,
  ) {
    // Calculate padding
    final contentLength =
        label.length + value.length + 3; // 3 for separators and spaces
    final padding = PAPER_WIDTH - 2 - contentLength; // 2 for borders

    String paddingStr = ' ' * (padding > 0 ? padding : 1);
    String row = '│ $label: $value$paddingStr│';

    // Ensure exact width
    if (row.length > PAPER_WIDTH) {
      row = row.substring(0, PAPER_WIDTH);
    } else if (row.length < PAPER_WIDTH) {
      row = row.padRight(PAPER_WIDTH);
    }

    bytes += generator.text(row);
  }

  /// Add items table with borders and columns
  void _addItemsTable(
    Generator generator,
    List<int> bytes, {
    required List<ServiceModel> services,
  }) {
    bytes += generator.feed(1);

    // Table header border
    bytes += generator.text('┌' + '─' * (PAPER_WIDTH - 2) + '┐');

    // Column headers (RTL: Description | Price | Qty | Total)
    bytes += generator.text(
      _formatItemRow('الوصف', 'السعر', 'الكمية', 'الإجمالي', bold: true),
    );

    bytes += generator.text('├' + '─' * (PAPER_WIDTH - 2) + '┤');

    // Items
    for (final service in services) {
      final price = service.price.toStringAsFixed(2);
      final quantity = '1';
      final total = service.price.toStringAsFixed(2);

      bytes += generator.text(
        _formatItemRow(service.name, price, quantity, total),
      );
    }

    // Table border bottom
    bytes += generator.text('└' + '─' * (PAPER_WIDTH - 2) + '┘');
    bytes += generator.feed(1);
  }

  /// Format a single item row with proper column widths
  String _formatItemRow(
    String desc,
    String price,
    String qty,
    String total, {
    bool bold = false,
  }) {
    // Column widths (adjust based on paper width)
    const descWidth = 20;
    const priceWidth = 8;
    const qtyWidth = 6;
    const totalWidth = 10;

    // Truncate or pad each column
    final descCol = _padOrTruncate(desc, descWidth);
    final priceCol = _padOrTruncate(price, priceWidth, align: TextAlign.right);
    final qtyCol = _padOrTruncate(qty, qtyWidth, align: TextAlign.center);
    final totalCol = _padOrTruncate(total, totalWidth, align: TextAlign.right);

    return '│$descCol│$priceCol│$qtyCol│$totalCol│';
  }

  /// Pad or truncate text to fit column width
  String _padOrTruncate(
    String text,
    int width, {
    TextAlign align = TextAlign.left,
  }) {
    if (text.length > width) {
      return text.substring(0, width);
    }

    final padding = width - text.length;
    switch (align) {
      case TextAlign.right:
        return ' ' * padding + text;
      case TextAlign.center:
        final leftPad = padding ~/ 2;
        final rightPad = padding - leftPad;
        return ' ' * leftPad + text + ' ' * rightPad;
      default:
        return text + ' ' * padding;
    }
  }

  /// Add totals section
  void _addTotalsSection(
    Generator generator,
    List<int> bytes, {
    required double subtotal,
    required double taxAmount,
    required double finalTotal,
    required double discount,
    double? paid,
    double? remaining,
    String? paymentMethod,
  }) {
    bytes += generator.hr(ch: '─', len: PAPER_WIDTH);
    bytes += generator.feed(1);

    // Subtotal Before Tax (if non-zero)
    if (subtotal > 0) {
      bytes += generator.row([
        PosColumn(
          text: 'الإجمالي قبل الضريبة:',
          width: 6,
          styles: const PosStyles(align: PosAlign.left),
        ),
        PosColumn(
          text: '${subtotal.toStringAsFixed(2)} ر.س',
          width: 6,
          styles: const PosStyles(align: PosAlign.right),
        ),
      ]);
    }

    // Tax Amount
    bytes += generator.row([
      PosColumn(
        text: 'ضريبة القيمة المضافة:',
        width: 6,
        styles: const PosStyles(align: PosAlign.left),
      ),
      PosColumn(
        text: '${taxAmount.toStringAsFixed(2)} ر.س',
        width: 6,
        styles: const PosStyles(align: PosAlign.right),
      ),
    ]);

    // Discount Amount if any
    if (discount > 0) {
      bytes += generator.row([
        PosColumn(
          text: 'مبلغ الخصم:',
          width: 6,
          styles: const PosStyles(align: PosAlign.left),
        ),
        PosColumn(
          text: '-${discount.toStringAsFixed(2)} ر.س',
          width: 6,
          styles: const PosStyles(align: PosAlign.right),
        ),
      ]);
    }

    bytes += generator.feed(1);
    bytes += generator.hr(ch: '═', len: PAPER_WIDTH);

    // Total including tax
    bytes += generator.row([
      PosColumn(
        text: 'الإجمالي شامل الضريبة:',
        width: 6,
        styles: const PosStyles(align: PosAlign.left, bold: true),
      ),
      PosColumn(
        text: '${finalTotal.toStringAsFixed(2)} ر.س',
        width: 6,
        styles: const PosStyles(
          align: PosAlign.right,
          bold: true,
          height: PosTextSize.size1,
          width: PosTextSize.size1,
        ),
      ),
    ]);

    bytes += generator.hr(ch: '═', len: PAPER_WIDTH);
    bytes += generator.feed(1);

    // Payment Method
    if (paymentMethod != null && paymentMethod.isNotEmpty) {
      bytes += generator.row([
        PosColumn(
          text: 'طريقة الدفع:',
          width: 6,
          styles: const PosStyles(align: PosAlign.left),
        ),
        PosColumn(
          text: paymentMethod,
          width: 6,
          styles: const PosStyles(align: PosAlign.right),
        ),
      ]);
    }

    // Paid Amount
    if (paid != null) {
      bytes += generator.row([
        PosColumn(
          text: 'المبلغ المدفوع:',
          width: 6,
          styles: const PosStyles(align: PosAlign.left, bold: true),
        ),
        PosColumn(
          text: '${paid.toStringAsFixed(2)} ر.س',
          width: 6,
          styles: const PosStyles(align: PosAlign.right, bold: true),
        ),
      ]);
    }

    // Remaining/Change Amount
    if (remaining != null && remaining != 0) {
      final isChange = remaining < 0;
      final absRemaining = remaining.abs();
      bytes += generator.row([
        PosColumn(
          text: isChange ? 'الباقي (للعميل):' : 'المتبقي:',
          width: 6,
          styles: const PosStyles(align: PosAlign.left, bold: true),
        ),
        PosColumn(
          text: '${absRemaining.toStringAsFixed(2)} ر.س',
          width: 6,
          styles: const PosStyles(align: PosAlign.right, bold: true),
        ),
      ]);
    } else if (paid != null && paid >= finalTotal) {
      // If paid equals or exceeds total, show "مدفوع بالكامل"
      bytes += generator.row([
        PosColumn(
          text: '✓ مدفوع بالكامل',
          width: 12,
          styles: const PosStyles(align: PosAlign.center, bold: true),
        ),
      ]);
    }

    bytes += generator.feed(1);
    bytes += generator.hr(ch: '═', len: PAPER_WIDTH);
  }

  /// Add footer with thank you message
  void _addFooter(Generator generator, List<int> bytes) {
    bytes += generator.feed(1);
    bytes += generator.text(
      'شكراً لزيارتكم',
      styles: const PosStyles(align: PosAlign.center, bold: true),
    );
    bytes += generator.text(
      'نتطلع لرؤيتكم مرة أخرى',
      styles: const PosStyles(align: PosAlign.center),
    );
    bytes += generator.feed(1);
  }

  /// Add QR code centered
  void _addQRCode(Generator generator, List<int> bytes, double total) {
    try {
      // Generate QR with invoice data
      // TLV format for ZATCA (Saudi Arabia)
      final sellerName = 'صالون الشباب';
      final vatNumber = '300000000000003'; // Replace with actual VAT number
      final timestamp = DateFormat(
        'yyyy-MM-dd HH:mm:ss',
      ).format(DateTime.now());
      final totalStr = total.toStringAsFixed(2);
      final taxStr = (total * 0.15 / 1.15).toStringAsFixed(2);

      final qrData =
          'Seller: $sellerName\n'
          'VAT: $vatNumber\n'
          'Time: $timestamp\n'
          'Total: $totalStr SAR\n'
          'Tax: $taxStr SAR';

      bytes += generator.qrcode(qrData);
      bytes += generator.feed(1);
    } catch (e) {
      print('Could not generate QR code: $e');
    }
  }

  /// Fallback simple receipt if image generation fails
  Future<List<int>> _generateFallbackReceipt(
    Generator generator,
    String orderNumber,
    Customer? customer,
    List<ServiceModel> services,
    String cashierName,
    String branchName,
    double total,
  ) async {
    List<int> bytes = [];

    bytes += generator.text(
      'صالون الشباب',
      styles: const PosStyles(
        align: PosAlign.center,
        bold: true,
        height: PosTextSize.size2,
      ),
    );
    bytes += generator.text(
      'فاتورة ضريبية ',
      styles: const PosStyles(align: PosAlign.center, bold: true),
    );
    bytes += generator.hr();
    bytes += generator.text('رقم الطلب: $orderNumber');
    bytes += generator.text('العميل: ${customer?.name ?? "عميل كاش"}');
    bytes += generator.text('الكاشير: $cashierName');
    bytes += generator.hr();

    for (final service in services) {
      bytes += generator.text(
        '${service.name} - ${service.price.toStringAsFixed(2)} ر.س',
      );
    }

    bytes += generator.hr();
    bytes += generator.text(
      'الإجمالي: ${total.toStringAsFixed(2)} ر.س',
      styles: const PosStyles(bold: true, align: PosAlign.right),
    );
    bytes += generator.feed(2);
    bytes += generator.cut();

    return bytes;
  }
}
