# Quick Testing Guide - Bluetooth Permissions

## How to Test the Fix

### 1. Build and Install the App

```bash
flutter clean
flutter pub get
flutter run
```

### 2. Test Bluetooth Scanning

#### On First Launch:
1. Navigate to printer settings
2. Click on "Bluetooth" tab
3. Click "Scan" button
4. **Expected:** Permission dialog appears asking for:
   - Bluetooth Scan
   - Bluetooth Connect  
   - Location

5. Grant permissions
6. **Expected:** Bluetooth devices appear in the list

#### Test Permission Denial:

**Scenario 1: Deny Once**
1. Click "Scan"
2. Click "Deny" on permission dialog
3. **Expected:** Warning toast appears in Arabic
4. **Expected:** No devices shown

**Scenario 2: Deny Permanently**
1. Click "Scan"
2. Check "Don't ask again" and click "Deny"
3. Click "Scan" again
4. **Expected:** Dialog appears with "Open Settings" button
5. Click "Open Settings"
6. **Expected:** App settings page opens
7. Grant permissions manually
8. Return to app and scan again
9. **Expected:** Devices appear

### 3. Check Logs

Enable verbose logging to see detailed permission states:

```bash
flutter run --verbose
```

Look for log entries like:
- `📡 Starting Bluetooth printer scan...`
- `✅ All Bluetooth permissions granted`
- `📱 Found X paired Bluetooth device(s)`

### 4. Test on Different Android Versions

**Android 11 and below:**
- Should use old Bluetooth permissions
- Should still request Location permission
- Should work without BLUETOOTH_SCAN/BLUETOOTH_CONNECT

**Android 12 and above:**
- Should use new Bluetooth permissions (BLUETOOTH_SCAN, BLUETOOTH_CONNECT)
- Should request Location permission
- Should work properly after granting permissions

### 5. Verify No Breaking Changes

**WiFi Printers:**
1. Click "WiFi" tab
2. Click "Scan"
3. **Expected:** Works without permission prompts (only network access needed)

**Printer Settings Screen:**
1. Navigate to printer settings from main screen
2. **Expected:** All existing functionality works
3. **Expected:** No visual changes to UI

## Common Issues and Solutions

### Issue: "Bluetooth is not enabled"
**Solution:** Turn on Bluetooth from Android settings

### Issue: "No paired Bluetooth devices found"
**Solution:** Pair your printer with the phone first via Android Bluetooth settings

### Issue: Permissions not requested
**Solution:** 
1. Uninstall the app completely
2. Reinstall using `flutter run`
3. Try scanning again

### Issue: Devices still not appearing
**Solution:**
1. Check logs for permission states
2. Verify permissions are granted in App Settings > Permissions
3. Ensure Bluetooth is enabled
4. Ensure printer is paired in Android Bluetooth settings

## Debug Commands

```bash
# View real-time logs
adb logcat | grep -i bluetooth

# Check installed permissions
adb shell dumpsys package com.example.barber_casher | grep permission

# Clear app data and restart
adb shell pm clear com.example.barber_casher
flutter run
```

## Success Criteria

✅ Permission dialog appears on first Bluetooth scan
✅ Bluetooth devices appear after granting permissions
✅ Clear error message when permissions denied
✅ "Open Settings" dialog for permanently denied permissions
✅ Logs show permission states and device counts
✅ Works on Android 11 and below
✅ Works on Android 12 and above
✅ WiFi and USB scanning unaffected
✅ No crashes or unexpected behavior
