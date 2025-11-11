import 'package:barber_casher/screens/casher/header_section.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:toastification/toastification.dart';
import 'cart_section.dart';
import 'data/service_data.dart';
import 'categories_section.dart';
import 'models/customer.dart';
import 'models/service-model.dart';
import 'invoice_page.dart';

class CashierScreen extends StatefulWidget {
  final VoidCallback onToggleTheme;
  const CashierScreen({super.key,  required this.onToggleTheme});

  @override
  State<CashierScreen> createState() => _CashierScreenState();
}

class _CashierScreenState extends State<CashierScreen> {
  Customer? _selectedCustomer;
  String? _selectedBarber;
  final List<String> _barbers = ['أسامة', 'يوسف', 'محمد', 'أحمد'];

  String selectedCategory = "قص الشعر";
  List<ServiceModel> cart = [];

  List<ServiceModel> get filteredServices {
    return allServices.where((s) => s.category == selectedCategory).toList();
  }

  void addToCart(ServiceModel service) {
    if (_selectedBarber == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('الرجاء اختيار الحلاق أولاً.'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }
    final serviceToAdd = ServiceModel(
        name: service.name,
        price: service.price,
        category: service.category,
        barber: _selectedBarber);
    setState(() => cart.add(serviceToAdd));

    // Show a modern banner at the top
     toastification.show(
      context: context,
      type: ToastificationType.success,
      title: Text('تمت إضافة الخدمة بنجاح ✅'),
      description: RichText(
        text: TextSpan(
          text: 'تمت إضافة "${service.name}" إلى السلة.',
          style: TextStyle(
            color: Colors.black87,
            fontSize: 10,
            fontFamily: 'Cairo',
          ),
        ),
      ),
      style: ToastificationStyle.fillColored,
      autoCloseDuration: const Duration(seconds: 2),
      alignment: Alignment.topRight,
      direction: TextDirection.rtl,
      animationDuration: const Duration(milliseconds: 300),
      animationBuilder: (context, animation, alignment, child) {
        return FadeTransition(opacity: animation, child: child);
      },
      icon: const Icon(Icons.check_circle_outline, color: Colors.green),
      showIcon: true,
      primaryColor: Colors.green,
      backgroundColor: Colors.white,
      foregroundColor: Colors.black87,
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 12),
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      borderRadius: BorderRadius.circular(12),
      boxShadow: const [
        BoxShadow(
          color: Color(0x07000000),
          blurRadius: 16,
          offset: Offset(0, 16),
        ),
      ],
      showProgressBar: true,
      closeButtonShowType: CloseButtonShowType.onHover,
      closeOnClick: true,
      pauseOnHover: true,
      dragToClose: true,
      applyBlurEffect: true,
    );

    void removeFromCart(int index) {
      final removed = cart[index];
      setState(() => cart.removeAt(index));

      toastification.show(
        context: context,
        type: ToastificationType.error,
        title: const Text('تم حذف الخدمة ❌'),
        description: RichText(
          text: TextSpan(
            text: 'تم حذف "${removed.name}" من السلة.',
            style: const TextStyle(color: Colors.black87, fontFamily: 'Cairo'),
          ),
        ),
        alignment: Alignment.topRight,
        direction: TextDirection.rtl,
        autoCloseDuration: const Duration(seconds: 4),
        primaryColor: Colors.red,
        backgroundColor: Colors.white,
        icon: const Icon(Icons.delete_forever, color: Colors.red),
        style: ToastificationStyle.fillColored,
        showProgressBar: true,
        borderRadius: BorderRadius.circular(12),
        applyBlurEffect: true,
      );
    }


    // Auto-hide after 3 seconds
    Future.delayed(const Duration(seconds: 3), () {
      if (mounted) {
        ScaffoldMessenger.of(context).hideCurrentMaterialBanner();
      }
    });
  }

  void removeFromCart(int index) {
    setState(() => cart.removeAt(index));
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


  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDarkMode = theme.brightness == Brightness.dark;
    final screenWidth = MediaQuery.of(context).size.width;

    final crossAxisCount = (screenWidth / 200).floor().clamp(2, 4);

    return Scaffold(
      appBar: AppBar(
        title: Text(" الكاشير ", style: theme.appBarTheme.titleTextStyle),
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
            onCustomerSelected: (customer) {
              setState(() {
                _selectedCustomer = customer;
              });
            },
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
            child: DropdownButtonFormField<String>(
              value: _selectedBarber,
              hint: const Text('اختر الحلاق'),
              onChanged: (String? newValue) {
                setState(() {
                  _selectedBarber = newValue;
                });
              },
              items: _barbers.map<DropdownMenuItem<String>>((String value) {
                return DropdownMenuItem<String>(
                  value: value,
                  child: Text(value),
                );
              }).toList(),
              decoration: const InputDecoration(
                border: OutlineInputBorder(),
                contentPadding: EdgeInsets.symmetric(horizontal: 12),
              ),
            ),
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
          if (cart.isNotEmpty) CartSection(
            cart: cart,
            removeFromCart: removeFromCart,
            selectedCustomer: _selectedCustomer,
            navigateToInvoice: () => _navigateToInvoice(context),
          ),
        ],
      ),
    );
  }

  void _navigateToInvoice(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => InvoicePage(
          cart: List<ServiceModel>.from(cart),
          customer: _selectedCustomer,
        ),
      ),
    );
  }



}
