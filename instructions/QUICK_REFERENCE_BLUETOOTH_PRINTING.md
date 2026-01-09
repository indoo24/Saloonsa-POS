# ⚡ BLUETOOTH THERMAL PRINTING - QUICK REFERENCE

## 🎯 ONE-PAGE REFERENCE CARD

---

## 📱 PERMISSIONS BY ANDROID VERSION

```
Android 8-11  (API 26-30):  ✅ Auto-granted (no runtime permission)
Android 12+   (API 31+):    🔑 BLUETOOTH_CONNECT (runtime permission)
```

**Never request:**
- ❌ BLUETOOTH_SCAN (not needed for bonded devices)
- ❌ Location (not needed on Android 12+)

---

## 🔧 BASIC USAGE

### 1. Pre-Flight Check

```dart
final validation = await BluetoothValidationService().validate();
if (!validation.isReady) {
  showError(validation.arabicMessage);
  return;
}
```

### 2. Discover Printers

```dart
final printers = await BluetoothClassicPrinterService()
    .discoverBondedPrinters();
```

### 3. Validate Connection

```dart
final connectionValidation = await PrinterConnectionValidator()
    .validateConnection(device);
if (!connectionValidation.isReady) {
  showError(connectionValidation.arabicMessage);
  return;
}
```

### 4. Print (Image-Based ONLY)

```dart
final bytes = await ImageBasedThermalPrinter
    .generateImageBasedReceipt(invoiceData, paperSize: PaperSize.mm58);

final validation = ThermalPrintEnforcer.validatePrintData(bytes);
if (!validation.isValid) {
  throw Exception(validation.guidanceMessage);
}

await bluetoothPrinter.writeBytes(Uint8List.fromList(bytes));
```

---

## ⚠️ GOLDEN RULES

1. **ALWAYS validate before operations** (pre-flight check)
2. **ONLY use bonded devices** (no scanning)
3. **IMAGE-BASED printing ONLY** (no text/byte commands)
4. **Validate connection before print** (avoid offline printers)
5. **Handle errors in Arabic** (user-friendly messages)

---

## 🚫 FORBIDDEN

❌ Text-based ESC/POS printing  
❌ BLE scanning  
❌ Requesting BLUETOOTH_SCAN permission  
❌ Requesting Location on Android 12+  
❌ Silent failures (always show errors)  
❌ Printing without validation  

---

## ✅ REQUIRED STEPS CHECKLIST

**Before Printing:**
- [ ] Bluetooth environment validated
- [ ] Printer bonded in Android Settings
- [ ] Connection validated
- [ ] Print data is image-based
- [ ] Image dimensions validated

**Print Flow:**
1. Validate environment → 2. Discover printer → 3. Validate connection → 4. Render image → 5. Validate data → 6. Print

---

## 🧪 QUICK TEST

```dart
final result = await TestPrintService().performTestPrint(
  device,
  paperSize: PaperSize.mm58,
);

if (result.overallSuccess) {
  print('✅ All tests passed');
} else {
  print('❌ Failed: ${result.failedTests}');
}
```

---

## 📞 COMMON ERRORS & SOLUTIONS

| Error | Solution |
|-------|----------|
| "Bluetooth disabled" | Enable in Android Settings |
| "No bonded devices" | Pair printer in Android Settings first |
| "Permission denied" | Grant BLUETOOTH_CONNECT (Android 12+) |
| "Printer offline" | Power on printer, move closer |
| "Printer busy" | Disconnect from other device |
| "Text-based printing" | Use ImageBasedThermalPrinter only |

---

## 📚 FILE REFERENCE

| Service | File | Purpose |
|---------|------|---------|
| BluetoothValidationService | `bluetooth_validation_service.dart` | Pre-flight checks |
| PrinterConnectionValidator | `printer_connection_validator.dart` | Connection validation |
| ThermalPrintEnforcer | `thermal_print_enforcer.dart` | Image-based enforcement |
| ImagePipelineValidator | `image_pipeline_validator.dart` | Image validation |
| TestPrintService | `test_print_service.dart` | Comprehensive testing |
| ImageBasedThermalPrinter | `image_based_thermal_printer.dart` | Receipt generation |

---

## 🎯 PAPER SIZES

```dart
PaperSize.mm58  →  384px width
PaperSize.mm80  →  576px width
```

---

## 📋 ERROR CODE REFERENCE

```
E001-E006:  Environment errors
E101-E106:  Connection errors  
E201:       Discovery errors
E301:       Communication errors
E401:       Network errors
E501:       Compatibility errors
E999:       Unknown errors
```

---

## ✅ PRODUCTION DEPLOYMENT CHECKLIST

- [ ] Tested on Android 8-11 device
- [ ] Tested on Android 12+ device
- [ ] Tested with 2+ printer brands
- [ ] Test print shows 100% pass rate
- [ ] Arabic text renders correctly
- [ ] Error messages are user-friendly
- [ ] No crashes or silent failures
- [ ] Documentation complete

---

**Quick Reference Version:** 1.0  
**Date:** January 1, 2026  
**System:** Barbershop Cashier POS

---

**🔖 PRINT THIS PAGE AND KEEP IT HANDY!**
