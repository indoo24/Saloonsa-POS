import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:logger/logger.dart';

/// Widget to Image Renderer Utility
///
/// Converts a Flutter widget to a ui.Image off-screen (without displaying it).
/// This is used for image-based thermal printing where Arabic text cannot be
/// rendered via ESC/POS text commands on printers like Sunmi V2.
///
/// The widget is rendered in a RepaintBoundary with specified dimensions,
/// then captured as a bitmap image.
class WidgetToImageRenderer {
  static final Logger _logger = Logger();

  /// Render a widget to a ui.Image off-screen
  ///
  /// [widget] - The widget to render (e.g., ThermalReceiptImageWidget)
  /// [widthPx] - The width in pixels (e.g., 384 for Sunmi V2)
  /// [pixelRatio] - The pixel ratio for rendering (default: 3.0 for high quality on thermal)
  ///
  /// Returns a ui.Image that can be converted to bytes and sent to printer
  static Future<ui.Image> renderWidgetToImage(
    Widget widget, {
    required double widthPx,
    double pixelRatio = 3.0,
  }) async {
    try {
      _logger.i('[PRINT] Starting off-screen widget rendering');
      _logger.d(
        '[PRINT] Render dimensions: width=${widthPx}px, pixelRatio=$pixelRatio',
      );

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
      final rootElement = RenderObjectToWidgetAdapter<RenderBox>(
        container: repaintBoundary,
        child: Directionality(
          textDirection: ui.TextDirection.rtl,
          child: MediaQuery(
            data: MediaQueryData(
              devicePixelRatio: pixelRatio,
              size: Size(
                widthPx / pixelRatio,
                10000,
              ), // Large height for dynamic content
            ),
            child: Material(
              color: Colors.white,
              child: DefaultTextStyle(
                style: const TextStyle(color: Colors.black),
                child: Container(
                  width: widthPx / pixelRatio,
                  color: Colors.white,
                  child: widget,
                ),
              ),
            ),
          ),
        ),
      ).attachToRenderTree(buildOwner);

      _logger.d('[PRINT] Widget tree built, performing layout');

      // Build and layout the widget
      buildOwner.buildScope(rootElement);
      buildOwner.finalizeTree();

      pipelineOwner.flushLayout();
      pipelineOwner.flushCompositingBits();
      pipelineOwner.flushPaint();

      _logger.d('[PRINT] Layout complete, capturing image');

      // Capture the image from the RepaintBoundary
      final image = await repaintBoundary.toImage(pixelRatio: pixelRatio);

      _logger.i(
        '[PRINT] Image captured successfully: ${image.width}x${image.height}px',
      );

      // Clean up
      buildOwner.finalizeTree();

      return image;
    } catch (e, stackTrace) {
      _logger.e(
        '[PRINT] Failed to render widget to image',
        error: e,
        stackTrace: stackTrace,
      );
      rethrow;
    }
  }

  /// Alternative simpler method using GlobalKey (requires widget to be in widget tree)
  /// This is the recommended method when the widget can be temporarily added to the tree
  static Future<ui.Image?> renderWidgetToImageWithKey(
    GlobalKey key, {
    double pixelRatio = 3.0,
  }) async {
    try {
      _logger.i('[PRINT] Rendering widget to image using GlobalKey');

      // Wait a frame to ensure widget is fully built
      await Future.delayed(const Duration(milliseconds: 100));

      // Find the RenderRepaintBoundary
      final RenderRepaintBoundary? boundary =
          key.currentContext?.findRenderObject() as RenderRepaintBoundary?;

      if (boundary == null) {
        _logger.e('[PRINT] Could not find RenderRepaintBoundary from key');
        return null;
      }

      // Capture the image
      final image = await boundary.toImage(pixelRatio: pixelRatio);

      _logger.i('[PRINT] Image captured: ${image.width}x${image.height}px');

      return image;
    } catch (e, stackTrace) {
      _logger.e(
        '[PRINT] Failed to capture image from key',
        error: e,
        stackTrace: stackTrace,
      );
      return null;
    }
  }

  /// Convert ui.Image to PNG bytes
  /// This is useful for debugging or custom image processing
  static Future<List<int>> imageToBytes(ui.Image image) async {
    try {
      _logger.d('[PRINT] Converting image to PNG bytes');

      final byteData = await image.toByteData(format: ui.ImageByteFormat.png);
      if (byteData == null) {
        throw Exception('Failed to convert image to bytes');
      }

      final bytes = byteData.buffer.asUint8List();
      _logger.d('[PRINT] Image converted to ${bytes.length} PNG bytes');

      return bytes;
    } catch (e, stackTrace) {
      _logger.e(
        '[PRINT] Failed to convert image to bytes',
        error: e,
        stackTrace: stackTrace,
      );
      rethrow;
    }
  }
}
