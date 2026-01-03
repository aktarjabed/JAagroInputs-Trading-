import 'dart:io';
import 'package:flutter/services.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';
import 'package:invoice_app/utils/constants.dart';
import 'package:invoice_app/utils/gst_helper.dart';

class PdfGenerator {
  static Future<File> generateInvoice(Map<String, dynamic> invoice, Map<String, dynamic> companySettings, List<Map<String, dynamic>> items) async {
    final pdf = pw.Document();

    // Load font if needed, otherwise use standard
    // final font = await rootBundle.load("assets/fonts/OpenSans-Regular.ttf");
    // final ttf = pw.Font.ttf(font);

    final isInterState = GSTHelper.isInterState(invoice['place_of_supply'] ?? '18');
    final placeOfSupplyName = Constants.getStateName(invoice['place_of_supply'] ?? '18');

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(32),
        build: (context) => [
          _buildHeader(invoice, companySettings, placeOfSupplyName),
          pw.SizedBox(height: 20),
          _buildCustomerSection(invoice),
          pw.SizedBox(height: 20),
          _buildInvoiceItemsTable(items, isInterState),
          pw.SizedBox(height: 20),
          _buildTotalsSection(invoice, isInterState),
          pw.Spacer(),
          _buildFooter(companySettings),
        ],
      ),
    );

    return _saveDocument(name: 'invoice_${invoice['invoice_number']}.pdf', pdf: pdf);
  }

  static pw.Widget _buildHeader(Map<String, dynamic> invoice, Map<String, dynamic> settings, String placeOfSupplyName) {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Row(
          mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
          children: [
            pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Text(settings['company_name'], style: pw.TextStyle(fontSize: 24, fontWeight: pw.FontWeight.bold)),
                pw.Text(settings['address']),
                pw.Text('${settings['city']}, ${settings['state']} - ${settings['pincode']}'),
                pw.Text('GSTIN: ${settings['gstin']}'),
                pw.Text('Phone: ${settings['phone']}'),
              ],
            ),
            pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.end,
              children: [
                pw.Text('TAX INVOICE', style: pw.TextStyle(fontSize: 20, fontWeight: pw.FontWeight.bold, color: PdfColors.green800)),
                pw.SizedBox(height: 10),
                pw.Text('Invoice #: ${invoice['invoice_number']}', style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
                pw.Text('Date: ${invoice['invoice_date']}'),
                pw.Text('Place of Supply: $placeOfSupplyName'),
                if (invoice['reverse_charge'] == 'Yes')
                   pw.Text('Reverse Charge: Yes', style: pw.TextStyle(color: PdfColors.red)),
              ],
            ),
          ],
        ),
        pw.Divider(thickness: 1),
      ],
    );
  }

  static pw.Widget _buildCustomerSection(Map<String, dynamic> invoice) {
    return pw.Row(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Expanded(
          child: pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Text('Bill To / Ship To:', style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 14)),
              pw.SizedBox(height: 5),
              pw.Text(invoice['customer_name'], style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
              pw.Text(invoice['customer_address']),
              pw.Text('${invoice['customer_city']}, ${invoice['customer_state']} - ${invoice['customer_pincode']}'),
              if (invoice['customer_gstin'] != null && invoice['customer_gstin'].isNotEmpty)
                pw.Text('GSTIN: ${invoice['customer_gstin']}'),
            ],
          ),
        ),
      ],
    );
  }

  static pw.Widget _buildInvoiceItemsTable(List<Map<String, dynamic>> items, bool isInterState) {
    final headers = [
      '#',
      'Item / Category',
      'HSN',
      'Batch / Exp',
      'Qty',
      'Rate',
      'Tax',
      'Total'
    ];

    final data = items.asMap().entries.map((entry) {
      final index = entry.key + 1;
      final item = entry.value;

      final category = item['product_category'] ?? '';
      final batch = item['batch_number'] ?? '-';
      final exp = item['expiry_date'] != null
          ? DateFormat('dd/MM/yy').format(DateTime.parse(item['expiry_date']))
          : '-';

      final gstRate = (item['gst_rate'] as num).toDouble();

      return [
        index.toString(),
        '${item['description']}\n${category.isNotEmpty ? "($category)" : ""}',
        item['hsn_code'],
        '$batch\n$exp',
        '${item['quantity']} ${item['unit']}',
        GSTHelper.formatCurrency((item['rate'] as num).toDouble()).replaceAll('₹ ', ''),
        '${gstRate}%',
        GSTHelper.formatCurrency((item['total'] as num).toDouble()).replaceAll('₹ ', ''),
      ];
    }).toList();

    return pw.Table.fromTextArray(
      headers: headers,
      data: data,
      border: null,
      headerStyle: pw.TextStyle(fontWeight: pw.FontWeight.bold, color: PdfColors.white),
      headerDecoration: const pw.BoxDecoration(color: PdfColors.green700),
      cellHeight: 30,
      cellAlignments: {
        0: pw.Alignment.center,
        1: pw.Alignment.centerLeft,
        2: pw.Alignment.center,
        3: pw.Alignment.center,
        4: pw.Alignment.center,
        5: pw.Alignment.centerRight,
        6: pw.Alignment.center,
        7: pw.Alignment.centerRight,
      },
      oddRowDecoration: const pw.BoxDecoration(color: PdfColors.grey100),
    );
  }

  static pw.Widget _buildTotalsSection(Map<String, dynamic> invoice, bool isInterState) {
    final subtotalVeg = (invoice['subtotal_vegetables'] as num).toDouble();
    final subtotalFert = (invoice['subtotal_fertilizers'] as num).toDouble();
    final totalTaxable = subtotalVeg + subtotalFert;

    final cgst = (invoice['cgst'] as num).toDouble();
    final sgst = (invoice['sgst'] as num).toDouble();
    final igst = (invoice['igst'] as num).toDouble();
    final grandTotal = (invoice['grand_total'] as num).toDouble();

    // Calculate simple words (Placeholder)
    final amountInWords = GSTHelper.amountToWords(grandTotal);

    return pw.Row(
      mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Expanded(
          flex: 2,
          child: pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Text('Amount in Words:', style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
              pw.Text(amountInWords, style: pw.TextStyle(fontStyle: pw.FontStyle.italic)),
              pw.SizedBox(height: 10),
              pw.Text('Terms & Conditions:', style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
              pw.Text('1. Goods once sold will not be taken back.', style: const pw.TextStyle(fontSize: 10)),
              pw.Text('2. Interest @ 18% p.a. will be charged if payment is delayed.', style: const pw.TextStyle(fontSize: 10)),
              pw.Text('3. Subject to Cachar Jurisdiction.', style: const pw.TextStyle(fontSize: 10)),
            ],
          ),
        ),
        pw.SizedBox(width: 20),
        pw.Expanded(
          flex: 1,
          child: pw.Column(
            children: [
              _buildTotalRow('Taxable Amount', totalTaxable),
              if (!isInterState && cgst > 0) ...[
                _buildTotalRow('CGST', cgst),
                _buildTotalRow('SGST', sgst),
              ],
              if (isInterState && igst > 0)
                _buildTotalRow('IGST', igst),

              pw.Divider(),
              _buildTotalRow('Grand Total', grandTotal, isBold: true, fontSize: 14),
            ],
          ),
        ),
      ],
    );
  }

  static pw.Widget _buildTotalRow(String label, double amount, {bool isBold = false, double fontSize = 12}) {
    return pw.Padding(
      padding: const pw.EdgeInsets.symmetric(vertical: 2),
      child: pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
        children: [
          pw.Text(label, style: pw.TextStyle(fontWeight: isBold ? pw.FontWeight.bold : pw.FontWeight.normal, fontSize: fontSize)),
          pw.Text(GSTHelper.formatCurrency(amount).replaceAll('₹ ', ''), style: pw.TextStyle(fontWeight: isBold ? pw.FontWeight.bold : pw.FontWeight.normal, fontSize: fontSize)),
        ],
      ),
    );
  }

  static pw.Widget _buildFooter(Map<String, dynamic> settings) {
    return pw.Column(
      children: [
        pw.Divider(),
        pw.Row(
          mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
          children: [
            pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Text('Bank Details:', style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
                pw.Text('Bank: ${settings['bank_name']}'),
                pw.Text('A/c No: ${settings['account_number']}'),
                pw.Text('IFSC: ${settings['ifsc_code']}'),
              ],
            ),
            pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.end,
              children: [
                pw.Text('For ${settings['company_name']}', style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
                pw.SizedBox(height: 30),
                pw.Text('Authorized Signatory'),
              ],
            ),
          ],
        ),
        pw.SizedBox(height: 20),
        pw.Center(child: pw.Text('Thank you for your business!', style: const pw.TextStyle(color: PdfColors.grey))),
      ],
    );
  }

  static Future<File> _saveDocument({required String name, required pw.Document pdf}) async {
    final bytes = await pdf.save();
    final dir = await getApplicationDocumentsDirectory();
    final file = File('${dir.path}/$name');
    await file.writeAsBytes(bytes);
    return file;
  }
}
