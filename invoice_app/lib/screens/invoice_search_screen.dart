import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:invoice_app/database/database_helper.dart';
import 'package:invoice_app/screens/invoice_preview_screen.dart';

class InvoiceSearchScreen extends StatefulWidget {
  const InvoiceSearchScreen({super.key});

  @override
  State<InvoiceSearchScreen> createState() => _InvoiceSearchScreenState();
}

class _InvoiceSearchScreenState extends State<InvoiceSearchScreen> {
  final searchController = TextEditingController();
  Map<String, dynamic>? invoice;
  bool isSearching = false;
  String? errorMessage;

  Future<void> searchInvoice() async {
    if (searchController.text.isEmpty) return;

    setState(() {
      isSearching = true;
      errorMessage = null;
    });

    try {
      final result = await DatabaseHelper.instance.getInvoiceByNumber(
        searchController.text.trim(),
      );

      setState(() {
        invoice = result;
        isSearching = false;
        if (result == null) {
          errorMessage = 'Invoice not found';
        }
      });
    } catch (e) {
      setState(() {
        isSearching = false;
        errorMessage = 'Error: $e';
      });
    }
  }

  @override
  void dispose() {
    searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Search Invoice'),
        backgroundColor: Colors.green[700],
        foregroundColor: Colors.white,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            TextField(
              controller: searchController,
              decoration: InputDecoration(
                labelText: 'Invoice Number',
                border: const OutlineInputBorder(),
                suffixIcon: IconButton(
                  icon: isSearching
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.search),
                  onPressed: isSearching ? null : searchInvoice,
                ),
              ),
              onSubmitted: (_) => searchInvoice(),
            ),
            const SizedBox(height: 16),
            if (errorMessage != null)
              Text(
                errorMessage!,
                style: const TextStyle(color: Colors.red, fontSize: 16),
              ),
            if (invoice != null)
              Expanded(
                child: Card(
                  child: ListTile(
                    leading: CircleAvatar(
                      backgroundColor: Colors.green[100],
                      child: Icon(Icons.receipt, color: Colors.green[700]),
                    ),
                    title: Text(invoice!['invoice_number']),
                    subtitle: Text(
                      '${invoice!['customer_name']} • ${invoice!['invoice_date']}',
                    ),
                    trailing: Text(
                      '₹ ${NumberFormat('#,##,##0.00').format(invoice!['grand_total'])}',
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                    onTap: () {
                      Navigator.pushReplacement(
                        context,
                        MaterialPageRoute(
                          builder: (context) => InvoicePreviewScreen(
                            invoiceData: invoice!,
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
