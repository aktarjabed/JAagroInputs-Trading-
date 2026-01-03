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
            // Invoice Header
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
                            Text(
                              'JA AGRO INPUTS & TRADING',
                              style: const TextStyle(
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
                            Text(
                              'INVOICE',
                              style: const TextStyle(
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
            ),

            const SizedBox(height: 16),

            // Buyer Details
            _buildSection(
              'Bill To',
              [
                _buildDetailRow('Name', invoice.buyerName),
                _buildDetailRow('GSTIN', invoice.buyerGSTIN),
                _buildDetailRow('PAN', invoice.buyerPAN),
                _buildDetailRow('State', invoice.buyerState),
                _buildDetailRow('Type', invoice.buyerType),
                _buildDetailRow('Contact', invoice.buyerContactPerson),
              ],
            ),

            const SizedBox(height: 16),

            // GST Compliance Info (Phase 1)
            _buildSection(
              'GST Compliance (Phase 1)',
              [
                _buildDetailRow('Place of Supply', invoice.placeOfSupply),
                _buildDetailRow('Supply Type', invoice.supplyType),
                _buildDetailRow('Reverse Charge', invoice.reverseChargeMechanism),
              ],
            ),

            const SizedBox(height: 16),

            // Delivery Details (Phase 3)
            if (invoice.deliveryAddress.isNotEmpty)
              _buildSection(
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
              ),

            const SizedBox(height: 16),

            // Line Items
            _buildSection('Line Items', [
              Card(
                child: Column(
                  children: [
                    Table(
                      border: TableBorder.symmetric(
                        inside: BorderSide(color: Colors.grey[300]!),
                      ),
                      columnWidths: const {
                        0: FlexColumnWidth(1),
                        1: FlexColumnWidth(2),
                        2: FlexColumnWidth(1),
                        3: FlexColumnWidth(1),
                        4: FlexColumnWidth(1),
                      },
                      children: [
                        TableRow(
                          decoration: BoxDecoration(
                            color: Colors.grey[100],
                          ),
                          children: const [
                            Padding(
                              padding: EdgeInsets.all(8),
                              child: Text(
                                'HSN',
                                style: TextStyle(fontWeight: FontWeight.bold),
                              ),
                            ),
                            Padding(
                              padding: EdgeInsets.all(8),
                              child: Text(
                                'Product',
                                style: TextStyle(fontWeight: FontWeight.bold),
                              ),
                            ),
                            Padding(
                              padding: EdgeInsets.all(8),
                              child: Text(
                                'Qty',
                                style: TextStyle(fontWeight: FontWeight.bold),
                              ),
                            ),
                            Padding(
                              padding: EdgeInsets.all(8),
                              child: Text(
                                'Rate',
                                style: TextStyle(fontWeight: FontWeight.bold),
                              ),
                            ),
                            Padding(
                              padding: EdgeInsets.all(8),
                              child: Text(
                                'Amount',
                                style: TextStyle(fontWeight: FontWeight.bold),
                              ),
                            ),
                          ],
                        ),
                        ...invoice.items.map((item) {
                          return TableRow(
                            children: [
                              Padding(
                                padding: const EdgeInsets.all(8),
                                child: Text(item.hsnCode),
                              ),
                              Padding(
                                padding: const EdgeInsets.all(8),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      item.productName,
                                      style: const TextStyle(fontWeight: FontWeight.w500),
                                    ),
                                    if (item.batchNumber != null)
                                      Text(
                                        'Batch: ${item.batchNumber}',
                                        style: TextStyle(
                                          fontSize: 12,
                                          color: Colors.grey[600],
                                        ),
                                      ),
                                    if (item.expiryDate != null)
                                      Text(
                                        'Expiry: ${item.expiryDate}',
                                        style: TextStyle(
                                          fontSize: 12,
                                          color: Colors.grey[600],
                                        ),
                                      ),
                                  ],
                                ),
                              ),
                              Padding(
                                padding: const EdgeInsets.all(8),
                                child: Text('${item.quantity} ${item.unit}'),
                              ),
                              Padding(
                                padding: const EdgeInsets.all(8),
                                child: Text('₹${item.rate}'),
                              ),
                              Padding(
                                padding: const EdgeInsets.all(8),
                                child: Text('₹${item.lineTotal.toStringAsFixed(2)}'),
                              ),
                            ],
                          );
                        }).toList(),
                      ],
                    ),
                  ],
                ),
              ),
            ]),

            const SizedBox(height: 16),

            // Totals
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    _buildTotalRow('Subtotal', invoice.subtotal),
                    if (invoice.cgstAmount > 0) ...[
                      _buildTotalRow('CGST (5%)', invoice.cgstAmount),
                      _buildTotalRow('SGST (5%)', invoice.sgstAmount),
                    ]
                    else if (invoice.igstAmount > 0)
                      _buildTotalRow('IGST (10%)', invoice.igstAmount),
                    if (invoice.discountAmount > 0)
                      _buildTotalRow('Discount', -invoice.discountAmount),
                    const Divider(height: 16),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'GRAND TOTAL',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF2E7D32),
                          ),
                        ),
                        Text(
                          '₹${invoice.grandTotal.toStringAsFixed(2)}',
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF2E7D32),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'In Words: ${invoice.amountInWords}',
                      style: const TextStyle(
                        fontSize: 13,
                        fontStyle: FontStyle.italic,
                      ),
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 16),

            // Payment Terms
            if (invoice.paymentTerms.isNotEmpty)
              _buildSection('Payment Details', [
                _buildDetailRow('Payment Terms', invoice.paymentTerms),
                _buildDetailRow(
                  'Due Date',
                  DateFormat('dd-MMM-yyyy').format(invoice.paymentDueDate),
                ),
              ]),

            const SizedBox(height: 16),

            // Footer
            Card(
              color: Colors.grey[50],
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: const [
                    Text(
                      'Bank Details',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                      ),
                    ),
                    SizedBox(height: 8),
                    Text('HDFC Bank'),
                    Text('Account: 36893269388'),
                    Text('IFSC: HDFC0000020'),
                    SizedBox(height: 16),
                    Text(
                      'Terms & Conditions: Payment on due date. Goods remain company property until paid in full.',
                      style: TextStyle(fontSize: 12),
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 24),
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
                fontSize: 14,
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
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              fontWeight: FontWeight.w500,
              color: Colors.grey[700],
            ),
          ),
          Expanded(
            child: Text(
              value,
              textAlign: TextAlign.right,
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
          Text(
            '₹${amount.toStringAsFixed(2)}',
            style: const TextStyle(fontWeight: FontWeight.w600),
          ),
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
