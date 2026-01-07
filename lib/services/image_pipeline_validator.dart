import 'dart:ui' as ui;
import 'package:logger/logger.dart';
import 'package:image/image.dart' as img;

/// ═══════════════════════════════════════════════════════════════════════════
/// IMAGE PIPELINE VALIDATOR
/// ═══════════════════════════════════════════════════════════════════════════
///
/// Validates image data before sending to thermal printer.
/// Ensures images meet thermal printer requirements and won't cause failures.
///
/// VALIDATES:
/// 1. Image dimensions (width matches paper size, height is reasonable)
/// 2. Image format (valid and complete)
/// 3. Image size (not too large for printer buffer)
/// 4. Image can be safely transmitted
///
/// PREVENTS:
/// - Zero or invalid dimensions
/// - Corrupted image data
/// - Buffer overflow on printer
/// - Print failures due to malformed images
///
/// THERMAL PRINTER REQUIREMENTS:
/// - Width: 384px (58mm) or 576px (80mm)
/// - Height: Dynamic, but typically < 10000px
/// - Format: Monochrome/grayscale recommended
/// - Max size: Depends on printer model (typically 2-4MB)
///
/// ═══════════════════════════════════════════════════════════════════════════

class ImagePipelineValidator {
  static final Logger _logger = Logger();

  /// Paper size specifications (pixels)
  static const int width58mm = 384;
  static const int width80mm = 576;

  /// Dimension limits
  static const int minWidth = 200; // Minimum viable width
  static const int maxWidth = 800; // Maximum supported width
  static const int minHeight = 100; // Minimum viable height
  static const int maxHeight = 15000; // Maximum practical height

  /// Size limits
  static const int maxImageSizeBytes = 10 * 1024 * 1024; // 10MB max

  /// ═══════════════════════════════════════════════════════════════════════════
  /// VALIDATE UI.IMAGE FOR THERMAL PRINTING
  /// ═══════════════════════════════════════════════════════════════════════════
  ///
  /// Validates a ui.Image before converting to printer format.
  /// Ensures image meets thermal printer requirements.
  ///
  /// [image] - The rendered Flutter image
  /// [expectedPaperSize] - Expected paper size (58mm or 80mm)
  ///
  /// Returns validation result with specific failure reason if invalid.
  static Future<ImageValidationResult> validateUiImage(
    ui.Image image, {
    required PaperSize expectedPaperSize,
  }) async {
    _logger.i('🔍 [Image Validator] Validating ui.Image for thermal printing');

    final width = image.width;
    final height = image.height;

    _logger.d('  Image dimensions: ${width}x${height}px');
    _logger.d('  Expected paper size: $expectedPaperSize');

    // ═══════════════════════════════════════════════════════════════════════════
    // CHECK 1: Valid Dimensions
    // ═══════════════════════════════════════════════════════════════════════════
    _logger.i('  ├─ Check 1/5: Dimension validity');

    if (width <= 0 || height <= 0) {
      _logger.e('  └─ ❌ FAILED: Invalid dimensions (${width}x${height})');
      return ImageValidationResult.invalidDimensions(width, height);
    }

    _logger.i('  ├─ ✅ Dimensions are positive');

    // ═══════════════════════════════════════════════════════════════════════════
    // CHECK 2: Width Matches Paper Size
    // ═══════════════════════════════════════════════════════════════════════════
    _logger.i('  ├─ Check 2/5: Width matches paper size');

    final expectedWidth = expectedPaperSize == PaperSize.mm58
        ? width58mm
        : width80mm;
    final widthTolerance = 50; // Allow 50px tolerance

    if ((width - expectedWidth).abs() > widthTolerance) {
      _logger.e('  └─ ⚠️ WARNING: Width mismatch');
      _logger.e('      Expected: ${expectedWidth}px (±${widthTolerance}px)');
      _logger.e('      Actual: ${width}px');
      _logger.e('      This may cause distorted printing');

      // This is a warning, not a failure - continue with validation
    } else {
      _logger.i('  ├─ ✅ Width matches expected paper size');
    }

    // ═══════════════════════════════════════════════════════════════════════════
    // CHECK 3: Dimensions Within Limits
    // ═══════════════════════════════════════════════════════════════════════════
    _logger.i('  ├─ Check 3/5: Dimensions within acceptable limits');

    if (width < minWidth || width > maxWidth) {
      _logger.e('  └─ ❌ FAILED: Width out of range');
      _logger.e('      Range: $minWidth - $maxWidth px');
      _logger.e('      Actual: $width px');
      return ImageValidationResult.widthOutOfRange(width, minWidth, maxWidth);
    }

    if (height < minHeight) {
      _logger.e('  └─ ❌ FAILED: Height too small');
      _logger.e('      Minimum: $minHeight px');
      _logger.e('      Actual: $height px');
      return ImageValidationResult.heightTooSmall(height, minHeight);
    }

    if (height > maxHeight) {
      _logger.e('  └─ ❌ FAILED: Height too large');
      _logger.e('      Maximum: $maxHeight px');
      _logger.e('      Actual: $height px');
      _logger.e('      Receipt is too long - consider splitting');
      return ImageValidationResult.heightTooLarge(height, maxHeight);
    }

    _logger.i('  ├─ ✅ Dimensions within acceptable limits');

    // ═══════════════════════════════════════════════════════════════════════════
    // CHECK 4: Estimated Size
    // ═══════════════════════════════════════════════════════════════════════════
    _logger.i('  ├─ Check 4/5: Estimated data size');

    // Estimate size: width * height * 4 bytes (RGBA)
    final estimatedSize = width * height * 4;

    _logger.d(
      '      Estimated RGBA size: ${(estimatedSize / 1024).toStringAsFixed(1)} KB',
    );

    if (estimatedSize > maxImageSizeBytes) {
      _logger.e('  └─ ❌ FAILED: Image too large');
      _logger.e(
        '      Estimated: ${(estimatedSize / 1024 / 1024).toStringAsFixed(1)} MB',
      );
      _logger.e(
        '      Maximum: ${(maxImageSizeBytes / 1024 / 1024).toStringAsFixed(1)} MB',
      );
      return ImageValidationResult.imageTooLarge(
        estimatedSize,
        maxImageSizeBytes,
      );
    }

    _logger.i('  ├─ ✅ Estimated size within limits');

    // ═══════════════════════════════════════════════════════════════════════════
    // CHECK 5: Can Convert to ByteData
    // ═══════════════════════════════════════════════════════════════════════════
    _logger.i('  ├─ Check 5/5: Image can be converted to bytes');

    try {
      final byteData = await image.toByteData(
        format: ui.ImageByteFormat.rawRgba,
      );

      if (byteData == null) {
        _logger.e('  └─ ❌ FAILED: toByteData returned null');
        return ImageValidationResult.conversionFailed();
      }

      final actualSize = byteData.lengthInBytes;
      _logger.d(
        '      Actual size: ${(actualSize / 1024).toStringAsFixed(1)} KB',
      );

      _logger.i('  └─ ✅ Image can be converted successfully');
    } catch (e) {
      _logger.e('  └─ ❌ FAILED: Conversion error: $e');
      return ImageValidationResult.conversionFailed();
    }

    // ═══════════════════════════════════════════════════════════════════════════
    // ALL CHECKS PASSED ✅
    // ═══════════════════════════════════════════════════════════════════════════
    _logger.i('✅ [Image Validator] Image is valid for thermal printing');

    return ImageValidationResult.valid(width, height);
  }

  /// ═══════════════════════════════════════════════════════════════════════════
  /// VALIDATE IMG.IMAGE FOR THERMAL PRINTING
  /// ═══════════════════════════════════════════════════════════════════════════
  ///
  /// Validates an img.Image (from image package) before encoding.
  static ImageValidationResult validateImgImage(img.Image image) {
    _logger.i('🔍 [Image Validator] Validating img.Image');

    final width = image.width;
    final height = image.height;

    _logger.d('  Image dimensions: ${width}x${height}px');

    // Basic dimension checks (same as ui.Image)
    if (width <= 0 || height <= 0) {
      _logger.e('  └─ ❌ FAILED: Invalid dimensions');
      return ImageValidationResult.invalidDimensions(width, height);
    }

    if (width < minWidth || width > maxWidth) {
      _logger.e('  └─ ❌ FAILED: Width out of range');
      return ImageValidationResult.widthOutOfRange(width, minWidth, maxWidth);
    }

    if (height < minHeight || height > maxHeight) {
      _logger.e('  └─ ❌ FAILED: Height out of range');
      if (height < minHeight) {
        return ImageValidationResult.heightTooSmall(height, minHeight);
      } else {
        return ImageValidationResult.heightTooLarge(height, maxHeight);
      }
    }

    _logger.i('  └─ ✅ img.Image is valid');
    return ImageValidationResult.valid(width, height);
  }

  /// ═══════════════════════════════════════════════════════════════════════════
  /// SAFE CHUNKING RECOMMENDATION
  /// ═══════════════════════════════════════════════════════════════════════════
  ///
  /// Determines if image should be split into chunks for transmission.
  /// Very large images may need chunking to avoid printer buffer overflow.
  ///
  /// Returns recommended chunk size in pixels (height), or null if no chunking needed.
  static int? recommendChunkSize(int imageHeight) {
    // Most thermal printers can handle up to 5000px in one go
    const maxChunkHeight = 5000;

    if (imageHeight > maxChunkHeight) {
      _logger.w(
        '📏 [Image Validator] Image height ($imageHeight px) exceeds safe chunk size',
      );
      _logger.w('   Recommendation: Split into chunks of $maxChunkHeight px');
      return maxChunkHeight;
    }

    return null; // No chunking needed
  }
}

// ═══════════════════════════════════════════════════════════════════════════
// IMAGE VALIDATION RESULT
// ═══════════════════════════════════════════════════════════════════════════

class ImageValidationResult {
  final bool isValid;
  final String statusCode;
  final String errorMessage;
  final String guidanceMessage;
  final int? width;
  final int? height;

  const ImageValidationResult({
    required this.isValid,
    required this.statusCode,
    required this.errorMessage,
    required this.guidanceMessage,
    this.width,
    this.height,
  });

  // ═══════════════════════════════════════════════════════════════════════════
  // SUCCESS RESULT
  // ═══════════════════════════════════════════════════════════════════════════

  factory ImageValidationResult.valid(int width, int height) {
    return ImageValidationResult(
      isValid: true,
      statusCode: 'VALID',
      errorMessage: '',
      guidanceMessage: '',
      width: width,
      height: height,
    );
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // FAILURE RESULTS
  // ═══════════════════════════════════════════════════════════════════════════

  factory ImageValidationResult.invalidDimensions(int width, int height) {
    return ImageValidationResult(
      isValid: false,
      statusCode: 'INVALID_DIMENSIONS',
      errorMessage: 'Image has invalid dimensions: ${width}x${height}px',
      guidanceMessage:
          'CRITICAL ERROR: Image dimensions are invalid.\n'
          'Width and height must be positive integers.\n\n'
          'This indicates a widget rendering failure.',
      width: width,
      height: height,
    );
  }

  factory ImageValidationResult.widthOutOfRange(
    int width,
    int minWidth,
    int maxWidth,
  ) {
    return ImageValidationResult(
      isValid: false,
      statusCode: 'WIDTH_OUT_OF_RANGE',
      errorMessage: 'Image width out of range: $width px',
      guidanceMessage:
          'Image width must be between $minWidth and $maxWidth pixels.\n'
          'Actual: $width px\n\n'
          'For thermal printers:\n'
          '  - 58mm paper: 384px width\n'
          '  - 80mm paper: 576px width\n\n'
          'Check paper size configuration in PrinterSettings.',
      width: width,
    );
  }

  factory ImageValidationResult.heightTooSmall(int height, int minHeight) {
    return ImageValidationResult(
      isValid: false,
      statusCode: 'HEIGHT_TOO_SMALL',
      errorMessage: 'Image height too small: $height px',
      guidanceMessage:
          'Image height must be at least $minHeight pixels.\n'
          'Actual: $height px\n\n'
          'This suggests the receipt has no content or rendering failed.',
      height: height,
    );
  }

  factory ImageValidationResult.heightTooLarge(int height, int maxHeight) {
    return ImageValidationResult(
      isValid: false,
      statusCode: 'HEIGHT_TOO_LARGE',
      errorMessage: 'Image height too large: $height px',
      guidanceMessage:
          'Image height exceeds maximum: $height px (max: $maxHeight px)\n\n'
          'The receipt is too long for a single print job.\n\n'
          'Solutions:\n'
          '  1. Reduce number of items per receipt\n'
          '  2. Use smaller font sizes\n'
          '  3. Remove unnecessary spacing\n'
          '  4. Split into multiple receipts\n\n'
          'Note: Very long receipts may also cause printer paper jams.',
      height: height,
    );
  }

  factory ImageValidationResult.imageTooLarge(int actualSize, int maxSize) {
    return ImageValidationResult(
      isValid: false,
      statusCode: 'IMAGE_TOO_LARGE',
      errorMessage:
          'Image data too large: ${(actualSize / 1024 / 1024).toStringAsFixed(1)} MB',
      guidanceMessage:
          'Image exceeds maximum size:\n'
          '  Actual: ${(actualSize / 1024 / 1024).toStringAsFixed(1)} MB\n'
          '  Maximum: ${(maxSize / 1024 / 1024).toStringAsFixed(1)} MB\n\n'
          'This will cause printer buffer overflow.\n\n'
          'Solutions:\n'
          '  1. Reduce receipt height\n'
          '  2. Lower pixel ratio (image quality)\n'
          '  3. Split into multiple print jobs',
    );
  }

  factory ImageValidationResult.conversionFailed() {
    return const ImageValidationResult(
      isValid: false,
      statusCode: 'CONVERSION_FAILED',
      errorMessage: 'Failed to convert image to byte data',
      guidanceMessage:
          'CRITICAL ERROR: Image conversion failed.\n\n'
          'Possible causes:\n'
          '  - Corrupted image data\n'
          '  - Out of memory\n'
          '  - Invalid image format\n\n'
          'Try:\n'
          '  - Reducing receipt complexity\n'
          '  - Lowering image quality\n'
          '  - Restarting the app',
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════
// PAPER SIZE ENUM
// ═══════════════════════════════════════════════════════════════════════════

enum PaperSize { mm58, mm80 }
