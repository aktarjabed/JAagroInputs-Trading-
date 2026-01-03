// lib/screens/invoice_detail_screen.dart
// COMPLETE - PRODUCTION READY
// Invoice Detail View with PDF Export & Display

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/invoice_model.dart';
import '../services/pdf_helper.dart';

class InvoiceDetailScreen extends StatelessWidget {
  final InvoiceModel invoice;

  const InvoiceDetailScreen({Key? key, required this.invoice}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(invoice.invoiceNumber),
        elevation: 0,
        actions: [
          Tooltip(
            message: 'Generate PDF',
            child: IconButton(
              icon: const Icon(Icons.picture_as_pdf),
              onPressed: () async {
                try {
                  await PDFHelper.generateInvoicePDF(invoice);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('PDF generated successfully')),
                  );
                } catch (e) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Error generating PDF: $e')),
                  );
                }
              },
            ),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildInvoiceHeader(),
            const SizedBox(height: 16),
            _buildBuyerDetails(),
            const SizedBox(height: 16),
            _buildGSTCompliance(),
            const SizedBox(height: 16),
            if (invoice.deliveryAddress.isNotEmpty) ...[
              _buildDeliveryDetails(),
              const SizedBox(height: 16),
            ],
            _buildLineItems(),
            const SizedBox(height: 16),
            _buildTotals(),
          ],
        ),
      ),
    );
  }

  Widget _buildInvoiceHeader() {
    return Card(
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
                      'JA AGRO INPUTS & TRADING',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      'GSTIN: 18CCFPB3144R1Z5',
                      style: TextStyle(color: Colors.grey[700]),
                    ),
                  ],
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    const Text(
                      'INVOICE',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF2E7D32),
                      ),
                    ),
                    Text(
                      invoice.invoiceNumber,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 16),
            const Divider(),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Date', style: TextStyle(fontWeight: FontWeight.w600)),
                    Text(invoice.getFormattedDate()),
                  ],
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Status', style: TextStyle(fontWeight: FontWeight.w600)),
                    Chip(
                      label: Text(invoice.status),
                      backgroundColor: _getStatusColor(invoice.status),
                      labelStyle: const TextStyle(color: Colors.white),
                    ),
                  ],
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBuyerDetails() {
    return _buildSection(
      'Bill To',
      [
        _buildDetailRow('Name', invoice.buyerName),
        _buildDetailRow('GSTIN', invoice.buyerGSTIN),
        _buildDetailRow('PAN', invoice.buyerPAN),
        _buildDetailRow('State', invoice.buyerState),
        _buildDetailRow('Type', invoice.buyerType),
        _buildDetailRow('Contact', invoice.buyerContactPerson),
      ],
    );
  }

  Widget _buildGSTCompliance() {
    return _buildSection(
      'GST Compliance',
      [
        _buildDetailRow('Place of Supply', invoice.placeOfSupply),
        _buildDetailRow('Supply Type', invoice.supplyType),
        _buildDetailRow('Reverse Charge', invoice.reverseChargeMechanism),
      ],
    );
  }

  Widget _buildDeliveryDetails() {
    return _buildSection(
      'Delivery Details',
      [
        _buildDetailRow('Address', invoice.deliveryAddress),
        if (invoice.deliveryDate != null)
          _buildDetailRow(
            'Delivery Date',
            DateFormat('dd-MMM-yyyy').format(invoice.deliveryDate!),
          ),
        if (invoice.poReferenceNumber.isNotEmpty)
          _buildDetailRow('PO Reference', invoice.poReferenceNumber),
        if (invoice.eWayBillNumber.isNotEmpty)
          _buildDetailRow('E-Way Bill', invoice.eWayBillNumber),
        if (invoice.transporterName.isNotEmpty)
          _buildDetailRow('Transporter', invoice.transporterName),
        if (invoice.vehicleNumber.isNotEmpty)
          _buildDetailRow('Vehicle #', invoice.vehicleNumber),
      ],
    );
  }

  Widget _buildLineItems() {
    return _buildSection('Line Items', [
      Card(
        child: SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: DataTable(
            headingRowColor: MaterialStateProperty.all(Colors.grey[100]),
            columns: const [
              DataColumn(label: Text('HSN', style: TextStyle(fontWeight: FontWeight.bold))),
              DataColumn(label: Text('Product', style: TextStyle(fontWeight: FontWeight.bold))),
              DataColumn(label: Text('Category', style: TextStyle(fontWeight: FontWeight.bold))),
              DataColumn(label: Text('Qty', style: TextStyle(fontWeight: FontWeight.bold))),
              DataColumn(label: Text('Unit', style: TextStyle(fontWeight: FontWeight.bold))),
              DataColumn(label: Text('Rate', style: TextStyle(fontWeight: FontWeight.bold))),
              DataColumn(label: Text('Amount', style: TextStyle(fontWeight: FontWeight.bold))),
            ],
            rows: invoice.items.map((item) {
              return DataRow(cells: [
                DataCell(Text(item.hsnCode)),
                DataCell(SizedBox(
                  width: 150,
                  child: Text(item.productName, overflow: TextOverflow.ellipsis),
                )),
                DataCell(Text(item.productCategory ?? '')),
                DataCell(Text(item.quantity.toString())),
                DataCell(Text(item.unit)),
                DataCell(Text('₹${item.rate.toStringAsFixed(2)}')),
                DataCell(Text('₹${item.lineTotal.toStringAsFixed(2)}')),
              ]);
            }).toList(),
          ),
        ),
      ),
    ]);
  }

  Widget _buildTotals() {
    return Card(
      color: Colors.grey[50],
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            _buildTotalRow('Subtotal', invoice.subtotal),
            if (invoice.cgstAmount > 0) ...[
              _buildTotalRow('CGST (5%)', invoice.cgstAmount),
              _buildTotalRow('SGST (5%)', invoice.sgstAmount),
            ] else if (invoice.igstAmount > 0)
              _buildTotalRow('IGST (10%)', invoice.igstAmount),
            if (invoice.discountAmount > 0)
              _buildTotalRow('Discount', invoice.discountAmount),
            const Divider(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'GRAND TOTAL',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF2E7D32),
                  ),
                ),
                Text(
                  '₹${invoice.grandTotal.toStringAsFixed(2)}',
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF2E7D32),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.blue[50],
                borderRadius: BorderRadius.circular(4),
              ),
              child: Text(
                'Amount in Words: ${invoice.amountInWords}',
                style: const TextStyle(
                  fontWeight: FontWeight.w600,
                  fontSize: 12,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSection(String title, List<Widget> children) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Color(0xFF2E7D32),
              ),
            ),
            const SizedBox(height: 12),
            ...children,
          ],
        ),
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(
              label,
              style: TextStyle(
                color: Colors.grey[700],
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTotalRow(String label, double amount) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label),
          Text('₹${amount.toStringAsFixed(2)}'),
        ],
      ),
    );
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'Draft':
        return Colors.orange;
      case 'Sent':
        return Colors.blue;
      case 'Paid':
        return Colors.green;
      case 'Cancelled':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }
}
