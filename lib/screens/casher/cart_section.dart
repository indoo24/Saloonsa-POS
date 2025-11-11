import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:toastification/toastification.dart';

import 'models/service-model.dart';

class CartSection extends StatelessWidget {
  final List<ServiceModel> cart;
  final Function(int) removeFromCart;
  final dynamic selectedCustomer;
  final VoidCallback navigateToInvoice;

  const CartSection({
    Key? key,
    required this.cart,
    required this.removeFromCart,
    required this.selectedCustomer,
    required this.navigateToInvoice,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final total = cart.fold<double>(0, (sum, item) => sum + item.price);

    return Card(
      margin: const EdgeInsets.all(12),
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(10.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  selectedCustomer != null
                      ? 'الخدمات لـ: ${selectedCustomer.name}'
                      : "الخدمات المختارة",
                  style: theme.textTheme.titleMedium,
                ),
                Text(
                  "الإجمالي: ${total.toStringAsFixed(2)} ر.س",
                  style: GoogleFonts.cairo(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                    color: theme.colorScheme.primary,
                  ),
                ),
              ],
            ),

            const Divider(height: 24),

            SizedBox(
              height: 220,
              child: ListView.builder(
                itemCount: cart.length,
                itemBuilder: (context, index) {
                  final service = cart[index];
                  return ListTile(
                    leading: CircleAvatar(
                      child: Icon(
                        _getIconForCategory(service.category),
                        size: 20,
                      ),
                    ),
                    title: Text(service.name),
                    subtitle: Text(service.barber ?? 'لم يتم تحديد حلاق'),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          '${service.price.toStringAsFixed(2)} ر.س',
                          style: TextStyle(
                            color: theme.colorScheme.secondary,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.delete_outline,
                              color: Colors.redAccent),
                          onPressed: () {
                            // احذف الخدمة
                            removeFromCart(index);

                            // أظهر Toast بعد الحذف

                          },
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),

            const Divider(height: 24),

            ElevatedButton.icon(
              icon: const Icon(Icons.receipt_long),
              label: const Text("الانتقال إلى الفاتورة"),
              onPressed: navigateToInvoice,
            ),
          ],
        ),
      ),
    );
  }

  IconData _getIconForCategory(String? category) {
    switch (category) {
      case 'قص الشعر':
        return Icons.content_cut;
      case 'تحديد اللحية':
        return Icons.face_retouching_natural;
      case 'تنظيف البشرة':
        return Icons.spa;
      default:
        return Icons.miscellaneous_services;
    }
  }
}
