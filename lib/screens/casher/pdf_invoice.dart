import 'dart:typed_data';
import 'package:flutter/services.dart' show rootBundle;
import 'package:intl/intl.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'models/customer.dart';
import 'models/service-model.dart';

Future<Uint8List> generateInvoicePdf({
  required Customer? customer,
  required List<ServiceModel> services,
  required double discount,
  required String cashierName,
  required String paymentMethod,
  required String invoiceNumber, // Invoice number from API
  // NEW: API-provided calculated values (preferred)
  double? apiSubtotal,
  double? apiTaxAmount,
  double? apiDiscountAmount,
  double? apiGrandTotal,
}) async {
  final pdf = pw.Document();

  final font = await rootBundle.load("assets/fonts/Cairo-Regular.ttf");
  final ttf = pw.Font.ttf(font);

  final shopImage = pw.MemoryImage(
    (await rootBundle.load('assets/images/logo.png')).buffer.asUint8List(),
  );

  // Calculate totals - prefer API values if provided
  // CRITICAL: Correct calculation order per business rules:
  // 1. subtotal_before_tax = sum(service prices)
  // 2. discount_amount = subtotal * discount_percent (discount applied BEFORE tax)
  // 3. amount_after_discount = subtotal - discount_amount
  // 4. tax_amount = amount_after_discount * tax_percent (tax calculated AFTER discount)
  // 5. final_total = amount_after_discount + tax_amount

  final subtotal =
      apiSubtotal ?? services.fold<double>(0, (sum, item) => sum + item.price);

  // Discount applied to subtotal (BEFORE tax)
  final discountAmount =
      apiDiscountAmount ?? (discount > 0 ? subtotal * (discount / 100) : 0);

  // Amount after discount (before adding tax)
  final amountAfterDiscount = subtotal - discountAmount;

  // Tax calculated on discounted amount (AFTER discount)
  final tax = apiTaxAmount ?? (amountAfterDiscount * 0.15);

  // Total after tax = amount after discount + tax
  final totalBeforeDiscount = amountAfterDiscount + tax;

  // Final total (same as totalBeforeDiscount in this context)
  final finalTotal = apiGrandTotal ?? totalBeforeDiscount;

  print('📄 PDF Invoice Generation (Correct Calculation Order):');
  print('  Using API values: ${apiSubtotal != null}');
  print('  1. Subtotal before tax: $subtotal');
  print('  2. Discount % input: $discount');
  print('  3. Discount amount: $discountAmount');
  print('  4. Amount after discount: $amountAfterDiscount');
  print('  5. Tax (15% on discounted amount): $tax');
  print('  6. Final Total: $finalTotal');

  const tableBorder = pw.TableBorder(
    top: pw.BorderSide(),
    bottom: pw.BorderSide(),
    left: pw.BorderSide(),
    right: pw.BorderSide(),
    horizontalInside: pw.BorderSide(),
    verticalInside: pw.BorderSide(),
  );

  pw.Widget _buildCell(
    String text, {
    pw.TextAlign align = pw.TextAlign.center,
    pw.FontWeight? weight,
    double fontSize = 10,
  }) {
    return pw.Padding(
      padding: const pw.EdgeInsets.all(4),
      child: pw.Text(
        text,
        textAlign: align,
        style: pw.TextStyle(font: ttf, fontSize: fontSize, fontWeight: weight),
      ),
    );
  }

  pdf.addPage(
    pw.Page(
      pageFormat: PdfPageFormat.a4,
      theme: pw.ThemeData.withFont(base: ttf, bold: ttf),
      build: (pw.Context context) {
        return pw.Directionality(
          textDirection: pw.TextDirection.rtl,
          child: pw.Column(
            children: [
              // Header
              pw.Table(
                border: tableBorder,
                columnWidths: {
                  0: const pw.FlexColumnWidth(1),
                  1: const pw.FlexColumnWidth(2),
                },
                children: [
                  pw.TableRow(
                    children: [
                      pw.Image(shopImage, height: 60, fit: pw.BoxFit.cover),
                      pw.Padding(
                        padding: const pw.EdgeInsets.all(8.0),
                        child: pw.Column(
                          crossAxisAlignment: pw.CrossAxisAlignment.center,
                          mainAxisAlignment: pw.MainAxisAlignment.center,
                          children: [
                            pw.Text(
                              'صالون الشباب',
                              style: pw.TextStyle(
                                font: ttf,
                                fontWeight: pw.FontWeight.bold,
                                fontSize: 12,
                              ),
                            ),
                            pw.Text(
                              'المدينة المنورة',
                              style: pw.TextStyle(font: ttf, fontSize: 10),
                            ),
                            pw.Text(
                              '0565656565',
                              style: pw.TextStyle(font: ttf, fontSize: 10),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              pw.SizedBox(height: 10),

              // Invoice Title
              pw.Container(
                padding: const pw.EdgeInsets.all(4),
                decoration: pw.BoxDecoration(border: pw.Border.all()),
                child: pw.Center(
                  child: pw.Text(
                    'فاتورة ضريبية مبسطة',
                    style: pw.TextStyle(
                      font: ttf,
                      fontWeight: pw.FontWeight.bold,
                      fontSize: 14,
                    ),
                  ),
                ),
              ),
              pw.SizedBox(height: 5),

              // Invoice Details
              pw.Table(
                border: tableBorder,
                children: [
                  pw.TableRow(
                    children: [
                      _buildCell(invoiceNumber),
                      _buildCell('# الفاتورة'),
                    ],
                  ),
                  pw.TableRow(
                    children: [_buildCell(paymentMethod), _buildCell('الدفع')],
                  ),
                  pw.TableRow(
                    children: [
                      _buildCell(
                        DateFormat('yyyy-MM-dd').format(DateTime.now()),
                      ),
                      _buildCell('التاريخ'),
                    ],
                  ),
                  pw.TableRow(
                    children: [_buildCell(cashierName), _buildCell('الكاشير')],
                  ),
                  pw.TableRow(
                    children: [
                      _buildCell(customer?.name ?? 'عميل كاش'),
                      _buildCell('العميل'),
                    ],
                  ),
                ],
              ),
              pw.SizedBox(height: 10),

              // Services Table
              pw.Table(
                border: tableBorder,
                columnWidths: const {
                  0: pw.FlexColumnWidth(1),
                  1: pw.FlexColumnWidth(2),
                  2: pw.FlexColumnWidth(1),
                  3: pw.FlexColumnWidth(1),
                },
                children: [
                  pw.TableRow(
                    children: [
                      _buildCell('الموظف', weight: pw.FontWeight.bold),
                      _buildCell('إجمالي', weight: pw.FontWeight.bold),
                      _buildCell('السعر', weight: pw.FontWeight.bold),
                      _buildCell('الوصف', weight: pw.FontWeight.bold),
                    ],
                  ),
                  ...services.map(
                    (service) => pw.TableRow(
                      children: [
                        _buildCell(service.barber ?? 'N/A'),
                        _buildCell('${service.price.toStringAsFixed(2)} ر.س'),
                        _buildCell('${service.price.toStringAsFixed(2)} ر.س'),
                        _buildCell(service.name),
                      ],
                    ),
                  ),
                ],
              ),
              pw.SizedBox(height: 5),

              // Totals - Following correct business rules:
              // 1. Subtotal before tax
              // 2. Discount % and amount (applied to subtotal)
              // 3. Amount after discount
              // 4. Tax (calculated on discounted amount)
              // 5. Final total
              pw.Table(
                border: tableBorder,
                children: [
                  pw.TableRow(
                    children: [
                      _buildCell(services.length.toString()),
                      _buildCell('عدد الخدمات', weight: pw.FontWeight.bold),
                    ],
                  ),
                  // Step 1: Subtotal before tax and discount
                  pw.TableRow(
                    children: [
                      _buildCell('${subtotal.toStringAsFixed(2)} ر.س'),
                      _buildCell(
                        'الإجمالي قبل الضريبة',
                        weight: pw.FontWeight.bold,
                      ),
                    ],
                  ),
                  // Step 2: Discount percentage and amount
                  if (discount > 0 || discountAmount > 0)
                    pw.TableRow(
                      children: [
                        _buildCell(
                          discount > 0 ? '${discount.toStringAsFixed(0)}%' : '',
                        ),
                        _buildCell('نسبة الخصم', weight: pw.FontWeight.bold),
                      ],
                    ),
                  if (discount > 0 || discountAmount > 0)
                    pw.TableRow(
                      children: [
                        _buildCell('-${discountAmount.toStringAsFixed(2)} ر.س'),
                        _buildCell('مبلغ الخصم', weight: pw.FontWeight.bold),
                      ],
                    ),
                  // Step 3: Amount after discount (before tax)
                  if (discountAmount > 0)
                    pw.TableRow(
                      children: [
                        _buildCell(
                          '${amountAfterDiscount.toStringAsFixed(2)} ر.س',
                        ),
                        _buildCell(
                          'المبلغ بعد الخصم',
                          weight: pw.FontWeight.bold,
                        ),
                      ],
                    ),
                  // Step 4: Tax (on discounted amount)
                  pw.TableRow(
                    children: [
                      _buildCell('${tax.toStringAsFixed(2)} ر.س (15%)'),
                      _buildCell('قيمة الضريبة', weight: pw.FontWeight.bold),
                    ],
                  ),
                  // Step 5: Final total
                  pw.TableRow(
                    children: [
                      _buildCell(
                        '${finalTotal.toStringAsFixed(2)} ر.س',
                        weight: pw.FontWeight.bold,
                        fontSize: 12,
                      ),
                      _buildCell(
                        'الإجمالي النهائي',
                        weight: pw.FontWeight.bold,
                        fontSize: 12,
                      ),
                    ],
                  ),
                ],
              ),
              pw.SizedBox(height: 10),

              // Due Amount
              pw.Table(
                border: tableBorder,
                children: [
                  pw.TableRow(
                    children: [
                      _buildCell(
                        '${finalTotal.toStringAsFixed(2)} ر.س',
                        weight: pw.FontWeight.bold,
                        fontSize: 12,
                      ),
                      _buildCell(
                        'إجمالي المستحقات',
                        weight: pw.FontWeight.bold,
                        fontSize: 12,
                      ),
                    ],
                  ),
                ],
              ),
              pw.SizedBox(height: 5),

              // Balance
              pw.Table(
                border: tableBorder,
                children: [
                  pw.TableRow(
                    children: [
                      _buildCell('0.00 ر.س'),
                      _buildCell(
                        'المديونية السابقة',
                        weight: pw.FontWeight.bold,
                      ),
                    ],
                  ),
                  pw.TableRow(
                    children: [
                      _buildCell('${finalTotal.toStringAsFixed(2)} ر.س'),
                      _buildCell('الرصيد', weight: pw.FontWeight.bold),
                    ],
                  ),
                ],
              ),

              pw.Spacer(),

              // Footer
              pw.Center(
                child: pw.Text(
                  'شكرا لزيارتكم ... نتطلع لرؤيتكم مرة أخرى',
                  style: pw.TextStyle(font: ttf, fontSize: 10),
                ),
              ),
              pw.SizedBox(height: 5),
              pw.Center(
                child: pw.BarcodeWidget(
                  barcode: pw.Barcode.qrCode(),
                  data:
                      'Invoice Total: ${finalTotal.toStringAsFixed(2)} SAR', // Placeholder data for QR code
                  width: 80,
                  height: 80,
                ),
              ),
            ],
          ),
        );
      },
    ),
  );

  return pdf.save();
}
