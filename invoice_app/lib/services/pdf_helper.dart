// lib/services/pdf_helper.dart
// COMPLETE - PRODUCTION READY
// Professional PDF Generation for Invoices

import 'dart:typed_data';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import '../utils/number_to_words_converter.dart';
import '../models/invoice_model.dart';
import '../models/company_settings_model.dart';
import '../services/settings_service.dart';
import '../utils/constants.dart';

class PDFHelper {
  static Future<void> generateInvoicePDF(InvoiceModel invoice) async {
    final pdf = pw.Document();

    // Fetch settings for PDF
    final settingsService = SettingsService();
    final settings = await settingsService.getSettings();

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(32),
        build: (context) => [
          _buildHeader(invoice, settings),
          pw.SizedBox(height: 20),
          _buildBuyerDetails(invoice),
          pw.SizedBox(height: 20),
          _buildLineItemsTable(invoice),
          pw.SizedBox(height: 20),
          _buildTotals(invoice),
          pw.SizedBox(height: 20),
          _buildFooter(invoice, settings),
        ],
      ),
    );

    await Printing.layoutPdf(
      onLayout: (format) async => pdf.save(),
    );
  }

  static pw.Widget _buildHeader(InvoiceModel invoice, CompanySettingsModel settings) {
    return pw.Row(
      mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            pw.Text(
              settings.companyName,
              style: pw.TextStyle(
                fontSize: 18,
                fontWeight: pw.FontWeight.bold,
              ),
            ),
            pw.SizedBox(height: 4),
            pw.Text('GSTIN: ${settings.gstin}', style: const pw.TextStyle(fontSize: 10)),
            pw.Text('PAN: ${settings.pan}', style: const pw.TextStyle(fontSize: 10)),
            pw.Text(
              '${settings.address}, ${settings.state} - ${settings.pincode}',
              style: const pw.TextStyle(fontSize: 10),
            ),
            pw.Text('Ph: ${settings.phone}', style: const pw.TextStyle(fontSize: 10)),
          ],
        ),
        pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.end,
          children: [
            pw.Text(
              'TAX INVOICE',
              style: pw.TextStyle(
                fontSize: 20,
                fontWeight: pw.FontWeight.bold,
                color: PdfColor.fromHex('#2E7D32'),
              ),
            ),
            pw.SizedBox(height: 8),
            pw.Text('Invoice No: ${invoice.invoiceNumber}',
                    style: pw.TextStyle(fontSize: 11, fontWeight: pw.FontWeight.bold)),
            pw.Text('Date: ${invoice.getFormattedDate()}', style: const pw.TextStyle(fontSize: 10)),
            pw.Text('Place of Supply: ${invoice.placeOfSupply}', style: const pw.TextStyle(fontSize: 10)),
          ],
        ),
      ],
    );
  }

  static pw.Widget _buildBuyerDetails(InvoiceModel invoice) {
    return pw.Container(
      padding: const pw.EdgeInsets.all(12),
      decoration: pw.BoxDecoration(
        border: pw.Border.all(color: PdfColors.grey400),
        borderRadius: const pw.BorderRadius.all(pw.Radius.circular(4)),
      ),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Text('Bill To:', style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 12)),
          pw.SizedBox(height: 4),
          pw.Text(invoice.buyerName, style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
          pw.Text('GSTIN: ${invoice.buyerGSTIN}', style: const pw.TextStyle(fontSize: 10)),
          pw.Text('PAN: ${invoice.buyerPAN}', style: const pw.TextStyle(fontSize: 10)),
          pw.Text('State: ${invoice.buyerState}', style: const pw.TextStyle(fontSize: 10)),
          pw.Text('Type: ${invoice.buyerType}', style: const pw.TextStyle(fontSize: 10)),
          if (invoice.buyerContactPerson.isNotEmpty)
            pw.Text('Contact: ${invoice.buyerContactPerson}', style: const pw.TextStyle(fontSize: 10)),
          if (invoice.deliveryAddress.isNotEmpty) ...[
            pw.SizedBox(height: 8),
            pw.Text('Delivery Address:', style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 10)),
            pw.Text(invoice.deliveryAddress, style: const pw.TextStyle(fontSize: 10)),
          ],
        ],
      ),
    );
  }

  static pw.Widget _buildLineItemsTable(InvoiceModel invoice) {
    return pw.Table(
      border: pw.TableBorder.all(color: PdfColors.grey400),
      columnWidths: {
        0: const pw.FixedColumnWidth(30),
        1: const pw.FixedColumnWidth(50),
        2: const pw.FlexColumnWidth(2),
        3: const pw.FlexColumnWidth(1.5),
        4: const pw.FixedColumnWidth(40),
        5: const pw.FixedColumnWidth(40),
        6: const pw.FixedColumnWidth(50),
        7: const pw.FixedColumnWidth(60),
      },
      children: [
        pw.TableRow(
          decoration: pw.BoxDecoration(color: PdfColor.fromHex('#2E7D32')),
          children: [
            _buildTableHeader('#'),
            _buildTableHeader('HSN'),
            _buildTableHeader('Product'),
            _buildTableHeader('Category'),
            _buildTableHeader('Qty'),
            _buildTableHeader('Unit'),
            _buildTableHeader('Rate'),
            _buildTableHeader('Amount'),
          ],
        ),
        ...invoice.items.asMap().entries.map((entry) {
          final index = entry.key + 1;
          final item = entry.value;
          return pw.TableRow(
            children: [
              _buildTableCell(index.toString()),
              _buildTableCell(item.hsnCode),
              _buildTableCellLeft(item.productName),
              _buildTableCell(item.productCategory ?? ''),
              _buildTableCell(item.quantity.toString()),
              _buildTableCell(item.unit),
              _buildTableCell('₹${item.rate.toStringAsFixed(2)}'),
              _buildTableCell('₹${item.lineTotal.toStringAsFixed(2)}', bold: true),
            ],
          );
        }).toList(),
      ],
    );
  }

  static pw.Widget _buildTotals(InvoiceModel invoice) {
    return pw.Row(
      mainAxisAlignment: pw.MainAxisAlignment.end,
      children: [
        pw.Container(
          width: 250,
          padding: const pw.EdgeInsets.all(12),
          decoration: pw.BoxDecoration(
            border: pw.Border.all(color: PdfColors.grey400),
            borderRadius: const pw.BorderRadius.all(pw.Radius.circular(4)),
          ),
          child: pw.Column(
            children: [
              _buildTotalRow('Subtotal', invoice.subtotal),
              if (invoice.cgstAmount > 0) ...[
                _buildTotalRow('CGST (Intrastate)', invoice.cgstAmount),
                _buildTotalRow('SGST (Intrastate)', invoice.sgstAmount),
              ],
              if (invoice.igstAmount > 0)
                _buildTotalRow('IGST (Interstate)', invoice.igstAmount),
              if (invoice.discountAmount > 0)
                _buildTotalRow('Discount', invoice.discountAmount),
              pw.Divider(thickness: 1.5),
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Text(
                    'GRAND TOTAL',
                    style: pw.TextStyle(
                      fontWeight: pw.FontWeight.bold,
                      fontSize: 14,
                      color: PdfColor.fromHex('#2E7D32'),
                    ),
                  ),
                  pw.Text(
                    '₹${invoice.grandTotal.toStringAsFixed(2)}',
                    style: pw.TextStyle(
                      fontWeight: pw.FontWeight.bold,
                      fontSize: 14,
                      color: PdfColor.fromHex('#2E7D32'),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }

  static pw.Widget _buildFooter(InvoiceModel invoice, CompanySettingsModel settings) {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Container(
          padding: const pw.EdgeInsets.all(10),
          decoration: pw.BoxDecoration(
            border: pw.Border.all(color: PdfColors.grey400),
            color: PdfColors.grey100,
            borderRadius: const pw.BorderRadius.all(pw.Radius.circular(4)),
          ),
          child: pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Text(
                'Amount in Words (Rounded):',
                style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 10),
              ),
              pw.Text(
                NumberToWordsConverter.convertToIndianWords(invoice.grandTotal),
                style: const pw.TextStyle(fontSize: 10),
              ),
            ],
          ),
        ),
        pw.SizedBox(height: 16),
        pw.Row(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            pw.Expanded(
              child: pw.Container(
                padding: const pw.EdgeInsets.all(10),
                decoration: pw.BoxDecoration(
                  border: pw.Border.all(color: PdfColors.grey400),
                  borderRadius: const pw.BorderRadius.all(pw.Radius.circular(4)),
                ),
                child: pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Text('Bank Details:', style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 11)),
                    pw.Text('Account Name: JA Agro Inputs & Trading', style: const pw.TextStyle(fontSize: 9)),
                    pw.Text('Bank: State Bank of India', style: const pw.TextStyle(fontSize: 9)),
                    pw.Text('A/C No: 36893269388', style: const pw.TextStyle(fontSize: 9)),
                    pw.Text('IFSC: SBIN0001803', style: const pw.TextStyle(fontSize: 9)),
                  ],
                ),
              ),
            ),
            pw.Expanded(
              child: pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Text('Payment Terms:', style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 11)),
                  pw.Text(invoice.paymentTerms, style: const pw.TextStyle(fontSize: 9)),
                  pw.Text('Due Date: ${invoice.paymentDueDate.toString().substring(0, 10)}',
                          style: const pw.TextStyle(fontSize: 9)),
                ],
              ),
            ),
          ],
        ),
        pw.SizedBox(height: 24),
        pw.Row(
          mainAxisAlignment: pw.MainAxisAlignment.end,
          children: [
            pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.end,
              children: [
                pw.Text('For ${settings.companyName}',
                        style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 10)),
                pw.SizedBox(height: 30),
                pw.Text('Authorized Signatory', style: const pw.TextStyle(fontSize: 9)),
              ],
            ),
          ],
        ),
      ],
    );
  }

  static pw.Widget _buildTableHeader(String text) {
    return pw.Padding(
      padding: const pw.EdgeInsets.all(4),
      child: pw.Text(
        text,
        style: pw.TextStyle(
          fontWeight: pw.FontWeight.bold,
          fontSize: 9,
          color: PdfColors.white,
        ),
        textAlign: pw.TextAlign.center,
      ),
    );
  }

  static pw.Widget _buildTableCell(String text, {bool bold = false}) {
    return pw.Padding(
      padding: const pw.EdgeInsets.all(4),
      child: pw.Text(
        text,
        style: pw.TextStyle(
          fontSize: 8,
          fontWeight: bold ? pw.FontWeight.bold : pw.FontWeight.normal,
        ),
        textAlign: pw.TextAlign.center,
      ),
    );
  }

  static pw.Widget _buildTableCellLeft(String text, {bool bold = false}) {
    return pw.Padding(
      padding: const pw.EdgeInsets.all(4),
      child: pw.Text(
        text,
        style: pw.TextStyle(
          fontSize: 8,
          fontWeight: bold ? pw.FontWeight.bold : pw.FontWeight.normal,
        ),
        textAlign: pw.TextAlign.left,
      ),
    );
  }

  static pw.Widget _buildTotalRow(String label, double amount) {
    return pw.Padding(
      padding: const pw.EdgeInsets.symmetric(vertical: 2),
      child: pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
        children: [
          pw.Text(label, style: const pw.TextStyle(fontSize: 10)),
          pw.Text('₹${amount.toStringAsFixed(2)}', style: const pw.TextStyle(fontSize: 10)),
        ],
      ),
    );
  }
}
