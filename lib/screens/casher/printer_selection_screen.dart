import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:permission_handler/permission_handler.dart';
import '../../cubits/printer/printer_cubit.dart';
import '../../cubits/printer/printer_state.dart';
import '../../services/permission_service.dart';
import 'models/printer_device.dart';
import 'package:toastification/toastification.dart';

/// Printer selection and management screen
class PrinterSelectionScreen extends StatefulWidget {
  const PrinterSelectionScreen({super.key});

  @override
  State<PrinterSelectionScreen> createState() => _PrinterSelectionScreenState();
}

class _PrinterSelectionScreenState extends State<PrinterSelectionScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  PrinterConnectionType _selectedType = PrinterConnectionType.wifi;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _tabController.addListener(() {
      if (!_tabController.indexIsChanging) {
        setState(() {
          _selectedType = PrinterConnectionType.values[_tabController.index];
        });
      }
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _scanPrinters() async {
    // If scanning Bluetooth, request permissions first
    if (_selectedType == PrinterConnectionType.bluetooth) {
      final result = await context.read<PrinterCubit>().requestBluetoothPermissions();

      if (result == PermissionResult.permanentlyDenied) {
        // Show dialog to open settings
        if (!mounted) return;
        _showPermissionDeniedDialog();
        return;
      } else if (result == PermissionResult.denied) {
        // Show error message
        if (!mounted) return;
        toastification.show(
          context: context,
          title: const Text('يجب منح صلاحيات البلوتوث'),
          description: const Text('الصلاحيات مطلوبة للبحث عن الطابعات'),
          type: ToastificationType.warning,
          autoCloseDuration: const Duration(seconds: 3),
        );
        return;
      }
    }

    // Proceed with scanning
    if (!mounted) return;
    context.read<PrinterCubit>().scanPrinters(_selectedType);
  }

  void _showPermissionDeniedDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('صلاحيات البلوتوث مطلوبة'),
        content: const Text(
          'تطبيق الصالون يحتاج صلاحيات البلوتوث للبحث عن الطابعات.\n\n'
          'الرجاء فتح الإعدادات ومنح الصلاحيات التالية:\n'
          '• Bluetooth Scan\n'
          '• Bluetooth Connect\n'
          '• Location',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('إلغاء'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              openAppSettings();
            },
            child: const Text('فتح الإعدادات'),
          ),
        ],
      ),
    );
  }

  void _connectToPrinter(PrinterDevice device) {
    context.read<PrinterCubit>().connectToPrinter(device);
  }

  void _disconnect() {
    context.read<PrinterCubit>().disconnect();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('إعدادات الطابعة'),
        centerTitle: true,
        actions: [
          BlocBuilder<PrinterCubit, PrinterState>(
            builder: (context, state) {
              if (state is PrinterConnected) {
                return IconButton(
                  icon: const Icon(Icons.link_off),
                  tooltip: 'قطع الاتصال',
                  onPressed: _disconnect,
                );
              }
              return const SizedBox.shrink();
            },
          ),
        ],
      ),
      body: BlocConsumer<PrinterCubit, PrinterState>(
        listener: (context, state) {
          if (state is PrinterConnected) {
            toastification.show(
              context: context,
              title: Text('تم الاتصال بالطابعة: ${state.device.name}'),
              type: ToastificationType.success,
              autoCloseDuration: const Duration(seconds: 2),
            );
          } else if (state is PrinterError) {
            // Show detailed error message
            // Check if it's a critical error that needs a dialog
            final message = state.message;
            final isCriticalError = message.contains('مطلوبة') || 
                                   message.contains('مغلق') ||
                                   message.contains('غير مدعوم') ||
                                   message.contains('يجب') ||
                                   message.length > 100;
            
            if (isCriticalError) {
              // Show dialog for critical errors with detailed explanation
              toastification.show(
                context: context,
                title: Text(message),
                type: ToastificationType.error,
                autoCloseDuration: const Duration(seconds: 5),
                showProgressBar: true,
              );
            } else {
              // Show toast for simple errors
              toastification.show(
                context: context,
                title: Text(message),
                type: ToastificationType.error,
                autoCloseDuration: const Duration(seconds: 3),
              );
            }
          } else if (state is PrintersFound && state.devices.isEmpty) {
            // Show helpful message when no devices found
            final typeArabic = state.type == PrinterConnectionType.bluetooth
                ? 'بلوتوث'
                : state.type == PrinterConnectionType.wifi
                    ? 'شبكة'
                    : 'USB';
            
            toastification.show(
              context: context,
              title: Text('لم يتم العثور على طابعات $typeArabic'),
              description: state.type == PrinterConnectionType.bluetooth
                  ? const Text('تأكد من أن الطابعة مشغلة ومقترنة مع الجهاز')
                  : const Text('تأكد من أن الطابعة مشغلة ومتصلة بالشبكة'),
              type: ToastificationType.warning,
              autoCloseDuration: const Duration(seconds: 4),
            );
          } else if (state is PrinterDisconnected) {
            toastification.show(
              context: context,
              title: const Text('تم قطع الاتصال بالطابعة'),
              type: ToastificationType.info,
              autoCloseDuration: const Duration(seconds: 2),
            );
          }
        },
        builder: (context, state) {
          return Column(
            children: [
              // Connected printer status
              if (state is PrinterConnected)
                Container(
                  padding: const EdgeInsets.all(16),
                  color: Colors.green.withOpacity(0.1),
                  child: Row(
                    children: [
                      const Icon(Icons.check_circle, color: Colors.green),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'الطابعة المتصلة',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 14,
                              ),
                            ),
                            Text(
                              state.device.displayName,
                              style: TextStyle(
                                color: Colors.grey[600],
                                fontSize: 13,
                              ),
                            ),
                          ],
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.link_off, color: Colors.red),
                        onPressed: _disconnect,
                      ),
                    ],
                  ),
                ),

              // Tabs for connection types
              TabBar(
                controller: _tabController,
                tabs: const [
                  Tab(icon: Icon(Icons.wifi), text: 'WiFi'),
                  Tab(icon: Icon(Icons.bluetooth), text: 'Bluetooth'),
                  Tab(icon: Icon(Icons.usb), text: 'USB'),
                ],
              ),

              // Scan button
              Padding(
                padding: const EdgeInsets.all(16),
                child: SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: state is PrinterScanning ? null : _scanPrinters,
                    icon: state is PrinterScanning
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Icon(Icons.search),
                    label: Text(
                      state is PrinterScanning
                          ? 'جاري البحث...'
                          : 'بحث عن طابعات',
                    ),
                  ),
                ),
              ),

              // Printers list
              Expanded(child: _buildPrintersList(state)),
            ],
          );
        },
      ),
    );
  }

  Widget _buildPrintersList(PrinterState state) {
    if (state is PrinterScanning) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(),
            SizedBox(height: 16),
            Text('جاري البحث عن الطابعات...'),
          ],
        ),
      );
    }

    if (state is PrintersFound) {
      if (state.devices.isEmpty) {
        return Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.print_disabled, size: 64, color: Colors.grey[400]),
              const SizedBox(height: 16),
              Text(
                'لم يتم العثور على طابعات',
                style: TextStyle(color: Colors.grey[600]),
              ),
              const SizedBox(height: 8),
              Text(
                'تأكد من أن الطابعة متصلة وقريبة',
                style: TextStyle(color: Colors.grey[500], fontSize: 12),
              ),
            ],
          ),
        );
      }

      return ListView.builder(
        itemCount: state.devices.length,
        padding: const EdgeInsets.all(16),
        itemBuilder: (context, index) {
          final device = state.devices[index];
          return Card(
            margin: const EdgeInsets.only(bottom: 12),
            child: ListTile(
              leading: CircleAvatar(
                backgroundColor: _getConnectionColor(
                  device.type,
                ).withOpacity(0.2),
                child: Icon(
                  _getConnectionIcon(device.type),
                  color: _getConnectionColor(device.type),
                ),
              ),
              title: Text(
                device.name,
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
              subtitle: Text(device.address ?? 'لا يوجد عنوان'),
              trailing: ElevatedButton(
                onPressed: () => _connectToPrinter(device),
                child: const Text('اتصال'),
              ),
            ),
          );
        },
      );
    }

    if (state is PrinterConnecting) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const CircularProgressIndicator(),
            const SizedBox(height: 16),
            Text('جاري الاتصال بـ ${state.device.name}...'),
          ],
        ),
      );
    }

    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.print, size: 64, color: Colors.grey[400]),
          const SizedBox(height: 16),
          Text(
            'اضغط على "بحث عن طابعات" للبدء',
            style: TextStyle(color: Colors.grey[600]),
          ),
        ],
      ),
    );
  }

  IconData _getConnectionIcon(PrinterConnectionType type) {
    switch (type) {
      case PrinterConnectionType.wifi:
        return Icons.wifi;
      case PrinterConnectionType.bluetooth:
        return Icons.bluetooth;
      case PrinterConnectionType.usb:
        return Icons.usb;
    }
  }

  Color _getConnectionColor(PrinterConnectionType type) {
    switch (type) {
      case PrinterConnectionType.wifi:
        return Colors.blue;
      case PrinterConnectionType.bluetooth:
        return Colors.indigo;
      case PrinterConnectionType.usb:
        return Colors.green;
    }
  }
}
