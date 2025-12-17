import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../core/utils/paper_size_helper.dart';
import '../../models/app_settings.dart';
import '../../services/settings_service.dart';
import '../../widgets/receipt_widget.dart';
import '../casher/models/customer.dart';
import '../casher/models/service-model.dart';

/// Receipt Preview Screen - Developer Tool
/// Visual preview that matches thermal printer output exactly
/// Supports 58mm, 80mm, and A4 paper sizes
class ReceiptPreviewScreen extends StatefulWidget {
  const ReceiptPreviewScreen({Key? key}) : super(key: key);

  @override
  State<ReceiptPreviewScreen> createState() => _ReceiptPreviewScreenState();
}

class _ReceiptPreviewScreenState extends State<ReceiptPreviewScreen> {
  String _selectedPaperSize = PaperSizeHelper.paper80mm;
  AppSettings _settings = const AppSettings();
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    try {
      // Load app settings
      final settingsService = SettingsService();
      final settings = await settingsService.loadSettings();

      // Load printer paper size from settings
      final prefs = await SharedPreferences.getInstance();
      final savedPaperSize =
          prefs.getString('printer_paper_size') ?? PaperSizeHelper.paper80mm;

      setState(() {
        _settings = settings;
        _selectedPaperSize = savedPaperSize;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('فشل تحميل الإعدادات: $e')));
      }
    }
  }

  Future<void> _changePaperSize(String newSize) async {
    setState(() {
      _selectedPaperSize = newSize;
    });

    // Save to preferences (simulating printer settings)
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('printer_paper_size', newSize);
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        appBar: AppBar(title: const Text('معاينة الإيصال')),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      backgroundColor: Colors.grey.shade200,
      appBar: AppBar(
        title: const Text('معاينة الإيصال - Developer Tool'),
        actions: [
          // Paper size selector
          PopupMenuButton<String>(
            icon: const Icon(Icons.pageview),
            onSelected: _changePaperSize,
            itemBuilder: (context) {
              return PaperSizeHelper.getAllSizes().map((size) {
                return PopupMenuItem<String>(
                  value: size,
                  child: Row(
                    children: [
                      if (_selectedPaperSize == size)
                        const Icon(Icons.check, size: 20)
                      else
                        const SizedBox(width: 20),
                      const SizedBox(width: 8),
                      Text(PaperSizeHelper.getDisplayName(size)),
                    ],
                  ),
                );
              }).toList();
            },
          ),
        ],
      ),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: _buildReceiptPreview(),
        ),
      ),
      bottomNavigationBar: _buildBottomInfo(),
    );
  }

  Widget _buildReceiptPreview() {
    final previewWidth = PaperSizeHelper.getPreviewWidth(_selectedPaperSize);
    final isA4 = _selectedPaperSize == PaperSizeHelper.paperA4;

    return Container(
      width: isA4 ? MediaQuery.of(context).size.width * 0.9 : previewWidth,
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.2),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: ReceiptWidget(
        paperSize: _selectedPaperSize,
        orderNumber: '12345',
        customer: Customer(id: 1, name: 'أحمد محمد', phone: '0501234567'),
        services: _getSampleServices(),
        discount: 10.0,
        cashierName: 'محمد علي',
        paymentMethod: 'كاش',
        branchName: 'الفرع الرئيسي',
        paid: 100.0,
        remaining: 0.0,
        settings: _settings,
      ),
    );
  }

  Widget _buildBottomInfo() {
    final charsPerLine = PaperSizeHelper.getCharsPerLine(_selectedPaperSize);
    final width = PaperSizeHelper.getPreviewWidth(_selectedPaperSize);

    return Container(
      padding: const EdgeInsets.all(16),
      color: Colors.blue.shade50,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildInfoChip(
                icon: Icons.print,
                label: 'Paper Size',
                value: _selectedPaperSize,
              ),
              _buildInfoChip(
                icon: Icons.text_fields,
                label: 'Chars/Line',
                value: '$charsPerLine',
              ),
              _buildInfoChip(
                icon: Icons.width_full,
                label: 'Width',
                value: '${width.toInt()}px',
              ),
            ],
          ),
          const SizedBox(height: 8),
          const Text(
            'معاينة مطابقة لطباعة ESC/POS الحرارية',
            style: TextStyle(
              fontSize: 12,
              color: Colors.blue,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoChip({
    required IconData icon,
    required String label,
    required String value,
  }) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 20, color: Colors.blue),
        const SizedBox(height: 4),
        Text(label, style: const TextStyle(fontSize: 10, color: Colors.grey)),
        Text(
          value,
          style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
        ),
      ],
    );
  }

  List<ServiceModel> _getSampleServices() {
    return [
      ServiceModel(
        id: 1,
        name: 'قص شعر',
        price: 50.0,
        category: 'حلاقة',
        image: '',
        barber: 'أحمد',
      ),
      ServiceModel(
        id: 2,
        name: 'تشذيب لحية',
        price: 30.0,
        category: 'حلاقة',
        image: '',
        barber: 'محمد',
      ),
      ServiceModel(
        id: 3,
        name: 'حمام مغربي',
        price: 80.0,
        category: 'عناية',
        image: '',
        barber: 'علي',
      ),
    ];
  }
}
