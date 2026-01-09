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
        elevation: 0,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Drag Handle Indicator
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
                      decoration: BoxDecoration(
                        color: Colors.grey[400],
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'اسحب للتحكم بالحجم',
                      style: TextStyle(fontSize: 8, color: Colors.grey[600]),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 6),
              // Header with customer name and total
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Flexible(
                    child: Text(
                      selectedCustomer != null
                          ? ' ${selectedCustomer!.name}'
                          : "الخدمات المختارة",
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
              const Divider(height: 8),
              // Scrollable cart items - takes all available space
              Expanded(
                child: cart.isEmpty
                    ? Center(
                        child: Text(
                          'لا توجد خدمات في السلة',
                          style: TextStyle(
                            color: Colors.grey[400],
                            fontSize: 14,
                          ),
                        ),
                      )
                    : ListView.builder(
                        padding: EdgeInsets.zero,
                        physics: const BouncingScrollPhysics(),
                        itemCount: cart.length,
                        itemBuilder: (context, index) {
                          final service = cart[index];
                          return Container(
                            margin: const EdgeInsets.only(bottom: 4),
                            child: Row(
                              children: [
                                CircleAvatar(
                                  radius: 16,
                                  child: Icon(
                                    _getIconForCategory(service.category),
                                    size: 16,
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Text(
                                        service.name,
                                        overflow: TextOverflow.ellipsis,
                                        maxLines: 1,
                                        style: const TextStyle(
                                          fontSize: 13,
                                          fontWeight: FontWeight.w500,
                                        ),
                                      ),
                                      Text(
                                        service.barber ?? 'لم يتم تحديد حلاق',
                                        style: TextStyle(
                                          color: Colors.grey[600],
                                          fontSize: 11,
                                        ),
                                        overflow: TextOverflow.ellipsis,
                                        maxLines: 1,
                                      ),
                                    ],
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  '${service.price.toStringAsFixed(2)} ر.س',
                                  style: TextStyle(
                                    color: theme.colorScheme.secondary,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 12,
                                  ),
                                ),
                                IconButton(
                                  icon: const Icon(
                                    Icons.delete_outline,
                                    color: Colors.redAccent,
                                    size: 18,
                                  ),
                                  onPressed: () {
                                    FocusScope.of(context).unfocus();
                                    removeFromCart(index);
                                  },
                                  padding: const EdgeInsets.all(4),
                                  constraints: const BoxConstraints(
                                    minWidth: 28,
                                    minHeight: 28,
                                  ),
                                ),
                              ],
                            ),
                          );
                        },
                      ),
              ),
              // Bottom section with flexible spacing
              const Divider(height: 8),
              const SizedBox(height: 4),
              ElevatedButton.icon(
                icon: const Icon(Icons.receipt_long, size: 20),
                label: const Text("الانتقال إلى الفاتورة"),
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 12),
                ),
                onPressed: () {
                  FocusScope.of(context).unfocus();
                  navigateToInvoice();
                },
              ),
              const SizedBox(height: 4),
            ],
          ),
        ),
      ),
    ); // Container closing
  }

  IconData _getIconForCategory(String category) {
    switch (category) {
      case "قص الشعر":
        return Icons.content_cut;
      case "حلاقة ذقن":
        return Icons.face_retouching_natural;
      case "العناية بالبشرة":
        return Icons.cleaning_services;
      case "الصبغات":
        return Icons.brush;
      case "استشوار":
        return Icons.air;
      case "تسريحة":
        return Icons.style;
      default:
        return Icons.cut;
    }
  }
}
