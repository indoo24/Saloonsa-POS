# Receipt Layout Structure

```
╔═══════════════════════════════════════════════════╗
║                                                   ║
║                    [LOGO IMAGE]                   ║
║              (assets/images/logo.png)             ║
║                                                   ║
╠═══════════════════════════════════════════════════╣
║                                                   ║
║              صالون الشباب                         ║
║           (Store Name - Bold, Large)              ║
║                                                   ║
║         المدينة المنورة، حي النخيل                ║
║              (Address - Normal)                   ║
║                                                   ║
║              هاتف: 0565656565                     ║
║              (Phone - Normal)                     ║
║                                                   ║
╠═══════════════════════════════════════════════════╣
║                                                   ║
║          فاتورة ضريبية مبسطة                      ║
║      (Simplified Tax Invoice - Bold, Large)       ║
║                                                   ║
╠═══════════════════════════════════════════════════╣
║  ┌─────────────────────────────────────────────┐ ║
║  │ رقم الطلب: 1731779266000                    │ ║
║  │ (Order Number)                              │ ║
║  ├─────────────────────────────────────────────┤ ║
║  │ العميل: عميل كاش                            │ ║
║  │ (Customer Name)                             │ ║
║  ├─────────────────────────────────────────────┤ ║
║  │ التاريخ: 2025-11-16 21:47                   │ ║
║  │ (Date & Time)                               │ ║
║  ├─────────────────────────────────────────────┤ ║
║  │ الكاشير: Yousef                             │ ║
║  │ (Cashier Name)                              │ ║
║  ├─────────────────────────────────────────────┤ ║
║  │ الفرع: الفرع الرئيسي                         │ ║
║  │ (Branch Name)                               │ ║
║  └─────────────────────────────────────────────┘ ║
╠═══════════════════════════════════════════════════╣
║  ┌───────────────────────────────────────────┐   ║
║  │ الوصف    │ السعر  │ الكمية │ الإجمالي    │   ║
║  │ (Desc)   │ (Price)│ (Qty) │ (Total)     │   ║
║  ├───────────────────────────────────────────┤   ║
║  │ حلاقة    │  30.00 │   1   │   30.00     │   ║
║  │ (Haircut)                                 │   ║
║  ├───────────────────────────────────────────┤   ║
║  │ صبغة     │  50.00 │   1   │   50.00     │   ║
║  │ (Coloring)                                │   ║
║  ├───────────────────────────────────────────┤   ║
║  │ حلاقة لحية│ 20.00 │   1   │   20.00     │   ║
║  │ (Beard Trim)                              │   ║
║  └───────────────────────────────────────────┘   ║
╠═══════════════════════════════════════════════════╣
║                                                   ║
║  الإجمالي قبل الضريبة:         100.00 ر.س        ║
║  (Subtotal Before Tax)                            ║
║                                                   ║
║  ضريبة القيمة المضافة (15%):    15.00 ر.س        ║
║  (VAT 15%)                                        ║
║                                                   ║
║  الإجمالي شامل الضريبة:        115.00 ر.س        ║
║  (Total Including Tax - Bold, Large)              ║
║                                                   ║
╠═══════════════════════════════════════════════════╣
║                                                   ║
║              شكراً لزيارتكم                       ║
║           (Thank you for visiting)                ║
║                                                   ║
║          نتطلع لرؤيتكم مرة أخرى                  ║
║        (Looking forward to seeing you again)      ║
║                                                   ║
╠═══════════════════════════════════════════════════╣
║                                                   ║
║                 ▄▄▄▄▄▄▄▄▄▄▄▄▄                     ║
║                 █ ▄▄▄▄▄ █▄ ▄█                     ║
║                 █ █   █ █▀█ █                     ║
║                 █ █▄▄▄█ █  ██                     ║
║                 █▄▄▄▄▄▄▄█▄ ▄█                     ║
║                 █  █ ▀▄ ▀ ▀██                     ║
║                 ▀▀▀▀▀▀▀▀▀▀▀▀▀                     ║
║               (QR Code - Centered)                ║
║                                                   ║
║            Contains: Seller, VAT#,                ║
║          Timestamp, Total, Tax Amount             ║
║                                                   ║
╚═══════════════════════════════════════════════════╝
```

## Layout Specifications

### Paper Width
- **80mm thermal paper**
- **48 characters per line** (standard density)
- **576 dots horizontal** (8 dots/mm)

### Section Breakdown

#### 1. HEADER (Lines 1-10)
```
Height: ~40mm
Content: Logo + Store Info
Alignment: Center
Font Sizes: 
  - Logo: 380px width (auto height)
  - Store Name: 2x height, 2x width
  - Address/Phone: Normal size
```

#### 2. TITLE (Lines 11-12)
```
Height: ~10mm
Content: "فاتورة ضريبية مبسطة"
Alignment: Center
Font Size: 2x height, 1x width
Style: Bold
```

#### 3. ORDER INFO TABLE (Lines 13-23)
```
Height: ~25mm
Rows: 5
Border Style: Unicode box-drawing (┌─┐│├┤└┘)
Content:
  - Order Number (auto-generated)
  - Customer Name
  - Date & Time (yyyy-MM-dd HH:mm)
  - Cashier Name
  - Branch Name
```

#### 4. ITEMS TABLE (Lines 24-35)
```
Height: Variable (depends on items)
Columns: 4
  - Description: 20 chars
  - Price: 8 chars (right-aligned)
  - Quantity: 6 chars (center-aligned)
  - Total: 10 chars (right-aligned)
Border Style: Unicode box-drawing
Header Row: Bold
```

#### 5. TOTALS SECTION (Lines 36-42)
```
Height: ~15mm
Content:
  - Subtotal before tax (normal)
  - VAT 15% (normal)
  - Total including tax (bold, 1.5x size)
Alignment: Two-column (label left, amount right)
```

#### 6. FOOTER MESSAGE (Lines 43-46)
```
Height: ~10mm
Content: Thank you messages
Alignment: Center
Style: Normal
```

#### 7. QR CODE (Lines 47-52)
```
Height: ~30mm
Size: Medium (QR version depends on data length)
Error Correction: High (H level)
Alignment: Center
Content Format:
  Seller: صالون الشباب
  VAT: 300000000000003
  Time: 2025-11-16 21:47:00
  Total: 115.00 SAR
  Tax: 15.00 SAR
```

### Total Receipt Length
- **Minimum**: ~140mm (with 1 item)
- **Average**: ~170mm (with 3-5 items)
- **Maximum**: Variable (depends on item count)

## Character Encoding

### Arabic Text
- **Encoding**: UTF-8
- **Direction**: Right-to-Left (RTL)
- **Font**: Arabic-compatible thermal printer font

### Numbers
- **Format**: Western Arabic numerals (0-9)
- **Decimal**: 2 decimal places for currency
- **Alignment**: Right-aligned for amounts

### Special Characters
```
┌ U+250C  Box Drawing Light Down and Right
─ U+2500  Box Drawing Light Horizontal
┐ U+2510  Box Drawing Light Down and Left
│ U+2502  Box Drawing Light Vertical
├ U+251C  Box Drawing Light Vertical and Right
┤ U+2524  Box Drawing Light Vertical and Left
└ U+2514  Box Drawing Light Up and Right
┘ U+2518  Box Drawing Light Up and Left
═ U+2550  Box Drawing Double Horizontal
```

## Printer Commands (ESC/POS)

### Text Styles
```
Normal:  No special formatting
Bold:    ESC E 1 (or PosStyles(bold: true))
Large:   ESC ! 0x30 (or PosTextSize.size2)
Center:  ESC a 1 (or PosAlign.center)
Right:   ESC a 2 (or PosAlign.right)
```

### Image Printing
```
Command: GS v 0 (or generator.imageRaster())
Mode: Raster bit image
Density: Normal (203 DPI for 80mm paper)
```

### QR Code
```
Command: Uses ESC/POS QR code command
Size: Module size 3-6
Error Correction: L (7%), M (15%), Q (25%), H (30%)
```

## Spacing Guidelines

### Vertical Spacing
```
After Logo:         1 line feed
After Store Info:   1 line feed
After Title:        0 line feeds (separator line)
After Order Table:  1 line feed
After Items Table:  1 line feed
After Totals:       0 line feeds (separator line)
After Footer:       1 line feed
After QR Code:      2 line feeds (before cut)
```

### Horizontal Spacing
```
Table Cell Padding: 1 space on each side
Column Separators:  │ character
Label-Value Gap:    : character + 1 space
```

## Responsive Design

### If Paper Width < 48 chars
1. Reduce column widths proportionally
2. Truncate long text with "..."
3. Maintain essential information

### If Item Count > 10
1. Continue table seamlessly
2. Add page breaks if printer supports
3. Summarize on second page if needed

## Color & Style

### Text Colors
- All text: Black (thermal printing)

### Font Weights
- Headers: Bold
- Totals: Bold
- Regular text: Normal

### Font Sizes
- Logo: Max 380px width
- Title: 2x height
- Subtotals: Normal
- Final Total: 1.5x size

## Accessibility

### Readability
- Clear section separation
- Consistent alignment
- Adequate white space
- High contrast (black on white)

### Arabic Support
- Proper RTL text flow
- Correct character joining
- Diacritic marks support

---

**Last Updated:** November 16, 2025  
**Format Version:** 2.0  
**Printer Compatibility:** ESC/POS Standard
