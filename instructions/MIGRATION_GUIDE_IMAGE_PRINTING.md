# Migration Guide: Text-Based to Image-Based Thermal Printing

## 🎯 Overview

This guide helps you migrate from the old text-based ESC/POS printing to the new image-based thermal printing system.

---

## ⚠️ BREAKING CHANGES

### What Changed

#### BEFORE (Old System - ❌ Deprecated)
```dart
// Old way - DON'T USE THIS
import 'receipt_generator.dart';

final bytes = await generateInvoiceBytes(
  customer: customer,
  services: services,
  discount: discount,
  cashierName: cashierName,
  paymentMethod: paymentMethod,
);

await printerService.printBytes(bytes);
```

#### AFTER (New System - ✅ Required)
```dart
// New way - USE THIS
import 'print_dirct.dart';
import '../../models/invoice_data.dart';

final invoiceData = InvoiceData(
  orderNumber: '12345',
  branchName: 'الفرع الرئيسي',
  cashierName: cashierName,
  dateTime: DateTime.now(),
  items: items,
  subtotalBeforeTax: subtotal,
  discountPercentage: discountPercent,
  discountAmount: discountAmount,
  amountAfterDiscount: amountAfterDiscount,
  taxRate: 15.0,
  taxAmount: taxAmount,
  grandTotal: grandTotal,
  paymentMethod: paymentMethod,
  businessName: 'اسم المحل',
  businessAddress: 'العنوان',
  businessPhone: '0501234567',
);

final success = await printInvoiceDirectFromData(data: invoiceData);
```

---

## 📋 Step-by-Step Migration

### Step 1: Create InvoiceData Instead of Raw Parameters

**Old Code:**
```dart
await printInvoiceDirect(
  customer: customer,
  services: services,
  discount: discount,
  cashierName: cashierName,
  paymentMethod: paymentMethod,
  orderNumber: orderNumber,
  branchName: branchName,
  paid: paid,
  remaining: remaining,
);
```

**New Code:**
```dart
// Convert your data to InvoiceData model
final invoiceData = InvoiceData(
  orderNumber: orderNumber ?? DateTime.now().millisecondsSinceEpoch.toString(),
  branchName: branchName ?? 'الفرع الرئيسي',
  cashierName: cashierName,
  dateTime: DateTime.now(),
  
  // Customer info
  customerName: customer?.name,
  customerPhone: customer?.phone,
  
  // Convert services to items
  items: services.map((service) => InvoiceItem(
    name: service.name,
    price: service.price,
    quantity: 1,
    employeeName: service.employeeName,
  )).toList(),
  
  // Financial calculations
  subtotalBeforeTax: subtotal,
  discountPercentage: discount,
  discountAmount: discountAmount,
  amountAfterDiscount: amountAfterDiscount,
  taxRate: 15.0,
  taxAmount: taxAmount,
  grandTotal: grandTotal,
  
  // Payment info
  paymentMethod: paymentMethod,
  paidAmount: paid,
  remainingAmount: remaining,
  
  // Business info
  businessName: 'اسم المحل',
  businessAddress: 'العنوان',
  businessPhone: '0501234567',
  taxNumber: 'رقم ضريبي اختياري',
);

// Print using new method
final success = await printInvoiceDirectFromData(data: invoiceData);
```

### Step 2: Remove Old Imports

**Remove these imports:**
```dart
import 'receipt_generator.dart';           // ❌ Remove
import 'thermal_receipt_generator.dart';   // ❌ Remove
import 'charset_converter';                 // ❌ Remove
import 'sunmi_printer_detector.dart';      // ❌ Remove (for printing)
```

**Add these imports:**
```dart
import 'print_dirct.dart';                 // ✅ Add
import '../../models/invoice_data.dart';   // ✅ Add
```

### Step 3: Update Function Calls

Find and replace all instances:

| Old Function | New Function |
|-------------|--------------|
| `printInvoiceDirect()` | `printInvoiceDirectFromData()` |
| `generateInvoiceBytes()` | N/A (use `printInvoiceDirectFromData()`) |
| `ReceiptGenerator.generateReceipt()` | N/A (use `printInvoiceDirectFromData()`) |
| `ThermalReceiptGenerator.generateThermalReceipt()` | N/A (use `printInvoiceDirectFromData()`) |

### Step 4: Remove Printer Type Detection

**Old Code:**
```dart
// ❌ Remove this - no longer needed
final isSunmi = await SunmiPrinterDetector.isSunmiPrinter();
if (isSunmi) {
  // Use image-based
} else {
  // Use text-based
}
```

**New Code:**
```dart
// ✅ Just print - works on all printers
final success = await printInvoiceDirectFromData(data: invoiceData);
```

---

## 🔄 Common Migration Patterns

### Pattern 1: Invoice Page Printing

**Before:**
```dart
final bytes = await generateInvoiceBytes(
  customer: _selectedCustomer,
  services: _selectedServices,
  discount: _discount,
  cashierName: widget.cashierName,
  paymentMethod: _selectedPaymentMethod,
  orderNumber: orderNumber,
  branchName: _branchName,
);

final printerService = PrinterService();
await printerService.printBytes(bytes);
```

**After:**
```dart
final invoiceData = _buildInvoiceData();  // Helper method
final success = await printInvoiceDirectFromData(data: invoiceData);

if (success) {
  // Handle success
} else {
  // Handle failure
}
```

### Pattern 2: Direct PrinterService Usage

**Before:**
```dart
final printerService = PrinterService();
final bytes = await generateInvoiceBytes(...);
await printerService.printBytes(bytes);
```

**After:**
```dart
final printerService = PrinterService();
await printerService.printInvoiceDirectFromData(invoiceData);
```

### Pattern 3: Test Receipts

**Before:**
```dart
await printerService.printTestReceipt(); // Still works - uses text
```

**After:**
```dart
// Test receipt still uses text (English-only)
await printerService.printTestReceipt();

// For Arabic test, create test InvoiceData
final testData = InvoiceData(/* ... test data ... */);
await printerService.printInvoiceDirectFromData(testData);
```

---

## 🧪 Testing Your Migration

### 1. Compile Check
```bash
flutter pub get
flutter analyze
```

### 2. Search for Deprecated Code
Search your codebase for:
- `ReceiptGenerator`
- `ThermalReceiptGenerator`
- `charset_converter`
- `printInvoiceDirect(` (without "FromData")
- `generateInvoiceBytes`

### 3. Test Printing
- [ ] Test on Sunmi V2
- [ ] Test on non-Sunmi printer (Xprinter, Rongta, etc.)
- [ ] Verify Arabic text prints correctly
- [ ] Verify no squares or garbled characters
- [ ] Check logs show "Rendering receipt as image"

---

## 🐛 Troubleshooting Migration Issues

### Issue: "Undefined class 'Customer'"
**Cause:** Still using old function signature  
**Solution:** Migrate to `InvoiceData` model

### Issue: "The function 'ReceiptGenerator' isn't defined"
**Cause:** Old import is used but file is deprecated  
**Solution:** Remove import and use `printInvoiceDirectFromData()`

### Issue: Arabic still shows squares
**Cause:** Old code path is still being executed  
**Solution:** Check logs - should show "Rendering receipt as image"

### Issue: Compilation errors after migration
**Cause:** Missing InvoiceData fields  
**Solution:** Check InvoiceData model and provide all required fields

---

## ✅ Migration Checklist

Use this checklist for each file you migrate:

- [ ] Removed `import 'receipt_generator.dart'`
- [ ] Removed `import 'thermal_receipt_generator.dart'`
- [ ] Removed `charset_converter` usage
- [ ] Added `import 'print_dirct.dart'`
- [ ] Added `import '../../models/invoice_data.dart'`
- [ ] Created `InvoiceData` object with all required fields
- [ ] Replaced old print function with `printInvoiceDirectFromData()`
- [ ] Removed Sunmi detection logic
- [ ] Tested on actual thermal printer
- [ ] Verified Arabic prints correctly
- [ ] Checked logs show image-based printing

---

## 📞 Need Help?

If you encounter issues during migration:

1. Check the logs - look for "Rendering receipt as image"
2. Verify InvoiceData has all required fields
3. Ensure printer is connected before printing
4. Review the complete example in `IMAGE_BASED_THERMAL_PRINTING_COMPLETE.md`

---

## 🎉 Post-Migration Benefits

After migration, you'll have:

✅ **No Arabic encoding issues** - Works on all printers  
✅ **Simpler code** - One printing method for all printers  
✅ **Better maintainability** - No printer-specific branches  
✅ **Production stability** - Predictable behavior  
✅ **Cleaner dependencies** - No charset_converter needed  

**Welcome to the future of thermal printing! 🚀**
