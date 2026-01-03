import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'dart:io';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:invoice_app/database/database_helper.dart';
import 'package:invoice_app/models/invoice_item.dart';

class InvoicePreviewScreen extends StatelessWidget {
  final Map<String, dynamic> invoiceData;

  const InvoicePreviewScreen({super.key, required this.invoiceData});

  @override
  Widget build(BuildContext context) {
    final items = InvoiceItem.parseItems(invoiceData['items']);
    final isInterstate = (invoiceData['igst'] as num) > 0;

    return Scaffold(
      appBar: AppBar(
        title: Text(invoiceData['invoice_number']),
        backgroundColor: Colors.green[700],
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.picture_as_pdf),
            onPressed: () => _generateAndSharePDF(context),
          ),
          IconButton(
            icon: const Icon(Icons.print),
            onPressed: () => _printInvoice(context),
          ),
          PopupMenuButton<String>(
            onSelected: (value) async {
              if (value == 'delete') {
                final confirm = await showDialog<bool>(
                  context: context,
                  builder: (context) => AlertDialog(
                    title: const Text('Delete Invoice'),
                    content: const Text('Are you sure you want to delete this invoice?'),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.pop(context, false),
                        child: const Text('Cancel'),
                      ),
                      TextButton(
                        onPressed: () => Navigator.pop(context, true),
                        style: TextButton.styleFrom(foregroundColor: Colors.red),
                        child: const Text('Delete'),
                      ),
                    ],
                  ),
                );

                if (confirm == true && context.mounted) {
                  await DatabaseHelper.instance.deleteInvoice(
                    invoiceData['invoice_number'],
                  );
                  if (context.mounted) {
                    Navigator.pop(context);
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Invoice deleted')),
                    );
                  }
                }
              }
            },
            itemBuilder: (context) => [
              const PopupMenuItem(
                value: 'delete',
                child: Row(
                  children: [
                    Icon(Icons.delete, color: Colors.red),
                    SizedBox(width: 8),
                    Text('Delete Invoice'),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'JA Agro Inputs & Trading',
                              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                            ),
                            Text(
                              'Invoice: ${invoiceData['invoice_number']}',
                              style: TextStyle(fontSize: 14, color: Colors.grey[600]),
                            ),
                          ],
                        ),
                        Text(
                          invoiceData['invoice_date'],
                          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),

            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Bill To:',
                      style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      invoiceData['customer_name'],
                      style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                    ),
                    Text(invoiceData['customer_address']),
                    Text('${invoiceData['customer_city']}, ${invoiceData['customer_state']} - ${invoiceData['customer_pincode']}'),
                    if (invoiceData['customer_gstin'] != null &&
                        invoiceData['customer_gstin'].toString().isNotEmpty)
                      Text('GSTIN: ${invoiceData['customer_gstin']}'),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),

            const Text(
              'Items',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: DataTable(
                columnSpacing: 20,
                columns: const [
                  DataColumn(label: Text('#', style: TextStyle(fontWeight: FontWeight.bold))),
                  DataColumn(label: Text('Description', style: TextStyle(fontWeight: FontWeight.bold))),
                  DataColumn(label: Text('HSN', style: TextStyle(fontWeight: FontWeight.bold))),
                  DataColumn(label: Text('Qty', style: TextStyle(fontWeight: FontWeight.bold))),
                  DataColumn(label: Text('Rate', style: TextStyle(fontWeight: FontWeight.bold))),
                  DataColumn(label: Text('GST%', style: TextStyle(fontWeight: FontWeight.bold))),
                  DataColumn(label: Text('Amount', style: TextStyle(fontWeight: FontWeight.bold))),
                ],
                rows: items.asMap().entries.map((entry) {
                  final index = entry.key + 1;
                  final item = entry.value;
                  return DataRow(cells: [
                    DataCell(Text(index.toString())),
                    DataCell(Text(item.description)),
                    DataCell(Text(item.hsnCode)),
                    DataCell(Text('${item.quantity} ${item.unit}')),
                    DataCell(Text('₹${item.rate.toStringAsFixed(2)}')),
                    DataCell(Text('${item.gstRate}%')),
                    DataCell(Text('₹${item.total.toStringAsFixed(2)}')),
                  ]);
                }).toList(),
              ),
            ),
            const SizedBox(height: 24),

            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.green[50],
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.green),
              ),
              child: Column(
                children: [
                  _buildTotalRow('Vegetables (0% GST)', invoiceData['subtotal_vegetables']),
                  _buildTotalRow('Other Items', invoiceData['subtotal_fertilizers']),
                  const Divider(),
                  if (!isInterstate) ...[
                    _buildTotalRow('CGST', invoiceData['cgst']),
                    _buildTotalRow('SGST', invoiceData['sgst']),
                  ] else
                    _buildTotalRow('IGST', invoiceData['igst']),
                  const Divider(thickness: 2),
                  _buildTotalRow(
                    'Grand Total',
                    invoiceData['grand_total'],
                    isBold: true,
                    fontSize: 20,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            const Card(
              child: Padding(
                padding: EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Terms & Conditions:',
                      style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
                    ),
                    SizedBox(height: 8),
                    Text('1. Payment due within 30 days', style: TextStyle(fontSize: 12)),
                    Text('2. Goods once sold will not be taken back', style: TextStyle(fontSize: 12)),
                    Text('3. Subject to Nagaon jurisdiction', style: TextStyle(fontSize: 12)),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTotalRow(String label, dynamic amount, {bool isBold = false, double fontSize = 16}) {
    final value = (amount is num) ? amount.toDouble() : 0.0;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: fontSize,
              fontWeight: isBold ? FontWeight.bold : FontWeight.normal,
            ),
          ),
          Text(
            '₹ ${NumberFormat('#,##,##0.00').format(value)}',
            style: TextStyle(
              fontSize: fontSize,
              fontWeight: isBold ? FontWeight.bold : FontWeight.normal,
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _generateAndSharePDF(BuildContext context) async {
    try {
      final pdfBytes = await _generatePDF();
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

  Future<void> _printInvoice(BuildContext context) async {
    try {
      await Printing.layoutPdf(
        onLayout: (format) => _generatePDF(),
      );
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error printing: $e')),
        );
      }
    }
  }

  Future<List<int>> _generatePDF() async {
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

              pw.Divider(),
              pw.Text(
                'Terms & Conditions:',
                style: pw.TextStyle(fontSize: 10, fontWeight: pw.FontWeight.bold),
              ),
              pw.Text('1. Payment due within 30 days', style: const pw.TextStyle(fontSize: 9)),
              pw.Text('2. Goods once sold will not be taken back', style: const pw.TextStyle(fontSize: 9)),
              pw.Text('3. Subject to Nagaon jurisdiction', style: const pw.TextStyle(fontSize: 9)),
              pw.SizedBox(height: 16),

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

  pw.Widget _buildPDFTotalRow(String label, dynamic amount, {bool isBold = false}) {
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
