import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../cubits/printer/printer_cubit.dart';
import '../../cubits/printer/printer_state.dart';
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

  void _scanPrinters() {
    context.read<PrinterCubit>().scanPrinters(_selectedType);
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
            toastification.show(
              context: context,
              title: Text(state.message),
              type: ToastificationType.error,
              autoCloseDuration: const Duration(seconds: 3),
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
