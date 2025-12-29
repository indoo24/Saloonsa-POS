import 'dart:ui' as ui;
import 'package:logger/logger.dart';
import 'package:esc_pos_utils_plus/esc_pos_utils_plus.dart';
import 'package:image/image.dart' as img;
import '../models/invoice_data.dart';
import '../widgets/thermal_receipt_image_widget.dart';
import '../helpers/widget_to_image_renderer.dart';

/// Image-Based Thermal Printer
/// 
/// Prints thermal receipts as bitmap/raster images instead of ESC/POS text.
/// This is specifically designed for Sunmi V2 and other printers that
/// DO NOT support Arabic text encoding (CP1256/CP864) but DO support
/// bitmap printing.
/// 
/// Process:
/// 1. Render InvoiceData as a Flutter widget (ThermalReceiptImageWidget)
/// 2. Convert widget to ui.Image off-screen
/// 3. Convert ui.Image to img.Image (from image package)
/// 4. Use ESC/POS imageRaster() to print the bitmap
/// 
/// This ensures Arabic text prints perfectly as part of the image.
class ImageBasedThermalPrinter {
  static final Logger _logger = Logger();

  /// Sunmi V2 specifications
  static const double _sunmiWidthPx = 384.0; // 384px for 58mm paper
  static const double _pixelRatio = 3.0; // High quality for thermal printing
  static const PaperSize _paperSize = PaperSize.mm58;

  /// Generate thermal receipt as image-based ESC/POS bytes
  /// 
  /// [data] - The invoice data to print
  /// [paperSize] - Paper size (default: 58mm for Sunmi V2)
  /// 
  /// Returns ESC/POS bytes ready to send to printer
  static Future<List<int>> generateImageBasedReceipt(
    InvoiceData data, {
    PaperSize paperSize = _paperSize,
  }) async {
    try {
      _logger.i('[PRINT] ═══════════════════════════════════════════');
      _logger.i('[PRINT] Starting IMAGE-BASED thermal receipt generation');
      _logger.i('[PRINT] This method renders Arabic as bitmap image');
      _logger.i('[PRINT] ═══════════════════════════════════════════');

      // Step 1: Create the receipt widget
      _logger.i('[PRINT] Step 1: Creating receipt widget from InvoiceData');
      final receiptWidget = ThermalReceiptImageWidget(data: data);
      _logger.i('[PRINT] ✅ Receipt widget created');

      // Step 2: Render widget to ui.Image
      _logger.i('[PRINT] Step 2: Rendering widget to image (off-screen)');
      _logger.d('[PRINT]   - Width: $_sunmiWidthPx px');
      _logger.d('[PRINT]   - Pixel ratio: $_pixelRatio');
      
      final uiImage = await WidgetToImageRenderer.renderWidgetToImage(
        receiptWidget,
        widthPx: _sunmiWidthPx,
        pixelRatio: _pixelRatio,
      );
      
      _logger.i('[PRINT] ✅ Image rendered: ${uiImage.width}x${uiImage.height}px');

      // Step 3: Convert ui.Image to img.Image (for ESC/POS)
      _logger.i('[PRINT] Step 3: Converting Flutter image to ESC/POS format');
      final imgImage = await _convertUiImageToImgImage(uiImage);
      _logger.i('[PRINT] ✅ Image converted: ${imgImage.width}x${imgImage.height}px');

      // Step 4: Generate ESC/POS bytes with image raster
      _logger.i('[PRINT] Step 4: Generating ESC/POS raster commands');
      final bytes = await _generateEscPosBytes(imgImage, paperSize);
      _logger.i('[PRINT] ✅ ESC/POS bytes generated: ${bytes.length} bytes');

      _logger.i('[PRINT] ═══════════════════════════════════════════');
      _logger.i('[PRINT] ✅ IMAGE-BASED receipt generation COMPLETE');
      _logger.i('[PRINT] Ready to print ${bytes.length} bytes to thermal printer');
      _logger.i('[PRINT] ═══════════════════════════════════════════');

      return bytes;
    } catch (e, stackTrace) {
      _logger.e('[PRINT] ❌ Failed to generate image-based receipt', error: e, stackTrace: stackTrace);
      rethrow;
    }
  }

  /// Convert ui.Image to img.Image (from image package)
  static Future<img.Image> _convertUiImageToImgImage(ui.Image uiImage) async {
    try {
      // Get the raw RGBA bytes from ui.Image
      final byteData = await uiImage.toByteData(format: ui.ImageByteFormat.rawRgba);
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
      _logger.e('[PRINT] Failed to convert ui.Image to img.Image', error: e, stackTrace: stackTrace);
      rethrow;
    }
  }

  /// Generate ESC/POS bytes with image raster
  static Future<List<int>> _generateEscPosBytes(
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

      _logger.d('[PRINT] Added printer initialization');

      // Print image as raster
      _logger.d('[PRINT] Adding image raster command');
      bytes.addAll(generator.imageRaster(image, align: PosAlign.center));

      _logger.d('[PRINT] Image raster command added');

      // Feed paper and cut
      bytes.addAll(generator.feed(3));
      bytes.addAll(generator.cut());

      _logger.d('[PRINT] Added feed and cut commands');

      return bytes;
    } catch (e, stackTrace) {
      _logger.e('[PRINT] Failed to generate ESC/POS bytes', error: e, stackTrace: stackTrace);
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
      _logger.d('[PRINT] Debug image would be saved as $filename (${pngBytes.length} bytes)');
    } catch (e) {
      _logger.w('[PRINT] Failed to save debug image: $e');
    }
  }
}
