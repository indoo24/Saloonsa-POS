import 'dart:io';

import 'package:barber_casher/screens/casher/print_dirct.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:printing/printing.dart';
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
  final _cashierNameController = TextEditingController(text: 'Yousef');
  final _orderNumberController = TextEditingController(text: '${DateTime.now().millisecondsSinceEpoch}');
  final _branchNameController = TextEditingController(text: 'الفرع الرئيسي');
  String _paymentMethod = 'نقدي';

  double _discount = 0.0;

  @override
  void initState() {
    super.initState();
    _discountController.addListener(() {
      setState(() {
        _discount = double.tryParse(_discountController.text) ?? 0.0;
      });
    });
  }

  @override
  void dispose() {
    _discountController.dispose();
    _cashierNameController.dispose();
    _orderNumberController.dispose();
    _branchNameController.dispose();
    super.dispose();
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
      final socket = await Socket.connect('192.168.1.123', 9100, timeout: const Duration(seconds: 3));
      socket.destroy();
      return true;
    } catch (e) {
      print('❌ الطابعة غير متصلة: $e');
      return false;
    }
  }
  Future<void> _handlePrint() async {
    try {
      final connected = await tryConnectToPrinter();
      if (connected) {
        await printInvoiceDirect(
          customer: widget.customer,
          services: widget.cart,
          discount: _discount,
          cashierName: _cashierNameController.text,
          paymentMethod: _paymentMethod,
          orderNumber: _orderNumberController.text,
          branchName: _branchNameController.text,
        );
      } else {
        final pdfData = await generateInvoicePdf(
          customer: widget.customer,
          services: widget.cart,
          discount: _discount,
          cashierName: _cashierNameController.text,
          paymentMethod: _paymentMethod,
        );
        await Printing.layoutPdf(onLayout: (_) => pdfData);
      }
    } catch (e) {
      print('حدث خطأ أثناء الطباعة: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final subtotal = widget.cart.fold<double>(0, (sum, item) => sum + item.price);
    final tax = subtotal * 0.15;
    final totalBeforeDiscount = subtotal + tax;
    final discountAmount = totalBeforeDiscount * (_discount / 100);
    final finalTotal = totalBeforeDiscount - discountAmount;

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
            _buildTotalsSection(theme, subtotal, tax, discountAmount, finalTotal),
            const SizedBox(height: 32),
            ElevatedButton.icon(
              icon: const Icon(Icons.print_outlined),
              label: const Text("طباعة الفاتورة"),
              style: theme.elevatedButtonTheme.style?.copyWith(
                minimumSize: MaterialStateProperty.all(const Size(double.infinity, 50)),
              ),
              onPressed: _handlePrint,
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
            _buildInfoRow(theme, "رقم الطلب:", null, controller: _orderNumberController),
            _buildInfoRow(theme, "العميل:", widget.customer?.name ?? "عميل كاش"),
            _buildInfoRow(theme, "التاريخ:", DateFormat('yyyy-MM-dd').format(DateTime.now())),
            _buildInfoRow(theme, "الكاشير:", null, controller: _cashierNameController),
            _buildInfoRow(theme, "الفرع:", null, controller: _branchNameController),
            _buildInfoRow(theme, "طريقة الدفع:", null, dropdown: _buildPaymentDropdown()),
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
                decoration: BoxDecoration(border: Border(bottom: BorderSide(color: theme.dividerColor.withOpacity(0.5)))),
                children: [
                  Padding(padding: const EdgeInsets.all(8.0), child: Text("الخدمة", style: theme.textTheme.titleSmall)),
                  Padding(padding: const EdgeInsets.all(8.0), child: Text("الحلاق", style: theme.textTheme.titleSmall)),
                  Padding(padding: const EdgeInsets.all(8.0), child: Text("السعر", style: theme.textTheme.titleSmall, textAlign: TextAlign.right)),
                ],
              ),
              ...widget.cart.map((service) => TableRow(
                children: [
                  Padding(padding: const EdgeInsets.all(8.0), child: Text(service.name)),
                  Padding(padding: const EdgeInsets.all(8.0), child: Text(service.barber ?? 'N/A')),
                  Padding(padding: const EdgeInsets.all(8.0), child: Text("${service.price.toStringAsFixed(2)} ر.س", textAlign: TextAlign.right)),
                ],
              )),
            ],
          ),
           const SizedBox(height: 8),
        ],
      ),
    );
  }
  
  Widget _buildTotalsSection(ThemeData theme, double subtotal, double tax, double discountAmount, double finalTotal) {
    return Card(
       elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            _buildTotalRow(theme, "الإجمالي الفرعي:", "${subtotal.toStringAsFixed(2)} ر.س"),
            const SizedBox(height: 8),
            _buildTotalRow(theme, "Tax (15%):", "${tax.toStringAsFixed(2)} ر.س"),
             const SizedBox(height: 8),
            _buildInfoRow(theme, "خصم (%):", null, controller: _discountController, isNumeric: true),
             const SizedBox(height: 8),
            if (_discount > 0)
              _buildTotalRow(theme, "مبلغ الخصم:", "-${discountAmount.toStringAsFixed(2)} ر.س", color: Colors.redAccent),
            const Divider(height: 24),
            _buildTotalRow(theme, "الإجمالي النهائي:", "${finalTotal.toStringAsFixed(2)} ر.س", isBold: true),
          ],
        ),
      ),
    );
  }

  Widget _buildPaymentDropdown() {
    return DropdownButtonFormField<String>(
      value: _paymentMethod,
      decoration: const InputDecoration(isDense: true, border: OutlineInputBorder()),
      onChanged: (String? newValue) {
        if (newValue != null) {
          setState(() => _paymentMethod = newValue);
        }
      },
      items: <String>['نقدي', 'شبكة', 'تحويل'].map<DropdownMenuItem<String>>((String value) {
        return DropdownMenuItem<String>(value: value, child: Text(value));
      }).toList(),
    );
  }

  Widget _buildInfoRow(ThemeData theme, String label, String? value, {TextEditingController? controller, Widget? dropdown, bool isNumeric = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(flex: 2, child: Text(label, style: theme.textTheme.titleMedium)),
          Expanded(flex: 3, child: controller != null
            ? TextFormField(
                controller: controller, 
                textAlign: TextAlign.right,
                keyboardType: isNumeric ? const TextInputType.numberWithOptions(decimal: true) : TextInputType.text,
                decoration: const InputDecoration(isDense: true, border: OutlineInputBorder()),
              )
            : (dropdown ?? Text(value ?? '', style: theme.textTheme.bodyLarge))),
        ],
      ),
    );
  }

  Widget _buildTotalRow(ThemeData theme, String title, String value, {bool isBold = false, Color? color}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(title, style: GoogleFonts.cairo(fontWeight: isBold ? FontWeight.bold : FontWeight.normal, fontSize: isBold ? 18 : 16, color: color)),
          Text(value, style: GoogleFonts.cairo(fontWeight: FontWeight.bold, fontSize: isBold ? 18 : 16, color: color)),
        ],
      ),
    );
  }
}
