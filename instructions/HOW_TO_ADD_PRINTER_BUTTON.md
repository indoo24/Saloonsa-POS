# How to Add Printer Button to Casher Screen

## Step 1: Import Required Files

Add these imports at the top of `casher_screen.dart`:

```dart
import '../../cubits/printer/printer_cubit.dart';
import '../../cubits/printer/printer_state.dart';
import 'printer_selection_screen.dart';
```

## Step 2: Add Printer Button to AppBar Actions

Find the AppBar in `casher_screen.dart` (around line 202) and update the `actions` list:

### Before:
```dart
appBar: AppBar(
  title: Text("الكاشير", style: theme.appBarTheme.titleTextStyle),
  actions: [
    IconButton(
      tooltip: isDarkMode ? "التبديل إلى الوضع الفاتح" : "التبديل إلى الوضع الداكن",
      icon: Icon(isDarkMode ? Icons.light_mode : Icons.dark_mode),
      onPressed: widget.onToggleTheme,
    ),
    // Show invoice button only if cart has items
    if (loadedState.cart.isNotEmpty)
      IconButton(
        icon: const Icon(Icons.receipt_long),
        onPressed: () => _navigateToInvoice(context, loadedState),
      ),
  ],
),
```

### After:
```dart
appBar: AppBar(
  title: Text("الكاشير", style: theme.appBarTheme.titleTextStyle),
  actions: [
    // Printer settings button
    BlocBuilder<PrinterCubit, PrinterState>(
      builder: (context, printerState) {
        return IconButton(
          tooltip: "إعدادات الطابعة",
          icon: Icon(
            Icons.print,
            color: printerState is PrinterConnected 
              ? Colors.green 
              : theme.iconTheme.color,
          ),
          onPressed: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => const PrinterSelectionScreen(),
              ),
            );
          },
        );
      },
    ),
    IconButton(
      tooltip: isDarkMode ? "التبديل إلى الوضع الفاتح" : "التبديل إلى الوضع الداكن",
      icon: Icon(isDarkMode ? Icons.light_mode : Icons.dark_mode),
      onPressed: widget.onToggleTheme,
    ),
    // Show invoice button only if cart has items
    if (loadedState.cart.isNotEmpty)
      IconButton(
        icon: const Icon(Icons.receipt_long),
        onPressed: () => _navigateToInvoice(context, loadedState),
      ),
  ],
),
```

## Step 3: That's It!

The printer button will now:
- ✅ Show as a print icon in the AppBar
- ✅ Turn **green** when a printer is connected
- ✅ Open the printer selection screen when tapped
- ✅ Allow users to scan, connect, and manage printers

## Visual Indicators

| State | Icon Color | Meaning |
|-------|-----------|---------|
| No printer connected | Default (white/black) | No active printer |
| Printer connected | Green | Ready to print |

## User Flow

1. User taps printer icon in AppBar
2. Printer Selection Screen opens
3. User selects WiFi/Bluetooth/USB tab
4. User taps "Search for Printers"
5. Available printers appear in list
6. User taps "Connect" on desired printer
7. Success notification appears
8. Printer icon turns green in AppBar
9. User returns to casher screen
10. Printing now works automatically!

## Notes

- The printer connection persists across app restarts (saved in SharedPreferences)
- No changes needed to existing `printInvoiceDirect()` calls
- The button uses BlocBuilder to automatically update when printer state changes
- The green color provides instant visual feedback to the user
