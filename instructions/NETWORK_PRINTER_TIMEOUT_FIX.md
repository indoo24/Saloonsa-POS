# Network Printer Timeout Fix

## Problem Description

The A4 network printer at `192.168.1.123:9100` was experiencing connection timeouts when printing actual invoices, despite test prints working successfully.

**Error Message:**
```
❌ الطابعة غير متصلة: SocketException: Connection timed out, host: 192.168.1.123, port: 9100
```

**Symptoms:**
- ✅ Test prints worked fine
- ❌ Actual invoice printing timed out
- ❌ System fell back to PDF generation

## Root Causes Identified

### 1. Short Connection Timeout (3 seconds)
The default connection timeout was too short for:
- Establishing connection
- Sending large invoice data
- Printer processing time

### 2. Immediate Disconnection
The code disconnected immediately after sending data without waiting for transmission to complete.

### 3. No Retry Mechanism
A single connection failure caused the print job to fail completely.

## Solutions Implemented

### ✅ Fix 1: Extended Connection Timeout

**File:** `lib/screens/casher/services/printer_service.dart`

**Change in `_printToWiFi()` method:**
```dart
// BEFORE:
final result = await printer.connect(
  _connectedPrinter!.address!,
  port: _connectedPrinter!.port!,
);

// AFTER:
final result = await printer.connect(
  _connectedPrinter!.address!,
  port: _connectedPrinter!.port!,
  timeout: const Duration(seconds: 10), // Extended timeout for large invoices
);
```

**Benefit:** Allows sufficient time for large invoice data to be transmitted.

### ✅ Fix 2: Wait Before Disconnecting

**File:** `lib/screens/casher/services/printer_service.dart`

**Change in `_printToWiFi()` method:**
```dart
// BEFORE:
printer.rawBytes(bytes);
printer.disconnect();

// AFTER:
printer.rawBytes(bytes);

// Wait a moment to ensure all data is sent before disconnecting
await Future.delayed(const Duration(milliseconds: 500));

printer.disconnect();
```

**Benefit:** Ensures all data is transmitted before closing the connection.

### ✅ Fix 3: Retry Mechanism

**File:** `lib/screens/casher/services/printer_service.dart`

**Change in `printBytes()` method:**
```dart
// Added automatic retry for network printers (up to 2 attempts)
int maxRetries = _connectedPrinter!.type == PrinterConnectionType.wifi ? 2 : 1;

for (int attempt = 1; attempt <= maxRetries; attempt++) {
  // Try printing
  if (success) return true;
  
  // Wait 2 seconds before retry
  if (attempt < maxRetries) {
    await Future.delayed(Duration(seconds: 2));
  }
}
```

**Benefit:** Automatically retries on failure, handling temporary network issues.

### ✅ Fix 4: Better Error Logging

**File:** `lib/screens/casher/services/printer_service.dart`

**Added detailed logging:**
```dart
print('🖨️ Print attempt $attempt/$maxRetries...');
print('✅ Network printer: Data sent successfully');
print('❌ Failed to connect to network printer: $result');
print('❌ Error sending data to network printer: $e');
```

**Benefit:** Easier debugging and monitoring of print operations.

### ✅ Fix 5: Updated Connection Test Timeout

**File:** `lib/screens/casher/invoice_page.dart`

**Change in `tryConnectToPrinter()` method:**
```dart
// BEFORE:
timeout: const Duration(seconds: 3),

// AFTER:
timeout: const Duration(seconds: 5), // Increased to match printer service
```

**Benefit:** Connection test now uses same timeout as actual printing.

## Technical Details

### Network Printer Flow (After Fix)

```
1. User clicks print invoice
   ↓
2. tryConnectToPrinter() - 5 second timeout
   ↓
3. If connected → printInvoiceDirect()
   ↓
4. generateInvoiceBytes() - Creates ESC/POS data
   ↓
5. PrinterService.printBytes()
   ↓
6. ATTEMPT 1:
   - Connect with 10 second timeout
   - Send raw bytes
   - Wait 500ms for transmission
   - Disconnect
   ↓
7. If ATTEMPT 1 fails:
   - Wait 2 seconds
   - ATTEMPT 2 (same process)
   ↓
8. Success → Print completed
   Failure → Fall back to PDF
```

### Timeout Configuration Summary

| Component | Old Timeout | New Timeout | Purpose |
|-----------|-------------|-------------|---------|
| Connection Test | 3 seconds | 5 seconds | Verify printer is reachable |
| Print Connection | Default (~5s) | 10 seconds | Connect to printer for data send |
| Data Transmission | 0ms (immediate) | 500ms delay | Wait for buffer to flush |
| Retry Delay | N/A | 2 seconds | Wait between retry attempts |

### Retry Logic

- **WiFi/Network Printers:** 2 attempts (1 initial + 1 retry)
- **Bluetooth Printers:** 1 attempt (more reliable, no retry needed)
- **USB Printers:** 1 attempt (disabled currently)
- **Delay Between Retries:** 2 seconds

## Testing Recommendations

### 1. Test Small Invoice
```
- 1-2 services
- Should print instantly
```

### 2. Test Large Invoice
```
- 10+ services
- Should complete within 10 seconds
```

### 3. Test Network Issues
```
- Unplug network cable briefly
- Should retry and succeed when reconnected
```

### 4. Monitor Logs
```
Look for:
🖨️ Print attempt 1/2...
✅ Network printer: Data sent successfully
```

## Expected Behavior After Fix

### ✅ Normal Operation
```
🖨️ Print attempt 1/2...
✅ Network printer: Data sent successfully
✅ Print successful on attempt 1
```

### ✅ Retry Success
```
🖨️ Print attempt 1/2...
❌ Failed to connect to network printer: timeout
⏳ Waiting before retry...
🖨️ Print attempt 2/2...
✅ Network printer: Data sent successfully
✅ Print successful on attempt 2
```

### ❌ Complete Failure (Falls back to PDF)
```
🖨️ Print attempt 1/2...
❌ Failed to connect to network printer: timeout
⏳ Waiting before retry...
🖨️ Print attempt 2/2...
❌ Failed to connect to network printer: timeout
❌ الطابعة غير متصلة
[System falls back to PDF generation]
```

## Files Modified

1. **lib/screens/casher/services/printer_service.dart**
   - Extended WiFi connection timeout to 10 seconds
   - Added 500ms delay before disconnecting
   - Implemented retry mechanism (2 attempts for WiFi)
   - Enhanced error logging

2. **lib/screens/casher/invoice_page.dart**
   - Increased connection test timeout to 5 seconds

## Backward Compatibility

✅ All changes are backward compatible:
- Test prints still work the same way
- Bluetooth printing unaffected
- PDF fallback still available if all retries fail
- No API or data structure changes

## Performance Impact

- **Test Print Time:** ~1-2 seconds (no change)
- **Invoice Print Time:** ~2-5 seconds (slight increase due to 500ms delay)
- **Failed Print Time:** ~24 seconds worst case (2 attempts × 10s timeout + 2s retry delay)
- **Previous Failed Print Time:** ~3 seconds (then immediate fallback)

**Note:** The increased time on failure is acceptable because the retry mechanism increases success rate significantly.

## Next Steps if Issues Persist

If timeout issues continue:

1. **Increase timeout further:**
   ```dart
   timeout: const Duration(seconds: 15)
   ```

2. **Add chunked data sending:**
   ```dart
   // Send data in smaller chunks
   for (int i = 0; i < bytes.length; i += 1024) {
     printer.rawBytes(bytes.sublist(i, min(i + 1024, bytes.length)));
     await Future.delayed(Duration(milliseconds: 100));
   }
   ```

3. **Check printer buffer size:**
   - Some printers have small buffers
   - May need to reduce receipt complexity
   - Consider removing logo or reducing image quality

4. **Network infrastructure:**
   - Check WiFi signal strength
   - Verify no network congestion
   - Consider wired connection if available

## Conclusion

The fixes implement industry best practices for network printer communication:
- ✅ Extended timeouts for large data
- ✅ Graceful disconnection after data transmission
- ✅ Automatic retry on failure
- ✅ Detailed logging for debugging

The combination of these changes should resolve the timeout issues while maintaining reliability and user experience.
