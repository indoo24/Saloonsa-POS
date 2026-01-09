import 'package:flutter/material.dart';
import 'package:logger/logger.dart';
import 'package:printing/printing.dart';
import '../../models/invoice_data.dart';
import '../../widgets/thermal_receipt_widget.dart';
import '../../services/image_based_thermal_printer.dart';
import '../../screens/casher/services/printer_service.dart';
import '../../screens/casher/thermal_receipt_pdf_generator.dart';
import 'package:esc_pos_utils_plus/esc_pos_utils_plus.dart' as esc_pos;

/// THERMAL PREVIEW SCREEN
///
/// Production-grade receipt preview and printing workflow.
/// The user SEES the exact receipt before printing.
///
/// WORKFLOW:
/// 1. Display ThermalReceiptWidget (centered, scrollable, white background)
/// 2. User confirms visually
/// 3. User presses "Print Receipt" button
/// 4. Attempt thermal printing (PRIMARY PATH)
/// 5. If thermal fails → automatic PDF fallback (SAFETY NET)
///
/// CRITICAL: Same widget used for preview, thermal print, and PDF fallback.
class ThermalPreviewScreen extends StatefulWidget {
  final InvoiceData invoiceData;
  final esc_pos.PaperSize paperSize;

  const ThermalPreviewScreen({
    super.key,
    required this.invoiceData,
    this.paperSize = esc_pos.PaperSize.mm58,
  });

  @override
  State<ThermalPreviewScreen> createState() => _ThermalPreviewScreenState();
}

class _ThermalPreviewScreenState extends State<ThermalPreviewScreen> {
  final Logger _logger = Logger();
  bool _isPrinting = false;

  /// Get paper width in pixels
  double get _paperWidthPx {
    return widget.paperSize == esc_pos.PaperSize.mm58
        ? ThermalReceiptWidget.width58mm
        : ThermalReceiptWidget.width80mm;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[300],
      appBar: AppBar(title: const Text('معاينة الفاتورة'), centerTitle: true),
      body: Column(
        children: [
          // Preview Area (Scrollable)
          Expanded(
            child: Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: Container(
                  // Add shadow to make it look like paper
                  decoration: BoxDecoration(
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.2),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: ThermalReceiptWidget(
                    data: widget.invoiceData,
                    paperWidthPx: _paperWidthPx,
                  ),
                ),
              ),
            ),
          ),

          // Action Buttons (Fixed at Bottom)
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  blurRadius: 4,
                  offset: const Offset(0, -2),
                ),
              ],
            ),
            child: SafeArea(
              child: Row(
                children: [
                  // Cancel Button
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: _isPrinting
                          ? null
                          : () => Navigator.pop(context),
                      icon: const Icon(Icons.close),
                      label: const Text('إلغاء'),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  // Print Button
                  Expanded(
                    flex: 2,
                    child: ElevatedButton.icon(
                      onPressed: _isPrinting ? null : _handlePrintReceipt,
                      icon: _isPrinting
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            )
                          : const Icon(Icons.print),
                      label: Text(
                        _isPrinting ? 'جاري الطباعة...' : 'طباعة الفاتورة',
                      ),
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        backgroundColor: Colors.green,
                        foregroundColor: Colors.white,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// Handle print receipt button press
  /// STEP 4: PRINT CONFIRMATION LOGIC
  Future<void> _handlePrintReceipt() async {
    setState(() => _isPrinting = true);

    try {
      _logger.i('═══════════════════════════════════════════');
      _logger.i('PRINT WORKFLOW STARTED');
      _logger.i('═══════════════════════════════════════════');

      // STEP 4.1: DETECT PRINTER STATE
      final printerService = PrinterService();
      final connectedPrinter = printerService.connectedPrinter;

      _logger.i('STEP 1: Checking printer connection...');

      if (connectedPrinter == null) {
        _logger.w('⚠️ No printer connected');
        await _fallbackToPdf('لا يوجد طابعة متصلة');
        return;
      }

      if (connectedPrinter.address == null ||
          connectedPrinter.address!.isEmpty) {
        _logger.w('⚠️ Printer address is empty');
        await _fallbackToPdf('عنوان الطابعة غير صالح');
        return;
      }

      _logger.i('✓ Printer connected: ${connectedPrinter.name}');
      _logger.i('  Type: ${connectedPrinter.type}');
      _logger.i('  Address: ${connectedPrinter.address}');

      // STEP 4.2: ATTEMPT DIRECT THERMAL PRINT (PRIMARY PATH)
      _logger.i('STEP 2: Attempting thermal print...');

      final thermalSuccess = await _attemptThermalPrint(printerService);

      if (thermalSuccess) {
        _logger.i('✅ THERMAL PRINT SUCCESS');
        _logger.i('═══════════════════════════════════════════');

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('✅ تمت الطباعة بنجاح'),
              backgroundColor: Colors.green,
              duration: Duration(seconds: 2),
            ),
          );

          // Close preview screen
          Navigator.pop(context);
        }
        return;
      }

      // STEP 5: AUTOMATIC FAIL-SAFE FALLBACK
      _logger.w('⚠️ Thermal print failed, falling back to PDF');
      await _fallbackToPdf('فشلت الطباعة الحرارية');
    } catch (e, stackTrace) {
      _logger.e('❌ Print workflow error', error: e, stackTrace: stackTrace);
      await _fallbackToPdf('حدث خطأ: ${e.toString()}');
    } finally {
      if (mounted) {
        setState(() => _isPrinting = false);
      }
    }
  }

  /// Attempt thermal printing
  /// Returns true if successful, false otherwise
  Future<bool> _attemptThermalPrint(PrinterService printerService) async {
    try {
      _logger.i('Rendering receipt to image...');

      // Generate ESC/POS bytes using image-based printing
      final bytes = await ImageBasedThermalPrinter.generateImageBasedReceipt(
        widget.invoiceData,
        paperSize: widget.paperSize,
      );

      _logger.i('Image rendered, sending to printer...');
      _logger.i('Total bytes: ${bytes.length}');

      // Send bytes to printer
      await printerService.printBytes(bytes);

      _logger.i('✅ Bytes sent successfully');
      return true;
    } catch (e, stackTrace) {
      _logger.e('Thermal print failed', error: e, stackTrace: stackTrace);
      return false;
    }
  }

  /// Fallback to PDF when thermal printing fails
  Future<void> _fallbackToPdf(String reason) async {
    _logger.i('═══════════════════════════════════════════');
    _logger.i('FALLBACK TO PDF');
    _logger.i('Reason: $reason');
    _logger.i('═══════════════════════════════════════════');

    try {
      // Generate PDF using the same widget
      final pdfBytes =
          await ThermalReceiptPdfGenerator.generateThermalReceiptPdf(
            data: widget.invoiceData,
          );

      _logger.i('PDF generated successfully');

      if (!mounted) return;

      // Show PDF preview
      await Printing.layoutPdf(
        onLayout: (format) => pdfBytes,
        name: 'receipt_${widget.invoiceData.orderNumber}.pdf',
      );

      _logger.i('PDF preview opened');

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('⚠️ $reason\nتم فتح الفاتورة كملف PDF'),
            backgroundColor: Colors.orange,
            duration: const Duration(seconds: 4),
          ),
        );
      }
    } catch (e, stackTrace) {
      _logger.e('PDF fallback failed', error: e, stackTrace: stackTrace);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('❌ فشلت الطباعة والنسخ الاحتياطي: ${e.toString()}'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 4),
          ),
        );
      }
    }
  }
}
