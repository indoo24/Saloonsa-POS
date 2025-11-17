import '../screens/casher/models/customer.dart';
import '../screens/casher/models/service-model.dart';
import '../screens/casher/data/service_data.dart';

/// Repository layer for managing cashier-related data
/// This acts as a single source of truth and separates business logic from UI
class CashierRepository {
  // ============ SERVICES ============
  
  /// Fetch all available services
  /// In a real app, this would be an API call
  Future<List<ServiceModel>> fetchServices() async {
    // Simulate network delay
    await Future.delayed(const Duration(milliseconds: 500));
    return allServices;
  }

  /// Get services filtered by category
  Future<List<ServiceModel>> fetchServicesByCategory(String category) async {
    await Future.delayed(const Duration(milliseconds: 300));
    return allServices.where((s) => s.category == category).toList();
  }

  // ============ CUSTOMERS ============
  
  // Mock customer database
  final List<Customer> _customers = [
    Customer(id: 1, name: 'عميل كاش'),
    Customer(id: 2, name: 'رواف', phone: '123456789'),
    Customer(id: 3, name: 'سام', customerId: 'CUST003'),
    Customer(id: 4, name: 'أحمد', phone: '987654321'),
    Customer(id: 5, name: 'نوال السيد'),
    Customer(id: 6, name: 'سما'),
  ];

  /// Fetch all customers
  Future<List<Customer>> fetchCustomers() async {
    await Future.delayed(const Duration(milliseconds: 300));
    return List.from(_customers);
  }

  /// Add a new customer
  Future<Customer> addCustomer({
    required String name,
    String? phone,
    String? customerId,
  }) async {
    await Future.delayed(const Duration(milliseconds: 500));
    
    final newCustomer = Customer(
      id: DateTime.now().millisecondsSinceEpoch,
      name: name,
      phone: phone,
      customerId: customerId,
    );
    
    _customers.add(newCustomer);
    return newCustomer;
  }

  /// Search customers by name, phone, or ID
  Future<List<Customer>> searchCustomers(String query) async {
    await Future.delayed(const Duration(milliseconds: 200));
    
    if (query.isEmpty) return List.from(_customers);
    
    return _customers.where((customer) {
      return customer.name.toLowerCase().contains(query.toLowerCase()) ||
          customer.phone?.contains(query) == true ||
          customer.customerId?.toLowerCase().contains(query.toLowerCase()) == true;
    }).toList();
  }

  // ============ BARBERS ============
  
  /// Fetch available barbers
  Future<List<String>> fetchBarbers() async {
    await Future.delayed(const Duration(milliseconds: 200));
    return ['أسامة', 'يوسف', 'محمد', 'أحمد'];
  }

  // ============ CART ============
  
  /// Save cart to local storage (mock implementation)
  /// In real app, this could save to SharedPreferences or local database
  Future<void> saveCart(List<ServiceModel> cart) async {
    await Future.delayed(const Duration(milliseconds: 100));
    // TODO: Implement actual persistence
    print('Cart saved: ${cart.length} items');
  }

  /// Load cart from local storage (mock implementation)
  Future<List<ServiceModel>> loadCart() async {
    await Future.delayed(const Duration(milliseconds: 100));
    // TODO: Implement actual loading from storage
    return [];
  }

  // ============ INVOICE ============
  
  /// Submit an invoice (mock implementation)
  /// In real app, this would send data to backend
  Future<bool> submitInvoice({
    required List<ServiceModel> services,
    required Customer? customer,
    required double total,
  }) async {
    await Future.delayed(const Duration(milliseconds: 800));
    
    // Simulate 95% success rate
    final success = DateTime.now().millisecond % 100 < 95;
    
    if (success) {
      print('Invoice submitted successfully');
      return true;
    } else {
      throw Exception('فشل في إرسال الفاتورة');
    }
  }
}
