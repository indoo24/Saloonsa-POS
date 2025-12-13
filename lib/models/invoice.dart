/// Invoice/Order model for API integration
class Invoice {
  final int id;
  final int invoiceNumber;
  final String date;
  final String? clientName;
  final int? personId; // New field for Orders API
  final int? saleId; // New field for Orders API (employee who made the sale)
  final String? note; // New field for Orders API
  final double total;
  final double paid;
  final double due;
  final String status;
  final String? paymentType;
  final List<InvoiceItem>? items;
  final double? subtotal;
  final double? discount;
  final String? discountType;
  final double? tax;
  final Map<String, dynamic>? person; // Person object from API
  final Map<String, dynamic>? sale; // Sale employee object from API

  // New fields for API-driven invoice calculations with correct order
  final double? subtotalBeforeTax; // Sum of service prices (before tax)
  final double? taxPercent; // Tax rate as percentage (e.g., 15 for 15%)
  final double? taxAmount; // Calculated tax amount
  final double? totalAfterTax; // Subtotal + tax
  final double? discountPercent; // Discount rate as percentage
  final double? discountAmount; // Calculated discount amount
  final double? finalTotal; // Total after tax and discount (grand total)
  final double? paidAmount; // Amount actually paid
  final double? remainingAmount; // Amount still owed (final_total - paid)

  Invoice({
    required this.id,
    required this.invoiceNumber,
    required this.date,
    this.clientName,
    this.personId,
    this.saleId,
    this.note,
    required this.total,
    required this.paid,
    required this.due,
    required this.status,
    this.paymentType,
    this.items,
    this.subtotal,
    this.discount,
    this.discountType,
    this.tax,
    this.person,
    this.sale,
    this.subtotalBeforeTax,
    this.taxPercent,
    this.taxAmount,
    this.totalAfterTax,
    this.discountPercent,
    this.discountAmount,
    this.finalTotal,
    this.paidAmount,
    this.remainingAmount,
  });

  factory Invoice.fromJson(Map<String, dynamic> json) {
    // Helper to safely get string value with fallback
    String getStringOrDefault(String key, String defaultValue) {
      final value = json[key];
      if (value == null) return defaultValue;
      return value.toString();
    }

    // Helper to safely parse int
    int parseInt(dynamic value, {int defaultValue = 0}) {
      if (value == null) return defaultValue;
      if (value is int) return value;
      if (value is double) return value.toInt();
      if (value is String) return int.tryParse(value) ?? defaultValue;
      return defaultValue;
    }

    // Parse int or null
    int? parseIntOrNull(dynamic value) {
      if (value == null) return null;
      if (value is int) return value;
      if (value is double) return value.toInt();
      if (value is String) return int.tryParse(value);
      return null;
    }

    // Get client name from person object or client_name field
    String? clientName;
    if (json['person'] != null && json['person'] is Map) {
      clientName = json['person']['name']?.toString();
    } else if (json['client_name'] != null) {
      clientName = json['client_name'].toString();
    }

    return Invoice(
      id: parseInt(json['id']),
      invoiceNumber: parseInt(json['invoice_number']),
      date: getStringOrDefault('date', DateTime.now().toIso8601String()),
      clientName: clientName,
      personId: parseIntOrNull(json['person_id']),
      saleId: parseIntOrNull(json['sale_id']),
      note: json['note']?.toString(),
      total: _parseDouble(json['total']),
      paid: _parseDouble(json['paid']),
      due: _parseDouble(json['due']),
      status: getStringOrDefault('status', 'pending'),
      paymentType: json['payment_type']?.toString(),
      items: json['items'] != null || json['details'] != null
          ? ((json['details'] ?? json['items']) as List)
                .map((i) => InvoiceItem.fromJson(i))
                .toList()
          : null,
      subtotal: json['subtotal'] != null
          ? _parseDouble(json['subtotal'])
          : null,
      discount: json['discount'] != null
          ? _parseDouble(json['discount'])
          : null,
      discountType: json['discount_type']?.toString(),
      tax: json['tax'] != null
          ? _parseDouble(json['tax'])
          : json['tax_value'] != null
          ? _parseDouble(json['tax_value'])
          : null,
      person: json['person'] as Map<String, dynamic>?,
      sale: json['sale'] as Map<String, dynamic>?,
      subtotalBeforeTax: json['subtotal_before_tax'] != null
          ? _parseDouble(json['subtotal_before_tax'])
          : json['subtotal'] != null
          ? _parseDouble(json['subtotal'])
          : null,
      taxPercent: json['tax_percent'] != null
          ? _parseDouble(json['tax_percent'])
          : null,
      taxAmount: json['tax_amount'] != null
          ? _parseDouble(json['tax_amount'])
          : json['tax'] != null
          ? _parseDouble(json['tax'])
          : json['tax_value'] != null
          ? _parseDouble(json['tax_value'])
          : null,
      totalAfterTax: json['total_after_tax'] != null
          ? _parseDouble(json['total_after_tax'])
          : json['total_before_discount'] != null
          ? _parseDouble(json['total_before_discount'])
          : null,
      discountPercent: json['discount_percent'] != null
          ? _parseDouble(json['discount_percent'])
          : null,
      discountAmount: json['discount_amount'] != null
          ? _parseDouble(json['discount_amount'])
          : json['discount'] != null && json['discount_type'] == 'fixed'
          ? _parseDouble(json['discount'])
          : null,
      finalTotal: json['final_total'] != null
          ? _parseDouble(json['final_total'])
          : json['grand_total'] != null
          ? _parseDouble(json['grand_total'])
          : json['total'] != null
          ? _parseDouble(json['total'])
          : null,
      paidAmount: json['paid_amount'] != null
          ? _parseDouble(json['paid_amount'])
          : json['paid'] != null
          ? _parseDouble(json['paid'])
          : null,
      remainingAmount: json['remaining_amount'] != null
          ? _parseDouble(json['remaining_amount'])
          : json['due'] != null
          ? _parseDouble(json['due'])
          : null,
    );
  }

  static double _parseDouble(dynamic value) {
    if (value == null) return 0.0;
    if (value is double) return value;
    if (value is int) return value.toDouble();
    if (value is String) return double.tryParse(value) ?? 0.0;
    return 0.0;
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'invoice_number': invoiceNumber,
      'date': date,
      'client_name': clientName,
      'person_id': personId,
      'sale_id': saleId,
      'note': note,
      'total': total,
      'paid': paid,
      'due': due,
      'status': status,
      'payment_type': paymentType,
      'items': items?.map((i) => i.toJson()).toList(),
      'subtotal': subtotal,
      'discount': discount,
      'discount_type': discountType,
      'tax': tax,
      'tax_value': tax,
      'person': person,
      'sale': sale,
      if (subtotalBeforeTax != null) 'subtotal_before_tax': subtotalBeforeTax,
      if (taxPercent != null) 'tax_percent': taxPercent,
      if (taxAmount != null) 'tax_amount': taxAmount,
      if (totalAfterTax != null) 'total_after_tax': totalAfterTax,
      if (discountPercent != null) 'discount_percent': discountPercent,
      if (discountAmount != null) 'discount_amount': discountAmount,
      if (finalTotal != null) 'final_total': finalTotal,
      if (paidAmount != null) 'paid_amount': paidAmount,
      if (remainingAmount != null) 'remaining_amount': remainingAmount,
    };
  }

  @override
  String toString() =>
      'Invoice(id: $id, number: $invoiceNumber, total: $total)';
}

/// Invoice/Order item model
class InvoiceItem {
  final int? id;
  final int serviceId; // Can be service_id or product_id
  final String? serviceName; // Can be service name or product name
  final int? employeeId;
  final String? employeeName;
  final double quantity;
  final double price;
  final double discount;
  final double total;
  final Map<String, dynamic>? product; // Product object from API
  final Map<String, dynamic>? employee; // Employee object from API

  InvoiceItem({
    this.id,
    required this.serviceId,
    this.serviceName,
    this.employeeId,
    this.employeeName,
    required this.quantity,
    required this.price,
    this.discount = 0,
    required this.total,
    this.product,
    this.employee,
  });

  factory InvoiceItem.fromJson(Map<String, dynamic> json) {
    // Helper to safely parse int
    int? parseIntOrNull(dynamic value) {
      if (value == null) return null;
      if (value is int) return value;
      if (value is double) return value.toInt();
      if (value is String) return int.tryParse(value);
      return null;
    }

    // Get service/product ID - try both fields
    int serviceId =
        parseIntOrNull(json['service_id']) ??
        parseIntOrNull(json['product_id']) ??
        0;

    // Get service/product name from object or direct field
    String? serviceName;
    if (json['product'] != null && json['product'] is Map) {
      serviceName = json['product']['name']?.toString();
    } else if (json['service_name'] != null) {
      serviceName = json['service_name'].toString();
    } else if (json['product_name'] != null) {
      serviceName = json['product_name'].toString();
    }

    // Get employee name from object or direct field
    String? employeeName;
    if (json['employee'] != null && json['employee'] is Map) {
      employeeName = json['employee']['name']?.toString();
    } else if (json['employee_name'] != null) {
      employeeName = json['employee_name'].toString();
    }

    return InvoiceItem(
      id: parseIntOrNull(json['id']),
      serviceId: serviceId,
      serviceName: serviceName,
      employeeId: parseIntOrNull(json['employee_id']),
      employeeName: employeeName,
      quantity: _parseDouble(json['quantity']) != 0
          ? _parseDouble(json['quantity'])
          : _parseDouble(json['qty']),
      price: _parseDouble(json['price']),
      discount: json['discount'] != null ? _parseDouble(json['discount']) : 0,
      total: _parseDouble(json['total']),
      product: json['product'] as Map<String, dynamic>?,
      employee: json['employee'] as Map<String, dynamic>?,
    );
  }

  static double _parseDouble(dynamic value) {
    if (value == null) return 0.0;
    if (value is double) return value;
    if (value is int) return value.toDouble();
    if (value is String) return double.tryParse(value) ?? 0.0;
    return 0.0;
  }

  Map<String, dynamic> toJson() {
    return {
      if (id != null) 'id': id,
      'service_id': serviceId,
      'product_id': serviceId, // Include both for compatibility
      if (serviceName != null) 'service_name': serviceName,
      if (serviceName != null) 'product_name': serviceName,
      'employee_id': employeeId,
      if (employeeName != null) 'employee_name': employeeName,
      'quantity': quantity,
      'qty': quantity, // Include both for compatibility
      'price': price,
      'discount': discount,
      'total': total,
      'product': product,
      'employee': employee,
    };
  }

  /// Convert to map for creating invoice/order
  Map<String, dynamic> toCreateJson() {
    return {
      'product_id': serviceId, // New Orders API uses product_id
      if (employeeId != null) 'employee_id': employeeId,
      'qty': quantity, // New Orders API uses qty
      'price': price,
    };
  }

  @override
  String toString() =>
      'InvoiceItem(service: $serviceName, quantity: $quantity, total: $total)';
}
