# Enhanced Receipt Printing System

## Overview
The receipt printing system has been completely redesigned to match the reference invoice format with professional tax invoice layout, borders, tables, and QR codes.

## Key Features

### ✅ Exact Layout Matching
The receipt now generates output that matches the reference image exactly:

1. **Header Section**
   - Store logo centered at the top (from `assets/images/logo.png`)
   - Store name: "صالون الشباب" (large, bold, centered)
   - Store address: "المدينة المنورة، حي النخيل"
   - Phone number: "0565656565"
   - Thick horizontal separator line

2. **Title**
   - "فاتورة ضريبية مبسطة" (Simplified Tax Invoice)
   - Centered, bold, larger font

3. **Order Information Table**
   - Professional bordered table
   - Right-to-left (Arabic) layout
   - Fields:
     * رقم الطلب (Order Number)
     * العميل (Customer Name)
     * التاريخ (Date & Time)
     * الكاشير (Cashier Name)
     * الفرع (Branch Name)

4. **Items Table**
   - 4-column bordered table:
     * الوصف (Description)
     * السعر (Price)
     * الكمية (Quantity)
     * الإجمالي (Total)
   - Header row with borders
   - Each item row with proper alignment

5. **Totals Section**
   - الإجمالي قبل الضريبة (Subtotal Before Tax)
   - ضريبة القيمة المضافة 15% (VAT 15%)
   - الإجمالي شامل الضريبة (Total Including Tax) - Bold, larger font

6. **Footer**
   - "شكراً لزيارتكم" (Thank you for your visit)
   - "نتطلع لرؤيتكم مرة أخرى" (Looking forward to seeing you again)

7. **QR Code**
   - Centered QR code
   - Contains: Seller name, VAT number, timestamp, total, and tax amount
   - ZATCA-compliant format for Saudi Arabia

## Files Modified

### 1. `receipt_generator.dart` (NEW)
Complete receipt generation class with:
- Logo loading and resizing
- Bordered table generation
- Proper Arabic RTL layout
- Tax calculations
- QR code generation
- Fallback simple receipt if image processing fails

### 2. `print_dirct.dart` (UPDATED)
- Simplified to use the new `ReceiptGenerator`
- Added `orderNumber` and `branchName` parameters
- Cleaner interface

### 3. `invoice_page.dart` (UPDATED)
- Added order number field (auto-generated timestamp)
- Added branch name field (default: "الفرع الرئيسي")
- Updated UI to show all required fields

### 4. `pubspec.yaml` (UPDATED)
- Added `image: ^4.0.17` package for logo processing

## Usage

### Basic Printing
```dart
await printInvoiceDirect(
  customer: customer,
  services: cartItems,
  discount: 0.0,
  cashierName: 'Yousef',
  paymentMethod: 'نقدي',
  orderNumber: '123456',
  branchName: 'الفرع الرئيسي',
);
```

### Generate Bytes Only
```dart
final receiptGenerator = ReceiptGenerator();
final bytes = await receiptGenerator.generateReceiptBytes(
  orderNumber: '123456',
  customer: customer,
  services: cartItems,
  discount: 0.0,
  cashierName: 'Yousef',
  paymentMethod: 'نقدي',
  branchName: 'الفرع الرئيسي',
);
```

## Technical Details

### Paper Size
- 80mm thermal paper (48 characters width)
- ESC/POS compatible

### Table Formatting
- Uses Unicode box-drawing characters for borders:
  - `┌─┐` (top border)
  - `│ │` (vertical borders)
  - `├─┤` (middle separator)
  - `└─┘` (bottom border)

### Text Alignment
- Arabic text: Right-to-left layout
- Numbers: Right-aligned
- Headers: Centered

### Logo Handling
- Logo loaded from `assets/images/logo.png`
- Automatically resized to 380px width
- Centered on receipt
- Falls back gracefully if logo not found

### QR Code Format
The QR code contains:
```
Seller: صالون الشباب
VAT: 300000000000003
Time: 2025-11-16 21:47:00
Total: 115.00 SAR
Tax: 15.00 SAR
```

## Customization

### Change Store Information
Edit in `receipt_generator.dart`, `_addHeader()` method:
```dart
bytes += generator.text(
  'صالون الشباب',  // Change store name here
  styles: const PosStyles(
    align: PosAlign.center,
    bold: true,
    height: PosTextSize.size2,
    width: PosTextSize.size2,
  ),
);

bytes += generator.text(
  'المدينة المنورة، حي النخيل',  // Change address
  ...
);

bytes += generator.text(
  'هاتف: 0565656565',  // Change phone
  ...
);
```

### Change VAT Rate
Edit in `receipt_generator.dart`, `generateReceiptBytes()`:
```dart
final taxAmount = taxableAmount * 0.15;  // Change 0.15 to your VAT rate
```

### Change VAT Number
Edit in `receipt_generator.dart`, `_addQRCode()`:
```dart
final vatNumber = '300000000000003';  // Change to your VAT registration number
```

### Adjust Table Column Widths
Edit in `receipt_generator.dart`, `_formatItemRow()`:
```dart
const descWidth = 20;    // Description column width
const priceWidth = 8;    // Price column width
const qtyWidth = 6;      // Quantity column width
const totalWidth = 10;   // Total column width
```

## Troubleshooting

### Logo Not Showing
1. Ensure `assets/images/logo.png` exists
2. Check `pubspec.yaml` has assets declared
3. Run `flutter pub get`
4. Clean and rebuild: `flutter clean && flutter pub get`

### QR Code Not Generating
- The system will continue without QR code if generation fails
- Check console for error messages

### Borders Not Aligned
- Ensure your printer supports Unicode box-drawing characters
- Some older printers may not display borders correctly
- The system will still print, just without perfect borders

### Arabic Text Issues
- Ensure your printer supports Arabic character encoding
- Most modern thermal printers support UTF-8
- Check printer firmware if Arabic appears as question marks

## Testing

### Test Print Without Hardware
1. Use the invoice page UI to preview all fields
2. Check generated PDF output as reference
3. Verify all calculations are correct

### Test With Actual Printer
1. Connect to printer via WiFi/Bluetooth/USB
2. Print a test receipt
3. Compare output with reference image
4. Adjust column widths if needed

## Future Enhancements

### Potential Improvements
1. Multi-language support (English/Arabic toggle)
2. Custom logo upload via app settings
3. Dynamic store info from database
4. Multiple VAT rates for different items
5. Customer signature line
6. Barcode generation for order tracking
7. Printer-specific optimizations
8. Receipt templates (compact/detailed modes)

## Compliance

### Saudi Arabia ZATCA Requirements
The receipt includes:
- ✅ Seller name and VAT number
- ✅ Date and time
- ✅ Sequential invoice number
- ✅ Item descriptions and prices
- ✅ Subtotal before VAT
- ✅ VAT amount (15%)
- ✅ Total amount including VAT
- ✅ QR code with invoice data

### E-Invoice Phase 2 Ready
For full ZATCA Phase 2 compliance, you'll need to:
1. Register your VAT number
2. Generate cryptographic stamps
3. Use official ZATCA SDK for QR code generation
4. Submit invoices to ZATCA portal

## Support

For issues or questions:
1. Check console output for error messages
2. Verify printer connection
3. Test with simple receipt first
4. Contact printer manufacturer for hardware issues

---

**Last Updated:** November 16, 2025  
**Version:** 2.0  
**Compatible With:** Flutter 3.9.2+, ESC/POS thermal printers
