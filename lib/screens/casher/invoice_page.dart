import 'package:flutter/material.dart';
import 'package:printing/printing.dart';

import 'data/service_data.dart';
import 'models/service-model.dart';
import 'pdf_invoice.dart';

class InvoicePage extends StatefulWidget {
  final List<ServiceModel> cart;

  const InvoicePage({super.key, required this.cart});

  @override
  State<InvoicePage> createState() => _InvoicePageState();
}

class _InvoicePageState extends State<InvoicePage> {
  final List<String> _clients = const [
    'اختر العميل',
    'عميل جديد',
    'سلمان الغامدي',
    'عبدالله القحطاني',
    'فهد الشهري',
    'تركي العتيبي',
  ];

  late List<ServiceModel> _items;
  String? _selectedClient;
  ServiceModel? _selectedService;

  double get _subtotal =>
      _items.fold<double>(0, (total, service) => total + service.price);
  double get _tax => _subtotal * 0.15;
  double get _total => _subtotal + _tax;

  @override
  void initState() {
    super.initState();
    _items = widget.cart;
    _selectedClient = _clients.first;
  }

  void _addService(ServiceModel? service) {
    if (service == null) return;
    setState(() {
      _items.add(service);
      _selectedService = null;
    });
  }

  void _removeService(int index) {
    setState(() => _items.removeAt(index));
  }

  Future<void> _showSummarySheet() async {
    final colorScheme = Theme.of(context).colorScheme;
    await showModalBottomSheet<void>(
      context: context,
      useSafeArea: true,
      showDragHandle: true,
      backgroundColor: colorScheme.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      builder: (context) {
        return Padding(
          padding: const EdgeInsets.fromLTRB(24, 16, 24, 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'ملخص الفاتورة',
                style: Theme.of(context)
                    .textTheme
                    .titleLarge
                    ?.copyWith(fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 16),
              _SummaryRow(label: 'إسم العميل', value: _selectedClient ?? '-'),
              _SummaryRow(
                label: 'عدد الخدمات',
                value: _items.length.toString(),
              ),
              _SummaryRow(
                label: 'الإجمالي الفرعي',
                value: '${_subtotal.toStringAsFixed(2)} ر.س',
              ),
              _SummaryRow(
                label: 'الضريبة (15%)',
                value: '${_tax.toStringAsFixed(2)} ر.س',
              ),
              const Divider(height: 32),
              _SummaryRow(
                label: 'الإجمالي الكلي',
                value: '${_total.toStringAsFixed(2)} ر.س',
                highlight: true,
              ),
              const SizedBox(height: 24),
              FilledButton.icon(
                icon: const Icon(Icons.print_outlined),
                label: const Text('حفظ و طباعة'),
                onPressed: () async {
                  Navigator.of(context).pop();
                  final pdfData = await generateInvoicePdf(_items);
                  await Printing.layoutPdf(onLayout: (_) => pdfData);
                },
              ),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: Text(
          'إدارة الفاتورة',
          style: Theme.of(context)
              .textTheme
              .titleLarge
              ?.copyWith(fontWeight: FontWeight.w600),
        ),
        centerTitle: true,
      ),
      bottomNavigationBar: SafeArea(
        minimum: const EdgeInsets.fromLTRB(24, 8, 24, 24),
        child: FilledButton.icon(
          icon: const Icon(Icons.check_circle_outline),
          label: const Text('حفظ وطباعة'),
          onPressed: _items.isEmpty ? null : _showSummarySheet,
        ),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(24, 24, 24, 8),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Card(
                elevation: 0,
                color: colorScheme.surfaceVariant.withOpacity(0.6),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(24),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'بيانات العميل',
                        style: Theme.of(context)
                            .textTheme
                            .titleMedium
                            ?.copyWith(fontWeight: FontWeight.w700),
                      ),
                      const SizedBox(height: 16),
                      DropdownButtonFormField<String>(
                        value: _selectedClient,
                        items: _clients
                            .map(
                              (client) => DropdownMenuItem(
                                value: client,
                                child: Text(client),
                              ),
                            )
                            .toList(),
                        onChanged: (value) =>
                            setState(() => _selectedClient = value ?? _clients.first),
                        decoration: InputDecoration(
                          labelText: 'اختر العميل',
                          filled: true,
                          fillColor: colorScheme.surface,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                      DropdownButtonFormField<ServiceModel>(
                        value: _selectedService,
                        items: allServices
                            .map(
                              (service) => DropdownMenuItem(
                                value: service,
                                child: Text('${service.name} — ${service.price} ر.س'),
                              ),
                            )
                            .toList(),
                        onChanged: (value) => _addService(value),
                        decoration: InputDecoration(
                          labelText: 'إضافة خدمة إلى الفاتورة',
                          filled: true,
                          fillColor: colorScheme.surface,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                        ),
                        hint: const Text('اختر الخدمة'),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 24),
              Text(
                'تفاصيل الفاتورة',
                style: Theme.of(context)
                    .textTheme
                    .titleLarge
                    ?.copyWith(fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 16),
              Expanded(
                child: _items.isEmpty
                    ? _EmptyInvoiceState(colorScheme: colorScheme)
                    : ListView.separated(
                        physics: const BouncingScrollPhysics(),
                        itemCount: _items.length,
                        separatorBuilder: (_, __) => const SizedBox(height: 12),
                        itemBuilder: (context, index) {
                          final service = _items[index];
                          return Card(
                            elevation: 0,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(20),
                            ),
                            color: colorScheme.surfaceVariant.withOpacity(0.5),
                            child: ListTile(
                              contentPadding: const EdgeInsets.symmetric(
                                horizontal: 20,
                                vertical: 8,
                              ),
                              leading: CircleAvatar(
                                radius: 24,
                                backgroundColor:
                                    colorScheme.primary.withOpacity(0.15),
                                child: Icon(Icons.spa_rounded,
                                    color: colorScheme.primary),
                              ),
                              title: Text(service.name),
                              subtitle: Text(
                                '${service.price.toStringAsFixed(2)} ر.س',
                                style: Theme.of(context)
                                    .textTheme
                                    .bodyMedium
                                    ?.copyWith(color: colorScheme.onSurfaceVariant),
                              ),
                              trailing: IconButton(
                                icon: Icon(Icons.delete_outline,
                                    color: colorScheme.error),
                                onPressed: () => _removeService(index),
                              ),
                            ),
                          );
                        },
                      ),
              ),
              const SizedBox(height: 16),
              Container(
                decoration: BoxDecoration(
                  color: colorScheme.surfaceVariant.withOpacity(0.4),
                  borderRadius: BorderRadius.circular(20),
                ),
                padding: const EdgeInsets.all(20),
                child: Column(
                  children: [
                    _SummaryRow(
                      label: 'الإجمالي الفرعي',
                      value: '${_subtotal.toStringAsFixed(2)} ر.س',
                    ),
                    _SummaryRow(
                      label: 'الضريبة (15%)',
                      value: '${_tax.toStringAsFixed(2)} ر.س',
                    ),
                    const Divider(height: 24),
                    _SummaryRow(
                      label: 'الإجمالي الكلي',
                      value: '${_total.toStringAsFixed(2)} ر.س',
                      highlight: true,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SummaryRow extends StatelessWidget {
  final String label;
  final String value;
  final bool highlight;

  const _SummaryRow({
    required this.label,
    required this.value,
    this.highlight = false,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                  fontWeight: highlight ? FontWeight.w700 : FontWeight.w500,
                  color: highlight
                      ? colorScheme.primary
                      : colorScheme.onSurfaceVariant,
                ),
          ),
          Text(
            value,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: highlight ? FontWeight.bold : FontWeight.w600,
                ),
          ),
        ],
      ),
    );
  }
}

class _EmptyInvoiceState extends StatelessWidget {
  final ColorScheme colorScheme;

  const _EmptyInvoiceState({required this.colorScheme});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: colorScheme.surfaceVariant.withOpacity(0.4),
          borderRadius: BorderRadius.circular(24),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.list_alt_outlined, size: 40, color: colorScheme.outline),
            const SizedBox(height: 16),
            Text(
              'لا توجد خدمات مضافة حتى الآن',
              style: Theme.of(context)
                  .textTheme
                  .titleMedium
                  ?.copyWith(color: colorScheme.onSurfaceVariant),
            ),
            const SizedBox(height: 8),
            Text(
              'اختر الخدمات من القائمة لإضافتها إلى الفاتورة.',
              style: Theme.of(context)
                  .textTheme
                  .bodyMedium
                  ?.copyWith(color: colorScheme.onSurfaceVariant),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
