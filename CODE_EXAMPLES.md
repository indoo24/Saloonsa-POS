# Code Examples - Printer Settings Integration

## 🎯 Common Use Cases with Code Examples

---

## 1. Navigate to Printer Settings

### From Any Screen
```dart
import 'package:flutter/material.dart';
import 'package:barber_casher/screens/casher/printer_settings_screen.dart';

void openPrinterSettings(BuildContext context) {
  Navigator.push(
    context,
    MaterialPageRoute(
      builder: (_) => const PrinterSettingsScreen(),
    ),
  );
}
```

### With Result Callback
```dart
void openPrinterSettingsWithCallback(BuildContext context) async {
  final result = await Navigator.push(
    context,
    MaterialPageRoute(
      builder: (_) => const PrinterSettingsScreen(),
    ),
  );
  
  if (result == true) {
    print('User configured printer successfully');
  }
}
```

---

## 2. Check Printer Connection Status

### Simple Check
```dart
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:barber_casher/cubits/printer/printer_cubit.dart';

void checkPrinterStatus(BuildContext context) {
  final printerCubit = context.read<PrinterCubit>();
  
  if (printerCubit.isConnected) {
    print('Printer connected: ${printerCubit.connectedPrinter?.name}');
  } else {
    print('No printer connected');
  }
}
```

### With Widget
```dart
Widget buildPrinterStatusWidget(BuildContext context) {
  return BlocBuilder<PrinterCubit, PrinterState>(
    builder: (context, state) {
      if (state is PrinterConnected) {
        return Text('✅ Connected: ${state.device.name}');
      } else {
        return const Text('❌ Not Connected');
      }
    },
  );
}
```

---

## 3. Get Current Printer Settings

### Access Paper Size
```dart
import 'package:barber_casher/models/printer_settings.dart';

void getCurrentSettings(BuildContext context) {
  final cubit = context.read<PrinterCubit>();
  final settings = cubit.settings;
  
  print('Paper Size: ${settings.paperSize.displayName}');
  print('Characters per line: ${settings.paperSize.charsPerLine}');
  print('Paper width: ${settings.paperWidthMM}mm');
  
  if (settings.selectedPrinter != null) {
    print('Selected Printer: ${settings.selectedPrinter!.name}');
    print('Connection Type: ${settings.selectedPrinter!.type}');
  }
}
```

### Use Settings in Printing
```dart
Future<void> printWithCurrentSettings(BuildContext context) async {
  final cubit = context.read<PrinterCubit>();
  final settings = cubit.settings;
  
  // Adjust your receipt layout based on paper size
  switch (settings.paperSize) {
    case PaperSize.mm58:
      // Use 32 characters per line
      print('Using 58mm layout');
      break;
    case PaperSize.mm80:
      // Use 48 characters per line
      print('Using 80mm layout');
      break;
    case PaperSize.a4:
      // Use 80 characters per line
      print('Using A4 layout');
      break;
  }
}
```

---

## 4. Change Paper Size Programmatically

```dart
Future<void> changePaperSize(
  BuildContext context,
  PaperSize newSize,
) async {
  final cubit = context.read<PrinterCubit>();
  final currentSettings = cubit.settings;
  
  // Update settings with new paper size
  await cubit.updateSettings(
    currentSettings.copyWith(paperSize: newSize),
  );
  
  print('Paper size changed to: ${newSize.displayName}');
}

// Usage
changePaperSize(context, PaperSize.mm58);
```

---

## 5. Send Test Print

### Simple Test Print
```dart
Future<void> sendTestPrint(BuildContext context) async {
  final cubit = context.read<PrinterCubit>();
  
  if (!cubit.isConnected) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('No printer connected')),
    );
    return;
  }
  
  await cubit.testPrint();
}
```

### Test Print with Feedback
```dart
Future<void> testPrintWithFeedback(BuildContext context) async {
  final cubit = context.read<PrinterCubit>();
  
  if (!cubit.isConnected) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Please connect a printer first')),
    );
    return;
  }
  
  // Show loading
  showDialog(
    context: context,
    barrierDismissible: false,
    builder: (_) => const Center(child: CircularProgressIndicator()),
  );
  
  await cubit.testPrint();
  
  // Close loading
  Navigator.of(context).pop();
}
```

---

## 6. Print Custom Receipt

### Basic Receipt
```dart
import 'package:esc_pos_utils_plus/esc_pos_utils_plus.dart' as esc_pos;

Future<void> printCustomReceipt(BuildContext context, String content) async {
  final cubit = context.read<PrinterCubit>();
  
  if (!cubit.isConnected) {
    print('No printer connected');
    return;
  }
  
  final settings = cubit.settings;
  final profile = await esc_pos.CapabilityProfile.load();
  final paperSize = _convertToEscPosPaperSize(settings.paperSize);
  final generator = esc_pos.Generator(paperSize, profile);
  
  List<int> bytes = [];
  
  // Add content
  bytes += generator.text(
    content,
    styles: const esc_pos.PosStyles(
      align: esc_pos.PosAlign.center,
    ),
  );
  
  bytes += generator.feed(2);
  bytes += generator.cut();
  
  // Send to printer
  await cubit.printBytes(bytes);
}

esc_pos.PaperSize _convertToEscPosPaperSize(PaperSize size) {
  switch (size) {
    case PaperSize.mm58:
      return esc_pos.PaperSize.mm58;
    case PaperSize.mm80:
      return esc_pos.PaperSize.mm80;
    case PaperSize.a4:
      return esc_pos.PaperSize.mm80;
  }
}
```

### Advanced Receipt with Formatting
```dart
Future<void> printFormattedReceipt(BuildContext context) async {
  final cubit = context.read<PrinterCubit>();
  final settings = cubit.settings;
  
  final profile = await esc_pos.CapabilityProfile.load();
  final paperSize = _convertToEscPosPaperSize(settings.paperSize);
  final generator = esc_pos.Generator(paperSize, profile);
  
  List<int> bytes = [];
  
  // Header
  bytes += generator.text(
    'BARBER SHOP',
    styles: const esc_pos.PosStyles(
      align: esc_pos.PosAlign.center,
      height: esc_pos.PosTextSize.size2,
      width: esc_pos.PosTextSize.size2,
      bold: true,
    ),
  );
  bytes += generator.emptyLines(1);
  
  // Divider
  bytes += generator.text('=' * settings.paperSize.charsPerLine);
  bytes += generator.emptyLines(1);
  
  // Items
  bytes += generator.row([
    esc_pos.PosColumn(
      text: 'Haircut',
      width: 8,
      styles: const esc_pos.PosStyles(align: esc_pos.PosAlign.left),
    ),
    esc_pos.PosColumn(
      text: '50.00',
      width: 4,
      styles: const esc_pos.PosStyles(align: esc_pos.PosAlign.right),
    ),
  ]);
  
  bytes += generator.row([
    esc_pos.PosColumn(
      text: 'Beard Trim',
      width: 8,
      styles: const esc_pos.PosStyles(align: esc_pos.PosAlign.left),
    ),
    esc_pos.PosColumn(
      text: '30.00',
      width: 4,
      styles: const esc_pos.PosStyles(align: esc_pos.PosAlign.right),
    ),
  ]);
  
  bytes += generator.emptyLines(1);
  bytes += generator.text('=' * settings.paperSize.charsPerLine);
  
  // Total
  bytes += generator.row([
    esc_pos.PosColumn(
      text: 'TOTAL',
      width: 8,
      styles: const esc_pos.PosStyles(
        align: esc_pos.PosAlign.left,
        bold: true,
      ),
    ),
    esc_pos.PosColumn(
      text: '80.00 ر.س',
      width: 4,
      styles: const esc_pos.PosStyles(
        align: esc_pos.PosAlign.right,
        bold: true,
      ),
    ),
  ]);
  
  bytes += generator.emptyLines(2);
  bytes += generator.text(
    'Thank You!',
    styles: const esc_pos.PosStyles(align: esc_pos.PosAlign.center),
  );
  
  bytes += generator.feed(2);
  bytes += generator.cut();
  
  await cubit.printBytes(bytes);
}
```

---

## 7. Listen to Printer State Changes

### Using BlocListener
```dart
BlocListener<PrinterCubit, PrinterState>(
  listener: (context, state) {
    if (state is PrinterConnected) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Connected: ${state.device.name}')),
      );
    } else if (state is PrinterError) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: ${state.message}')),
      );
    } else if (state is PrinterPrintSuccess) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Print successful!')),
      );
    }
  },
  child: YourWidget(),
)
```

### Using BlocConsumer (Listen + Build)
```dart
BlocConsumer<PrinterCubit, PrinterState>(
  listener: (context, state) {
    // Handle side effects (toasts, navigation, etc.)
    if (state is PrinterError) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(state.message)),
      );
    }
  },
  builder: (context, state) {
    // Build UI based on state
    if (state is PrinterConnected) {
      return Text('Connected: ${state.device.name}');
    } else if (state is PrinterPrinting) {
      return const CircularProgressIndicator();
    } else {
      return const Text('Not connected');
    }
  },
)
```

---

## 8. Handle Printing Errors

### With Try-Catch
```dart
Future<void> printWithErrorHandling(
  BuildContext context,
  List<int> bytes,
) async {
  final cubit = context.read<PrinterCubit>();
  
  try {
    if (!cubit.isConnected) {
      throw Exception('No printer connected');
    }
    
    await cubit.printBytes(bytes);
    
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Print successful!')),
    );
  } catch (e) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Print failed: $e')),
    );
  }
}
```

### Retry Logic
```dart
Future<bool> printWithRetry(
  BuildContext context,
  List<int> bytes, {
  int maxRetries = 3,
}) async {
  final cubit = context.read<PrinterCubit>();
  
  for (int attempt = 1; attempt <= maxRetries; attempt++) {
    try {
      await cubit.printBytes(bytes);
      return true;
    } catch (e) {
      if (attempt == maxRetries) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Print failed after $maxRetries attempts: $e'),
          ),
        );
        return false;
      }
      
      // Wait before retry
      await Future.delayed(Duration(seconds: attempt));
    }
  }
  
  return false;
}
```

---

## 9. Scan for Printers Programmatically

```dart
Future<List<PrinterDevice>> scanForPrinters(
  BuildContext context,
  PrinterConnectionType type,
) async {
  final cubit = context.read<PrinterCubit>();
  
  // Trigger scan
  await cubit.scanPrinters(type);
  
  // Wait for results
  await Future.delayed(const Duration(seconds: 2));
  
  // Get state
  final state = cubit.state;
  
  if (state is PrintersFound) {
    return state.devices;
  }
  
  return [];
}

// Usage
void findAndConnectWiFiPrinter(BuildContext context) async {
  final printers = await scanForPrinters(
    context,
    PrinterConnectionType.wifi,
  );
  
  if (printers.isNotEmpty) {
    // Auto-connect to first printer
    final cubit = context.read<PrinterCubit>();
    await cubit.connectToPrinter(printers.first);
  }
}
```

---

## 10. Create Custom Settings Dialog

```dart
Future<void> showPaperSizeDialog(BuildContext context) async {
  final cubit = context.read<PrinterCubit>();
  final currentSize = cubit.settings.paperSize;
  
  final result = await showDialog<PaperSize>(
    context: context,
    builder: (context) => AlertDialog(
      title: const Text('Select Paper Size'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: PaperSize.values.map((size) {
          return RadioListTile<PaperSize>(
            title: Text(size.displayName),
            subtitle: Text('${size.charsPerLine} characters per line'),
            value: size,
            groupValue: currentSize,
            onChanged: (value) => Navigator.pop(context, value),
          );
        }).toList(),
      ),
    ),
  );
  
  if (result != null && result != currentSize) {
    await cubit.updateSettings(
      cubit.settings.copyWith(paperSize: result),
    );
  }
}
```

---

## 11. Build Custom Printer Status Widget

```dart
class PrinterStatusWidget extends StatelessWidget {
  const PrinterStatusWidget({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<PrinterCubit, PrinterState>(
      builder: (context, state) {
        final cubit = context.read<PrinterCubit>();
        final isConnected = state is PrinterConnected;
        
        return Card(
          child: ListTile(
            leading: Icon(
              isConnected ? Icons.print : Icons.print_disabled,
              color: isConnected ? Colors.green : Colors.grey,
            ),
            title: Text(
              isConnected 
                ? 'Printer Connected'
                : 'No Printer',
            ),
            subtitle: isConnected
                ? Text(cubit.connectedPrinter?.name ?? '')
                : null,
            trailing: isConnected
                ? IconButton(
                    icon: const Icon(Icons.print),
                    onPressed: () => cubit.testPrint(),
                  )
                : TextButton(
                    child: const Text('Setup'),
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const PrinterSettingsScreen(),
                        ),
                      );
                    },
                  ),
          ),
        );
      },
    );
  }
}
```

---

## 12. Check Before Printing

```dart
Future<bool> ensurePrinterConnected(BuildContext context) async {
  final cubit = context.read<PrinterCubit>();
  
  if (cubit.isConnected) {
    return true;
  }
  
  // Show dialog to connect
  final shouldConnect = await showDialog<bool>(
    context: context,
    builder: (context) => AlertDialog(
      title: const Text('No Printer Connected'),
      content: const Text('Would you like to connect a printer?'),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context, false),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: () => Navigator.pop(context, true),
          child: const Text('Setup Printer'),
        ),
      ],
    ),
  );
  
  if (shouldConnect == true) {
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => const PrinterSettingsScreen(),
      ),
    );
    
    // Check again after settings
    return cubit.isConnected;
  }
  
  return false;
}

// Usage in print function
Future<void> printInvoice(BuildContext context) async {
  if (!await ensurePrinterConnected(context)) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Printing cancelled')),
    );
    return;
  }
  
  // Proceed with printing
  // ...
}
```

---

## 📚 Additional Resources

### Import Statements Reference
```dart
// For printer settings screen
import 'package:barber_casher/screens/casher/printer_settings_screen.dart';

// For printer cubit and state
import 'package:barber_casher/cubits/printer/printer_cubit.dart';
import 'package:barber_casher/cubits/printer/printer_state.dart';

// For models
import 'package:barber_casher/models/printer_settings.dart';
import 'package:barber_casher/screens/casher/models/printer_device.dart';

// For ESC/POS printing
import 'package:esc_pos_utils_plus/esc_pos_utils_plus.dart' as esc_pos;

// For BLoC
import 'package:flutter_bloc/flutter_bloc.dart';
```

---

These code examples cover the most common use cases for integrating with the Printer Settings feature!
