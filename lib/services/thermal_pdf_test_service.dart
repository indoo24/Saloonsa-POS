import 'dart:ui' as ui;
import 'package:flutter/services.dart';
import 'package:logger/logger.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import '../models/invoice_data.dart';
import '../widgets/thermal_receipt_image_widget.dart';
import '../helpers/widget_to_image_renderer.dart';

/// Thermal PDF Test Service
///
/// 🎯 PURPOSE: Preview thermal receipt layout on A4 PDF for testing/debugging
///
/// ✅ WHAT THIS DOES:
/// - Renders the SAME thermal receipt widget used in production
/// - Converts it to an image (just like thermal printing)
/// - Embeds the image into an A4 PDF
/// - Opens PDF preview dialog for printing/saving
///
/// ❌ WHAT THIS DOES NOT DO:
/// - Does NOT modify production thermal printing
/// - Does NOT send ESC/POS commands
/// - Does NOT affect real thermal printers
/// - Does NOT duplicate layout logic
///
/// 🔧 USE CASE:
/// - Testing receipt layout without a thermal printer
/// - Validating Arabic text rendering
/// - Debugging spacing and alignment
/// - Preview before printing on thermal
///
/// 🚨 IMPORTANT: This is for TESTING ONLY, not for production receipts
class ThermalPdfTestService {
  static final Logger _logger = Logger();

  /// Paper size constants (same as thermal printing)
  static const double _width58mmPx = 384.0; // 384px for 58mm paper
  static const double _width80mmPx = 576.0; // 576px for 80mm paper
  static const double _pixelRatio = 3.0; // High quality rendering

  /// PDF embedding constants
  /// The receipt appears at approximately the same physical width as thermal paper
  static const double _pdfReceiptWidth58mm = 165.0; // ~58mm on A4 in points
  static const double _pdfReceiptWidth80mm = 220.0; // ~80mm on A4 in points

  /// Preview thermal receipt as A4 PDF
  ///
  /// [data] - The invoice data to preview
  /// [paperSize] - Thermal paper size (58mm or 80mm)
  /// [receiptName] - Optional name for the PDF file
  ///
  /// This method:
  /// 1. Renders the thermal receipt widget to an image
  /// 2. Embeds the image into an A4 PDF
  /// 3. Opens the PDF in the printing dialog
  static Future<void> previewThermalReceiptAsPdf(
    InvoiceData data, {
    ThermalPaperSize paperSize = ThermalPaperSize.mm58,
    String receiptName = 'thermal_receipt_test',
  }) async {
    try {
      _logger.i('[PDF TEST] ═══════════════════════════════════════════');
      _logger.i('[PDF TEST] Generating thermal receipt preview as PDF');
      _logger.i(
        '[PDF TEST] Paper size: ${paperSize == ThermalPaperSize.mm58 ? "58mm" : "80mm"}',
      );
      _logger.i('[PDF TEST] ═══════════════════════════════════════════');

      // Step 1: Render thermal receipt to image (same as production)
      final receiptImage = await _renderThermalReceiptToImage(
        data,
        paperSize: paperSize,
      );

      _logger.i('[PDF TEST] Receipt image rendered successfully');
      _logger.d(
        '[PDF TEST]   - Dimensions: ${receiptImage.width}x${receiptImage.height}px',
      );

      // Step 2: Convert ui.Image to bytes for PDF
      final imageBytes = await _convertImageToBytes(receiptImage);

      _logger.i(
        '[PDF TEST] Image converted to bytes: ${imageBytes.length} bytes',
      );

      // Step 3: Generate A4 PDF with embedded receipt image
      final pdfBytes = await _generatePdfWithThermalReceipt(
        imageBytes,
        paperSize: paperSize,
      );

      _logger.i('[PDF TEST] PDF generated: ${pdfBytes.length} bytes');

      // Step 4: Open PDF preview dialog
      await Printing.layoutPdf(
        name: '$receiptName.pdf',
        onLayout: (_) async => pdfBytes,
      );

      _logger.i('[PDF TEST] ═══════════════════════════════════════════');
      _logger.i('[PDF TEST] PDF preview opened successfully');
      _logger.i('[PDF TEST] ═══════════════════════════════════════════');
    } catch (e, stackTrace) {
      _logger.e(
        '[PDF TEST] ❌ Failed to generate PDF preview',
        error: e,
        stackTrace: stackTrace,
      );
      rethrow;
    }
  }

  /// Render thermal receipt widget to image
  ///
  /// This uses the EXACT SAME widget and rendering process as production thermal printing.
  /// No layout duplication - just reusing the existing ThermalReceiptImageWidget.
  static Future<ui.Image> _renderThermalReceiptToImage(
    InvoiceData data, {
    required ThermalPaperSize paperSize,
  }) async {
    try {
      _logger.i('[PDF TEST] Rendering thermal receipt widget to image');

      // Determine width based on paper size (same as thermal printing)
      final widthPx = paperSize == ThermalPaperSize.mm58
          ? _width58mmPx
          : _width80mmPx;

      // Create the SAME thermal receipt widget used in production
      final receiptWidget = ThermalReceiptImageWidget(
        data: data,
        widthPx: widthPx,
      );

      // Render widget to image (same method as thermal printing)
      final uiImage = await WidgetToImageRenderer.renderWidgetToImage(
        receiptWidget,
        widthPx: widthPx,
        pixelRatio: _pixelRatio,
      );

      _logger.d('[PDF TEST] Widget rendered to image successfully');

      return uiImage;
    } catch (e, stackTrace) {
      _logger.e(
        '[PDF TEST] Failed to render receipt to image',
        error: e,
        stackTrace: stackTrace,
      );
      rethrow;
    }
  }

  /// Convert ui.Image to PNG bytes
  static Future<Uint8List> _convertImageToBytes(ui.Image image) async {
    try {
      final byteData = await image.toByteData(format: ui.ImageByteFormat.png);

      if (byteData == null) {
        throw Exception('Failed to convert image to bytes');
      }

      return byteData.buffer.asUint8List();
    } catch (e, stackTrace) {
      _logger.e(
        '[PDF TEST] Failed to convert image to bytes',
        error: e,
        stackTrace: stackTrace,
      );
      rethrow;
    }
  }

  /// Generate A4 PDF with embedded thermal receipt image
  ///
  /// The receipt image is centered on the A4 page at approximately the same
  /// physical width as the thermal paper (58mm or 80mm).
  static Future<Uint8List> _generatePdfWithThermalReceipt(
    Uint8List imageBytes, {
    required ThermalPaperSize paperSize,
  }) async {
    try {
      _logger.i('[PDF TEST] Generating A4 PDF with thermal receipt');

      final pdf = pw.Document();

      // Determine receipt width on A4 to match thermal paper size
      final receiptWidth = paperSize == ThermalPaperSize.mm58
          ? _pdfReceiptWidth58mm
          : _pdfReceiptWidth80mm;

      pdf.addPage(
        pw.Page(
          pageFormat: PdfPageFormat.a4,
          build: (context) {
            return pw.Center(
              child: pw.Column(
                mainAxisAlignment: pw.MainAxisAlignment.start,
                children: [
                  // Add some top padding
                  pw.SizedBox(height: 40),

                  // Title
                  pw.Text(
                    'Thermal Receipt Preview (${paperSize == ThermalPaperSize.mm58 ? "58mm" : "80mm"})',
                    style: pw.TextStyle(
                      fontSize: 12,
                      fontWeight: pw.FontWeight.bold,
                      color: PdfColors.grey700,
                    ),
                  ),
                  pw.SizedBox(height: 10),
                  pw.Text(
                    'Test Mode - For Preview Only',
                    style: const pw.TextStyle(
                      fontSize: 8,
                      color: PdfColors.grey600,
                    ),
                  ),
                  pw.SizedBox(height: 20),

                  // Receipt image (centered, scaled to match thermal paper width)
                  pw.Container(
                    decoration: pw.BoxDecoration(
                      border: pw.Border.all(color: PdfColors.grey300, width: 1),
                      borderRadius: pw.BorderRadius.circular(4),
                    ),
                    padding: const pw.EdgeInsets.all(2),
                    child: pw.Image(
                      pw.MemoryImage(imageBytes),
                      width: receiptWidth,
                      fit: pw.BoxFit.contain,
                    ),
                  ),

                  pw.SizedBox(height: 20),

                  // Footer note
                  pw.Text(
                    'This is a visual preview of the thermal receipt.',
                    style: const pw.TextStyle(
                      fontSize: 8,
                      color: PdfColors.grey600,
                    ),
                  ),
                  pw.Text(
                    'The actual thermal print will appear identical to this image.',
                    style: const pw.TextStyle(
                      fontSize: 8,
                      color: PdfColors.grey600,
                    ),
                  ),
                ],
              ),
            );
          },
        ),
      );

      _logger.d('[PDF TEST] PDF page created with receipt image');

      return await pdf.save();
    } catch (e, stackTrace) {
      _logger.e(
        '[PDF TEST] Failed to generate PDF',
        error: e,
        stackTrace: stackTrace,
      );
      rethrow;
    }
  }

  /// Save thermal receipt as PDF file (alternative to preview)
  ///
  /// This can be used to save the PDF directly without opening the preview dialog.
  /// Useful for automated testing or batch preview generation.
  static Future<Uint8List> saveThermalReceiptAsPdf(
    InvoiceData data, {
    ThermalPaperSize paperSize = ThermalPaperSize.mm58,
  }) async {
    try {
      _logger.i('[PDF TEST] Saving thermal receipt as PDF');

      // Render thermal receipt to image
      final receiptImage = await _renderThermalReceiptToImage(
        data,
        paperSize: paperSize,
      );

      // Convert to bytes
      final imageBytes = await _convertImageToBytes(receiptImage);

      // Generate PDF
      final pdfBytes = await _generatePdfWithThermalReceipt(
        imageBytes,
        paperSize: paperSize,
      );

      _logger.i('[PDF TEST] PDF saved: ${pdfBytes.length} bytes');

      return pdfBytes;
    } catch (e, stackTrace) {
      _logger.e(
        '[PDF TEST] Failed to save PDF',
        error: e,
        stackTrace: stackTrace,
      );
      rethrow;
    }
  }
}

/// Thermal paper size enum
///
/// This is separate from ESC/POS PaperSize to keep test mode independent.
enum ThermalPaperSize { mm58, mm80 }
