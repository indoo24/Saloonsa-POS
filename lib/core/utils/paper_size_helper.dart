/// Helper class for thermal printer paper size calculations
/// Matches ESC/POS printer specifications exactly
class PaperSizeHelper {
  /// Paper size types matching printer settings
  static const String paper58mm = '58mm';
  static const String paper80mm = '80mm';
  static const String paperA4 = 'A4';

  /// Get pixel width for preview based on paper size
  /// These widths match real thermal printer output
  static double getPreviewWidth(String paperSize) {
    switch (paperSize) {
      case paper58mm:
        return 280.0; // 58mm = ~280px at 120 DPI
      case paper80mm:
        return 380.0; // 80mm = ~380px at 120 DPI
      case paperA4:
        return double.infinity; // Use 90% of screen width
      default:
        return 380.0; // Default to 80mm
    }
  }

  /// Get characters per line for text layout
  /// Critical for text wrapping and alignment
  static int getCharsPerLine(String paperSize) {
    switch (paperSize) {
      case paper58mm:
        return 32; // 58mm thermal printers
      case paper80mm:
        return 48; // 80mm thermal printers
      case paperA4:
        return 80; // A4 preview (wider)
      default:
        return 48; // Default to 80mm
    }
  }

  /// Get font size for receipt text
  static double getFontSize(String paperSize) {
    switch (paperSize) {
      case paper58mm:
        return 9.0; // Smaller for 58mm
      case paper80mm:
        return 10.0; // Standard for 80mm
      case paperA4:
        return 11.0; // Slightly larger for A4
      default:
        return 10.0;
    }
  }

  /// Generate separator line (like ESC/POS horizontal rule)
  static String generateSeparator(String paperSize, {String char = '─'}) {
    final charsPerLine = getCharsPerLine(paperSize);
    return char * charsPerLine;
  }

  /// Generate double line separator
  static String generateDoubleSeparator(String paperSize) {
    return generateSeparator(paperSize, char: '═');
  }

  /// Center text within paper width
  static String centerText(String text, String paperSize) {
    final charsPerLine = getCharsPerLine(paperSize);
    if (text.length >= charsPerLine) return text.substring(0, charsPerLine);

    final padding = (charsPerLine - text.length) ~/ 2;
    return ' ' * padding + text;
  }

  /// Align text left-right (like item name and price)
  /// Example: "Haircut                    50.00 ر.س"
  static String alignLeftRight(String left, String right, String paperSize) {
    final charsPerLine = getCharsPerLine(paperSize);
    final totalLength = left.length + right.length;

    if (totalLength >= charsPerLine) {
      // Truncate left text if too long
      final maxLeft = charsPerLine - right.length - 2;
      return '${left.substring(0, maxLeft)}  $right';
    }

    final spaces = charsPerLine - totalLength;
    return left + (' ' * spaces) + right;
  }

  /// Pad text to right with spaces
  static String padRight(String text, String paperSize) {
    final charsPerLine = getCharsPerLine(paperSize);
    if (text.length >= charsPerLine) return text.substring(0, charsPerLine);
    return text.padRight(charsPerLine);
  }

  /// Get all available paper sizes
  static List<String> getAllSizes() {
    return [paper58mm, paper80mm, paperA4];
  }

  /// Get paper size display name
  static String getDisplayName(String paperSize) {
    switch (paperSize) {
      case paper58mm:
        return '58mm (32 chars)';
      case paper80mm:
        return '80mm (48 chars)';
      case paperA4:
        return 'A4 (80 chars)';
      default:
        return paperSize;
    }
  }
}
