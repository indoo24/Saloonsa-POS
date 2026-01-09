# Bluetooth Printer Discovery - Quick Reference

## 🎯 THE GOLDEN RULE

```
IF paired in Android Bluetooth Settings → MUST appear in app
```

**NO EXCEPTIONS. NO FILTERING. NO EXCUSES.**

---

## 🔧 Core Principle

```dart
// ✅ CORRECT: Show ALL bonded devices
final printers = await bluetooth.getBondedDevices();
return printers; // Return ALL, let user choose

// ❌ WRONG: Filter by name
final filtered = printers.where((p) => 
  p.name.contains('printer') || 
  p.name.contains('thermal')
);
return filtered; // Hides valid printers!
```

---

## 📱 Android 12+ Permissions

### Required Permissions (BOTH are mandatory)
```dart
// 1. BLUETOOTH_CONNECT - to connect to paired devices
await Permission.bluetoothConnect.request();

// 2. BLUETOOTH_SCAN - to list bonded devices (YES, really!)
await Permission.bluetoothScan.request();
```

### Why Both?
- Documentation says: "SCAN only for discovery"
- **Reality:** Samsung/Xiaomi require SCAN for `getBondedDevices()`
- **Solution:** Request BOTH, always

---

## 🔍 Discovery Flow

```
1. Get bonded devices (MANDATORY)
   └─ Show ALL immediately
   └─ User can print right away
   
2. Optional: Run discovery scan
   └─ Max 5 seconds
   └─ Only for NEW unpaired devices
   └─ Merge with bonded list (don't replace!)
```

---

## 📊 Logging Template

```dart
// At start
_logger.i('📱 Device: ${manufacturer} ${model}');
_logger.i('📱 Android: ${version} (SDK ${sdkInt})');
_logger.i('📱 ABI: ${supportedAbis}');

// During discovery
_logger.i('📱 Found ${count} bonded device(s):');
for (device in devices) {
  _logger.i('   📱 ${device.name} (${device.address})');
}

// Summary
_logger.i('TOTAL: ${devices.length}');
_logger.i('Permissions: ${granted ? "✅" : "❌"}');
_logger.i('Bluetooth: ${enabled ? "✅" : "❌"}');
```

---

## 🚫 Common Mistakes

### Mistake 1: Filtering bonded devices
```dart
// ❌ WRONG
if (device.name.contains('printer')) {
  return device;
}
```

**Fix:** Return ALL bonded devices

### Mistake 2: Making BLUETOOTH_SCAN optional on Android 12+
```dart
// ❌ WRONG
if (!scanGranted) {
  _logger.w('Scan not granted, continuing anyway');
  return true; // Pretend success
}
```

**Fix:** Require SCAN, return false if denied

### Mistake 3: Not logging device info
```dart
// ❌ WRONG
_logger.i('Discovery complete');
```

**Fix:** Log manufacturer, model, ABI, Android version

### Mistake 4: Trusting discovery scan over bonded devices
```dart
// ❌ WRONG
final devices = await bluetooth.scan(); // Only scan
return devices; // Missing bonded devices!
```

**Fix:** Get bonded first, scan is optional

---

## ✅ Verification Checklist

Before deploying:
- [ ] ALL bonded devices shown (no filtering)
- [ ] BLUETOOTH_SCAN required on Android 12+
- [ ] Device info logged (manufacturer, model, ABI, SDK)
- [ ] Each printer logged individually
- [ ] Works on Samsung device (Android 12+)
- [ ] Works on Xiaomi device (Android 12+)
- [ ] Works on arm64-v8a device
- [ ] Printer with generic name (e.g., "BT-58") appears

---

## 🎯 Success Metrics

```
Bonded in Android Settings = Visible in App
100% = 100%
```

If this is not true, there's a bug.

---

## 🔗 Related Files

- `lib/services/unified_printer_discovery_service.dart` - Main discovery logic
- `lib/services/bluetooth_classic_printer_service.dart` - Classic Bluetooth
- `lib/screens/casher/services/printer_service.dart` - Service layer
- `BLUETOOTH_DISCOVERY_FIX_PRODUCTION.md` - Full documentation

---

**Remember:** User's Android Settings is the source of truth. Our job is to show what's there.
