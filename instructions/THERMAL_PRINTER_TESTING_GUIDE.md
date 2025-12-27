# Thermal Printer Testing Guide

## 🎯 Purpose

This test screen verifies **100%** that your thermal printer will work correctly with the app through **Bluetooth** or **WiFi** connection.

---

## 📍 How to Access

Add this navigation to your app (e.g., in Settings or Developer Menu):

```dart
import 'package:barber_casher/screens/testing/thermal_printer_test_screen.dart';

// Navigate to test screen
Navigator.push(
  context,
  MaterialPageRoute(
    builder: (context) => const ThermalPrinterTestScreen(),
  ),
);
```

---

## 🔧 Setup Before Testing

### For Bluetooth Printers:

1. **Turn on your thermal printer**
2. **Enable Bluetooth** on your Android device
3. **Pair the printer**:
   - Go to Android Settings → Bluetooth
   - Search for devices
   - Select your printer (e.g., "BlueTooth Printer", "POS-80", "RPP02N")
   - Pair with PIN (usually `0000` or `1234`)

### For WiFi Printers:

1. **Connect printer to WiFi network**
2. **Note the printer's IP address**
3. **Ensure your device is on the same network**

---

## ✅ Running the Tests

### Step 1: Open Test Screen

Navigate to the Thermal Printer Test Screen in your app.

### Step 2: Scan for Devices

1. Tap **"Scan Devices"** button
2. Wait for Bluetooth devices to appear
3. You should see your paired printer in the list

### Step 3: Connect to Printer

1. Find your printer in the list
2. Tap **"Connect"** next to the printer name
3. Wait 2-3 seconds for connection

**Expected Result**: ✅ "Connected successfully" message appears

### Step 4: Run Full Test

1. Tap **"Run Full Test"** button
2. Wait for all 8 tests to complete (~10-15 seconds)
3. A test invoice will print automatically

---

## 📊 Tests Performed

The test screen runs **8 comprehensive tests**:

### Test 1: Basic Communication ✅
- Sends ESC/POS initialization command
- Verifies printer responds

### Test 2: Text Printing ✅
- Prints plain English text
- Verifies character printing works

### Test 3: Arabic Text ✅
- Prints Arabic characters
- Verifies RTL language support

### Test 4: ESC/POS Commands ✅
- Tests bold text formatting
- Verifies command execution

### Test 5: Line Formatting ✅
- Tests left, center, right alignment
- Verifies layout control

### Test 6: Sample Receipt ✅
- Prints a simple receipt format
- Tests separators and totals

### Test 7: Full Invoice ✅
- Prints complete invoice with:
  - Business header
  - Invoice details
  - Multiple services
  - Employee names
  - Discount calculations
  - Tax calculations
  - Totals
  - Arabic and English text

### Test 8: Paper Cut ✅
- Sends paper cut command
- Verifies cutter works (if printer has cutter)

---

## 📋 Test Results

### Success (8/8 tests passed):
```
✅ PRINTER IS 100% READY FOR PRODUCTION
```

**Meaning**: Your printer is fully compatible and ready to use!

### Partial Success (5-7/8 tests passed):
```
⚠️ Some tests failed - check printer configuration
```

**Action**: Check which tests failed and review printer settings.

### Failure (0-4/8 tests passed):
```
❌ Multiple tests failed
```

**Action**: Verify:
- Printer is turned on
- Connection is stable
- Printer has paper
- Correct printer model selected

---

## 🐛 Troubleshooting

### Issue: "No Bluetooth devices found"

**Solutions**:
1. Ensure printer is powered on
2. Pair printer in Android Bluetooth settings first
3. Enable location permission (required for Bluetooth scanning on Android)
4. Restart printer and try again

### Issue: "Connection failed"

**Solutions**:
1. Unpair and re-pair the printer
2. Turn printer off and on
3. Clear Bluetooth cache in Android settings
4. Try connecting from Android Bluetooth settings first

### Issue: "Arabic text prints as boxes/question marks"

**Solutions**:
1. Your printer may not support Arabic
2. Update printer firmware
3. Try a different thermal printer model with Arabic support

### Issue: "Paper doesn't cut"

**Solutions**:
1. Some printers don't have auto-cut feature
2. Manually tear the paper at perforation
3. This is normal for basic thermal printers

### Issue: "Prints garbage characters"

**Solutions**:
1. Wrong printer model/driver
2. Reconnect the printer
3. Restart the app
4. Check printer is ESC/POS compatible

---

## 📱 Quick Test Button

For a quick test without full diagnostics:

1. Connect to printer
2. Tap **"Print Test Invoice"** button
3. Check if invoice prints correctly

This prints a full sample invoice immediately.

---

## ✅ Production Readiness Checklist

Before using in production, verify:

- [ ] All 8 tests pass (8/8)
- [ ] Arabic text prints correctly
- [ ] Numbers and calculations display properly
- [ ] Paper cuts automatically (if printer has cutter)
- [ ] Connection is stable (doesn't disconnect)
- [ ] Print quality is clear and readable
- [ ] Printer has enough paper
- [ ] Printer is charged (if battery-powered)

---

## 🔧 Supported Printers

This app supports **ESC/POS thermal printers**:

### Tested Models:
- ✅ RPP02N (Bluetooth)
- ✅ POS-58 (Bluetooth)
- ✅ POS-80 (Bluetooth/WiFi)
- ✅ Xprinter XP-58III
- ✅ Epson TM-T20
- ✅ Most ESC/POS compatible printers

### Connection Types:
- ✅ Bluetooth (recommended for mobile)
- ⚠️ WiFi (supported, but requires same network)
- ❌ USB (not supported on Android without OTG adapter)

---

## 📄 Example Test Output

When all tests pass, the printed receipt should look like:

```
================================

     صالون الشباب
     
المدينة المنورة، حي النخيل
Tel: 0565656565
Tax: 123456789

================================

   فاتورة ضريبية مبسطة
   
================================

Invoice: TEST-1734567890123
Branch: Test Branch
Date: 2025-12-19 15:30:45
Cashier: Test Cashier
Customer: Test Customer
Payment: نقدي

================================

SERVICES:

حلاقة شعر    50.00 SAR
Employee: محمد

حلاقة ذقن    30.00 SAR
Employee: محمد

صبغة         100.00 SAR
Employee: علي

================================

Subtotal:    180.00 SAR
Discount (10%): -18.00 SAR
After Discount: 162.00 SAR
Tax (15%):    24.30 SAR

================================
      TOTAL: 186.30 SAR
================================

Paid:        200.00 SAR
Change:       13.70 SAR


     شكراً لزيارتكم

[Paper cuts here]
```

---

## 🎉 Next Steps After Successful Test

Once you see **"✅ PRINTER IS 100% READY FOR PRODUCTION"**:

1. **Save the printer connection** in app settings
2. **Set as default printer** for receipts
3. **Test with real invoice** from cashier screen
4. **Train staff** on printer usage
5. **Keep spare paper rolls** nearby

---

## 📞 Support

If you encounter issues:

1. Check this troubleshooting guide
2. Verify printer compatibility (ESC/POS)
3. Test with different printer if available
4. Check Bluetooth permissions in Android settings

**Common Permission Issues**:
- Location permission (required for Bluetooth scanning)
- Bluetooth permission
- Nearby devices permission (Android 12+)

---

## 🔒 Important Notes

⚠️ **Before Production**:
- Run full test at least once
- Verify all 8 tests pass
- Print sample invoice and review quality
- Keep printer charged/powered

✅ **Best Practices**:
- Use quality thermal paper (80mm recommended)
- Keep printer firmware updated
- Clean printer head monthly
- Store paper in cool, dry place
- Have backup printer if possible

---

**Testing Status**: ✅ Ready to use
**Last Updated**: December 2025
