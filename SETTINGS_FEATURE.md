# Settings Feature Implementation

## Overview

A new **Settings** feature has been added to the POS/Salon app, allowing configuration of business information, invoice settings, and tax settings.

## What Was Added

### 1. New Files Created

#### Models
- `lib/models/app_settings.dart` - Settings data model with JSON serialization

#### Services
- `lib/services/settings_service.dart` - Handles persistence using SharedPreferences

#### Cubits (State Management)
- `lib/cubits/settings/settings_state.dart` - Settings state definitions
- `lib/cubits/settings/settings_cubit.dart` - Settings business logic

#### Screens
- `lib/screens/settings/settings_screen.dart` - Main settings UI

### 2. Modified Files

#### `lib/main.dart`
- Added `SettingsCubit` to app-level BlocProviders
- Settings automatically load on app startup

#### `lib/screens/casher/casher_screen.dart`
- Added Settings button (⚙️) to AppBar
- Changed Printer Settings icon to printer (🖨️)

#### `lib/screens/casher/receipt_generator.dart`
- Integrated settings into receipt generation
- Business name, address, phone, and tax number now come from settings
- Tax calculation uses configurable tax rate from settings
- Invoice notes appear in receipt footer

## Settings Fields

### 🏷 Business Information
- **Business Name** - Appears on receipts
- **Address** - Multi-line address on receipts
- **Phone Number** - Contact number on receipts
- **Tax Number** - Optional tax/VAT registration number

### 🧾 Invoice / Receipt Settings
- **Invoice Notes** - Multi-line text that appears at the bottom of printed receipts

### 💰 Tax Settings
- **Tax Value (%)** - Tax percentage (e.g., 15 for 15%)
- **Prices Include Tax** - Toggle to indicate if displayed prices include tax
  - Currently for future use in calculations
  - Does not affect existing invoice logic

## How to Use

### Access Settings
1. Open the app and login
2. Click the **Settings** button (⚙️) in the top AppBar
3. Fill in your business information
4. Configure invoice notes and tax settings
5. Click **Save Settings**

### Access Printing Settings
- From the Settings screen, tap "إعدادات الطباعة" card
- OR directly from the main screen's printer icon (🖨️)

### Settings Persistence
- All settings are saved locally using SharedPreferences
- Settings persist across app restarts
- Default values are used if no settings are saved

## Integration Points

### Receipt Generation
When generating receipts, the system:
1. Loads saved settings
2. Uses business info for header
3. Calculates tax using configured percentage
4. Adds invoice notes to footer
5. Falls back to defaults if settings not available

### Default Values
If no settings are configured, the system uses these defaults:
- Business Name: "صالون الشباب"
- Address: "المدينة المنورة، حي النخيل"
- Phone: "0565656565"
- Tax Rate: 15%
- Invoice Notes: "شكراً لزيارتكم"
- Prices Include Tax: No

## Architecture

### State Management
- Uses **Cubit** pattern (existing app architecture)
- Consistent with `CashierCubit`, `AuthCubit`, `PrinterCubit`

### Data Storage
- Uses **SharedPreferences** (existing app storage)
- JSON serialization for complex data
- No database migration needed

### Navigation
- Standard navigation to Settings screen
- Reuses existing Printer Settings screen
- No breaking changes to existing navigation

## What Was NOT Changed

✅ **No refactoring of existing code**
✅ **Invoice calculation logic unchanged** (only tax rate is configurable)
✅ **Printing logic unchanged** (reuses existing printer service)
✅ **Authentication unchanged**
✅ **Cashier/Cart logic unchanged**

## Testing Checklist

- [ ] Open Settings screen
- [ ] Fill in all fields and save
- [ ] Restart app and verify settings persisted
- [ ] Create an invoice and verify:
  - [ ] Business name appears on receipt
  - [ ] Address appears on receipt
  - [ ] Phone number appears on receipt
  - [ ] Tax number appears (if set)
  - [ ] Invoice notes appear at bottom
  - [ ] Tax calculation uses configured rate
- [ ] Navigate to Printing Settings from Settings screen
- [ ] Change tax rate and verify calculations update
- [ ] Test with empty/default settings

## Future Enhancements

Potential improvements for later:
1. Use "Prices Include Tax" toggle for price display logic
2. Add logo upload/configuration
3. Add currency settings
4. Add language preferences
5. Export/import settings backup

## Notes

- All UI text is in Arabic (matching existing app)
- Form validation ensures required fields are filled
- Numeric validation for tax percentage (0-100)
- Multi-line support for address and invoice notes
- Settings icon distinguishes between general settings and printer settings
