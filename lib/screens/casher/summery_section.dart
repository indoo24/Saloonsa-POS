import 'package:flutter/material.dart';
import 'models/service-model.dart';

class SummarySection extends StatelessWidget {
  final List<ServiceModel> cart;

  const SummarySection({super.key, required this.cart});

  @override
  Widget build(BuildContext context) {
    final total = cart.fold<double>(0, (a, b) => a + b.price);

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(top: BorderSide(color: Colors.grey.shade300)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            "الإجمالي: ${total.toStringAsFixed(2)} ر.س",
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          FilledButton.icon(
            onPressed: () {},
            icon: const Icon(Icons.print),
            label: const Text("حفظ وطباعة"),
          ),
        ],
      ),
    );
  }
}
