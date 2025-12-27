# New Printing Architecture - Integration Guide

## Overview

The printing system has been completely refactored for production stability with clean separation of concerns:

### Key Principle
**A4 → Pure PDF | Thermal → Pure ESC/POS**

No mixing, no confusion, no hacks.

---

## Architecture Components

### 1. **InvoiceData** (`lib/models/invoice_data.dart`)
Clean data model used by both PDF and Thermal generators.

```dart
final invoiceData = InvoiceData(
  orderNumber: '12345',
  customerName: 'محمد أحمد',
  items: [
    InvoiceItem(name: 'قص شعر', price: 50.0, quantity: 1),
  ],
  grandTotal: 57.50,
  // ... all other fields
);
```

### 2. **ThermalReceiptGenerator** (`lib/services/thermal_receipt_generator.dart`)
Stateless ESC/POS byte generator for thermal printers.

```dart
// Generate thermal receipt bytes
final bytes = await ThermalReceiptGenerator.generateThermalReceipt(
  invoiceData,
  PaperSize.mm80, // or mm58
);

// Send to printer
await printerService.printBytes(bytes);
```

**Features:**
- ✅ Completely stateless (no services, no UI)
- ✅ Windows-1256 Arabic encoding
- ✅ Supports 58mm and 80mm
- ✅ Returns `List<int>` ESC/POS bytes
- ✅ Safe error handling

### 3. **PdfInvoiceGenerator** (`lib/services/pdf_invoice_generator.dart`)
Pure PDF generator for A4 printing.

```dart
// Generate A4 PDF
final pdfBytes = await PdfInvoiceGenerator.generateA4Invoice(invoiceData);

// Print or save
await Printing.layoutPdf(onLayout: (_) => pdfBytes);
```

**Features:**
- ✅ Pure PDF output (NO ESC/POS)
- ✅ Full UTF-8 Arabic support via Cairo font
- ✅ Professional A4 layout
- ✅ Returns `Uint8List` PDF bytes
- ✅ Works offline

### 4. **ThermalReceiptPreviewScreen** (`lib/screens/thermal_receipt_preview_screen.dart`)
Flutter widget preview for thermal receipts.

```dart
// Show preview before printing
Navigator.push(
  context,
  MaterialPageRoute(
    builder: (_) => ThermalReceiptPreviewScreen(
      data: invoiceData,
      paperWidth: PaperWidth.mm80,
      onPrint: () => _printThermal(),
      onClose: () => Navigator.pop(context),
    ),
  ),
);
```

**Features:**
- ✅ Pure Flutter widgets (no bytes)
- ✅ Simulates thermal paper width
- ✅ Arabic text preview
- ✅ Print and Close buttons
- ✅ Works without printer connection

### 5. **InvoiceDataMapper** (`lib/helpers/invoice_data_mapper.dart`)
Helper to convert existing data to InvoiceData.

```dart
// From existing cart/customer data
final invoiceData = InvoiceDataMapper.fromExistingData(
  services: cart,
  customer: customer,
  orderNumber: '12345',
  cashierName: 'Yousef',
  branchName: 'الفرع الرئيسي',
  // ... calculations
);

// From API response
final invoiceData = InvoiceDataMapper.fromApiPrintData(
  printData,
  branchName: 'الفرع الرئيسي',
  businessName: 'صالون الشباب',
);
```

---

## Integration Steps

### Step 1: Check Paper Size Setting

```dart
final printerService = PrinterService();
final paperSize = printerService.settings.paperSize;

if (paperSize == PaperSize.a4) {
  // A4 PDF
} else {
  // Thermal (58mm or 80mm)
}
```

### Step 2: Create InvoiceData

```dart
// Calculate totals
final calculations = _calculateTotals();

// Create invoice data
final invoiceData = InvoiceDataMapper.fromExistingData(
  services: widget.cart,
  customer: widget.customer,
  orderNumber: _orderNumberController.text,
  cashierName: _cashierNameController.text,
  branchName: _branchNameController.text,
  dateTime: DateTime.now(),
  subtotalBeforeTax: calculations['subtotal']!,
  discountPercentage: calculations['discountPercentage']!,
  discountAmount: calculations['discountAmount']!,
  amountAfterDiscount: calculations['amountAfterDiscount']!,
  taxRate: 15.0,
  taxAmount: calculations['taxAmount']!,
  grandTotal: calculations['finalTotal']!,
  paymentMethod: _paymentMethod,
  paidAmount: _paidAmount,
  remainingAmount: _calculateRemaining(),
  businessName: 'صالون الشباب',
  businessAddress: 'الرياض، المملكة العربية السعودية',
  businessPhone: '+966 XX XXX XXXX',
  taxNumber: '1234567890',
  logoPath: 'assets/images/logo.png',
);
```

### Step 3: Route by Paper Size

```dart
if (paperSize == PaperSize.a4) {
  // ========== A4: Pure PDF ==========
  final pdfBytes = await PdfInvoiceGenerator.generateA4Invoice(invoiceData);
  await Printing.layoutPdf(onLayout: (_) => pdfBytes);
  
} else {
  // ========== Thermal: ESC/POS ==========
  
  // Option 1: Direct print
  final bytes = await ThermalReceiptGenerator.generateThermalReceipt(
    invoiceData,
    paperSize,
  );
  await printerService.printBytes(bytes);
  
  // Option 2: Preview first, then print
  showDialog(
    context: context,
    builder: (_) => ThermalReceiptPreviewScreen(
      data: invoiceData,
      paperWidth: paperSize == PaperSize.mm58 
        ? PaperWidth.mm58 
        : PaperWidth.mm80,
      onPrint: () async {
        final bytes = await ThermalReceiptGenerator.generateThermalReceipt(
          invoiceData,
          paperSize,
        );
        await printerService.printBytes(bytes);
        Navigator.pop(context);
      },
    ),
  );
}
```

---

## Complete Example: Print Invoice

```dart
Future<void> _printInvoice() async {
  try {
    // 1. Get paper size setting
    final printerService = PrinterService();
    final paperSize = printerService.settings.paperSize;
    
    // 2. Calculate totals
    final calculations = _calculateTotals();
    
    // 3. Create invoice data
    final invoiceData = InvoiceDataMapper.fromExistingData(
      services: widget.cart,
      customer: widget.customer,
      orderNumber: _orderNumberController.text,
      cashierName: _cashierNameController.text,
      branchName: _branchNameController.text,
      dateTime: DateTime.now(),
      subtotalBeforeTax: calculations['subtotal']!,
      discountPercentage: calculations['discountPercentage']!,
      discountAmount: calculations['discountAmount']!,
      amountAfterDiscount: calculations['amountAfterDiscount']!,
      taxRate: 15.0,
      taxAmount: calculations['taxAmount']!,
      grandTotal: calculations['finalTotal']!,
      paymentMethod: _paymentMethod,
      paidAmount: _paidAmount,
      businessName: 'صالون الشباب',
      businessAddress: 'الرياض، المملكة العربية السعودية',
      businessPhone: '+966 XX XXX XXXX',
      taxNumber: '1234567890',
      logoPath: 'assets/images/logo.png',
    );
    
    // 4. Route by paper size
    if (paperSize == PaperSize.a4) {
      // A4: Pure PDF
      final pdfBytes = await PdfInvoiceGenerator.generateA4Invoice(invoiceData);
      await Printing.layoutPdf(onLayout: (_) => pdfBytes);
      print('✅ A4 PDF printed successfully');
      
    } else {
      // Thermal: ESC/POS
      final bytes = await ThermalReceiptGenerator.generateThermalReceipt(
        invoiceData,
        paperSize,
      );
      await printerService.printBytes(bytes);
      print('✅ Thermal receipt printed successfully');
    }
    
  } catch (e) {
    print('❌ Print failed: $e');
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('فشل الطباعة: $e'), backgroundColor: Colors.red),
    );
  }
}
```

---

## Benefits of New Architecture

### 1. **Clean Separation**
- A4 and Thermal logic completely separated
- No shared code between PDF and ESC/POS
- Easy to maintain and debug

### 2. **Stateless Generators**
- No service dependencies
- Pure functions (data in, bytes out)
- Easy to test and reuse

### 3. **Preview Support**
- Thermal receipts can be previewed before printing
- Uses Flutter widgets, not bytes
- Works offline without printer

### 4. **Production Ready**
- Proper error handling
- Type-safe data model
- Professional code structure
- Stable and predictable

### 5. **Encoding Done Right**
- A4 PDF: UTF-8 Arabic via font
- Thermal: Windows-1256 encoding
- No confusion, no garbled text

---

## Migration Checklist

- [x] Create InvoiceData model
- [x] Create ThermalReceiptGenerator
- [x] Create PdfInvoiceGenerator
- [x] Create ThermalReceiptPreviewScreen
- [x] Create InvoiceDataMapper helper
- [ ] Update invoice_page.dart to use new routing
- [ ] Update print_dirct.dart to use new generators
- [ ] Test A4 PDF printing
- [ ] Test thermal 80mm printing
- [ ] Test thermal 58mm printing
- [ ] Test preview screen
- [ ] Remove old receipt_generator.dart
- [ ] Update documentation

---

## Testing

### Test A4 PDF
1. Go to Settings → Printer Settings
2. Select "A4" paper size
3. Create invoice and click "Print"
4. **Expected**: PDF dialog opens with professional A4 layout
5. **Verify**: Arabic text renders correctly via Cairo font

### Test Thermal 80mm
1. Go to Settings → Printer Settings
2. Select "80mm Thermal" paper size
3. Ensure printer is connected (192.168.100.128:9100)
4. Create invoice and click "Print"
5. **Expected**: Thermal receipt prints directly
6. **Verify**: Arabic text in Windows-1256 encoding

### Test Thermal 58mm
1. Go to Settings → Printer Settings
2. Select "58mm Thermal" paper size
3. Create invoice and click "Print"
4. **Expected**: Narrower thermal receipt
5. **Verify**: Text fits within 58mm width

### Test Preview
1. Before printing thermal, show preview
2. **Expected**: Flutter widgets render receipt
3. **Verify**: Can see exactly what will print
4. Click "Print" button in preview
5. **Expected**: Actual print matches preview

---

## Troubleshooting

### "amountAfterDiscount is required"
**Fix**: Always pass `amountAfterDiscount` when creating InvoiceData:
```dart
final amountAfterDiscount = subtotalBeforeTax - discountAmount;
```

### "Thermal receipt still uses old code"
**Fix**: Import new generator and use static method:
```dart
import 'package:barber_casher/services/thermal_receipt_generator.dart';

final bytes = await ThermalReceiptGenerator.generateThermalReceipt(
  invoiceData,
  paperSize,
);
```

### "A4 PDF shows ESC/POS bytes"
**Fix**: Use PdfInvoiceGenerator, NOT ThermalReceiptGenerator:
```dart
import 'package:barber_casher/services/pdf_invoice_generator.dart';

final pdfBytes = await PdfInvoiceGenerator.generateA4Invoice(invoiceData);
```

### "Preview doesn't match print"
**Check**:
1. Same InvoiceData used for preview and print
2. Correct PaperWidth (mm58 vs mm80)
3. Preview uses Flutter widgets, print uses ESC/POS (slight differences expected)

---

## Production Deployment

Before deploying to production:

1. ✅ All tests pass (A4, 58mm, 80mm)
2. ✅ Arabic encoding works correctly
3. ✅ Preview matches actual print
4. ✅ No console errors
5. ✅ Business calculations preserved
6. ✅ Error handling tested
7. ✅ Old code removed
8. ✅ Documentation updated

---

## Support

For issues or questions about the new printing architecture:
1. Check this integration guide
2. Review code comments in generator files
3. Test with actual printer hardware
4. Verify InvoiceData has all required fields

Remember: **This is a POS system, stability > hacks**
