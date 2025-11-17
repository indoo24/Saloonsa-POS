import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'models/customer.dart';
import 'models/service-model.dart';

class CartSection extends StatelessWidget {
  final List<ServiceModel> cart;
  final Function(int) removeFromCart;
  final Customer? selectedCustomer;
  final VoidCallback navigateToInvoice;

  const CartSection({
    super.key,
    required this.cart,
    required this.removeFromCart,
    this.selectedCustomer,
    required this.navigateToInvoice,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final total = cart.fold<double>(0, (sum, item) => sum + item.price);

    return Card(
      margin: const EdgeInsets.all(12),
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  selectedCustomer != null ? ' ${selectedCustomer!.name}' : "الخدمات المختارة",
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: theme.colorScheme.primary,
                  )
                ),
                Text(
                  "الإجمالي: ${total.toStringAsFixed(2)} ر.س",
                  style: GoogleFonts.cairo(
                    fontWeight: FontWeight.bold,
                    fontSize: 12,
                    color: theme.colorScheme.primary,
                  ),
                ),
              ],
            ),
            const Divider(height: 15),
            SizedBox(
              height: 150, // Fixed height for the cart items list
              child: ListView.builder(
                shrinkWrap: true,
                itemCount: cart.length,
                itemBuilder: (context, index) {
                  final service = cart[index];
                  return Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(

                        children: [
                          CircleAvatar(
                            child: Icon(_getIconForCategory(service.category), size: 18),
                          ),
                          const SizedBox(width: 8),
                          Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(service.name),
                                Text(service.barber ?? 'لم يتم تحديد حلاق',
                                  style: TextStyle(
                                    color: Colors.grey
                                  ) ,),
                              ]
                          ),
                        ]
                      ),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          Text('${service.price.toStringAsFixed(2)} ر.س',
                              style: TextStyle(
                                  color: theme.colorScheme.secondary,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 13
                              )),
                          const SizedBox(width: 1),
                          IconButton(
                            icon: const Icon(Icons.delete_outline, color: Colors.redAccent, size: 20),
                            onPressed: () => removeFromCart(index),
                            padding: EdgeInsets.zero,
                            constraints: const BoxConstraints(),
                          ),
                        ],
                      ),
                    ],
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

  IconData _getIconForCategory(String category) {
    switch (category) {
      case "قص الشعر": return Icons.content_cut;
      case "حلاقة ذقن": return Icons.face_retouching_natural;
      case "العناية بالبشرة": return Icons.cleaning_services;
      case "الصبغات": return Icons.brush;
      case "استشوار": return Icons.air;
      case "تسريحة": return Icons.style;
      default: return Icons.cut;
    }
  }
}
