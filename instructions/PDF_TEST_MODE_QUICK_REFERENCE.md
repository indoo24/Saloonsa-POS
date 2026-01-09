# PDF Test Mode - Quick Reference Card

## 🎯 ONE-LINER

Preview thermal receipts as A4 PDF for testing without a physical printer.

---

## 🚀 QUICK START

```dart
// 1. Enable test mode
PrinterService().thermalPdfTestMode = true;

// 2. Print normally
await PrinterService().printInvoiceDirectFromData(invoiceData);

// 3. PDF preview opens automatically ✅
```

---

## 📁 FILES

| File | Purpose |
|------|---------|
| `lib/services/thermal_pdf_test_service.dart` | PDF test mode service |
| `lib/screens/casher/services/printer_service.dart` | Routing logic (modified) |
| `instructions/PDF_TEST_MODE_GUIDE.md` | Full documentation |
| `instructions/QUICK_START_PDF_TEST_MODE.md` | Quick guide |

---

## 🔧 CONFIGURATION

### Enable Test Mode
```dart
printerService.thermalPdfTestMode = true;
```

### Disable Test Mode (Production)
```dart
printerService.thermalPdfTestMode = false;  // ⚠️ Required for production!
```

---

## 📊 ROUTING LOGIC

```
printInvoiceDirectFromData()
    ↓
if (thermalPdfTestMode == true)
    ↓
    ThermalPdfTestService.previewThermalReceiptAsPdf()
    ↓
    PDF Preview Opens
    
else
    ↓
    ImageBasedThermalPrinter.generateImageBasedReceipt()
    ↓
    Thermal Printer Prints
```

---

## ✅ WHAT IT DOES

- ✅ Renders thermal receipt to image
- ✅ Embeds image in A4 PDF
- ✅ Opens PDF preview dialog
- ✅ Allows printing to A4 printer
- ✅ Shows exact thermal layout
- ✅ Supports Arabic/RTL perfectly

---

## ❌ WHAT IT DOES NOT DO

- ❌ Modify production thermal printing
- ❌ Send ESC/POS commands
- ❌ Affect real thermal printers
- ❌ Duplicate layout logic
- ❌ Rely on text encoding

---

## 🧪 TESTING

### Verify
- [ ] Arabic text correct?
- [ ] RTL layout proper?
- [ ] All data visible?
- [ ] Spacing looks good?
- [ ] Paper size correct?

### Test Both Modes
```dart
// Test mode
printerService.thermalPdfTestMode = true;
await printerService.printInvoiceDirectFromData(data);
// Check PDF ✅

// Production mode
printerService.thermalPdfTestMode = false;
await printerService.printInvoiceDirectFromData(data);
// Check thermal print ✅
```

---

## 📝 LOGGING

Look for these in console:

```
[PDF TEST] ═══════════════════════════════════════════
[PDF TEST] Generating thermal receipt preview as PDF
[PDF TEST] Paper size: 80mm
[PDF TEST] ═══════════════════════════════════════════
```

---

## ⚠️ PRODUCTION CHECKLIST

Before deploying:

- [ ] `thermalPdfTestMode = false` ✅
- [ ] Thermal printing tested ✅
- [ ] No test-only code ✅
- [ ] Logs reviewed ✅

---

## 🆘 TROUBLESHOOTING

| Issue | Solution |
|-------|----------|
| PDF doesn't open | Check `printing` package installed |
| Wrong layout | Check `ThermalReceiptImageWidget` |
| Arabic missing | Verify Google Fonts loaded |
| Thermal broken | Ensure test mode is OFF |

---

## 📞 SUPPORT

1. Check logs for `[PDF TEST]` entries
2. Read `PDF_TEST_MODE_GUIDE.md`
3. Verify flag: `printerService.thermalPdfTestMode`
4. Test with real thermal printer (test mode OFF)

---

## 🎯 KEY POINTS

1. **Single Flag**: `thermalPdfTestMode` controls everything
2. **Same Widget**: Uses `ThermalReceiptImageWidget` (no duplication)
3. **Safe Default**: OFF by default (production safe)
4. **Zero Impact**: Production thermal printing unchanged
5. **Full Preview**: See exact thermal output on A4

---

## 📦 DEPENDENCIES

Already in `pubspec.yaml`:
- `pdf: ^3.11.0`
- `printing: ^5.13.0`
- `logger: ^2.0.2+1`

No additional packages needed! ✅

---

## 🎨 PAPER SIZES

| Thermal | Pixels | PDF Width |
|---------|--------|-----------|
| 58mm | 384px | 165pt |
| 80mm | 576px | 220pt |

---

## 💡 TIP

Use test mode during development, then disable for production:

```dart
// Development
#if DEBUG
  printerService.thermalPdfTestMode = true;
#else
  printerService.thermalPdfTestMode = false;
#endif
```

---

## ✨ BENEFITS

- 🔍 Test without printer
- 🐛 Debug layout easily
- 🌍 Work remotely
- ⚡ Fast iteration
- 📝 Document designs
- ✅ Validate before deploy

---

**Remember**: Test mode is for TESTING ONLY, not for production receipts.

**Default Setting**: `false` (production safe)

**Status**: ✅ Production Ready
