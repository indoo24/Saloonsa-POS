# 🔧 Thermal Printing - Quick Troubleshooting Guide

## 🎯 Quick Diagnosis

### Symptom: Print only works when app is closed
**Status:** ✅ **FIXED** (Socket flush implementation)

### Symptom: Print is slow (2-3 seconds)
**Status:** ✅ **EXPECTED** (Socket drain time - this is CORRECT behavior)

### Symptom: Print cuts off or is incomplete
**Action:** Increase drain delay in `_printToWiFi()`:
```dart
await Future.delayed(Duration(milliseconds: 500));  // Try 800ms
```

### Symptom: Print takes too long
**Action:** Decrease drain delay (minimum 300ms for WiFi):
```dart
await Future.delayed(Duration(milliseconds: 300));  // Minimum safe value
```

### Symptom: Bluetooth print incomplete
**Action:** Increase Bluetooth wait time:
```dart
await Future.delayed(Duration(milliseconds: 1500));  // Try 2000ms
```

---

## 📋 Log Analysis

### Normal Successful Print (WiFi)
```
[PRINT] ========== START PRINT JOB ==========
[PRINT] Printer: Network Printer
[PRINT] Type: PrinterConnectionType.wifi
[PRINT] Data size: 4567 bytes
[PRINT] 📡 Connecting to WiFi printer...
[PRINT] ✅ Socket opened
[PRINT] 📤 Sending 4567 bytes...
[PRINT] ✅ Bytes added to socket buffer
[PRINT] 🔄 Flushing socket...
[PRINT] ✅ Socket flushed
[PRINT] ⏳ Waiting for socket drain...
[PRINT] ✅ Socket drained
[PRINT] 🔒 Closing socket...
[PRINT] ✅ Socket closed
[PRINT] ✅ WiFi print transmission complete
[PRINT] ========== END PRINT JOB ==========
```

### Connection Failed
```
[PRINT] ========== START PRINT JOB ==========
[PRINT] 📡 Connecting to WiFi printer...
[PRINT] ❌ WiFi print error: SocketException: Connection refused
[PRINT] ❌ FAILED: All retry attempts exhausted
[PRINT] ========== END PRINT JOB ==========
```
**Action:** Check printer IP/port, verify printer is on

### Timeout
```
[PRINT] 📡 Connecting to WiFi printer...
[PRINT] ❌ WiFi print error: TimeoutException after 0:00:10.000000
```
**Action:** Check network connectivity, firewall settings

---

## 🔍 Debugging Commands

### View Real-Time Logs (Android)
```bash
adb logcat | grep PRINT
```

### View Real-Time Logs (iOS - Xcode)
```
Product → Scheme → Edit Scheme → Run → Arguments
Add: -FIRDebugEnabled
```

### Check Socket Timing
Look for time between:
- `Socket opened` → `Socket closed` = **Total transmission time**
- Should be ~700-1000ms for WiFi
- Should be ~1500-2000ms for Bluetooth

---

## ⚙️ Configuration Tuning

### WiFi Printer Settings

| Setting | Default | Fast Network | Slow Network |
|---------|---------|--------------|--------------|
| Socket Timeout | 10s | 5s | 15s |
| Drain Delay | 500ms | 300ms | 800ms |
| Post-Close Delay | 200ms | 100ms | 300ms |
| Max Retries | 2 | 1 | 3 |

### Bluetooth Printer Settings

| Setting | Default | Fast Printer | Slow Printer |
|---------|---------|--------------|--------------|
| Transmission Wait | 1500ms | 1000ms | 2500ms |
| Max Retries | 1 | 1 | 2 |

---

## 🚨 Common Issues & Solutions

### Issue: "No printer connected"
```
[PRINT] ❌ FAILED: No printer connected
```
**Solution:**
1. Go to Settings → Printer
2. Click "Scan for Printers"
3. Select printer
4. Test connection

### Issue: "Socket closed by remote host"
```
[PRINT] ❌ WiFi print error: SocketException: Connection closed by peer
```
**Solution:**
- Printer may have disconnected
- Try reconnecting to printer
- Check printer is not in sleep mode

### Issue: Print is garbled/random characters
**Solution:**
- This is NOT a socket issue
- Check receipt generator encoding
- Verify ESC/POS command format
- Test with different paper size setting

### Issue: First print works, second fails
```
[PRINT] Attempt 1: ✅ SUCCESS
[PRINT] Attempt 2: ❌ Socket already in use
```
**Solution:**
- This should NOT happen with current fix
- If it does, check that socket is closed in all code paths
- Verify no socket reuse is happening

---

## 📊 Performance Benchmarks

### Expected Print Times (WiFi)
- **Small receipt** (500 bytes): ~600ms
- **Medium receipt** (2KB): ~700ms
- **Large receipt** (5KB): ~900ms

### Expected Print Times (Bluetooth)
- **Small receipt** (500 bytes): ~1200ms
- **Medium receipt** (2KB): ~1500ms
- **Large receipt** (5KB): ~2000ms

**If your times are significantly different:**
- Much slower → Check network/printer performance
- Much faster → May indicate incomplete transmission (check printer output)

---

## 🔬 Testing Protocol

### 1. Basic Print Test
```
1. Open app
2. Create invoice
3. Click "Save & Print"
4. Timer start → Wait for print to START (not complete)
5. Timer stop
6. Expected: <2 seconds for WiFi, <2.5 seconds for Bluetooth
```

### 2. Stay On Screen Test
```
1. Create invoice
2. Click "Save & Print"
3. DO NOT navigate away
4. DO NOT background app
5. Expected: Print starts immediately
```

### 3. Rapid Print Test
```
1. Create invoice 1 → Print
2. Immediately create invoice 2 → Print
3. Immediately create invoice 3 → Print
4. Expected: All 3 print in order without errors
```

### 4. Disconnect Test
```
1. Turn off printer
2. Create invoice → Print
3. Expected: Error after 10s timeout, retry attempt, then fail gracefully
```

---

## 🛠️ Manual Socket Timing Adjustment

If you need to adjust timing for your specific printer:

**File:** `lib/screens/casher/services/printer_service.dart`

**WiFi Drain Delay (line ~430):**
```dart
// Slower printer - increase to 800ms
await Future.delayed(Duration(milliseconds: 800));

// Faster printer - decrease to 300ms (minimum)
await Future.delayed(Duration(milliseconds: 300));
```

**WiFi Post-Close Delay (line ~440):**
```dart
// Slower network - increase to 300ms
await Future.delayed(Duration(milliseconds: 300));

// Faster network - decrease to 100ms (minimum)
await Future.delayed(Duration(milliseconds: 100));
```

**Bluetooth Transmission Wait (line ~480):**
```dart
// Slower Bluetooth - increase to 2500ms
await Future.delayed(Duration(milliseconds: 2500));

// Faster Bluetooth - decrease to 1000ms (minimum)
await Future.delayed(Duration(milliseconds: 1000));
```

**⚠️ WARNING:** Do NOT reduce delays below minimums - may cause incomplete prints!

---

## ✅ Verification Checklist

After any timing adjustments:

- [ ] Print test receipt from Settings
- [ ] Create real invoice and print
- [ ] Verify entire receipt printed (not cut off)
- [ ] Check logs show "Transmission complete"
- [ ] Test rapid printing (3 invoices back-to-back)
- [ ] Verify no socket errors in logs
- [ ] Test with app staying open (no background)

---

**Last Updated:** December 23, 2025  
**Version:** 1.0.0
