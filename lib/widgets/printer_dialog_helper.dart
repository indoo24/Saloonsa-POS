import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';
import '../services/printer_error_mapper.dart' as error_mapper;
import '../services/bluetooth_environment_service.dart';

/// Dialog helper for showing printer-related errors and guidance
class PrinterDialogHelper {
  /// Show error dialog with user-friendly message and suggestions
  static Future<void> showErrorDialog(
    BuildContext context, {
    required String title,
    required String message,
    List<String> suggestions = const [],
    bool canOpenSettings = false,
  }) async {
    return showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            const Icon(Icons.error_outline, color: Colors.red, size: 28),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                title,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(message, style: const TextStyle(fontSize: 16)),
              if (suggestions.isNotEmpty) ...[
                const SizedBox(height: 16),
                const Text(
                  'الحلول المقترحة:',
                  style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                ...suggestions.map(
                  (suggestion) => Padding(
                    padding: const EdgeInsets.only(bottom: 6),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('  '),
                        Expanded(
                          child: Text(
                            suggestion,
                            style: const TextStyle(fontSize: 14),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('حسناً'),
          ),
          if (canOpenSettings)
            ElevatedButton.icon(
              onPressed: () {
                Navigator.pop(context);
                openAppSettings();
              },
              icon: const Icon(Icons.settings),
              label: const Text('فتح الإعدادات'),
            ),
        ],
      ),
    );
  }

  /// Show error dialog from PrinterError object
  static Future<void> showPrinterErrorDialog(
    BuildContext context,
    error_mapper.PrinterError error,
  ) async {
    return showErrorDialog(
      context,
      title: error.arabicTitle,
      message: error.arabicMessage,
      suggestions: error.suggestions,
      canOpenSettings:
          error.code.contains('PERMISSION') || error.code.contains('DISABLED'),
    );
  }

  /// Show environment check failure dialog
  static Future<void> showEnvironmentCheckDialog(
    BuildContext context,
    BluetoothEnvironmentCheck check,
  ) async {
    if (check.error != null) {
      return showErrorDialog(
        context,
        title: check.error!.arabicTitle,
        message: check.error!.arabicMessage,
        suggestions: check.error!.suggestions,
        canOpenSettings: true,
      );
    }

    return showErrorDialog(
      context,
      title: 'فشل فحص البيئة',
      message: check.readableMessage,
      suggestions: check.missingRequirements,
      canOpenSettings: true,
    );
  }

  /// Show no devices found dialog
  static Future<void> showNoDevicesDialog(
    BuildContext context, {
    required String connectionType,
  }) async {
    String title;
    String message;
    List<String> suggestions;

    if (connectionType == 'bluetooth') {
      title = 'لم يتم العثور على طابعات';
      message =
          'لم يتم العثور على طابعات بلوتوث قريبة.\n'
          'تأكد من أن الطابعة مشغلة ومقترنة مع الجهاز.';
      suggestions = [
        'شغّل الطابعة',
        'اذهب إلى إعدادات البلوتوث في الجهاز',
        'اقترن بالطابعة (Pair)',
        'ارجع للتطبيق وحاول مرة أخرى',
      ];
    } else if (connectionType == 'wifi') {
      title = 'لم يتم العثور على طابعات';
      message =
          'لم يتم العثور على طابعات شبكة.\n'
          'تأكد من اتصال الجهاز والطابعة بنفس الشبكة.';
      suggestions = [
        'تأكد من تشغيل الطابعة',
        'تحقق من اتصالك بالواي فاي',
        'تأكد من أن الطابعة على نفس الشبكة',
      ];
    } else {
      title = 'لم يتم العثور على طابعات';
      message = 'لم يتم العثور على طابعات متاحة.';
      suggestions = ['تأكد من تشغيل الطابعة', 'تحقق من الاتصال'];
    }

    return showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            const Icon(Icons.print_disabled, color: Colors.orange, size: 28),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                title,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(message, style: const TextStyle(fontSize: 16)),
              const SizedBox(height: 16),
              const Text(
                'جرب الحلول التالية:',
                style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              ...suggestions.map(
                (s) => Padding(
                  padding: const EdgeInsets.only(bottom: 6),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('  '),
                      Expanded(
                        child: Text(s, style: const TextStyle(fontSize: 14)),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('حسناً'),
          ),
        ],
      ),
    );
  }

  /// Show success dialog
  static Future<void> showSuccessDialog(
    BuildContext context, {
    required String title,
    required String message,
  }) async {
    return showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            const Icon(Icons.check_circle, color: Colors.green, size: 28),
            const SizedBox(width: 12),
            Text(title, style: const TextStyle(fontSize: 18)),
          ],
        ),
        content: Text(message, style: const TextStyle(fontSize: 16)),
        actions: [
          ElevatedButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('حسناً'),
          ),
        ],
      ),
    );
  }
}
