import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:invoice_app/database/database_helper.dart';
import 'package:invoice_app/screens/invoice_preview_screen.dart';

class AllInvoicesScreen extends StatefulWidget {
  const AllInvoicesScreen({super.key});

  @override
  State<AllInvoicesScreen> createState() => _AllInvoicesScreenState();
}

class _AllInvoicesScreenState extends State<AllInvoicesScreen> {
  List<Map<String, dynamic>> invoices = [];
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    loadInvoices();
  }

  Future<void> loadInvoices() async {
    try {
      final data = await DatabaseHelper.instance.getAllInvoices();
      setState(() {
        invoices = data;
        isLoading = false;
      });
    } catch (e) {
      setState(() => isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading invoices: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('All Invoices'),
        backgroundColor: Colors.green[700],
        foregroundColor: Colors.white,
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : invoices.isEmpty
              ? const Center(
                  child: Padding(
                    padding: EdgeInsets.all(32),
                    child: Text('No invoices found'),
                  ),
                )
              : RefreshIndicator(
                  onRefresh: loadInvoices,
                  child: ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: invoices.length,
                    itemBuilder: (context, index) {
                      final invoice = invoices[index];
                      return Card(
                        margin: const EdgeInsets.only(bottom: 8),
                        child: ListTile(
                          leading: CircleAvatar(
                            backgroundColor: Colors.green[100],
                            child: Icon(Icons.receipt, color: Colors.green[700]),
                          ),
                          title: Text(invoice['invoice_number']),
                          subtitle: Text(
                            '${invoice['customer_name']} • ${invoice['invoice_date']}',
                          ),
                          trailing: Text(
                            '₹ ${NumberFormat('#,##,##0.00').format(invoice['grand_total'])}',
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                          ),
                          onTap: () async {
                            await Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => InvoicePreviewScreen(
                                  invoiceData: invoice,
                                ),
                              ),
                            );
                            loadInvoices();
                          },
                        ),
                      );
                    },
                  ),
                ),
    );
  }
}
