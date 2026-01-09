import '../screens/casher/models/printer_device.dart';

/// Paper size options for receipt printers
enum PaperSize {
  mm58('58mm', 32), // 58mm paper, ~32 characters per line
  mm80('80mm', 48), // 80mm paper, ~48 characters per line
  a4('A4', 80); // A4 paper, ~80 characters per line

  final String displayName;
  final int charsPerLine;

  const PaperSize(this.displayName, this.charsPerLine);

  static PaperSize fromString(String value) {
    return PaperSize.values.firstWhere(
      (e) => e.name == value,
      orElse: () => PaperSize.mm80, // Default to 80mm
    );
  }
}

/// Complete printer settings model
class PrinterSettings {
  final PaperSize paperSize;
  final PrinterConnectionType? connectionType;
  final PrinterDevice? selectedPrinter;
  final bool autoReconnect;

  const PrinterSettings({
    this.paperSize = PaperSize.mm80,
    this.connectionType,
    this.selectedPrinter,
    this.autoReconnect = true,
  });

  PrinterSettings copyWith({
    PaperSize? paperSize,
    PrinterConnectionType? connectionType,
    PrinterDevice? selectedPrinter,
    bool? autoReconnect,
    bool clearPrinter = false,
  }) {
    return PrinterSettings(
      paperSize: paperSize ?? this.paperSize,
      connectionType: connectionType ?? this.connectionType,
      selectedPrinter: clearPrinter
          ? null
          : (selectedPrinter ?? this.selectedPrinter),
      autoReconnect: autoReconnect ?? this.autoReconnect,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'paperSize': paperSize.name,
      'connectionType': connectionType?.toString(),
      'selectedPrinter': selectedPrinter?.toJson(),
      'autoReconnect': autoReconnect,
    };
  }

  factory PrinterSettings.fromJson(Map<String, dynamic> json) {
    return PrinterSettings(
      paperSize: PaperSize.fromString(json['paperSize'] ?? 'mm80'),
      connectionType: json['connectionType'] != null
          ? PrinterConnectionType.values.firstWhere(
              (e) => e.toString() == json['connectionType'],
              orElse: () => PrinterConnectionType.wifi,
            )
          : null,
      selectedPrinter: json['selectedPrinter'] != null
          ? PrinterDevice.fromJson(json['selectedPrinter'])
          : null,
      autoReconnect: json['autoReconnect'] ?? true,
    );
  }

  /// Get paper width in millimeters
  int get paperWidthMM {
    switch (paperSize) {
      case PaperSize.mm58:
        return 58;
      case PaperSize.mm80:
        return 80;
      case PaperSize.a4:
        return 210; // A4 width
    }
  }

  @override
  String toString() {
    return 'PrinterSettings(paperSize: ${paperSize.displayName}, '
        'connectionType: $connectionType, '
        'printer: ${selectedPrinter?.name}, '
        'autoReconnect: $autoReconnect)';
  }
}
