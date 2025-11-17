# 🎯 BLOC/CUBIT INTEGRATION GUIDE
## Complete State Management for Barber Cashier App

---

## 📦 STEP 1: DEPENDENCIES (ALREADY ADDED)

Your `pubspec.yaml` now includes:
```yaml
flutter_bloc: ^8.1.6  # State management
equatable: ^2.0.7     # Easy state comparison
```

---

## 🗂️ FOLDER STRUCTURE

```
lib/
├── cubits/
│   ├── auth/
│   │   ├── auth_cubit.dart          ✅ Created
│   │   └── auth_state.dart          ✅ Created
│   └── cashier/
│       ├── cashier_cubit.dart       ✅ Created
│       └── cashier_state.dart       ✅ Created
├── repositories/
│   ├── auth_repository.dart         ✅ Created
│   └── cashier_repository.dart      ✅ Created
└── screens/
    ├── auth/
    │   └── login_screen.dart        🔄 Needs integration
    └── casher/
        ├── casher_screen.dart       🔄 Needs integration
        ├── header_section.dart      🔄 Needs integration
        └── cart_section.dart        🔄 Needs integration
```

---

## 🚀 STEP 2: UPDATE MAIN.DART

Replace your `main.dart` with this:

```dart
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'screens/splash_screen.dart';
import 'screens/auth/login_screen.dart';
import 'screens/casher/casher_screen.dart';
import 'theme.dart';
import 'cubits/auth/auth_cubit.dart';
import 'cubits/cashier/cashier_cubit.dart';
import 'repositories/auth_repository.dart';
import 'repositories/cashier_repository.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  ThemeMode _themeMode = ThemeMode.light;

  void _toggleTheme() {
    setState(() {
      _themeMode = _themeMode == ThemeMode.light ? ThemeMode.dark : ThemeMode.light;
    });
  }

  @override
  Widget build(BuildContext context) {
    return MultiRepositoryProvider(
      // Step 1: Provide repositories to entire app
      providers: [
        RepositoryProvider(create: (context) => AuthRepository()),
        RepositoryProvider(create: (context) => CashierRepository()),
      ],
      child: MultiBlocProvider(
        // Step 2: Provide cubits to entire app
        providers: [
          BlocProvider(
            create: (context) => AuthCubit(
              repository: context.read<AuthRepository>(),
            )..checkAuthStatus(), // Check if user is logged in
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
          // Step 3: Use BlocBuilder to decide which screen to show
          home: BlocBuilder<AuthCubit, AuthState>(
            builder: (context, state) {
              if (state is AuthChecking) {
                // Show splash while checking auth
                return SplashScreen(onToggleTheme: _toggleTheme);
              } else if (state is AuthAuthenticated) {
                // User is logged in, show cashier screen
                return CashierScreen(onToggleTheme: _toggleTheme);
              } else {
                // User not logged in, show login screen
                return LoginScreen(onToggleTheme: _toggleTheme);
              }
            },
          ),
        ),
      ),
    );
  }
}
```

**What this does:**
- ✅ Creates repositories once for the entire app
- ✅ Creates cubits once and provides them to all screens
- ✅ Automatically switches between Login and Cashier screens based on auth state
- ✅ No more manual navigation - Bloc handles it!

---

## 🔐 STEP 3: INTEGRATE LOGIN SCREEN

### Option A: Minimal Changes (Recommended)

In your `login_screen.dart`, replace the `_login()` method:

```dart
// FIND THIS:
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

// REPLACE WITH THIS:
Future<void> _login() async {
  if (_formKey.currentState!.validate()) {
    // Save subdomain
    if (_showSubdomain) {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('subdomain', _subdomainController.text);
    }
    
    // Call the cubit login method
    await context.read<AuthCubit>().login(
      username: _usernameController.text,
      password: _passwordController.text,
      subdomain: _subdomainController.text,
    );
    
    // No need for manual navigation!
    // AuthCubit will emit AuthAuthenticated state
    // and main.dart's BlocBuilder will automatically show CashierScreen
  }
}
```

### Add loading indicator and error handling

Wrap your Scaffold with BlocConsumer:

```dart
@override
Widget build(BuildContext context) {
  final theme = Theme.of(context);

  return BlocConsumer<AuthCubit, AuthState>(
    // Listen for state changes to show messages
    listener: (context, state) {
      if (state is AuthError) {
        // Show error message
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(state.message),
            backgroundColor: Colors.red,
          ),
        );
      }
    },
    // Build UI based on state
    builder: (context, state) {
      final isLoading = state is AuthLoading;

      return Scaffold(
        body: Stack(
          children: [
            // Your existing login form UI
            Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(24.0),
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 400),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      // ... your existing UI code
                      children: [
                        // ... your existing fields
                        
                        // Your login button (modify it)
                        ElevatedButton(
                          onPressed: isLoading ? null : _login, // Disable when loading
                          child: isLoading
                              ? const SizedBox(
                                  height: 20,
                                  width: 20,
                                  child: CircularProgressIndicator(strokeWidth: 2),
                                )
                              : const Text('تسجيل الدخول'),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
            // Show loading overlay
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

---

## 💰 STEP 4: INTEGRATE CASHIER SCREEN

### Replace your CashierScreen class:

Find this section in `casher_screen.dart`:

```dart
class _CashierScreenState extends State<CashierScreen> {
  Customer? _selectedCustomer;
  final List<String> _barbers = ['أسامة', 'يوسف', 'محمد', 'أحمد'];
  String selectedCategory = "قص الشعر";
  List<ServiceModel> cart = [];

  List<ServiceModel> get filteredServices {
    return allServices.where((s) => s.category == selectedCategory).toList();
  }

  void addToCart(ServiceModel service, String barberName) {
    // ... existing code
  }

  void removeFromCart(int index) {
    // ... existing code
  }
```

**Replace the entire class with:**

```dart
class _CashierScreenState extends State<CashierScreen> {
  @override
  void initState() {
    super.initState();
    // Initialize data when screen opens
    context.read<CashierCubit>().initialize();
  }

  // No more local state! Everything is in the Cubit
  // No more addToCart, removeFromCart methods - they're in the Cubit

  void _showBarberSelectionSheet(ServiceModel service) {
    // Keep your existing implementation but change the callback
    String? localSelectedBarber;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return Padding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(context).viewInsets.bottom,
            left: 16,
            right: 16,
            top: 16,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                'اختر الحلاق لخدمة "${service.name}"',
                style: Theme.of(context).textTheme.titleMedium,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),
              // Get barbers from state instead of local variable
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
              ),
              const SizedBox(height: 24),
              Row(
                children: [
                  Expanded(
                    child: TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: const Text('إلغاء'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () {
                        if (localSelectedBarber != null) {
                          // Call cubit method instead of local method
                          context.read<CashierCubit>().addToCart(
                            service,
                            localSelectedBarber!,
                          );
                          Navigator.pop(context);
                        }
                      },
                      child: const Text('تأكيد'),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
            ],
          ),
        );
      },
    );
  }

  IconData _getIconForCategory(String category) {
    // Keep your existing implementation
    switch (category) {
      case "قص الشعر": return Icons.content_cut;
      case "حلاقة ذقن": return Icons.face_retouching_natural;
      case "العناية بالبشرة": return Icons.cleaning_services;
      case "الصبغات": return Icons.brush;
      case "استشوار": return Icons.air;
      case "تسريحة": return Icons.style;
      default: return Icons.cut;
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDarkMode = theme.brightness == Brightness.dark;
    final screenWidth = MediaQuery.of(context).size.width;
    final crossAxisCount = (screenWidth / 200).floor().clamp(2, 4);

    return BlocConsumer<CashierCubit, CashierState>(
      // Listen for one-time events like success/error messages
      listener: (context, state) {
        if (state is CashierItemAdded) {
          // Show success toast
          toastification.show(
            context: context,
            type: ToastificationType.success,
            style: ToastificationStyle.fillColored,
            title: Text('تمت إضافة "${state.service.name}" للسلة'),
            alignment: Alignment.topRight,
            autoCloseDuration: const Duration(seconds: 3),
          );
        } else if (state is CashierItemRemoved) {
          // Show removal toast
          toastification.show(
            context: context,
            type: ToastificationType.error,
            style: ToastificationStyle.fillColored,
            title: Text('تم حذف "${state.service.name}" من السلة'),
            alignment: Alignment.topRight,
            autoCloseDuration: const Duration(seconds: 3),
          );
        } else if (state is CashierError) {
          // Show error message
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(state.message), backgroundColor: Colors.red),
          );
        }
      },
      // Build UI based on state
      builder: (context, state) {
        // Show loading indicator
        if (state is CashierLoading || state is CashierInitial) {
          return Scaffold(
            appBar: AppBar(title: Text("الكاشير")),
            body: const Center(child: CircularProgressIndicator()),
          );
        }

        // Show error screen
        if (state is CashierError) {
          return Scaffold(
            appBar: AppBar(title: Text("الكاشير")),
            body: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.error_outline, size: 64, color: Colors.red),
                  const SizedBox(height: 16),
                  Text(state.message),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () => context.read<CashierCubit>().initialize(),
                    child: const Text('إعادة المحاولة'),
                  ),
                ],
              ),
            ),
          );
        }

        // Get loaded state (contains all data)
        final loadedState = state is CashierLoaded ? state : null;
        if (loadedState == null) {
          return Scaffold(
            appBar: AppBar(title: Text("الكاشير")),
            body: const Center(child: Text('حدث خطأ')),
          );
        }

        // Build main UI with data from state
        return Scaffold(
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
          body: GestureDetector(
            onTap: () => FocusScope.of(context).unfocus(),
            child: Column(
              children: [
                // Pass selected customer from state
                HeaderSection(
                  onCustomerSelected: (customer) {
                    context.read<CashierCubit>().selectCustomer(customer);
                  },
                ),
                CategoriesSection(
                  selectedCategory: loadedState.selectedCategory,
                  onCategorySelected: (cat) {
                    // Call cubit method to change category
                    context.read<CashierCubit>().selectCategory(cat);
                  },
                ),
                const SizedBox(height: 10),
                const Divider(height: 1),
                Expanded(
                  child: SingleChildScrollView(
                    child: Column(
                      children: [
                        SizedBox(
                          height: MediaQuery.of(context).size.height * 0.4,
                          child: GridView.builder(
                            padding: const EdgeInsets.all(12),
                            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                              crossAxisCount: crossAxisCount,
                              childAspectRatio: 1.2,
                              crossAxisSpacing: 12,
                              mainAxisSpacing: 12,
                            ),
                            // Use filtered services from state
                            itemCount: loadedState.filteredServices.length,
                            itemBuilder: (context, index) {
                              final service = loadedState.filteredServices[index];
                              return InkWell(
                                onTap: () => _showBarberSelectionSheet(service),
                                borderRadius: BorderRadius.circular(16),
                                child: Card(
                                  elevation: 2,
                                  child: Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Icon(_getIconForCategory(service.category), size: 32, color: theme.colorScheme.secondary),
                                      const SizedBox(height: 12),
                                      Text(service.name, style: theme.textTheme.titleMedium, textAlign: TextAlign.center),
                                      const SizedBox(height: 4),
                                      Text("${service.price.toStringAsFixed(0)} ر.س", style: GoogleFonts.cairo(color: theme.colorScheme.secondary, fontWeight: FontWeight.bold)),
                                    ],
                                  ),
                                ),
                              );
                            },
                          ),
                        ),
                        // Show cart if not empty
                        if (loadedState.cart.isNotEmpty)
                          CartSection(
                            cart: loadedState.cart,
                            removeFromCart: (index) {
                              // Call cubit method to remove item
                              context.read<CashierCubit>().removeFromCart(index);
                            },
                            selectedCustomer: loadedState.selectedCustomer,
                            navigateToInvoice: () => _navigateToInvoice(context, loadedState),
                          ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  void _navigateToInvoice(BuildContext context, CashierLoaded state) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => InvoicePage(
          cart: List<ServiceModel>.from(state.cart),
          customer: state.selectedCustomer,
        ),
      ),
    );
  }
}
```

---

## 👤 STEP 5: UPDATE HEADER SECTION

In `header_section.dart`, update the add customer dialog to use Cubit:

Find the `ElevatedButton` in `_showAddCustomerDialog`:

```dart
// FIND THIS:
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

// REPLACE WITH:
BlocBuilder<CashierCubit, CashierState>(
  builder: (context, state) {
    final isAdding = state is CashierLoading;
    
    return ElevatedButton(
      onPressed: isAdding ? null : () async {
        if (formKey.currentState!.validate()) {
          // Call cubit method
          await context.read<CashierCubit>().addCustomer(
            name: nameController.text,
            phone: phoneController.text.isNotEmpty ? phoneController.text : null,
            customerId: idController.text.isNotEmpty ? idController.text : null,
          );
          Navigator.pop(context);
        }
      },
      child: isAdding
          ? const SizedBox(
              height: 20,
              width: 20,
              child: CircularProgressIndicator(strokeWidth: 2),
            )
          : const Text('إضافة'),
    );
  },
),
```

And update the widget to get customers from Cubit:

```dart
@override
Widget build(BuildContext context) {
  final theme = Theme.of(context);

  return BlocBuilder<CashierCubit, CashierState>(
    builder: (context, state) {
      if (state is! CashierLoaded) {
        return const SizedBox(); // or show loading
      }

      return Padding(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text("العميل", style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold)),
            const SizedBox(height: 4),
            Container(
              decoration: BoxDecoration(
                border: Border.all(color: theme.colorScheme.outline.withOpacity(0.7)),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  InkWell(
                    onTap: _showAddCustomerDialog,
                    child: Container(
                      height: 48,
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      decoration: BoxDecoration(
                        border: Border(right: BorderSide(color: theme.colorScheme.outline.withOpacity(0.7)))
                      ),
                      child: Icon(Icons.add, color: theme.colorScheme.primary),
                    ),
                  ),
                  Expanded(
                    child: Autocomplete<Customer>(
                      key: _autocompleteKey,
                      initialValue: TextEditingValue(
                        text: state.selectedCustomer?.name ?? '',
                      ),
                      optionsBuilder: (TextEditingValue textEditingValue) {
                        if (textEditingValue.text.isEmpty) {
                          return state.customers; // From cubit state
                        }
                        return state.customers.where((Customer option) {
                          return option.name.toLowerCase().contains(textEditingValue.text.toLowerCase()) ||
                              option.phone?.contains(textEditingValue.text) == true ||
                              option.customerId?.toLowerCase().contains(textEditingValue.text.toLowerCase()) == true;
                        });
                      },
                      displayStringForOption: (Customer option) => option.name,
                      onSelected: (Customer selection) {
                        widget.onCustomerSelected(selection);
                      },
                      fieldViewBuilder: (context, controller, focusNode, onSubmitted) {
                        return TextField(
                          controller: controller,
                          focusNode: focusNode,
                          decoration: const InputDecoration(
                            border: InputBorder.none,
                            hintText: 'ابحث عن عميل...',
                            contentPadding: EdgeInsets.symmetric(horizontal: 16),
                          ),
                        );
                      },
                    ),
                  ),
                ],
              ),
            )
          ],
        ),
      );
    },
  );
}
```

---

## 📊 SUMMARY OF CHANGES

### ✅ What You Created:
1. **2 Repositories** - Data layer (mock APIs)
2. **2 Cubits** - Business logic layer
3. **2 State classes** - State definitions

### 🔄 What You Need to Update:
1. **main.dart** - Add providers
2. **login_screen.dart** - Replace login method, add BlocConsumer
3. **casher_screen.dart** - Remove local state, use BlocConsumer
4. **header_section.dart** - Use cubit for customers

### 🎯 Key Concepts:

**BlocProvider**: Makes cubit available to widgets below
```dart
BlocProvider(
  create: (context) => CashierCubit(repository: repository),
  child: CashierScreen(),
)
```

**BlocBuilder**: Rebuilds when state changes
```dart
BlocBuilder<CashierCubit, CashierState>(
  builder: (context, state) {
    if (state is CashierLoaded) {
      return Text('${state.cart.length} items');
    }
    return CircularProgressIndicator();
  },
)
```

**BlocListener**: Executes code once when state changes (for toasts, navigation)
```dart
BlocListener<CashierCubit, CashierState>(
  listener: (context, state) {
    if (state is CashierItemAdded) {
      showToast('Item added!');
    }
  },
  child: YourWidget(),
)
```

**BlocConsumer**: Combines builder + listener
```dart
BlocConsumer<CashierCubit, CashierState>(
  listener: (context, state) { /* show toasts */ },
  builder: (context, state) { /* build UI */ },
)
```

**Calling Methods**:
```dart
context.read<CashierCubit>().addToCart(service, barber);
```

---

## 🐛 DEBUGGING TIPS

**Check current state:**
```dart
print(context.read<CashierCubit>().state);
```

**Enable Bloc logging:**
Add to main.dart:
```dart
import 'package:flutter_bloc/flutter_bloc.dart';

class MyBlocObserver extends BlocObserver {
  @override
  void onChange(BlocBase bloc, Change change) {
    super.onChange(bloc, change);
    print('${bloc.runtimeType} $change');
  }

  @override
  void onError(BlocBase bloc, Object error, StackTrace stackTrace) {
    print('${bloc.runtimeType} $error');
    super.onError(bloc, error, stackTrace);
  }
}

void main() {
  Bloc.observer = MyBlocObserver();
  runApp(const MyApp());
}
```

---

## 📚 NEXT STEPS

1. ✅ Copy the integration code for each file
2. ✅ Test login flow
3. ✅ Test adding services to cart
4. ✅ Test adding customers
5. ✅ Add more features as needed!

**Need help?** Check the comments in the cubit files - they have detailed examples!
