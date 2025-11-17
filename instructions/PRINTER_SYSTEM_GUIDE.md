# Universal Printer System Guide

## Overview
The barber cashier app now supports **WiFi, Bluetooth, and USB printers** for invoice printing. The system automatically detects available printers and maintains connections across app sessions.

---

## Architecture

### Components
1. **PrinterDevice Model** (`lib/screens/casher/models/printer_device.dart`)
   - Represents a printer with connection type, address, and status
   - Supports WiFi (IP + Port), Bluetooth (MAC address), and USB

2. **PrinterService** (`lib/screens/casher/services/printer_service.dart`)
   - Singleton service handling all printer operations
   - Methods: `scanWiFiPrinters()`, `scanBluetoothPrinters()`, `scanUSBPrinters()`
   - Connection management: `connectToPrinter()`, `disconnect()`, `autoReconnect()`
   - Printing: `printBytes()` - Universal method for all printer types
   - Persistence: Saves last connected printer to SharedPreferences

3. **PrinterCubit** (`lib/cubits/printer/printer_cubit.dart`)
   - State management for printer operations
   - States: Scanning, Found, Connecting, Connected, Printing, Success, Error
   - Automatically reconnects on app start

4. **PrinterSelectionScreen** (`lib/screens/casher/printer_selection_screen.dart`)
   - User interface for selecting and connecting printers
   - Tab-based interface: WiFi | Bluetooth | USB
   - Real-time connection status

5. **Updated print_dirct.dart** (`lib/screens/casher/print_dirct.dart`)
   - No longer hardcoded to specific IP
   - Uses universal `PrinterService.printBytes()` method
   - Works with any connected printer type

---

## Usage

### 1. Navigate to Printer Settings
```dart
Navigator.push(
  context,
  MaterialPageRoute(
    builder: (context) => const PrinterSelectionScreen(),
  ),
);
```

### 2. Scan for Printers
- Open the app's printer settings screen
- Select the connection type tab (WiFi/Bluetooth/USB)
- Tap "بحث عن طابعات" (Search for Printers)
- Wait for scanning to complete

### 3. Connect to Printer
- Tap "اتصال" (Connect) next to desired printer
- Connection status appears at the top
- Connected printer is saved automatically

### 4. Print Invoice
```dart
// Just call printInvoiceDirect - it automatically uses connected printer
await printInvoiceDirect(
  customer: selectedCustomer,
  services: cartItems,
  discount: discountPercent,
  cashierName: 'أحمد',
  paymentMethod: 'نقدي',
);
```

---

## Connection Types

### WiFi Printers
- **Scanning**: Searches local network (192.168.1.1-254) on port 9100
- **Connection**: Uses ESC/POS over TCP/IP
- **Requirements**: Printer and device on same WiFi network
- **Best For**: Desktop setups, fixed locations

### Bluetooth Printers
- **Scanning**: Lists paired Bluetooth devices
- **Connection**: Uses Bluetooth serial communication
- **Requirements**: Printer must be paired in device settings first
- **Best For**: Mobile setups, portable printing

### USB Printers
- **Scanning**: Detects USB-connected thermal printers
- **Connection**: USB serial communication (115200 baud)
- **Requirements**: USB OTG adapter for mobile devices
- **Best For**: Dedicated POS stations

---

## Auto-Reconnection

The system automatically reconnects to the last connected printer on app start:

```dart
BlocProvider(
  create: (context) => PrinterCubit()..initialize(), // Calls autoReconnect()
),
```

If reconnection fails, user can manually select a printer from settings.

---

## State Management Flow

```
User Action: Tap "Scan"
    ↓
Cubit: emit PrinterScanning(type)
    ↓
Service: scanWiFiPrinters() / scanBluetoothPrinters() / scanUSBPrinters()
    ↓
Cubit: emit PrintersFound(devices)
    ↓
UI: Display list of printers
    ↓
User Action: Tap "Connect" on a printer
    ↓
Cubit: emit PrinterConnecting(device)
    ↓
Service: connectToPrinter(device)
    ↓
Service: Save to SharedPreferences
    ↓
Cubit: emit PrinterConnected(device)
    ↓
UI: Show success message and connected status
```

---

## Printing Flow

```
User Action: Tap "Print" in casher screen
    ↓
Call: printInvoiceDirect(...)
    ↓
Generate: ESC/POS bytes (generateInvoiceBytes)
    ↓
Service: printBytes(bytes)
    ↓
Route to correct method based on connection type:
    - WiFi → _printToWiFi()
    - Bluetooth → _printToBluetooth()
    - USB → _printToUSB()
    ↓
Cubit: emit PrinterPrintSuccess()
    ↓
UI: Show success message
```

---

## Error Handling

### Common Errors and Solutions

| Error | Cause | Solution |
|-------|-------|----------|
| "No printer connected" | No printer selected | Navigate to printer settings and connect |
| "Failed to connect" | Printer offline/unreachable | Check printer power and network/Bluetooth |
| "Failed to scan WiFi" | Not on WiFi network | Connect device to WiFi |
| "Bluetooth not available" | Bluetooth disabled | Enable Bluetooth in device settings |
| "USB device not found" | USB printer not connected | Connect USB printer with OTG adapter |

---

## Permissions Required

### Android Permissions (android/app/src/main/AndroidManifest.xml)

```xml
<!-- WiFi Scanning -->
<uses-permission android:name="android.permission.INTERNET"/>
<uses-permission android:name="android.permission.ACCESS_WIFI_STATE"/>
<uses-permission android:name="android.permission.ACCESS_NETWORK_STATE"/>

<!-- Bluetooth -->
<uses-permission android:name="android.permission.BLUETOOTH"/>
<uses-permission android:name="android.permission.BLUETOOTH_ADMIN"/>
<uses-permission android:name="android.permission.BLUETOOTH_CONNECT"/>
<uses-permission android:name="android.permission.BLUETOOTH_SCAN"/>

<!-- USB -->
<uses-feature android:name="android.hardware.usb.host"/>
```

### iOS Permissions (ios/Runner/Info.plist)

```xml
<!-- Bluetooth -->
<key>NSBluetoothAlwaysUsageDescription</key>
<string>This app needs Bluetooth to connect to printers</string>
<key>NSBluetoothPeripheralUsageDescription</key>
<string>This app needs Bluetooth to connect to printers</string>
```

---

## Adding Printer Button to Casher Screen

You can add a printer settings button to the app bar in `casher_screen.dart`:

```dart
AppBar(
  title: const Text('نظام الكاشير'),
  actions: [
    // Add printer settings button
    IconButton(
      icon: BlocBuilder<PrinterCubit, PrinterState>(
        builder: (context, state) {
          return Icon(
            Icons.print,
            color: state is PrinterConnected ? Colors.green : null,
          );
        },
      ),
      tooltip: 'إعدادات الطابعة',
      onPressed: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => const PrinterSelectionScreen(),
          ),
        );
      },
    ),
  ],
)
```

---

## Testing Checklist

- [ ] WiFi printer scanning works on local network
- [ ] Bluetooth printer appears in scan results (after pairing)
- [ ] USB printer detected when connected
- [ ] Connection to WiFi printer successful
- [ ] Connection to Bluetooth printer successful
- [ ] Connection to USB printer successful
- [ ] Invoice prints correctly on WiFi printer
- [ ] Invoice prints correctly on Bluetooth printer
- [ ] Invoice prints correctly on USB printer
- [ ] Auto-reconnect works after app restart
- [ ] Disconnection works properly
- [ ] Error messages appear correctly

---

## Troubleshooting

### WiFi Printer Not Found
1. Ensure printer is on same WiFi network as device
2. Check printer IP is in 192.168.1.x range (or modify `scanWiFiPrinters()`)
3. Verify printer port is 9100 (ESC/POS standard)
4. Try pinging printer IP from terminal

### Bluetooth Printer Not Found
1. Pair printer in device Bluetooth settings first
2. Ensure Bluetooth permissions are granted
3. Check printer is in pairing mode
4. Restart Bluetooth on device

### USB Printer Not Detected
1. Ensure USB OTG adapter is working
2. Check USB cable connection
3. Grant USB permissions when prompted
4. Try unplugging and reconnecting

### Print Quality Issues
1. Check printer paper is loaded correctly
2. Verify printer has enough ink/toner (if applicable)
3. Clean printer head if using thermal printer
4. Adjust baud rate in `_connectToUSBPrinter()` if needed

---

## Future Enhancements

- [ ] Manual IP entry for WiFi printers
- [ ] Printer test print function
- [ ] Multiple saved printer profiles
- [ ] Printer configuration options (paper size, density)
- [ ] Print preview before sending
- [ ] Support for other ESC/POS commands (drawer open, beep)
- [ ] Network printer discovery via mDNS/Bonjour
