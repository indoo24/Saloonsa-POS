import 'package:flutter/material.dart';
import 'package:printing/printing.dart';
import '../../widgets/gradiant_background.dart';
import 'models/service-model.dart';
import 'pdf_invoice.dart';
import '../../../theme.dart';

class InvoicePage extends StatelessWidget {
  final List<ServiceModel> cart;
  const InvoicePage({super.key, required this.cart});

  @override
  Widget build(BuildContext context) {
    double subtotal = cart.fold(0, (sum, item) => sum + item.price);
    double tax = subtotal * 0.15;
    double total = subtotal + tax;

    return Scaffold(
        appBar: AppBar(title: const Text("الفاتورة 💵")),
        body: GradientBackground(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text("الخدمات المختارة:",
                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
                  const SizedBox(height: 10),
                  Expanded(
                    child: ListView.builder(
                      itemCount: cart.length,
                      itemBuilder: (context, index) {
                        final s = cart[index];
                        return ListTile(
                          leading: const Icon(Icons.cut),
                          title: Text(s.name),
                          trailing: Text("${s.price} ر.س"),
                        );
                      },
                    ),
                  ),
                  const Divider(),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text("الإجمالي الفرعي:"),
                      Text("${subtotal.toStringAsFixed(2)} ر.س"),
                    ],
                  ),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text("الضريبة (15%):"),
                      Text("${tax.toStringAsFixed(2)}   ر.س"),
                    ],
                  ),
                  const Divider(),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text("الإجمالي الكلي:",
                          style: TextStyle(fontWeight: FontWeight.bold)),
                      Text("${total.toStringAsFixed(2)} ر.س",
                          style: const TextStyle(fontWeight: FontWeight.bold)),
                    ],
                  ),
                  const SizedBox(height: 20),
                  ElevatedButton.icon(
                    icon: const Icon(Icons.print),
                    label: const Text("حفظ وطباعة PDF"),
                    style: ElevatedButton.styleFrom(
                      minimumSize: const Size.fromHeight(50),
                      backgroundColor: brandGold,
                      foregroundColor: Colors.black,
                    ),
                    onPressed: () async {
                      final pdfData = await generateInvoicePdf(cart);
                      await Printing.layoutPdf(onLayout: (_) => pdfData);
                    },
                  ),
                ],
              ),
            ),
            ),
        );
    }
}