import 'package:barber_casher/screens/casher/header_section.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'data/service_data.dart';
import 'categories_section.dart';
import 'models/service-model.dart';
import 'invoice_page.dart';

class CashierScreen extends StatefulWidget {
  final VoidCallback onToggleTheme;
  const CashierScreen({super.key,  required this.onToggleTheme});

  @override
  State<CashierScreen> createState() => _CashierScreenState();
}

class _CashierScreenState extends State<CashierScreen> {
  String selectedCategory = "قص الشعر";
  List<ServiceModel> cart = [];

  List<ServiceModel> get filteredServices =>
      allServices.where((s) => s.category == selectedCategory).toList();

  void addToCart(ServiceModel service) {
    setState(() => cart.add(service));
  }

  void removeFromCart(int index) {
    setState(() => cart.removeAt(index));
  }

  // Helper function to get icons for services
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


  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDarkMode = theme.brightness == Brightness.dark;
    final screenWidth = MediaQuery.of(context).size.width;

    // Responsive grid cross-axis count
    final crossAxisCount = (screenWidth / 200).floor().clamp(2, 4);

    return Scaffold(
      appBar: AppBar(
        title: Text("شاشة الكاشير 💈", style: theme.appBarTheme.titleTextStyle),
        actions: [
          IconButton(
            tooltip: isDarkMode
                ? "التبديل إلى الوضع الفاتح"
                : "التبديل إلى الوضع الداكن",
            icon: Icon(isDarkMode ? Icons.light_mode : Icons.dark_mode),
            onPressed: widget.onToggleTheme,
          ),
          if (cart.isNotEmpty)
            IconButton(
              icon: const Icon(Icons.receipt_long),
              onPressed: () => _navigateToInvoice(context),
            ),
        ],
      ),
      body: Column(
        children: [
          HeaderSection(
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
            child: CategoriesSection(
              selectedCategory: selectedCategory,
              onCategorySelected: (cat) => setState(() => selectedCategory = cat),
            ),
          ),
          Expanded(
            child: GridView.builder(
              padding: const EdgeInsets.all(12),
              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: crossAxisCount,
                childAspectRatio: 1.1,
                crossAxisSpacing: 12,
                mainAxisSpacing: 12,
              ),
              itemCount: filteredServices.length,
              itemBuilder: (context, index) {
                final service = filteredServices[index];
                return InkWell(
                  onTap: () => addToCart(service),
                  borderRadius: BorderRadius.circular(16),
                  child: Card(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(_getIconForCategory(service.category), size: 36, color: theme.colorScheme.secondary),
                        const SizedBox(height: 8),
                        Text(
                          service.name,
                          style: theme.textTheme.titleMedium,
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 4),
                        Text(
                          "${service.price.toStringAsFixed(0)} ر.س",
                          style: GoogleFonts.cairo(
                            color: theme.colorScheme.secondary,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
          if (cart.isNotEmpty) _buildCartSection(context),
        ],
      ),
    );
  }

  void _navigateToInvoice(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => InvoicePage(cart: List<ServiceModel>.from(cart)),
      ),
    );
  }

  Widget _buildCartSection(BuildContext context) {
    final theme = Theme.of(context);
    final total = cart.fold<double>(0, (sum, item) => sum + item.price);

    return Card(
      margin: const EdgeInsets.all(12),
      elevation: 6,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text("الخدمات المختارة", style: theme.textTheme.titleMedium),
                Text(
                  "الإجمالي: ${total.toStringAsFixed(0)} ر.س",
                  style: GoogleFonts.cairo(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                    color: theme.colorScheme.primary,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: List.generate(cart.length, (index) {
                final service = cart[index];
                return Chip(
                  label: Text(service.name, style: GoogleFonts.cairo()),
                  avatar: CircleAvatar(child: Icon(_getIconForCategory(service.category), size: 16)),
                  onDeleted: () => removeFromCart(index),
                  deleteIcon: const Icon(Icons.close, size: 18),
                );
              }),
            ),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              icon: const Icon(Icons.receipt_long),
              label: const Text("الانتقال إلى الفاتورة"),
              style: theme.elevatedButtonTheme.style?.copyWith(
                backgroundColor: MaterialStateProperty.all(Colors.blue[700]),
                foregroundColor: MaterialStateProperty.all(Colors.white),
                minimumSize: MaterialStateProperty.all(const Size(double.infinity, 50)),
              ),
              onPressed: () => _navigateToInvoice(context),
            ),
          ],
        ),
      ),
    );
  }
}
