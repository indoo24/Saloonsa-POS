import 'package:equatable/equatable.dart';
import '../../screens/casher/models/service-model.dart';
import '../../screens/casher/models/customer.dart';
import '../../models/category.dart';
import '../../models/payment_method.dart';

/// Base state for Cashier screen
/// Uses Equatable for easy state comparison in BlocBuilder
abstract class CashierState extends Equatable {
  const CashierState();

  @override
  List<Object?> get props => [];
}

/// Initial state when screen loads
class CashierInitial extends CashierState {}

/// State when loading data (services, customers, etc.)
class CashierLoading extends CashierState {}

/// State when all data is loaded and ready
class CashierLoaded extends CashierState {
  final List<ServiceModel> services;
  final List<ServiceModel> cart;
  final List<Customer> customers;
  final List<String> barbers;
  final List<Category> categories;
  final List<PaymentMethod> paymentMethods;
  final Customer? selectedCustomer;
  final String selectedCategory;

  const CashierLoaded({
    required this.services,
    required this.cart,
    required this.customers,
    required this.barbers,
    required this.categories,
    required this.paymentMethods,
    this.selectedCustomer,
    this.selectedCategory = "الكل",
  });

  /// Helper to get filtered services by category
  List<ServiceModel> get filteredServices {
    if (selectedCategory == "الكل") {
      return services;
    }
    return services.where((s) => s.category == selectedCategory).toList();
  }

  /// Helper to calculate cart total
  double get cartTotal {
    return cart.fold<double>(0, (sum, item) => sum + item.price);
  }

  /// Create a copy of this state with updated fields
  /// This is crucial for Bloc pattern - states are immutable
  CashierLoaded copyWith({
    List<ServiceModel>? services,
    List<ServiceModel>? cart,
    List<Customer>? customers,
    List<String>? barbers,
    List<Category>? categories,
    List<PaymentMethod>? paymentMethods,
    Customer? selectedCustomer,
    String? selectedCategory,
    bool clearCustomer = false,
  }) {
    return CashierLoaded(
      services: services ?? this.services,
      cart: cart ?? this.cart,
      customers: customers ?? this.customers,
      barbers: barbers ?? this.barbers,
      categories: categories ?? this.categories,
      paymentMethods: paymentMethods ?? this.paymentMethods,
      selectedCustomer: clearCustomer
          ? null
          : (selectedCustomer ?? this.selectedCustomer),
      selectedCategory: selectedCategory ?? this.selectedCategory,
    );
  }

  @override
  List<Object?> get props => [
    services,
    cart,
    customers,
    barbers,
    categories,
    paymentMethods,
    selectedCustomer,
    selectedCategory,
  ];
}

/// State when an error occurs
class CashierError extends CashierState {
  final String message;

  const CashierError(this.message);

  @override
  List<Object?> get props => [message];
}

/// State when adding item to cart
class CashierAddingToCart extends CashierState {
  final ServiceModel service;

  const CashierAddingToCart(this.service);

  @override
  List<Object?> get props => [service];
}

/// State when item added successfully (for showing toast)
class CashierItemAdded extends CashierState {
  final ServiceModel service;
  final DateTime timestamp; // To ensure state change even for same item

  CashierItemAdded(this.service) : timestamp = DateTime.now();

  @override
  List<Object?> get props => [service, timestamp];
}

/// State when item removed from cart (for showing toast)
class CashierItemRemoved extends CashierState {
  final ServiceModel service;
  final DateTime timestamp;

  CashierItemRemoved(this.service) : timestamp = DateTime.now();

  @override
  List<Object?> get props => [service, timestamp];
}

/// State when customer is added
class CashierCustomerAdded extends CashierState {
  final Customer customer;
  final DateTime timestamp;

  CashierCustomerAdded(this.customer) : timestamp = DateTime.now();

  @override
  List<Object?> get props => [customer, timestamp];
}

/// State when submitting invoice
class CashierSubmittingInvoice extends CashierState {}

/// State when invoice submitted successfully
class CashierInvoiceSubmitted extends CashierState {
  final DateTime timestamp;

  CashierInvoiceSubmitted() : timestamp = DateTime.now();

  @override
  List<Object?> get props => [timestamp];
}
