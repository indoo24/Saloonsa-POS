# Code Flow Diagram

## Receipt Generation Flow

```
┌─────────────────────────────────────────────────────────────────┐
│                         USER INTERACTION                         │
│                                                                  │
│  1. User adds services to cart                                  │
│  2. User clicks "إصدار الفاتورة"                                │
│  3. User reviews invoice details                                │
│  4. User clicks "طباعة الفاتورة"                                │
└──────────────────────────┬──────────────────────────────────────┘
                           │
                           ▼
┌─────────────────────────────────────────────────────────────────┐
│                      INVOICE_PAGE.DART                           │
│                    _handlePrint() method                         │
│                                                                  │
│  • Checks printer connection                                    │
│  • Gathers invoice data:                                        │
│    - Order number (from controller)                             │
│    - Customer info (from widget)                                │
│    - Services (from cart)                                       │
│    - Discount (from controller)                                 │
│    - Cashier name (from controller)                             │
│    - Branch name (from controller)                              │
│    - Payment method (from dropdown)                             │
│                                                                  │
│  • Calls printInvoiceDirect()                                   │
└──────────────────────────┬──────────────────────────────────────┘
                           │
                           ▼
┌─────────────────────────────────────────────────────────────────┐
│                       PRINT_DIRCT.DART                           │
│                  printInvoiceDirect() function                   │
│                                                                  │
│  • Calls generateInvoiceBytes()                                 │
│  • Sends bytes to PrinterService                                │
│  • Returns success/failure                                      │
└──────────────────────────┬──────────────────────────────────────┘
                           │
                           ▼
┌─────────────────────────────────────────────────────────────────┐
│                       PRINT_DIRCT.DART                           │
│                  generateInvoiceBytes() function                 │
│                                                                  │
│  • Creates ReceiptGenerator instance                            │
│  • Calls generateReceiptBytes()                                 │
│  • Returns List<int> (ESC/POS bytes)                            │
└──────────────────────────┬──────────────────────────────────────┘
                           │
                           ▼
┌─────────────────────────────────────────────────────────────────┐
│                    RECEIPT_GENERATOR.DART                        │
│               generateReceiptBytes() main method                 │
│                                                                  │
│  ┌────────────────────────────────────────────────────────────┐│
│  │ STEP 1: Calculate Totals                                   ││
│  │  • Subtotal = sum of all service prices                    ││
│  │  • Tax = subtotal × 0.15                                   ││
│  │  • Total = subtotal + tax - discount                       ││
│  └────────────────────────────────────────────────────────────┘│
│                           │                                      │
│  ┌────────────────────────┴────────────────────────────────────┐│
│  │ STEP 2: Initialize Generator                               ││
│  │  • Load capability profile                                 ││
│  │  • Create Generator for 80mm paper                         ││
│  │  • Initialize bytes list                                   ││
│  └────────────────────────┬────────────────────────────────────┘│
│                           │                                      │
│  ┌────────────────────────┴────────────────────────────────────┐│
│  │ STEP 3: Add Header (_addHeader)                            ││
│  │  ┌──────────────────────────────────────────────────────┐ ││
│  │  │ • Load logo from assets/images/logo.png              │ ││
│  │  │ • Resize logo to 380px width                         │ ││
│  │  │ • Add as raster image (centered)                     │ ││
│  │  │ • Add store name (large, bold, centered)             │ ││
│  │  │ • Add address (normal, centered)                     │ ││
│  │  │ • Add phone (normal, centered)                       │ ││
│  │  │ • Add thick separator line (═)                       │ ││
│  │  └──────────────────────────────────────────────────────┘ ││
│  └────────────────────────┬────────────────────────────────────┘│
│                           │                                      │
│  ┌────────────────────────┴────────────────────────────────────┐│
│  │ STEP 4: Add Title (_addTitle)                              ││
│  │  ┌──────────────────────────────────────────────────────┐ ││
│  │  │ • "فاتورة ضريبية مبسطة"                             │ ││
│  │  │ • Centered, bold, 2x height                          │ ││
│  │  │ • Add separator line (═)                             │ ││
│  │  └──────────────────────────────────────────────────────┘ ││
│  └────────────────────────┬────────────────────────────────────┘│
│                           │                                      │
│  ┌────────────────────────┴────────────────────────────────────┐│
│  │ STEP 5: Add Order Info Table (_addOrderInfoTable)          ││
│  │  ┌──────────────────────────────────────────────────────┐ ││
│  │  │ • Draw top border (┌─┐)                              │ ││
│  │  │ • Add row: رقم الطلب + order number                 │ ││
│  │  │ • Add row: العميل + customer name                   │ ││
│  │  │ • Add row: التاريخ + date & time                    │ ││
│  │  │ • Add row: الكاشير + cashier name                   │ ││
│  │  │ • Add row: الفرع + branch name                      │ ││
│  │  │ • Draw bottom border (└─┘)                           │ ││
│  │  │ • Each row: │ label: value + padding │              │ ││
│  │  └──────────────────────────────────────────────────────┘ ││
│  └────────────────────────┬────────────────────────────────────┘│
│                           │                                      │
│  ┌────────────────────────┴────────────────────────────────────┐│
│  │ STEP 6: Add Items Table (_addItemsTable)                   ││
│  │  ┌──────────────────────────────────────────────────────┐ ││
│  │  │ • Draw top border (┌─┐)                              │ ││
│  │  │ • Add header: الوصف│السعر│الكمية│الإجمالي          │ ││
│  │  │ • Draw middle separator (├─┤)                        │ ││
│  │  │ • For each service:                                  │ ││
│  │  │   - Format row with 4 columns                        │ ││
│  │  │   - Description (20 chars, left)                     │ ││
│  │  │   - Price (8 chars, right)                           │ ││
│  │  │   - Quantity (6 chars, center)                       │ ││
│  │  │   - Total (10 chars, right)                          │ ││
│  │  │   - Add vertical separators (│)                      │ ││
│  │  │ • Draw bottom border (└─┘)                           │ ││
│  │  └──────────────────────────────────────────────────────┘ ││
│  └────────────────────────┬────────────────────────────────────┘│
│                           │                                      │
│  ┌────────────────────────┴────────────────────────────────────┐│
│  │ STEP 7: Add Totals Section (_addTotalsSection)             ││
│  │  ┌──────────────────────────────────────────────────────┐ ││
│  │  │ • Draw separator line (─)                            │ ││
│  │  │ • Add row: "الإجمالي قبل الضريبة" + subtotal        │ ││
│  │  │ • Add row: "ضريبة القيمة المضافة 15%" + tax         │ ││
│  │  │ • Add row: "الإجمالي شامل الضريبة" + total (BOLD)   │ ││
│  │  │ • Each row: label (left) | amount (right)            │ ││
│  │  │ • Draw thick separator (═)                           │ ││
│  │  └──────────────────────────────────────────────────────┘ ││
│  └────────────────────────┬────────────────────────────────────┘│
│                           │                                      │
│  ┌────────────────────────┴────────────────────────────────────┐│
│  │ STEP 8: Add Footer (_addFooter)                            ││
│  │  ┌──────────────────────────────────────────────────────┐ ││
│  │  │ • "شكراً لزيارتكم" (centered, bold)                 │ ││
│  │  │ • "نتطلع لرؤيتكم مرة أخرى" (centered)               │ ││
│  │  └──────────────────────────────────────────────────────┘ ││
│  └────────────────────────┬────────────────────────────────────┘│
│                           │                                      │
│  ┌────────────────────────┴────────────────────────────────────┐│
│  │ STEP 9: Add QR Code (_addQRCode)                           ││
│  │  ┌──────────────────────────────────────────────────────┐ ││
│  │  │ • Build QR data:                                     │ ││
│  │  │   - Seller name                                      │ ││
│  │  │   - VAT number                                       │ ││
│  │  │   - Timestamp                                        │ ││
│  │  │   - Total amount                                     │ ││
│  │  │   - Tax amount                                       │ ││
│  │  │ • Generate QR code (centered)                        │ ││
│  │  └──────────────────────────────────────────────────────┘ ││
│  └────────────────────────┬────────────────────────────────────┘│
│                           │                                      │
│  ┌────────────────────────┴────────────────────────────────────┐│
│  │ STEP 10: Finalize                                           ││
│  │  • Add 2 line feeds                                         ││
│  │  • Add cut command                                          ││
│  │  • Return bytes list                                        ││
│  └─────────────────────────────────────────────────────────────┘│
│                                                                  │
└──────────────────────────┬──────────────────────────────────────┘
                           │
                           ▼
┌─────────────────────────────────────────────────────────────────┐
│                      PRINTER_SERVICE.DART                        │
│                    printBytes() method                           │
│                                                                  │
│  • Sends bytes to connected printer                             │
│  • Handles WiFi/Bluetooth/USB communication                     │
│  • Returns success/failure                                      │
└──────────────────────────┬──────────────────────────────────────┘
                           │
                           ▼
┌─────────────────────────────────────────────────────────────────┐
│                      PHYSICAL PRINTER                            │
│                                                                  │
│  • Receives ESC/POS commands                                    │
│  • Prints receipt on thermal paper                              │
│  • Cuts paper                                                   │
└─────────────────────────────────────────────────────────────────┘
```

## Helper Method Details

### _addTableRow (Order Info Table)
```
Input: label, value
Process:
  1. Calculate content length
  2. Calculate padding needed
  3. Build row string: │ label: value + padding │
  4. Ensure exact width (48 chars)
  5. Add to bytes
```

### _formatItemRow (Items Table)
```
Input: description, price, quantity, total
Process:
  1. Truncate/pad description to 20 chars
  2. Right-align price in 8 chars
  3. Center-align quantity in 6 chars
  4. Right-align total in 10 chars
  5. Join with vertical separators │
  6. Return formatted row string
```

### _padOrTruncate (Text Formatting)
```
Input: text, width, alignment
Process:
  If text.length > width:
    Return text.substring(0, width)
  Else:
    Calculate padding
    Apply alignment (left/right/center)
    Return padded text
```

## Data Flow

```
User Input
    ↓
Invoice Page State
    ↓
Print Function
    ↓
Receipt Generator
    ↓
ESC/POS Bytes
    ↓
Printer Service
    ↓
Physical Printer
    ↓
Printed Receipt
```

## Error Handling Flow

```
┌─────────────────────┐
│ Generate Receipt    │
└──────────┬──────────┘
           │
           ▼
    ┌──────────────┐
    │ Load Logo    │
    └──────┬───────┘
           │
           ├─── Success ──→ Continue
           │
           └─── Fail ───→ Log error, continue without logo
                           │
                           ▼
                    ┌──────────────┐
                    │ Build Tables │
                    └──────┬───────┘
                           │
                           ├─── Success ──→ Continue
                           │
                           └─── Fail ───→ Use fallback simple receipt
                                           │
                                           ▼
                                    ┌──────────────┐
                                    │ Generate QR  │
                                    └──────┬───────┘
                                           │
                                           ├─── Success ──→ Include QR
                                           │
                                           └─── Fail ───→ Log error, skip QR
                                                           │
                                                           ▼
                                                    ┌──────────────┐
                                                    │ Return Bytes │
                                                    └──────────────┘
```

## Class Relationships

```
┌─────────────────────┐
│  InvoicePage        │
│  (StatefulWidget)   │
└──────────┬──────────┘
           │ uses
           ▼
┌─────────────────────┐
│  printInvoiceDirect │
│  (Function)         │
└──────────┬──────────┘
           │ uses
           ▼
┌─────────────────────┐
│ generateInvoice-    │
│ Bytes (Function)    │
└──────────┬──────────┘
           │ uses
           ▼
┌─────────────────────┐
│  ReceiptGenerator   │
│  (Class)            │
└──────────┬──────────┘
           │ uses
           ▼
┌─────────────────────┐
│  Generator          │
│  (esc_pos_utils)    │
└──────────┬──────────┘
           │ produces
           ▼
┌─────────────────────┐
│  List<int>          │
│  (ESC/POS bytes)    │
└─────────────────────┘
```

## Dependencies

```
receipt_generator.dart
    ├── dart:typed_data
    ├── package:flutter/services.dart (rootBundle)
    ├── package:image/image.dart (img.*)
    ├── package:esc_pos_utils_plus (Generator, PosStyles, etc.)
    ├── package:intl/intl.dart (DateFormat)
    ├── models/customer.dart
    └── models/service-model.dart

print_dirct.dart
    ├── models/customer.dart
    ├── models/service-model.dart
    ├── services/printer_service.dart
    └── receipt_generator.dart

invoice_page.dart
    ├── dart:io
    ├── package:flutter/material.dart
    ├── package:google_fonts/google_fonts.dart
    ├── package:intl/intl.dart
    ├── package:printing/printing.dart
    ├── print_dirct.dart
    ├── pdf_invoice.dart
    ├── models/customer.dart
    └── models/service-model.dart
```

---

**This diagram shows the complete flow from user interaction to printed receipt.**
