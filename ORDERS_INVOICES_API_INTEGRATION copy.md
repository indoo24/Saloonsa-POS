# Orders & Invoices API Integration Guide

## Overview
Complete guide for integrating Orders (Invoices) API with your Flutter application.

---

## 📋 Table of Contents
1. [Authentication](#authentication)
2. [Discount Calculation](#discount-calculation)
3. [API Endpoints](#api-endpoints)
4. [Data Models](#data-models)
5. [Flutter Integration](#flutter-integration)
6. [Usage Examples](#usage-examples)
7. [Error Handling](#error-handling)

---

## Authentication

All order endpoints require authentication. Include the Bearer token in the header:

```dart
headers: {
  'Authorization': 'Bearer ${yourToken}',
  'Content-Type': 'application/json',
  'Accept': 'application/json',
}
```

---

## Discount Calculation

### ⚠️ Important: Discount as Percentage

The backend treats the `discount` field as a **percentage (0-100)**, NOT a fixed amount.

### Calculation Formula

```php
$subtotal = sum of all items (qty × price)
$discountAmount = $subtotal × ($discount / 100)
$amountAfterDiscount = $subtotal - $discountAmount
$tax = $amountAfterDiscount × 0.15  // 15% VAT
$total = $amountAfterDiscount + $tax
```

### Example

**Order Items:**
- Item 1: 50 SAR
- Item 2: 75 SAR
- **Subtotal: 125 SAR**

**With 50% Discount:**
- Discount Amount: 125 × (50 / 100) = **62.5 SAR**
- Amount After Discount: 125 - 62.5 = **62.5 SAR**
- Tax (15%): 62.5 × 0.15 = **9.38 SAR**
- **Final Total: 71.88 SAR**

### Common Discount Values

| Discount % | Description |
|------------|-------------|
| 0 | No discount |
| 10 | 10% off |
| 25 | 25% off (Quarter) |
| 50 | 50% off (Half price) |
| 75 | 75% off |
| 100 | 100% off (Free) |

### Flutter Implementation

```dart
// Calculate order totals
double calculateOrderTotal({
  required double subtotal,
  required double discountPercentage,
}) {
  final discountAmount = subtotal * (discountPercentage / 100);
  final amountAfterDiscount = subtotal - discountAmount;
  final tax = amountAfterDiscount * 0.15;
  final total = amountAfterDiscount + tax;
  
  return total;
}

// Example usage
final subtotal = 125.0;
final discount = 50.0; // 50%
final total = calculateOrderTotal(
  subtotal: subtotal,
  discountPercentage: discount,
);
// Result: 71.88 SAR
```

---

## API Endpoints

### Base URL
```
http://your-domain.com/api
```

### 1. Get All Orders (List Invoices)

**Endpoint**: `GET /api/orders`

**Query Parameters**:
| Parameter | Type | Required | Description |
|-----------|------|----------|-------------|
| `client_id` | integer | No | Filter by customer ID |
| `sale_id` | integer | No | Filter by employee/salesman ID |
| `from_date` | date | No | Start date (YYYY-MM-DD) |
| `to_date` | date | No | End date (YYYY-MM-DD) |
| `per_page` | integer | No | Items per page (default: 15) |

**Example Request**:
```
GET /api/orders?client_id=1&from_date=2025-01-01&to_date=2025-12-31&per_page=20
```

**Response (200 OK)**:
```json
{
  "success": true,
  "data": {
    "current_page": 1,
    "data": [
      {
        "id": 43,
        "invoice_number": "34",
        "invoice_type": "sales",
        "payment_type": "cash",
        "client_id": 1,
        "sale_id": 1,
        "total": 130,
        "paid": 100,
        "due": 30,
        "discount": 10,
        "tax_value": 0,
        "note": "Test order from API",
        "invoice_date": "2025-12-11",
        "created_at": "2025-12-11T18:00:57.000000Z",
        "client": {
          "id": 1,
          "name": "عميل كاش",
          "mobile": null
        },
        "sale_man": {
          "id": 1,
          "name": "جوري",
          "mobile": null
        },
        "items": [
          {
            "id": 79,
            "product_id": 13,
            "qty": 1,
            "price": 50,
            "total": 50,
            "product": {
              "id": 13,
              "name": "قص الشعر",
              "is_service": 1
            }
          }
        ]
      }
    ],
    "per_page": 15,
    "total": 41,
    "last_page": 3
  }
}
```

---

### 2. Get Single Order (Invoice Details)

**Endpoint**: `GET /api/orders/{id}`

**Example Request**:
```
GET /api/orders/43
```

**Response (200 OK)**:
```json
{
  "success": true,
  "data": {
    "id": 43,
    "invoice_number": "34",
    "invoice_type": "sales",
    "payment_type": "cash",
    "client_id": 1,
    "sale_id": 1,
    "total": 130,
    "paid": 100,
    "due": 30,
    "tax": 0,
    "discount": 10,
    "tax_value": 0,
    "note": "Test order from API",
    "invoice_date": "2025-12-11",
    "created_at": "2025-12-11T18:00:57.000000Z",
    "updated_at": "2025-12-11T18:00:57.000000Z",
    "client": {
      "id": 1,
      "name": "عميل كاش",
      "mobile": null,
      "address": null
    },
    "sale_man": {
      "id": 1,
      "name": "جوري",
      "mobile": null
    },
    "items": [
      {
        "id": 79,
        "order_id": 43,
        "product_id": 13,
        "qty": 1,
        "price": 50,
        "total": 50,
        "employee_id": "1",
        "is_service": 1,
        "product": {
          "id": 13,
          "name": "قص الشعر",
          "code": "1210",
          "is_service": 1,
          "img": "/storage/4/salon.png"
        },
        "employee": {
          "id": 1,
          "name": "جوري",
          "mobile": null
        }
      }
    ]
  }
}
```

---

### 3. Create Order (Create Invoice)

**Endpoint**: `POST /api/orders`

**Request Body**:
```json
{
  "client_id": 1,
  "sale_id": 2,
  "payment_type": "cash",
  "discount": 50,
  "paid": 100,
  "note": "Customer requested specific stylist",
  "items": [
    {
      "product_id": 13,
      "qty": 1,
      "price": 50,
      "employee_id": 1
    },
    {
      "product_id": 14,
      "qty": 1,
      "price": 75,
      "employee_id": 1
    }
  ]
}
```

**Important**: 
- **Discount is a percentage (0-100)**, not a fixed amount
- Backend calculates: 
  - Subtotal = sum of all items
  - Discount Amount = Subtotal × (discount / 100)
  - Amount After Discount = Subtotal - Discount Amount
  - Tax = Amount After Discount × 0.15 (15%)
  - Total = Amount After Discount + Tax

**Example Calculation**:
- Subtotal: 125 SAR (50 + 75)
- Discount 50%: -62.5 SAR (125 × 0.50)
- Amount After Discount: 62.5 SAR
- Tax 15%: 9.38 SAR (62.5 × 0.15)
- **Total: 71.88 SAR**

**Required Fields**:
- `client_id`: Customer ID (required)
- `items`: Array of order items (required, min 1 item)
- `items.*.product_id`: Product/Service ID (required)
- `items.*.qty`: Quantity (required, min 0.01)
- `items.*.price`: Unit price (required, min 0)

**Optional Fields**:
- `sale_id`: Employee/Salesman ID
- `payment_type`: 'cash', 'visa', 'bank' (default: 'cash')
- `discount`: Discount percentage 0-100 (e.g., 50 = 50% off)
- `paid`: Amount paid
- `note`: Order notes
- `items.*.employee_id`: Employee assigned to this service

**Response (201 Created)**:
```json
{
  "success": true,
  "message": "Order created successfully",
  "data": {
    "id": 68,
    "invoice_number": "59",
    "invoice_type": "sales",
    "payment_type": "cash",
    "client_id": 1,
    "sale_id": 1,
    "total": 71.88,
    "paid": 50,
    "due": 21.88,
    "discount": 50,
    "tax_value": 9.38,
    "note": "Testing percentage discount calculation",
    "created_at": "2025-12-14T18:00:57.000000Z",
    "client": { 
      "id": 1,
      "name": "عميل كاش"
    },
    "sale_man": { 
      "id": 1,
      "name": "جوري"
    },
    "items": [
      {
        "id": 1,
        "product_id": 13,
        "qty": 1,
        "price": 50,
        "total": 50,
        "employee_id": 1,
        "product": {
          "id": 13,
          "name": "قص الشعر"
        }
      },
      {
        "id": 2,
        "product_id": 14,
        "qty": 1,
        "price": 75,
        "total": 75,
        "employee_id": 1,
        "product": {
          "id": 14,
          "name": "تنعيم وتجعيد الشعر"
        }
      }
    ]
  }
}
```

---

### 4. Print Order (Get Formatted Invoice for Printing)

**Endpoint**: `POST /api/orders/{id}/print`

**Example Request**:
```
POST /api/orders/43/print
```

**Response (200 OK)**:
```json
{
  "success": true,
  "data": {
    "order_id": 68,
    "invoice_number": "59",
    "date": "2025-12-14 18:00:57",
    "customer": {
      "name": "عميل كاش",
      "mobile": null,
      "address": null
    },
    "employee": {
      "name": "جوري",
      "mobile": null
    },
    "items": [
      {
        "product_name": "قص الشعر",
        "employee_name": "جوري",
        "qty": 1,
        "price": 50,
        "total": 50
      },
      {
        "product_name": "تنعيم وتجعيد الشعر",
        "employee_name": "جوري",
        "qty": 1,
        "price": 75,
        "total": 75
      }
    ],
    "subtotal": 125,
    "discount_percentage": 50,
    "discount_amount": 62.5,
    "amount_after_discount": 62.5,
    "tax_rate": 15,
    "tax_amount": 9.38,
    "total": 71.88,
    "paid": 50,
    "due": 21.88,
    "remaining": 21.88,
    "note": "Testing percentage discount calculation"
  }
}
```

---

## Data Models

### Flutter Models

#### 1. Order Model

```dart
// lib/models/order_model.dart
class OrderModel {
  final int id;
  final String invoiceNumber;
  final String invoiceType;
  final String paymentType;
  final int clientId;
  final int? saleId;
  final double total;
  final double paid;
  final double due;
  final double discount;
  final double taxValue;
  final String? note;
  final String invoiceDate;
  final DateTime createdAt;
  final CustomerModel? client;
  final EmployeeModel? saleMan;
  final List<OrderItemModel> items;

  OrderModel({
    required this.id,
    required this.invoiceNumber,
    required this.invoiceType,
    required this.paymentType,
    required this.clientId,
    this.saleId,
    required this.total,
    required this.paid,
    required this.due,
    required this.discount,
    required this.taxValue,
    this.note,
    required this.invoiceDate,
    required this.createdAt,
    this.client,
    this.saleMan,
    required this.items,
  });

  factory OrderModel.fromJson(Map<String, dynamic> json) {
    return OrderModel(
      id: json['id'] ?? 0,
      invoiceNumber: json['invoice_number']?.toString() ?? '',
      invoiceType: json['invoice_type'] ?? 'sales',
      paymentType: json['payment_type'] ?? 'cash',
      clientId: json['client_id'] ?? 0,
      saleId: json['sale_id'],
      total: (json['total'] ?? 0).toDouble(),
      paid: (json['paid'] ?? 0).toDouble(),
      due: (json['due'] ?? 0).toDouble(),
      discount: (json['discount'] ?? 0).toDouble(),
      taxValue: (json['tax_value'] ?? 0).toDouble(),
      note: json['note'],
      invoiceDate: json['invoice_date'] ?? '',
      createdAt: DateTime.parse(json['created_at'] ?? DateTime.now().toIso8601String()),
      client: json['client'] != null ? CustomerModel.fromJson(json['client']) : null,
      saleMan: json['sale_man'] != null ? EmployeeModel.fromJson(json['sale_man']) : null,
      items: (json['items'] as List?)?.map((item) => OrderItemModel.fromJson(item)).toList() ?? [],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'invoice_number': invoiceNumber,
      'invoice_type': invoiceType,
      'payment_type': paymentType,
      'client_id': clientId,
      'sale_id': saleId,
      'total': total,
      'paid': paid,
      'due': due,
      'discount': discount,
      'tax_value': taxValue,
      'note': note,
      'invoice_date': invoiceDate,
      'created_at': createdAt.toIso8601String(),
    };
  }
}
```

#### 2. Order Item Model

```dart
// lib/models/order_item_model.dart
class OrderItemModel {
  final int id;
  final int orderId;
  final int productId;
  final double qty;
  final double price;
  final double total;
  final String? employeeId;
  final int isService;
  final ProductModel? product;
  final EmployeeModel? employee;

  OrderItemModel({
    required this.id,
    required this.orderId,
    required this.productId,
    required this.qty,
    required this.price,
    required this.total,
    this.employeeId,
    required this.isService,
    this.product,
    this.employee,
  });

  factory OrderItemModel.fromJson(Map<String, dynamic> json) {
    return OrderItemModel(
      id: json['id'] ?? 0,
      orderId: json['order_id'] ?? 0,
      productId: json['product_id'] ?? 0,
      qty: (json['qty'] ?? 0).toDouble(),
      price: (json['price'] ?? 0).toDouble(),
      total: (json['total'] ?? 0).toDouble(),
      employeeId: json['employee_id']?.toString(),
      isService: json['is_service'] ?? 0,
      product: json['product'] != null ? ProductModel.fromJson(json['product']) : null,
      employee: json['employee'] != null ? EmployeeModel.fromJson(json['employee']) : null,
    );
  }
}
```

#### 3. Create Order Request Model

```dart
// lib/models/create_order_request.dart
class CreateOrderRequest {
  final int clientId;
  final int? saleId;
  final String? paymentType;
  final double? discount; // Percentage (0-100)
  final double? paid;
  final String? note;
  final List<OrderItemRequest> items;

  CreateOrderRequest({
    required this.clientId,
    this.saleId,
    this.paymentType,
    this.discount, // e.g., 50 = 50% discount
    this.paid,
    this.note,
    required this.items,
  });

  Map<String, dynamic> toJson() {
    return {
      'client_id': clientId,
      if (saleId != null) 'sale_id': saleId,
      if (paymentType != null) 'payment_type': paymentType,
      if (discount != null) 'discount': discount, // Send percentage value
      if (paid != null) 'paid': paid,
      if (note != null && note!.isNotEmpty) 'note': note,
      'items': items.map((item) => item.toJson()).toList(),
    };
  }
  
  // Calculate expected total for validation
  double calculateTotal() {
    final subtotal = items.fold<double>(
      0, 
      (sum, item) => sum + (item.qty * item.price)
    );
    
    final discountAmount = subtotal * ((discount ?? 0) / 100);
    final amountAfterDiscount = subtotal - discountAmount;
    final tax = amountAfterDiscount * 0.15;
    final total = amountAfterDiscount + tax;
    
    return total;
  }
  
  // Calculate discount amount
  double calculateDiscountAmount() {
    final subtotal = items.fold<double>(
      0, 
      (sum, item) => sum + (item.qty * item.price)
    );
    
    return subtotal * ((discount ?? 0) / 100);
  }
}

class OrderItemRequest {
  final int productId;
  final double qty;
  final double price;
  final int? employeeId;

  OrderItemRequest({
    required this.productId,
    required this.qty,
    required this.price,
    this.employeeId,
  });

  Map<String, dynamic> toJson() {
    return {
      'product_id': productId,
      'qty': qty,
      'price': price,
      if (employeeId != null) 'employee_id': employeeId,
    };
  }
}
```

---

## Flutter Integration

### 1. Order Service

```dart
// lib/services/order_service.dart
import 'package:dio/dio.dart';
import '../models/order_model.dart';
import '../models/create_order_request.dart';

class OrderService {
  final Dio _dio;
  static const String baseUrl = 'http://your-domain.com/api';

  OrderService(this._dio);

  // Get all orders with filters
  Future<List<OrderModel>> getOrders({
    int? clientId,
    int? saleId,
    String? fromDate,
    String? toDate,
    int page = 1,
    int perPage = 15,
  }) async {
    try {
      final queryParams = <String, dynamic>{
        'page': page,
        'per_page': perPage,
      };

      if (clientId != null) queryParams['client_id'] = clientId;
      if (saleId != null) queryParams['sale_id'] = saleId;
      if (fromDate != null) queryParams['from_date'] = fromDate;
      if (toDate != null) queryParams['to_date'] = toDate;

      final response = await _dio.get(
        '$baseUrl/orders',
        queryParameters: queryParams,
      );

      if (response.statusCode == 200 && response.data['success']) {
        final List<dynamic> ordersData = response.data['data']['data'];
        return ordersData.map((json) => OrderModel.fromJson(json)).toList();
      }
      return [];
    } on DioException catch (e) {
      throw Exception('Failed to fetch orders: ${e.message}');
    }
  }

  // Get single order by ID
  Future<OrderModel?> getOrderById(int orderId) async {
    try {
      final response = await _dio.get('$baseUrl/orders/$orderId');

      if (response.statusCode == 200 && response.data['success']) {
        return OrderModel.fromJson(response.data['data']);
      }
      return null;
    } on DioException catch (e) {
      if (e.response?.statusCode == 404) {
        throw Exception('Order not found');
      }
      throw Exception('Failed to fetch order: ${e.message}');
    }
  }

  // Create new order
  Future<OrderModel?> createOrder(CreateOrderRequest orderRequest) async {
    try {
      final response = await _dio.post(
        '$baseUrl/orders',
        data: orderRequest.toJson(),
      );

      if (response.statusCode == 201 && response.data['success']) {
        return OrderModel.fromJson(response.data['data']);
      }
      return null;
    } on DioException catch (e) {
      if (e.response?.statusCode == 422) {
        final errors = e.response?.data['errors'];
        throw Exception('Validation error: ${errors.toString()}');
      }
      throw Exception('Failed to create order: ${e.message}');
    }
  }

  // Get print data for order
  Future<Map<String, dynamic>?> getPrintData(int orderId) async {
    try {
      final response = await _dio.post('$baseUrl/orders/$orderId/print');

      if (response.statusCode == 200 && response.data['success']) {
        return response.data['data'];
      }
      return null;
    } on DioException catch (e) {
      throw Exception('Failed to get print data: ${e.message}');
    }
  }
}
```

---

## Usage Examples

### 1. List Orders Screen

```dart
// lib/screens/orders_list_screen.dart
import 'package:flutter/material.dart';
import '../services/order_service.dart';
import '../models/order_model.dart';

class OrdersListScreen extends StatefulWidget {
  @override
  _OrdersListScreenState createState() => _OrdersListScreenState();
}

class _OrdersListScreenState extends State<OrdersListScreen> {
  final OrderService _orderService = OrderService(Dio());
  List<OrderModel> orders = [];
  bool isLoading = false;

  @override
  void initState() {
    super.initState();
    _loadOrders();
  }

  Future<void> _loadOrders() async {
    setState(() => isLoading = true);
    try {
      final fetchedOrders = await _orderService.getOrders();
      setState(() {
        orders = fetchedOrders;
        isLoading = false;
      });
    } catch (e) {
      setState(() => isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: ${e.toString()}')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Orders')),
      body: isLoading
          ? Center(child: CircularProgressIndicator())
          : ListView.builder(
              itemCount: orders.length,
              itemBuilder: (context, index) {
                final order = orders[index];
                return ListTile(
                  title: Text('Invoice #${order.invoiceNumber}'),
                  subtitle: Text(
                    '${order.client?.name ?? "Unknown"} - ${order.total} EGP',
                  ),
                  trailing: Text(order.invoiceDate),
                  onTap: () {
                    // Navigate to order details
                    Navigator.pushNamed(
                      context,
                      '/order-details',
                      arguments: order.id,
                    );
                  },
                );
              },
            ),
      floatingActionButton: FloatingActionButton(
        child: Icon(Icons.add),
        onPressed: () {
          // Navigate to create order screen
          Navigator.pushNamed(context, '/create-order');
        },
      ),
    );
  }
}
```

### 2. Create Order Screen

```dart
// lib/screens/create_order_screen.dart
import 'package:flutter/material.dart';
import '../services/order_service.dart';
import '../models/create_order_request.dart';

class CreateOrderScreen extends StatefulWidget {
  @override
  _CreateOrderScreenState createState() => _CreateOrderScreenState();
}

class _CreateOrderScreenState extends State<CreateOrderScreen> {
  final OrderService _orderService = OrderService(Dio());
  final _formKey = GlobalKey<FormState>();
  
  int? selectedCustomerId;
  int? selectedEmployeeId;
  double discount = 0;
  double paid = 0;
  String? note;
  List<OrderItemRequest> items = [];
  
  bool isLoading = false;

  Future<void> _createOrder() async {
    if (!_formKey.currentState!.validate() || items.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Please add at least one item')),
      );
      return;
    }

    _formKey.currentState!.save();
    setState(() => isLoading = true);

    try {
      final orderRequest = CreateOrderRequest(
        clientId: selectedCustomerId!,
        saleId: selectedEmployeeId,
        paymentType: 'cash',
        discount: discount, // Percentage (0-100)
        paid: paid,
        note: note,
        items: items,
      );
      
      // Show preview of calculated total
      final expectedTotal = orderRequest.calculateTotal();
      final discountAmount = orderRequest.calculateDiscountAmount();
      
      print('Expected Total: $expectedTotal SAR');
      print('Discount Amount: $discountAmount SAR');

      final createdOrder = await _orderService.createOrder(orderRequest);
      
      setState(() => isLoading = false);
      
      if (createdOrder != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Order created successfully!')),
        );
        Navigator.pop(context, createdOrder);
      }
    } catch (e) {
      setState(() => isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error: ${e.toString()}'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  void _addItem(int productId, double qty, double price, int? employeeId) {
    setState(() {
      items.add(OrderItemRequest(
        productId: productId,
        qty: qty,
        price: price,
        employeeId: employeeId,
      ));
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Create Order')),
      body: isLoading
          ? Center(child: CircularProgressIndicator())
          : Form(
              key: _formKey,
              child: ListView(
                padding: EdgeInsets.all(16),
                children: [
                  // Customer selection
                  DropdownButtonFormField<int>(
                    decoration: InputDecoration(labelText: 'Customer'),
                    items: [], // Load customers from API
                    onChanged: (value) => selectedCustomerId = value,
                    validator: (value) => value == null ? 'Required' : null,
                  ),
                  SizedBox(height: 16),
                  
                  // Employee selection (optional)
                  DropdownButtonFormField<int>(
                    decoration: InputDecoration(labelText: 'Employee (Optional)'),
                    items: [], // Load employees from API
                    onChanged: (value) => selectedEmployeeId = value,
                  ),
                  SizedBox(height: 16),
                  
                  // Discount (percentage)
                  TextFormField(
                    decoration: InputDecoration(
                      labelText: 'Discount (%)',
                      helperText: 'Enter percentage (0-100)',
                      suffixText: '%',
                    ),
                    keyboardType: TextInputType.number,
                    onSaved: (value) => discount = double.tryParse(value ?? '0') ?? 0,
                    validator: (value) {
                      if (value != null && value.isNotEmpty) {
                        final val = double.tryParse(value);
                        if (val == null || val < 0 || val > 100) {
                          return 'Discount must be between 0 and 100';
                        }
                      }
                      return null;
                    },
                  ),
                  SizedBox(height: 16),
                  
                  // Paid amount
                  TextFormField(
                    decoration: InputDecoration(labelText: 'Paid Amount'),
                    keyboardType: TextInputType.number,
                    onSaved: (value) => paid = double.tryParse(value ?? '0') ?? 0,
                  ),
                  SizedBox(height: 16),
                  
                  // Note
                  TextFormField(
                    decoration: InputDecoration(labelText: 'Note'),
                    maxLines: 3,
                    onSaved: (value) => note = value,
                  ),
                  SizedBox(height: 24),
                  
                  // Items list
                  Text('Items: ${items.length}', style: TextStyle(fontSize: 18)),
                  // Add button to add items
                  
                  SizedBox(height: 24),
                  ElevatedButton(
                    onPressed: _createOrder,
                    child: Padding(
                      padding: EdgeInsets.all(16),
                      child: Text('Create Order', style: TextStyle(fontSize: 18)),
                    ),
                  ),
                ],
              ),
            ),
    );
  }
}
```

### 3. Order Details Screen

```dart
// lib/screens/order_details_screen.dart
import 'package:flutter/material.dart';
import '../services/order_service.dart';
import '../models/order_model.dart';

class OrderDetailsScreen extends StatefulWidget {
  final int orderId;

  OrderDetailsScreen({required this.orderId});

  @override
  _OrderDetailsScreenState createState() => _OrderDetailsScreenState();
}

class _OrderDetailsScreenState extends State<OrderDetailsScreen> {
  final OrderService _orderService = OrderService(Dio());
  OrderModel? order;
  bool isLoading = false;

  @override
  void initState() {
    super.initState();
    _loadOrder();
  }

  Future<void> _loadOrder() async {
    setState(() => isLoading = true);
    try {
      final fetchedOrder = await _orderService.getOrderById(widget.orderId);
      setState(() {
        order = fetchedOrder;
        isLoading = false;
      });
    } catch (e) {
      setState(() => isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: ${e.toString()}')),
      );
    }
  }

  Future<void> _printOrder() async {
    try {
      final printData = await _orderService.getPrintData(widget.orderId);
      if (printData != null) {
        // Navigate to print preview or send to printer
        Navigator.pushNamed(context, '/print-preview', arguments: printData);
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: ${e.toString()}')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return Scaffold(
        appBar: AppBar(title: Text('Order Details')),
        body: Center(child: CircularProgressIndicator()),
      );
    }

    if (order == null) {
      return Scaffold(
        appBar: AppBar(title: Text('Order Details')),
        body: Center(child: Text('Order not found')),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: Text('Invoice #${order!.invoiceNumber}'),
        actions: [
          IconButton(
            icon: Icon(Icons.print),
            onPressed: _printOrder,
          ),
        ],
      ),
      body: ListView(
        padding: EdgeInsets.all(16),
        children: [
          // Customer info
          Card(
            child: ListTile(
              title: Text('Customer'),
              subtitle: Text(order!.client?.name ?? 'Unknown'),
              trailing: Text(order!.client?.mobile ?? '-'),
            ),
          ),
          SizedBox(height: 8),
          
          // Employee info
          if (order!.saleMan != null)
            Card(
              child: ListTile(
                title: Text('Employee'),
                subtitle: Text(order!.saleMan!.name),
              ),
            ),
          SizedBox(height: 16),
          
          // Items
          Text('Items', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
          SizedBox(height: 8),
          ...order!.items.map((item) => Card(
            child: ListTile(
              title: Text(item.product?.name ?? 'Unknown Product'),
              subtitle: Text('${item.qty} x ${item.price} EGP'),
              trailing: Text('${item.total} EGP'),
            ),
          )).toList(),
          SizedBox(height: 16),
          
          // Totals
          Card(
            child: Padding(
              padding: EdgeInsets.all(16),
              child: Column(
                children: [
                  // Calculate subtotal from items
                  Builder(
                    builder: (context) {
                      final subtotal = order!.items.fold<double>(
                        0, 
                        (sum, item) => sum + item.total
                      );
                      final discountAmount = subtotal * (order!.discount / 100);
                      
                      return Column(
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text('Subtotal:'),
                              Text('${subtotal.toStringAsFixed(2)} SAR'),
                            ],
                          ),
                          if (order!.discount > 0) ...[
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text('Discount (${order!.discount}%):'),
                                Text('-${discountAmount.toStringAsFixed(2)} SAR'),
                              ],
                            ),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text('After Discount:'),
                                Text('${(subtotal - discountAmount).toStringAsFixed(2)} SAR'),
                              ],
                            ),
                          ],
                          if (order!.taxValue > 0)
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text('Tax (15%):'),
                                Text('${order!.taxValue.toStringAsFixed(2)} SAR'),
                              ],
                            ),
                          Divider(),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text('Total:', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
                              Text('${order!.total.toStringAsFixed(2)} SAR', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
                            ],
                          ),
                          SizedBox(height: 8),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text('Paid:'),
                              Text('${order!.paid.toStringAsFixed(2)} SAR', style: TextStyle(color: Colors.green)),
                            ],
                          ),
                          if (order!.due > 0)
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text('Due:', style: TextStyle(color: Colors.red)),
                                Text('${order!.due.toStringAsFixed(2)} SAR', style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold)),
                              ],
                            ),
                        ],
                      );
                    }
                  ),
                ],
              ),
            ),
          ),
          
          // Note
          if (order!.note != null && order!.note!.isNotEmpty)
            Card(
              child: ListTile(
                title: Text('Note'),
                subtitle: Text(order!.note!),
              ),
            ),
        ],
      ),
    );
  }
}
```

---

## Error Handling

### Common Errors and Solutions

#### 1. Validation Error (422)

```json
{
  "success": false,
  "message": "Validation error",
  "errors": {
    "client_id": ["The client id field is required."],
    "items": ["The items field is required."]
  }
}
```

**Solution**: Ensure all required fields are provided and valid.

#### 2. Unauthorized (401)

```json
{
  "success": false,
  "message": "Unauthenticated"
}
```

**Solution**: Check that the Bearer token is included and valid.

#### 3. Order Not Found (404)

```json
{
  "success": false,
  "message": "Order not found"
}
```

**Solution**: Verify the order ID exists.

#### 4. Server Error (500)

```json
{
  "success": false,
  "message": "Failed to create order",
  "error": "Error details..."
}
```

**Solution**: Check the error details and contact backend support if needed.

---

## Testing with Postman

### 1. Import Collection

Import the `Salon_API_Postman_Collection.json` file into Postman.

### 2. Set Environment Variables

- `base_url`: `http://localhost:8000/api`
- `auth_token`: Will be set automatically after login

### 3. Test Flow

1. **Login** → Get token
2. **GET /api/orders** → List all orders
3. **POST /api/orders** → Create new order
4. **GET /api/orders/{id}** → View order details
5. **POST /api/orders/{id}/print** → Get print data

---

## Best Practices

### 1. Always Validate Input

```dart
if (items.isEmpty) {
  throw Exception('At least one item is required');
}

if (clientId == null) {
  throw Exception('Customer is required');
}

// Validate discount percentage
if (discount != null && (discount < 0 || discount > 100)) {
  throw Exception('Discount must be between 0 and 100');
}
```

### 2. Calculate Total Before Submitting

```dart
// Show user the expected total before creating order
double calculateExpectedTotal(List<OrderItemRequest> items, double discountPercentage) {
  final subtotal = items.fold<double>(0, (sum, item) => sum + (item.qty * item.price));
  final discountAmount = subtotal * (discountPercentage / 100);
  final amountAfterDiscount = subtotal - discountAmount;
  final tax = amountAfterDiscount * 0.15;
  return amountAfterDiscount + tax;
}

// Show preview dialog
showDialog(
  context: context,
  builder: (context) => AlertDialog(
    title: Text('Order Summary'),
    content: Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text('Subtotal: ${subtotal.toStringAsFixed(2)} SAR'),
        Text('Discount ($discountPercentage%): -${discountAmount.toStringAsFixed(2)} SAR'),
        Text('Tax (15%): ${tax.toStringAsFixed(2)} SAR'),
        Divider(),
        Text('Total: ${total.toStringAsFixed(2)} SAR', 
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
      ],
    ),
    actions: [
      TextButton(onPressed: () => Navigator.pop(context), child: Text('Cancel')),
      ElevatedButton(onPressed: () {
        Navigator.pop(context);
        _submitOrder();
      }, child: Text('Confirm')),
    ],
  ),
);
```

### 3. Handle Loading States

```dart
bool isLoading = false;

setState(() => isLoading = true);
try {
  // API call
} finally {
  setState(() => isLoading = false);
}
```

### 4. Cache Orders Locally

```dart
// Use shared_preferences or local database
final prefs = await SharedPreferences.getInstance();
await prefs.setString('last_orders', jsonEncode(orders));
```

### 5. Implement Pull-to-Refresh

```dart
RefreshIndicator(
  onRefresh: _loadOrders,
  child: ListView.builder(...),
)
```

### 6. Add Search and Filters

```dart
// Filter by date range
await _orderService.getOrders(
  fromDate: '2025-01-01',
  toDate: '2025-12-31',
);

// Filter by customer
await _orderService.getOrders(clientId: customerId);
```

---

## Summary

This guide covers:
- ✅ All order/invoice endpoints
- ✅ Complete Flutter models
- ✅ Service layer implementation
- ✅ UI screens with examples
- ✅ Error handling
- ✅ Best practices

For additional support, refer to the main API documentation or contact the backend team.
