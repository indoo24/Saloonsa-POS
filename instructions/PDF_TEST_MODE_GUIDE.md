# PDF Test Mode for Thermal Receipts

## 📋 Overview

The PDF Test Mode allows you to preview the exact thermal receipt layout on an A4 PDF without needing a physical thermal printer. This is a **testing and debugging tool only** - it does not replace or modify production thermal printing.

## 🎯 Purpose

- **Test receipt layout** without a thermal printer
- **Validate Arabic text** rendering and RTL layout
- **Debug spacing and alignment** issues
- **Preview receipts** before printing on actual thermal hardware
- **Develop and test** on machines without printer access

## ✅ What It Does

1. **Reuses Production Widget**: Uses the exact same `ThermalReceiptImageWidget` as real thermal printing
2. **Renders to Image**: Converts the widget to an image (identical to thermal printing process)
3. **Embeds in PDF**: Places the thermal receipt image on an A4 page for easy viewing
4. **Opens Preview**: Displays the PDF in the printing dialog for review/printing

## ❌ What It Does NOT Do

- **Does NOT modify** production thermal printing behavior
- **Does NOT send** ESC/POS commands
- **Does NOT affect** real thermal printers (Sunmi, Bluetooth, WiFi, USB)
- **Does NOT duplicate** layout logic (reuses existing widget)

## 🚀 How to Use

### 1. Enable Test Mode

In your code, set the test mode flag to `true`:

```dart
// In PrinterService
PrinterService printerService = PrinterService();
printerService.thermalPdfTestMode = true;
```

### 2. Print as Normal

Call the regular print method - it will automatically route to PDF preview:

```dart
await printerService.printInvoiceDirectFromData(invoiceData);
```

### 3. View the PDF

A PDF preview dialog will open showing:
- The thermal receipt image (centered)
- Paper size indicator (58mm or 80mm)
- Test mode labels
- The exact layout that would appear on thermal printer

### 4. Review and Validate

Check:
- ✅ Arabic text appears correctly
- ✅ RTL layout is proper
- ✅ Spacing and alignment match expectations
- ✅ All data fields are present and formatted correctly

### 5. Disable for Production

**IMPORTANT**: Always disable test mode before deploying to production:

```dart
printerService.thermalPdfTestMode = false; // Production
```

## 🔧 Advanced Usage

### Direct PDF Preview (Without PrinterService)

You can also call the PDF test service directly:

```dart
import 'package:barber_casher/services/thermal_pdf_test_service.dart';

// Preview as PDF
await ThermalPdfTestService.previewThermalReceiptAsPdf(
  invoiceData,
  paperSize: ThermalPaperSize.mm80, // or mm58
  receiptName: 'my_test_receipt',
);
```

### Save PDF to Bytes (For Automation)

Generate PDF bytes without opening the preview dialog:

```dart
Uint8List pdfBytes = await ThermalPdfTestService.saveThermalReceiptAsPdf(
  invoiceData,
  paperSize: ThermalPaperSize.mm58,
);

// Save to file, send via API, etc.
```

## 📐 Technical Details

### Paper Size Mapping

| Thermal Paper | PDF Width | Physical Size |
|---------------|-----------|---------------|
| 58mm          | 165pt     | ~58mm on A4   |
| 80mm          | 220pt     | ~80mm on A4   |

### Rendering Process

```
InvoiceData
    ↓
ThermalReceiptImageWidget (same as production)
    ↓
WidgetToImageRenderer.renderWidgetToImage()
    ↓
ui.Image (384px or 576px wide)
    ↓
Convert to PNG bytes
    ↓
Embed in A4 PDF
    ↓
Display in printing dialog
```

### Image Specifications

- **58mm paper**: 384px wide × dynamic height
- **80mm paper**: 576px wide × dynamic height
- **Pixel ratio**: 3.0 (high quality)
- **Format**: PNG in PDF
- **Color**: Grayscale (optimized for thermal)

## 🧪 Testing Checklist

Before considering test mode implementation successful, verify:

- [ ] PDF shows **identical layout** to thermal printing
- [ ] Arabic text renders **correctly** (no encoding issues)
- [ ] RTL direction is **proper**
- [ ] No image dimension errors occur
- [ ] Real thermal printing **remains untouched** when test mode is OFF
- [ ] Switching between test/production modes works **seamlessly**
- [ ] No ESC/POS commands are sent in test mode

## ⚙️ Configuration

### Flag Location

```dart
// File: lib/screens/casher/services/printer_service.dart
class PrinterService {
  // ...
  
  /// 🧪 PDF TEST MODE FLAG
  /// Set to true for testing, false for production
  bool thermalPdfTestMode = false;
  
  // ...
}
```

### Recommended Settings

**Development/Testing:**
```dart
thermalPdfTestMode = true;  // Preview as PDF
```

**Production:**
```dart
thermalPdfTestMode = false; // Real thermal printing
```

## 🔍 Debugging

### Enable Logging

The test service uses the same logger as production printing. Check logs for:

```
[PDF TEST] ═══════════════════════════════════════════
[PDF TEST] Generating thermal receipt preview as PDF
[PDF TEST] Paper size: 80mm
[PDF TEST] ═══════════════════════════════════════════
[PDF TEST] Receipt image rendered successfully
[PDF TEST]   - Dimensions: 576x1234px
[PDF TEST] Image converted to bytes: 123456 bytes
[PDF TEST] PDF generated: 234567 bytes
[PDF TEST] ═══════════════════════════════════════════
[PDF TEST] PDF preview opened successfully
[PDF TEST] ═══════════════════════════════════════════
```

### Common Issues

**PDF doesn't open:**
- Check that `printing` package is properly installed
- Verify platform permissions (if needed)
- Check logs for exceptions

**Layout looks different:**
- This should never happen - uses same widget
- If it does, check for external layout modifications

**Arabic text missing:**
- Ensure Google Fonts are properly loaded
- Check that Cairo font is available

## 📦 Dependencies

The following packages are used (already in `pubspec.yaml`):

```yaml
dependencies:
  pdf: ^3.11.0        # PDF generation
  printing: ^5.13.0   # PDF preview dialog
  logger: ^2.0.2+1    # Logging
  # ... other existing dependencies
```

## 🎨 Example Output

The PDF will contain:

```
┌─────────────────────────────────────┐
│                                     │
│  Thermal Receipt Preview (80mm)    │
│      Test Mode - For Preview Only   │
│                                     │
│  ┌───────────────────────────────┐ │
│  │                               │ │
│  │     [THERMAL RECEIPT IMAGE]   │ │
│  │     (Exact thermal layout)    │ │
│  │                               │ │
│  └───────────────────────────────┘ │
│                                     │
│  This is a visual preview of the   │
│  thermal receipt.                  │
│  The actual thermal print will     │
│  appear identical to this image.   │
│                                     │
└─────────────────────────────────────┘
```

## ✨ Benefits

1. **No Duplication**: Reuses exact production widget
2. **Pixel-Perfect**: Shows exact thermal output
3. **Clean Separation**: Test mode doesn't affect production
4. **Easy Toggle**: Single flag switches modes
5. **Full Preview**: Can print/save PDF for documentation
6. **Development Friendly**: Test without hardware

## 🚨 Important Notes

### Production Deployment

**ALWAYS** ensure test mode is disabled in production:

```dart
// ❌ NEVER deploy with this:
thermalPdfTestMode = true;

// ✅ Production setting:
thermalPdfTestMode = false;
```

### Not a Replacement

This PDF test mode is **NOT**:
- A replacement for thermal receipts
- For customer-facing receipts
- A different receipt format
- For A4 receipt printing

It is **ONLY** for:
- Testing and debugging
- Layout validation
- Development without hardware

## 📝 Code Structure

```
lib/
├── services/
│   ├── thermal_pdf_test_service.dart     # PDF test mode implementation
│   └── image_based_thermal_printer.dart  # Production thermal printing
├── screens/casher/services/
│   └── printer_service.dart              # Routing logic (test vs production)
└── widgets/
    └── thermal_receipt_image_widget.dart # Shared receipt widget
```

## 🎯 Success Criteria

This implementation is successful when:

✅ PDF shows **exact** thermal receipt layout
✅ Arabic appears **correctly**
✅ RTL is **correct**
✅ No ESC/POS logic runs in test mode
✅ No image dimension errors
✅ Real thermal printing **remains untouched**
✅ Clean toggle between modes

## 📞 Support

For issues or questions:
1. Check logs for `[PDF TEST]` entries
2. Verify `thermalPdfTestMode` flag setting
3. Ensure all dependencies are installed
4. Test with production thermal printing disabled

---

**Remember**: This is a **testing tool**, not a production feature. Always disable test mode before deployment.
