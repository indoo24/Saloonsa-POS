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
import 'package:http/http.dart' as http;
import '../models/invoice_data.dart';

/// ⚠️ DEPRECATED: Use ImageBasedThermalPrinter instead
/// This uses text-based ESC/POS with charset encoding issues
@Deprecated('Use ImageBasedThermalPrinter for reliable Arabic printing')
class ThermalReceiptGenerator {
  /// Generate ESC/POS bytes for thermal printer
  static Future<List<int>> generateThermalReceipt(
    InvoiceData data,
    PaperSize paperSize,
  ) async {
    final profile = await CapabilityProfile.load();
    final generator = Generator(paperSize, profile);
    List<int> bytes = [];

    // Initialize printer
    bytes.addAll([0x1B, 0x40]); // ESC @ - Initialize
    bytes.addAll(generator.reset());

    // 1. HEADER - Logo + Business Info
    await _addHeader(generator, bytes, data);

    // 2. TITLE - "فاتورة ضريبية مبسطة"
    await _addTitle(generator, bytes);

    // 3. ORDER INFO TABLE
    await _addOrderInfoTable(generator, bytes, data);

    // 4. EMPLOYEE SECTION
    await _addEmployeeSection(generator, bytes, data);

    // 5. FINANCIAL DETAILS TABLE
    await _addFinancialTable(generator, bytes, data);

    // 6. TOTALS SUMMARY
    await _addTotalsSummary(generator, bytes, data);

    // 7. QR CODE
    await _addQRCode(generator, bytes, data);

    // Feed and cut
    bytes.addAll(generator.feed(3));
    bytes.addAll(generator.cut());

    return bytes;
  }

  /// Add header with logo and business info
  static Future<void> _addHeader(
    Generator generator,
    List<int> bytes,
    InvoiceData data,
  ) async {
    // Try to load logo
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

        // Decode and resize image
        final img.Image? image = img.decodeImage(logoBytes);
        if (image != null) {
          final resized = img.copyResize(image, width: 200);
          bytes.addAll(generator.imageRaster(resized, align: PosAlign.center));
          bytes.addAll(generator.feed(1));
        }
      } catch (e) {
        print('Could not load logo: $e');
      }
    }

    // Business name and address (right aligned)
    await _addText(bytes, data.businessName, align: PosAlign.right, bold: true);
    await _addText(bytes, data.businessAddress, align: PosAlign.right);
    await _addText(bytes, data.businessPhone, align: PosAlign.right);

    bytes.addAll(generator.feed(1));
  }

  /// Add title - "فاتورة ضريبية مبسطة"
  static Future<void> _addTitle(Generator generator, List<int> bytes) async {
    bytes.addAll(generator.hr(ch: '─'));
    await _addText(
      bytes,
      'فاتورة ضريبية مبسطة',
      align: PosAlign.center,
      bold: true,
    );
    bytes.addAll(generator.hr(ch: '─'));
    bytes.addAll(generator.feed(1));
  }

  /// Add order info table
  static Future<void> _addOrderInfoTable(
    Generator generator,
    List<int> bytes,
    InvoiceData data,
  ) async {
    bytes.addAll(
      generator.text('┌────────────────────────────────────────────┐'),
    );

    // Order number
    await _addTableRow(bytes, 'الفاتورة رقم', data.orderNumber);
    bytes.addAll(
      generator.text('├────────────────────────────────────────────┤'),
    );

    // Customer name
    final customerName = data.customerName ?? 'عميل كاش';
    await _addTableRow(bytes, 'العميل', customerName);
    bytes.addAll(
      generator.text('├────────────────────────────────────────────┤'),
    );

    // Date
    final dateStr = DateFormat('yyyy-MM-dd HH:mm').format(data.dateTime);
    await _addTableRow(bytes, 'التاريخ', dateStr);

    bytes.addAll(
      generator.text('└────────────────────────────────────────────┘'),
    );
    bytes.addAll(generator.feed(1));
  }

  /// Add table row helper (label and value)
  static Future<void> _addTableRow(
    List<int> bytes,
    String label,
    String value,
  ) async {
    final row = '│ $label                 $value                 │';
    await _addText(bytes, row);
  }

  /// Add employee section with services
  static Future<void> _addEmployeeSection(
    Generator generator,
    List<int> bytes,
    InvoiceData data,
  ) async {
    bytes.addAll(
      generator.text('┌────────┬───────────────────────────────────┐'),
    );
    await _addText(bytes, '│ الموظف  │             الخدمة                │');
    bytes.addAll(
      generator.text('╞════════╪═══════════════════════════════════╡'),
    );

    // Items with employee names
    for (final item in data.items) {
      final employeeName = item.employeeName ?? 'موظف';
      final serviceName = item.name;

      // Create row with proper padding
      final empPad = _padRight(employeeName, 7);
      final svcPad = _padRight(serviceName, 33);
      await _addText(bytes, '│ $empPad│ $svcPad  │');
    }

    bytes.addAll(
      generator.text('└────────┴───────────────────────────────────┘'),
    );
    bytes.addAll(generator.feed(1));
  }

  /// Add financial details table
  static Future<void> _addFinancialTable(
    Generator generator,
    List<int> bytes,
    InvoiceData data,
  ) async {
    await _addText(bytes, 'تفاصير المبالغ', align: PosAlign.center, bold: true);
    bytes.addAll(generator.feed(1));

    bytes.addAll(
      generator.text('┌────────────────────────┬───────────────────┐'),
    );
    await _addText(bytes, '│      اسم الحساب        │      المبلغ       │');
    bytes.addAll(
      generator.text('╞════════════════════════╪═══════════════════╡'),
    );

    // Service prices
    for (final item in data.items) {
      final serviceName = _padRight(item.name, 22);
      final price = _padLeft('ر.س ${item.price.toStringAsFixed(2)}', 17);
      await _addText(bytes, '│ $serviceName│ $price │');
    }

    bytes.addAll(
      generator.text('├────────────────────────┼───────────────────┤'),
    );

    // Subtotal before discount
    final subtotal = _padLeft(
      'ر.س ${data.subtotalBeforeTax.toStringAsFixed(2)}',
      17,
    );
    await _addText(bytes, '│ مجموع السلع قبل الخصم  │ $subtotal │');

    bytes.addAll(
      generator.text('├────────────────────────┼───────────────────┤'),
    );

    // Discount (if any)
    if (data.hasDiscount) {
      final discountLabel =
          'الخصم (${data.discountPercentage.toStringAsFixed(0)}%)';
      final discountLabelPad = _padRight(discountLabel, 22);
      final discountAmount = _padLeft(
        'ر.س ${data.discountAmount.toStringAsFixed(2)}',
        17,
      );
      await _addText(bytes, '│ $discountLabelPad│ $discountAmount │');
      bytes.addAll(
        generator.text('├────────────────────────┼───────────────────┤'),
      );
    }

    // Total after discount (المجموع)
    final afterDiscount = _padLeft(
      'ر.س ${data.amountAfterDiscount.toStringAsFixed(2)}',
      17,
    );
    await _addText(bytes, '│ المجموع                │ $afterDiscount │');

    bytes.addAll(
      generator.text('├────────────────────────┼───────────────────┤'),
    );

    // Tax
    final taxLabel = 'الضريبة ${data.taxRate.toStringAsFixed(0)}%';
    final taxLabelPad = _padRight(taxLabel, 22);
    final taxAmount = _padLeft('ر.س ${data.taxAmount.toStringAsFixed(2)}', 17);
    await _addText(bytes, '│ $taxLabelPad│ $taxAmount │');

    bytes.addAll(
      generator.text('└────────────────────────┴───────────────────┘'),
    );
    bytes.addAll(generator.feed(1));
  }

  /// Add totals summary section
  static Future<void> _addTotalsSummary(
    Generator generator,
    List<int> bytes,
    InvoiceData data,
  ) async {
    await _addText(
      bytes,
      'اجمالي المبلغات',
      align: PosAlign.center,
      bold: true,
    );
    bytes.addAll(generator.feed(1));

    // Grand total box
    bytes.addAll(
      generator.text('┌────────────────────────────────────────────┐'),
    );
    await _addText(bytes, '│ اجمالي المبلغ الشامل للضريبة              │');

    final grandTotal = 'ر.س ${data.grandTotal.toStringAsFixed(2)}';
    final grandTotalPad = _padLeft(grandTotal, 20);
    await _addText(bytes, '│         $grandTotalPad          │', bold: true);

    bytes.addAll(
      generator.text('└────────────────────────────────────────────┘'),
    );
    bytes.addAll(generator.feed(1));

    // Payment method and amounts
    bytes.addAll(
      generator.text('┌────────────────────────────────────────────┐'),
    );

    final paymentMethod = _padLeft(data.paymentMethod, 32);
    await _addText(bytes, '│ طريقة الدفع: $paymentMethod│');

    bytes.addAll(
      generator.text('├────────────────────────────────────────────┤'),
    );

    if (data.paidAmount != null) {
      final paid = _padLeft('ر.س ${data.paidAmount!.toStringAsFixed(2)}', 30);
      await _addText(bytes, '│ الرصيد       $paid│');
    }

    bytes.addAll(
      generator.text('└────────────────────────────────────────────┘'),
    );
    bytes.addAll(generator.feed(1));
  }

  /// Add QR code
  static Future<void> _addQRCode(
    Generator generator,
    List<int> bytes,
    InvoiceData data,
  ) async {
    try {
      final timestamp = DateFormat('yyyy-MM-dd HH:mm:ss').format(data.dateTime);
      final qrData =
          'Seller: ${data.businessName}\n'
          'VAT: ${data.taxNumber ?? "N/A"}\n'
          'Time: $timestamp\n'
          'Total: ${data.grandTotal.toStringAsFixed(2)} SAR\n'
          'Tax: ${data.taxAmount.toStringAsFixed(2)} SAR';

      bytes.addAll(generator.qrcode(qrData, align: PosAlign.center));
      bytes.addAll(generator.feed(1));
    } catch (e) {
      print('Could not generate QR code: $e');
    }
  }

  /// Pad text to right
  static String _padRight(String text, int width) {
    if (text.length >= width) return text.substring(0, width);
    return text + ' ' * (width - text.length);
  }

  /// Pad text to left
  static String _padLeft(String text, int width) {
    if (text.length >= width) return text.substring(0, width);
    return ' ' * (width - text.length) + text;
  }

  /// Helper method to safely add text with Arabic support
  static Future<void> _addText(
    List<int> bytes,
    String text, {
    PosAlign align = PosAlign.left,
    bool bold = false,
    PosTextSize height = PosTextSize.size1,
    PosTextSize width = PosTextSize.size1,
  }) async {
    final hasArabic = RegExp(r'[\u0600-\u06FF]').hasMatch(text);

    if (hasArabic) {
      try {
        final encoded = await CharsetConverter.encode('Windows-1256', text);

        if (bold) bytes.addAll([0x1B, 0x45, 0x01]);
        if (height == PosTextSize.size2 || width == PosTextSize.size2) {
          bytes.addAll([0x1D, 0x21, 0x11]);
        }
        if (align == PosAlign.center) bytes.addAll([0x1B, 0x61, 0x01]);
        if (align == PosAlign.right) bytes.addAll([0x1B, 0x61, 0x02]);

        bytes.addAll(encoded);
        bytes.addAll([0x0A]);

        if (bold) bytes.addAll([0x1B, 0x45, 0x00]);
        if (height == PosTextSize.size2 || width == PosTextSize.size2) {
          bytes.addAll([0x1D, 0x21, 0x00]);
        }
        if (align != PosAlign.left) bytes.addAll([0x1B, 0x61, 0x00]);
      } catch (e) {
        print('Error encoding Arabic: $e');
        bytes.addAll(utf8.encode(text));
        bytes.addAll([0x0A]);
      }
    } else {
      // English text - use standard encoding
      if (bold) bytes.addAll([0x1B, 0x45, 0x01]);
      if (height == PosTextSize.size2 || width == PosTextSize.size2) {
        bytes.addAll([0x1D, 0x21, 0x11]);
      }
      if (align == PosAlign.center) bytes.addAll([0x1B, 0x61, 0x01]);
      if (align == PosAlign.right) bytes.addAll([0x1B, 0x61, 0x02]);

      bytes.addAll(utf8.encode(text));
      bytes.addAll([0x0A]);

      if (bold) bytes.addAll([0x1B, 0x45, 0x00]);
      if (height == PosTextSize.size2 || width == PosTextSize.size2) {
        bytes.addAll([0x1D, 0x21, 0x00]);
      }
      if (align != PosAlign.left) bytes.addAll([0x1B, 0x61, 0x00]);
    }
  }
}
