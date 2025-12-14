# Error Handling Flow Architecture

## 🏗️ System Architecture

```
┌─────────────────────────────────────────────────────────────┐
│                     Flutter Application                      │
│                                                               │
│  ┌───────────────────────────────────────────────────────┐  │
│  │              Global Error Handler                      │  │
│  │  ┌──────────────────────────────────────────────────┐ │  │
│  │  │ runZonedGuarded (Async Errors)                   │ │  │
│  │  │ FlutterError.onError (Widget Errors)             │ │  │
│  │  │ PlatformDispatcher.instance.onError (Platform)   │ │  │
│  │  └──────────────────────────────────────────────────┘ │  │
│  └───────────────────────────────────────────────────────┘  │
│                              ↓                                │
│  ┌───────────────────────────────────────────────────────┐  │
│  │                   UI Layer (Screens)                   │  │
│  │                                                         │  │
│  │  ErrorBoundary → InvoicePage                           │  │
│  │  ErrorBoundary → CashierScreen                         │  │
│  │  ErrorBoundary → LoginScreen                           │  │
│  └───────────────────────────────────────────────────────┘  │
│                              ↓                                │
│  ┌───────────────────────────────────────────────────────┐  │
│  │                 State Management (Bloc)                │  │
│  │                                                         │  │
│  │  AuthCubit ←→ AuthRepository                          │  │
│  │  CashierCubit ←→ CashierRepository                    │  │
│  └───────────────────────────────────────────────────────┘  │
│                              ↓                                │
│  ┌───────────────────────────────────────────────────────┐  │
│  │                   Network Layer                        │  │
│  │                                                         │  │
│  │  NetworkService → connectivity_plus                    │  │
│  │       ↓                                                 │  │
│  │  ApiClient (with timeout, retries, error handling)     │  │
│  └───────────────────────────────────────────────────────┘  │
│                              ↓                                │
│  ┌───────────────────────────────────────────────────────┐  │
│  │                  Backend API                           │  │
│  │                                                         │  │
│  │  http://192.168.100.8:8000/api (Development)          │  │
│  │  https://api.yourdomain.com/api (Production)          │  │
│  └───────────────────────────────────────────────────────┘  │
└─────────────────────────────────────────────────────────────┘
```

---

## 🔄 Error Handling Flow

### 1. API Call Flow
```
User Action
    ↓
UI Widget (Form Submit)
    ↓
Bloc Event (e.g., CreateOrderEvent)
    ↓
Bloc → Repository
    ↓
Repository → ApiClient
    ↓
┌─────────────────────────────────────┐
│   NetworkService.ensureConnected()   │ ← Check internet FIRST
└─────────────────────────────────────┘
    ↓
    ├─ No Internet → throw NetworkException
    │                      ↓
    │              "لا يوجد اتصال بالإنترنت"
    │
    └─ Has Internet
         ↓
┌─────────────────────────────────────┐
│   http.post() with .timeout(30s)    │
└─────────────────────────────────────┘
    ↓
    ├─ Timeout → throw TimeoutException
    │                 ↓
    │         "انتهت مهلة الطلب"
    │
    ├─ SocketException → throw NetworkException
    │                         ↓
    │                 "لا يوجد اتصال"
    │
    └─ Response received
         ↓
┌─────────────────────────────────────┐
│   _handleResponse(response)          │
└─────────────────────────────────────┘
    ↓
    ├─ Status 200-299 → Success ✅
    │
    ├─ Status 401 → Unauthorized
    │    ↓
    │  clearAuth() + throw ApiException
    │
    ├─ Status 422 → ValidationException
    │    ↓
    │  Show field errors
    │
    └─ Other errors → ApiException
         ↓
    Bloc State: Error
         ↓
    UI: BlocListener
         ↓
    Show SnackBar/Dialog with Arabic message
```

---

## 🛡️ Error Catching Layers

### Layer 1: Global Handler (Catches Everything)
```dart
main() async {
  // Layer 1: Catches ALL uncaught errors
  await GlobalErrorHandler.runAppWithErrorHandling(app);
}
```

**Catches**:
- Widget build errors
- Async errors
- Platform errors
- Any unhandled exception

**Result**: No red error screen, logs error, shows AppErrorWidget

---

### Layer 2: Error Boundary (Per-Screen Protection)
```dart
ErrorBoundary(
  child: InvoicePage(),
  errorBuilder: (error, retry) => CustomErrorWidget(),
)
```

**Catches**:
- Errors in this widget subtree only
- Doesn't crash entire app
- Shows custom error UI
- Allows retry

**Result**: Isolated failure, rest of app works

---

### Layer 3: Bloc Error States
```dart
BlocListener<CashierCubit, CashierState>(
  listener: (context, state) {
    if (state is CashierError) {
      // Show user-friendly message
    }
  },
)
```

**Catches**:
- Business logic errors
- API errors
- State management errors

**Result**: User sees specific, contextual error message

---

### Layer 4: Try-Catch (Specific Operations)
```dart
try {
  await apiClient.post('/orders', body: data);
} on NetworkException catch (e) {
  // Handle no internet
} on ValidationException catch (e) {
  // Handle validation errors
} catch (e) {
  // Handle any other error
}
```

**Catches**:
- Specific expected errors
- Allows custom handling per error type

**Result**: Precise error handling and user feedback

---

## 📊 Error Types & Handling

| Error Type | Where Caught | User Message | Action |
|------------|--------------|--------------|--------|
| **NetworkException** | ApiClient | "لا يوجد اتصال بالإنترنت" | Show retry button |
| **TimeoutException** | ApiClient | "انتهت مهلة الطلب" | Show retry button |
| **ValidationException** | ApiClient | Field-specific errors | Show in form |
| **ApiException (401)** | ApiClient | "غير مصرح" | Auto logout |
| **ApiException (500)** | ApiClient | "خطأ في الخادم" | Show support info |
| **Widget Error** | ErrorBoundary | "حدث خطأ ما" | Show error widget |
| **Unknown Error** | GlobalHandler | "حدث خطأ غير متوقع" | Log & show generic |

---

## 🎯 Validation Flow

```
User enters data in TextFormField
    ↓
TextFormField validator function
    ↓
InputValidator.discountPercentage(value)
    ↓
    ├─ value is null/empty → "نسبة الخصم مطلوب"
    │
    ├─ value is not numeric → "يجب إدخال رقم صحيح"
    │
    ├─ value < 0 → "القيمة يجب أن تكون 0 على الأقل"
    │
    ├─ value > 100 → "القيمة يجب أن تكون 100 كحد أقصى"
    │
    └─ value valid → null (no error)
         ↓
    Form is valid
         ↓
    Submit button enabled
         ↓
    Proceed with API call
```

---

## 🌐 Network Monitoring Flow

```
App Startup
    ↓
NetworkService.initialize()
    ↓
connectivity_plus starts monitoring
    ↓
┌──────────────────────────────────┐
│  Network Status Stream           │
│  (WiFi, Mobile, None)            │
└──────────────────────────────────┘
    ↓
    ├─ Connection detected
    │    ↓
    │  Test actual internet (ping google.com)
    │    ↓
    │    ├─ Success → isConnected = true
    │    └─ Fail → isConnected = false
    │
    └─ No connection → isConnected = false
         ↓
    Broadcast status to listeners
         ↓
┌──────────────────────────────────┐
│  Widgets listening to stream      │
│  - Show offline banner            │
│  - Disable buttons                │
│  - Show cached data               │
└──────────────────────────────────┘
```

---

## 🔧 Configuration Flow

```
App Launch
    ↓
Check AppConfig.current
    ↓
    ├─ Development
    │    ↓
    │  - Local API: http://192.168.100.8:8000/api
    │  - Logging enabled
    │  - Show debug banner
    │
    ├─ Staging
    │    ↓
    │  - Staging API: https://staging-api.domain.com
    │  - Logging enabled
    │  - Crash reporting enabled
    │
    └─ Production
         ↓
       - Production API: https://api.domain.com
       - Logging disabled
       - Crash reporting enabled
       - No debug banner
```

---

## 📱 User Experience Flow

### Happy Path ✅
```
User opens app
  → Splash screen (with animations)
  → Check authentication
  → Load cashier screen
  → Create invoice
  → Submit order
  → Success message
  → Print receipt
```

### Error Path (Network) ❌
```
User opens app
  → Splash screen
  → Check authentication
  → No internet detected
  → Show "لا يوجد اتصال بالإنترنت"
  → User clicks retry
  → Internet restored
  → Load cashier screen ✅
```

### Error Path (Validation) ❌
```
User creates invoice
  → Enters discount: "150%"
  → Clicks save
  → Validator catches error
  → Show "القيمة يجب أن تكون 100 كحد أقصى"
  → User corrects to "15%"
  → Validation passes
  → Submit order ✅
```

### Error Path (API) ❌
```
User submits order
  → API call starts
  → Server returns 500 error
  → ApiClient catches error
  → Bloc state: CashierError
  → BlocListener shows SnackBar
  → "حدث خطأ في الخادم"
  → User clicks retry
  → Success ✅
```

---

## 🚀 Deployment Stages

### Stage 1: Development
```
AppConfig.development
    ↓
Local server (192.168.100.8)
Logging enabled
All errors visible
```

### Stage 2: Staging
```
AppConfig.staging
    ↓
Staging server (staging-api.domain.com)
Logging enabled
Crash reporting enabled
Test with real scenarios
```

### Stage 3: Production
```
AppConfig.production
    ↓
Production server (api.domain.com)
Logging disabled
Crash reporting enabled
User-friendly errors only
```

---

## 📈 Success Metrics

### Zero Tolerance Goals
- ✅ **0** red error screens
- ✅ **0** app crashes
- ✅ **100%** errors caught
- ✅ **100%** errors logged
- ✅ **100%** user-friendly messages

### Performance Goals
- ⏱️ API timeout: 30 seconds
- 🔄 Max retry attempts: 3
- 📱 Offline detection: < 1 second
- 🚀 App startup: < 3 seconds

---

**This architecture ensures**:
1. Every error is caught somewhere
2. Users never see technical errors
3. All errors are logged for debugging
4. App never crashes
5. Graceful degradation always

🎉 **Production-Ready Error Handling Achieved!**
