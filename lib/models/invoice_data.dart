/// Clean invoice data model for printing
/// This is shared between PDF and Thermal printing
class InvoiceData {
  // Order Information
  final String orderNumber;
  final String branchName;
  final String cashierName;
  final DateTime dateTime;

  // Customer Information
  final String? customerName;
  final String? customerPhone;

  // Services/Items
  final List<InvoiceItem> items;

  // Financial Data (all calculated values)
  final double subtotalBeforeTax;
  final double discountPercentage;
  final double discountAmount;
  final double amountAfterDiscount;
  final double taxRate; // e.g., 15 for 15%
  final double taxAmount;
  final double grandTotal;

  // Payment Information
  final String paymentMethod;
  final double? paidAmount;
  final double? remainingAmount;

  // Business Information
  final String businessName;
  final String businessAddress;
  final String businessPhone;
  final String? taxNumber;
  final String? invoiceNotes;
  final String? logoPath;

  const InvoiceData({
    required this.orderNumber,
    required this.branchName,
    required this.cashierName,
    required this.dateTime,
    this.customerName,
    this.customerPhone,
    required this.items,
    required this.subtotalBeforeTax,
    required this.discountPercentage,
    required this.discountAmount,
    required this.amountAfterDiscount,
    required this.taxRate,
    required this.taxAmount,
    required this.grandTotal,
    required this.paymentMethod,
    this.paidAmount,
    this.remainingAmount,
    required this.businessName,
    required this.businessAddress,
    required this.businessPhone,
    this.taxNumber,
    this.invoiceNotes,
    this.logoPath,
  });

  bool get hasDiscount => discountAmount > 0;
  bool get hasPaymentInfo => paidAmount != null;
  bool get hasRemaining => remainingAmount != null && remainingAmount! != 0;
  bool get isPaidInFull =>
      paidAmount != null && paidAmount! >= grandTotal && !hasRemaining;
}

/// Individual item in the invoice
class InvoiceItem {
  final String name;
  final double price;
  final int quantity;
  final String? employeeName;

  const InvoiceItem({
    required this.name,
    required this.price,
    this.quantity = 1,
    this.employeeName,
  });

  double get total => price * quantity;
}
