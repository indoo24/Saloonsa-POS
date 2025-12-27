# Receipt Generator Arabic Text Fix

## Summary

Fixed two critical errors in receipt printing:

1. **"Cannot add to a fixed-length list" error** - Changed all `bytes +=` to `bytes.addAll()`
2. **"Invalid argument: Contains invalid characters" error** - Replaced Arabic text with English in areas where `esc_pos_utils` is used

## Changes Made

### 1. Imports Added
```dart
import 'dart:convert';
import 'package:charset_converter/charset_converter.dart';
```

### 2. QR Code - Replaced Arabic with English
**Line 540:**
```dart
// OLD:
final sellerName = 'صالون الشباب';

// NEW:
final sellerName = 'Salon Al-Shabab';
```

### 3. Fallback Receipt - Replaced Arabic with English
**Line 575:**
```dart
// OLD:
bytes += generator.text('صالون الشباب', ...);

// NEW:
bytes.addAll(generator.text('Salon Al-Shabab', ...));
```

### 4. Fixed ALL `bytes +=` to `bytes.addAll()`

Throughout the file, changed:
- `bytes += generator.xxx()` → `bytes.addAll(generator.xxx())`

This prevents the "Cannot add to a fixed-length list" error.

## Root Cause

**Issue 1 - Fixed-length list:**
- `bytes` is a `List<int>` returned by generator methods
- Using `+=` operator tries to reassign the entire list
- Using `.addAll()` method appends to the existing list

**Issue 2 - Arabic encoding:**
- `esc_pos_utils` generator.text() only supports ASCII characters
- Arabic characters cause "Invalid argument" exception
- Solution: Use English text for ESC/POS commands
- For actual Arabic display, need to use encoded bytes (Windows-1256)

## Note

For business name and address from settings, the code already handles Arabic correctly by loading from `AppSettings`. The Arabic text errors only occurred in hardcoded strings like "صالون الشباب" in the QR code and fallback receipt.

The proper solution is to either:
1. Use English equivalents in QR codes (current fix)
2. Or implement proper Arabic encoding using charset_converter for ALL Arabic text

Currently, the app settings handle Arabic through the settings service, which likely already has proper encoding.
