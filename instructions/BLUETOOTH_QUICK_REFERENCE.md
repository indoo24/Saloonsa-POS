# Bluetooth Classic Quick Reference Card

## 🎯 One-Page Developer Reference

### The Golden Rule
**Thermal printers use Bluetooth Classic (RFCOMM/SPP), NOT BLE**

---

## 📋 Quick Facts

| Aspect | Value |
|--------|-------|
| **Protocol** | Bluetooth Classic (SPP/RFCOMM) |
| **Discovery Method** | `getBondedDevices()` |
| **Pairing Required** | Yes (system-level) |
| **BLE Scanning** | ❌ Never (wrong protocol) |
| **Permission (Android 12+)** | `BLUETOOTH_CONNECT` only |
| **Discovery Time** | < 100ms |
| **Package** | `blue_thermal_printer` |

---

## 💻 Essential Code Snippets

### Discover Printers
```dart
final service = BluetoothClassicPrinterService();

// Pre-flight check
final check = await service.performPreFlightCheck();
if (!check.isReady) {
  showError(check.arabicMessage);
  return;
}

// Get bonded printers
final printers = await service.discoverBondedPrinters();
```

### Request Permission
```dart
final permService = PermissionService();
final result = await permService.requestBluetoothPermissions();

if (result == PermissionResult.granted) {
  // Proceed
} else if (result == PermissionResult.permanentlyDenied) {
  // Open settings
  await permService.openSettings();
}
```

### Connect to Printer
```dart
final bluetooth = BlueThermalPrinter.instance;

// Verify bonded
final bondedDevices = await bluetooth.getBondedDevices();
final device = bondedDevices.firstWhere(
  (d) => d.address == printerAddress,
);

// Connect
await bluetooth.connect(device);
```

---

## ⚠️ Common Mistakes

### ❌ WRONG
```dart
// BLE scanning (won't find thermal printers)
await FlutterBluePlus.startScan();
await ble.scanForDevices();

// Requesting unnecessary permissions
await [bluetoothScan, location].request();
```

### ✅ CORRECT
```dart
// Bluetooth Classic bonded devices
await BlueThermalPrinter.instance.getBondedDevices();

// Minimal permissions
await Permission.bluetoothConnect.request(); // Android 12+ only
```

---

## 🔍 Debugging Checklist

```dart
// 1. Check Bluetooth available
final available = await bluetooth.isAvailable;
print('Bluetooth available: $available');

// 2. Check Bluetooth enabled
final enabled = await bluetooth.isOn;
print('Bluetooth enabled: $enabled');

// 3. Check bonded devices
final bonded = await bluetooth.getBondedDevices();
print('Bonded devices: ${bonded.length}');
bonded.forEach((d) => print('  - ${d.name} (${d.address})'));

// 4. Check permissions (Android 12+)
final hasPermission = await Permission.bluetoothConnect.isGranted;
print('BLUETOOTH_CONNECT granted: $hasPermission');
```

---

## 🎨 User Guidance Templates

### No Printers Found
```dart
showDialog(
  context: context,
  builder: (context) => AlertDialog(
    title: Text('لم يتم العثور على طابعات مقترنة'),
    content: Text(
      'لإعداد طابعة بلوتوث:\n'
      '1. شغّل الطابعة\n'
      '2. افتح إعدادات الأندرويد\n'
      '3. انتقل إلى البلوتوث\n'
      '4. اضغط "البحث عن أجهزة جديدة"\n'
      '5. اختر طابعتك واقترن (PIN: 0000 أو 1234)\n'
      '6. ارجع للتطبيق وابحث مرة أخرى'
    ),
    actions: [
      TextButton(
        onPressed: () => Navigator.pop(context),
        child: Text('إلغاء'),
      ),
      ElevatedButton(
        onPressed: () {
          Navigator.pop(context);
          openAppSettings();
        },
        child: Text('فتح الإعدادات'),
      ),
    ],
  ),
);
```

### Bluetooth Disabled
```dart
showDialog(
  context: context,
  builder: (context) => AlertDialog(
    title: Text('البلوتوث مغلق'),
    content: Text('يرجى تشغيل البلوتوث من إعدادات الجهاز'),
    actions: [
      ElevatedButton(
        onPressed: () {
          Navigator.pop(context);
          openAppSettings();
        },
        child: Text('فتح الإعدادات'),
      ),
    ],
  ),
);
```

---

## 🔐 AndroidManifest.xml

```xml
<!-- Android 8-11: Auto-granted -->
<uses-permission android:name="android.permission.BLUETOOTH"
    android:maxSdkVersion="30"/>
<uses-permission android:name="android.permission.BLUETOOTH_ADMIN"
    android:maxSdkVersion="30"/>

<!-- Android 12+: Only this -->
<uses-permission android:name="android.permission.BLUETOOTH_CONNECT"/>

<!-- NO LONGER NEEDED on Android 12+ -->
<!-- <uses-permission android:name="android.permission.BLUETOOTH_SCAN"/> -->
<!-- <uses-permission android:name="android.permission.ACCESS_FINE_LOCATION"/> -->
```

---

## 📊 Decision Tree

```
User taps "Search for Printers"
         ↓
Is Bluetooth available? → NO → Show "Device not supported"
         ↓ YES
Is Bluetooth enabled? → NO → Show "Enable Bluetooth"
         ↓ YES
Android >= 12? → YES → BLUETOOTH_CONNECT granted? → NO → Request permission
         ↓ YES                                        ↓ YES
Get bonded devices
         ↓
Devices found? → NO → Show "Pairing guide"
         ↓ YES
Display printer list ✅
```

---

## 🚨 Error Codes

| Code | Meaning | Action |
|------|---------|--------|
| `BLUETOOTH_NOT_SUPPORTED` | No BT hardware | Use WiFi printer |
| `BLUETOOTH_DISABLED` | BT turned off | Guide to enable |
| `PERMISSIONS_REQUIRED` | Permission denied | Request again |
| `PAIRING_REQUIRED` | Printer not bonded | Show pairing guide |
| `CONNECTION_TIMEOUT` | Printer not responding | Check if powered on |

---

## 🎯 Testing Scenarios

1. **Happy Path**: Paired printer → appears → connects ✅
2. **No Devices**: Nothing paired → shows guide ✅
3. **Permission Denied**: User denies → clear error ✅
4. **BT Disabled**: BT off → guide to enable ✅
5. **Printer Off**: Paired but off → connection fails with guidance ✅

---

## 📦 Dependencies

```yaml
dependencies:
  blue_thermal_printer: ^1.2.3  # Bluetooth Classic
  permission_handler: ^11.3.1   # Permissions
  device_info_plus: ^11.2.0     # Android version
  logger: ^2.0.2                # Logging
```

---

## 🎓 Key Principles

1. **No BLE scanning** for thermal printers
2. **System pairing required** before app use
3. **Minimal permissions** (only BLUETOOTH_CONNECT on Android 12+)
4. **Clear user guidance** in Arabic
5. **Fast discovery** using bonded devices

---

## ✅ Checklist for New Features

When adding printer features:
- [ ] Use `getBondedDevices()` not BLE scan
- [ ] Check pre-flight before operations
- [ ] Handle Bluetooth disabled state
- [ ] Handle permission denied state
- [ ] Provide Arabic error messages
- [ ] Test on Android 12+
- [ ] Verify no Location permission needed

---

## 📞 Need Help?

1. Read `BLUETOOTH_CLASSIC_VS_BLE_EXPLANATION.md`
2. Check `BLUETOOTH_TESTING_GUIDE.md`
3. Review `BLUETOOTH_CLASSIC_IMPLEMENTATION_COMPLETE.md`
4. Check logs with `Logger`

---

**Remember:** If it's a thermal printer, it's Bluetooth Classic. Always use `getBondedDevices()`. 🎯

---

**Version:** 1.0  
**Last Updated:** January 1, 2026  
**Status:** Production-Ready ✅
