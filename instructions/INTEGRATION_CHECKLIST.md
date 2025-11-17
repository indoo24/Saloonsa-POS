# ✅ STEP-BY-STEP INTEGRATION CHECKLIST

Follow this checklist to integrate Bloc into your app without breaking anything!

---

## 📋 PHASE 1: SETUP (5 minutes)

### ✅ Step 1: Add Dependencies
- [x] Added `flutter_bloc: ^8.1.6` to pubspec.yaml
- [x] Added `equatable: ^2.0.7` to pubspec.yaml
- [x] Ran `flutter pub get`

### ✅ Step 2: Verify Files Created
Check that these files exist:
- [x] `lib/repositories/auth_repository.dart`
- [x] `lib/repositories/cashier_repository.dart`
- [x] `lib/cubits/auth/auth_cubit.dart`
- [x] `lib/cubits/auth/auth_state.dart`
- [x] `lib/cubits/cashier/cashier_cubit.dart`
- [x] `lib/cubits/cashier/cashier_state.dart`

---

## 📋 PHASE 2: UPDATE MAIN.DART (10 minutes)

### ✅ Step 3: Add Imports
Add these imports at the top of `lib/main.dart`:

```dart
import 'package:flutter_bloc/flutter_bloc.dart';
import 'cubits/auth/auth_cubit.dart';
import 'cubits/auth/auth_state.dart';
import 'cubits/cashier/cashier_cubit.dart';
import 'repositories/auth_repository.dart';
import 'repositories/cashier_repository.dart';
```

- [ ] Added imports

### ✅ Step 4: Wrap MaterialApp
Replace your `MaterialApp` widget with providers:

**BEFORE:**
```dart
return MaterialApp(
  theme: lightTheme,
  darkTheme: darkTheme,
  home: SplashScreen(onToggleTheme: _toggleTheme),
);
```

**AFTER:**
```dart
return MultiRepositoryProvider(
  providers: [
    RepositoryProvider(create: (context) => AuthRepository()),
    RepositoryProvider(create: (context) => CashierRepository()),
  ],
  child: MultiBlocProvider(
    providers: [
      BlocProvider(
        create: (context) => AuthCubit(
          repository: context.read<AuthRepository>(),
        )..checkAuthStatus(),
      ),
      BlocProvider(
        create: (context) => CashierCubit(
          repository: context.read<CashierRepository>(),
        ),
      ),
    ],
    child: MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Barber Cashier',
      theme: lightTheme,
      darkTheme: darkTheme,
      themeMode: _themeMode,
      home: BlocBuilder<AuthCubit, AuthState>(
        builder: (context, state) {
          if (state is AuthChecking) {
            return SplashScreen(onToggleTheme: _toggleTheme);
          } else if (state is AuthAuthenticated) {
            return CashierScreen(onToggleTheme: _toggleTheme);
          } else {
            return LoginScreen(onToggleTheme: _toggleTheme);
          }
        },
      ),
    ),
  ),
);
```

- [ ] Wrapped MaterialApp
- [ ] Added BlocBuilder for home
- [ ] Tested that app still runs

---

## 📋 PHASE 3: UPDATE LOGIN SCREEN (15 minutes)

### ✅ Step 5: Add Import
Add to `lib/screens/auth/login_screen.dart`:

```dart
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../cubits/auth/auth_cubit.dart';
import '../../cubits/auth/auth_state.dart';
```

- [ ] Added imports

### ✅ Step 6: Update Login Method
Find the `_login()` method and replace it:

**BEFORE:**
```dart
Future<void> _login() async {
  if (_formKey.currentState!.validate()) {
    if (_showSubdomain) {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('subdomain', _subdomainController.text);
    }
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Logging in...')),
    );
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (context) => CashierScreen(onToggleTheme: widget.onToggleTheme)),
    );
  }
}
```

**AFTER:**
```dart
Future<void> _login() async {
  if (_formKey.currentState!.validate()) {
    if (_showSubdomain) {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('subdomain', _subdomainController.text);
    }
    
    // Call cubit login - navigation happens automatically
    await context.read<AuthCubit>().login(
      username: _usernameController.text,
      password: _passwordController.text,
      subdomain: _subdomainController.text,
    );
  }
}
```

- [ ] Updated login method
- [ ] Removed manual navigation

### ✅ Step 7: Wrap Scaffold with BlocConsumer
Wrap your `Scaffold` widget:

**BEFORE:**
```dart
@override
Widget build(BuildContext context) {
  final theme = Theme.of(context);
  
  return Scaffold(
    body: Center(
      child: SingleChildScrollView(
        // ... your form
      ),
    ),
  );
}
```

**AFTER:**
```dart
@override
Widget build(BuildContext context) {
  final theme = Theme.of(context);
  
  return BlocConsumer<AuthCubit, AuthState>(
    listener: (context, state) {
      if (state is AuthError) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(state.message),
            backgroundColor: Colors.red,
          ),
        );
      }
    },
    builder: (context, state) {
      final isLoading = state is AuthLoading;
      
      return Scaffold(
        body: Stack(
          children: [
            Center(
              child: SingleChildScrollView(
                // ... your existing form
              ),
            ),
            if (isLoading)
              Container(
                color: Colors.black26,
                child: const Center(
                  child: CircularProgressIndicator(),
                ),
              ),
          ],
        ),
      );
    },
  );
}
```

- [ ] Added BlocConsumer
- [ ] Added loading overlay
- [ ] Tested login flow

---

## 📋 PHASE 4: UPDATE CASHIER SCREEN (20 minutes)

### ✅ Step 8: Add Imports
Add to `lib/screens/casher/casher_screen.dart`:

```dart
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../cubits/cashier/cashier_cubit.dart';
import '../../cubits/cashier/cashier_state.dart';
```

- [ ] Added imports

### ✅ Step 9: Remove Local State
In `_CashierScreenState`, remove these lines:

```dart
// DELETE THESE:
Customer? _selectedCustomer;
final List<String> _barbers = ['أسامة', 'يوسف', 'محمد', 'أحمد'];
String selectedCategory = "قص الشعر";
List<ServiceModel> cart = [];

List<ServiceModel> get filteredServices {
  return allServices.where((s) => s.category == selectedCategory).toList();
}

void addToCart(ServiceModel service, String barberName) {
  // delete entire method
}

void removeFromCart(int index) {
  // delete entire method
}
```

- [ ] Removed local state variables
- [ ] Removed addToCart method
- [ ] Removed removeFromCart method

### ✅ Step 10: Add initState
Add this method to initialize data:

```dart
@override
void initState() {
  super.initState();
  context.read<CashierCubit>().initialize();
}
```

- [ ] Added initState

### ✅ Step 11: Update _showBarberSelectionSheet
In the confirm button callback, change:

**BEFORE:**
```dart
onPressed: () {
  if (localSelectedBarber != null) {
    addToCart(service, localSelectedBarber!);
    Navigator.pop(context);
  }
},
```

**AFTER:**
```dart
onPressed: () {
  if (localSelectedBarber != null) {
    context.read<CashierCubit>().addToCart(service, localSelectedBarber!);
    Navigator.pop(context);
  }
},
```

Also wrap the DropdownButtonFormField with BlocBuilder:

**BEFORE:**
```dart
DropdownButtonFormField<String>(
  hint: const Text('الرجاء اختيار حلاق'),
  items: _barbers.map((barber) {
    // ...
  }).toList(),
  // ...
),
```

**AFTER:**
```dart
BlocBuilder<CashierCubit, CashierState>(
  builder: (context, state) {
    if (state is! CashierLoaded) return const SizedBox();
    
    return DropdownButtonFormField<String>(
      hint: const Text('الرجاء اختيار حلاق'),
      items: state.barbers.map((barber) {
        return DropdownMenuItem(
          value: barber,
          child: Text(barber, style: Theme.of(context).textTheme.titleMedium)
        );
      }).toList(),
      onChanged: (value) {
        localSelectedBarber = value;
      },
      decoration: const InputDecoration(border: OutlineInputBorder()),
    );
  },
)
```

- [ ] Updated barber selection
- [ ] Changed addToCart call to use cubit

### ✅ Step 12: Wrap build() with BlocConsumer
Replace entire `build()` method with the version from `BLOC_INTEGRATION_GUIDE.md` Step 4.

Key changes:
- Wrap with `BlocConsumer<CashierCubit, CashierState>`
- Add listener for toasts
- Check state type before building UI
- Use `state.cart`, `state.filteredServices`, etc.
- Call `context.read<CashierCubit>().selectCategory()` for category changes
- Call `context.read<CashierCubit>().removeFromCart()` for cart removal

- [ ] Added BlocConsumer
- [ ] Added listener for toasts
- [ ] Added loading state
- [ ] Added error state
- [ ] Used data from state
- [ ] Tested adding items to cart
- [ ] Tested removing items from cart
- [ ] Tested category selection

---

## 📋 PHASE 5: UPDATE HEADER SECTION (10 minutes)

### ✅ Step 13: Add Imports
Add to `lib/screens/casher/header_section.dart`:

```dart
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../cubits/cashier/cashier_cubit.dart';
import '../../cubits/cashier/cashier_state.dart';
```

- [ ] Added imports

### ✅ Step 14: Remove Local Customer List
Delete this line:

```dart
// DELETE:
static final List<Customer> _customers = [
  Customer(id: 1, name: 'عميل كاش'),
  // ... rest
];
```

- [ ] Removed local customers list

### ✅ Step 15: Update Add Customer Button
In `_showAddCustomerDialog`, find the ElevatedButton and replace:

**BEFORE:**
```dart
ElevatedButton(
  onPressed: () {
    if (formKey.currentState!.validate()) {
      final customer = Customer(
        id: DateTime.now().millisecondsSinceEpoch,
        name: nameController.text,
        phone: phoneController.text.isNotEmpty ? phoneController.text : null,
        customerId: idController.text.isNotEmpty ? idController.text : null,
      );
      Navigator.pop(context, customer);
    }
  },
  child: const Text('إضافة'),
),
```

**AFTER:**
```dart
ElevatedButton(
  onPressed: () async {
    if (formKey.currentState!.validate()) {
      await context.read<CashierCubit>().addCustomer(
        name: nameController.text,
        phone: phoneController.text.isNotEmpty ? phoneController.text : null,
        customerId: idController.text.isNotEmpty ? idController.text : null,
      );
      Navigator.pop(context);
    }
  },
  child: const Text('إضافة'),
),
```

- [ ] Updated add customer button

### ✅ Step 16: Wrap build() with BlocBuilder
Wrap the entire `build()` return with BlocBuilder:

**AFTER:**
```dart
@override
Widget build(BuildContext context) {
  final theme = Theme.of(context);

  return BlocBuilder<CashierCubit, CashierState>(
    builder: (context, state) {
      if (state is! CashierLoaded) {
        return const SizedBox();
      }

      return Padding(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ... rest of your UI
            Autocomplete<Customer>(
              // ...
              optionsBuilder: (TextEditingValue textEditingValue) {
                if (textEditingValue.text.isEmpty) {
                  return state.customers; // From cubit state
                }
                return state.customers.where((Customer option) {
                  // ... filtering logic
                });
              },
              // ...
            ),
          ],
        ),
      );
    },
  );
}
```

- [ ] Wrapped with BlocBuilder
- [ ] Used `state.customers` instead of `_customers`
- [ ] Tested adding customers
- [ ] Tested searching customers

---

## 📋 PHASE 6: TESTING (15 minutes)

### ✅ Step 17: Test Authentication Flow
- [ ] App starts and shows splash screen briefly
- [ ] Login screen appears
- [ ] Enter credentials and click login
- [ ] Loading indicator appears
- [ ] Cashier screen appears after login
- [ ] No manual navigation code needed

### ✅ Step 18: Test Cashier Features
- [ ] Services load and display
- [ ] Can switch between categories
- [ ] Can select a service
- [ ] Barber selection sheet opens
- [ ] Can select barber
- [ ] Item added to cart
- [ ] Success toast appears
- [ ] Cart displays item
- [ ] Can remove item from cart
- [ ] Removal toast appears

### ✅ Step 19: Test Customer Management
- [ ] Can search for existing customers
- [ ] Can add new customer
- [ ] New customer appears in dropdown
- [ ] Customer is automatically selected

### ✅ Step 20: Test Error Handling
- [ ] Try login with empty fields - see validation
- [ ] Network errors show proper messages
- [ ] Can retry after errors

---

## 📋 PHASE 7: CLEANUP (5 minutes)

### ✅ Step 21: Remove Old Code
- [ ] Remove any unused imports
- [ ] Remove commented-out old code
- [ ] Run `flutter analyze` to check for issues

### ✅ Step 22: Enable Bloc Logging (Optional)
Add to `main.dart` for debugging:

```dart
import 'package:flutter_bloc/flutter_bloc.dart';

class MyBlocObserver extends BlocObserver {
  @override
  void onChange(BlocBase bloc, Change change) {
    super.onChange(bloc, change);
    print('${bloc.runtimeType} $change');
  }
}

void main() {
  Bloc.observer = MyBlocObserver();
  runApp(const MyApp());
}
```

- [ ] Added Bloc observer (optional)

---

## 📋 FINAL CHECKLIST

- [ ] All tests pass
- [ ] App runs without errors
- [ ] No unused imports
- [ ] No compiler warnings
- [ ] Login/logout works
- [ ] Cart operations work
- [ ] Customer operations work
- [ ] Loading states show properly
- [ ] Error messages display correctly
- [ ] Toasts appear for actions

---

## 🎉 CONGRATULATIONS!

You have successfully integrated Bloc/Cubit into your app!

### What You Achieved:
✅ Separated UI from business logic
✅ Centralized state management
✅ Made code more testable
✅ Improved maintainability
✅ Added proper error handling
✅ Implemented loading states

### Next Steps:
1. Add more features using the same pattern
2. Write unit tests for cubits
3. Write widget tests for UI
4. Connect to real backend API
5. Add more advanced features

### Need Help?
- Check `BLOC_INTEGRATION_GUIDE.md` for detailed explanations
- Check `BLOC_CHEAT_SHEET.md` for quick reference
- Check `ARCHITECTURE_DIAGRAM.md` for visual understanding
- Check cubit files - they have detailed comments

**Happy coding! 🚀**
