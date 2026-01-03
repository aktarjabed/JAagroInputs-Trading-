import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:invoice_app/database/database_helper.dart';
import 'package:invoice_app/models/invoice_item.dart';
import 'package:invoice_app/utils/pdf_generator.dart';
import 'package:invoice_app/utils/gst_helper.dart'; // Add GST Helper

class InvoicePreviewScreen extends StatefulWidget {
  final Map<String, dynamic> invoiceData;

  const InvoicePreviewScreen({super.key, required this.invoiceData});

  @override
  State<InvoicePreviewScreen> createState() => _InvoicePreviewScreenState();
}

class _InvoicePreviewScreenState extends State<InvoicePreviewScreen> {
  late Map<String, dynamic> invoice;
  bool isLoading = true;
  List<InvoiceItem> items = [];

  @override
  void initState() {
    super.initState();
    _loadFullInvoice();
  }

  Future<void> _loadFullInvoice() async {
    try {
      final fullInvoice = await DatabaseHelper.instance.getInvoiceByNumber(
        widget.invoiceData['invoice_number'],
      );

      if (fullInvoice != null) {
        setState(() {
          invoice = fullInvoice;
          // Use the robust parsing from InvoiceItem
          items = InvoiceItem.parseItems(invoice['items']);
          isLoading = false;
        });
      } else {
        // Fallback if load fails (shouldn't happen)
        setState(() {
          invoice = widget.invoiceData;
          items = InvoiceItem.parseItems(invoice['items']);
          isLoading = false;
        });
      }
    } catch (e) {
      setState(() => isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error loading details: $e')));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return Scaffold(
        appBar: AppBar(title: const Text('Loading...'), backgroundColor: Colors.green[700]),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    final isInterstate = GSTHelper.isInterState(invoice['place_of_supply'] ?? '18');
    final placeOfSupply = invoice['place_of_supply'] ?? '18'; // Display Code or Name?

    // We need company settings for PDF generation
    // We can fetch them on demand when clicking buttons

    return Scaffold(
      appBar: AppBar(
        title: Text(invoice['invoice_number']),
        backgroundColor: Colors.green[700],
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.picture_as_pdf),
            onPressed: () async {
               // Fetch company settings first
               final settings = await DatabaseHelper.instance.getCompanySettings();
               // Prepare items list for PDF (List<Map>)
               final itemsMap = items.map((e) => e.toJson()).toList();

               if (context.mounted) {
                   await PdfGenerator.generateInvoice(invoice, settings, itemsMap);
                   ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Invoice generated! Check Documents folder.')));
               }
            },
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
                      TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
                      TextButton(onPressed: () => Navigator.pop(context, true), style: TextButton.styleFrom(foregroundColor: Colors.red), child: const Text('Delete')),
                    ],
                  ),
                );

                if (confirm == true && context.mounted) {
                  await DatabaseHelper.instance.deleteInvoice(invoice['invoice_number']);
                  if (context.mounted) {
                    Navigator.pop(context);
                    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Invoice deleted')));
                  }
                }
              }
            },
            itemBuilder: (context) => [
              const PopupMenuItem(value: 'delete', child: Row(children: [Icon(Icons.delete, color: Colors.red), SizedBox(width: 8), Text('Delete Invoice')])),
            ],
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header Card
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('JA Agro Inputs & Trading', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                        Text(invoice['invoice_date'], style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text('Invoice: ${invoice['invoice_number']}', style: TextStyle(color: Colors.grey[800])),
                    Text('Place of Supply: $placeOfSupply', style: TextStyle(color: Colors.grey[800])),
                    if (invoice['reverse_charge'] == 'Yes')
                      const Text('Reverse Charge: Yes', style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold)),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Customer Card
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Bill To:', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.grey)),
                    const SizedBox(height: 8),
                    Text(invoice['customer_name'], style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                    Text(invoice['customer_address']),
                    Text('${invoice['customer_city']}, ${invoice['customer_state']} - ${invoice['customer_pincode']}'),
                    if (invoice['customer_gstin'] != null && invoice['customer_gstin'].toString().isNotEmpty)
                      Text('GSTIN: ${invoice['customer_gstin']}', style: const TextStyle(fontWeight: FontWeight.bold)),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),

            const Text('Items', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: DataTable(
                columnSpacing: 20,
                headingRowColor: MaterialStateProperty.all(Colors.green[50]),
                columns: const [
                  DataColumn(label: Text('#', style: TextStyle(fontWeight: FontWeight.bold))),
                  DataColumn(label: Text('Description', style: TextStyle(fontWeight: FontWeight.bold))),
                  DataColumn(label: Text('HSN', style: TextStyle(fontWeight: FontWeight.bold))),
                  DataColumn(label: Text('Batch', style: TextStyle(fontWeight: FontWeight.bold))), // New
                  DataColumn(label: Text('Qty', style: TextStyle(fontWeight: FontWeight.bold))),
                  DataColumn(label: Text('Rate', style: TextStyle(fontWeight: FontWeight.bold))),
                  DataColumn(label: Text('Tax', style: TextStyle(fontWeight: FontWeight.bold))),
                  DataColumn(label: Text('Amount', style: TextStyle(fontWeight: FontWeight.bold))),
                ],
                rows: items.asMap().entries.map((entry) {
                  final index = entry.key + 1;
                  final item = entry.value;
                  return DataRow(cells: [
                    DataCell(Text(index.toString())),
                    DataCell(Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(item.description),
                        if (item.productCategory != null) Text('(${item.productCategory})', style: const TextStyle(fontSize: 10, color: Colors.grey)),
                      ],
                    )),
                    DataCell(Text(item.hsnCode)),
                    DataCell(Text(item.batchNumber ?? '-')),
                    DataCell(Text('${item.quantity} ${item.unit}')),
                    DataCell(Text('₹${item.rate}')), // Format?
                    DataCell(Text('${item.gstRate}%')),
                    DataCell(Text('₹${item.total.toStringAsFixed(2)}')),
                  ]);
                }).toList(),
              ),
            ),
            const SizedBox(height: 24),

            // Totals
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(color: Colors.green[50], borderRadius: BorderRadius.circular(8), border: Border.all(color: Colors.green.shade200)),
              child: Column(
                children: [
                  _buildTotalRow('Vegetables (0% GST)', invoice['subtotal_vegetables']),
                  _buildTotalRow('Other Items', invoice['subtotal_fertilizers']),
                  const Divider(),
                  if (!isInterstate) ...[
                    _buildTotalRow('CGST', invoice['cgst']),
                    _buildTotalRow('SGST', invoice['sgst']),
                  ] else
                    _buildTotalRow('IGST', invoice['igst']),
                  const Divider(thickness: 2),
                  _buildTotalRow('Grand Total', invoice['grand_total'], isBold: true, fontSize: 20),
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
                    Text('Terms & Conditions:', style: TextStyle(fontWeight: FontWeight.bold)),
                    SizedBox(height: 8),
                    Text('1. Payment due within 30 days', style: TextStyle(fontSize: 12)),
                    Text('2. Goods once sold will not be taken back', style: TextStyle(fontSize: 12)),
                    Text('3. Interest @ 18% p.a. will be charged if payment is delayed', style: TextStyle(fontSize: 12)),
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
          Text(label, style: TextStyle(fontSize: fontSize, fontWeight: isBold ? FontWeight.bold : FontWeight.normal)),
          Text(GSTHelper.formatCurrency(value), style: TextStyle(fontSize: fontSize, fontWeight: isBold ? FontWeight.bold : FontWeight.normal)),
        ],
      ),
    );
  }
}
