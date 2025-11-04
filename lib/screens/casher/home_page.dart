import 'package:flutter/material.dart';

import 'data/service_data.dart';
import 'invoice_page.dart';
import 'models/service-model.dart';

class HomePage extends StatefulWidget {
  final VoidCallback onToggleTheme;

  const HomePage({super.key, required this.onToggleTheme});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  late String _selectedCategory;
  final List<ServiceModel> _cart = [];

  final double _baseSales = 2480.75;
  final int _baseInvoices = 34;
  final int _baseClients = 26;

  List<ServiceModel> get _filteredServices => allServices
      .where((service) => service.category == _selectedCategory)
      .toList();

  double get _todaysSales =>
      _baseSales + _cart.fold(0.0, (sum, item) => sum + item.price);
  int get _todaysInvoices => _baseInvoices + (_cart.isEmpty ? 0 : 1);
  int get _todaysClients =>
      _baseClients + (_cart.isEmpty ? 0 : (_cart.length / 1.5).ceil());

  @override
  void initState() {
    super.initState();
    _selectedCategory =
        allServices.isNotEmpty ? allServices.first.category : '';
  }

  void _onCategorySelected(String category) {
    setState(() => _selectedCategory = category);
  }

  void _addToCart(ServiceModel service) {
    setState(() => _cart.add(service));
    final colorScheme = Theme.of(context).colorScheme;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('${service.name} تمت إضافتها إلى الفاتورة'),
        behavior: SnackBarBehavior.floating,
        backgroundColor: colorScheme.primaryContainer,
        elevation: 0,
      ),
    );
  }

  void _removeFromCart(int index) {
    setState(() => _cart.removeAt(index));
  }

  void _openInvoice() {
    if (_cart.isEmpty) {
      final colorScheme = Theme.of(context).colorScheme;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('اختر خدمة واحدة على الأقل قبل إنشاء الفاتورة'),
          behavior: SnackBarBehavior.floating,
          backgroundColor: colorScheme.errorContainer,
          elevation: 0,
        ),
      );
      return;
    }

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => InvoicePage(cart: List<ServiceModel>.from(_cart)),
      ),
    ).then((_) {
      if (!mounted) return;
      setState(() => _cart.clear());
    });
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final categories = allServices.map((e) => e.category).toSet().toList();

    return Scaffold(
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _openInvoice,
        icon: const Icon(Icons.receipt_long),
        label: const Text('إنشاء فاتورة جديدة'),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
      appBar: AppBar(
        title: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.cut, color: colorScheme.primary),
            const SizedBox(width: 8),
            Text(
              'Salon POS',
              style: Theme.of(context)
                  .textTheme
                  .titleLarge
                  ?.copyWith(fontWeight: FontWeight.w600),
            ),
          ],
        ),
        centerTitle: true,
        actions: [
          IconButton(
            tooltip: Theme.of(context).brightness == Brightness.dark
                ? 'الوضع الفاتح'
                : 'الوضع الداكن',
            icon: Icon(
              Theme.of(context).brightness == Brightness.dark
                  ? Icons.light_mode
                  : Icons.dark_mode,
            ),
            onPressed: widget.onToggleTheme,
          ),
        ],
      ),
      body: SafeArea(
        child: CustomScrollView(
          physics: const BouncingScrollPhysics(),
          slivers: [
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 24, 20, 8),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'مرحبا بك،',
                      style: Theme.of(context)
                          .textTheme
                          .titleMedium
                          ?.copyWith(color: colorScheme.onSurfaceVariant),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'إجمالي مبيعات اليوم',
                      style: Theme.of(context)
                          .textTheme
                          .headlineSmall
                          ?.copyWith(fontWeight: FontWeight.w700),
                    ),
                    const SizedBox(height: 24),
                    LayoutBuilder(
                      builder: (context, constraints) {
                        final isWide = constraints.maxWidth > 640;
                        return Wrap(
                          spacing: 16,
                          runSpacing: 16,
                          children: [
                            _SummaryCard(
                              icon: Icons.payments_rounded,
                              label: 'مبيعات اليوم',
                              value:
                                  '${_todaysSales.toStringAsFixed(2)} ر.س',
                              colorScheme: colorScheme,
                              width: isWide
                                  ? (constraints.maxWidth - 32) / 3
                                  : constraints.maxWidth,
                            ),
                            _SummaryCard(
                              icon: Icons.description_outlined,
                              label: 'عدد الفواتير',
                              value: _todaysInvoices.toString(),
                              colorScheme: colorScheme,
                              width: isWide
                                  ? (constraints.maxWidth - 32) / 3
                                  : constraints.maxWidth,
                            ),
                            _SummaryCard(
                              icon: Icons.people_alt_outlined,
                              label: 'عدد العملاء',
                              value: _todaysClients.toString(),
                              colorScheme: colorScheme,
                              width: isWide
                                  ? (constraints.maxWidth - 32) / 3
                                  : constraints.maxWidth,
                            ),
                          ],
                        );
                      },
                    ),
                    const SizedBox(height: 24),
                    Text(
                      'الخدمات',
                      style: Theme.of(context)
                          .textTheme
                          .titleLarge
                          ?.copyWith(fontWeight: FontWeight.w600),
                    ),
                    const SizedBox(height: 12),
                    SizedBox(
                      height: 48,
                      child: ListView.separated(
                        scrollDirection: Axis.horizontal,
                        itemCount: categories.length,
                        separatorBuilder: (_, __) => const SizedBox(width: 12),
                        itemBuilder: (context, index) {
                          final category = categories[index];
                          final isSelected = category == _selectedCategory;
                          return ChoiceChip(
                            label: Text(category),
                            selected: isSelected,
                            onSelected: (_) => _onCategorySelected(category),
                            labelStyle: TextStyle(
                              color: isSelected
                                  ? colorScheme.onPrimaryContainer
                                  : colorScheme.onSurfaceVariant,
                              fontWeight: FontWeight.w600,
                            ),
                            selectedColor: colorScheme.primaryContainer,
                            backgroundColor:
                                colorScheme.surfaceVariant.withOpacity(0.6),
                            showCheckmark: false,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14),
                            ),
                          );
                        },
                      ),
                    ),
                    const SizedBox(height: 16),
                  ],
                ),
              ),
            ),
            SliverPadding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              sliver: SliverGrid(
                delegate: SliverChildBuilderDelegate(
                  (context, index) {
                    if (_filteredServices.isEmpty) {
                      return _EmptyServiceState(colorScheme: colorScheme);
                    }
                    final service = _filteredServices[index];
                    return _ServiceCard(
                      service: service,
                      onTap: () => _addToCart(service),
                    );
                  },
                  childCount: _filteredServices.isEmpty
                      ? 1
                      : _filteredServices.length,
                ),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  crossAxisSpacing: 16,
                  mainAxisSpacing: 16,
                  childAspectRatio: 1.1,
                ),
              ),
            ),
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 24, 20, 120),
                child: AnimatedSwitcher(
                  duration: const Duration(milliseconds: 250),
                  child: _cart.isEmpty
                      ? _EmptyCartMessage(colorScheme: colorScheme)
                      : _SelectedServicesList(
                          cart: _cart,
                          onRemove: _removeFromCart,
                        ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SummaryCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final ColorScheme colorScheme;
  final double width;

  const _SummaryCard({
    required this.icon,
    required this.label,
    required this.value,
    required this.colorScheme,
    required this.width,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: width,
      child: Card(
        elevation: 0,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        color: colorScheme.surfaceVariant.withOpacity(0.6),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: colorScheme.primary.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Icon(icon, color: colorScheme.primary),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      label,
                      style: Theme.of(context)
                          .textTheme
                          .labelLarge
                          ?.copyWith(color: colorScheme.onSurfaceVariant),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      value,
                      style: Theme.of(context)
                          .textTheme
                          .titleLarge
                          ?.copyWith(fontWeight: FontWeight.w700),
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

class _ServiceCard extends StatelessWidget {
  final ServiceModel service;
  final VoidCallback onTap;

  const _ServiceCard({required this.service, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      color: colorScheme.surfaceVariant.withOpacity(0.4),
      child: InkWell(
        borderRadius: BorderRadius.circular(20),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Align(
                alignment: Alignment.topRight,
                child: Container(
                  decoration: BoxDecoration(
                    color: colorScheme.primary.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  padding: const EdgeInsets.all(10),
                  child: Icon(Icons.spa_rounded, color: colorScheme.primary),
                ),
              ),
              const Spacer(),
              Text(
                service.name,
                style: Theme.of(context)
                    .textTheme
                    .titleMedium
                    ?.copyWith(fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 8),
              Text(
                '${service.price.toStringAsFixed(0)} ر.س',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: colorScheme.primary,
                    ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SelectedServicesList extends StatelessWidget {
  final List<ServiceModel> cart;
  final void Function(int index) onRemove;

  const _SelectedServicesList({required this.cart, required this.onRemove});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      color: colorScheme.surfaceVariant.withOpacity(0.6),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'الخدمات المختارة',
              style: Theme.of(context)
                  .textTheme
                  .titleMedium
                  ?.copyWith(fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 16),
            ...List.generate(cart.length, (index) {
              final service = cart[index];
              return Padding(
                padding: EdgeInsets.only(bottom: index == cart.length - 1 ? 0 : 12),
                child: Container(
                  decoration: BoxDecoration(
                    color: colorScheme.surface,
                    borderRadius: BorderRadius.circular(18),
                  ),
                  child: ListTile(
                    contentPadding:
                        const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                    title: Text(service.name),
                    subtitle: Text('${service.price.toStringAsFixed(0)} ر.س'),
                    trailing: IconButton(
                      icon: Icon(Icons.delete_outline, color: colorScheme.error),
                      onPressed: () => onRemove(index),
                    ),
                  ),
                ),
              );
            }),
          ],
        ),
      ),
    );
  }
}

class _EmptyCartMessage extends StatelessWidget {
  final ColorScheme colorScheme;

  const _EmptyCartMessage({required this.colorScheme});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: colorScheme.surfaceVariant.withOpacity(0.4),
        borderRadius: BorderRadius.circular(24),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.inbox_outlined, size: 36, color: colorScheme.outline),
          const SizedBox(height: 12),
          Text(
            'لم يتم اختيار أي خدمة بعد',
            style: Theme.of(context)
                .textTheme
                .titleMedium
                ?.copyWith(color: colorScheme.onSurfaceVariant),
          ),
          const SizedBox(height: 4),
          Text(
            'ابدأ بالضغط على الخدمات لإضافتها إلى الفاتورة الجديدة.',
            style: Theme.of(context)
                .textTheme
                .bodyMedium
                ?.copyWith(color: colorScheme.onSurfaceVariant),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}

class _EmptyServiceState extends StatelessWidget {
  final ColorScheme colorScheme;

  const _EmptyServiceState({required this.colorScheme});

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      color: colorScheme.surfaceVariant.withOpacity(0.4),
      child: Center(
        child: Text(
          'لا توجد خدمات في هذه الفئة حالياً',
          style: Theme.of(context)
              .textTheme
              .bodyLarge
              ?.copyWith(color: colorScheme.onSurfaceVariant),
          textAlign: TextAlign.center,
        ),
      ),
    );
  }
}
