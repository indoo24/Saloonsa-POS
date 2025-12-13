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

    return Container(
      decoration: BoxDecoration(
        color: theme.cardColor,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.15),
            blurRadius: 10,
            offset: const Offset(0, -5),
          ),
        ],
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Card(
        margin: const EdgeInsets.all(12),
        elevation: 0, // Remove card elevation since container has shadow
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            mainAxisSize: MainAxisSize.min,
            children: [
              // Drag Handle Indicator with visual feedback
              Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 50,
                      height: 5,
                      margin: const EdgeInsets.only(bottom: 2),
                      decoration: BoxDecoration(
                        color: Colors.grey[300],
                        borderRadius: BorderRadius.circular(3),
                      ),
                    ),
                    Container(
                      width: 40,
                      height: 4,
                      margin: const EdgeInsets.only(bottom: 8),
                      decoration: BoxDecoration(
                        color: Colors.grey[400],
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                    Text(
                      'اسحب للتحكم بالحجم',
                      style: TextStyle(
                        fontSize: 10,
                        color: Colors.grey[600],
                      ),
                    ),
                    const SizedBox(height: 8),
                  ],
                ),
              ),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Flexible(
                    child: Text(
                      selectedCustomer != null ? ' ${selectedCustomer!.name}' : "الخدمات المختارة",
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: theme.colorScheme.primary,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
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
            Expanded(
              child: ListView.builder(
                shrinkWrap: true,
                itemCount: cart.length,
                itemBuilder: (context, index) {
                  final service = cart[index];
                  return Padding(
                    padding: const EdgeInsets.symmetric(vertical: 4.0),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Row(
                            children: [
                              CircleAvatar(
                                child: Icon(_getIconForCategory(service.category), size: 18),
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      service.name,
                                      overflow: TextOverflow.ellipsis,
                                      maxLines: 1,
                                    ),
                                    Text(
                                      service.barber ?? 'لم يتم تحديد حلاق',
                                      style: const TextStyle(
                                        color: Colors.grey,
                                        fontSize: 12,
                                      ),
                                      overflow: TextOverflow.ellipsis,
                                      maxLines: 1,
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
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
                              onPressed: () {
                                // Close keyboard when removing item
                                FocusScope.of(context).unfocus();
                                removeFromCart(index);
                              },
                              padding: EdgeInsets.zero,
                              constraints: const BoxConstraints(),
                            ),
                          ],
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
              onPressed: () {
                // Close keyboard before navigating to invoice
                FocusScope.of(context).unfocus();
                navigateToInvoice();
              },
            ),
          ],
        ),
      ),
    ),
    ); // Container closing
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
