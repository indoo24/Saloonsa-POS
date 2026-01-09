# BLUETOOTH PERMISSIONS - ANDROID 8-14 REFERENCE

## 🎯 QUICK REFERENCE

### Permission Requirements by Android Version

| Android Version | API Level | Bluetooth Permission | Location Permission | Notes |
|----------------|-----------|---------------------|-------------------|-------|
| **Android 8-9** | 26-28 | ✅ Auto-granted | ❌ Not required | Legacy permissions |
| **Android 10-11** | 29-30 | ✅ Auto-granted | ⚠️ Required for scanning | Only for BLE |
| **Android 12+** | 31+ | 🔑 BLUETOOTH_CONNECT | ❌ Not required | Runtime permission |

---

## 📱 ANDROID 8-11 (API 26-30)

### Permissions in AndroidManifest.xml

```xml
<!-- Legacy Bluetooth permissions (auto-granted at install) -->
<uses-permission 
    android:name="android.permission.BLUETOOTH" 
    android:maxSdkVersion="30"/>
    
<uses-permission 
    android:name="android.permission.BLUETOOTH_ADMIN" 
    android:maxSdkVersion="30"/>

<!-- Location (ONLY if doing BLE scanning) -->
<uses-permission 
    android:name="android.permission.ACCESS_FINE_LOCATION" 
    android:maxSdkVersion="30"/>
<uses-permission 
    android:name="android.permission.ACCESS_COARSE_LOCATION" 
    android:maxSdkVersion="30"/>
```

### Runtime Behavior

✅ **Bluetooth Classic (RFCOMM/SPP):**
- No runtime permissions needed
- Permissions granted automatically at install
- Can access bonded devices immediately
- Can connect to paired printers without prompts

⚠️ **BLE Scanning (Not used for thermal printers):**
- Requires runtime Location permission
- User must manually grant
- Only needed for discovering NEW BLE devices

### For This Application (Bluetooth Classic Thermal Printers)

```dart
// Android 8-11: No runtime permission checks needed
final androidInfo = await DeviceInfoPlugin().androidInfo;
final sdkInt = androidInfo.version.sdkInt;

if (sdkInt < 31) {
  // Bluetooth permissions are auto-granted
  // Proceed directly to bonded device discovery
  final printers = await bluetoothPrinter.getBondedDevices();
}
```

---

## 📱 ANDROID 12+ (API 31+)

### Permissions in AndroidManifest.xml

```xml
<!-- New Bluetooth permission model -->
<uses-permission android:name="android.permission.BLUETOOTH_CONNECT"/>

<!-- BLUETOOTH_SCAN is NOT REQUIRED for bonded devices -->
<!-- Only needed for discovering NEW BLE devices -->
```

### Runtime Behavior

🔑 **BLUETOOTH_CONNECT:**
- **Required:** Access bonded (paired) devices
- **Required:** Connect to Bluetooth Classic devices (RFCOMM/SPP)
- **Runtime permission:** Must request from user
- **When to request:** Before first Bluetooth operation

❌ **BLUETOOTH_SCAN:**
- **NOT REQUIRED:** For bonded device access
- **ONLY REQUIRED:** For discovering NEW BLE devices
- **This app:** Does NOT use this permission

❌ **Location:**
- **NOT REQUIRED:** On Android 12+
- **Old requirement:** Only for BLE scanning on Android < 12
- **Removed:** No longer needed for bonded Bluetooth Classic devices

### Request Permission

```dart
// Android 12+: Request BLUETOOTH_CONNECT
if (sdkInt >= 31) {
  final status = await Permission.bluetoothConnect.request();
  
  if (status.isGranted) {
    // Permission granted - proceed
    final printers = await bluetoothPrinter.getBondedDevices();
  } else if (status.isPermanentlyDenied) {
    // User must enable in Settings
    openAppSettings();
  } else {
    // User denied - show explanation
    showPermissionRationale();
  }
}
```

---

## 🔐 PERMISSION SERVICE IMPLEMENTATION

Our `BluetoothValidationService` handles all permission logic correctly:

```dart
Future<BluetoothValidationResult> validate() async {
  // Get Android version
  final androidInfo = await DeviceInfoPlugin().androidInfo;
  final sdkInt = androidInfo.version.sdkInt;

  if (sdkInt < 31) {
    // Android 8-11: Permissions auto-granted
    return BluetoothValidationResult.ready();
  } else {
    // Android 12+: Check BLUETOOTH_CONNECT
    final connectStatus = await Permission.bluetoothConnect.status;
    
    if (!connectStatus.isGranted) {
      if (connectStatus.isPermanentlyDenied) {
        return BluetoothValidationResult.permissionsPermanentlyDenied();
      }
      return BluetoothValidationResult.permissionsNotGranted();
    }
    
    return BluetoothValidationResult.ready();
  }
}
```

---

## 📋 COMPARISON: BLE vs BLUETOOTH CLASSIC

### Bluetooth Low Energy (BLE)

**Permissions:**
- Android < 12: `ACCESS_FINE_LOCATION` (runtime)
- Android 12+: `BLUETOOTH_SCAN` (runtime)

**Use cases:**
- Fitness trackers
- Smart watches
- BLE beacons
- Medical devices

**Our app:** ❌ **NOT USED**

### Bluetooth Classic (RFCOMM/SPP)

**Permissions:**
- Android < 12: Auto-granted at install
- Android 12+: `BLUETOOTH_CONNECT` (runtime)

**Use cases:**
- Thermal printers (ESC/POS)
- Audio devices
- File transfer
- Serial communication

**Our app:** ✅ **USED**

---

## ⚠️ COMMON MISTAKES TO AVOID

### ❌ WRONG: Requesting BLUETOOTH_SCAN

```dart
// WRONG - Not needed for bonded Bluetooth Classic devices
await Permission.bluetoothScan.request(); // ❌ Unnecessary!
await Permission.location.request();      // ❌ Not needed on Android 12+
```

**Why wrong:**
- BLUETOOTH_SCAN is only for discovering NEW BLE devices
- We use bonded (already paired) devices
- Users must pair printers in Android Settings first
- No scanning is performed in the app

### ❌ WRONG: Requesting Location on Android 12+

```dart
// WRONG - Location not needed on Android 12+
if (sdkInt >= 31) {
  await Permission.location.request(); // ❌ Unnecessary!
}
```

**Why wrong:**
- Location was only required for BLE scanning on Android < 12
- Android 12+ changed permission model
- Bonded Bluetooth Classic devices don't need Location
- Users will be confused by unnecessary permission request

### ✅ CORRECT: Only BLUETOOTH_CONNECT on Android 12+

```dart
// CORRECT - Only what we need
if (sdkInt >= 31) {
  await Permission.bluetoothConnect.request(); // ✅ Required
}
// No other permissions needed!
```

---

## 🧪 TESTING PERMISSIONS

### Test Scenarios

**1. Android 11 Device**
```
Expected behavior:
✅ No permission prompts
✅ Direct access to bonded devices
✅ Immediate connection capability
```

**2. Android 12+ Device (First Launch)**
```
Expected behavior:
⚠️ BLUETOOTH_CONNECT permission prompt
✅ Clear explanation of why needed
✅ Grant → Access bonded devices
❌ Deny → Show user-friendly error
```

**3. Android 12+ Device (Permission Denied)**
```
Expected behavior:
❌ Cannot access bonded devices
✅ Clear error message in Arabic
✅ "Open Settings" button
✅ Instructions on how to enable
```

**4. Android 12+ Device (Permission Permanently Denied)**
```
Expected behavior:
❌ Cannot request permission again
✅ Direct to Settings
✅ Step-by-step instructions
```

---

## 🔧 DEBUGGING PERMISSION ISSUES

### Check Current Permissions

```dart
final androidInfo = await DeviceInfoPlugin().androidInfo;
final sdkInt = androidInfo.version.sdkInt;

print('Android SDK: $sdkInt');

if (sdkInt >= 31) {
  final connectStatus = await Permission.bluetoothConnect.status;
  print('BLUETOOTH_CONNECT: $connectStatus');
}

final btAvailable = await bluetoothPrinter.isAvailable;
print('Bluetooth available: $btAvailable');

final btEnabled = await bluetoothPrinter.isOn;
print('Bluetooth enabled: $btEnabled');
```

### Common Issues

**"Permission denied" on Android 12+**
- ✅ Solution: Request BLUETOOTH_CONNECT permission
- ❌ Don't: Request BLUETOOTH_SCAN or Location

**"No devices found" on Android 12+**
- ✅ Check: BLUETOOTH_CONNECT granted
- ✅ Check: Devices are paired in Android Settings
- ❌ Don't: Try to scan for new devices

**"Location required" error**
- ✅ Solution: Update to Android 12+ permission model
- ❌ Don't: Request Location on Android 12+

---

## 📚 OFFICIAL ANDROID DOCUMENTATION

- [Bluetooth permissions](https://developer.android.com/guide/topics/connectivity/bluetooth/permissions)
- [Android 12 Bluetooth changes](https://developer.android.com/about/versions/12/features/bluetooth-permissions)
- [Request runtime permissions](https://developer.android.com/training/permissions/requesting)

---

## ✅ IMPLEMENTATION STATUS

| Requirement | Status | Notes |
|------------|--------|-------|
| Android 8-11 support | ✅ Complete | Auto-granted permissions |
| Android 12+ support | ✅ Complete | BLUETOOTH_CONNECT only |
| Permission validation | ✅ Complete | BluetoothValidationService |
| Version-aware logic | ✅ Complete | Correct permissions per version |
| No unnecessary permissions | ✅ Complete | No SCAN, no Location on 12+ |
| User-friendly errors | ✅ Complete | Arabic error messages |
| Settings navigation | ✅ Complete | Direct to Settings when needed |

---

**Last Updated:** January 1, 2026  
**System:** Barbershop Cashier POS  
**Scope:** Android 8-14 (API 26-34)
