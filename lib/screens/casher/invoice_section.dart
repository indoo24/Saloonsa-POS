import 'package:flutter/material.dart';
import 'models/service-model.dart';

class InvoiceSection extends StatelessWidget {
  final List<ServiceModel> cart;

  const InvoiceSection({super.key, required this.cart});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 140,
      margin: const EdgeInsets.symmetric(horizontal: 10),
      decoration: BoxDecoration(
        color: Colors.grey.shade100,
        borderRadius: BorderRadius.circular(12),
      ),
      child: ListView.builder(
        itemCount: cart.length,
        itemBuilder: (context, index) {
          final item = cart[index];
          return ListTile(
            leading: const Icon(Icons.check_circle, color: Colors.blueGrey),
            title: Text(item.name),
            trailing: Text("${item.price} ر.س",
                style: const TextStyle(fontWeight: FontWeight.bold)),
          );
        },
      ),
    );
  }
}
