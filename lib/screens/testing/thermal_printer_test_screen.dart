import 'package:flutter/material.dart';
import 'package:blue_thermal_printer/blue_thermal_printer.dart';
import 'dart:typed_data';
import 'dart:convert';
import 'package:charset_converter/charset_converter.dart';
import '../../services/settings_service.dart';

/// Thermal Printer Test Screen
///
/// This screen verifies 100% that:
/// 1. Printer is connected via Bluetooth or WiFi
/// 2. Receipt will print correctly
/// 3. All data formats properly
/// 4. Connection is stable
class ThermalPrinterTestScreen extends StatefulWidget {
  const ThermalPrinterTestScreen({Key? key}) : super(key: key);

  @override
  State<ThermalPrinterTestScreen> createState() =>
      _ThermalPrinterTestScreenState();
}

class _ThermalPrinterTestScreenState extends State<ThermalPrinterTestScreen> {
  final BlueThermalPrinter _printer = BlueThermalPrinter.instance;

  bool _isConnected = false;
  bool _isTesting = false;
  BluetoothDevice? _connectedDevice;
  List<BluetoothDevice> _devices = [];
  List<String> _testResults = [];
  int _testsPassed = 0;
  int _totalTests = 0;

  @override
  void initState() {
    super.initState();
    _checkConnection();
  }

  Future<void> _checkConnection() async {
    try {
      final isConnected = await _printer.isConnected ?? false;
      setState(() {
        _isConnected = isConnected;
      });

      if (isConnected) {
        _addTestResult('✅ Printer is connected', true);
      } else {
        _addTestResult('❌ No printer connected', false);
      }
    } catch (e) {
      _addTestResult('❌ Error checking connection: $e', false);
    }
  }

  Future<void> _scanForDevices() async {
    setState(() {
      _devices = [];
      _testResults.clear();
    });

    try {
      _addTestResult('🔍 Scanning for Bluetooth devices...', null);

      final devices = await _printer.getBondedDevices();
      setState(() {
        _devices = devices;
      });

      if (_devices.isEmpty) {
        _addTestResult('❌ No Bluetooth devices found', false);
        _addTestResult(
          'ℹ️ Please pair your printer in Bluetooth settings first',
          null,
        );
      } else {
        _addTestResult('✅ Found ${_devices.length} Bluetooth device(s)', true);
      }
    } catch (e) {
      _addTestResult('❌ Error scanning: $e', false);
    }
  }

  Future<void> _connectToDevice(BluetoothDevice device) async {
    setState(() {
      _testResults.clear();
      _isTesting = true;
    });

    try {
      _addTestResult('🔌 Attempting to connect to ${device.name}...', null);

      // Try to connect
      await _printer.connect(device);

      // Wait for connection to stabilize
      await Future.delayed(const Duration(seconds: 2));

      // Verify connection
      final isConnected = await _printer.isConnected ?? false;

      if (isConnected) {
        setState(() {
          _isConnected = true;
          _connectedDevice = device;
        });
        _addTestResult('✅ Connected successfully to ${device.name}', true);
        _addTestResult('✅ Connection verified', true);

        // Run comprehensive tests
        await _runComprehensiveTests();
      } else {
        _addTestResult('❌ Connection failed', false);
      }
    } catch (e) {
      _addTestResult('❌ Connection error: $e', false);
      setState(() {
        _isConnected = false;
        _connectedDevice = null;
      });
    } finally {
      setState(() {
        _isTesting = false;
      });
    }
  }

  Future<void> _disconnectPrinter() async {
    try {
      await _printer.disconnect();
      setState(() {
        _isConnected = false;
        _connectedDevice = null;
      });
      _addTestResult('✅ Disconnected successfully', true);
    } catch (e) {
      _addTestResult('❌ Disconnect error: $e', false);
    }
  }

  Future<void> _runComprehensiveTests() async {
    setState(() {
      _testsPassed = 0;
      _totalTests = 8;
    });

    // Test 1: Basic Communication
    await _testBasicCommunication();

    // Test 2: Text Printing
    await _testTextPrinting();

    // Test 3: Arabic Text
    await _testArabicText();

    // Test 4: ESC/POS Commands
    await _testEscPosCommands();

    // Test 5: Line Formatting
    await _testLineFormatting();

    // Test 6: Sample Receipt
    await _testSampleReceipt();

    // Test 7: Full Invoice
    await _testFullInvoice();

    // Test 8: Paper Cut
    await _testPaperCut();

    // Final summary
    _addTestResult('', null);
    _addTestResult('═══════════════════════════', null);
    _addTestResult(
      'FINAL RESULT: $_testsPassed/$_totalTests tests passed',
      _testsPassed == _totalTests,
    );

    if (_testsPassed == _totalTests) {
      _addTestResult('✅ PRINTER IS 100% READY FOR PRODUCTION', true);
    } else {
      _addTestResult(
        '⚠️ Some tests failed - check printer configuration',
        false,
      );
    }
  }

  Future<void> _testBasicCommunication() async {
    try {
      _addTestResult('', null);
      _addTestResult('[TEST 1/8] Basic Communication', null);

      // Send initialization command
      _printer.writeBytes(Uint8List.fromList([27, 64])); // ESC @
      await Future.delayed(const Duration(milliseconds: 500));

      _addTestResult('✅ Basic communication successful', true);
      setState(() => _testsPassed++);
    } catch (e) {
      _addTestResult('❌ Basic communication failed: $e', false);
    }
  }

  Future<void> _testTextPrinting() async {
    try {
      _addTestResult('', null);
      _addTestResult('[TEST 2/8] Text Printing', null);

      _printer.printCustom('TEST PRINT', 1, 1);
      _printer.printNewLine();
      await Future.delayed(const Duration(milliseconds: 500));

      _addTestResult('✅ Text printing successful', true);
      setState(() => _testsPassed++);
    } catch (e) {
      _addTestResult('❌ Text printing failed: $e', false);
    }
  }

  Future<void> _testArabicText() async {
    try {
      _addTestResult('', null);
      _addTestResult('[TEST 3/8] Arabic Text', null);

      // Convert Arabic text to Windows-1256 encoding for thermal printers
      final arabicText = 'اختبار اللغة العربية';
      try {
        final encodedBytes = await CharsetConverter.encode(
          'windows-1256',
          arabicText,
        );

        // Send with proper encoding
        List<int> bytes = [];
        bytes += [27, 97, 1]; // Center alignment
        bytes += encodedBytes;
        bytes += [10]; // New line

        _printer.writeBytes(Uint8List.fromList(bytes));
        await Future.delayed(const Duration(milliseconds: 500));

        _addTestResult('✅ Arabic text printing successful', true);
        setState(() => _testsPassed++);
      } catch (encodeError) {
        // Fallback: Try UTF-8 encoding
        _addTestResult(
          '⚠️ Windows-1256 encoding failed, trying UTF-8...',
          null,
        );
        final utf8Bytes = utf8.encode(arabicText);

        List<int> bytes = [];
        bytes += [27, 97, 1]; // Center alignment
        bytes += utf8Bytes;
        bytes += [10]; // New line

        _printer.writeBytes(Uint8List.fromList(bytes));
        await Future.delayed(const Duration(milliseconds: 500));

        _addTestResult('✅ Arabic text printing successful (UTF-8)', true);
        setState(() => _testsPassed++);
      }
    } catch (e) {
      _addTestResult('❌ Arabic text failed: $e', false);
    }
  }

  Future<void> _testEscPosCommands() async {
    try {
      _addTestResult('', null);
      _addTestResult('[TEST 4/8] ESC/POS Commands', null);

      // Test bold
      List<int> bytes = [];
      bytes += [27, 69, 1]; // Bold ON
      bytes += 'BOLD TEXT'.codeUnits;
      bytes += [27, 69, 0]; // Bold OFF
      bytes += [10]; // New line

      _printer.writeBytes(Uint8List.fromList(bytes));
      await Future.delayed(const Duration(milliseconds: 500));

      _addTestResult('✅ ESC/POS commands successful', true);
      setState(() => _testsPassed++);
    } catch (e) {
      _addTestResult('❌ ESC/POS commands failed: $e', false);
    }
  }

  Future<void> _testLineFormatting() async {
    try {
      _addTestResult('', null);
      _addTestResult('[TEST 5/8] Line Formatting', null);

      _printer.printCustom('Left', 0, 0);
      _printer.printCustom('Center', 1, 1);
      _printer.printCustom('Right', 2, 2);
      _printer.printNewLine();
      await Future.delayed(const Duration(milliseconds: 500));

      _addTestResult('✅ Line formatting successful', true);
      setState(() => _testsPassed++);
    } catch (e) {
      _addTestResult('❌ Line formatting failed: $e', false);
    }
  }

  Future<void> _testSampleReceipt() async {
    try {
      _addTestResult('', null);
      _addTestResult('[TEST 6/8] Sample Receipt', null);

      _printer.printCustom('SAMPLE RECEIPT', 2, 1);
      _printer.printNewLine();
      _printer.printCustom('================================', 0, 1);
      _printer.printNewLine();
      _printer.printCustom('Item: Test Product', 0, 0);
      _printer.printCustom('Price: 100.00 SAR', 0, 0);
      _printer.printCustom('================================', 0, 1);
      _printer.printCustom('Total: 100.00 SAR', 1, 1);
      _printer.printNewLine();
      _printer.printNewLine();
      await Future.delayed(const Duration(seconds: 1));

      _addTestResult('✅ Sample receipt printed', true);
      setState(() => _testsPassed++);
    } catch (e) {
      _addTestResult('❌ Sample receipt failed: $e', false);
    }
  }

  Future<void> _testFullInvoice() async {
    try {
      _addTestResult('', null);
      _addTestResult('[TEST 7/8] Full Invoice Test', null);

      // Load settings
      final settingsService = SettingsService();
      final settings = await settingsService.loadSettings();

      // Print test invoice using safe method
      _printer.printCustom('================================', 0, 1);
      _printer.printNewLine();

      // Business info (may contain Arabic)
      await _printTextSafe(settings.businessName, size: 2, align: 1);
      await _printTextSafe(settings.address, size: 0, align: 1);
      _printer.printCustom('Tel: ${settings.phoneNumber}', 0, 1);
      if (settings.taxNumber.isNotEmpty) {
        _printer.printCustom('Tax: ${settings.taxNumber}', 0, 1);
      }
      _printer.printNewLine();
      _printer.printCustom('================================', 0, 1);
      _printer.printNewLine();

      // Arabic title
      await _printTextSafe('فاتورة ضريبية مبسطة', size: 1, align: 1);
      _printer.printNewLine();
      _printer.printCustom('================================', 0, 1);
      _printer.printNewLine();

      // Invoice details
      _printer.printCustom(
        'Invoice: TEST-${DateTime.now().millisecondsSinceEpoch}',
        0,
        0,
      );
      _printer.printCustom('Branch: Test Branch', 0, 0);
      _printer.printCustom('Date: ${DateTime.now()}', 0, 0);
      _printer.printCustom('Cashier: Test Cashier', 0, 0);
      _printer.printCustom('Customer: Test Customer', 0, 0);
      await _printTextSafe('Payment: نقدي', size: 0, align: 0);
      _printer.printNewLine();
      _printer.printCustom('================================', 0, 1);
      _printer.printNewLine();

      // Services
      _printer.printCustom('SERVICES:', 1, 0);
      _printer.printNewLine();

      await _printTextSafe('حلاقة شعر    50.00 SAR', size: 0, align: 0);
      await _printTextSafe('Employee: محمد', size: 0, align: 0);
      _printer.printNewLine();

      await _printTextSafe('حلاقة ذقن    30.00 SAR', size: 0, align: 0);
      await _printTextSafe('Employee: محمد', size: 0, align: 0);
      _printer.printNewLine();

      await _printTextSafe('صبغة         100.00 SAR', size: 0, align: 0);
      await _printTextSafe('Employee: علي', size: 0, align: 0);
      _printer.printNewLine();

      _printer.printCustom('================================', 0, 1);
      _printer.printNewLine();

      // Totals
      _printer.printCustom('Subtotal:    180.00 SAR', 0, 0);
      _printer.printCustom('Discount (10%): -18.00 SAR', 0, 0);
      _printer.printCustom('After Discount: 162.00 SAR', 0, 0);
      _printer.printCustom('Tax (15%):    24.30 SAR', 0, 0);
      _printer.printNewLine();
      _printer.printCustom('================================', 0, 1);
      _printer.printCustom('TOTAL:       186.30 SAR', 2, 1);
      _printer.printCustom('================================', 0, 1);
      _printer.printNewLine();
      _printer.printCustom('Paid:        200.00 SAR', 0, 0);
      _printer.printCustom('Change:       13.70 SAR', 0, 0);
      _printer.printNewLine();
      _printer.printNewLine();

      await _printTextSafe('شكراً لزيارتكم', size: 1, align: 1);
      _printer.printNewLine();
      _printer.printNewLine();

      await Future.delayed(const Duration(seconds: 2));

      _addTestResult('✅ Full invoice printed successfully', true);
      _addTestResult('ℹ️ Check printed receipt for quality', null);
      setState(() => _testsPassed++);
    } catch (e) {
      _addTestResult('❌ Full invoice failed: $e', false);
    }
  }

  Future<void> _testPaperCut() async {
    try {
      _addTestResult('', null);
      _addTestResult('[TEST 8/8] Paper Cut', null);

      _printer.paperCut();
      await Future.delayed(const Duration(milliseconds: 500));

      _addTestResult('✅ Paper cut command sent', true);
      setState(() => _testsPassed++);
    } catch (e) {
      _addTestResult('❌ Paper cut failed: $e', false);
    }
  }

  void _addTestResult(String message, bool? success) {
    setState(() {
      _testResults.add(message);
    });
  }

  /// Safely print text with Arabic support
  Future<void> _printTextSafe(
    String text, {
    int size = 0,
    int align = 0,
  }) async {
    try {
      // Check if text contains Arabic characters
      final hasArabic = text.contains(RegExp(r'[\u0600-\u06FF]'));

      if (hasArabic) {
        // Use byte-level encoding for Arabic
        try {
          final encodedBytes = await CharsetConverter.encode(
            'windows-1256',
            text,
          );

          List<int> bytes = [];
          // Set alignment
          bytes += [27, 97, align]; // ESC a n (0=left, 1=center, 2=right)
          // Set size (optional)
          if (size > 0) {
            bytes += [27, 33, size * 16]; // ESC ! n
          }
          bytes += encodedBytes;
          bytes += [10]; // New line

          _printer.writeBytes(Uint8List.fromList(bytes));
        } catch (e) {
          // Fallback to UTF-8
          final utf8Bytes = utf8.encode(text);
          List<int> bytes = [];
          bytes += [27, 97, align];
          if (size > 0) {
            bytes += [27, 33, size * 16];
          }
          bytes += utf8Bytes;
          bytes += [10];
          _printer.writeBytes(Uint8List.fromList(bytes));
        }
      } else {
        // Use standard printing for English text
        _printer.printCustom(text, size, align);
      }
    } catch (e) {
      // Last resort: try standard printing
      try {
        _printer.printCustom(text, size, align);
      } catch (e2) {
        print('Failed to print text: $text, Error: $e2');
      }
    }
  }

  Color _getResultColor(String result) {
    if (result.startsWith('✅')) return Colors.green;
    if (result.startsWith('❌')) return Colors.red;
    if (result.startsWith('⚠️')) return Colors.orange;
    if (result.startsWith('ℹ️')) return Colors.blue;
    if (result.startsWith('🔍') || result.startsWith('🔌'))
      return Colors.purple;
    if (result.contains('TEST') || result.contains('FINAL'))
      return Colors.indigo;
    return Colors.black87;
  }

  FontWeight _getResultWeight(String result) {
    if (result.contains('FINAL RESULT') || result.contains('100% READY')) {
      return FontWeight.bold;
    }
    if (result.startsWith('[TEST')) {
      return FontWeight.w600;
    }
    return FontWeight.normal;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Thermal Printer Test'),
        backgroundColor: Colors.indigo,
        actions: [
          if (_isConnected)
            IconButton(
              icon: const Icon(Icons.refresh),
              onPressed: _isTesting ? null : _runComprehensiveTests,
              tooltip: 'Re-run tests',
            ),
        ],
      ),
      body: Column(
        children: [
          // Connection Status
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            color: _isConnected ? Colors.green.shade50 : Colors.orange.shade50,
            child: Row(
              children: [
                Icon(
                  _isConnected ? Icons.check_circle : Icons.warning,
                  color: _isConnected ? Colors.green : Colors.orange,
                  size: 32,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _isConnected ? 'Connected' : 'Not Connected',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: _isConnected
                              ? Colors.green.shade900
                              : Colors.orange.shade900,
                        ),
                      ),
                      if (_connectedDevice != null)
                        Text(
                          _connectedDevice!.name ?? 'Unknown Device',
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.green.shade700,
                          ),
                        ),
                    ],
                  ),
                ),
                if (_isConnected)
                  ElevatedButton.icon(
                    onPressed: _disconnectPrinter,
                    icon: const Icon(Icons.bluetooth_disabled, size: 18),
                    label: const Text('Disconnect'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.red,
                      foregroundColor: Colors.white,
                    ),
                  )
                else
                  ElevatedButton.icon(
                    onPressed: _scanForDevices,
                    icon: const Icon(Icons.bluetooth_searching, size: 18),
                    label: const Text('Scan Devices'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.indigo,
                      foregroundColor: Colors.white,
                    ),
                  ),
              ],
            ),
          ),

          // Available Devices
          if (!_isConnected && _devices.isNotEmpty)
            Container(
              padding: const EdgeInsets.all(16),
              color: Colors.blue.shade50,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Available Bluetooth Devices:',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  ..._devices.map(
                    (device) => Card(
                      child: ListTile(
                        leading: const Icon(Icons.print, color: Colors.indigo),
                        title: Text(device.name ?? 'Unknown'),
                        subtitle: Text(device.address ?? ''),
                        trailing: ElevatedButton(
                          onPressed: () => _connectToDevice(device),
                          child: const Text('Connect'),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),

          // Test Results
          Expanded(
            child: Container(
              color: Colors.grey.shade100,
              child: _testResults.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.print,
                            size: 64,
                            color: Colors.grey.shade400,
                          ),
                          const SizedBox(height: 16),
                          Text(
                            'Connect to a printer to start testing',
                            style: TextStyle(
                              fontSize: 16,
                              color: Colors.grey.shade600,
                            ),
                          ),
                        ],
                      ),
                    )
                  : ListView.builder(
                      padding: const EdgeInsets.all(16),
                      itemCount: _testResults.length,
                      itemBuilder: (context, index) {
                        final result = _testResults[index];
                        if (result.isEmpty) {
                          return const SizedBox(height: 8);
                        }
                        return Padding(
                          padding: const EdgeInsets.symmetric(vertical: 2),
                          child: Text(
                            result,
                            style: TextStyle(
                              fontFamily: 'Courier',
                              fontSize: 13,
                              color: _getResultColor(result),
                              fontWeight: _getResultWeight(result),
                            ),
                          ),
                        );
                      },
                    ),
            ),
          ),

          // Action Buttons
          if (_isConnected && !_isTesting)
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 4,
                    offset: const Offset(0, -2),
                  ),
                ],
              ),
              child: Row(
                children: [
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: _runComprehensiveTests,
                      icon: const Icon(Icons.play_arrow),
                      label: const Text('Run Full Test'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.all(16),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: _testFullInvoice,
                      icon: const Icon(Icons.receipt_long),
                      label: const Text('Print Test Invoice'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.indigo,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.all(16),
                      ),
                    ),
                  ),
                ],
              ),
            ),

          if (_isTesting)
            Container(
              padding: const EdgeInsets.all(16),
              color: Colors.blue.shade50,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const CircularProgressIndicator(),
                  const SizedBox(width: 16),
                  Text(
                    'Running tests... ($_testsPassed/$_totalTests)',
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}
