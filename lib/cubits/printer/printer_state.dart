import 'package:equatable/equatable.dart';
import '../../screens/casher/models/printer_device.dart';

/// Base state for printer operations
abstract class PrinterState extends Equatable {
  const PrinterState();

  @override
  List<Object?> get props => [];
}

/// Initial state
class PrinterInitial extends PrinterState {
  const PrinterInitial();
}

/// Scanning for printers
class PrinterScanning extends PrinterState {
  final PrinterConnectionType type;
  
  const PrinterScanning(this.type);

  @override
  List<Object?> get props => [type];
}

/// Printers found after scanning
class PrintersFound extends PrinterState {
  final List<PrinterDevice> devices;
  final PrinterConnectionType type;
  
  const PrintersFound(this.devices, this.type);

  @override
  List<Object?> get props => [devices, type];
}

/// Connecting to printer
class PrinterConnecting extends PrinterState {
  final PrinterDevice device;
  
  const PrinterConnecting(this.device);

  @override
  List<Object?> get props => [device];
}

/// Printer connected successfully
class PrinterConnected extends PrinterState {
  final PrinterDevice device;
  
  const PrinterConnected(this.device);

  @override
  List<Object?> get props => [device];
}

/// Printer disconnected
class PrinterDisconnected extends PrinterState {
  const PrinterDisconnected();
}

/// Printing in progress
class PrinterPrinting extends PrinterState {
  const PrinterPrinting();
}

/// Print completed successfully
class PrinterPrintSuccess extends PrinterState {
  const PrinterPrintSuccess();
}

/// Error state
class PrinterError extends PrinterState {
  final String message;
  
  const PrinterError(this.message);

  @override
  List<Object?> get props => [message];
}
