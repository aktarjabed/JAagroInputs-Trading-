import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:share_plus/share_plus.dart';
import 'package:invoice_app/database/database_helper.dart';
import 'package:invoice_app/screens/create_invoice_screen.dart';
import 'package:invoice_app/screens/all_invoices_screen.dart';
import 'package:invoice_app/screens/invoice_preview_screen.dart';
import 'package:invoice_app/screens/invoice_search_screen.dart';
import 'package:invoice_app/widgets/stat_card.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  Map<String, dynamic>? stats;
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    loadStats();
  }

  Future<void> loadStats() async {
    try {
      final data = await DatabaseHelper.instance.getDashboardStats();
      setState(() {
        stats = data;
        isLoading = false;
      });
    } catch (e) {
      setState(() => isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading data: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('JA Agro Inputs & Trading'),
        backgroundColor: Colors.green[700],
        foregroundColor: Colors.white,
        actions: [
          PopupMenuButton<String>(
            onSelected: (value) async {
              if (value == 'export') {
                try {
                  final file = await DatabaseHelper.instance.exportDatabase();
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Backup saved: ${file.path}')),
                    );
                    await Share.shareXFiles([XFile(file.path)], text: 'Invoice Database Backup');
                  }
                } catch (e) {
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Error: $e')),
                    );
                  }
                }
              }
            },
            itemBuilder: (context) => [
              const PopupMenuItem(value: 'export', child: Text('Backup Database')),
            ],
          ),
        ],
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: loadStats,
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: StatCard(
                            title: 'Total Invoices',
                            value: stats!['totalInvoices'].toString(),
                            icon: Icons.receipt_long,
                            color: Colors.blue,
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: StatCard(
                            title: 'Today\'s Invoices',
                            value: stats!['todayInvoices'].toString(),
                            icon: Icons.today,
                            color: Colors.orange,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    StatCard(
                      title: 'Total Revenue',
                      value: '₹ ${NumberFormat('#,##,##0.00').format(stats!['totalRevenue'])}',
                      icon: Icons.currency_rupee,
                      color: Colors.green,
                    ),
                    const SizedBox(height: 24),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'Recent Invoices',
                          style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                        ),
                        TextButton(
                          onPressed: () async {
                            await Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => const AllInvoicesScreen(),
                              ),
                            );
                            loadStats();
                          },
                          child: const Text('View All'),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    if ((stats!['recentInvoices'] as List).isEmpty)
                      const Center(
                        child: Padding(
                          padding: EdgeInsets.all(32),
                          child: Text('No invoices yet. Create your first one!'),
                        ),
                      )
                    else
                      ...((stats!['recentInvoices'] as List).map((invoice) {
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
                              loadStats();
                            },
                          ),
                        );
                      }).toList()),
                  ],
                ),
              ),
            ),
      floatingActionButton: Column(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          FloatingActionButton(
            heroTag: 'search',
            onPressed: () async {
              await Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const InvoiceSearchScreen(),
                ),
              );
              loadStats();
            },
            backgroundColor: Colors.blue,
            child: const Icon(Icons.search),
          ),
          const SizedBox(height: 16),
          FloatingActionButton(
            heroTag: 'create',
            onPressed: () async {
              await Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const CreateInvoiceScreen(),
                ),
              );
              loadStats();
            },
            backgroundColor: Colors.green,
            child: const Icon(Icons.add),
          ),
        ],
      ),
    );
  }
}
