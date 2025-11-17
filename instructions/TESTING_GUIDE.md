# Receipt Testing Guide

## Quick Test Steps

### 1. Initial Setup ✅

```bash
# Navigate to project
cd "c:\Users\SOFT LAPTOP\StudioProjects\barber_casher"

# Install dependencies (ALREADY DONE)
flutter pub get

# Verify logo exists
dir assets\images\logo.png
```

### 2. Run the App

```bash
flutter run
```

### 3. Test Receipt Generation

#### A. Navigate to Invoice Page
1. Open the app
2. Log in as cashier
3. Add services to cart:
   - Add "حلاقة" (30 ر.س)
   - Add "صبغة" (50 ر.س)
   - Add "حلاقة لحية" (20 ر.س)
4. Click "إصدار الفاتورة" button

#### B. Verify Invoice Fields
Check that all fields are visible:
- ✅ رقم الطلب (Order Number) - auto-filled with timestamp
- ✅ العميل (Customer) - shows "عميل كاش" or selected customer
- ✅ التاريخ (Date) - shows current date
- ✅ الكاشير (Cashier) - editable, default "Yousef"
- ✅ الفرع (Branch) - editable, default "الفرع الرئيسي"
- ✅ طريقة الدفع (Payment Method) - dropdown with options

#### C. Verify Calculations
- Subtotal: 100.00 ر.س (30 + 50 + 20)
- Tax (15%): 15.00 ر.س
- **Total: 115.00 ر.س**

#### D. Print Test Receipt
1. Click "طباعة الفاتورة" button
2. If printer connected → direct print
3. If printer not connected → PDF preview

### 4. Visual Verification Checklist

Compare your printed receipt with reference image:

#### Header Section
- [ ] Logo appears centered at top
- [ ] Store name "صالون الشباب" is large and bold
- [ ] Address "المدينة المنورة، حي النخيل" is visible
- [ ] Phone "0565656565" is visible
- [ ] Thick separator line below header

#### Title Section
- [ ] "فاتورة ضريبية مبسطة" is centered and bold
- [ ] Title is larger than normal text
- [ ] Separator line below title

#### Order Info Table
- [ ] Table has borders (┌─┐│└┘ characters)
- [ ] 5 rows visible:
  - [ ] رقم الطلب with order number
  - [ ] العميل with customer name
  - [ ] التاريخ with date/time
  - [ ] الكاشير with cashier name
  - [ ] الفرع with branch name
- [ ] Text aligned properly (RTL for Arabic)

#### Items Table
- [ ] Table has borders
- [ ] 4 columns: الوصف | السعر | الكمية | الإجمالي
- [ ] Header row is bold
- [ ] Each service appears in its own row
- [ ] Prices are right-aligned
- [ ] Quantities are centered
- [ ] Totals are right-aligned

#### Totals Section
- [ ] "الإجمالي قبل الضريبة" with subtotal
- [ ] "ضريبة القيمة المضافة (15%)" with tax amount
- [ ] "الإجمالي شامل الضريبة" is bold and larger
- [ ] All amounts right-aligned with ر.س suffix

#### Footer Section
- [ ] "شكراً لزيارتكم" message
- [ ] "نتطلع لرؤيتكم مرة أخرى" message
- [ ] Both centered

#### QR Code
- [ ] QR code appears
- [ ] QR code is centered
- [ ] QR code is scannable
- [ ] Proper spacing before/after

### 5. Test Different Scenarios

#### Test 1: Single Item
```
Cart: [حلاقة - 30 ر.س]
Expected Total: 34.50 ر.س (30 + 15% tax)
```

#### Test 2: Multiple Items
```
Cart: [حلاقة - 30 ر.س, صبغة - 50 ر.س]
Expected Total: 92.00 ر.س (80 + 15% tax)
```

#### Test 3: With Discount
```
Cart: [حلاقة - 30 ر.س, صبغة - 50 ر.س]
Discount: 10%
Expected Total: 82.80 ر.س (92 - 10%)
```

#### Test 4: Long Service Names
```
Cart: [خدمة طويلة جداً مع اسم كبير - 100 ر.س]
Expected: Name truncated to fit column width
```

#### Test 5: Many Items (>10)
```
Cart: 15 different services
Expected: All items printed, table continues seamlessly
```

### 6. Edge Case Testing

#### Test Long Customer Name
```
Customer: "محمد بن عبدالله بن عبدالعزيز آل سعود"
Expected: Name fits in table cell (may truncate if too long)
```

#### Test Special Characters
```
Customer: "أحمد O'Brien"
Expected: Both Arabic and English characters print correctly
```

#### Test Zero Discount
```
Discount: 0%
Expected: No discount line shown (or shows 0.00)
```

#### Test High Discount
```
Discount: 99%
Expected: Correct calculation, final total very small
```

### 7. Printer-Specific Tests

#### WiFi Printer Test
```
1. Connect to WiFi printer IP
2. Print receipt
3. Verify formatting
4. Check borders alignment
```

#### Bluetooth Printer Test
```
1. Pair with Bluetooth printer
2. Connect in app
3. Print receipt
4. Verify Arabic text
```

#### USB Printer Test
```
1. Connect USB printer
2. Grant USB permissions
3. Print receipt
4. Check paper feed
```

### 8. Performance Tests

#### Time to Generate
```
Expected: < 1 second to generate receipt bytes
Method: Print timestamp before/after generation
```

#### Time to Print
```
Expected: < 5 seconds to print complete receipt
Method: Print timestamp before/after printing
```

#### Memory Usage
```
Expected: < 10MB additional memory for receipt
Method: Monitor app memory before/after
```

### 9. Error Handling Tests

#### Test: Logo Missing
```
Action: Remove/rename logo.png file
Expected: Receipt prints without logo, no crash
Result: ___________
```

#### Test: Printer Disconnected
```
Action: Disconnect printer mid-print
Expected: Error message, fallback to PDF
Result: ___________
```

#### Test: Invalid Data
```
Action: Empty cart, print receipt
Expected: Graceful error message
Result: ___________
```

#### Test: Unsupported Characters
```
Action: Use emoji in customer name 😊
Expected: Emoji replaced or removed
Result: ___________
```

### 10. Cross-Platform Tests

#### Android Device
```
- [ ] Receipt generates correctly
- [ ] Logo loads properly
- [ ] Borders display correctly
- [ ] QR code scans successfully
- [ ] Arabic text is RTL
```

#### iOS Device (if applicable)
```
- [ ] Receipt generates correctly
- [ ] Logo loads properly
- [ ] Borders display correctly
- [ ] QR code scans successfully
- [ ] Arabic text is RTL
```

#### Windows Desktop
```
- [ ] Receipt generates correctly
- [ ] Logo loads properly
- [ ] PDF preview works
```

## Common Issues & Solutions

### Issue: Logo doesn't appear
**Solution:**
```bash
# Verify file exists
dir assets\images\logo.png

# If missing, add logo file
# Then run:
flutter clean
flutter pub get
flutter run
```

### Issue: Borders look misaligned
**Solution:**
Edit `receipt_generator.dart`:
```dart
// Adjust column widths in _formatItemRow()
const descWidth = 18;  // Try different values
const priceWidth = 9;
const qtyWidth = 5;
const totalWidth = 10;
```

### Issue: Arabic text appears as ???
**Solution:**
1. Check printer supports UTF-8 encoding
2. Update printer firmware
3. Test with different printer

### Issue: QR code not scanning
**Solution:**
1. Increase QR code size
2. Ensure printer quality is good
3. Clean printer head
4. Try different QR reader app

### Issue: Receipt too long
**Solution:**
```dart
// Reduce spacing in receipt_generator.dart
bytes += generator.feed(0);  // Instead of feed(1)
```

### Issue: Print job fails
**Solution:**
1. Check printer connection
2. Verify printer has paper
3. Restart printer
4. Reconnect in app

## Regression Testing Checklist

After any code changes, verify:

- [ ] Receipt still generates without errors
- [ ] All fields still appear correctly
- [ ] Calculations still accurate
- [ ] Layout still matches reference
- [ ] Printer connectivity still works
- [ ] PDF fallback still works
- [ ] No new crashes or exceptions

## Test Results Template

```
Date: __________
Tester: __________
Device: __________
Printer Model: __________

Test Case 1: Basic Print
[ ] PASS  [ ] FAIL
Notes: _______________________________

Test Case 2: With Discount
[ ] PASS  [ ] FAIL
Notes: _______________________________

Test Case 3: Multiple Items
[ ] PASS  [ ] FAIL
Notes: _______________________________

Test Case 4: Long Names
[ ] PASS  [ ] FAIL
Notes: _______________________________

Overall Status: [ ] PASS  [ ] FAIL
```

## Automated Testing (Future)

### Unit Tests
```dart
test('Receipt generates correct totals', () {
  final generator = ReceiptGenerator();
  // Test calculations
});

test('Receipt includes all required fields', () {
  final bytes = await generator.generateReceiptBytes(...);
  // Verify bytes contain expected data
});
```

### Integration Tests
```dart
testWidgets('Invoice page displays correctly', (tester) async {
  // Test UI elements
});

testWidgets('Print button triggers receipt generation', (tester) async {
  // Test print flow
});
```

---

## Summary

✅ **Modified Files:** 3 core files + 1 dependency  
✅ **New Files:** 1 receipt generator + 4 documentation files  
✅ **Ready to Test:** Yes  
✅ **Expected Result:** Receipt matching reference image exactly  

**Next Action:** Run app and test print! 🖨️

---

**Last Updated:** November 16, 2025  
**Test Version:** 2.0
