# 🔍 Printer Error Codes - Quick Reference

## Error Code Format
`E[Category][Number]_[NAME]`

---

## 🌍 Environment Errors (E001-E004)

| Code | Arabic Title | Cause | Solution |
|------|--------------|-------|----------|
| **E001_BT_NOT_SUPPORTED** | البلوتوث غير مدعوم | Device doesn't support Bluetooth | Use WiFi printer instead |
| **E002_BT_DISABLED** | البلوتوث مغلق | Bluetooth is turned OFF | Go to Settings → Turn ON Bluetooth |
| **E003_LOCATION_DISABLED** | خدمات الموقع مغلقة | Location services OFF | Go to Settings → Turn ON Location (required by Android for Bluetooth discovery) |
| **E004_PERMISSION_DENIED** | صلاحيات البلوتوث مطلوبة | App doesn't have Bluetooth permissions | Grant permissions: Bluetooth Scan, Bluetooth Connect, Location |

---

## 🔌 Connection Errors (E101-E106)

| Code | Arabic Title | Cause | Solution |
|------|--------------|-------|----------|
| **E101_ALREADY_CONNECTED** | الطابعة متصلة بجهاز آخر | Printer is currently connected to another device | Disconnect from other device, or restart printer |
| **E102_CONNECTION_REFUSED** | فشل الاتصال بالطابعة | Printer refused connection | Check printer is ON, within range, not busy |
| **E103_CONNECTION_TIMEOUT** | انتهت مهلة الاتصال | Connection took too long (>15 seconds) | Move closer to printer, check printer is ON |
| **E104_PAIRING_REQUIRED** | يجب إقران الطابعة أولاً | Printer is not paired with phone | Go to Android Bluetooth settings → Pair with printer |
| **E105_CONNECTION_LOST** | انقطع الاتصال بالطابعة | Lost connection during operation | Check printer is ON and within range |
| **E106_NOT_CONNECTED** | لا توجد طابعة متصلة | No printer is currently connected | Connect to a printer first |

---

## 🔎 Discovery Errors (E201)

| Code | Arabic Title | Cause | Solution |
|------|--------------|-------|----------|
| **E201_NO_DEVICES_FOUND** | لم يتم العثور على طابعات | No Bluetooth devices discovered | 1. Turn ON printer<br>2. Pair printer in Android settings<br>3. Move closer to printer<br>4. Try scanning again |

---

## 📡 Communication Errors (E301)

| Code | Arabic Title | Cause | Solution |
|------|--------------|-------|----------|
| **E301_SEND_FAILED** | فشل إرسال البيانات | Failed to send print data | 1. Check connection<br>2. Check printer has paper<br>3. Restart printer<br>4. Try again |

---

## 🌐 Network Errors (E401)

| Code | Arabic Title | Cause | Solution |
|------|--------------|-------|----------|
| **E401_NETWORK_UNREACHABLE** | لا يمكن الوصول للطابعة | Cannot reach WiFi printer | 1. Check phone is connected to WiFi<br>2. Check printer is on same network<br>3. Verify printer IP address |

---

## ⚠️ Compatibility Errors (E501)

| Code | Arabic Title | Cause | Solution |
|------|--------------|-------|----------|
| **E501_INCOMPATIBLE** | طابعة غير متوافقة | Printer model not fully compatible | Use a compatible thermal printer (ESC/POS) |

---

## ❓ Unknown Errors (E999)

| Code | Arabic Title | Cause | Solution |
|------|--------------|-------|----------|
| **E999_UNKNOWN** | خطأ غير متوقع | Unexpected error occurred | 1. Restart app<br>2. Restart printer<br>3. Contact support |

---

## 📊 Error Priority Levels

### 🔴 Critical (Cannot Recover)
- E001_BT_NOT_SUPPORTED
- E501_INCOMPATIBLE

### 🟡 Needs User Action
- E002_BT_DISABLED
- E003_LOCATION_DISABLED
- E004_PERMISSION_DENIED
- E104_PAIRING_REQUIRED

### 🟢 Recoverable (Retry or Reconnect)
- E101_ALREADY_CONNECTED
- E102_CONNECTION_REFUSED
- E103_CONNECTION_TIMEOUT
- E105_CONNECTION_LOST
- E106_NOT_CONNECTED
- E201_NO_DEVICES_FOUND
- E301_SEND_FAILED
- E401_NETWORK_UNREACHABLE

---

## 🛠️ Troubleshooting Flow

```
Error Occurred
    ↓
Check Error Code
    ↓
E001-E004? → Environment Issue
    ↓ Fix Settings/Permissions
    ↓
E101-E106? → Connection Issue
    ↓ Check Printer/Connection
    ↓
E201? → Discovery Issue
    ↓ Pair Device
    ↓
E301? → Communication Issue
    ↓ Check Printer State
    ↓
E401? → Network Issue
    ↓ Check WiFi
    ↓
E501? → Compatibility Issue
    ↓ Use Different Printer
    ↓
E999? → Unknown Issue
    ↓ Restart Everything
```

---

## 📱 User-Facing Messages

### Example: E002_BT_DISABLED
**Toast/Dialog:**
```
البلوتوث مغلق

البلوتوث مغلق حالياً.
يرجى تشغيله من الإعدادات.

الحلول المقترحة:
  • افتح إعدادات الجهاز
  • قم بتشغيل البلوتوث
  • ارجع وحاول مرة أخرى

[حسناً]  [فتح الإعدادات]
```

### Example: E104_PAIRING_REQUIRED
**Toast/Dialog:**
```
يجب إقران الطابعة أولاً

يجب إقران الطابعة مع الجهاز أولاً من إعدادات البلوتوث.

الحلول المقترحة:
  • افتح إعدادات البلوتوث في الجهاز
  • ابحث عن الطابعة
  • اضغط على "إقران" أو "Pair"
  • ارجع للتطبيق وحاول مرة أخرى

[حسناً]  [فتح الإعدادات]
```

---

## 🔧 For Developers

### Logging Format:
```dart
_logger.e('🔴 [E002_BT_DISABLED] Bluetooth is turned off');
_logger.i('✅ [SUCCESS] Bluetooth scan completed. Found 2 device(s)');
_logger.w('⚠️ [E103_CONNECTION_TIMEOUT] Connection attempt timed out after 15s');
```

### Error Mapping Example:
```dart
try {
  await scanBluetoothPrinters();
} catch (e) {
  if (e is PrinterError) {
    // Already a mapped error
    print('Error Code: ${e.code}');
    print('Message: ${e.arabicMessage}');
  } else {
    // Map unknown error
    final mapped = PrinterErrorMapper().mapError(e);
    print('Mapped to: ${mapped.code}');
  }
}
```

---

## 📈 Metrics & Monitoring

Track these error codes to identify common issues:

```dart
// Error frequency
Map<String, int> errorCounts = {
  'E002_BT_DISABLED': 45,      // Most common - educate users
  'E104_PAIRING_REQUIRED': 23, // Second - improve onboarding
  'E103_CONNECTION_TIMEOUT': 12,
  ...
};
```

---

## ✅ Best Practices

1. **Always log error codes** for debugging
2. **Show Arabic messages** to users
3. **Provide actionable suggestions** in every error
4. **Track error frequency** to improve UX
5. **Never show raw exceptions** to users

---

## 🎯 Goal

**Zero Silent Failures + 100% Clear Guidance**

Every error should:
- ✅ Have a unique code
- ✅ Be logged
- ✅ Show clear message to user
- ✅ Provide actionable steps
- ✅ Guide user to resolution
