import 'package:flutter_bloc/flutter_bloc.dart';
import '../../repositories/cashier_repository.dart';
import '../../screens/casher/models/service-model.dart';
import '../../screens/casher/models/customer.dart';
import 'cashier_state.dart';

/// Cashier Cubit - Manages all business logic for the cashier screen
/// 
/// HOW TO USE IN YOUR UI:
/// 1. Wrap your widget with BlocProvider (see main.dart)
/// 2. Call methods like: context.read<CashierCubit>().addToCart(...)
/// 3. Listen to state changes with BlocBuilder or BlocListener
class CashierCubit extends Cubit<CashierState> {
  final CashierRepository repository;

  CashierCubit({required this.repository}) : super(CashierInitial());

  /// Initialize the cashier screen - loads all necessary data
  /// CALL THIS in initState or when screen opens
  Future<void> initialize() async {
    try {
      emit(CashierLoading());

      // Load all data in parallel for better performance
      final results = await Future.wait([
        repository.fetchServices(),
        repository.fetchCustomers(),
        repository.fetchBarbers(),
        repository.loadCart(),
      ]);

      final services = results[0] as List<ServiceModel>;
      final customers = results[1] as List<Customer>;
      final barbers = results[2] as List<String>;
      final cart = results[3] as List<ServiceModel>;

      emit(CashierLoaded(
        services: services,
        cart: cart,
        customers: customers,
        barbers: barbers,
        selectedCustomer: customers.isNotEmpty ? customers.first : null,
      ));
    } catch (e) {
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
        name: service.name,
        price: service.price,
        category: service.category,
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
      // Add customer via repository
      final newCustomer = await repository.addCustomer(
        name: name,
        phone: phone,
        customerId: customerId,
      );

      // Update customers list
      final updatedCustomers = List<Customer>.from(currentState.customers)
        ..add(newCustomer);

      // Update state with new customer and select it
      emit(currentState.copyWith(
        customers: updatedCustomers,
        selectedCustomer: newCustomer,
      ));

      // Emit success state
      emit(CashierCustomerAdded(newCustomer));

      // Return to loaded state
      emit(currentState.copyWith(
        customers: updatedCustomers,
        selectedCustomer: newCustomer,
      ));
    } catch (e) {
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
  ///     final success = await context.read<CashierCubit>().submitInvoice();
  ///     if (success) {
  ///       // Navigate away or show success message
  ///     }
  ///   },
  ///   child: Text('إتمام'),
  /// )
  /// ```
  Future<bool> submitInvoice() async {
    final currentState = state;
    if (currentState is! CashierLoaded) return false;

    try {
      emit(CashierSubmittingInvoice());

      // Submit to backend
      await repository.submitInvoice(
        services: currentState.cart,
        customer: currentState.selectedCustomer,
        total: currentState.cartTotal,
      );

      // Clear cart after successful submission
      await repository.saveCart([]);

      emit(CashierInvoiceSubmitted());

      // Reset to empty cart
      emit(currentState.copyWith(cart: []));

      return true;
    } catch (e) {
      emit(CashierError('فشل في إرسال الفاتورة: ${e.toString()}'));
      emit(currentState);
      return false;
    }
  }

  /// Refresh all data
  Future<void> refresh() async {
    await initialize();
  }
}
