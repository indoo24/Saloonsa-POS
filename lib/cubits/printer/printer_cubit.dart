import 'package:flutter_bloc/flutter_bloc.dart';
import '../../screens/casher/models/printer_device.dart';
import '../../screens/casher/services/printer_service.dart';
import 'printer_state.dart';

/// Cubit for managing printer operations
class PrinterCubit extends Cubit<PrinterState> {
  final PrinterService _printerService;

  PrinterCubit({PrinterService? printerService})
      : _printerService = printerService ?? PrinterService(),
        super(const PrinterInitial());

  /// Initialize and auto-reconnect to previously connected printer
  Future<void> initialize() async {
    try {
      final success = await _printerService.autoReconnect();
      if (success && _printerService.connectedPrinter != null) {
        emit(PrinterConnected(_printerService.connectedPrinter!));
      }
    } catch (e) {
      emit(PrinterError('Failed to auto-reconnect: $e'));
    }
  }

  /// Scan for printers based on connection type
  Future<void> scanPrinters(PrinterConnectionType type) async {
    emit(PrinterScanning(type));

    try {
      List<PrinterDevice> devices;

      switch (type) {
        case PrinterConnectionType.wifi:
          devices = await _printerService.scanWiFiPrinters();
          break;
        case PrinterConnectionType.bluetooth:
          devices = await _printerService.scanBluetoothPrinters();
          break;
        case PrinterConnectionType.usb:
          devices = await _printerService.scanUSBPrinters();
          break;
      }

      emit(PrintersFound(devices, type));
    } catch (e) {
      emit(PrinterError('Failed to scan printers: $e'));
    }
  }

  /// Connect to a specific printer
  Future<void> connectToPrinter(PrinterDevice device) async {
    emit(PrinterConnecting(device));

    try {
      final success = await _printerService.connectToPrinter(device);

      if (success) {
        emit(PrinterConnected(device));
      } else {
        emit(const PrinterError('Failed to connect to printer'));
      }
    } catch (e) {
      emit(PrinterError('Connection error: $e'));
    }
  }

  /// Disconnect from current printer
  Future<void> disconnect() async {
    try {
      await _printerService.disconnect();
      emit(const PrinterDisconnected());
    } catch (e) {
      emit(PrinterError('Disconnect error: $e'));
    }
  }

  /// Print bytes to connected printer
  Future<void> printBytes(List<int> bytes) async {
    if (_printerService.connectedPrinter == null) {
      emit(const PrinterError('No printer connected'));
      return;
    }

    emit(const PrinterPrinting());

    try {
      final success = await _printerService.printBytes(bytes);

      if (success) {
        emit(const PrinterPrintSuccess());
        // Return to connected state
        if (_printerService.connectedPrinter != null) {
          emit(PrinterConnected(_printerService.connectedPrinter!));
        }
      } else {
        emit(const PrinterError('Failed to print'));
      }
    } catch (e) {
      emit(PrinterError('Print error: $e'));
    }
  }

  /// Get currently connected printer
  PrinterDevice? get connectedPrinter => _printerService.connectedPrinter;

  /// Check if a printer is connected
  bool get isConnected => _printerService.connectedPrinter != null;
}
