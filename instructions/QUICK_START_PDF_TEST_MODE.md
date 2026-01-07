# Quick Start: PDF Test Mode

## 🚀 Basic Usage

### Enable Test Mode

In your printing code, enable the test mode flag:

```dart
// Get the printer service instance
final printerService = PrinterService();

// 🧪 Enable PDF test mode
printerService.thermalPdfTestMode = true;

// Now when you print, it will show a PDF preview instead
await printerService.printInvoiceDirectFromData(invoiceData);
```

### Disable Test Mode (Production)

```dart
// 🖨️ Disable test mode for real thermal printing
printerService.thermalPdfTestMode = false;

// Now it will print to the actual thermal printer
await printerService.printInvoiceDirectFromData(invoiceData);
```

## 📝 Complete Example

```dart
import 'package:barber_casher/screens/casher/services/printer_service.dart';
import 'package:barber_casher/models/invoice_data.dart';

Future<void> testReceiptLayout() async {
  // Get printer service
  final printerService = PrinterService();
  
  // Enable test mode
  printerService.thermalPdfTestMode = true;
  
  // Your existing invoice data
  final invoiceData = InvoiceData(
    orderNumber: 'ORDER-001',
    branchName: 'فرع الرياض',
    cashierName: 'أحمد محمد',
    dateTime: DateTime.now(),
    items: [
      InvoiceItem(
        name: 'قص شعر',
        price: 50.0,
        quantity: 1,
        employeeName: 'محمد',
      ),
    ],
    subtotalBeforeTax: 50.0,
    discountPercentage: 0,
    discountAmount: 0,
    amountAfterDiscount: 50.0,
    taxRate: 15,
    taxAmount: 7.5,
    grandTotal: 57.5,
    paymentMethod: 'نقدي',
    paidAmount: 60.0,
    remainingAmount: 0.0,
    businessName: 'صالون الحلاقة',
    businessAddress: 'الرياض، المملكة العربية السعودية',
    businessPhone: '+966 50 123 4567',
    taxNumber: '123456789012345',
  );
  
  // Print (will show PDF preview)
  await printerService.printInvoiceDirectFromData(invoiceData);
  
  // The PDF preview dialog will open automatically
}
```

## 🔧 Direct PDF Service Usage

You can also use the PDF service directly without PrinterService:

```dart
import 'package:barber_casher/services/thermal_pdf_test_service.dart';
import 'package:barber_casher/models/invoice_data.dart';

Future<void> previewReceipt(InvoiceData invoiceData) async {
  // Preview as 80mm thermal receipt
  await ThermalPdfTestService.previewThermalReceiptAsPdf(
    invoiceData,
    paperSize: ThermalPaperSize.mm80, // or ThermalPaperSize.mm58
    receiptName: 'test_receipt',
  );
}
```

## 📋 Testing Checklist

When you open the PDF preview, verify:

- [ ] Arabic text appears correctly
- [ ] RTL layout is proper
- [ ] All data fields are visible
- [ ] Spacing looks good
- [ ] Layout matches your expectations
- [ ] Receipt fits within the paper width (58mm or 80mm)

## 🎯 Common Use Cases

### 1. Test Layout Without Printer

```dart
printerService.thermalPdfTestMode = true;
await printerService.printInvoiceDirectFromData(invoiceData);
// Review the PDF, make changes to the widget if needed
```

### 2. Validate Changes

```dart
// Before making changes to production
printerService.thermalPdfTestMode = true;
await printerService.printInvoiceDirectFromData(invoiceData);
// Review, then update your layout code
```

### 3. Compare Paper Sizes

```dart
// Test 58mm
await ThermalPdfTestService.previewThermalReceiptAsPdf(
  invoiceData,
  paperSize: ThermalPaperSize.mm58,
);

// Test 80mm
await ThermalPdfTestService.previewThermalReceiptAsPdf(
  invoiceData,
  paperSize: ThermalPaperSize.mm80,
);
```

## ⚠️ Important Notes

1. **Always disable test mode in production**:
   ```dart
   printerService.thermalPdfTestMode = false;
   ```

2. **The PDF shows the exact thermal receipt** - same widget, same rendering

3. **No ESC/POS commands** are sent in test mode

4. **Real thermal printing is not affected** when test mode is OFF

## 🐛 Troubleshooting

**PDF doesn't open?**
- Check that the `printing` package is installed
- Check logs for errors (search for `[PDF TEST]`)

**Layout looks wrong?**
- This should never happen (uses same widget)
- If it does, check your `ThermalReceiptImageWidget` for issues

**Want to see logs?**
- Look for `[PDF TEST]` entries in the console
- They show the rendering progress and any errors

## 📦 What Gets Installed

The PDF test mode uses these packages (already in your `pubspec.yaml`):

- `pdf: ^3.11.0` - PDF generation
- `printing: ^5.13.0` - PDF preview dialog
- `logger: ^2.0.2+1` - Logging

No additional dependencies needed!

## ✅ Success Criteria

Your test mode is working correctly when:

- ✅ PDF opens in preview dialog
- ✅ Receipt image is visible and centered
- ✅ Arabic text is correct
- ✅ RTL layout is proper
- ✅ Paper size label matches your choice
- ✅ "Test Mode" indicator is visible
- ✅ Real thermal printing still works when test mode is OFF

---

**Need more details?** See `PDF_TEST_MODE_GUIDE.md` for comprehensive documentation.
