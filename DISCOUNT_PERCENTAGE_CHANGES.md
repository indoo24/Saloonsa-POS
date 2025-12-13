# Backend Changes Summary - Discount as Percentage

## 🔄 Changes Made

### 1. OrderController.php - store() Method

**Changed**: Discount calculation from fixed amount to percentage

**Before**:
```php
$discount = $request->discount ?? 0;
$taxValue = $request->tax_value ?? 0;
$total = $subtotal - $discount + $taxValue;
```

**After**:
```php
// Discount is treated as percentage (0-100)
$discountPercentage = $request->discount ?? 0;
$discountAmount = $subtotal * ($discountPercentage / 100);
$amountAfterDiscount = $subtotal - $discountAmount;

// Tax is 15% of amount after discount
$tax = $amountAfterDiscount * 0.15;

// Final total
$total = $amountAfterDiscount + $tax;
```

**Order Creation**:
```php
'discount' => $discountPercentage, // Store as percentage
'discount_type' => 1, // 0 = fixed amount, 1 = percentage
'tax' => 15, // 15% tax rate
'tax_value' => $tax,
```

### 2. Validation Rules Updated

**Changed**: Added min/max validation for discount percentage

```php
'discount' => 'nullable|numeric|min:0|max:100', // Percentage (0-100)
```

**Removed**: `tax_value` from request (now calculated automatically)

### 3. OrderController.php - print() Method

**Changed**: Print data now shows discount details

**Added Fields**:
```php
'subtotal' => (float)$subtotal,
'discount_percentage' => $discountPercentage,
'discount_amount' => $discountAmount,
'amount_after_discount' => $amountAfterDiscount,
'tax_rate' => 15,
'tax_amount' => $taxAmount,
```

---

## 📊 Calculation Formula

```
Subtotal = Sum of all items (qty × price)
Discount Amount = Subtotal × (discount / 100)
Amount After Discount = Subtotal - Discount Amount
Tax = Amount After Discount × 0.15 (15%)
Total = Amount After Discount + Tax
```

---

## ✅ Testing Results

### Test Case: 50% Discount

**Input**:
- Item 1: 50 SAR
- Item 2: 75 SAR
- Discount: 50%

**Expected**:
- Subtotal: 125 SAR
- Discount (50%): -62.5 SAR
- Amount After Discount: 62.5 SAR
- Tax (15%): 9.375 SAR
- **Total: 71.88 SAR**

**Actual Result**: ✅ **PASSED**
- Order ID: 68
- Invoice Number: 59
- Total: 71.88 SAR
- Tax Value: 9.38 SAR
- Discount: 50%

---

## 📝 API Request Example

**Before** (Fixed Amount):
```json
{
  "client_id": 1,
  "discount": 10,
  "tax_value": 5,
  "items": [...]
}
```
Result: Total = 125 - 10 + 5 = 120 SAR

**After** (Percentage):
```json
{
  "client_id": 1,
  "discount": 50,
  "items": [...]
}
```
Result: Total = (125 - 62.5) × 1.15 = 71.88 SAR

---

## 🔍 Print Data Response

**New Format**:
```json
{
  "subtotal": 125,
  "discount_percentage": 50,
  "discount_amount": 62.5,
  "amount_after_discount": 62.5,
  "tax_rate": 15,
  "tax_amount": 9.38,
  "total": 71.88,
  "paid": 50,
  "due": 21.88
}
```

---

## 📱 Frontend Updates Required

### 1. Update Request Model
```dart
// discount is now percentage (0-100)
final orderRequest = CreateOrderRequest(
  discount: 50, // 50% not 50 SAR
);
```

### 2. Add Calculation Helper
```dart
double calculateOrderTotal(double subtotal, double discountPercentage) {
  final discountAmount = subtotal * (discountPercentage / 100);
  final amountAfterDiscount = subtotal - discountAmount;
  final tax = amountAfterDiscount * 0.15;
  return amountAfterDiscount + tax;
}
```

### 3. Update UI
```dart
TextFormField(
  decoration: InputDecoration(
    labelText: 'Discount (%)',
    suffixText: '%',
  ),
  validator: (value) {
    final val = double.tryParse(value ?? '0');
    if (val != null && (val < 0 || val > 100)) {
      return 'Must be between 0 and 100';
    }
    return null;
  },
)
```

---

## 🚨 Breaking Changes

1. **Discount field meaning changed**: Now represents percentage instead of fixed amount
2. **tax_value removed from request**: Now calculated automatically at 15%
3. **Print response structure changed**: Added new fields for detailed breakdown

---

## 📄 Documentation Updated

✅ `API_DOCS/ORDERS_INVOICES_API_INTEGRATION.md` - Complete rewrite with:
- Discount calculation section
- Updated examples with 50% discount
- Flutter models with calculation methods
- Updated UI screens
- Best practices for percentage handling

---

## 🎯 Migration Guide

### For Existing Orders
- Old orders with `discount_type = 0` remain as fixed amounts
- New orders with `discount_type = 1` use percentage calculation
- Check `discount_type` field when displaying old orders

### For Frontend Applications
1. Update CreateOrderRequest model
2. Add discount percentage validation (0-100)
3. Update UI to show "%" suffix
4. Add preview calculation before submission
5. Update print/display logic to show discount breakdown

---

## 📊 Comparison Table

| Aspect | Before | After |
|--------|--------|-------|
| Discount Type | Fixed Amount | Percentage (0-100) |
| Tax Input | Manual | Auto-calculated (15%) |
| Validation | Any number | 0-100 only |
| Calculation | Subtotal - Discount + Tax | (Subtotal - Discount%) × 1.15 |
| Print Data | Simple total | Detailed breakdown |
| discount_type | 0 (fixed) | 1 (percentage) |

---

## ✅ Files Modified

1. `app/Http/Controllers/API/OrderController.php`
   - store() method: New calculation logic
   - Validation rules: Updated for percentage
   - print() method: Enhanced response data

2. `API_DOCS/ORDERS_INVOICES_API_INTEGRATION.md`
   - Added discount calculation section
   - Updated all examples
   - Enhanced Flutter models
   - Updated UI screens
   - Added best practices

3. `test_discount_percentage.php` (New)
   - Comprehensive test script
   - Validates calculation
   - Tests print endpoint

---

## 🎉 Benefits

1. **More Intuitive**: Users think in percentages for discounts
2. **Tax Compliance**: Automatic 15% VAT calculation
3. **Transparent**: Print shows full breakdown
4. **Validated**: Cannot enter invalid percentages
5. **Consistent**: Same formula applied everywhere
6. **Flexible**: Supports 0-100% range including "free" (100%)

---

## 📞 Support

If you encounter issues with the new discount system:
1. Check that discount value is between 0-100
2. Verify calculations match the formula
3. Review test_discount_percentage.php output
4. Check discount_type field (should be 1 for new orders)
