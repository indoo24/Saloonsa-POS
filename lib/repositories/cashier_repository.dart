import '../screens/casher/models/customer.dart';
import '../screens/casher/models/service-model.dart';
import '../screens/casher/data/service_data.dart';
import '../services/api_client.dart';
import '../services/logger_service.dart';
import '../models/customer_model.dart';
import '../models/payment_method.dart';
import '../models/invoice.dart';

/// Repository layer for managing cashier-related data
/// This acts as a single source of truth and separates business logic from UI
/// Services and employees are kept as mock data locally
/// Customers, payment methods, and invoices use real API
class CashierRepository {
  final ApiClient _apiClient = ApiClient();

  // ============ SERVICES (MOCK DATA - LOCAL) ============
  
  /// Fetch all available services (LOCAL MOCK DATA)
  Future<List<ServiceModel>> fetchServices() async {
    LoggerService.info('Fetching services (LOCAL MOCK DATA)');
    // Simulate network delay
    await Future.delayed(const Duration(milliseconds: 500));
    return allServices;
  }

  /// Get services filtered by category (LOCAL MOCK DATA)
  Future<List<ServiceModel>> fetchServicesByCategory(String category) async {
    LoggerService.info('Fetching services by category (LOCAL)', data: {'category': category});
    await Future.delayed(const Duration(milliseconds: 300));
    return allServices.where((s) => s.category == category).toList();
  }

  // ============ BARBERS/EMPLOYEES (MOCK DATA - LOCAL) ============
  
  /// Fetch available barbers (LOCAL MOCK DATA)
  Future<List<String>> fetchBarbers() async {
    LoggerService.info('Fetching barbers (LOCAL MOCK DATA)');
    await Future.delayed(const Duration(milliseconds: 200));
    return ['أسامة', 'يوسف', 'محمد', 'أحمد'];
  }

  // ============ CUSTOMERS (API INTEGRATION) ============
  
  /// Fetch all customers from API
  Future<List<Customer>> fetchCustomers() async {
    try {
      LoggerService.info('Fetching customers from API');

      final salonId = _apiClient.getSalonId();
      if (salonId == null) {
        LoggerService.warning('No salon ID found, returning empty customer list');
        return [];
      }

      final response = await _apiClient.get(
        '/customers',
        queryParams: {'salon_id': salonId.toString()},
      );

      if (!response['success']) {
        throw Exception(response['message'] ?? 'فشل في جلب العملاء');
      }

      final customersData = response['data'] as List;
      final customers = customersData
          .map((json) => CustomerModel.fromJson(json))
          .map((customerModel) => Customer(
                id: customerModel.id,
                name: customerModel.name,
                phone: customerModel.mobile,
                customerId: 'CUST${customerModel.id}',
              ))
          .toList();

      LoggerService.info('Customers fetched successfully', data: {'count': customers.length});
      return customers;
    } on ApiException catch (e) {
      LoggerService.error('Failed to fetch customers from API', error: e);
      throw Exception(e.message);
    } catch (e, stackTrace) {
      LoggerService.error('Failed to fetch customers', error: e, stackTrace: stackTrace);
      throw Exception('فشل في جلب العملاء: ${e.toString()}');
    }
  }

  /// Add a new customer via API
  Future<Customer> addCustomer({
    required String name,
    String? phone,
    String? customerId,
  }) async {
    try {
      LoggerService.info('Adding new customer', data: {
        'name': name,
        'phone': phone,
      });

      final response = await _apiClient.post(
        '/customers',
        body: {
          'name': name,
          if (phone != null && phone.isNotEmpty) 'mobile': phone,
        },
      );

      if (!response['success']) {
        throw Exception(response['message'] ?? 'فشل في إضافة العميل');
      }

      final customerModel = CustomerModel.fromJson(response['data']);
      final customer = Customer(
        id: customerModel.id,
        name: customerModel.name,
        phone: customerModel.mobile,
        customerId: 'CUST${customerModel.id}',
      );

      LoggerService.info('Customer added successfully', data: customer.toString());
      return customer;
    } on ApiException catch (e) {
      LoggerService.error('Failed to add customer via API', error: e);
      throw Exception(e.message);
    } on ValidationException catch (e) {
      LoggerService.error('Validation error adding customer', error: e);
      throw Exception(e.message);
    } catch (e, stackTrace) {
      LoggerService.error('Failed to add customer', error: e, stackTrace: stackTrace);
      throw Exception('فشل في إضافة العميل: ${e.toString()}');
    }
  }

  /// Search customers by name, phone, or ID
  /// This searches locally from fetched customers
  Future<List<Customer>> searchCustomers(String query) async {
    try {
      // Fetch all customers first
      final allCustomers = await fetchCustomers();
      
      if (query.isEmpty) return allCustomers;
      
      final searchQuery = query.toLowerCase();
      return allCustomers.where((customer) {
        return customer.name.toLowerCase().contains(searchQuery) ||
            customer.phone?.contains(query) == true ||
            customer.customerId?.toLowerCase().contains(searchQuery) == true;
      }).toList();
    } catch (e, stackTrace) {
      LoggerService.error('Failed to search customers', error: e, stackTrace: stackTrace);
      return [];
    }
  }

  // ============ PAYMENT METHODS (API INTEGRATION) ============
  
  /// Fetch available payment methods from API
  Future<List<PaymentMethod>> fetchPaymentMethods() async {
    try {
      LoggerService.info('Fetching payment methods from API');

      final response = await _apiClient.get('/payments/methods');

      if (!response['success']) {
        throw Exception(response['message'] ?? 'فشل في جلب طرق الدفع');
      }

      final methodsData = response['data'] as List;
      final methods = methodsData
          .map((json) => PaymentMethod.fromJson(json))
          .where((method) => method.enabled)
          .toList();

      LoggerService.info('Payment methods fetched', data: {'count': methods.length});
      return methods;
    } on ApiException catch (e) {
      LoggerService.error('Failed to fetch payment methods', error: e);
      throw Exception(e.message);
    } catch (e, stackTrace) {
      LoggerService.error('Failed to fetch payment methods', error: e, stackTrace: stackTrace);
      throw Exception('فشل في جلب طرق الدفع: ${e.toString()}');
    }
  }

  // ============ CART ============
  
  /// Save cart to local storage (mock implementation)
  /// In real app, this could save to SharedPreferences or local database
  Future<void> saveCart(List<ServiceModel> cart) async {
    await Future.delayed(const Duration(milliseconds: 100));
    LoggerService.cartAction('Cart saved', data: {'itemCount': cart.length});
  }

  /// Load cart from local storage (mock implementation)
  Future<List<ServiceModel>> loadCart() async {
    await Future.delayed(const Duration(milliseconds: 100));
    LoggerService.cartAction('Cart loaded');
    return [];
  }

  // ============ INVOICE (API INTEGRATION) ============
  
  /// Submit an invoice to API
  Future<Invoice> submitInvoice({
    required List<ServiceModel> services,
    required Customer? customer,
    required double total,
    required String paymentType,
    double discount = 0,
    double tax = 0,
  }) async {
    try {
      LoggerService.invoiceAction('Submitting invoice', data: {
        'customer': customer?.name,
        'serviceCount': services.length,
        'total': total,
        'paymentType': paymentType,
      });

      final salonId = _apiClient.getSalonId();
      if (salonId == null) {
        throw Exception('لم يتم العثور على معرف الصالون');
      }

      if (customer == null) {
        throw Exception('يجب اختيار عميل');
      }

      // Convert services to invoice items
      final items = services.map((service) {
        return {
          'service_id': 1, // You may need to map service names to IDs
          'quantity': 1,
          'price': service.price,
          'discount': 0,
          if (service.barber != null) 'employee_id': 1, // Map barber name to ID
        };
      }).toList();

      final requestBody = {
        'salon_id': salonId,
        'client_id': customer.id,
        'payment_type': paymentType,
        'items': items,
        'tax': tax,
        'discount': discount,
        'discount_type': 'fixed',
        'paid': total,
      };

      final response = await _apiClient.post('/invoices', body: requestBody);

      if (!response['success']) {
        throw Exception(response['message'] ?? 'فشل في إنشاء الفاتورة');
      }

      // Log the response data to understand the structure
      LoggerService.info('Invoice API Response', data: response['data']);

      final invoice = Invoice.fromJson(response['data']);

      LoggerService.invoiceAction('Invoice submitted successfully', data: {
        'invoiceId': invoice.id,
        'invoiceNumber': invoice.invoiceNumber,
      });

      return invoice;
    } on ApiException catch (e) {
      LoggerService.error('Failed to submit invoice via API', error: e);
      throw Exception(e.message);
    } on ValidationException catch (e) {
      LoggerService.error('Validation error submitting invoice', error: e);
      throw Exception(e.message);
    } catch (e, stackTrace) {
      LoggerService.error('Failed to submit invoice', error: e, stackTrace: stackTrace);
      throw Exception('فشل في إنشاء الفاتورة: ${e.toString()}');
    }
  }

  /// Get invoice details from API
  Future<Invoice> getInvoice(int invoiceId) async {
    try {
      LoggerService.invoiceAction('Fetching invoice details', data: {'invoiceId': invoiceId});

      final response = await _apiClient.get('/invoices/$invoiceId');

      if (!response['success']) {
        throw Exception(response['message'] ?? 'فشل في جلب الفاتورة');
      }

      final invoice = Invoice.fromJson(response['data']);

      LoggerService.invoiceAction('Invoice fetched', data: {'invoiceNumber': invoice.invoiceNumber});
      return invoice;
    } on ApiException catch (e) {
      LoggerService.error('Failed to fetch invoice', error: e);
      throw Exception(e.message);
    } catch (e, stackTrace) {
      LoggerService.error('Failed to fetch invoice', error: e, stackTrace: stackTrace);
      throw Exception('فشل في جلب الفاتورة: ${e.toString()}');
    }
  }

  /// Get all invoices with optional filters
  Future<List<Invoice>> fetchInvoices({
    int? clientId,
    String? fromDate,
    String? toDate,
  }) async {
    try {
      LoggerService.invoiceAction('Fetching invoices', data: {
        'clientId': clientId,
        'fromDate': fromDate,
        'toDate': toDate,
      });

      final salonId = _apiClient.getSalonId();
      
      final queryParams = <String, String>{};
      if (salonId != null) queryParams['salon_id'] = salonId.toString();
      if (clientId != null) queryParams['client_id'] = clientId.toString();
      if (fromDate != null) queryParams['from_date'] = fromDate;
      if (toDate != null) queryParams['to_date'] = toDate;

      final response = await _apiClient.get('/invoices', queryParams: queryParams);

      if (!response['success']) {
        throw Exception(response['message'] ?? 'فشل في جلب الفواتير');
      }

      final invoicesData = response['data'] as List;
      final invoices = invoicesData.map((json) => Invoice.fromJson(json)).toList();

      LoggerService.invoiceAction('Invoices fetched', data: {'count': invoices.length});
      return invoices;
    } on ApiException catch (e) {
      LoggerService.error('Failed to fetch invoices', error: e);
      throw Exception(e.message);
    } catch (e, stackTrace) {
      LoggerService.error('Failed to fetch invoices', error: e, stackTrace: stackTrace);
      throw Exception('فشل في جلب الفواتير: ${e.toString()}');
    }
  }

  /// Print invoice via API
  Future<Map<String, dynamic>> printInvoice(int invoiceId) async {
    try {
      LoggerService.invoiceAction('Printing invoice', data: {'invoiceId': invoiceId});

      final response = await _apiClient.post('/invoices/$invoiceId/print');

      if (!response['success']) {
        throw Exception(response['message'] ?? 'فشل في طباعة الفاتورة');
      }

      LoggerService.invoiceAction('Invoice ready for printing');
      return response['data'];
    } on ApiException catch (e) {
      LoggerService.error('Failed to print invoice', error: e);
      throw Exception(e.message);
    } catch (e, stackTrace) {
      LoggerService.error('Failed to print invoice', error: e, stackTrace: stackTrace);
      throw Exception('فشل في طباعة الفاتورة: ${e.toString()}');
    }
  }
}
