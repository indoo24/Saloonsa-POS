
import 'package:flutter/material.dart';
import '../../../theme.dart';
import '../../widgets/gradiant_background.dart';
import 'data/service_data.dart';
import 'header_section.dart';
import 'categories_section.dart';
import 'models/service-model.dart';
import 'invoice_page.dart';

class CashierScreen extends StatefulWidget {
  final VoidCallback onToggleTheme;
  const CashierScreen({super.key, required this.onToggleTheme});

  @override
  State<CashierScreen> createState() => _CashierScreenState();
}

class _CashierScreenState extends State<CashierScreen> {
  String selectedCategory = "قص الشعر";
  List<ServiceModel> cart = [];

  List<ServiceModel> get filteredServices => allServices
      .where((s) => s.category == selectedCategory)
      .toList();

  void addToCart(ServiceModel service) {
    setState(() => cart.add(service));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("شاشة الكاشير 💈"),
        actions: [
          IconButton(
            icon: const Icon(Icons.receipt_long),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => InvoicePage(cart: cart),
                ),
              );
            },
          ),
        ],
      ),
      body: GradientBackground(
        child: Column(
          children: [
            const HeaderSection(),
            CategoriesSection(
              selectedCategory: selectedCategory,
              onCategorySelected: (cat) {
                setState(() => selectedCategory = cat);
              },
            ),
            Expanded(
              child: GridView.builder(
                padding: const EdgeInsets.all(12),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  childAspectRatio: 1.6,
                  crossAxisSpacing: 12,
                  mainAxisSpacing: 12,
                ),
                itemCount: filteredServices.length,
                itemBuilder: (context, index) {
                  final service = filteredServices[index];
                  return InkWell(
                    onTap: () => addToCart(service),
                    child: Card(
                      elevation: 3,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(15),
                      ),
                      child: Center(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(service.name,
                                style: const TextStyle(
                                    fontWeight: FontWeight.bold, fontSize: 16)),
                            const SizedBox(height: 5),
                            Text("${service.price.toStringAsFixed(0)} ج.م"),
                          ],
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 16),
              child: ElevatedButton.icon(
                icon: const Icon(Icons.receipt_long),
                label: const Text("الانتقال إلى الفاتورة"),
                style: ElevatedButton.styleFrom(
                  minimumSize: const Size.fromHeight(50),
                  backgroundColor: brandGold,
                  foregroundColor: Colors.black,
                  textStyle: const TextStyle(fontWeight: FontWeight.bold),
                ),
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => InvoicePage(cart: cart),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

