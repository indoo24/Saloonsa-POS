import 'package:barber_casher/screens/casher/header_section.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:toastification/toastification.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'cart_section.dart';
import 'categories_section.dart';
import 'models/service-model.dart';
import 'invoice_page.dart';
import '../../cubits/cashier/cashier_cubit.dart';
import '../../cubits/cashier/cashier_state.dart';

class CashierScreen extends StatefulWidget {
  final VoidCallback onToggleTheme;
  const CashierScreen({super.key, required this.onToggleTheme});

  @override
  State<CashierScreen> createState() => _CashierScreenState();
}

class _CashierScreenState extends State<CashierScreen> {
  @override
  void initState() {
    super.initState();
    // Initialize data when screen opens
    context.read<CashierCubit>().initialize();
  }

  // All state is now managed by CashierCubit - no local state needed!

  void _showBarberSelectionSheet(ServiceModel service) {
    String? localSelectedBarber;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (sheetContext) {
        return Padding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(sheetContext).viewInsets.bottom,
            left: 16,
            right: 16,
            top: 16,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                'اختر الحلاق لخدمة "${service.name}"',
                style: Theme.of(sheetContext).textTheme.titleMedium,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),
              // Get barbers from CashierCubit state
              BlocBuilder<CashierCubit, CashierState>(
                builder: (context, state) {
                  if (state is! CashierLoaded) return const SizedBox();
                  
                  return DropdownButtonFormField<String>(
                    hint: const Text('الرجاء اختيار حلاق'),
                    items: state.barbers.map((barber) {
                      return DropdownMenuItem(
                        value: barber,
                        child: Text(barber, style: Theme.of(sheetContext).textTheme.titleMedium)
                      );
                    }).toList(),
                    onChanged: (value) {
                      localSelectedBarber = value;
                    },
                    decoration: const InputDecoration(border: OutlineInputBorder()),
                  );
                },
              ),
              const SizedBox(height: 24),
              Row(
                children: [
                  Expanded(
                    child: TextButton(
                      onPressed: () => Navigator.pop(sheetContext),
                      child: const Text('إلغاء'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () {
                        if (localSelectedBarber != null) {
                          // Call cubit method instead of local method
                          context.read<CashierCubit>().addToCart(service, localSelectedBarber!);
                          Navigator.pop(sheetContext);
                        }
                      },
                      child: const Text('تأكيد'),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
            ],
          ),
        );
      },
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

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDarkMode = theme.brightness == Brightness.dark;
    final screenWidth = MediaQuery.of(context).size.width;
    final crossAxisCount = (screenWidth / 200).floor().clamp(2, 4);

    return BlocConsumer<CashierCubit, CashierState>(
      // Listen for one-time events like success/error messages
      listener: (context, state) {
        if (state is CashierItemAdded) {
          // Show success toast
          toastification.show(
            context: context,
            type: ToastificationType.success,
            style: ToastificationStyle.fillColored,
            title: Text('تمت إضافة "${state.service.name}" للسلة'),
            alignment: Alignment.topRight,
            autoCloseDuration: const Duration(seconds: 3),
          );
        } else if (state is CashierItemRemoved) {
          // Show removal toast
          toastification.show(
            context: context,
            type: ToastificationType.error,
            style: ToastificationStyle.fillColored,
            title: Text('تم حذف "${state.service.name}" من السلة'),
            alignment: Alignment.topRight,
            autoCloseDuration: const Duration(seconds: 3),
          );
        } else if (state is CashierError) {
          // Show error message
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(state.message), backgroundColor: Colors.red),
          );
        }
      },
      // Build UI based on state
      builder: (context, state) {
        // Show loading indicator
        if (state is CashierLoading || state is CashierInitial) {
          return Scaffold(
            appBar: AppBar(title: Text("الكاشير")),
            body: const Center(child: CircularProgressIndicator()),
          );
        }

        // Show error screen
        if (state is CashierError) {
          return Scaffold(
            appBar: AppBar(title: Text("الكاشير")),
            body: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.error_outline, size: 64, color: Colors.red),
                  const SizedBox(height: 16),
                  Text(state.message),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () => context.read<CashierCubit>().initialize(),
                    child: const Text('إعادة المحاولة'),
                  ),
                ],
              ),
            ),
          );
        }

        // Get loaded state (contains all data)
        final loadedState = state is CashierLoaded ? state : null;
        if (loadedState == null) {
          return Scaffold(
            appBar: AppBar(title: Text("الكاشير")),
            body: const Center(child: Text('حدث خطأ')),
          );
        }

        // Build main UI with data from state
        return Scaffold(
          appBar: AppBar(
            title: Text("الكاشير", style: theme.appBarTheme.titleTextStyle),
            actions: [
              IconButton(
                tooltip: isDarkMode ? "التبديل إلى الوضع الفاتح" : "التبديل إلى الوضع الداكن",
                icon: Icon(isDarkMode ? Icons.light_mode : Icons.dark_mode),
                onPressed: widget.onToggleTheme,
              ),
              // Show invoice button only if cart has items
              if (loadedState.cart.isNotEmpty)
                IconButton(
                  icon: const Icon(Icons.receipt_long),
                  onPressed: () => _navigateToInvoice(context, loadedState),
                ),
            ],
          ),
          body: GestureDetector(
            onTap: () => FocusScope.of(context).unfocus(),
            child: Column(
              children: [
                // Pass selected customer from state
                HeaderSection(
                  onCustomerSelected: (customer) {
                    context.read<CashierCubit>().selectCustomer(customer);
                  },
                ),
                CategoriesSection(
                  selectedCategory: loadedState.selectedCategory,
                  onCategorySelected: (cat) {
                    // Call cubit method to change category
                    context.read<CashierCubit>().selectCategory(cat);
                  },
                ),
                const SizedBox(height: 10),
                const Divider(height: 1),
                Expanded(
                  child: SingleChildScrollView(
                    child: Column(
                      children: [
                        SizedBox(
                          height: MediaQuery.of(context).size.height * 0.4,
                          child: GridView.builder(
                            padding: const EdgeInsets.all(12),
                            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                              crossAxisCount: crossAxisCount,
                              childAspectRatio: 1.2,
                              crossAxisSpacing: 12,
                              mainAxisSpacing: 12,
                            ),
                            // Use filtered services from state
                            itemCount: loadedState.filteredServices.length,
                            itemBuilder: (context, index) {
                              final service = loadedState.filteredServices[index];
                              return InkWell(
                                onTap: () => _showBarberSelectionSheet(service),
                                borderRadius: BorderRadius.circular(16),
                                child: Card(
                                  elevation: 2,
                                  child: Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Icon(_getIconForCategory(service.category), size: 32, color: theme.colorScheme.secondary),
                                      const SizedBox(height: 12),
                                      Text(service.name, style: theme.textTheme.titleMedium, textAlign: TextAlign.center),
                                      const SizedBox(height: 4),
                                      Text("${service.price.toStringAsFixed(0)} ر.س", style: GoogleFonts.cairo(color: theme.colorScheme.secondary, fontWeight: FontWeight.bold)),
                                    ],
                                  ),
                                ),
                              );
                            },
                          ),
                        ),
                        // Show cart if not empty
                        if (loadedState.cart.isNotEmpty)
                          CartSection(
                            cart: loadedState.cart,
                            removeFromCart: (index) {
                              // Call cubit method to remove item
                              context.read<CashierCubit>().removeFromCart(index);
                            },
                            selectedCustomer: loadedState.selectedCustomer,
                            navigateToInvoice: () => _navigateToInvoice(context, loadedState),
                          ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  void _navigateToInvoice(BuildContext context, CashierLoaded state) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => InvoicePage(
          cart: List<ServiceModel>.from(state.cart),
          customer: state.selectedCustomer,
        ),
      ),
    );
  }
}
