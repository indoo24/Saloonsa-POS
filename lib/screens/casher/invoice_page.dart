import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:printing/printing.dart';
import 'models/service-model.dart';
import 'pdf_invoice.dart';

class InvoicePage extends StatefulWidget {
  final List<ServiceModel> cart;
  const InvoicePage({super.key, required this.cart});

  @override
  State<InvoicePage> createState() => _InvoicePageState();
}

class _InvoicePageState extends State<InvoicePage> {
  final _discountController = TextEditingController();
  double _discountPercentage = 0.0;

  @override
  void initState() {
    super.initState();
    _discountController.addListener(_onDiscountChanged);
  }

  @override
  void dispose() {
    _discountController.removeListener(_onDiscountChanged);
    _discountController.dispose();
    super.dispose();
  }

  void _onDiscountChanged() {
    setState(() {
      _discountPercentage = double.tryParse(_discountController.text) ?? 0.0;
    });
  }

  IconData _getIconForService(String serviceName) {
    // ... (keep the same icon logic)
    return Icons.cut;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final subtotal = widget.cart.fold<double>(0, (sum, item) => sum + item.price);
    final tax = subtotal * 0.15;
    final totalBeforeDiscount = subtotal + tax;
    final discountAmount = totalBeforeDiscount * (_discountPercentage / 100);
    final finalTotal = totalBeforeDiscount - discountAmount;

    return Scaffold(
      appBar: AppBar(
        title: Text("الفاتورة 💵", style: theme.appBarTheme.titleTextStyle),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            Expanded(
              child: Card(
                child: ListView.builder(
                  itemCount: widget.cart.length,
                  itemBuilder: (context, index) {
                    final service = widget.cart[index];
                    return ListTile(
                      leading: Icon(_getIconForService(service.name), color: theme.colorScheme.secondary),
                      title: Text(service.name, style: theme.textTheme.bodyLarge),
                      trailing: Text(
                        "${service.price.toStringAsFixed(0)} ر.س",
                        style: GoogleFonts.cairo(
                          fontWeight: FontWeight.bold,
                          color: theme.colorScheme.secondary,
                        ),
                      ),
                    );
                  },
                ),
              ),
            ),
            const SizedBox(height: 16),
            _buildTotalsCard(
              context,
              subtotal: subtotal,
              tax: tax,
              discountAmount: discountAmount,
              finalTotal: finalTotal,
            ),
            const SizedBox(height: 20),
            ElevatedButton.icon(

              icon: const Icon(Icons.print_outlined),
              label: const Text("حفظ وطباعة الفاتورة"),
              style: theme.elevatedButtonTheme.style?.copyWith(
                backgroundColor: MaterialStateProperty.all(Colors.green[800]),

                minimumSize: MaterialStateProperty.all(const Size(double.infinity, 50)),
              ),
              onPressed: () async {
                // TODO: Pass discount info to PDF if needed
                final pdfData = await generateInvoicePdf(widget.cart);
                await Printing.layoutPdf(onLayout: (_) => pdfData);
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTotalsCard(BuildContext context, {
    required double subtotal,
    required double tax,
    required double discountAmount,
    required double finalTotal,
  }) {
    final theme = Theme.of(context);
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            _buildTotalRow(context, "الإجمالي الفرعي:", "${subtotal.toStringAsFixed(2)} ر.س"),
            const SizedBox(height: 12),
            _buildTotalRow(context, "الضريبة (15%):", "${tax.toStringAsFixed(2)} ر.س"),
            const SizedBox(height: 12),
            TextField(
              controller: _discountController,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              decoration: InputDecoration(
                labelText: 'نسبة الخصم',
                suffixText: '%',
                border: const OutlineInputBorder(),
                contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              ),
            ),
            const Divider(height: 24),
            AnimatedSwitcher(
              duration: const Duration(milliseconds: 300),
              transitionBuilder: (child, animation) => FadeTransition(opacity: animation, child: child),
              child: _discountPercentage > 0
                  ? _buildTotalRow(context, "الخصم (${_discountPercentage.toStringAsFixed(1)}%):",
                      "-${discountAmount.toStringAsFixed(2)} ر.س", color: Colors.redAccent)
                  : const SizedBox.shrink(),
            ),
            if (_discountPercentage > 0) const SizedBox(height: 12),
            _buildTotalRow(
              context,
              "الإجمالي الكلي:",
              "${finalTotal.toStringAsFixed(2)} ر.س",
              isBold: true,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTotalRow(BuildContext context, String title, String value, {bool isBold = false, Color? color}) {
    final theme = Theme.of(context);
    final textStyle = isBold
        ? theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)
        : theme.textTheme.bodyLarge;

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(title, style: textStyle?.copyWith(color: color)),
        Text(value, style: textStyle?.copyWith(
          color: color ?? (isBold ? theme.colorScheme.primary : theme.textTheme.bodyLarge?.color),
          fontWeight: FontWeight.bold,
          fontFamily: GoogleFonts.cairo().fontFamily,
        )),
      ],
    );
  }
}
