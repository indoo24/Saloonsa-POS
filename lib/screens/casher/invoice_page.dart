import 'dart:io';

import 'package:barber_casher/screens/casher/print_dirct.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:printing/printing.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../cubits/cashier/cashier_cubit.dart';
import '../../cubits/cashier/cashier_state.dart';
import '../../models/payment_method.dart';
import 'pdf_invoice.dart';
import 'models/customer.dart';
import 'models/service-model.dart';

class InvoicePage extends StatefulWidget {
  final List<ServiceModel> cart;
  final Customer? customer;

  const InvoicePage({super.key, required this.cart, this.customer});

  @override
  State<InvoicePage> createState() => _InvoicePageState();
}

class _InvoicePageState extends State<InvoicePage> {
  final _discountController = TextEditingController(text: '0');
  final _paidController = TextEditingController();
  final _cashierNameController = TextEditingController(text: 'Yousef');
  final _orderNumberController = TextEditingController(
    text: '${DateTime.now().millisecondsSinceEpoch}',
  );
  final _branchNameController = TextEditingController(text: 'الفرع الرئيسي');
  String _paymentMethod = 'نقدي';
  DateTime? _selectedServiceDateTime;
  bool _isSaving = false;

  double? _paidAmount;

  @override
  void initState() {
    super.initState();

    // Calculate initial total with tax (matching backend logic)
    final initialSubtotal = widget.cart.fold<double>(
      0,
      (sum, item) => sum + item.price,
    );

    // Calculate tax (15%) on subtotal (no discount initially)
    final initialTax = initialSubtotal * 0.15;
    final initialTotal = initialSubtotal + initialTax;

    // Set paid amount to total (including tax)
    _paidController.text = initialTotal.toStringAsFixed(2);
    _paidAmount = initialTotal;

    _discountController.addListener(() {
      setState(() {
        // Recalculate totals when discount changes
        _updatePaidAmountToTotal();
      });
    });

    _paidController.addListener(() {
      setState(() {
        _paidAmount = double.tryParse(_paidController.text);
      });
    });

    // Set default service date/time to now
    _selectedServiceDateTime = DateTime.now();
  }

  /// Update paid amount to match the calculated total
  void _updatePaidAmountToTotal() {
    final calculations = _calculateTotals();
    _paidController.text = calculations['finalTotal']!.toStringAsFixed(2);
    _paidAmount = calculations['finalTotal'];
  }

  /// Calculate all totals matching backend logic:
  /// 1. Subtotal = sum of service prices
  /// 2. Discount Amount = Subtotal × (discount% / 100)
  /// 3. Amount After Discount = Subtotal - Discount Amount
  /// 4. Tax = Amount After Discount × 0.15 (15%)
  /// 5. Final Total = Amount After Discount + Tax
  Map<String, double> _calculateTotals() {
    final subtotal = widget.cart.fold<double>(
      0,
      (sum, item) => sum + item.price,
    );

    final discountPercentage = double.tryParse(_discountController.text) ?? 0.0;
    final discountAmount = subtotal * (discountPercentage / 100);
    final amountAfterDiscount = subtotal - discountAmount;
    final taxAmount = amountAfterDiscount * 0.15; // 15% tax
    final finalTotal = amountAfterDiscount + taxAmount;

    return {
      'subtotal': subtotal,
      'discountPercentage': discountPercentage,
      'discountAmount': discountAmount,
      'amountAfterDiscount': amountAfterDiscount,
      'taxAmount': taxAmount,
      'finalTotal': finalTotal,
    };
  }

  @override
  void dispose() {
    _discountController.dispose();
    _paidController.dispose();
    _cashierNameController.dispose();
    _orderNumberController.dispose();
    _branchNameController.dispose();
    super.dispose();
  }

  /// Get payment type for API from selected payment method name
  String _getPaymentTypeForApi(BuildContext context) {
    final state = context.read<CashierCubit>().state;
    if (state is CashierLoaded) {
      final method = state.paymentMethods.firstWhere(
        (m) => m.nameAr == _paymentMethod,
        orElse: () => state.paymentMethods.first,
      );
      return method.type;
    }
    // Map to backend payment_type values: 'cash', 'visa', 'bank'
    if (_paymentMethod == 'شبكة') return 'visa';
    if (_paymentMethod == 'تحويل') return 'bank';
    return 'cash';
  }

  // Future<void> _handlePrint() async {
  //   final pdfData = await generateInvoicePdf(
  //     customer: widget.customer,
  //     services: widget.cart,
  //     discount: _discount,
  //     cashierName: _cashierNameController.text,
  //     paymentMethod: _paymentMethod,
  //   );
  //   await Printing.layoutPdf(onLayout: (_) => pdfData);
  // }
  Future<bool> tryConnectToPrinter() async {
    try {
      final socket = await Socket.connect(
        '192.168.1.123',
        9100,
        timeout: const Duration(seconds: 3),
      );
      socket.destroy();
      return true;
    } catch (e) {
      print('❌ الطابعة غير متصلة: $e');
      return false;
    }
  }

  // Save invoice without printing
  Future<void> _handleSaveOnly() async {
    if (_isSaving) return;

    setState(() => _isSaving = true);

    try {
      // Calculate totals locally (matching backend logic)
      final calculations = _calculateTotals();
      final subtotal = calculations['subtotal']!;
      final discountPercentage = calculations['discountPercentage']!;
      final discountAmount = calculations['discountAmount']!;
      final taxAmount = calculations['taxAmount']!;
      final finalTotal = calculations['finalTotal']!;
      final paidAmount = double.tryParse(_paidController.text) ?? finalTotal;

      print('💰 Invoice Submission (Calculated in App):');
      print('  Subtotal: $subtotal');
      print('  Discount %: $discountPercentage');
      print('  Discount Amount: $discountAmount');
      print('  Amount After Discount: ${calculations['amountAfterDiscount']}');
      print('  Tax (15%): $taxAmount');
      print('  Final Total: $finalTotal');
      print('  Paid Amount: $paidAmount');

      // Get payment type from payment methods
      final apiPaymentType = _getPaymentTypeForApi(context);

      // Submit to API with calculated values
      final invoice = await context.read<CashierCubit>().submitInvoice(
        paymentType: apiPaymentType,
        tax: 0, // Backend will calculate, but we've already shown user
        discount: discountPercentage, // Send as percentage
        paid: paidAmount,
      );

      if (invoice != null && mounted) {
        print('✅ Invoice saved with calculated values:');
        print(
          '  Subtotal Before Tax: ${invoice.subtotalBeforeTax ?? invoice.subtotal}',
        );
        print('  Tax Amount: ${invoice.taxAmount ?? invoice.tax}');
        print('  Total After Tax: ${invoice.totalAfterTax}');
        print(
          '  Discount Amount: ${invoice.discountAmount ?? invoice.discount}',
        );
        print('  Final Total: ${invoice.finalTotal ?? invoice.total}');
        print('  Paid Amount: ${invoice.paidAmount}');
        print('  Remaining Amount: ${invoice.remainingAmount}');

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('✅ تم حفظ الفاتورة بنجاح'),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.of(context).pop();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('❌ فشل حفظ الفاتورة: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isSaving = false);
      }
    }
  }

  // Save and print invoice
  Future<void> _handleSaveAndPrint() async {
    if (_isSaving) return;

    setState(() => _isSaving = true);

    try {
      // Calculate totals locally (matching backend logic)
      final calculations = _calculateTotals();
      final subtotal = calculations['subtotal']!;
      final discountPercentage = calculations['discountPercentage']!;
      final discountAmount = calculations['discountAmount']!;
      final taxAmount = calculations['taxAmount']!;
      final finalTotal = calculations['finalTotal']!;
      final paidAmount = double.tryParse(_paidController.text) ?? finalTotal;

      print('💰 Invoice Submission (Save & Print - Calculated in App):');
      print('  Subtotal: $subtotal');
      print('  Discount %: $discountPercentage');
      print('  Discount Amount: $discountAmount');
      print('  Amount After Discount: ${calculations['amountAfterDiscount']}');
      print('  Tax (15%): $taxAmount');
      print('  Final Total: $finalTotal');
      print('  Paid Amount: $paidAmount');

      // First save the invoice
      final apiPaymentType = _getPaymentTypeForApi(context);

      final invoice = await context.read<CashierCubit>().submitInvoice(
        paymentType: apiPaymentType,
        tax: 0, // Backend will calculate
        discount: discountPercentage,
        paid: paidAmount,
      );

      if (invoice == null) {
        throw Exception('فشل في حفظ الفاتورة');
      }

      print('✅ Invoice saved with calculated values:');
      print(
        '  Subtotal Before Tax: ${invoice.subtotalBeforeTax ?? invoice.subtotal}',
      );
      print('  Tax Amount: ${invoice.taxAmount ?? invoice.tax}');
      print('  Total After Tax: ${invoice.totalAfterTax}');
      print('  Discount Amount: ${invoice.discountAmount ?? invoice.discount}');
      print('  Final Total: ${invoice.finalTotal ?? invoice.total}');
      print('  Paid Amount: ${invoice.paidAmount}');
      print('  Remaining Amount: ${invoice.remainingAmount}');

      // Fetch print data from API
      final printData = await context.read<CashierCubit>().getPrintData(
        invoice.id,
      );

      if (printData == null) {
        throw Exception('فشل في جلب بيانات الطباعة');
      }

      // Then print using API data
      await _handlePrintWithApiData(printData);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('✅ تم حفظ وطباعة الفاتورة بنجاح'),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.of(context).pop();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('❌ خطأ: $e'), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isSaving = false);
      }
    }
  }

  /// Print invoice using data from API
  Future<void> _handlePrintWithApiData(Map<String, dynamic> printData) async {
    try {
      print('📄 Printing with API data: $printData');

      // Extract customer data from API response
      final customerData = printData['customer'] as Map<String, dynamic>?;
      final customer = customerData != null
          ? Customer(
              id: int.tryParse(printData['order_id']?.toString() ?? '0') ?? 0,
              name: customerData['name'] ?? 'غير محدد',
              phone: customerData['mobile'] ?? '',
            )
          : null;

      // Extract items data from API response
      final itemsData = printData['items'] as List<dynamic>? ?? [];
      final services = itemsData.map((item) {
        return ServiceModel(
          id: int.tryParse(item['product_id']?.toString() ?? '0') ?? 0,
          name: item['product_name'] ?? 'خدمة',
          price: (item['price'] as num?)?.toDouble() ?? 0.0,
          category: 'عام',
          image: '',
          barber: item['employee_name'],
        );
      }).toList();

      // Extract order details matching backend structure
      final orderNumber =
          printData['order_id']?.toString() ??
          printData['invoice_number']?.toString() ??
          '';
      final discountPercentage =
          (printData['discount_percentage'] as num?)?.toDouble() ??
          (printData['discount'] as num?)?.toDouble() ??
          0.0;
      final cashierName =
          printData['employee']?['name'] ?? _cashierNameController.text;
      final paid = (printData['paid'] as num?)?.toDouble();
      final remaining =
          (printData['remaining'] as num?)?.toDouble() ??
          (printData['due'] as num?)?.toDouble();

      // Extract payment method from API response (backend uses payment_type)
      final paymentMethodFromApi =
          printData['payment_type']?.toString() ??
          printData['payment_method']?.toString();
      final paymentMethod = paymentMethodFromApi ?? _paymentMethod;

      print('💳 Payment Method Debug:');
      print('  From API: $paymentMethodFromApi');
      print('  From Local: $_paymentMethod');
      print('  Using: $paymentMethod');

      // Extract API-calculated values matching NEW backend structure
      // Backend now returns: subtotal, discount_percentage, discount_amount,
      // amount_after_discount, tax_rate, tax_amount, total, paid, due
      final apiSubtotal = (printData['subtotal'] as num?)?.toDouble();
      final apiTaxAmount =
          (printData['tax_amount'] as num?)?.toDouble() ??
          (printData['tax'] as num?)?.toDouble() ??
          (printData['tax_value'] as num?)?.toDouble();
      final apiDiscountAmount =
          (printData['discount_amount'] as num?)?.toDouble() ??
          (printData['discount'] as num?)?.toDouble();
      final apiGrandTotal = (printData['total'] as num?)?.toDouble();

      print('💰 Receipt Values Debug (from backend):');
      print('  Subtotal: $apiSubtotal');
      print('  Discount %: $discountPercentage');
      print('  Discount Amount: $apiDiscountAmount');
      print('  Tax: $apiTaxAmount');
      print('  Discount: $apiDiscountAmount');
      print('  Total: $apiGrandTotal');
      print('  Paid: $paid');
      print('  Remaining/Due: $remaining');

      final connected = await tryConnectToPrinter();
      if (connected) {
        await printInvoiceDirect(
          customer: customer,
          services: services,
          discount:
              discountPercentage, // Pass percentage for fallback calculation
          cashierName: cashierName,
          paymentMethod: paymentMethod, // Use API payment method
          orderNumber: orderNumber,
          branchName: _branchNameController.text,
          paid: paid,
          remaining: remaining,
          // Pass API values for consistent calculation
          apiSubtotal: apiSubtotal,
          apiTaxAmount: apiTaxAmount,
          apiDiscountAmount: apiDiscountAmount,
          apiGrandTotal: apiGrandTotal,
        );
      } else {
        final pdfData = await generateInvoicePdf(
          customer: customer,
          services: services,
          discount:
              discountPercentage, // Pass percentage for fallback calculation
          cashierName: cashierName,
          paymentMethod: paymentMethod, // Use API payment method
          // Pass API values for accurate PDF
          apiSubtotal: apiSubtotal,
          apiTaxAmount: apiTaxAmount,
          apiDiscountAmount: apiDiscountAmount,
          apiGrandTotal: apiGrandTotal,
          // apiDiscountAmount: apiDiscountAmount,
          // apiGrandTotal: apiGrandTotal,
        );
        await Printing.layoutPdf(onLayout: (_) => pdfData);
      }

      print('✅ Print completed successfully with API data');
    } catch (e) {
      print('❌ Error printing with API data: $e');
      rethrow;
    }
  }

  // Date and Time Picker
  Future<void> _selectServiceDateTime() async {
    final DateTime? pickedDate = await showDatePicker(
      context: context,
      initialDate: _selectedServiceDateTime ?? DateTime.now(),
      firstDate: DateTime.now().subtract(const Duration(days: 30)),
      lastDate: DateTime.now().add(const Duration(days: 365)),
      locale: const Locale('ar', 'SA'),
    );

    if (pickedDate != null && mounted) {
      final TimeOfDay? pickedTime = await showTimePicker(
        context: context,
        initialTime: TimeOfDay.fromDateTime(
          _selectedServiceDateTime ?? DateTime.now(),
        ),
      );

      if (pickedTime != null && mounted) {
        setState(() {
          _selectedServiceDateTime = DateTime(
            pickedDate.year,
            pickedDate.month,
            pickedDate.day,
            pickedTime.hour,
            pickedTime.minute,
          );
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    // Calculate totals using the same logic as backend
    final calculations = _calculateTotals();
    final subtotal = calculations['subtotal']!;
    final discountAmount = calculations['discountAmount']!;
    final amountAfterDiscount = calculations['amountAfterDiscount']!;
    final taxAmount = calculations['taxAmount']!;
    final finalTotal = calculations['finalTotal']!;

    // Use calculated values for display
    final paidAmount = _paidAmount ?? finalTotal;
    final remainingAmount = finalTotal - paidAmount;

    return Scaffold(
      appBar: AppBar(
        title: Text("إصدار الفاتورة", style: theme.appBarTheme.titleTextStyle),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _buildInfoSection(theme),
            const SizedBox(height: 24),
            _buildServicesTable(theme),
            const SizedBox(height: 24),
            _buildTotalsSection(
              theme,
              subtotal,
              taxAmount,
              amountAfterDiscount,
              discountAmount,
              finalTotal,
              paidAmount,
              remainingAmount,
              false, // showEstimateNote removed
            ),
            const SizedBox(height: 32),
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    icon: _isSaving
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                        : const Icon(Icons.save_outlined),
                    label: const Text("حفظ الفاتورة"),
                    style: theme.elevatedButtonTheme.style?.copyWith(
                      minimumSize: MaterialStateProperty.all(
                        const Size(double.infinity, 50),
                      ),
                      backgroundColor: MaterialStateProperty.all(Colors.blue),
                    ),
                    onPressed: _isSaving ? null : _handleSaveOnly,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton.icon(
                    icon: _isSaving
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                        : const Icon(Icons.print_outlined),
                    label: const Text("حفظ وطباعة"),
                    style: theme.elevatedButtonTheme.style?.copyWith(
                      minimumSize: MaterialStateProperty.all(
                        const Size(double.infinity, 50),
                      ),
                    ),
                    onPressed: _isSaving ? null : _handleSaveAndPrint,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoSection(ThemeData theme) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text("تفاصيل الفاتورة", style: theme.textTheme.titleLarge),
            const Divider(height: 24),
            _buildInfoRow(
              theme,
              "رقم الطلب:",
              null,
              controller: _orderNumberController,
            ),
            _buildInfoRow(
              theme,
              "العميل:",
              widget.customer?.name ?? "عميل كاش",
            ),
            _buildInfoRow(
              theme,
              "التاريخ:",
              DateFormat('yyyy-MM-dd').format(DateTime.now()),
            ),
            _buildInfoRow(
              theme,
              "الكاشير:",
              null,
              controller: _cashierNameController,
            ),
            _buildInfoRow(
              theme,
              "الفرع:",
              null,
              controller: _branchNameController,
            ),
            _buildInfoRow(
              theme,
              "طريقة الدفع:",
              null,
              dropdown: _buildPaymentDropdown(),
            ),
            const SizedBox(height: 8),
            _buildServiceDateTimeRow(theme),
          ],
        ),
      ),
    );
  }

  Widget _buildServicesTable(ThemeData theme) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.only(top: 16, right: 16, left: 16),
            child: Text("الخدمات", style: theme.textTheme.titleLarge),
          ),
          const Divider(height: 24),
          Table(
            columnWidths: const {
              0: FlexColumnWidth(3),
              1: FlexColumnWidth(2),
              2: FlexColumnWidth(1.5),
            },
            children: [
              TableRow(
                decoration: BoxDecoration(
                  border: Border(
                    bottom: BorderSide(
                      color: theme.dividerColor.withOpacity(0.5),
                    ),
                  ),
                ),
                children: [
                  Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: Text("الخدمة", style: theme.textTheme.titleSmall),
                  ),
                  Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: Text("الحلاق", style: theme.textTheme.titleSmall),
                  ),
                  Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: Text(
                      "السعر",
                      style: theme.textTheme.titleSmall,
                      textAlign: TextAlign.right,
                    ),
                  ),
                ],
              ),
              ...widget.cart.map(
                (service) => TableRow(
                  children: [
                    Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: Text(service.name),
                    ),
                    Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: Text(service.barber ?? 'N/A'),
                    ),
                    Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: Text(
                        "${service.price.toStringAsFixed(2)} ر.س",
                        textAlign: TextAlign.right,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
        ],
      ),
    );
  }

  Widget _buildTotalsSection(
    ThemeData theme,
    double subtotal,
    double taxAmount,
    double amountAfterDiscount,
    double discountAmount,
    double finalTotal,
    double paidAmount,
    double remainingAmount,
    bool showEstimateNote,
  ) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            // Step 1: Subtotal Before Tax and Discount
            _buildTotalRow(
              theme,
              "الإجمالي قبل الضريبة والخصم:",
              "${subtotal.toStringAsFixed(2)} ر.س",
            ),
            const SizedBox(height: 8),

            // Step 2: Discount Input
            _buildInfoRow(
              theme,
              "خصم (%):",
              null,
              controller: _discountController,
              isNumeric: true,
            ),
            const SizedBox(height: 8),

            // Step 3: Discount Amount (calculated)
            _buildTotalRow(
              theme,
              "مبلغ الخصم:",
              discountAmount > 0
                  ? "-${discountAmount.toStringAsFixed(2)} ر.س"
                  : "0.00 ر.س",
              color: discountAmount > 0 ? Colors.redAccent : Colors.grey,
            ),
            const SizedBox(height: 8),

            // Step 4: Amount After Discount (before tax)
            _buildTotalRow(
              theme,
              "المبلغ بعد الخصم:",
              "${amountAfterDiscount.toStringAsFixed(2)} ر.س",
              color: Colors.blue.shade700,
            ),
            const SizedBox(height: 8),

            // Step 5: Tax Amount (15% on amount after discount)
            _buildTotalRow(
              theme,
              "الضريبة (15%):",
              "${taxAmount.toStringAsFixed(2)} ر.س",
              color: taxAmount > 0 ? Colors.orange.shade700 : Colors.grey,
            ),
            const Divider(height: 24),

            // Step 6: Final Total
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text("الإجمالي النهائي:", style: theme.textTheme.titleLarge),
                Text(
                  "${finalTotal.toStringAsFixed(2)} ر.س",
                  style: theme.textTheme.titleLarge?.copyWith(
                    color: Colors.green.shade700,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Step 7: Paid Amount Input with "Pay in Full" button
            Row(
              children: [
                Expanded(
                  flex: 2,
                  child: Text(
                    "المبلغ المدفوع:",
                    style: theme.textTheme.titleMedium,
                  ),
                ),
                Expanded(
                  flex: 3,
                  child: Row(
                    children: [
                      Expanded(
                        child: TextFormField(
                          controller: _paidController,
                          textAlign: TextAlign.right,
                          keyboardType: const TextInputType.numberWithOptions(
                            decimal: true,
                          ),
                          decoration: const InputDecoration(
                            isDense: true,
                            border: OutlineInputBorder(),
                            hintText: '0.00',
                          ),
                          onChanged: (value) {
                            setState(() {
                              _paidAmount = double.tryParse(value);
                            });
                          },
                        ),
                      ),
                      const SizedBox(width: 8),
                      ElevatedButton(
                        onPressed: () {
                          setState(() {
                            _paidAmount = finalTotal;
                            _paidController.text = finalTotal.toStringAsFixed(
                              2,
                            );
                          });
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.green,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 16,
                          ),
                        ),
                        child: const Text(
                          'دفع كامل',
                          style: TextStyle(fontSize: 12),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const Divider(height: 24),

            // Step 8: Remaining Amount Display
            if (remainingAmount > 0.01) // Customer owes money
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.orange.shade50,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.orange.shade200),
                ),
                child: _buildTotalRow(
                  theme,
                  "الباقي:",
                  "${remainingAmount.toStringAsFixed(2)} ر.س",
                  color: Colors.orange.shade700,
                  isBold: true,
                ),
              )
            else if (remainingAmount < -0.01) // Change to return
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.green.shade50,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.green.shade200),
                ),
                child: _buildTotalRow(
                  theme,
                  "الباقي (يُرجع للعميل):",
                  "${(-remainingAmount).toStringAsFixed(2)} ر.س",
                  color: Colors.green.shade700,
                  isBold: true,
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildPaymentDropdown() {
    return BlocBuilder<CashierCubit, CashierState>(
      builder: (context, state) {
        // Default fallback items
        final defaultMethods = <String>['نقدي', 'شبكة', 'تحويل'];

        if (state is! CashierLoaded) {
          // Ensure _paymentMethod is in default list
          if (!defaultMethods.contains(_paymentMethod)) {
            _paymentMethod = defaultMethods.first;
          }
          return DropdownButtonFormField<String>(
            value: _paymentMethod,
            decoration: const InputDecoration(
              isDense: true,
              border: OutlineInputBorder(),
            ),
            onChanged: null,
            items: defaultMethods.map<DropdownMenuItem<String>>((String value) {
              return DropdownMenuItem<String>(value: value, child: Text(value));
            }).toList(),
          );
        }

        // Get payment methods from state and remove duplicates by nameAr
        final paymentMethods = state.paymentMethods;

        // Debug logging
        print('🔍 Payment Methods Debug:');
        print('  Total from API: ${paymentMethods.length}');
        for (var i = 0; i < paymentMethods.length; i++) {
          print(
            '  [$i] id=${paymentMethods[i].id}, nameAr="${paymentMethods[i].nameAr}", type=${paymentMethods[i].type}',
          );
        }

        // Create unique list by nameAr (keep first occurrence)
        final seenNames = <String>{};
        final uniqueMethods = <PaymentMethod>[];
        for (final method in paymentMethods) {
          if (!seenNames.contains(method.nameAr)) {
            seenNames.add(method.nameAr);
            uniqueMethods.add(method);
          } else {
            print(
              '  ⚠️ Skipping duplicate: "${method.nameAr}" (id=${method.id})',
            );
          }
        }

        print('  Unique methods: ${uniqueMethods.length}');
        print('  Unique names: ${uniqueMethods.map((m) => m.nameAr).toList()}');
        print('  Current selection: "$_paymentMethod"');

        // If no payment methods available, use defaults
        if (uniqueMethods.isEmpty) {
          if (!defaultMethods.contains(_paymentMethod)) {
            _paymentMethod = defaultMethods.first;
          }
          return DropdownButtonFormField<String>(
            value: _paymentMethod,
            decoration: const InputDecoration(
              isDense: true,
              border: OutlineInputBorder(),
            ),
            onChanged: (String? newValue) {
              if (newValue != null) {
                setState(() => _paymentMethod = newValue);
              }
            },
            items: defaultMethods.map<DropdownMenuItem<String>>((String value) {
              return DropdownMenuItem<String>(value: value, child: Text(value));
            }).toList(),
          );
        }

        // Check if current selection exists in unique methods
        final selectedExists = uniqueMethods.any(
          (m) => m.nameAr == _paymentMethod,
        );
        print('  Selection exists: $selectedExists');

        if (!selectedExists) {
          // Update to first method
          final newValue = uniqueMethods.first.nameAr;
          print('  Updating selection to: "$newValue"');

          // Schedule update for next frame
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (mounted) {
              setState(() {
                _paymentMethod = newValue;
              });
            }
          });

          // Return dropdown with the new value
          return DropdownButtonFormField<String>(
            value: newValue,
            decoration: const InputDecoration(
              isDense: true,
              border: OutlineInputBorder(),
            ),
            onChanged: (String? value) {
              if (value != null) {
                setState(() => _paymentMethod = value);
              }
            },
            items: uniqueMethods.map<DropdownMenuItem<String>>((method) {
              return DropdownMenuItem<String>(
                value: method.nameAr,
                child: Text(method.nameAr),
              );
            }).toList(),
          );
        }

        // Normal case: selection exists in list
        return DropdownButtonFormField<String>(
          value: _paymentMethod,
          decoration: const InputDecoration(
            isDense: true,
            border: OutlineInputBorder(),
          ),
          onChanged: (String? newValue) {
            if (newValue != null) {
              setState(() => _paymentMethod = newValue);
            }
          },
          items: uniqueMethods.map<DropdownMenuItem<String>>((method) {
            return DropdownMenuItem<String>(
              value: method.nameAr,
              child: Text(method.nameAr),
            );
          }).toList(),
        );
      },
    );
  }

  Widget _buildInfoRow(
    ThemeData theme,
    String label,
    String? value, {
    TextEditingController? controller,
    Widget? dropdown,
    bool isNumeric = false,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            flex: 2,
            child: Text(label, style: theme.textTheme.titleMedium),
          ),
          Expanded(
            flex: 3,
            child: controller != null
                ? TextFormField(
                    controller: controller,
                    textAlign: TextAlign.right,
                    keyboardType: isNumeric
                        ? const TextInputType.numberWithOptions(decimal: true)
                        : TextInputType.text,
                    decoration: const InputDecoration(
                      isDense: true,
                      border: OutlineInputBorder(),
                    ),
                  )
                : (dropdown ??
                      Text(value ?? '', style: theme.textTheme.bodyLarge)),
          ),
        ],
      ),
    );
  }

  Widget _buildTotalRow(
    ThemeData theme,
    String title,
    String value, {
    bool isBold = false,
    Color? color,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            flex: 3,
            child: Text(
              title,
              style: GoogleFonts.cairo(
                fontWeight: isBold ? FontWeight.bold : FontWeight.normal,
                fontSize: isBold ? 18 : 16,
                color: color,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
          const SizedBox(width: 8),
          Flexible(
            flex: 2,
            child: Text(
              value,
              style: GoogleFonts.cairo(
                fontWeight: FontWeight.bold,
                fontSize: isBold ? 18 : 16,
                color: color,
              ),
              textAlign: TextAlign.right,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildServiceDateTimeRow(ThemeData theme) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            flex: 2,
            child: Text("موعد الخدمة:", style: theme.textTheme.titleMedium),
          ),
          Expanded(
            flex: 3,
            child: InkWell(
              onTap: _selectServiceDateTime,
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 12,
                ),
                decoration: BoxDecoration(
                  border: Border.all(color: theme.dividerColor),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Text(
                        _selectedServiceDateTime != null
                            ? DateFormat(
                                'yyyy-MM-dd HH:mm',
                              ).format(_selectedServiceDateTime!)
                            : 'اختر التاريخ والوقت',
                        style: theme.textTheme.bodyLarge,
                        textAlign: TextAlign.right,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Icon(
                      Icons.calendar_today,
                      size: 20,
                      color: theme.primaryColor,
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
