import 'dart:io';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:share_plus/share_plus.dart';
import 'package:invoice_app/database/database_helper.dart';
import 'package:invoice_app/models/invoice_item.dart';

class PDFGenerator {
  static Future<void> generateAndSharePDF(
    BuildContext context,
    Map<String, dynamic> invoiceData,
  ) async {
    try {
      final pdfBytes = await _generatePDF(invoiceData);
      final tempDir = await getTemporaryDirectory();
      final file = File('${tempDir.path}/${invoiceData['invoice_number']}.pdf');
      await file.writeAsBytes(pdfBytes);

      await Share.shareXFiles(
        [XFile(file.path)],
        text: 'Invoice ${invoiceData['invoice_number']}',
      );
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error generating PDF: $e')),
        );
      }
    }
  }

  static Future<void> printInvoice(
    BuildContext context,
    Map<String, dynamic> invoiceData,
  ) async {
    try {
      await Printing.layoutPdf(
        onLayout: (format) => _generatePDF(invoiceData),
      );
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error printing: $e')),
        );
      }
    }
  }

  static Future<List<int>> _generatePDF(Map<String, dynamic> invoiceData) async {
    final pdf = pw.Document();
    final items = InvoiceItem.parseItems(invoiceData['items']);
    final company = await DatabaseHelper.instance.getCompanySettings();
    final isInterstate = (invoiceData['igst'] as num) > 0;

    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(32),
        build: (context) {
          return pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              // Header
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      pw.Text(
                        company['company_name'],
                        style: pw.TextStyle(fontSize: 24, fontWeight: pw.FontWeight.bold),
                      ),
                      pw.Text(company['address']),
                      pw.Text('${company['city']}, ${company['state']} - ${company['pincode']}'),
                      pw.Text('GSTIN: ${company['gstin']}'),
                      if (company['pan'] != null) pw.Text('PAN: ${company['pan']}'),
                      if (company['phone'] != null) pw.Text('Ph No: ${company['phone']}'),
                      if (company['email'] != null) pw.Text('Email: ${company['email']}'),
                    ],
                  ),
                  pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.end,
                    children: [
                      pw.Text(
                        'TAX INVOICE',
                        style: pw.TextStyle(fontSize: 20, fontWeight: pw.FontWeight.bold),
                      ),
                      pw.SizedBox(height: 8),
                      pw.Text('Invoice #: ${invoiceData['invoice_number']}'),
                      pw.Text('Date: ${invoiceData['invoice_date']}'),
                      pw.Text('Place of Supply: ${invoiceData['customer_state']}'),
                    ],
                  ),
                ],
              ),
              pw.SizedBox(height: 24),
              pw.Divider(thickness: 2),
              pw.SizedBox(height: 16),

              // Bill To
              pw.Text(
                'Bill To:',
                style: pw.TextStyle(fontSize: 14, fontWeight: pw.FontWeight.bold),
              ),
              pw.SizedBox(height: 8),
              pw.Text(
                invoiceData['customer_name'],
                style: pw.TextStyle(fontSize: 16, fontWeight: pw.FontWeight.bold),
              ),
              pw.Text(invoiceData['customer_address']),
              pw.Text('${invoiceData['customer_city']}, ${invoiceData['customer_state']} - ${invoiceData['customer_pincode']}'),
              if (invoiceData['customer_gstin'] != null &&
                  invoiceData['customer_gstin'].toString().isNotEmpty)
                pw.Text('GSTIN: ${invoiceData['customer_gstin']}'),
              pw.SizedBox(height: 24),

              // Items Table
              pw.Table.fromTextArray(
                headerStyle: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 10),
                cellStyle: const pw.TextStyle(fontSize: 9),
                cellAlignment: pw.Alignment.centerLeft,
                headerAlignment: pw.Alignment.centerLeft,
                headers: ['Sr', 'Description', 'HSN', 'Qty', 'Unit', 'Rate (₹)', 'GST %', 'Total (₹)'],
                data: items.asMap().entries.map((entry) {
                  final index = entry.key + 1;
                  final item = entry.value;
                  return [
                    index.toString(),
                    item.description,
                    item.hsnCode,
                    item.quantity.toString(),
                    item.unit,
                    item.rate.toStringAsFixed(2),
                    '${item.gstRate}%',
                    item.total.toStringAsFixed(2),
                  ];
                }).toList(),
              ),
              pw.SizedBox(height: 24),

              // Totals
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.end,
                children: [
                  pw.Container(
                    width: 300,
                    child: pw.Column(
                      children: [
                        _buildPDFTotalRow('Taxable Amount (Vegetables - 0%)', invoiceData['subtotal_vegetables']),
                        _buildPDFTotalRow('Taxable Amount (Other Items)', invoiceData['subtotal_fertilizers']),
                        pw.Divider(),
                        if (!isInterstate) ...[
                          _buildPDFTotalRow('CGST @ ${_getCGSTRate(items)}%', invoiceData['cgst']),
                          _buildPDFTotalRow('SGST @ ${_getSGSTRate(items)}%', invoiceData['sgst']),
                        ] else
                          _buildPDFTotalRow('IGST', invoiceData['igst']),
                        pw.Divider(thickness: 2),
                        _buildPDFTotalRow(
                          'Grand Total',
                          invoiceData['grand_total'],
                          isBold: true,
                        ),
                      ],
                    ),
                  ),
                ],
              ),

              pw.SizedBox(height: 8),
              pw.Text(
                'Amount in Words (Rounded): ${_convertToWords(invoiceData['grand_total'])}',
                style: pw.TextStyle(fontSize: 11, fontWeight: pw.FontWeight.bold),
              ),

              pw.Spacer(),

              // Bank Details
              if (company['bank_name'] != null) ...[
                pw.Divider(),
                pw.Text(
                  'Bank Details:',
                  style: pw.TextStyle(fontSize: 12, fontWeight: pw.FontWeight.bold),
                ),
                if (company['account_holder'] != null)
                  pw.Text('Account Name: ${company['account_holder']}', style: const pw.TextStyle(fontSize: 10)),
                pw.Text('Bank: ${company['bank_name']}', style: const pw.TextStyle(fontSize: 10)),
                if (company['account_number'] != null)
                  pw.Text('A/C No: ${company['account_number']}', style: const pw.TextStyle(fontSize: 10)),
                if (company['ifsc_code'] != null)
                  pw.Text('IFSC: ${company['ifsc_code']}', style: const pw.TextStyle(fontSize: 10)),
                pw.SizedBox(height: 8),
              ],

              // Terms
              pw.Divider(),
              pw.Text(
                'Terms & Conditions:',
                style: pw.TextStyle(fontSize: 10, fontWeight: pw.FontWeight.bold),
              ),
              pw.Text('1. Prices are subject to market fluctuation', style: const pw.TextStyle(fontSize: 9)),
              pw.Text('2. Delivery within 7 days from order', style: const pw.TextStyle(fontSize: 9)),
              pw.Text('3. Payment terms as agreed', style: const pw.TextStyle(fontSize: 9)),
              pw.SizedBox(height: 16),

              // Signature
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.end,
                children: [
                  pw.Column(
                    children: [
                      pw.SizedBox(height: 40),
                      pw.Container(
                        width: 150,
                        decoration: const pw.BoxDecoration(
                          border: pw.Border(top: pw.BorderSide()),
                        ),
                        padding: const pw.EdgeInsets.only(top: 4),
                        child: pw.Text(
                          'For ${company['company_name']}',
                          style: const pw.TextStyle(fontSize: 10),
                          textAlign: pw.TextAlign.center,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ],
          );
        },
      ),
    );

    return pdf.save();
  }

  static pw.Widget _buildPDFTotalRow(String label, dynamic amount, {bool isBold = false}) {
    final value = (amount is num) ? amount.toDouble() : 0.0;
    return pw.Padding(
      padding: const pw.EdgeInsets.symmetric(vertical: 4),
      child: pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
        children: [
          pw.Text(
            label,
            style: pw.TextStyle(
              fontSize: isBold ? 14 : 12,
              fontWeight: isBold ? pw.FontWeight.bold : pw.FontWeight.normal,
            ),
          ),
          pw.Text(
            '₹ ${NumberFormat('#,##,##0.00').format(value)}',
            style: pw.TextStyle(
              fontSize: isBold ? 14 : 12,
              fontWeight: isBold ? pw.FontWeight.bold : pw.FontWeight.normal,
            ),
          ),
        ],
      ),
    );
  }

  static String _getCGSTRate(List<InvoiceItem> items) {
    final gstItems = items.where((item) => item.gstRate > 0).toList();
    if (gstItems.isEmpty) return '0';
    return (gstItems.first.gstRate / 2).toStringAsFixed(1);
  }

  static String _getSGSTRate(List<InvoiceItem> items) {
    final gstItems = items.where((item) => item.gstRate > 0).toList();
    if (gstItems.isEmpty) return '0';
    return (gstItems.first.gstRate / 2).toStringAsFixed(1);
  }

  static String _convertToWords(dynamic amount) {
    final value = (amount is num) ? amount.toDouble() : 0.0;
    final roundedValue = value.round();

    if (roundedValue == 0) return 'Zero Only';

    final ones = ['', 'One', 'Two', 'Three', 'Four', 'Five', 'Six', 'Seven', 'Eight', 'Nine'];
    final teens = ['Ten', 'Eleven', 'Twelve', 'Thirteen', 'Fourteen', 'Fifteen', 'Sixteen', 'Seventeen', 'Eighteen', 'Nineteen'];
    final tens = ['', '', 'Twenty', 'Thirty', 'Forty', 'Fifty', 'Sixty', 'Seventy', 'Eighty', 'Ninety'];

    String convertLessThanThousand(int num) {
      if (num == 0) return '';
      if (num < 10) return ones[num];
      if (num < 20) return teens[num - 10];
      if (num < 100) {
        return '${tens[num ~/ 10]} ${ones[num % 10]}'.trim();
      }
      return '${ones[num ~/ 100]} Hundred ${convertLessThanThousand(num % 100)}'.trim();
    }

    if (roundedValue < 1000) {
      return 'Rupees ${convertLessThanThousand(roundedValue)} Only';
    }

    final crore = roundedValue ~/ 10000000;
    final lakh = (roundedValue % 10000000) ~/ 100000;
    final thousand = (roundedValue % 100000) ~/ 1000;
    final remainder = roundedValue % 1000;

    String result = 'Rupees ';
    if (crore > 0) result += '${convertLessThanThousand(crore)} Crore ';
    if (lakh > 0) result += '${convertLessThanThousand(lakh)} Lakh ';
    if (thousand > 0) result += '${convertLessThanThousand(thousand)} Thousand ';
    if (remainder > 0) result += convertLessThanThousand(remainder);

    return '${result.trim()} Only';
  }
}
