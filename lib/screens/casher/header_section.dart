import 'package:flutter/material.dart';
import 'models/customer.dart';

class HeaderSection extends StatefulWidget {
  final Function(Customer) onCustomerSelected;

  const HeaderSection({super.key, required this.onCustomerSelected});

  @override
  State<HeaderSection> createState() => _HeaderSectionState();
}

class _HeaderSectionState extends State<HeaderSection> {
  static final List<Customer> _customers = [
    Customer(id: 1, name: 'عميل كاش'),
    Customer(id: 2, name: 'رواف', phone: '123456789'),
    Customer(id: 3, name: 'سام', customerId: 'CUST003'),
    Customer(id: 4, name: 'أحمد', phone: '987654321'),
    Customer(id: 5, name: 'نوال السيد'),
    Customer(id: 6, name: 'سما'),
  ];

  Key _autocompleteKey = UniqueKey();
  late Customer _selectedCustomer;

  @override
  void initState() {
    super.initState();
    _selectedCustomer = _customers.first;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      widget.onCustomerSelected(_selectedCustomer);
    });
  }

  Future<void> _showAddCustomerDialog() async {
    final formKey = GlobalKey<FormState>();
    final nameController = TextEditingController();
    final phoneController = TextEditingController();
    final idController = TextEditingController();

    final newCustomer = await showDialog<Customer>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('إضافة عميل جديد'),
          content: Form(
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
          actions: [
            TextButton(onPressed: () => Navigator.pop(context), child: const Text('إلغاء')),
            ElevatedButton(
              onPressed: () {
                if (formKey.currentState!.validate()) {
                  final customer = Customer(
                    id: DateTime.now().millisecondsSinceEpoch, // Unique ID
                    name: nameController.text,
                    phone: phoneController.text.isNotEmpty ? phoneController.text : null,
                    customerId: idController.text.isNotEmpty ? idController.text : null,
                  );
                  Navigator.pop(context, customer);
                }
              },
              child: const Text('إضافة'),
            ),
          ],
        );
      },
    );

    if (newCustomer != null) {
      setState(() {
        _customers.add(newCustomer);
        _selectedCustomer = newCustomer;
        _autocompleteKey = UniqueKey(); // Force rebuild of Autocomplete
      });
      widget.onCustomerSelected(newCustomer);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

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
                    initialValue: TextEditingValue(text: _selectedCustomer.name),
                    optionsBuilder: (TextEditingValue textEditingValue) {
                      if (textEditingValue.text.isEmpty) {
                        return _customers;
                      }
                      return _customers.where((Customer option) {
                        return option.name.toLowerCase().contains(textEditingValue.text.toLowerCase()) ||
                            option.phone?.contains(textEditingValue.text) == true ||
                            option.customerId?.toLowerCase().contains(textEditingValue.text.toLowerCase()) == true;
                      });
                    },
                    displayStringForOption: (Customer option) => option.name,
                    onSelected: (Customer selection) {
                      setState(() {
                        _selectedCustomer = selection;
                      });
                      widget.onCustomerSelected(selection);
                    },
                    fieldViewBuilder: (context, controller, focusNode, onSubmitted) {
                      return TextField(
                        controller: controller,
                        focusNode: focusNode,
                        decoration: const InputDecoration(
                          border: InputBorder.none,
                          hintText: 'ابحث عن عميل...',
                          contentPadding: EdgeInsets.symmetric(horizontal: 16),
                        ),
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
  }
}
