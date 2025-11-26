/// Invoice model for API integration
class Invoice {
  final int id;
  final int invoiceNumber;
  final String date;
  final String? clientName;
  final String? salonName;
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

  Invoice({
    required this.id,
    required this.invoiceNumber,
    required this.date,
    this.clientName,
    this.salonName,
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

    return Invoice(
      id: parseInt(json['id']),
      invoiceNumber: parseInt(json['invoice_number']),
      date: getStringOrDefault('date', DateTime.now().toIso8601String()),
      clientName: json['client_name']?.toString(),
      salonName: json['salon_name']?.toString(),
      total: _parseDouble(json['total']),
      paid: _parseDouble(json['paid']),
      due: _parseDouble(json['due']),
      status: getStringOrDefault('status', 'pending'),
      paymentType: json['payment_type']?.toString(),
      items: json['items'] != null
          ? (json['items'] as List).map((i) => InvoiceItem.fromJson(i)).toList()
          : null,
      subtotal: json['subtotal'] != null ? _parseDouble(json['subtotal']) : null,
      discount: json['discount'] != null ? _parseDouble(json['discount']) : null,
      discountType: json['discount_type']?.toString(),
      tax: json['tax'] != null ? _parseDouble(json['tax']) : null,
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
      'salon_name': salonName,
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
    };
  }

  @override
  String toString() => 'Invoice(id: $id, number: $invoiceNumber, total: $total)';
}

/// Invoice item model
class InvoiceItem {
  final int? id;
  final int serviceId;
  final String? serviceName;
  final int? employeeId;
  final String? employeeName;
  final double quantity;
  final double price;
  final double discount;
  final double total;

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

    return InvoiceItem(
      id: parseIntOrNull(json['id']),
      serviceId: parseIntOrNull(json['service_id']) ?? 0,
      serviceName: json['service_name']?.toString(),
      employeeId: parseIntOrNull(json['employee_id']),
      employeeName: json['employee_name']?.toString(),
      quantity: _parseDouble(json['quantity']),
      price: _parseDouble(json['price']),
      discount: json['discount'] != null ? _parseDouble(json['discount']) : 0,
      total: _parseDouble(json['total']),
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
      if (serviceName != null) 'service_name': serviceName,
      'employee_id': employeeId,
      if (employeeName != null) 'employee_name': employeeName,
      'quantity': quantity,
      'price': price,
      'discount': discount,
      'total': total,
    };
  }

  /// Convert to map for creating invoice
  Map<String, dynamic> toCreateJson() {
    return {
      'service_id': serviceId,
      if (employeeId != null) 'employee_id': employeeId,
      'quantity': quantity,
      'price': price,
      'discount': discount,
    };
  }

  @override
  String toString() => 'InvoiceItem(service: $serviceName, quantity: $quantity, total: $total)';
}
