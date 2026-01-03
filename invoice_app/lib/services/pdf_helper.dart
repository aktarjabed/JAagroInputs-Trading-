// lib/services/pdf_helper.dart
// COMPLETE - PRODUCTION READY
// PDF Generation for Professional Invoices (Phase 1-2)

import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:intl/intl.dart';
import '../models/invoice_model.dart';

class PDFHelper {
  static Future<void> generateInvoicePDF(InvoiceModel invoice) async {
    final pdf = pw.Document();

    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(20),
        build: (pw.Context context) {
          return pw.Column(
            children: [
              // Header with Company Details
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      pw.Text(
                        'JA AGRO INPUTS & TRADING',
                        style: pw.TextStyle(
                          fontSize: 18,
                          fontWeight: pw.FontWeight.bold,
                        ),
                      ),
                      pw.SizedBox(height: 4),
                      pw.Text('GSTIN: 18CCFPB3144R1Z5', style: const pw.TextStyle(fontSize: 10)),
                      pw.Text('PAN: CCFPB3144R', style: const pw.TextStyle(fontSize: 10)),
                      pw.Text('Badarpur, Assam - 788102', style: const pw.TextStyle(fontSize: 10)),
                    ],
                  ),
                  pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.end,
                    children: [
                      pw.Text(
                        'INVOICE',
                        style: pw.TextStyle(
                          fontSize: 24,
                          fontWeight: pw.FontWeight.bold,
                        ),
                      ),
                      pw.Text(invoice.invoiceNumber, style: const pw.TextStyle(fontSize: 12)),
                    ],
                  ),
                ],
              ),

              pw.SizedBox(height: 20),
              pw.Divider(thickness: 2),
              pw.SizedBox(height: 20),

              // Invoice Details
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      pw.Text('Invoice Date', style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
                      pw.Text(invoice.getFormattedDate()),
                      pw.SizedBox(height: 8),
                      pw.Text('Due Date', style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
                      pw.Text(DateFormat('dd-MMM-yyyy').format(invoice.paymentDueDate)),
                    ],
                  ),
                  pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      pw.Text('Place of Supply', style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
                      pw.Text(invoice.placeOfSupply),
                      pw.SizedBox(height: 8),
                      pw.Text('Supply Type', style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
                      pw.Text(invoice.supplyType),
                    ],
                  ),
                  pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      pw.Text('GST Type', style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
                      pw.Text(
                        invoice.cgstAmount > 0 ? 'CGST/SGST' : 'IGST',
                        style: const pw.TextStyle(fontSize: 12),
                      ),
                      pw.SizedBox(height: 8),
                      pw.Text('Reverse Charge', style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
                      pw.Text(invoice.reverseChargeMechanism),
                    ],
                  ),
                ],
              ),

              pw.SizedBox(height: 20),

              // Bill To & Ship To
              pw.Row(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Expanded(
                    child: pw.Column(
                      crossAxisAlignment: pw.CrossAxisAlignment.start,
                      children: [
                        pw.Text('BILL TO:', style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
                        pw.SizedBox(height: 8),
                        pw.Text(invoice.buyerName, style: const pw.TextStyle(fontSize: 12, fontWeight: pw.FontWeight.bold)),
                        pw.Text('GSTIN: ${invoice.buyerGSTIN}', style: const pw.TextStyle(fontSize: 10)),
                        pw.Text('PAN: ${invoice.buyerPAN}', style: const pw.TextStyle(fontSize: 10)),
                        pw.Text('State: ${invoice.buyerState}', style: const pw.TextStyle(fontSize: 10)),
                        pw.Text('Contact: ${invoice.buyerContactPerson}', style: const pw.TextStyle(fontSize: 10)),
                      ],
                    ),
                  ),
                  pw.Expanded(
                    child: pw.Column(
                      crossAxisAlignment: pw.CrossAxisAlignment.start,
                      children: [
                        pw.Text('SHIP TO:', style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
                        pw.SizedBox(height: 8),
                        pw.Text(invoice.deliveryAddress, style: const pw.TextStyle(fontSize: 10)),
                        if (invoice.poReferenceNumber.isNotEmpty)
                          pw.Text('PO: ${invoice.poReferenceNumber}', style: const pw.TextStyle(fontSize: 10)),
                        if (invoice.deliveryDate != null)
                          pw.Text(
                            'Delivery Date: ${DateFormat('dd-MMM-yyyy').format(invoice.deliveryDate!)}',
                            style: const pw.TextStyle(fontSize: 10),
                          ),
                      ],
                    ),
                  ),
                ],
              ),

              pw.SizedBox(height: 20),

              // Line Items Table (Phase 1-2 Data)
              pw.Table(
                border: pw.TableBorder.all(width: 0.5),
                columnWidths: {
                  0: const pw.FlexColumnWidth(1),
                  1: const pw.FlexColumnWidth(1.5),
                  2: const pw.FlexColumnWidth(1),
                  3: const pw.FlexColumnWidth(1.2),
                  4: const pw.FlexColumnWidth(0.8),
                  5: const pw.FlexColumnWidth(1),
                  6: const pw.FlexColumnWidth(1),
                  7: const pw.FlexColumnWidth(1.2),
                },
                children: [
                  // Header Row
                  pw.TableRow(
                    decoration: const pw.BoxDecoration(color: PdfColors.grey300),
                    children: [
                      pw.Padding(
                        padding: const pw.EdgeInsets.all(6),
                        child: pw.Text('HSN', style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 9)),
                      ),
                      pw.Padding(
                        padding: const pw.EdgeInsets.all(6),
                        child: pw.Text('Product', style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 9)),
                      ),
                      pw.Padding(
                        padding: const pw.EdgeInsets.all(6),
                        child: pw.Text('Category', style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 9)),
                      ),
                      pw.Padding(
                        padding: const pw.EdgeInsets.all(6),
                        child: pw.Text('Qty', style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 9)),
                      ),
                      pw.Padding(
                        padding: const pw.EdgeInsets.all(6),
                        child: pw.Text('Unit', style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 9)),
                      ),
                      pw.Padding(
                        padding: const pw.EdgeInsets.all(6),
                        child: pw.Text('Batch #', style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 9)),
                      ),
                      pw.Padding(
                        padding: const pw.EdgeInsets.all(6),
                        child: pw.Text('Expiry', style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 9)),
                      ),
                      pw.Padding(
                        padding: const pw.EdgeInsets.all(6),
                        child: pw.Text('Amount', style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 9)),
                      ),
                    ],
                  ),
                  // Item Rows
                  ...invoice.items.map((item) {
                    return pw.TableRow(
                      children: [
                        pw.Padding(
                          padding: const pw.EdgeInsets.all(6),
                          child: pw.Text(item.hsnCode, style: const pw.TextStyle(fontSize: 9)),
                        ),
                        pw.Padding(
                          padding: const pw.EdgeInsets.all(6),
                          child: pw.Text(item.productName, style: const pw.TextStyle(fontSize: 9)),
                        ),
                        pw.Padding(
                          padding: const pw.EdgeInsets.all(6),
                          child: pw.Text(item.productCategory ?? '', style: const pw.TextStyle(fontSize: 9)),
                        ),
                        pw.Padding(
                          padding: const pw.EdgeInsets.all(6),
                          child: pw.Text('${item.quantity}', style: const pw.TextStyle(fontSize: 9)),
                        ),
                        pw.Padding(
                          padding: const pw.EdgeInsets.all(6),
                          child: pw.Text(item.unit, style: const pw.TextStyle(fontSize: 9)),
                        ),
                        pw.Padding(
                          padding: const pw.EdgeInsets.all(6),
                          child: pw.Text(item.batchNumber ?? '', style: const pw.TextStyle(fontSize: 9)),
                        ),
                        pw.Padding(
                          padding: const pw.EdgeInsets.all(6),
                          child: pw.Text(item.expiryDate ?? '', style: const pw.TextStyle(fontSize: 9)),
                        ),
                        pw.Padding(
                          padding: const pw.EdgeInsets.all(6),
                          child: pw.Text('₹${item.lineTotal.toStringAsFixed(2)}', style: const pw.TextStyle(fontSize: 9)),
                        ),
                      ],
                    );
                  }).toList(),
                ],
              ),

              pw.SizedBox(height: 16),

              // Totals Section
              pw.Align(
                alignment: pw.Alignment.centerRight,
                child: pw.SizedBox(
                  width: 280,
                  child: pw.Column(
                    children: [
                      pw.Row(
                        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                        children: [
                          const pw.Text('Subtotal', style: pw.TextStyle(fontSize: 10)),
                          pw.Text('₹${invoice.subtotal.toStringAsFixed(2)}', style: const pw.TextStyle(fontSize: 10)),
                        ],
                      ),
                      pw.SizedBox(height: 4),
                      if (invoice.cgstAmount > 0) ...[
                        pw.Row(
                          mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                          children: [
                            const pw.Text('CGST (5%)', style: pw.TextStyle(fontSize: 10)),
                            pw.Text('₹${invoice.cgstAmount.toStringAsFixed(2)}', style: const pw.TextStyle(fontSize: 10)),
                          ],
                        ),
                        pw.Row(
                          mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                          children: [
                            const pw.Text('SGST (5%)', style: pw.TextStyle(fontSize: 10)),
                            pw.Text('₹${invoice.sgstAmount.toStringAsFixed(2)}', style: const pw.TextStyle(fontSize: 10)),
                          ],
                        ),
                      ]
                      else if (invoice.igstAmount > 0)
                        pw.Row(
                          mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                          children: [
                            const pw.Text('IGST (10%)', style: pw.TextStyle(fontSize: 10)),
                            pw.Text('₹${invoice.igstAmount.toStringAsFixed(2)}', style: const pw.TextStyle(fontSize: 10)),
                          ],
                        ),
                      if (invoice.discountAmount > 0)
                        pw.Row(
                          mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                          children: [
                            const pw.Text('Discount', style: pw.TextStyle(fontSize: 10)),
                            pw.Text('-₹${invoice.discountAmount.toStringAsFixed(2)}', style: const pw.TextStyle(fontSize: 10)),
                          ],
                        ),
                      pw.SizedBox(height: 6),
                      pw.Divider(thickness: 1),
                      pw.Row(
                        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                        children: [
                          pw.Text('TOTAL', style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 12)),
                          pw.Text('₹${invoice.grandTotal.toStringAsFixed(2)}', style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 12)),
                        ],
                      ),
                      pw.SizedBox(height: 8),
                      pw.Text(
                        'In Words: ${invoice.amountInWords}',
                        style: const pw.TextStyle(fontSize: 9, fontStyle: pw.FontStyle.italic),
                      ),
                    ],
                  ),
                ),
              ),

              pw.SizedBox(height: 16),

              // Footer with Terms
              pw.Divider(thickness: 0.5),
              pw.SizedBox(height: 8),
              pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Text('Bank Details:', style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 10)),
                  pw.Text('HDFC Bank | Account: 36893269388 | IFSC: HDFC0000020', style: const pw.TextStyle(fontSize: 9)),
                  pw.SizedBox(height: 6),
                  pw.Text('Payment Terms: ${invoice.paymentTerms}', style: const pw.TextStyle(fontSize: 9)),
                  pw.Text(
                    'Goods sold subject to our terms & conditions. Goods remain company property until payment in full.',
                    style: const pw.TextStyle(fontSize: 8),
                  ),
                ],
              ),
            ],
          );
        },
      ),
    );

    // Generate and display PDF
    await Printing.layoutPdf(
      onLayout: (PdfPageFormat format) async => pdf.save(),
    );
  }
}
