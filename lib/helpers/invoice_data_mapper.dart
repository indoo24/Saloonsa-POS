import '../models/invoice_data.dart';
import '../screens/casher/models/customer.dart';
import '../screens/casher/models/service-model.dart';
import '../services/api_client.dart';

/// Helper class to convert existing app data structures to InvoiceData
///
/// This allows seamless integration with the new printing architecture
/// while maintaining backward compatibility with existing code.
class InvoiceDataMapper {
  /// Convert a logo path from API to full URL
  static String? _getLogoUrl(String? logoPath) {
    if (logoPath == null || logoPath.isEmpty) return null;

    // If already a full URL, return as-is
    if (logoPath.startsWith('http://') || logoPath.startsWith('https://')) {
      return logoPath;
    }

    // If it's a relative path, construct full URL with subdomain
    if (logoPath.startsWith('/storage/') || logoPath.startsWith('storage/')) {
      final apiClient = ApiClient();
      final subdomain = apiClient.getSubdomain();

      // Remove leading slash if present
      final cleanPath = logoPath.startsWith('/') ? logoPath : '/$logoPath';

      if (subdomain != null && subdomain.isNotEmpty) {
        return 'https://$subdomain.saloonsa.com$cleanPath';
      } else {
        return 'https://saloonsa.com$cleanPath';
      }
    }

    // If it's an asset path (local), return as-is
    if (logoPath.startsWith('assets/')) {
      return logoPath;
    }

    return logoPath;
  }

  /// Convert existing cart, customer, and settings data to InvoiceData
  ///
  /// This preserves all business logic and calculations from the original code.
  static InvoiceData fromExistingData({
    required List<ServiceModel> services,
    Customer? customer,
    required String orderNumber,
    required String cashierName,
    required String branchName,
    required DateTime dateTime,
    required double subtotalBeforeTax,
    required double discountPercentage,
    required double discountAmount,
    required double taxRate,
    required double taxAmount,
    required double grandTotal,
    String? paymentMethod,
    double? paidAmount,
    double? remainingAmount,
    String? invoiceNotes,
    String businessName = 'صالون الشباب',
    String businessAddress = 'الرياض، المملكة العربية السعودية',
    String businessPhone = '+966 XX XXX XXXX',
    String? taxNumber,
    String? logoPath,
  }) {
    // Convert services to invoice items
    final items = services.map((service) {
      return InvoiceItem(
        name: service.name,
        price: service.price,
        quantity: 1, // Services are typically quantity 1
        employeeName: service.employeeName,
      );
    }).toList();

    // Calculate amount after discount
    final amountAfterDiscount = subtotalBeforeTax - discountAmount;

    return InvoiceData(
      orderNumber: orderNumber,
      branchName: branchName,
      cashierName: cashierName,
      dateTime: dateTime,
      customerName: customer?.name,
      customerPhone: customer?.phone,
      items: items,
      subtotalBeforeTax: subtotalBeforeTax,
      discountPercentage: discountPercentage,
      discountAmount: discountAmount,
      amountAfterDiscount: amountAfterDiscount,
      taxRate: taxRate,
      taxAmount: taxAmount,
      grandTotal: grandTotal,
      paymentMethod: paymentMethod ?? 'نقدي',
      paidAmount: paidAmount,
      remainingAmount: remainingAmount,
      invoiceNotes: invoiceNotes,
      businessName: businessName,
      businessAddress: businessAddress,
      businessPhone: businessPhone,
      taxNumber: taxNumber,
      logoPath: _getLogoUrl(logoPath),
    );
  }

  /// Convert from API print data response to InvoiceData
  ///
  /// This handles the backend response structure and maps it to InvoiceData
  static InvoiceData fromApiPrintData(
    Map<String, dynamic> printData, {
    required String branchName,
    String? customerName,
    String? customerPhone,
    String businessName = 'صالون الشباب',
    String businessAddress = 'الرياض، المملكة العربية السعودية',
    String businessPhone = '+966 XX XXX XXXX',
    String? taxNumber,
    String? logoPath,
  }) {
    // Extract items
    final itemsData = printData['items'] as List<dynamic>? ?? [];
    final items = itemsData.map((item) {
      return InvoiceItem(
        name: item['product_name'] ?? 'خدمة',
        price: (item['price'] as num?)?.toDouble() ?? 0.0,
        quantity: (item['quantity'] as int?) ?? 1,
        employeeName: item['employee_name'],
      );
    }).toList();

    // Extract financial data
    // IMPORTANT: Use invoice_number (same as website) instead of order_id
    final orderNumber =
        printData['invoice_number']?.toString() ??
        printData['order_id']?.toString() ??
        '';

    print('📋 Invoice Number Debug:');
    print('  invoice_number from API: ${printData['invoice_number']}');
    print('  order_id from API: ${printData['order_id']}');
    print('  Using: $orderNumber');

    final cashierName = printData['employee']?['name'] ?? 'الكاشير';

    final subtotal = (printData['subtotal'] as num?)?.toDouble() ?? 0.0;
    final discountPercentage =
        (printData['discount_percentage'] as num?)?.toDouble() ?? 0.0;
    final discountAmount =
        (printData['discount_amount'] as num?)?.toDouble() ?? 0.0;
    final taxRate = (printData['tax_rate'] as num?)?.toDouble() ?? 15.0;
    final taxAmount =
        (printData['tax_amount'] as num?)?.toDouble() ??
        (printData['tax'] as num?)?.toDouble() ??
        0.0;
    final grandTotal = (printData['total'] as num?)?.toDouble() ?? 0.0;

    final paid = (printData['paid'] as num?)?.toDouble();
    final remaining =
        (printData['remaining'] as num?)?.toDouble() ??
        (printData['due'] as num?)?.toDouble();

    // Extract payment method - try multiple possible field names
    print('🔍 Payment Method Debug:');
    print('  payment_type: ${printData['payment_type']}');
    print('  payment_method: ${printData['payment_method']}');
    print('  paymentType: ${printData['paymentType']}');
    print('  paymentMethod: ${printData['paymentMethod']}');
    print('  All keys: ${printData.keys.toList()}');

    final paymentMethodFromApi =
        printData['payment_type']?.toString() ??
        printData['payment_method']?.toString() ??
        printData['paymentType']?.toString() ??
        printData['paymentMethod']?.toString();

    print('  Raw value: $paymentMethodFromApi');
    final paymentMethod = _mapPaymentTypeToArabic(paymentMethodFromApi);
    print('  Mapped to Arabic: $paymentMethod');

    // Extract customer data
    final customerData = printData['customer'] as Map<String, dynamic>?;
    final finalCustomerName =
        customerData?['name'] ?? customerName ?? 'عميل كاش';
    final finalCustomerPhone = customerData?['mobile'] ?? customerPhone;

    // Extract date
    final dateStr = printData['date']?.toString();
    final dateTime = dateStr != null
        ? DateTime.tryParse(dateStr) ?? DateTime.now()
        : DateTime.now();

    // Calculate amount after discount
    final amountAfterDiscount = subtotal - discountAmount;

    return InvoiceData(
      orderNumber: orderNumber,
      branchName: branchName,
      cashierName: cashierName,
      dateTime: dateTime,
      customerName: finalCustomerName,
      customerPhone: finalCustomerPhone,
      items: items,
      subtotalBeforeTax: subtotal,
      discountPercentage: discountPercentage,
      discountAmount: discountAmount,
      amountAfterDiscount: amountAfterDiscount,
      taxRate: taxRate,
      taxAmount: taxAmount,
      grandTotal: grandTotal,
      paymentMethod: paymentMethod,
      paidAmount: paid,
      remainingAmount: remaining,
      invoiceNotes: null,
      businessName: businessName,
      businessAddress: businessAddress,
      businessPhone: businessPhone,
      taxNumber: taxNumber,
      logoPath: _getLogoUrl(logoPath),
    );
  }

  /// Map backend payment type to Arabic display name
  static String _mapPaymentTypeToArabic(String? paymentType) {
    if (paymentType == null || paymentType.isEmpty) {
      print('⚠️ Payment type is null or empty, defaulting to نقدي');
      return 'نقدي';
    }

    print('🔄 Mapping payment type: "$paymentType"');

    final normalized = paymentType.toLowerCase().trim();

    String result;
    switch (normalized) {
      case 'cash':
      case 'نقدي':
        result = 'نقدي';
        break;
      case 'visa':
      case 'card':
      case 'شبكة':
        result = 'شبكة';
        break;
      case 'bank':
      case 'transfer':
      case 'تحويل':
        result = 'تحويل';
        break;
      default:
        // If already in Arabic or unknown, return as-is
        print('⚠️ Unknown payment type: "$paymentType", using as-is');
        result = paymentType;
    }

    print('✅ Mapped to: "$result"');
    return result;
  }
}
