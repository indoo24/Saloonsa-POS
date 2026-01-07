import 'dart:ui' as ui;
import 'package:logger/logger.dart';
import 'package:esc_pos_utils_plus/esc_pos_utils_plus.dart';
import 'package:image/image.dart' as img;
import '../models/invoice_data.dart';
import '../widgets/thermal_receipt_widget.dart';
import '../helpers/widget_to_image_renderer.dart';
import 'escpos_raster_generator.dart';

/// Image-Based Thermal Printer
///
/// UNIVERSAL thermal receipt printing using bitmap/raster images.
/// This is the ONLY thermal printing method used in this application.
///
/// WHY IMAGE-BASED PRINTING:
/// - ✅ Arabic text renders perfectly (no encoding issues)
/// - ✅ Works on ALL thermal printer brands (Sunmi, Xprinter, Rongta, Gprinter, etc.)
/// - ✅ No dependency on printer firmware or character sets
/// - ✅ No CP864/CP1256/charset_converter needed
/// - ✅ Predictable, stable, production-ready
///
/// ESC/POS RASTER PROCESS (GS v 0):
/// 1. Render InvoiceData as a Flutter widget (ThermalReceiptWidget - THE SINGLE SOURCE OF TRUTH)
/// 2. Convert widget to ui.Image at EXACT printer pixel width (384px or 576px)
/// 3. Convert to 1-bit monochrome bitmap (thermal printer format)
/// 4. Generate GS v 0 raster command with proper header and data
/// 5. Send to printer via Bluetooth/WiFi
///
/// This treats thermal printers as "dumb image printers" - the most reliable POS strategy.
///
/// COMPATIBILITY:
/// - RawBT (Android Bluetooth printing service)
/// - Generic Bluetooth thermal printers
/// - WiFi thermal printers
/// - Sunmi built-in printers (optional SDK, but ESC/POS works too)
class ImageBasedThermalPrinter {
  static final Logger _logger = Logger();

  /// Generate thermal receipt as ESC/POS raster bytes (GS v 0)
  ///
  /// [data] - The invoice data to print
  /// [paperSize] - Paper size (58mm or 80mm)
  ///
  /// Returns ESC/POS bytes ready to send to printer
  static Future<List<int>> generateImageBasedReceipt(
    InvoiceData data, {
    PaperSize paperSize = PaperSize.mm58,
  }) async {
    try {
      _logger.i('[PRINT] ═══════════════════════════════════════════');
      _logger.i('[PRINT] 🖨️ ESC/POS RASTER IMAGE PRINTING');
      _logger.i(
        '[PRINT] Paper: ${paperSize == PaperSize.mm58 ? "58mm (384px)" : "80mm (576px)"}',
      );
      _logger.i('[PRINT] ═══════════════════════════════════════════');

      // Determine width based on paper size
      final widthPx = paperSize == PaperSize.mm58
          ? EscPosRasterGenerator.width58mm
          : EscPosRasterGenerator.width80mm;

      // Step 1: Create the receipt widget (THE SINGLE SOURCE OF TRUTH)
      _logger.i('[PRINT] [1/2] Creating receipt widget from InvoiceData');
      final receiptWidget = ThermalReceiptWidget(
        data: data,
        paperWidthPx: widthPx.toDouble(),
      );

      // Step 2: Generate ESC/POS raster bytes using our generator
      _logger.i('[PRINT] [2/2] Generating ESC/POS raster commands (GS v 0)');
      final escposBytes = await EscPosRasterGenerator.generateFromWidget(
        receiptWidget,
        paperWidth: widthPx,
      );

      _logger.i('[PRINT] ═══════════════════════════════════════════');
      _logger.i('[PRINT] ✅ ESC/POS generation complete');
      _logger.i('[PRINT] Total bytes: ${escposBytes.length}');
      _logger.i('[PRINT] Format: GS v 0 raster image');
      _logger.i('[PRINT] ═══════════════════════════════════════════');

      return escposBytes.toList();
    } catch (e, stackTrace) {
      _logger.e(
        '[PRINT] ❌ Failed to generate image-based receipt',
        error: e,
        stackTrace: stackTrace,
      );
      rethrow;
    }
  }

  /// Legacy method: Generate receipt using esc_pos_utils_plus library
  ///
  /// This is the OLD approach that may not work with all printers.
  /// Kept for compatibility testing only.
  @Deprecated(
    'Use generateImageBasedReceipt() with EscPosRasterGenerator instead',
  )
  static Future<List<int>> generateImageBasedReceiptLegacy(
    InvoiceData data, {
    PaperSize paperSize = PaperSize.mm58,
  }) async {
    try {
      _logger.w('[PRINT] ⚠️ Using LEGACY esc_pos_utils_plus approach');
      _logger.w('[PRINT] ⚠️ This may not work with RawBT/generic printers');

      // Determine width based on paper size
      final widthPx = paperSize == PaperSize.mm58
          ? ThermalReceiptWidget.width58mm
          : ThermalReceiptWidget.width80mm;

      // Pixel ratio to simulate thermal DPI (203 DPI thermal / 96 DPI screen)
      const pixelRatio = 203 / 96;

      // Step 1: Create the receipt widget
      final receiptWidget = ThermalReceiptWidget(
        data: data,
        paperWidthPx: widthPx,
      );

      // Step 2: Render widget to ui.Image
      final uiImage = await WidgetToImageRenderer.renderWidgetToImage(
        receiptWidget,
        widthPx: widthPx,
        pixelRatio: pixelRatio,
      );

      // Step 3: Convert ui.Image to img.Image (for ESC/POS)
      final imgImage = await _convertUiImageToImgImage(uiImage);

      // Step 4: Generate ESC/POS bytes with image raster (legacy)
      final bytes = await _generateEscPosBytesLegacy(imgImage, paperSize);

      return bytes;
    } catch (e, stackTrace) {
      _logger.e(
        '[PRINT] ❌ Legacy method failed',
        error: e,
        stackTrace: stackTrace,
      );
      rethrow;
    }
  }

  /// Convert ui.Image to img.Image (from image package)
  static Future<img.Image> _convertUiImageToImgImage(ui.Image uiImage) async {
    try {
      // Get the raw RGBA bytes from ui.Image
      final byteData = await uiImage.toByteData(
        format: ui.ImageByteFormat.rawRgba,
      );
      if (byteData == null) {
        throw Exception('Failed to convert ui.Image to bytes');
      }

      final buffer = byteData.buffer.asUint8List();

      // Create img.Image from raw RGBA data
      final imgImage = img.Image.fromBytes(
        width: uiImage.width,
        height: uiImage.height,
        bytes: buffer.buffer,
        order: img.ChannelOrder.rgba,
      );

      // Convert to grayscale for optimal thermal printing
      final grayscale = img.grayscale(imgImage);

      // Apply contrast adjustment for better thermal print quality
      final adjusted = img.adjustColor(
        grayscale,
        contrast: 1.2, // Slightly increase contrast
        brightness: 1.05, // Slightly brighten
      );

      _logger.d('[PRINT] Image converted and optimized for thermal printing');

      return adjusted;
    } catch (e, stackTrace) {
      _logger.e(
        '[PRINT] Failed to convert ui.Image to img.Image',
        error: e,
        stackTrace: stackTrace,
      );
      rethrow;
    }
  }

  /// Generate ESC/POS bytes with image raster (LEGACY - uses esc_pos_utils_plus)
  ///
  /// This is kept for testing/comparison purposes only.
  /// The new EscPosRasterGenerator is preferred.
  static Future<List<int>> _generateEscPosBytesLegacy(
    img.Image image,
    PaperSize paperSize,
  ) async {
    try {
      // Create ESC/POS generator
      final profile = await CapabilityProfile.load();
      final generator = Generator(paperSize, profile);

      List<int> bytes = [];

      // Initialize printer
      bytes.addAll([0x1B, 0x40]); // ESC @ - Initialize
      bytes.addAll(generator.reset());

      // Print image as raster
      bytes.addAll(generator.imageRaster(image, align: PosAlign.center));

      // Feed paper and cut
      bytes.addAll(generator.feed(3));
      bytes.addAll(generator.cut());

      return bytes;
    } catch (e, stackTrace) {
      _logger.e(
        '[PRINT] Failed to generate ESC/POS bytes (legacy)',
        error: e,
        stackTrace: stackTrace,
      );
      rethrow;
    }
  }

  /// Test method to save image to file (for debugging)
  static Future<void> saveDebugImage(ui.Image uiImage, String filename) async {
    try {
      final imgImage = await _convertUiImageToImgImage(uiImage);
      final pngBytes = img.encodePng(imgImage);

      // In production, you would save to file system
      // For now, just log the size
      _logger.d(
        '[PRINT] Debug image would be saved as $filename (${pngBytes.length} bytes)',
      );
    } catch (e) {
      _logger.w('[PRINT] Failed to save debug image: $e');
    }
  }
}
