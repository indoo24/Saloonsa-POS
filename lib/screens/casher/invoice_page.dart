import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:printing/printing.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:esc_pos_utils_plus/esc_pos_utils_plus.dart' as esc_pos;
import '../../cubits/cashier/cashier_cubit.dart';
import '../../cubits/cashier/cashier_state.dart';
import '../../models/payment_method.dart';
import '../../models/printer_settings.dart' as models;
import '../../helpers/invoice_data_mapper.dart';
import '../../services/settings_service.dart';
import '../../screens/printing/thermal_preview_screen.dart';
import 'thermal_receipt_pdf_generator.dart';
import 'models/customer.dart';
import 'models/service-model.dart';
import 'services/printer_service.dart';

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
    text: 'سيتم إنشاؤه تلقائياً',
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

  /// Convert from models.PaperSize to esc_pos.PaperSize
  esc_pos.PaperSize _convertToEscPosPaperSize(models.PaperSize paperSize) {
    switch (paperSize) {
      case models.PaperSize.mm58:
        return esc_pos.PaperSize.mm58;
      case models.PaperSize.mm80:
        return esc_pos.PaperSize.mm80;
      case models.PaperSize.a4:
        return esc_pos.PaperSize.mm80; // Default A4 to 80mm for thermal
    }
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

  /// Check if a printer is connected via PrinterService
  /// This properly handles WiFi, Bluetooth, and USB printers
  bool isPrinterConnected() {
    final printerService = PrinterService();
    final isConnected = printerService.connectedPrinter != null;

    print('🔌 Printer Connection Status: $isConnected');
    if (isConnected) {
      final printer = printerService.connectedPrinter!;
      print('  Printer: ${printer.name}');
      print('  Type: ${printer.type}');
      print('  Address: ${printer.address}');
    } else {
      print(
        '  ⚠️ No printer connected. Please connect a printer from Settings.',
      );
    }

    return isConnected;
  }

  // Preview thermal receipt as PDF - First saves to API, then fetches data for preview
  Future<void> _handlePreviewReceipt() async {
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

      print('💰 Invoice Submission for Preview (Calculated in App):');
      print('  Subtotal: $subtotal');
      print('  Discount %: $discountPercentage');
      print('  Discount Amount: $discountAmount');
      print('  Amount After Discount: ${calculations['amountAfterDiscount']}');
      print('  Tax (15%): $taxAmount');
      print('  Final Total: $finalTotal');
      print('  Paid Amount: $paidAmount');

      // First save the invoice to get API data
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

      print('✅ Invoice saved for preview:');
      print('  Invoice Number: ${invoice.invoiceNumber}');
      print('  Invoice ID: ${invoice.id}');

      // Update order number field with invoice number from API
      setState(() {
        _orderNumberController.text = invoice.invoiceNumber.toString();
      });

      // Fetch print data from API
      print('📡 Fetching print data from API for invoice ID: ${invoice.id}');
      final printData = await context.read<CashierCubit>().getPrintData(
        invoice.id,
      );

      if (printData == null) {
        throw Exception('فشل في جلب بيانات الطباعة من API');
      }

      print('✅ Print data received from API');
      print('  Order ID: ${printData['order_id']}');
      print('  Invoice Number: ${printData['invoice_number']}');
      print('  Subtotal: ${printData['subtotal']}');
      print('  Tax: ${printData['tax_amount'] ?? printData['tax']}');
      print('  Total: ${printData['total']}');

      // Get settings for business info
      final settingsService = SettingsService();
      final settings = await settingsService.loadSettings();

      // Create invoice data from API response
      final invoiceData = InvoiceDataMapper.fromApiPrintData(
        printData,
        branchName: _branchNameController.text,
        businessName: settings.businessName,
        businessAddress: settings.address,
        businessPhone: settings.phoneNumber,
        taxNumber: settings.taxNumber.isEmpty ? null : settings.taxNumber,
        logoPath: 'assets/images/logo.png',
      );

      print('📄 Generating PDF from API data...');

      // Generate PDF from API data
      final pdfBytes =
          await ThermalReceiptPdfGenerator.generateThermalReceiptPdf(
            data: invoiceData,
          );

      print('✅ PDF generated successfully');

      // Display PDF preview using printing package
      if (!mounted) return;

      await Printing.layoutPdf(
        onLayout: (format) => pdfBytes,
        name: 'thermal_receipt_${invoiceData.orderNumber}.pdf',
      );

      print('📱 PDF preview opened');

      // Show success message
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('✅ تم حفظ الفاتورة ومعاينتها بنجاح'),
            backgroundColor: Colors.green,
            duration: Duration(seconds: 2),
          ),
        );
      }
    } catch (e) {
      print('❌ Error in preview: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('❌ خطأ في معاينة الفاتورة: $e'),
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
        print('  Invoice Number: ${invoice.invoiceNumber}');
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

        // Update order number field with invoice number from API
        setState(() {
          _orderNumberController.text = invoice.invoiceNumber.toString();
        });

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

  // ════════════════════════════════════════════════════════════════════════════
  // PRODUCTION-GRADE SAVE & PRINT WORKFLOW
  // ════════════════════════════════════════════════════════════════════════════
  //
  // STRICT FLOW (NON-NEGOTIABLE):
  // 1. Save invoice to backend (if fails → STOP)
  // 2. Navigate to ThermalPreviewScreen (user sees exact receipt)
  // 3. User confirms and presses "Print Receipt" button
  // 4. Attempt thermal printing (PRIMARY PATH)
  // 5. If thermal fails → automatic PDF fallback (SAFETY NET)
  // ════════════════════════════════════════════════════════════════════════════

  Future<void> _handleSaveAndPrint() async {
    if (_isSaving) return;

    setState(() => _isSaving = true);

    try {
      // ═══ STEP 1: SAVE INVOICE ═══
      print('═══════════════════════════════════════════');
      print('STEP 1: SAVING INVOICE TO BACKEND');
      print('═══════════════════════════════════════════');

      final calculations = _calculateTotals();
      final discountPercentage = calculations['discountPercentage']!;
      final finalTotal = calculations['finalTotal']!;
      final paidAmount = double.tryParse(_paidController.text) ?? finalTotal;

      final apiPaymentType = _getPaymentTypeForApi(context);

      final invoice = await context.read<CashierCubit>().submitInvoice(
        paymentType: apiPaymentType,
        tax: 0, // Backend calculates
        discount: discountPercentage,
        paid: paidAmount,
      );

      if (invoice == null) {
        throw Exception('فشل في حفظ الفاتورة');
      }

      print('✅ Invoice saved successfully');
      print('   Invoice Number: ${invoice.invoiceNumber}');
      print('   Invoice ID: ${invoice.id}');

      // Update order number field
      setState(() {
        _orderNumberController.text = invoice.invoiceNumber.toString();
      });

      // ═══ STEP 2: FETCH PRINT DATA FROM API ═══
      print('═══════════════════════════════════════════');
      print('STEP 2: FETCHING PRINT DATA FROM API');
      print('═══════════════════════════════════════════');

      final printData = await context.read<CashierCubit>().getPrintData(
        invoice.id,
      );

      if (printData == null) {
        throw Exception('فشل في جلب بيانات الطباعة من API');
      }

      print('✅ Print data received from API');
      print('   Order ID: ${printData['order_id']}');
      print('   Invoice Number: ${printData['invoice_number']}');

      // ═══ STEP 3: CREATE INVOICE DATA ═══
      final settingsService = SettingsService();
      final settings = await settingsService.loadSettings();

      final invoiceData = InvoiceDataMapper.fromApiPrintData(
        printData,
        branchName: _branchNameController.text,
        businessName: settings.businessName,
        businessAddress: settings.address,
        businessPhone: settings.phoneNumber,
        taxNumber: settings.taxNumber.isEmpty ? null : settings.taxNumber,
        logoPath: 'assets/images/logo.png',
      );

      print('✅ InvoiceData created');

      // ═══ STEP 4: NAVIGATE TO PREVIEW SCREEN ═══
      print('═══════════════════════════════════════════');
      print('STEP 3: OPENING PREVIEW SCREEN');
      print('═══════════════════════════════════════════');

      if (!mounted) return;

      // Get paper size from printer settings and convert to ESC/POS enum
      final printerService = PrinterService();
      final settingsPaperSize = printerService.settings.paperSize;

      // Convert from models.PaperSize to esc_pos.PaperSize
      final escPosPaperSize = _convertToEscPosPaperSize(settingsPaperSize);

      // Navigate to preview screen (user will confirm printing there)
      await Navigator.of(context).push(
        MaterialPageRoute(
          builder: (context) => ThermalPreviewScreen(
            invoiceData: invoiceData,
            paperSize: escPosPaperSize,
          ),
        ),
      );

      print('✅ Returned from preview screen');

      // ═══ STEP 5: CLOSE INVOICE PAGE ═══
      // After returning from preview (whether printed or not), close invoice page
      if (mounted) {
        Navigator.of(context).pop();
      }
    } catch (e, stackTrace) {
      print('❌ Error in save & print workflow: $e');
      print('Stack trace: $stackTrace');

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('❌ خطأ: $e'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 4),
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isSaving = false);
      }
    }
  }

  // ════════════════════════════════════════════════════════════════════════════
  // OLD PRINT METHOD (DEPRECATED - KEPT FOR REFERENCE)
  // ════════════════════════════════════════════════════════════════════════════
  // This method is replaced by the new production-grade workflow in _handleSaveAndPrint
  // which navigates to ThermalPreviewScreen for user confirmation before printing.
  // ════════════════════════════════════════════════════════════════════════════

  /*
  /// Print invoice using data from API
  /// Returns true if thermal (direct) print was used, false if PDF dialog was shown
  Future<bool> _handlePrintWithApiData(Map<String, dynamic> printData) async {
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
      // IMPORTANT: Use invoice_number (same as website) instead of order_id
      final orderNumber =
          printData['invoice_number']?.toString() ??
          printData['order_id']?.toString() ??
          '';
      
      print('📋 Invoice Number Debug:');
      print('  invoice_number from API: ${printData['invoice_number']}');
      print('  order_id from API: ${printData['order_id']}');
      print('  Using orderNumber: $orderNumber');
      
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

      // Check paper size setting from printer service
      final printerService = PrinterService();
      final paperSize = printerService.settings.paperSize;

      print('📄 Paper Size Setting: ${paperSize.displayName}');

      // Check if printer is connected
      final connected = isPrinterConnected();

      if (connected) {
        // Create InvoiceData from API response for consistent formatting
        print('🖨️ Printing to thermal printer using InvoiceData (matches PDF format)');
        
        final settingsService = SettingsService();
        final settings = await settingsService.loadSettings();
        
        final invoiceData = InvoiceDataMapper.fromApiPrintData(
          printData,
          branchName: _branchNameController.text,
          businessName: settings.businessName,
          businessAddress: settings.address,
          businessPhone: settings.phoneNumber,
          taxNumber: settings.taxNumber.isEmpty ? null : settings.taxNumber,
          logoPath: 'assets/images/logo.png',
        );
        
        // Print using the new method that matches PDF format
        print('⏰ BEFORE PRINT CALL - Time: ${DateTime.now()}');
        final printSuccess = await printInvoiceDirectFromData(data: invoiceData);
        print('⏰ AFTER PRINT CALL - Time: ${DateTime.now()}, Success: $printSuccess');
        
        if (!printSuccess) {
          print('⚠️ Thermal print failed, but continuing...');
        }
        
        return true; // Thermal/direct print - can close invoice page
      } else {
        // Fallback to PDF if printer not connected
        print('⚠️ Printer not connected, opening PDF dialog');
        final pdfData = await generateInvoicePdf(
          customer: customer,
          services: services,
          discount: discountPercentage,
          cashierName: cashierName,
          paymentMethod: paymentMethod,
          invoiceNumber: orderNumber,
          apiSubtotal: apiSubtotal,
          apiTaxAmount: apiTaxAmount,
          apiDiscountAmount: apiDiscountAmount,
          apiGrandTotal: apiGrandTotal,
        );
        await Printing.layoutPdf(onLayout: (_) => pdfData);
        return false; // PDF dialog shown - must stay on page
      }
    } catch (e) {
      print('❌ Error printing with API data: $e');
      rethrow;
    }
  }
  */

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
            // Preview Receipt Button
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                icon: _isSaving
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.visibility_outlined),
                label: Text(
                  _isSaving
                      ? "جاري الحفظ والمعاينة..."
                      : "حفظ ومعاينة الفاتورة",
                ),
                style: OutlinedButton.styleFrom(
                  minimumSize: const Size(double.infinity, 50),
                  foregroundColor: theme.primaryColor,
                  side: BorderSide(color: theme.primaryColor, width: 2),
                ),
                onPressed: _isSaving ? null : _handlePreviewReceipt,
              ),
            ),
            const SizedBox(height: 12),
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
              "رقم الفاتورة:",
              null,
              controller: _orderNumberController,
              isReadOnly: true,
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
    bool isReadOnly = false,
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
                    readOnly: isReadOnly,
                    keyboardType: isNumeric
                        ? const TextInputType.numberWithOptions(decimal: true)
                        : TextInputType.text,
                    decoration: InputDecoration(
                      isDense: true,
                      border: const OutlineInputBorder(),
                      filled: isReadOnly,
                      fillColor: isReadOnly ? Colors.grey.shade100 : null,
                    ),
                    style: isReadOnly
                        ? TextStyle(color: Colors.grey.shade600)
                        : null,
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
