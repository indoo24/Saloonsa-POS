/// Printer connection type
enum PrinterConnectionType {
  wifi,      // Network/WiFi printer
  bluetooth, // Bluetooth printer
  usb,       // USB printer
}

/// Printer device information
class PrinterDevice {
  final String id;
  final String name;
  final String? address; // IP address for WiFi, MAC address for Bluetooth
  final int? port;       // Port for WiFi printers (usually 9100)
  final PrinterConnectionType type;
  final bool isConnected;

  PrinterDevice({
    required this.id,
    required this.name,
    this.address,
    this.port,
    required this.type,
    this.isConnected = false,
  });

  PrinterDevice copyWith({
    String? id,
    String? name,
    String? address,
    int? port,
    PrinterConnectionType? type,
    bool? isConnected,
  }) {
    return PrinterDevice(
      id: id ?? this.id,
      name: name ?? this.name,
      address: address ?? this.address,
      port: port ?? this.port,
      type: type ?? this.type,
      isConnected: isConnected ?? this.isConnected,
    );
  }

  String get displayName {
    switch (type) {
      case PrinterConnectionType.wifi:
        return '$name (WiFi - ${address ?? "N/A"})';
      case PrinterConnectionType.bluetooth:
        return '$name (Bluetooth)';
      case PrinterConnectionType.usb:
        return '$name (USB)';
    }
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'address': address,
      'port': port,
      'type': type.toString(),
      'isConnected': isConnected,
    };
  }

  factory PrinterDevice.fromJson(Map<String, dynamic> json) {
    return PrinterDevice(
      id: json['id'],
      name: json['name'],
      address: json['address'],
      port: json['port'],
      type: PrinterConnectionType.values.firstWhere(
        (e) => e.toString() == json['type'],
        orElse: () => PrinterConnectionType.wifi,
      ),
      isConnected: json['isConnected'] ?? false,
    );
  }
}
