import 'dart:typed_data';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:logger/logger.dart';

/// ESC/POS Raster Image Generator
///
/// Generates proper ESC/POS raster commands (GS v 0) for thermal printers.
/// This is the ONLY correct way to print images on generic thermal printers.
///
/// WHY THIS EXISTS:
/// - esc_pos_utils_plus library's imageRaster may produce incompatible output
/// - Some printers (RawBT, generic Bluetooth) need exact format
/// - We need full control over monochrome conversion and raster format
///
/// ESC/POS GS v 0 Command Format:
/// ┌─────────┬─────┬─────┬─────┬─────┬────────────────┐
/// │ 1D 76 30│  m  │ xL  │ xH  │ yL  │ yH  │ [d1...dn]│
/// └─────────┴─────┴─────┴─────┴─────┴────────────────┘
/// - 1D 76 30: GS v 0 command (print raster bit image)
/// - m: Density mode (0 = normal, 1 = double width, 2 = double height, 3 = quadruple)
/// - xL, xH: Number of bytes per line (width / 8), low byte first
/// - yL, yH: Number of lines (height), low byte first
/// - d1...dn: Raster data (each byte = 8 horizontal pixels, MSB first)
///
/// COMPATIBILITY:
/// - Works with RawBT
/// - Works with generic Bluetooth thermal printers
/// - Works with WiFi thermal printers
/// - NO dependency on Sunmi SDK
/// - NO text encoding, pure image printing
class EscPosRasterGenerator {
  static final Logger _logger = Logger();

  /// Standard thermal printer widths in pixels
  static const int width58mm = 384; // 203 DPI, 48mm printable area
  static const int width80mm = 576; // 203 DPI, 72mm printable area

  /// Monochrome threshold (0-255, pixels darker than this become black)
  static const int monochromeThreshold = 127;

  /// Generate ESC/POS raster bytes from a Flutter widget
  ///
  /// This is the main entry point for widget-to-printer conversion.
  ///
  /// [widget] - The Flutter widget to render (e.g., ThermalReceiptWidget)
  /// [paperWidth] - Paper width in pixels (384 for 58mm, 576 for 80mm)
  ///
  /// Returns complete ESC/POS byte sequence ready to send to printer
  static Future<Uint8List> generateFromWidget(
    Widget widget, {
    int paperWidth = width58mm,
  }) async {
    _logger.i('═══════════════════════════════════════════════════════');
    _logger.i('[ESC/POS RASTER] Starting widget-to-raster conversion');
    _logger.i('[ESC/POS RASTER] Paper width: ${paperWidth}px');
    _logger.i('═══════════════════════════════════════════════════════');

    try {
      // Step 1: Render widget to ui.Image at exact paper width
      _logger.i('[STEP 1] Rendering widget to image');
      final uiImage = await _renderWidgetToImage(
        widget,
        widthPx: paperWidth.toDouble(),
      );
      _logger.i(
        '[STEP 1] ✅ Widget rendered: ${uiImage.width}x${uiImage.height}px',
      );

      // Step 2: Convert to RGBA pixel data
      _logger.i('[STEP 2] Converting to pixel data');
      final rgba = await _getPixelData(uiImage);
      _logger.i('[STEP 2] ✅ Pixel data obtained: ${rgba.length} bytes');

      // Step 3: Convert to monochrome bitmap
      _logger.i('[STEP 3] Converting to monochrome');
      final monoBitmap = _convertToMonochrome(
        rgba,
        uiImage.width,
        uiImage.height,
      );
      _logger.i('[STEP 3] ✅ Monochrome bitmap: ${monoBitmap.length} bytes');

      // Step 4: Generate ESC/POS commands
      _logger.i('[STEP 4] Generating ESC/POS commands');
      final escposBytes = _generateEscPosCommands(
        monoBitmap,
        uiImage.width,
        uiImage.height,
      );
      _logger.i('[STEP 4] ✅ ESC/POS commands: ${escposBytes.length} bytes');

      _logger.i('═══════════════════════════════════════════════════════');
      _logger.i('[ESC/POS RASTER] Conversion complete');
      _logger.i('[ESC/POS RASTER] Total bytes: ${escposBytes.length}');
      _logger.i('═══════════════════════════════════════════════════════');

      return escposBytes;
    } catch (e, stackTrace) {
      _logger.e(
        '[ESC/POS RASTER] ❌ Conversion failed',
        error: e,
        stackTrace: stackTrace,
      );
      rethrow;
    }
  }

  /// Render a Flutter widget to ui.Image at EXACT pixel width
  ///
  /// CRITICAL: We use pixelRatio=1.0 to get EXACT pixel dimensions
  /// The widget width IS the output image width
  static Future<ui.Image> _renderWidgetToImage(
    Widget widget, {
    required double widthPx,
  }) async {
    _logger.d('[RENDER] Creating off-screen rendering pipeline');
    _logger.d('[RENDER] Target width: ${widthPx}px, pixelRatio: 1.0');

    // Create a RepaintBoundary to capture the widget
    final repaintBoundary = RenderRepaintBoundary();

    // Build the widget tree with proper constraints
    final renderView = RenderView(
      view: ui.PlatformDispatcher.instance.views.first,
      child: RenderPositionedBox(
        alignment: Alignment.topCenter,
        child: repaintBoundary,
      ),
      configuration: const ViewConfiguration(),
    );

    // Create a PipelineOwner to handle layout
    final pipelineOwner = PipelineOwner()..rootNode = renderView;
    final buildOwner = BuildOwner(focusManager: FocusManager());

    // Prepare the view
    renderView.prepareInitialFrame();

    // Build the widget tree
    // CRITICAL: We use pixelRatio 1.0 here so widget pixels = output pixels
    final rootElement = RenderObjectToWidgetAdapter<RenderBox>(
      container: repaintBoundary,
      child: Directionality(
        textDirection: ui.TextDirection.rtl,
        child: MediaQuery(
          data: MediaQueryData(
            devicePixelRatio: 1.0, // EXACT pixels
            size: Size(widthPx, 10000), // Large height for dynamic content
          ),
          child: Material(
            color: Colors.white,
            child: DefaultTextStyle(
              style: const TextStyle(color: Colors.black),
              child: Container(
                width: widthPx,
                color: Colors.white,
                child: widget,
              ),
            ),
          ),
        ),
      ),
    ).attachToRenderTree(buildOwner);

    _logger.d('[RENDER] Widget tree attached, performing layout');

    // Build and layout the widget
    buildOwner.buildScope(rootElement);
    buildOwner.finalizeTree();

    pipelineOwner.flushLayout();
    pipelineOwner.flushCompositingBits();
    pipelineOwner.flushPaint();

    _logger.d('[RENDER] Layout complete, capturing image');

    // Capture the image at EXACT pixels (pixelRatio 1.0)
    final image = await repaintBoundary.toImage(pixelRatio: 1.0);

    _logger.d('[RENDER] Image captured: ${image.width}x${image.height}px');

    // Clean up
    buildOwner.finalizeTree();

    return image;
  }

  /// Get RGBA pixel data from ui.Image
  static Future<Uint8List> _getPixelData(ui.Image image) async {
    final byteData = await image.toByteData(format: ui.ImageByteFormat.rawRgba);
    if (byteData == null) {
      throw Exception('Failed to get pixel data from image');
    }
    return byteData.buffer.asUint8List();
  }

  /// Convert RGBA pixel data to 1-bit monochrome bitmap
  ///
  /// Each output byte contains 8 horizontal pixels (MSB = leftmost)
  /// Black pixels = 1, White pixels = 0 (thermal printer convention)
  ///
  /// [rgba] - RGBA pixel data (4 bytes per pixel)
  /// [width] - Image width in pixels
  /// [height] - Image height in pixels
  ///
  /// Returns packed 1-bit bitmap (width/8 bytes per row)
  static Uint8List _convertToMonochrome(Uint8List rgba, int width, int height) {
    // Width must be padded to multiple of 8
    final bytesPerRow = (width + 7) ~/ 8;
    final monoData = Uint8List(bytesPerRow * height);

    _logger.d('[MONO] Converting ${width}x${height} image');
    _logger.d('[MONO] Bytes per row: $bytesPerRow');
    _logger.d('[MONO] Total output bytes: ${monoData.length}');

    for (int y = 0; y < height; y++) {
      for (int x = 0; x < width; x++) {
        // Calculate RGBA pixel index (4 bytes per pixel)
        final pixelIndex = (y * width + x) * 4;

        // Get RGB values (ignore alpha)
        final r = rgba[pixelIndex];
        final g = rgba[pixelIndex + 1];
        final b = rgba[pixelIndex + 2];

        // Calculate luminance (standard grayscale conversion)
        // Y = 0.299*R + 0.587*G + 0.114*B
        final luminance = (0.299 * r + 0.587 * g + 0.114 * b).round();

        // Convert to monochrome (1 = black, 0 = white for thermal)
        // Thermal printers print BLACK where bits are SET
        final isBlack = luminance < monochromeThreshold;

        if (isBlack) {
          // Calculate bit position in output byte
          final byteIndex = y * bytesPerRow + (x ~/ 8);
          final bitPosition = 7 - (x % 8); // MSB first

          // Set the bit
          monoData[byteIndex] |= (1 << bitPosition);
        }
      }
    }

    return monoData;
  }

  /// Generate complete ESC/POS command sequence for raster printing
  ///
  /// Includes:
  /// - Printer initialization (ESC @)
  /// - GS v 0 raster image command
  /// - Paper feed
  /// - Paper cut
  static Uint8List _generateEscPosCommands(
    Uint8List rasterData,
    int width,
    int height,
  ) {
    final bytesPerRow = (width + 7) ~/ 8;

    _logger.d('[CMD] Generating ESC/POS commands');
    _logger.d('[CMD] Image: ${width}x${height}px');
    _logger.d('[CMD] Bytes per row: $bytesPerRow');
    _logger.d('[CMD] Raster data: ${rasterData.length} bytes');

    // Calculate total bytes needed
    // ESC @ (2) + GS v 0 header (8) + raster data + feed (3) + cut (3)
    final headerSize = 2 + 8;
    final footerSize = 3 + 3;
    final totalSize = headerSize + rasterData.length + footerSize;

    final bytes = Uint8List(totalSize);
    var offset = 0;

    // ═══════════════════════════════════════════════════════════════════
    // ESC @ - Initialize printer
    // ═══════════════════════════════════════════════════════════════════
    bytes[offset++] = 0x1B; // ESC
    bytes[offset++] = 0x40; // @

    // ═══════════════════════════════════════════════════════════════════
    // GS v 0 - Print raster bit image
    // ═══════════════════════════════════════════════════════════════════
    // Format: 1D 76 30 m xL xH yL yH d1...dk
    bytes[offset++] = 0x1D; // GS
    bytes[offset++] = 0x76; // v
    bytes[offset++] = 0x30; // 0

    // m = 0 (normal density)
    bytes[offset++] = 0x00;

    // xL, xH: bytes per line (little-endian)
    bytes[offset++] = bytesPerRow & 0xFF; // xL
    bytes[offset++] = (bytesPerRow >> 8) & 0xFF; // xH

    // yL, yH: number of lines (little-endian)
    bytes[offset++] = height & 0xFF; // yL
    bytes[offset++] = (height >> 8) & 0xFF; // yH

    // ═══════════════════════════════════════════════════════════════════
    // Raster data (d1...dk)
    // ═══════════════════════════════════════════════════════════════════
    for (int i = 0; i < rasterData.length; i++) {
      bytes[offset++] = rasterData[i];
    }

    // ═══════════════════════════════════════════════════════════════════
    // ESC d n - Feed n lines
    // ═══════════════════════════════════════════════════════════════════
    bytes[offset++] = 0x1B; // ESC
    bytes[offset++] = 0x64; // d
    bytes[offset++] = 0x04; // 4 lines

    // ═══════════════════════════════════════════════════════════════════
    // GS V m - Paper cut
    // ═══════════════════════════════════════════════════════════════════
    bytes[offset++] = 0x1D; // GS
    bytes[offset++] = 0x56; // V
    bytes[offset++] = 0x00; // 0 (full cut)

    _logger.d('[CMD] Total ESC/POS bytes: $offset');

    return bytes;
  }

  /// Generate ESC/POS raster bytes from raw RGBA image data
  ///
  /// Alternative entry point for when you already have image data.
  ///
  /// [rgbaPixels] - RGBA pixel data (4 bytes per pixel)
  /// [width] - Image width in pixels
  /// [height] - Image height in pixels
  static Uint8List generateFromRgba(
    Uint8List rgbaPixels,
    int width,
    int height,
  ) {
    _logger.i('[ESC/POS RASTER] Generating from RGBA data');
    _logger.i('[ESC/POS RASTER] Dimensions: ${width}x${height}');

    // Convert to monochrome
    final monoBitmap = _convertToMonochrome(rgbaPixels, width, height);

    // Generate ESC/POS commands
    return _generateEscPosCommands(monoBitmap, width, height);
  }

  /// Debug helper: Print hex dump of bytes
  static void hexDump(Uint8List bytes, {int maxBytes = 100}) {
    final sb = StringBuffer();
    sb.writeln('Hex dump (first $maxBytes bytes of ${bytes.length}):');

    for (int i = 0; i < bytes.length && i < maxBytes; i++) {
      sb.write('${bytes[i].toRadixString(16).padLeft(2, '0').toUpperCase()} ');
      if ((i + 1) % 16 == 0) sb.writeln();
    }

    _logger.d(sb.toString());
  }
}
