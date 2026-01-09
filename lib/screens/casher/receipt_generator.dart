// ============================================================================
// ⚠️ DEPRECATED FILE - DO NOT USE
// ============================================================================
// This file uses TEXT-BASED ESC/POS printing with charset_converter.
// It has Arabic encoding issues and printer-specific behavior.
//
// REPLACEMENT: Use ImageBasedThermalPrinter instead
// Location: lib/services/image_based_thermal_printer.dart
//
// The new approach renders receipts as images, which:
// - Works on ALL thermal printer brands
// - Has NO Arabic encoding issues
// - Is predictable and stable
// ============================================================================

import 'dart:typed_data';
import 'dart:convert';
import 'package:flutter/services.dart';
import 'package:image/image.dart' as img;
import 'package:esc_pos_utils_plus/esc_pos_utils_plus.dart';
import 'package:intl/intl.dart';
import 'package:charset_converter/charset_converter.dart';
import 'models/customer.dart';
import 'models/service-model.dart';
import '../../models/app_settings.dart';
import '../../models/invoice_data.dart';
import '../../services/settings_service.dart';

/// ⚠️ DEPRECATED: Use ImageBasedThermalPrinter instead
/// This uses text-based ESC/POS with charset encoding issues
@Deprecated('Use ImageBasedThermalPrinter for reliable Arabic printing')
class ReceiptGenerator {
  static const int PAPER_WIDTH = 48; // 80mm paper = ~48 characters
  final SettingsService _settingsService = SettingsService();

  /// Helper method to safely add text with Arabic support
  /// Uses raw bytes encoding for Arabic characters
  Future<void> _addText(
    List<int> bytes,
    String text, {
    PosAlign align = PosAlign.left,
    bool bold = false,
    PosTextSize height = PosTextSize.size1,
    PosTextSize width = PosTextSize.size1,
  }) async {
    // Check if text contains Arabic characters
    final hasArabic = RegExp(r'[\u0600-\u06FF]').hasMatch(text);

    if (hasArabic) {
      try {
        // Encode to Windows-1256 for Arabic support
        final encoded = await CharsetConverter.encode('Windows-1256', text);

        // Add ESC/POS formatting commands
        if (bold) bytes.addAll([0x1B, 0x45, 0x01]); // Bold ON
        if (height == PosTextSize.size2 || width == PosTextSize.size2) {
          bytes.addAll([0x1D, 0x21, 0x11]); // Double size
        }
        if (align == PosAlign.center)
          bytes.addAll([0x1B, 0x61, 0x01]); // Center align
        if (align == PosAlign.right)
          bytes.addAll([0x1B, 0x61, 0x02]); // Right align

        // Add encoded text
        bytes.addAll(encoded);
        bytes.addAll([0x0A]); // Line feed

        // Reset formatting
        if (bold) bytes.addAll([0x1B, 0x45, 0x00]); // Bold OFF
        if (height == PosTextSize.size2 || width == PosTextSize.size2) {
          bytes.addAll([0x1D, 0x21, 0x00]); // Normal size
        }
        if (align != PosAlign.left)
          bytes.addAll([0x1B, 0x61, 0x00]); // Left align
      } catch (e) {
        print('Error encoding Arabic text: $e');
        // Fallback: add text as UTF-8
        bytes.addAll(utf8.encode(text));
        bytes.addAll([0x0A]);
      }
    } else {
      // English text - safe to use directly
      if (bold) bytes.addAll([0x1B, 0x45, 0x01]);
      if (height == PosTextSize.size2 || width == PosTextSize.size2) {
        bytes.addAll([0x1D, 0x21, 0x11]);
      }
      if (align == PosAlign.center) bytes.addAll([0x1B, 0x61, 0x01]);
      if (align == PosAlign.right) bytes.addAll([0x1B, 0x61, 0x02]);

      bytes.addAll(text.codeUnits);
      bytes.addAll([0x0A]);

      if (bold) bytes.addAll([0x1B, 0x45, 0x00]);
      if (height == PosTextSize.size2 || width == PosTextSize.size2) {
        bytes.addAll([0x1D, 0x21, 0x00]);
      }
      if (align != PosAlign.left) bytes.addAll([0x1B, 0x61, 0x00]);
    }
  }

  /// Generate receipt bytes from InvoiceData (matches PDF format exactly)
  /// This is the preferred method that ensures thermal receipt matches PDF preview
  Future<List<int>> generateReceiptBytesFromInvoiceData({
    required InvoiceData data,
  }) async {
    print(
      '📄 Generating thermal receipt from InvoiceData (matches PDF format)',
    );

    final profile = await CapabilityProfile.load();
    final generator = Generator(PaperSize.mm80, profile);
    List<int> bytes = [];

    try {
      // Initialize printer
      bytes.addAll([0x1B, 0x40]); // ESC @ - Initialize printer
      bytes.addAll(generator.reset());

      // 1. LOGO (if available)
      if (data.logoPath != null && data.logoPath!.startsWith('assets/')) {
        try {
          final ByteData logoData = await rootBundle.load(data.logoPath!);
          final Uint8List logoBytes = logoData.buffer.asUint8List();
          final img.Image? image = img.decodeImage(logoBytes);
          if (image != null) {
            // Resize and center logo
            final resized = img.copyResize(image, width: 200);
            bytes.addAll(
              generator.imageRaster(resized, align: PosAlign.center),
            );
            await _addText(bytes, '', align: PosAlign.center); // Spacing
          }
        } catch (e) {
          print('⚠️ Could not load logo: $e');
        }
      }

      // 2. BUSINESS INFO - Centered
      await _addText(
        bytes,
        data.businessName,
        align: PosAlign.center,
        bold: true,
        height: PosTextSize.size2,
        width: PosTextSize.size2,
      );

      await _addText(bytes, data.businessAddress, align: PosAlign.center);
      await _addText(bytes, data.businessPhone, align: PosAlign.center);

      if (data.taxNumber != null && data.taxNumber!.isNotEmpty) {
        await _addText(
          bytes,
          'الرقم الضريبي: ${data.taxNumber}',
          align: PosAlign.center,
        );
      }

      await _addText(bytes, '', align: PosAlign.center); // Spacing

      // 3. TITLE - "فاتورة ضريبية مبسطة"
      await _addText(bytes, '━━━━━━━━━━━━━━━━━━━━━━━━', align: PosAlign.center);
      await _addText(
        bytes,
        'فاتورة ضريبية مبسطة',
        align: PosAlign.center,
        bold: true,
        height: PosTextSize.size2,
      );
      await _addText(bytes, '━━━━━━━━━━━━━━━━━━━━━━━━', align: PosAlign.center);
      await _addText(bytes, '', align: PosAlign.center); // Spacing

      // 4. ORDER INFO TABLE
      final dateFormat = DateFormat('yyyy-MM-dd', 'ar');
      final timeFormat = DateFormat('HH:mm', 'ar');

      await _addText(bytes, '┌────────────────────────────────┐');
      await _addText(
        bytes,
        '│ رقم الفاتورة: ${_padArabic(data.orderNumber, 16)}│',
      );
      await _addText(
        bytes,
        '│ العميل: ${_padArabic(data.customerName ?? 'عميل كاش', 20)}│',
      );
      await _addText(
        bytes,
        '│ التاريخ: ${_padArabic(dateFormat.format(data.dateTime), 20)}│',
      );
      await _addText(
        bytes,
        '│ الوقت: ${_padArabic(timeFormat.format(data.dateTime), 22)}│',
      );
      await _addText(bytes, '│ الكاشير: ${_padArabic(data.cashierName, 20)}│');
      await _addText(bytes, '│ الفرع: ${_padArabic(data.branchName, 22)}│');
      await _addText(bytes, '└────────────────────────────────┘');
      await _addText(bytes, '', align: PosAlign.center); // Spacing

      // 5. ITEMS HEADER
      await _addText(bytes, '┌────────────────────────────────┐');
      await _addText(
        bytes,
        '│         تفاصيل الخدمات          │',
        align: PosAlign.center,
        bold: true,
      );
      await _addText(bytes, '├────────────────────────────────┤');

      // 6. ITEMS TABLE
      for (final item in data.items) {
        String itemName = item.name;
        if (item.employeeName != null) {
          itemName += ' (${item.employeeName})';
        }

        await _addText(bytes, '│ $itemName');

        final priceStr = '${item.price.toStringAsFixed(2)} ر.س';
        final qtyStr = 'الكمية: ${item.quantity}';
        final totalStr = 'المجموع: ${item.total.toStringAsFixed(2)} ر.س';

        await _addText(bytes, '│   $priceStr × $qtyStr');
        await _addText(bytes, '│   $totalStr');
        await _addText(bytes, '├────────────────────────────────┤');
      }

      // 7. TOTALS SECTION
      await _addText(bytes, '│');
      await _addText(
        bytes,
        '│ المجموع الفرعي: ${data.subtotalBeforeTax.toStringAsFixed(2)} ر.س',
        align: PosAlign.right,
      );

      if (data.hasDiscount) {
        await _addText(
          bytes,
          '│ الخصم (${data.discountPercentage.toStringAsFixed(0)}%): -${data.discountAmount.toStringAsFixed(2)} ر.س',
          align: PosAlign.right,
        );
        await _addText(
          bytes,
          '│ بعد الخصم: ${data.amountAfterDiscount.toStringAsFixed(2)} ر.س',
          align: PosAlign.right,
        );
      }

      await _addText(
        bytes,
        '│ ضريبة (${data.taxRate.toStringAsFixed(0)}%): ${data.taxAmount.toStringAsFixed(2)} ر.س',
        align: PosAlign.right,
      );
      await _addText(bytes, '├────────────────────────────────┤');
      await _addText(
        bytes,
        '│ الإجمالي: ${data.grandTotal.toStringAsFixed(2)} ر.س',
        align: PosAlign.right,
        bold: true,
        height: PosTextSize.size2,
      );

      if (data.hasPaymentInfo) {
        await _addText(bytes, '├────────────────────────────────┤');
        await _addText(
          bytes,
          '│ طريقة الدفع: ${data.paymentMethod}',
          align: PosAlign.right,
        );

        if (data.paidAmount != null) {
          await _addText(
            bytes,
            '│ المدفوع: ${data.paidAmount!.toStringAsFixed(2)} ر.س',
            align: PosAlign.right,
          );
        }

        if (data.hasRemaining) {
          final label = data.remainingAmount! > 0 ? 'المتبقي' : 'المرتجع';
          await _addText(
            bytes,
            '│ $label: ${data.remainingAmount!.abs().toStringAsFixed(2)} ر.س',
            align: PosAlign.right,
          );
        }
      }

      await _addText(bytes, '└────────────────────────────────┘');
      await _addText(bytes, '', align: PosAlign.center); // Spacing

      // 8. THANK YOU MESSAGE
      if (data.invoiceNotes != null && data.invoiceNotes!.isNotEmpty) {
        await _addText(bytes, '┌────────────────────────────────┐');
        await _addText(bytes, data.invoiceNotes!, align: PosAlign.center);
        await _addText(bytes, '└────────────────────────────────┘');
        await _addText(bytes, '', align: PosAlign.center); // Spacing
      }

      // 9. QR CODE
      bytes.addAll(
        generator.qrcode(
          'Invoice: ${data.orderNumber}, Total: ${data.grandTotal.toStringAsFixed(2)} SAR',
          align: PosAlign.center,
        ),
      );

      // Feed and cut
      bytes.addAll(generator.feed(2));
      bytes.addAll(generator.cut());

      print('✅ Thermal receipt generated successfully (${bytes.length} bytes)');
      return bytes;
    } catch (e) {
      print('❌ Error generating thermal receipt: $e');
      rethrow;
    }
  }

  /// Helper to pad Arabic text for table alignment
  String _padArabic(String text, int width) {
    if (text.length >= width) return text.substring(0, width);
    return text + ' ' * (width - text.length);
  }

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
    // Load settings to get tax rate and business info
    final settings = await _settingsService.loadSettings();

    final profile = await CapabilityProfile.load();
    // Always use 80mm for thermal printing (ESC/POS doesn't support A4)
    // A4 printing should use PDF generation instead
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

    // Tax calculated on discounted amount (AFTER discount) - USE SETTINGS
    final taxAmount =
        apiTaxAmount ?? (amountAfterDiscount * settings.taxMultiplier);

    // Grand total = amount after discount + tax
    final grandTotal = apiGrandTotal ?? (amountAfterDiscount + taxAmount);

    print('📄 Receipt Generation (Correct Calculation Order):');
    print('  Using API values: ${apiSubtotal != null}');
    print('  Tax rate from settings: ${settings.taxValue}%');
    print('  1. Subtotal before tax: $subtotal');
    print('  2. Discount % input: $discount');
    print('  3. Discount amount: $discountAmount');
    print('  4. Amount after discount: $amountAfterDiscount');
    print('  5. Tax (${settings.taxValue}% on discounted amount): $taxAmount');
    print('  6. Grand Total: $grandTotal');

    try {
      // Initialize printer with ESC/POS commands
      bytes.addAll([0x1B, 0x40]); // ESC @ - Initialize printer
      bytes.addAll(generator.reset());

      // 1. HEADER SECTION - Logo + Store Info (use settings)
      await _addHeader(generator, bytes, settings);

      // 2. TITLE - "فاتورة ضريبية"
      await _addTitle(generator, bytes);

      // 3. ORDER INFO TABLE (with borders)
      await _addOrderInfoTable(
        generator,
        bytes,
        orderNumber: orderNumber,
        customer: customer,
        cashierName: cashierName,
        branchName: branchName,
      );

      // 4. ITEMS TABLE (with borders)
      await _addItemsTable(generator, bytes, services: services);

      // 5. TOTALS SECTION - use calculated/API values
      await _addTotalsSection(
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

      // 6. FOOTER - Thank you message (use settings)
      await _addFooter(generator, bytes, settings);

      // 7. QR CODE
      await _addQRCode(generator, bytes, grandTotal);

      // Feed and cut
      bytes.addAll(generator.feed(2));
      bytes.addAll(generator.cut());
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
  Future<void> _addHeader(
    Generator generator,
    List<int> bytes,
    AppSettings settings,
  ) async {
    try {
      // Load and print logo
      final ByteData data = await rootBundle.load('assets/images/logo.png');
      final Uint8List logoBytes = data.buffer.asUint8List();
      final img.Image? image = img.decodeImage(logoBytes);

      if (image != null) {
        // Resize logo to fit receipt width (max 380 pixels for 80mm)
        final resizedImage = img.copyResize(image, width: 380);
        bytes.addAll(
          generator.imageRaster(resizedImage, align: PosAlign.center),
        );
        bytes.addAll(generator.feed(1));
      }
    } catch (e) {
      print('Could not load logo: $e');
      // Continue without logo
    }

    // Store name - FROM SETTINGS
    await _addText(
      bytes,
      settings.businessName,
      align: PosAlign.center,
      bold: true,
      height: PosTextSize.size2,
      width: PosTextSize.size2,
    );

    // Address - FROM SETTINGS
    await _addText(bytes, settings.address, align: PosAlign.center);

    // Phone - FROM SETTINGS
    await _addText(
      bytes,
      'Tel: ${settings.phoneNumber}',
      align: PosAlign.center,
    );

    // Tax Number - FROM SETTINGS (if provided)
    if (settings.taxNumber.isNotEmpty) {
      await _addText(
        bytes,
        'Tax ID: ${settings.taxNumber}',
        align: PosAlign.center,
      );
    }

    bytes.addAll(generator.feed(1));
    bytes.addAll(generator.hr(ch: '═', len: PAPER_WIDTH));
    bytes.addAll(generator.feed(1));
  }

  /// Add title "فاتورة ضريبية" (Tax Invoice)
  Future<void> _addTitle(Generator generator, List<int> bytes) async {
    await _addText(
      bytes,
      'فاتورة ضريبية',
      align: PosAlign.center,
      bold: true,
      height: PosTextSize.size2,
      width: PosTextSize.size1,
    );
    bytes.addAll(generator.feed(1));
    bytes.addAll(generator.hr(ch: '═', len: PAPER_WIDTH));
  }

  /// Add order information table with borders (RTL layout)
  Future<void> _addOrderInfoTable(
    Generator generator,
    List<int> bytes, {
    required String orderNumber,
    required Customer? customer,
    required String cashierName,
    required String branchName,
  }) async {
    bytes.addAll(generator.feed(1));

    final dateNow = DateFormat('yyyy-MM-dd HH:mm', 'ar').format(DateTime.now());
    final customerName = customer?.name ?? 'عميل كاش'; // Arabic: Cash Customer

    // Table border top
    bytes.addAll(generator.text('┌' + '─' * (PAPER_WIDTH - 2) + '┐'));

    // Order number - Arabic label
    await _addTableRow(generator, bytes, 'رقم الطلب', orderNumber);

    // Customer - Arabic label
    await _addTableRow(generator, bytes, 'العميل', customerName);

    // Date - Arabic label
    await _addTableRow(generator, bytes, 'التاريخ', dateNow);

    // Cashier - Arabic label
    await _addTableRow(generator, bytes, 'الكاشير', cashierName);

    // Branch - Arabic label
    await _addTableRow(generator, bytes, 'الفرع', branchName);

    // Table border bottom
    bytes.addAll(generator.text('└' + '─' * (PAPER_WIDTH - 2) + '┘'));
    bytes.addAll(generator.feed(1));
  }

  /// Add a single table row with label and value
  Future<void> _addTableRow(
    Generator generator,
    List<int> bytes,
    String label,
    String value,
  ) async {
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

    await _addText(bytes, row);
  }

  /// Add items table with borders and columns
  Future<void> _addItemsTable(
    Generator generator,
    List<int> bytes, {
    required List<ServiceModel> services,
  }) async {
    bytes.addAll(generator.feed(1));

    // Table header border
    bytes.addAll(generator.text('┌' + '─' * (PAPER_WIDTH - 2) + '┐'));

    // Column headers (RTL: وصف | السعر | الكمية | المجموع)
    await _addText(
      bytes,
      _formatItemRow('وصف', 'السعر', 'كمية', 'المجموع', bold: true),
      bold: true,
    );

    bytes.addAll(generator.text('├' + '─' * (PAPER_WIDTH - 2) + '┤'));

    // Items
    for (final service in services) {
      final price = service.price.toStringAsFixed(2);
      final quantity = '1';
      final total = service.price.toStringAsFixed(2);

      await _addText(
        bytes,
        _formatItemRow(service.name, price, quantity, total),
      );
    }

    // Table border bottom
    bytes.addAll(generator.text('└' + '─' * (PAPER_WIDTH - 2) + '┘'));
    bytes.addAll(generator.feed(1));
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
  Future<void> _addTotalsSection(
    Generator generator,
    List<int> bytes, {
    required double subtotal,
    required double taxAmount,
    required double finalTotal,
    required double discount,
    double? paid,
    double? remaining,
    String? paymentMethod,
  }) async {
    bytes.addAll(generator.hr(ch: '─', len: PAPER_WIDTH));
    bytes.addAll(generator.feed(1));

    // Subtotal Before Tax (if non-zero)
    if (subtotal > 0) {
      bytes.addAll(
        generator.row([
          PosColumn(
            text: 'المجموع قبل الضريبة:',
            width: 6,
            styles: const PosStyles(align: PosAlign.left),
          ),
          PosColumn(
            text: '${subtotal.toStringAsFixed(2)} SAR',
            width: 6,
            styles: const PosStyles(align: PosAlign.right),
          ),
        ]),
      );
    }

    // Tax Amount
    bytes.addAll(
      generator.row([
        PosColumn(
          text: 'ضريبة القيمة المضافة (15%):',
          width: 6,
          styles: const PosStyles(align: PosAlign.left),
        ),
        PosColumn(
          text: '${taxAmount.toStringAsFixed(2)} SAR',
          width: 6,
          styles: const PosStyles(align: PosAlign.right),
        ),
      ]),
    );

    // Discount Amount if any
    if (discount > 0) {
      bytes.addAll(
        generator.row([
          PosColumn(
            text: 'الخصم:',
            width: 6,
            styles: const PosStyles(align: PosAlign.left),
          ),
          PosColumn(
            text: '-${discount.toStringAsFixed(2)} SAR',
            width: 6,
            styles: const PosStyles(align: PosAlign.right),
          ),
        ]),
      );
    }

    bytes.addAll(generator.feed(1));
    bytes.addAll(generator.hr(ch: '═', len: PAPER_WIDTH));

    // Total including tax
    bytes.addAll(
      generator.row([
        PosColumn(
          text: 'المجموع الكلي (شامل الضريبة):',
          width: 6,
          styles: const PosStyles(align: PosAlign.left, bold: true),
        ),
        PosColumn(
          text: '${finalTotal.toStringAsFixed(2)} SAR',
          width: 6,
          styles: const PosStyles(
            align: PosAlign.right,
            bold: true,
            height: PosTextSize.size1,
            width: PosTextSize.size1,
          ),
        ),
      ]),
    );

    bytes.addAll(generator.hr(ch: '═', len: PAPER_WIDTH));
    bytes.addAll(generator.feed(1));

    // Payment Method
    if (paymentMethod != null && paymentMethod.isNotEmpty) {
      bytes.addAll(
        generator.row([
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
        ]),
      );
    }

    // Paid Amount
    if (paid != null) {
      bytes.addAll(
        generator.row([
          PosColumn(
            text: 'المدفوع:',
            width: 6,
            styles: const PosStyles(align: PosAlign.left, bold: true),
          ),
          PosColumn(
            text: '${paid.toStringAsFixed(2)} SAR',
            width: 6,
            styles: const PosStyles(align: PosAlign.right, bold: true),
          ),
        ]),
      );
    }

    // Remaining/Change Amount
    if (remaining != null && remaining != 0) {
      final isChange = remaining < 0;
      final absRemaining = remaining.abs();
      bytes.addAll(
        generator.row([
          PosColumn(
            text: isChange ? 'الفكة:' : 'المتبقي:',
            width: 6,
            styles: const PosStyles(align: PosAlign.left, bold: true),
          ),
          PosColumn(
            text: '${absRemaining.toStringAsFixed(2)} SAR',
            width: 6,
            styles: const PosStyles(align: PosAlign.right, bold: true),
          ),
        ]),
      );
    } else if (paid != null && paid >= finalTotal) {
      // If paid equals or exceeds total, show "Paid in Full"
      bytes.addAll(
        generator.row([
          PosColumn(
            text: '[OK] تم الدفع بالكامل',
            width: 12,
            styles: const PosStyles(align: PosAlign.center, bold: true),
          ),
        ]),
      );
    }

    bytes.addAll(generator.feed(1));
    bytes.addAll(generator.hr(ch: '═', len: PAPER_WIDTH));
  }

  /// Add footer with thank you message
  Future<void> _addFooter(
    Generator generator,
    List<int> bytes,
    AppSettings settings,
  ) async {
    bytes.addAll(generator.feed(1));

    // Invoice notes from settings
    if (settings.invoiceNotes.isNotEmpty) {
      // Split by newlines if multiline
      final lines = settings.invoiceNotes.split('\n');
      for (var line in lines) {
        if (line.trim().isNotEmpty) {
          await _addText(
            bytes,
            line.trim(),
            align: PosAlign.center,
            bold: true,
          );
        }
      }
    }

    bytes.addAll(generator.feed(1));
  }

  /// Add QR code centered
  Future<void> _addQRCode(
    Generator generator,
    List<int> bytes,
    double total,
  ) async {
    try {
      // Generate QR with invoice data
      // TLV format for ZATCA (Saudi Arabia)
      final sellerName = 'صالون الشباب'; // Arabic: Salon Al-Shabab
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

      bytes.addAll(generator.qrcode(qrData));
      bytes.addAll(generator.feed(1));
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

    await _addText(
      bytes,
      'صالون الشباب', // Salon Al-Shabab in Arabic
      align: PosAlign.center,
      bold: true,
      height: PosTextSize.size2,
    );
    await _addText(bytes, 'فاتورة ضريبية', align: PosAlign.center, bold: true);
    bytes.addAll(generator.hr());
    await _addText(bytes, 'رقم الطلب: $orderNumber');
    await _addText(bytes, 'العميل: ${customer?.name ?? "عميل كاش"}');
    await _addText(bytes, 'الكاشير: $cashierName');
    bytes.addAll(generator.hr());

    for (final service in services) {
      await _addText(
        bytes,
        '${service.name} - ${service.price.toStringAsFixed(2)} SAR',
      );
    }

    bytes.addAll(generator.hr());
    await _addText(
      bytes,
      'المجموع: ${total.toStringAsFixed(2)} SAR',
      bold: true,
      align: PosAlign.right,
    );
    bytes.addAll(generator.feed(2));
    bytes.addAll(generator.cut());

    return bytes;
  }
}
