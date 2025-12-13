import '../screens/casher/models/customer.dart';
import '../screens/casher/models/service-model.dart';
import '../services/api_client.dart';
import '../services/logger_service.dart';
import '../models/customer_model.dart';
import '../models/payment_method.dart';
import '../models/invoice.dart';
import '../models/service.dart';
import '../models/employee.dart';
import '../models/category.dart';

/// Repository layer for managing cashier-related data
/// This acts as a single source of truth and separates business logic from UI
/// All data now comes from API endpoints
class CashierRepository {
  final ApiClient _apiClient = ApiClient();

  // ============ CATEGORIES (API INTEGRATION) ============

  /// Fetch all main categories from API
  Future<List<Category>> fetchCategories() async {
    try {
      LoggerService.info('Fetching categories from API');

      final response = await _apiClient.get('/service-categories');

      if (!response['success']) {
        throw Exception(response['message'] ?? 'فشل في جلب التصنيفات');
      }

      // Handle different response formats
      final responseData = response['data'];

      LoggerService.info(
        'Categories response data type',
        data: {
          'type': responseData.runtimeType.toString(),
          'isList': responseData is List,
          'isMap': responseData is Map,
        },
      );

      final List<dynamic> categoriesData;

      if (responseData is List) {
        // Direct list response
        categoriesData = responseData;
      } else if (responseData is Map && responseData.containsKey('data')) {
        // Paginated response
        categoriesData = responseData['data'] as List;
      } else {
        throw Exception('تنسيق استجابة غير متوقع للتصنيفات');
      }

      final categories = categoriesData
          .map((json) => Category.fromJson(json as Map<String, dynamic>))
          .toList();

      LoggerService.info(
        'Categories fetched successfully',
        data: {'count': categories.length},
      );
      return categories;
    } on ApiException catch (e) {
      LoggerService.error('Failed to fetch categories from API', error: e);
      // Return empty list instead of throwing to prevent app crash
      LoggerService.info('Returning empty categories list');
      return [];
    } catch (e, stackTrace) {
      LoggerService.error(
        'Failed to fetch categories',
        error: e,
        stackTrace: stackTrace,
      );
      // Return empty list instead of throwing to prevent app crash
      LoggerService.info('Returning empty categories list');
      return [];
    }
  }

  // ============ PAYMENT METHODS (API INTEGRATION) ============

  /// Fetch all payment methods from API
  Future<List<PaymentMethod>> fetchPaymentMethods() async {
    try {
      LoggerService.info('Fetching payment methods from API');

      final response = await _apiClient.get('/payments/methods');

      if (!response['success']) {
        throw Exception(response['message'] ?? 'فشل في جلب طرق الدفع');
      }

      // Handle different response formats
      final responseData = response['data'];

      LoggerService.info(
        'Payment methods response data type',
        data: {
          'type': responseData.runtimeType.toString(),
          'isList': responseData is List,
          'isMap': responseData is Map,
        },
      );

      final List<dynamic> paymentMethodsData;

      if (responseData is List) {
        // Direct list response
        paymentMethodsData = responseData;
      } else if (responseData is Map && responseData.containsKey('data')) {
        // Paginated response
        paymentMethodsData = responseData['data'] as List;
      } else {
        throw Exception('تنسيق استجابة غير متوقع لطرق الدفع');
      }

      // Filter only enabled payment methods
      final paymentMethods = paymentMethodsData
          .map((json) => PaymentMethod.fromJson(json as Map<String, dynamic>))
          .where((method) => method.enabled)
          .toList();

      LoggerService.info(
        'Payment methods fetched successfully',
        data: {
          'count': paymentMethods.length,
          'methods': paymentMethods
              .map((m) => '${m.nameAr} (${m.type})')
              .toList(),
        },
      );
      return paymentMethods;
    } on ApiException catch (e) {
      LoggerService.error('Failed to fetch payment methods from API', error: e);
      // Return default payment methods on error
      LoggerService.info('Returning default payment methods');
      return _getDefaultPaymentMethods();
    } catch (e, stackTrace) {
      LoggerService.error(
        'Failed to fetch payment methods',
        error: e,
        stackTrace: stackTrace,
      );
      // Return default payment methods on error
      LoggerService.info('Returning default payment methods');
      return _getDefaultPaymentMethods();
    }
  }

  /// Get default payment methods as fallback
  List<PaymentMethod> _getDefaultPaymentMethods() {
    return [
      PaymentMethod(
        id: 1,
        name: 'cash',
        nameAr: 'نقدي',
        type: 'cash',
        enabled: true,
      ),
      PaymentMethod(
        id: 2,
        name: 'card',
        nameAr: 'شبكة',
        type: 'card',
        enabled: true,
      ),
      PaymentMethod(
        id: 3,
        name: 'transfer',
        nameAr: 'تحويل',
        type: 'bank_transfer',
        enabled: true,
      ),
    ];
  }

  // ============ SERVICES (API INTEGRATION) ============

  /// Fetch all available services from API
  Future<List<ServiceModel>> fetchServices() async {
    try {
      LoggerService.info('Fetching services from API');

      final response = await _apiClient.get(
        '/products',
        queryParams: {'is_service': '1'},
      );

      if (!response['success']) {
        throw Exception(response['message'] ?? 'فشل في جلب الخدمات');
      }

      // Log the full response to see all available fields
      LoggerService.info('Full services API response', data: response);

      // Handle paginated response
      final responseData = response['data'];
      final servicesData =
          responseData is Map && responseData.containsKey('data')
          ? responseData['data'] as List
          : responseData as List;

      LoggerService.info(
        'Raw services data sample',
        data: {
          'count': servicesData.length,
          'first_service_keys': servicesData.isNotEmpty
              ? (servicesData.first as Map<String, dynamic>).keys.toList()
              : [],
          'first_service': servicesData.isNotEmpty ? servicesData.first : null,
        },
      );

      final services = servicesData.map((json) => Service.fromJson(json)).map((
        service,
      ) {
        final jsonData =
            servicesData[servicesData.indexWhere((s) => s['id'] == service.id)];
        LoggerService.info(
          'Parsing service',
          data: {
            'id': service.id,
            'name': service.name,
            'price': service.price,
            'price_found': service.price != null,
            'image': service.image,
            'image_found': service.image != null && service.image!.isNotEmpty,
            'category': service.categoryName,
            'available_fields': (jsonData as Map<String, dynamic>).keys
                .toList(),
          },
        );

        return ServiceModel(
          id: service.id,
          name: service.name,
          price: service.price ?? 50.0, // Use price from API or default
          category: service.categoryName ?? 'عام',
          image: service.image ?? '', // Empty string to show icon instead
        );
      }).toList();

      LoggerService.info(
        'Services fetched successfully',
        data: {'count': services.length},
      );
      return services;
    } on ApiException catch (e) {
      LoggerService.error('Failed to fetch services from API', error: e);
      throw Exception(e.message);
    } catch (e) {
      LoggerService.error('Unexpected error fetching services', error: e);
      throw Exception('حدث خطأ غير متوقع أثناء جلب الخدمات');
    }
  }

  /// Get services filtered by category from API
  Future<List<ServiceModel>> fetchServicesByCategory(String category) async {
    LoggerService.info(
      'Fetching services by category from API',
      data: {'category': category},
    );

    // Fetch all services and filter locally
    final allServices = await fetchServices();
    return allServices.where((s) => s.category == category).toList();
  }

  // ============ EMPLOYEES (API INTEGRATION) ============

  /// Fetch available employees from API
  Future<List<String>> fetchBarbers() async {
    try {
      LoggerService.info('Fetching employees from API');

      final response = await _apiClient.get('/employees');

      if (!response['success']) {
        throw Exception(response['message'] ?? 'فشل في جلب الموظفين');
      }

      // Handle paginated response
      final responseData = response['data'];
      final employeesData =
          responseData is Map && responseData.containsKey('data')
          ? responseData['data'] as List
          : responseData as List;
      final employees = employeesData
          .map((json) => Employee.fromJson(json))
          .where((employee) => employee.isActive) // Only active employees
          .map((employee) => employee.name)
          .toList();

      LoggerService.info(
        'Employees fetched successfully',
        data: {'count': employees.length},
      );
      return employees;
    } on ApiException catch (e) {
      LoggerService.error('Failed to fetch employees from API', error: e);

      // If it's a parsing error (truncated response), provide helpful message
      if (e.message.contains('معالجة الاستجابة') ||
          e.message.contains('FormatException')) {
        LoggerService.warning(
          'API response truncated/invalid - check server logs',
        );
        throw Exception(
          'الاستجابة من الخادم غير مكتملة. تحقق من اتصال الشبكة أو اتصل بالدعم الفني',
        );
      }

      throw Exception(e.message);
    } catch (e) {
      LoggerService.error('Unexpected error fetching employees', error: e);
      throw Exception('حدث خطأ غير متوقع أثناء جلب الموظفين');
    }
  }

  /// Fetch full employee objects from API (for advanced features)

  /// Fetch full employee objects from API (for advanced features)
  Future<List<Employee>> fetchEmployees() async {
    try {
      LoggerService.info('Fetching full employee list from API');

      final response = await _apiClient.get('/employees');

      if (!response['success']) {
        throw Exception(response['message'] ?? 'فشل في جلب الموظفين');
      }

      // Handle paginated response
      final responseData = response['data'];
      final employeesData =
          responseData is Map && responseData.containsKey('data')
          ? responseData['data'] as List
          : responseData as List;
      final employees = employeesData
          .map((json) => Employee.fromJson(json))
          .where((employee) => employee.isActive)
          .toList();

      LoggerService.info(
        'Full employee list fetched',
        data: {'count': employees.length},
      );
      return employees;
    } on ApiException catch (e) {
      LoggerService.error('Failed to fetch employees from API', error: e);
      throw Exception(e.message);
    } catch (e) {
      LoggerService.error('Unexpected error fetching employees', error: e);
      throw Exception('حدث خطأ غير متوقع أثناء جلب الموظفين');
    }
  }

  // ============ CUSTOMERS (API INTEGRATION) ============

  /// Fetch all customers from API
  Future<List<Customer>> fetchCustomers() async {
    try {
      LoggerService.info('Fetching customers from API');

      final response = await _apiClient.get(
        '/persons',
        queryParams: {'type': 'client'},
      );

      if (!response['success']) {
        throw Exception(response['message'] ?? 'فشل في جلب العملاء');
      }

      // Handle different response formats
      final responseData = response['data'];

      LoggerService.info(
        'Customers response data type',
        data: {
          'type': responseData.runtimeType.toString(),
          'isList': responseData is List,
          'isMap': responseData is Map,
        },
      );

      final List<dynamic> customersData;

      if (responseData is List) {
        // Direct list response
        customersData = responseData;
      } else if (responseData is Map && responseData.containsKey('data')) {
        // Paginated response
        customersData = responseData['data'] as List;
      } else {
        throw Exception('تنسيق استجابة غير متوقع للعملاء');
      }

      final customers = customersData
          .map((json) => CustomerModel.fromJson(json as Map<String, dynamic>))
          .map(
            (customerModel) => Customer(
              id: customerModel.id,
              name: customerModel.name,
              phone: customerModel.mobile,
              customerId: 'CUST${customerModel.id}',
            ),
          )
          .toList();

      LoggerService.info(
        'Customers fetched successfully',
        data: {'count': customers.length},
      );
      return customers;
    } on ApiException catch (e) {
      LoggerService.error('Failed to fetch customers from API', error: e);
      throw Exception(e.message);
    } catch (e, stackTrace) {
      LoggerService.error(
        'Failed to fetch customers',
        error: e,
        stackTrace: stackTrace,
      );
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
      LoggerService.info(
        'Adding new customer',
        data: {'name': name, 'phone': phone},
      );

      final response = await _apiClient.post(
        '/persons',
        body: {
          'name': name,
          'type': 'client',
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

      LoggerService.info(
        'Customer added successfully',
        data: customer.toString(),
      );
      return customer;
    } on ApiException catch (e) {
      LoggerService.error('Failed to add customer via API', error: e);
      throw Exception(e.message);
    } on ValidationException catch (e) {
      LoggerService.error('Validation error adding customer', error: e);
      throw Exception(e.message);
    } catch (e, stackTrace) {
      LoggerService.error(
        'Failed to add customer',
        error: e,
        stackTrace: stackTrace,
      );
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
      LoggerService.error(
        'Failed to search customers',
        error: e,
        stackTrace: stackTrace,
      );
      return [];
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

  // ============ HELPER METHODS ============

  /// Get employee ID by name
  Future<int?> getEmployeeIdByName(String employeeName) async {
    try {
      final employees = await fetchEmployees();
      final employee = employees.firstWhere(
        (e) => e.name == employeeName,
        orElse: () => throw Exception('Employee not found'),
      );
      return employee.id;
    } catch (e) {
      LoggerService.warning(
        'Could not find employee ID for name: $employeeName',
        data: {'error': e.toString()},
      );
      return null;
    }
  }

  /// Submit an invoice to API
  /// The API will calculate tax, discount, and totals based on the items and configuration
  Future<Invoice> submitInvoice({
    required List<ServiceModel> services,
    required Customer? customer,
    required double
    total, // For backward compatibility, but API will recalculate
    required String paymentType,
    double discount = 0, // Discount percentage or fixed amount
    double tax =
        0, // Tax percentage or fixed amount (API will use its own rate)
    double? paid,
    int? cashierId,
  }) async {
    try {
      LoggerService.invoiceAction(
        'Submitting invoice',
        data: {
          'customer': customer?.name,
          'serviceCount': services.length,
          'total': total,
          'paymentType': paymentType,
        },
      );

      if (customer == null) {
        throw Exception('يجب اختيار عميل');
      }

      if (services.isEmpty) {
        throw Exception('يجب إضافة خدمة واحدة على الأقل');
      }

      // Convert services to order items (new API structure)
      // Get employees for ID mapping
      final employees = await fetchEmployees();
      final employeeMap = {for (var e in employees) e.name: e.id};

      final items = await Future.wait(
        services.map((service) async {
          final item = {
            'product_id': service.id,
            'qty': 1,
            'price': service.price, // Send individual service price
          };

          // Add employee_id if barber is assigned
          if (service.barber != null && service.barber!.isNotEmpty) {
            final employeeId = employeeMap[service.barber];
            if (employeeId != null) {
              item['employee_id'] = employeeId;
              LoggerService.info(
                'Mapped employee to service',
                data: {
                  'employeeName': service.barber,
                  'employeeId': employeeId,
                  'serviceName': service.name,
                },
              );
            } else {
              LoggerService.warning(
                'Could not find employee ID',
                data: {'employeeName': service.barber},
              );
            }
          }

          return item;
        }),
      );

      // Calculate subtotal from services (sum of prices)
      final subtotal = services.fold<double>(
        0,
        (sum, item) => sum + item.price,
      );

      final requestBody = <String, dynamic>{
        'client_id': customer.id, // Backend expects client_id
        'payment_type': paymentType, // Backend expects payment_type
        'items': items,
        'paid': paid ?? total, // Use provided paid amount or fallback to total
      };

      // CRITICAL: Discount handling per business rules
      // App UI collects discount as PERCENTAGE (e.g., 50 for 50%)
      // Backend MUST treat this as percentage, not fixed amount
      // If backend expects explicit type, add: 
      //'discount_type': 'percentage'
      if (discount > 0) {
        requestBody['discount'] =
            discount; // Sent as percentage value (e.g., 50 for 50%)
        // Uncomment if backend requires explicit type:
        requestBody['discount_type'] = 'percentage';
      }

      // Send tax if provided
      if (tax > 0) {
        requestBody['tax_value'] = tax;
      }

      // Add sale_id (cashier) - prioritize provided cashier ID
      if (cashierId != null) {
        requestBody['sale_id'] = cashierId;
      } else if (items.isNotEmpty && items.first['employee_id'] != null) {
        requestBody['sale_id'] = items.first['employee_id'];
      }

      LoggerService.info(
        'Invoice request body (matching backend structure)',
        data: {
          'client_id': customer.id,
          'sale_id': requestBody['sale_id'],
          'payment_type': paymentType,
          'discount': discount,
          'tax_value': tax,
          'paid': paid ?? total,
          'items_count': items.length,
          'subtotal': subtotal,
        },
      );

      final response = await _apiClient.post('/orders', body: requestBody);

      if (!response['success']) {
        throw Exception(response['message'] ?? 'فشل في إنشاء الفاتورة');
      }

      // Log the response data to understand the structure
      LoggerService.info('Invoice API Response', data: response['data']);

      final invoice = Invoice.fromJson(response['data']);

      LoggerService.invoiceAction(
        'Invoice submitted successfully (API calculated)',
        data: {
          'invoiceId': invoice.id,
          'invoiceNumber': invoice.invoiceNumber,
          'subtotalBeforeTax': invoice.subtotalBeforeTax ?? invoice.subtotal,
          'taxAmount': invoice.taxAmount,
          'totalAfterTax': invoice.totalAfterTax,
          'discountAmount': invoice.discountAmount,
          'finalTotal': invoice.finalTotal ?? invoice.total,
          'paidAmount': invoice.paidAmount,
          'remainingAmount': invoice.remainingAmount,
        },
      );

      return invoice;
    } on ApiException catch (e) {
      LoggerService.error('Failed to submit invoice via API', error: e);
      throw Exception(e.message);
    } on ValidationException catch (e) {
      LoggerService.error('Validation error submitting invoice', error: e);
      LoggerService.info(
        'Validation errors details',
        data: {'message': e.message, 'errors': e.errors},
      );
      // Show which fields are missing
      if (e.errors != null) {
        final errorDetails = e.errors!.entries
            .map((entry) => '${entry.key}: ${entry.value}')
            .join(', ');
        throw Exception('خطأ في التحقق: $errorDetails');
      }
      throw Exception(e.message);
    } catch (e, stackTrace) {
      LoggerService.error(
        'Failed to submit invoice',
        error: e,
        stackTrace: stackTrace,
      );
      throw Exception('فشل في إنشاء الفاتورة: ${e.toString()}');
    }
  }

  /// Get invoice details from API
  Future<Invoice> getInvoice(int invoiceId) async {
    try {
      LoggerService.invoiceAction(
        'Fetching invoice details',
        data: {'invoiceId': invoiceId},
      );

      final response = await _apiClient.get(
        '/orders/$invoiceId',
      ); // Changed from /invoices to /orders

      if (!response['success']) {
        throw Exception(response['message'] ?? 'فشل في جلب الفاتورة');
      }

      final invoice = Invoice.fromJson(response['data']);

      LoggerService.invoiceAction(
        'Invoice fetched',
        data: {'invoiceNumber': invoice.invoiceNumber},
      );
      return invoice;
    } on ApiException catch (e) {
      LoggerService.error('Failed to fetch invoice', error: e);
      throw Exception(e.message);
    } catch (e, stackTrace) {
      LoggerService.error(
        'Failed to fetch invoice',
        error: e,
        stackTrace: stackTrace,
      );
      throw Exception('فشل في جلب الفاتورة: ${e.toString()}');
    }
  }

  /// Get print data for an order from API
  /// Returns formatted data ready for printing
  Future<Map<String, dynamic>> getPrintData(int orderId) async {
    try {
      LoggerService.info(
        'Fetching print data from API',
        data: {'orderId': orderId},
      );

      final response = await _apiClient.post('/orders/$orderId/print');

      if (!response['success']) {
        throw Exception(response['message'] ?? 'فشل في جلب بيانات الطباعة');
      }

      LoggerService.info(
        'Print data fetched successfully',
        data: {'orderId': orderId},
      );

      return response['data'] as Map<String, dynamic>;
    } on ApiException catch (e) {
      LoggerService.error('Failed to fetch print data', error: e);
      throw Exception(e.message);
    } catch (e, stackTrace) {
      LoggerService.error(
        'Failed to fetch print data',
        error: e,
        stackTrace: stackTrace,
      );
      throw Exception('فشل في جلب بيانات الطباعة: ${e.toString()}');
    }
  }

  /// Get all invoices with optional filters
  Future<List<Invoice>> fetchInvoices({
    int? clientId,
    String? fromDate,
    String? toDate,
  }) async {
    try {
      LoggerService.invoiceAction(
        'Fetching invoices',
        data: {'clientId': clientId, 'fromDate': fromDate, 'toDate': toDate},
      );

      final queryParams = <String, String>{};
      if (clientId != null)
        queryParams['person_id'] = clientId
            .toString(); // Changed from client_id to person_id
      if (fromDate != null) queryParams['from_date'] = fromDate;
      if (toDate != null) queryParams['to_date'] = toDate;

      final response = await _apiClient.get(
        '/orders', // Changed from /invoices to /orders
        queryParams: queryParams,
      );

      if (!response['success']) {
        throw Exception(response['message'] ?? 'فشل في جلب الفواتير');
      }

      // Handle paginated response
      final responseData = response['data'];
      final invoicesData =
          responseData is Map && responseData.containsKey('data')
          ? responseData['data'] as List
          : responseData as List;
      final invoices = invoicesData
          .map((json) => Invoice.fromJson(json))
          .toList();

      LoggerService.invoiceAction(
        'Invoices fetched',
        data: {'count': invoices.length},
      );
      return invoices;
    } on ApiException catch (e) {
      LoggerService.error('Failed to fetch invoices', error: e);
      throw Exception(e.message);
    } catch (e, stackTrace) {
      LoggerService.error(
        'Failed to fetch invoices',
        error: e,
        stackTrace: stackTrace,
      );
      throw Exception('فشل في جلب الفواتير: ${e.toString()}');
    }
  }

  /// Print invoice via API
  Future<Map<String, dynamic>> printInvoice(int invoiceId) async {
    try {
      LoggerService.invoiceAction(
        'Printing invoice',
        data: {'invoiceId': invoiceId},
      );

      final response = await _apiClient.post(
        '/orders/$invoiceId/print',
      ); // Changed from /invoices to /orders

      if (!response['success']) {
        throw Exception(response['message'] ?? 'فشل في طباعة الفاتورة');
      }

      LoggerService.invoiceAction('Invoice ready for printing');
      return response['data'];
    } on ApiException catch (e) {
      LoggerService.error('Failed to print invoice', error: e);
      throw Exception(e.message);
    } catch (e, stackTrace) {
      LoggerService.error(
        'Failed to print invoice',
        error: e,
        stackTrace: stackTrace,
      );
      throw Exception('فشل في طباعة الفاتورة: ${e.toString()}');
    }
  }
}
