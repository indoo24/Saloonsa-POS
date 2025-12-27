import 'package:flutter_bloc/flutter_bloc.dart';
import '../../repositories/cashier_repository.dart';
import '../../repositories/auth_repository.dart';
import '../../screens/casher/models/service-model.dart';
import '../../screens/casher/models/customer.dart';
import '../../services/logger_service.dart';
import '../../models/category.dart';
import '../../models/payment_method.dart';
import '../../models/invoice.dart';
import 'cashier_state.dart';

/// Cashier Cubit - Manages all business logic for the cashier screen
/// Integrated with API for customers and invoices
///
/// HOW TO USE IN YOUR UI:
/// 1. Wrap your widget with BlocProvider (see main.dart)
/// 2. Call methods like: context.read<CashierCubit>().addToCart(...)
/// 3. Listen to state changes with BlocBuilder or BlocListener
class CashierCubit extends Cubit<CashierState> {
  final CashierRepository repository;
  final AuthRepository _authRepository = AuthRepository();

  CashierCubit({required this.repository}) : super(CashierInitial());

  /// Get current logged-in cashier ID
  Future<int?> _getCurrentCashierId() async {
    try {
      final user = await _authRepository.getCurrentUser();
      if (user != null) {
        LoggerService.info(
          'Current cashier/user ID',
          data: {'id': user.id, 'name': user.name},
        );
        return user.id;
      }
      LoggerService.warning('No current user found');
      return null;
    } catch (e) {
      LoggerService.error('Failed to get current cashier ID', error: e);
      return null;
    }
  }

  /// Initialize the cashier screen - loads all necessary data
  /// CALL THIS in initState or when screen opens
  Future<void> initialize() async {
    try {
      emit(CashierLoading());

      LoggerService.info('Initializing cashier cubit');

      // Load all data in parallel for better performance
      final results = await Future.wait([
        repository.fetchServices(),
        repository.fetchCustomers(),
        repository.fetchBarbers(),
        repository.loadCart(),
        repository.fetchCategories(),
        repository.fetchPaymentMethods(),
      ]);

      final services = results[0] as List<ServiceModel>;
      final customers = results[1] as List<Customer>;
      final barbers = results[2] as List<String>;
      final cart = results[3] as List<ServiceModel>;
      var categories = results[4] as List<Category>;
      final paymentMethods = (results[5] as List).cast<PaymentMethod>();

      // If no categories from API, extract unique categories from services
      if (categories.isEmpty) {
        LoggerService.info('No categories from API, extracting from services');
        final categoryNames = services
            .map((s) => s.category)
            .where((c) => c.isNotEmpty)
            .toSet()
            .toList();

        categories = categoryNames
            .asMap()
            .entries
            .map((e) => Category(id: e.key + 1, name: e.value))
            .toList();

        LoggerService.info(
          'Extracted categories from services',
          data: {'count': categories.length, 'categories': categoryNames},
        );
      }

      LoggerService.info(
        'Cashier data loaded',
        data: {
          'services': services.length,
          'customers': customers.length,
          'barbers': barbers.length,
          'cart': cart.length,
          'categories': categories.length,
          'paymentMethods': paymentMethods.length,
        },
      );

      emit(
        CashierLoaded(
          services: services,
          cart: cart,
          customers: customers,
          barbers: barbers,
          categories: categories,
          paymentMethods: paymentMethods,
          selectedCustomer: customers.isNotEmpty ? customers.first : null,
          selectedCategory: "الكل", // Default to "All" to show all services
        ),
      );
    } catch (e, stackTrace) {
      LoggerService.error(
        'Failed to initialize cashier',
        error: e,
        stackTrace: stackTrace,
      );
      emit(CashierError('فشل في تحميل البيانات: ${e.toString()}'));
    }
  }

  /// Add service to cart with selected barber
  ///
  /// HOW TO CALL FROM UI:
  /// ```dart
  /// onPressed: () {
  ///   context.read<CashierCubit>().addToCart(service, barberName);
  /// }
  /// ```
  Future<void> addToCart(ServiceModel service, String barberName) async {
    final currentState = state;
    if (currentState is! CashierLoaded) return;

    try {
      // Create service with barber assigned
      final serviceToAdd = ServiceModel(
        id: service.id,
        name: service.name,
        price: service.price,
        category: service.category,
        image: service.image,
        barber: barberName,
      );

      // Update cart
      final updatedCart = List<ServiceModel>.from(currentState.cart)
        ..add(serviceToAdd);

      // Save to repository (for persistence)
      await repository.saveCart(updatedCart);

      // Emit loaded state with updated cart
      emit(currentState.copyWith(cart: updatedCart));

      // Emit success state for showing toast
      emit(CashierItemAdded(serviceToAdd));

      // Return to loaded state
      emit(currentState.copyWith(cart: updatedCart));
    } catch (e) {
      emit(CashierError('فشل في إضافة الخدمة: ${e.toString()}'));
      // Return to previous state
      emit(currentState);
    }
  }

  /// Remove item from cart by index
  ///
  /// HOW TO CALL FROM UI:
  /// ```dart
  /// IconButton(
  ///   onPressed: () => context.read<CashierCubit>().removeFromCart(index),
  ///   icon: Icon(Icons.delete),
  /// )
  /// ```
  Future<void> removeFromCart(int index) async {
    final currentState = state;
    if (currentState is! CashierLoaded) return;

    try {
      if (index < 0 || index >= currentState.cart.length) return;

      final removedItem = currentState.cart[index];
      final updatedCart = List<ServiceModel>.from(currentState.cart)
        ..removeAt(index);

      await repository.saveCart(updatedCart);

      emit(currentState.copyWith(cart: updatedCart));

      // Emit removed state for showing toast
      emit(CashierItemRemoved(removedItem));

      // Return to loaded state
      emit(currentState.copyWith(cart: updatedCart));
    } catch (e) {
      emit(CashierError('فشل في حذف الخدمة: ${e.toString()}'));
      emit(currentState);
    }
  }

  /// Clear entire cart
  ///
  /// HOW TO CALL FROM UI:
  /// ```dart
  /// ElevatedButton(
  ///   onPressed: () => context.read<CashierCubit>().clearCart(),
  ///   child: Text('مسح السلة'),
  /// )
  /// ```
  Future<void> clearCart() async {
    final currentState = state;
    if (currentState is! CashierLoaded) return;

    try {
      await repository.saveCart([]);
      emit(currentState.copyWith(cart: []));
    } catch (e) {
      emit(CashierError('فشل في مسح السلة: ${e.toString()}'));
      emit(currentState);
    }
  }

  /// Change selected category to filter services
  ///
  /// HOW TO CALL FROM UI:
  /// ```dart
  /// GestureDetector(
  ///   onTap: () => context.read<CashierCubit>().selectCategory('قص الشعر'),
  ///   child: Text('قص الشعر'),
  /// )
  /// ```
  void selectCategory(String category) {
    final currentState = state;
    if (currentState is! CashierLoaded) return;

    emit(currentState.copyWith(selectedCategory: category));
  }

  /// Select a customer
  ///
  /// HOW TO CALL FROM UI:
  /// ```dart
  /// onSelected: (Customer customer) {
  ///   context.read<CashierCubit>().selectCustomer(customer);
  /// }
  /// ```
  void selectCustomer(Customer customer) {
    final currentState = state;
    if (currentState is! CashierLoaded) return;

    emit(currentState.copyWith(selectedCustomer: customer));
  }

  /// Add a new customer
  ///
  /// HOW TO CALL FROM UI:
  /// ```dart
  /// ElevatedButton(
  ///   onPressed: () async {
  ///     await context.read<CashierCubit>().addCustomer(
  ///       name: nameController.text,
  ///       phone: phoneController.text,
  ///       customerId: idController.text,
  ///     );
  ///   },
  ///   child: Text('إضافة'),
  /// )
  /// ```
  Future<void> addCustomer({
    required String name,
    String? phone,
    String? customerId,
  }) async {
    final currentState = state;
    if (currentState is! CashierLoaded) return;

    try {
      LoggerService.info(
        'Adding new customer from cubit',
        data: {'name': name, 'phone': phone},
      );

      // Add customer via repository (API call)
      final newCustomer = await repository.addCustomer(
        name: name,
        phone: phone,
        customerId: customerId,
      );

      // Update customers list
      final updatedCustomers = List<Customer>.from(currentState.customers)
        ..add(newCustomer);

      LoggerService.info(
        'Customer added successfully',
        data: {'customerId': newCustomer.id, 'name': newCustomer.name},
      );

      // Update state with new customer and select it
      emit(
        currentState.copyWith(
          customers: updatedCustomers,
          selectedCustomer: newCustomer,
        ),
      );

      // Emit success state
      emit(CashierCustomerAdded(newCustomer));

      // Return to loaded state
      emit(
        currentState.copyWith(
          customers: updatedCustomers,
          selectedCustomer: newCustomer,
        ),
      );
    } catch (e, stackTrace) {
      LoggerService.error(
        'Failed to add customer',
        error: e,
        stackTrace: stackTrace,
      );
      emit(CashierError('فشل في إضافة العميل: ${e.toString()}'));
      emit(currentState);
    }
  }

  /// Submit invoice (finalize transaction)
  ///
  /// HOW TO CALL FROM UI:
  /// ```dart
  /// ElevatedButton(
  ///   onPressed: () async {
  ///     final success = await context.read<CashierCubit>().submitInvoice(
  ///       paymentType: 'cash',
  ///       tax: 15.0,
  ///       discount: 5.0,
  ///     );
  ///     if (success) {
  ///       // Navigate away or show success message
  ///     }
  ///   },
  ///   child: Text('إتمام'),
  /// )
  /// ```
  Future<Invoice?> submitInvoice({
    String paymentType = 'cash',
    double tax = 0,
    double discount = 0,
    double? paid,
  }) async {
    final currentState = state;
    if (currentState is! CashierLoaded) return null;

    try {
      emit(CashierSubmittingInvoice());

      // Calculate paid amount (use total if not provided)
      final paidAmount = paid ?? currentState.cartTotal;

      LoggerService.invoiceAction(
        'Submitting invoice from cubit',
        data: {
          'cartItems': currentState.cart.length,
          'total': currentState.cartTotal,
          'customer': currentState.selectedCustomer?.name,
          'paymentType': paymentType,
          'tax': tax,
          'discount': discount,
          'paid': paidAmount,
        },
      );

      // Submit to backend API
      final invoice = await repository.submitInvoice(
        services: currentState.cart,
        customer: currentState.selectedCustomer,
        total: currentState.cartTotal,
        paymentType: paymentType,
        tax: tax,
        discount: discount,
        paid: paidAmount,
        cashierId: await _getCurrentCashierId(),
      );

      LoggerService.invoiceAction(
        'Invoice submitted successfully',
        data: {'invoiceId': invoice.id, 'invoiceNumber': invoice.invoiceNumber},
      );

      // Clear cart after successful submission
      await repository.saveCart([]);

      emit(CashierInvoiceSubmitted());

      // Reset to empty cart
      emit(currentState.copyWith(cart: []));

      return invoice;
    } catch (e, stackTrace) {
      LoggerService.error(
        'Failed to submit invoice',
        error: e,
        stackTrace: stackTrace,
      );
      emit(CashierError('فشل في إرسال الفاتورة: ${e.toString()}'));
      emit(currentState);
      return null;
    }
  }

  /// Get print data for an order from API
  Future<Map<String, dynamic>?> getPrintData(int orderId) async {
    try {
      LoggerService.info(
        'Getting print data for order',
        data: {'orderId': orderId},
      );
      final printData = await repository.getPrintData(orderId);
      
      // DEBUG: Log the entire API response to identify payment method field
      print('🔍 === RAW API RESPONSE FROM getPrintData ===');
      print(printData);
      print('🔍 === END RAW API RESPONSE ===');
      
      return printData;
    } catch (e, stackTrace) {
      LoggerService.error(
        'Failed to get print data',
        error: e,
        stackTrace: stackTrace,
      );
      return null;
    }
  }

  /// Refresh all data
  Future<void> refresh() async {
    await initialize();
  }
}
