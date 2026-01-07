# Quick Testing Guide: Bluetooth Classic Thermal Printers

## 🚀 Quick Start Testing

### Test 1: No Paired Printers
**Expected Behavior:**
1. Tap "بحث عن طابعات" on Bluetooth tab
2. Permission dialog appears (Android 12+ only)
3. Grant permission
4. Dialog appears: "لم يتم العثور على طابعات مقترنة"
5. Dialog shows 7-step pairing guide
6. "فتح إعدادات البلوتوث" button visible

**Pass Criteria:** ✅ Dialog appears with pairing instructions

---

### Test 2: Pair a Printer
**Steps:**
1. Turn on thermal printer
2. From test dialog, tap "فتح إعدادات البلوتوث"
3. In Android Settings → Bluetooth → "Scan for devices"
4. Select your printer (e.g., "Xprinter-58")
5. Enter PIN: `0000` or `1234`
6. Wait for "Paired" status
7. Return to app
8. Tap "بحث عن طابعات"

**Pass Criteria:** ✅ Printer appears in list with name and address

---

### Test 3: Connect to Printer
**Steps:**
1. Ensure printer is paired and powered on
2. Tap "بحث عن طابعات"
3. Printer appears in list
4. Tap "اتصال" button
5. Wait for connection

**Pass Criteria:** 
- ✅ "جاري الاتصال..." appears
- ✅ "تم الاتصال بالطابعة: [name]" toast shown
- ✅ Green connected banner appears at top

---

### Test 4: Test Print
**Steps:**
1. Connect to printer (Test 3)
2. Navigate to printer settings
3. Tap "طباعة تجريبية" button

**Pass Criteria:** ✅ Receipt prints with Arabic text correctly

---

### Test 5: Permission Denied
**Steps:**
1. Uninstall app
2. Reinstall app
3. Tap "بحث عن طابعات" on Bluetooth tab
4. When permission dialog appears, tap "Deny"
5. Observe error message

**Pass Criteria:** 
- ✅ Toast: "يجب منح صلاحيات البلوتوث"
- ✅ No crash

---

### Test 6: Permission Permanently Denied
**Steps:**
1. Go to Android Settings → Apps → [Your App] → Permissions
2. Disable "Nearby devices" / "Bluetooth"
3. Return to app
4. Tap "بحث عن طابعات"

**Pass Criteria:** 
- ✅ Dialog: "صلاحيات البلوتوث مطلوبة"
- ✅ "فتح الإعدادات" button appears
- ✅ Button opens app settings

---

### Test 7: Bluetooth Disabled
**Steps:**
1. Disable Bluetooth from Android quick settings
2. In app, tap "بحث عن طابعات"

**Pass Criteria:** 
- ✅ Error: "البلوتوث مغلق"
- ✅ Guidance: "يرجى تشغيل البلوتوث من إعدادات الجهاز"

---

### Test 8: Printer Paired but Turned Off
**Steps:**
1. Pair printer in Android Settings
2. Turn OFF printer
3. In app, tap "بحث عن طابعات"
4. Printer appears in list
5. Tap "اتصال"

**Pass Criteria:** 
- ✅ Connection attempt times out (15 seconds)
- ✅ Error message explains printer is off or out of range

---

### Test 9: Android Version Compatibility
**Test on each version:**
- Android 8 (API 26)
- Android 10 (API 29)
- Android 12 (API 31)
- Android 13 (API 33)
- Android 14 (API 34)

**Pass Criteria for Each:**
- ✅ No permission dialogs on Android 8-11
- ✅ BLUETOOTH_CONNECT permission on Android 12+
- ✅ NO Location permission requested
- ✅ Bonded printers appear

---

### Test 10: Multiple Bluetooth Devices
**Setup:**
1. Pair thermal printer
2. Pair Bluetooth headphones
3. Pair car audio

**Steps:**
1. Tap "بحث عن طابعات"

**Pass Criteria:** 
- ✅ All devices appear (or)
- ✅ Only printer appears if filtering enabled
- ✅ Can connect to correct printer

---

## 🔍 Debug Checklist

### If "No printers found"
```
[ ] Is Bluetooth enabled?
[ ] Is printer paired in Android Settings?
[ ] Is BLUETOOTH_CONNECT permission granted?
[ ] Check logs for bonded device count
```

### If "Connection fails"
```
[ ] Is printer turned on?
[ ] Is printer within range (<10m)?
[ ] Is printer already connected to another device?
[ ] Check battery level
```

### If "Permission error"
```
[ ] Android version >= 12?
[ ] BLUETOOTH_CONNECT in AndroidManifest.xml?
[ ] Permission request code working?
[ ] Check Settings → Apps → Permissions
```

---

## 📋 Test Report Template

```
Test Date: ___________
Tester: ___________
Device: ___________ (Model)
Android Version: ___________

Test 1 (No Paired Printers): [ ] Pass [ ] Fail
Test 2 (Pair Printer): [ ] Pass [ ] Fail
Test 3 (Connect): [ ] Pass [ ] Fail
Test 4 (Test Print): [ ] Pass [ ] Fail
Test 5 (Permission Denied): [ ] Pass [ ] Fail
Test 6 (Permanently Denied): [ ] Pass [ ] Fail
Test 7 (Bluetooth Disabled): [ ] Pass [ ] Fail
Test 8 (Printer Off): [ ] Pass [ ] Fail
Test 9 (Version Compatibility): [ ] Pass [ ] Fail
Test 10 (Multiple Devices): [ ] Pass [ ] Fail

Issues Found:
_________________________________
_________________________________

Notes:
_________________________________
_________________________________
```

---

## 🎯 Success Criteria Summary

**All tests must pass for production deployment:**

1. ✅ Bonded printers always appear
2. ✅ Pairing guidance shown when no devices
3. ✅ Permissions requested correctly per Android version
4. ✅ Connection succeeds with powered-on printer
5. ✅ Clear error messages for all failure scenarios
6. ✅ No crashes on permission denial
7. ✅ Works on Android 8-14
8. ✅ Arabic text displays correctly
9. ✅ Test print successful
10. ✅ Auto-reconnect works

---

## 🚨 Critical Test Scenarios

### Scenario A: First-Time User
1. Install app fresh
2. No printers paired
3. Tap search
→ **Must see:** Pairing instruction dialog

### Scenario B: Experienced User
1. Printer already paired
2. Printer turned on
3. Tap search
→ **Must see:** Printer in list immediately

### Scenario C: Permission Issues
1. Permission denied once
2. Try again
→ **Must see:** Permission request again

### Scenario D: System State Issues
1. Bluetooth off
2. Tap search
→ **Must see:** Enable Bluetooth guidance

---

**Last Updated:** January 1, 2026  
**For:** Bluetooth Classic Thermal Printer Implementation  
**Status:** Ready for Testing ✅
