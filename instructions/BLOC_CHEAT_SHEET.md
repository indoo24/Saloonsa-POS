# 🎯 BLOC QUICK REFERENCE CHEAT SHEET

## 📦 Import Statements

```dart
// Always import these when using Bloc
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';

// Import your cubits
import 'cubits/cashier/cashier_cubit.dart';
import 'cubits/cashier/cashier_state.dart';
import 'cubits/auth/auth_cubit.dart';
import 'cubits/auth/auth_state.dart';

// Import repositories
import 'repositories/cashier_repository.dart';
import 'repositories/auth_repository.dart';
```

---

## 🏗️ Setup Providers (in main.dart)

```dart
// Single Repository
RepositoryProvider(
  create: (context) => CashierRepository(),
  child: MyWidget(),
)

// Single Cubit
BlocProvider(
  create: (context) => CashierCubit(
    repository: context.read<CashierRepository>(),
  ),
  child: MyWidget(),
)

// Multiple Repositories
MultiRepositoryProvider(
  providers: [
    RepositoryProvider(create: (context) => AuthRepository()),
    RepositoryProvider(create: (context) => CashierRepository()),
  ],
  child: MyApp(),
)

// Multiple Cubits
MultiBlocProvider(
  providers: [
    BlocProvider(create: (context) => AuthCubit(...)),
    BlocProvider(create: (context) => CashierCubit(...)),
  ],
  child: MyApp(),
)
```

---

## 📞 Calling Cubit Methods

```dart
// ✅ READ - Call a method (doesn't listen to changes)
context.read<CashierCubit>().addToCart(service, barber);
context.read<CashierCubit>().removeFromCart(index);
context.read<CashierCubit>().selectCategory('قص الشعر');
context.read<AuthCubit>().login(username, password, subdomain);
context.read<AuthCubit>().logout();

// ❌ DON'T use read() inside build() - use BlocBuilder instead
Widget build(BuildContext context) {
  // ❌ BAD - will not rebuild when state changes
  final state = context.read<CashierCubit>().state;
  
  // ✅ GOOD - use BlocBuilder
  return BlocBuilder<CashierCubit, CashierState>(...);
}
```

---

## 👀 Listening to State Changes

### 1️⃣ BlocBuilder - Rebuild UI when state changes

```dart
// Use when you need to rebuild widgets based on state
BlocBuilder<CashierCubit, CashierState>(
  builder: (context, state) {
    // Check state type
    if (state is CashierLoading) {
      return CircularProgressIndicator();
    }
    
    if (state is CashierError) {
      return Text('Error: ${state.message}');
    }
    
    if (state is CashierLoaded) {
      return ListView.builder(
        itemCount: state.cart.length,
        itemBuilder: (context, index) {
          return ListTile(title: Text(state.cart[index].name));
        },
      );
    }
    
    return SizedBox(); // fallback
  },
)
```

### 2️⃣ BlocListener - Execute code once (toasts, navigation, dialogs)

```dart
// Use for side effects - does NOT rebuild UI
BlocListener<CashierCubit, CashierState>(
  listener: (context, state) {
    if (state is CashierItemAdded) {
      // Show toast
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Item added!')),
      );
    }
    
    if (state is CashierError) {
      // Show error dialog
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: Text('Error'),
          content: Text(state.message),
        ),
      );
    }
    
    if (state is AuthAuthenticated) {
      // Navigate to home
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => HomeScreen()),
      );
    }
  },
  child: YourWidget(),
)
```

### 3️⃣ BlocConsumer - Combines Builder + Listener

```dart
// Use when you need BOTH rebuilding and side effects
BlocConsumer<CashierCubit, CashierState>(
  // Listener: for one-time actions (toasts, navigation)
  listener: (context, state) {
    if (state is CashierItemAdded) {
      showToast('Added ${state.service.name}');
    }
  },
  // Builder: for rebuilding UI
  builder: (context, state) {
    if (state is CashierLoading) {
      return CircularProgressIndicator();
    }
    
    if (state is CashierLoaded) {
      return Text('Cart: ${state.cart.length} items');
    }
    
    return SizedBox();
  },
)
```

### 4️⃣ BlocSelector - Listen to specific part of state only

```dart
// Rebuilds only when cart.length changes, not other state changes
BlocSelector<CashierCubit, CashierState, int>(
  selector: (state) {
    if (state is CashierLoaded) {
      return state.cart.length;
    }
    return 0;
  },
  builder: (context, cartLength) {
    return Text('Cart: $cartLength items');
  },
)
```

---

## 🎨 Common UI Patterns

### Button with Loading State

```dart
BlocBuilder<AuthCubit, AuthState>(
  builder: (context, state) {
    final isLoading = state is AuthLoading;
    
    return ElevatedButton(
      onPressed: isLoading ? null : () {
        context.read<AuthCubit>().login(username, password, subdomain);
      },
      child: isLoading
          ? CircularProgressIndicator()
          : Text('تسجيل الدخول'),
    );
  },
)
```

### Form Submission

```dart
Future<void> _submitForm() async {
  if (_formKey.currentState!.validate()) {
    await context.read<CashierCubit>().addCustomer(
      name: _nameController.text,
      phone: _phoneController.text,
    );
  }
}
```

### Show/Hide Widget Based on State

```dart
BlocBuilder<CashierCubit, CashierState>(
  builder: (context, state) {
    // Only show cart when it has items
    if (state is CashierLoaded && state.cart.isNotEmpty) {
      return CartWidget(cart: state.cart);
    }
    return SizedBox.shrink(); // Hide
  },
)
```

### Refresh Data

```dart
RefreshIndicator(
  onRefresh: () async {
    await context.read<CashierCubit>().refresh();
  },
  child: ListView(...),
)
```

---

## 🔍 Checking State Type

```dart
// In listener or builder
if (state is CashierLoading) { /* loading */ }
if (state is CashierLoaded) { /* success */ }
if (state is CashierError) { /* error */ }

// Check and cast
if (state is CashierLoaded) {
  final cart = state.cart;
  final total = state.cartTotal;
  final customer = state.selectedCustomer;
}

// Null-safe check
final loadedState = state is CashierLoaded ? state : null;
if (loadedState != null) {
  // Use loadedState.cart, etc.
}
```

---

## 🎯 Available Methods

### CashierCubit Methods

```dart
context.read<CashierCubit>().initialize();                    // Load initial data
context.read<CashierCubit>().addToCart(service, barberName); // Add service
context.read<CashierCubit>().removeFromCart(index);          // Remove service
context.read<CashierCubit>().clearCart();                     // Clear all
context.read<CashierCubit>().selectCategory(category);        // Change category
context.read<CashierCubit>().selectCustomer(customer);        // Select customer
context.read<CashierCubit>().addCustomer(                     // Add new customer
  name: 'أحمد',
  phone: '123456789',
);
context.read<CashierCubit>().submitInvoice();                 // Submit invoice
context.read<CashierCubit>().refresh();                       // Reload data
```

### AuthCubit Methods

```dart
context.read<AuthCubit>().checkAuthStatus();  // Check if logged in
context.read<AuthCubit>().login(              // Login
  username: 'user',
  password: 'pass',
  subdomain: 'shop',
);
context.read<AuthCubit>().logout();           // Logout
```

---

## 🗂️ State Types

### CashierState Types

- `CashierInitial` - Just created
- `CashierLoading` - Loading data
- `CashierLoaded` - Data loaded successfully (main state)
  - Properties: `services`, `cart`, `customers`, `barbers`, `selectedCustomer`, `selectedCategory`
  - Helpers: `filteredServices`, `cartTotal`
- `CashierError` - Error occurred (message)
- `CashierAddingToCart` - Adding item
- `CashierItemAdded` - Item added (for toast)
- `CashierItemRemoved` - Item removed (for toast)
- `CashierCustomerAdded` - Customer added (for toast)
- `CashierSubmittingInvoice` - Submitting
- `CashierInvoiceSubmitted` - Invoice submitted

### AuthState Types

- `AuthInitial` - Just created
- `AuthChecking` - Checking if logged in
- `AuthLoading` - Logging in
- `AuthAuthenticated` - Logged in successfully
  - Properties: `token`, `userId`, `username`, `subdomain`
- `AuthUnauthenticated` - Not logged in
- `AuthError` - Login error (message)
- `AuthLoggingOut` - Logging out

---

## 🐛 Debugging

### Print Current State

```dart
print(context.read<CashierCubit>().state);
```

### Enable Bloc Logging

```dart
// In main.dart
import 'package:flutter_bloc/flutter_bloc.dart';

class MyBlocObserver extends BlocObserver {
  @override
  void onChange(BlocBase bloc, Change change) {
    super.onChange(bloc, change);
    print('${bloc.runtimeType} $change');
  }

  @override
  void onError(BlocBase bloc, Object error, StackTrace stackTrace) {
    print('${bloc.runtimeType} $error $stackTrace');
    super.onError(bloc, error, stackTrace);
  }
}

void main() {
  Bloc.observer = MyBlocObserver();
  runApp(const MyApp());
}
```

---

## ⚠️ Common Mistakes

### ❌ Don't do this:
```dart
// Don't use read() in build method
Widget build(BuildContext context) {
  final state = context.read<CashierCubit>().state; // ❌ Won't rebuild
  return Text('Items: ${state.cart.length}');
}

// Don't call methods in build
Widget build(BuildContext context) {
  context.read<CashierCubit>().initialize(); // ❌ Called every build
  return Text('Hello');
}
```

### ✅ Do this instead:
```dart
// Use BlocBuilder in build
Widget build(BuildContext context) {
  return BlocBuilder<CashierCubit, CashierState>(
    builder: (context, state) { // ✅ Rebuilds on state change
      if (state is CashierLoaded) {
        return Text('Items: ${state.cart.length}');
      }
      return SizedBox();
    },
  );
}

// Call methods in initState or callbacks
@override
void initState() {
  super.initState();
  context.read<CashierCubit>().initialize(); // ✅ Called once
}

ElevatedButton(
  onPressed: () {
    context.read<CashierCubit>().addToCart(...); // ✅ Called on tap
  },
  child: Text('Add'),
)
```

---

## 📝 Quick Examples

### Example 1: Show cart count in AppBar

```dart
AppBar(
  title: BlocBuilder<CashierCubit, CashierState>(
    builder: (context, state) {
      if (state is CashierLoaded) {
        return Text('Cart (${state.cart.length})');
      }
      return Text('Cart');
    },
  ),
)
```

### Example 2: Disable button when loading

```dart
BlocBuilder<CashierCubit, CashierState>(
  builder: (context, state) {
    final isLoading = state is CashierLoading;
    
    return ElevatedButton(
      onPressed: isLoading ? null : () {
        context.read<CashierCubit>().submitInvoice();
      },
      child: Text('Submit'),
    );
  },
)
```

### Example 3: Show different screens based on auth

```dart
BlocBuilder<AuthCubit, AuthState>(
  builder: (context, state) {
    if (state is AuthAuthenticated) {
      return HomeScreen();
    }
    return LoginScreen();
  },
)
```

### Example 4: Navigate on success

```dart
BlocListener<AuthCubit, AuthState>(
  listener: (context, state) {
    if (state is AuthAuthenticated) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => HomeScreen()),
      );
    }
    if (state is AuthError) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(state.message)),
      );
    }
  },
  child: LoginForm(),
)
```

---

## 🎓 Remember

1. **Use `read()`** to call methods
2. **Use `BlocBuilder`** to rebuild UI
3. **Use `BlocListener`** for side effects (toasts, navigation)
4. **Use `BlocConsumer`** when you need both
5. **Never** call methods in build() - use initState or callbacks
6. **Never** use read() to get state in build() - use BlocBuilder
7. States are **immutable** - always create new state with copyWith()

---

Good luck! 🚀
