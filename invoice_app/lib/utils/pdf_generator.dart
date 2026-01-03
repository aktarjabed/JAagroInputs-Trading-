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
                      if (company['phone'] != null) pw.Text('Phone: ${company['phone']}'),
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
                headerStyle: pw.TextStyle(fontWeight: pw.FontWeight.bold),
                cellAlignment: pw.Alignment.centerLeft,
                headers: ['#', 'Description', 'HSN', 'Qty', 'Rate', 'GST%', 'Amount'],
                data: items.asMap().entries.map((entry) {
                  final index = entry.key + 1;
                  final item = entry.value;
                  return [
                    index.toString(),
                    item.description,
                    item.hsnCode,
                    '${item.quantity} ${item.unit}',
                    '₹${item.rate.toStringAsFixed(2)}',
                    '${item.gstRate}%',
                    '₹${item.total.toStringAsFixed(2)}',
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
                        _buildPDFTotalRow('Vegetables (0% GST)', invoiceData['subtotal_vegetables']),
                        _buildPDFTotalRow('Other Items', invoiceData['subtotal_fertilizers']),
                        pw.Divider(),
                        if (!isInterstate) ...[
                          _buildPDFTotalRow('CGST', invoiceData['cgst']),
                          _buildPDFTotalRow('SGST', invoiceData['sgst']),
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
              pw.Spacer(),

              // Bank Details
              if (company['bank_name'] != null) ...[
                pw.Divider(),
                pw.Text(
                  'Bank Details:',
                  style: pw.TextStyle(fontSize: 12, fontWeight: pw.FontWeight.bold),
                ),
                pw.Text('Bank: ${company['bank_name']}', style: const pw.TextStyle(fontSize: 10)),
                if (company['account_number'] != null)
                  pw.Text('Account: ${company['account_number']}', style: const pw.TextStyle(fontSize: 10)),
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
              pw.Text('1. Payment due within 30 days', style: const pw.TextStyle(fontSize: 9)),
              pw.Text('2. Goods once sold will not be taken back', style: const pw.TextStyle(fontSize: 9)),
              pw.Text('3. Subject to Nagaon jurisdiction', style: const pw.TextStyle(fontSize: 9)),
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
                          'Authorized Signature',
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
}
