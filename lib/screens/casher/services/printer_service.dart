import 'dart:async';
import 'dart:io';
import 'dart:typed_data';
import 'package:blue_thermal_printer/blue_thermal_printer.dart';
import 'package:esc_pos_printer_plus/esc_pos_printer_plus.dart';
import 'package:esc_pos_utils_plus/esc_pos_utils_plus.dart';
import 'package:network_info_plus/network_info_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';
// import 'package:usb_serial/usb_serial.dart';  // Disabled due to compatibility issues
import '../models/printer_device.dart';
import 'dart:convert';

/// Universal printer service supporting WiFi, Bluetooth, and USB
class PrinterService {
  static final PrinterService _instance = PrinterService._internal();
  factory PrinterService() => _instance;
  PrinterService._internal();

  // Bluetooth printer instance
  final BlueThermalPrinter _bluetoothPrinter = BlueThermalPrinter.instance;
  
  // Currently connected printer
  PrinterDevice? _connectedPrinter;
  PrinterDevice? get connectedPrinter => _connectedPrinter;

  // Network printer instance (for WiFi)
  NetworkPrinter? _networkPrinter;

  // USB port and transaction (for USB) - Disabled due to compatibility issues
  // UsbPort? _usbPort;
  // StreamSubscription<String>? _usbSubscription;

  // ============================================================================
  // SCANNING METHODS
  // ============================================================================

  /// Scan for WiFi printers on local network
  Future<List<PrinterDevice>> scanWiFiPrinters() async {
    final devices = <PrinterDevice>[];
    
    try {
      // Get local network info
      final networkInfo = NetworkInfo();
      final wifiIP = await networkInfo.getWifiIP();
      
      if (wifiIP == null) {
        return devices;
      }

      // Extract network prefix (e.g., "192.168.1")
      final parts = wifiIP.split('.');
      if (parts.length < 3) return devices;
      final networkPrefix = '${parts[0]}.${parts[1]}.${parts[2]}';

      // Scan common printer IPs (192.168.1.1 - 192.168.1.254)
      final futures = <Future>[];
      for (int i = 1; i <= 254; i++) {
        final ip = '$networkPrefix.$i';
        futures.add(_checkPrinterAtIP(ip, 9100).then((isAvailable) {
          if (isAvailable) {
            devices.add(PrinterDevice(
              id: 'wifi_$ip',
              name: 'Network Printer',
              address: ip,
              port: 9100,
              type: PrinterConnectionType.wifi,
            ));
          }
        }));
      }

      // Wait for all scans with timeout
      await Future.wait(futures).timeout(
        const Duration(seconds: 10),
        onTimeout: () => [],
      );
    } catch (e) {
      print('Error scanning WiFi printers: $e');
    }

    return devices;
  }

  /// Check if a printer is available at the given IP and port
  Future<bool> _checkPrinterAtIP(String ip, int port) async {
    try {
      final socket = await Socket.connect(ip, port, timeout: const Duration(seconds: 1));
      await socket.close();
      return true;
    } catch (e) {
      return false;
    }
  }

  /// Scan for Bluetooth printers
  Future<List<PrinterDevice>> scanBluetoothPrinters() async {
    final devices = <PrinterDevice>[];

    try {
      // Check if Bluetooth is available
      final isAvailable = await _bluetoothPrinter.isAvailable;
      if (isAvailable == null || !isAvailable) {
        return devices;
      }

      // Check if Bluetooth is enabled
      final isOn = await _bluetoothPrinter.isOn;
      if (isOn == null || !isOn) {
        return devices;
      }

      // Get bonded (paired) devices
      final bondedDevices = await _bluetoothPrinter.getBondedDevices();
      
      for (var device in bondedDevices) {
        devices.add(PrinterDevice(
          id: 'bt_${device.address}',
          name: device.name ?? 'Unknown Bluetooth Printer',
          address: device.address,
          type: PrinterConnectionType.bluetooth,
        ));
      }
    } catch (e) {
      print('Error scanning Bluetooth printers: $e');
    }

    return devices;
  }

  /// Scan for USB printers (DISABLED - usb_serial package has compatibility issues)
  Future<List<PrinterDevice>> scanUSBPrinters() async {
    final devices = <PrinterDevice>[];

    try {
      // USB scanning disabled due to package compatibility issues
      // To re-enable: uncomment usb_serial import and reinstall package
      // final usbDevices = await UsbSerial.listDevices();
      // 
      // for (var device in usbDevices) {
      //   devices.add(PrinterDevice(
      //     id: 'usb_${device.deviceId}',
      //     name: device.productName ?? 'USB Printer',
      //     type: PrinterConnectionType.usb,
      //   ));
      // }
      
      print('USB printer scanning is currently disabled. Use WiFi or Bluetooth instead.');
    } catch (e) {
      print('Error scanning USB printers: $e');
    }

    return devices;
  }

  // ============================================================================
  // CONNECTION METHODS
  // ============================================================================

  /// Connect to a printer
  Future<bool> connectToPrinter(PrinterDevice device) async {
    try {
      switch (device.type) {
        case PrinterConnectionType.wifi:
          return await _connectToWiFiPrinter(device);
        case PrinterConnectionType.bluetooth:
          return await _connectToBluetoothPrinter(device);
        case PrinterConnectionType.usb:
          return await _connectToUSBPrinter(device);
      }
    } catch (e) {
      print('Error connecting to printer: $e');
      return false;
    }
  }

  /// Connect to WiFi printer
  Future<bool> _connectToWiFiPrinter(PrinterDevice device) async {
    if (device.address == null || device.port == null) {
      return false;
    }

    final printer = NetworkPrinter(PaperSize.mm80, await CapabilityProfile.load());
    final result = await printer.connect(device.address!, port: device.port!);

    if (result == PosPrintResult.success) {
      _networkPrinter = printer;
      _connectedPrinter = device.copyWith(isConnected: true);
      await _saveConnectedPrinter(device);
      return true;
    }

    return false;
  }

  /// Connect to Bluetooth printer
  Future<bool> _connectToBluetoothPrinter(PrinterDevice device) async {
    if (device.address == null) {
      return false;
    }

    // Get the Bluetooth device
    final bondedDevices = await _bluetoothPrinter.getBondedDevices();
    final btDevice = bondedDevices.firstWhere(
      (d) => d.address == device.address,
      orElse: () => throw Exception('Bluetooth device not found'),
    );

    // Connect
    await _bluetoothPrinter.connect(btDevice);
    
    // Check if connected
    final isConnected = await _bluetoothPrinter.isConnected;
    if (isConnected == true) {
      _connectedPrinter = device.copyWith(isConnected: true);
      await _saveConnectedPrinter(device);
      return true;
    }

    return false;
  }

  /// Connect to USB printer (DISABLED - usb_serial package has compatibility issues)
  Future<bool> _connectToUSBPrinter(PrinterDevice device) async {
    // USB connection disabled due to package compatibility issues
    // To re-enable: uncomment usb_serial import and reinstall package
    
    print('USB printer connection is currently disabled. Please use WiFi or Bluetooth.');
    return false;
    
    /* Original USB connection code (disabled):
    final usbDevices = await UsbSerial.listDevices();
    
    // Find the USB device by ID
    final usbDevice = usbDevices.firstWhere(
      (d) => 'usb_${d.deviceId}' == device.id,
      orElse: () => throw Exception('USB device not found'),
    );

    // Create port and open connection
    final port = await usbDevice.create();
    final opened = await port?.open();

    if (opened == true && port != null) {
      await port.setDTR(true);
      await port.setRTS(true);
      
      // Set baud rate for thermal printers (common: 9600 or 115200)
      port.setPortParameters(
        115200, // baudRate
        UsbPort.DATABITS_8,
        UsbPort.STOPBITS_1,
        UsbPort.PARITY_NONE,
      );

      _usbPort = port;
      _connectedPrinter = device.copyWith(isConnected: true);
      await _saveConnectedPrinter(device);
      return true;
    }

    return false;
    */
  }

  /// Disconnect from current printer
  Future<void> disconnect() async {
    if (_connectedPrinter == null) return;

    try {
      switch (_connectedPrinter!.type) {
        case PrinterConnectionType.wifi:
          _networkPrinter?.disconnect();
          _networkPrinter = null;
          break;
        case PrinterConnectionType.bluetooth:
          await _bluetoothPrinter.disconnect();
          break;
        case PrinterConnectionType.usb:
          // USB disconnection disabled (package compatibility issues)
          // await _usbSubscription?.cancel();
          // await _usbPort?.close();
          // _usbPort = null;
          break;
      }
      
      _connectedPrinter = null;
      await _clearConnectedPrinter();
    } catch (e) {
      print('Error disconnecting printer: $e');
    }
  }

  // ============================================================================
  // PRINTING METHODS
  // ============================================================================

  /// Print bytes to the connected printer
  Future<bool> printBytes(List<int> bytes) async {
    if (_connectedPrinter == null) {
      throw Exception('No printer connected');
    }

    try {
      switch (_connectedPrinter!.type) {
        case PrinterConnectionType.wifi:
          return await _printToWiFi(bytes);
        case PrinterConnectionType.bluetooth:
          return await _printToBluetooth(bytes);
        case PrinterConnectionType.usb:
          return await _printToUSB(bytes);
      }
    } catch (e) {
      print('Error printing: $e');
      return false;
    }
  }

  /// Print to WiFi printer
  Future<bool> _printToWiFi(List<int> bytes) async {
    if (_networkPrinter == null || _connectedPrinter == null) return false;
    
    // Reconnect for printing
    final printer = NetworkPrinter(PaperSize.mm80, await CapabilityProfile.load());
    final result = await printer.connect(
      _connectedPrinter!.address!,
      port: _connectedPrinter!.port!,
    );
    
    if (result != PosPrintResult.success) {
      return false;
    }
    
    // Send bytes by converting to ESC/POS commands
    // The bytes are already formatted ESC/POS commands from Generator
    printer.rawBytes(bytes);
    printer.disconnect();
    
    return true;
  }

  /// Print to Bluetooth printer
  Future<bool> _printToBluetooth(List<int> bytes) async {
    final isConnected = await _bluetoothPrinter.isConnected;
    if (isConnected != true) return false;

    await _bluetoothPrinter.writeBytes(Uint8List.fromList(bytes));
    return true;
  }

  /// Print to USB printer (DISABLED - usb_serial package has compatibility issues)
  Future<bool> _printToUSB(List<int> bytes) async {
    // USB printing disabled due to package compatibility issues
    print('USB printing is currently disabled. Please use WiFi or Bluetooth.');
    return false;
    
    /* Original USB printing code (disabled):
    if (_usbPort == null) return false;
    await _usbPort!.write(Uint8List.fromList(bytes));
    return true;
    */
  }

  // ============================================================================
  // PERSISTENCE METHODS
  // ============================================================================

  /// Save connected printer to preferences
  Future<void> _saveConnectedPrinter(PrinterDevice device) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('connected_printer', jsonEncode(device.toJson()));
  }

  /// Clear connected printer from preferences
  Future<void> _clearConnectedPrinter() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('connected_printer');
  }

  /// Load previously connected printer
  Future<PrinterDevice?> loadConnectedPrinter() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final jsonString = prefs.getString('connected_printer');
      
      if (jsonString != null) {
        return PrinterDevice.fromJson(jsonDecode(jsonString));
      }
    } catch (e) {
      print('Error loading connected printer: $e');
    }
    return null;
  }

  /// Auto-reconnect to previously connected printer
  Future<bool> autoReconnect() async {
    final savedPrinter = await loadConnectedPrinter();
    if (savedPrinter != null) {
      return await connectToPrinter(savedPrinter);
    }
    return false;
  }
}
