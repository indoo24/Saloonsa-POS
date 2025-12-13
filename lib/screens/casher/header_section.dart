import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'models/customer.dart';
import '../../cubits/cashier/cashier_cubit.dart';
import '../../cubits/cashier/cashier_state.dart';

class HeaderSection extends StatefulWidget {
  final Function(Customer) onCustomerSelected;

  const HeaderSection({super.key, required this.onCustomerSelected});

  @override
  State<HeaderSection> createState() => _HeaderSectionState();
}

class _HeaderSectionState extends State<HeaderSection> {
  Key _autocompleteKey = UniqueKey();
  final FocusNode _searchFocusNode = FocusNode();

  @override
  void initState() {
    super.initState();
    // Initial customer is selected from CashierCubit state
  }

  @override
  void dispose() {
    _searchFocusNode.dispose();
    super.dispose();
  }

  Future<void> _showAddCustomerDialog() async {
    final formKey = GlobalKey<FormState>();
    final nameController = TextEditingController();
    final phoneController = TextEditingController();
    final idController = TextEditingController();

    await showDialog<Customer>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('إضافة عميل جديد'),
          content: SingleChildScrollView(
            child: Form(
              key: formKey,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextFormField(
                    controller: nameController,
                    decoration: const InputDecoration(labelText: 'الاسم', border: OutlineInputBorder()),
                    validator: (value) => value!.isEmpty ? 'الاسم مطلوب' : null,
                  ),
                  const SizedBox(height: 8),
                  TextFormField(
                    controller: phoneController,
                    decoration: const InputDecoration(labelText: 'رقم الجوال', border: OutlineInputBorder()),
                  ),
                  const SizedBox(height: 8),
                  TextFormField(
                    controller: idController,
                    decoration: const InputDecoration(labelText: 'العنوان', border: OutlineInputBorder()),
                  ),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context), child: const Text('إلغاء')),
            ElevatedButton(
              onPressed: () async {
                if (formKey.currentState!.validate()) {
                  // Call cubit method to add customer
                  await context.read<CashierCubit>().addCustomer(
                    name: nameController.text,
                    phone: phoneController.text.isNotEmpty ? phoneController.text : null,
                    customerId: idController.text.isNotEmpty ? idController.text : null,
                  );
                  Navigator.pop(context);
                }
              },
              child: const Text('إضافة'),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return BlocBuilder<CashierCubit, CashierState>(
      builder: (context, state) {
        if (state is! CashierLoaded) {
          return const SizedBox(); // or show loading
        }

        return Padding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text("العميل", style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold)),
              const SizedBox(height: 4),
              Container(
                decoration: BoxDecoration(
                  border: Border.all(color: theme.colorScheme.outline.withOpacity(0.7)),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    InkWell(
                      onTap: _showAddCustomerDialog,
                      child: Container(
                        height: 48,
                        padding: const EdgeInsets.symmetric(horizontal: 12),
                        decoration: BoxDecoration(
                          border: Border(right: BorderSide(color: theme.colorScheme.outline.withOpacity(0.7)))
                        ),
                        child: Icon(Icons.add, color: theme.colorScheme.primary),
                      ),
                    ),
                    Expanded(
                      child: Autocomplete<Customer>(
                        key: _autocompleteKey,
                        initialValue: TextEditingValue(
                          text: '',
                        ),
                        optionsBuilder: (TextEditingValue textEditingValue) {
                          if (textEditingValue.text.isEmpty) {
                            return state.customers; // From cubit state
                          }
                          return state.customers.where((Customer option) {
                            return option.name.toLowerCase().contains(textEditingValue.text.toLowerCase()) ||
                                option.phone?.contains(textEditingValue.text) == true ||
                                option.customerId?.toLowerCase().contains(textEditingValue.text.toLowerCase()) == true;
                          });
                        },
                        displayStringForOption: (Customer option) => option.name,
                        onSelected: (Customer selection) {
                          widget.onCustomerSelected(selection);
                          // Immediately close keyboard and clear focus
                          WidgetsBinding.instance.addPostFrameCallback((_) {
                            FocusScope.of(context).requestFocus(FocusNode());
                            FocusManager.instance.primaryFocus?.unfocus();
                          });
                        },
                        fieldViewBuilder: (context, controller, focusNode, onSubmitted) {
                          // Store the focus node reference
                          WidgetsBinding.instance.addPostFrameCallback((_) {
                            if (_searchFocusNode != focusNode) {
                              // Update our reference to the actual focus node
                            }
                          });
                          
                          return TextField(
                            controller: controller,
                            focusNode: focusNode,
                            decoration: const InputDecoration(
                              border: InputBorder.none,
                              hintText: 'ابحث عن عميل...',
                              contentPadding: EdgeInsets.symmetric(horizontal: 16),
                            ),
                            onTap: () {
                              // Only allow opening when explicitly tapped
                            },
                          );
                        },
                      ),
                    ),
                  ],
                ),
              )
            ],
          ),
        );
      },
    );
  }
}
