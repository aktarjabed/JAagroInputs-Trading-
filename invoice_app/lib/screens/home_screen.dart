// lib/screens/home_screen.dart
// COMPLETE - PRODUCTION READY
// Invoice List Dashboard with Search, Statistics & CRUD

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../models/invoice_model.dart';
import '../services/invoice_service.dart';
import '../utils/theme_manager.dart';
import '../utils/constants.dart';
import 'invoice_form.dart';
import 'invoice_detail_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({Key? key}) : super(key: key);

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final _invoiceService = InvoiceService();
  final _searchController = TextEditingController();
  String _filterStatus = 'All';
  List<InvoiceModel> _allInvoices = [];
  List<InvoiceModel> _filteredInvoices = [];

  @override
  void initState() {
    super.initState();
    _loadInvoices();
    _searchController.addListener(_filterInvoices);
  }

  Future<void> _loadInvoices() async {
    try {
      final invoices = await _invoiceService.getAllInvoices();
      setState(() {
        _allInvoices = invoices;
        _filterInvoices();
      });
    } catch (e) {
      _showError('Error loading invoices: $e');
    }
  }

  void _filterInvoices() {
    final query = _searchController.text.toLowerCase();
    setState(() {
      _filteredInvoices = _allInvoices.where((invoice) {
        final matchesSearch = invoice.invoiceNumber.toLowerCase().contains(query) ||
            invoice.buyerName.toLowerCase().contains(query) ||
            invoice.buyerGSTIN.toLowerCase().contains(query);

        final matchesStatus = _filterStatus == 'All' || invoice.status == _filterStatus;

        return matchesSearch && matchesStatus;
      }).toList();
    });
  }

  Future<void> _deleteInvoice(String invoiceId) async {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Invoice'),
        content: const Text('Are you sure you want to delete this invoice?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
            ),
            onPressed: () async {
              try {
                await _invoiceService.deleteInvoice(invoiceId);
                Navigator.pop(context);
                _loadInvoices();
                _showSuccess('Invoice deleted successfully');
              } catch (e) {
                Navigator.pop(context);
                _showError('Error deleting invoice: $e');
              }
            },
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
      ),
    );
  }

  void _showSuccess(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.green,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('JA Agro Invoice'),
        elevation: 0,
        actions: [
          Tooltip(
            message: 'Toggle Theme',
            child: IconButton(
              icon: Icon(
                context.watch<ThemeManager>().isDarkMode
                    ? Icons.light_mode
                    : Icons.dark_mode,
              ),
              onPressed: () {
                context.read<ThemeManager>().toggleTheme();
              },
            ),
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () => Future.delayed(
          const Duration(milliseconds: 500),
          _loadInvoices,
        ),
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(16),
              child: TextField(
                controller: _searchController,
                decoration: InputDecoration(
                  hintText: 'Search invoice #, buyer name, GSTIN...',
                  prefixIcon: const Icon(Icons.search),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  suffixIcon: _searchController.text.isNotEmpty
                      ? IconButton(
                          icon: const Icon(Icons.clear),
                          onPressed: () {
                            _searchController.clear();
                          },
                        )
                      : null,
                ),
              ),
            ),

            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: DropdownButton<String>(
                      isExpanded: true,
                      value: _filterStatus,
                      items: const [
                        DropdownMenuItem(value: 'All', child: Text('All Status')),
                        DropdownMenuItem(value: 'Draft', child: Text('Draft')),
                        DropdownMenuItem(value: 'Sent', child: Text('Sent')),
                        DropdownMenuItem(value: 'Paid', child: Text('Paid')),
                      ],
                      onChanged: (value) {
                        setState(() {
                          _filterStatus = value!;
                          _filterInvoices();
                        });
                      },
                    ),
                  ),
                  const SizedBox(width: 16),
                  FutureBuilder<Map<String, dynamic>>(
                    future: _invoiceService.getInvoiceStatistics(),
                    builder: (context, snapshot) {
                      if (!snapshot.hasData) {
                        return const SizedBox.shrink();
                      }
                      final stats = snapshot.data!;
                      return Tooltip(
                        message: 'Total Amount: ₹${stats['totalAmount']}',
                        child: Chip(
                          label: Text(
                            '${stats['totalInvoices']} invoices',
                            style: const TextStyle(
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          backgroundColor: const Color(0xFF2E7D32),
                          labelStyle: const TextStyle(color: Colors.white),
                        ),
                      );
                    },
                  ),
                ],
              ),
            ),

            const SizedBox(height: 16),

            Expanded(
              child: _filteredInvoices.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.receipt_long,
                            size: 64,
                            color: Colors.grey[400],
                          ),
                          const SizedBox(height: 16),
                          Text(
                            _allInvoices.isEmpty
                                ? 'No invoices yet'
                                : 'No invoices match your search',
                            style: TextStyle(
                              fontSize: 16,
                              color: Colors.grey[600],
                            ),
                          ),
                        ],
                      ),
                    )
                  : ListView.builder(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      itemCount: _filteredInvoices.length,
                      itemBuilder: (context, index) {
                        final invoice = _filteredInvoices[index];
                        return _buildInvoiceCard(invoice);
                      },
                    ),
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          final result = await Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => const InvoiceFormScreen(),
            ),
          );
          if (result != null) {
            _loadInvoices();
            _showSuccess('Invoice created successfully');
          }
        },
        tooltip: 'Create Invoice',
        child: const Icon(Icons.add),
      ),
    );
  }

  Widget _buildInvoiceCard(InvoiceModel invoice) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 2,
      child: InkWell(
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => InvoiceDetailScreen(invoice: invoice),
            ),
          );
        },
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          invoice.invoiceNumber,
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          invoice.buyerName,
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey[700],
                          ),
                        ),
                      ],
                    ),
                  ),
                  Chip(
                    label: Text(invoice.status),
                    backgroundColor: _getStatusColor(invoice.status),
                    labelStyle: const TextStyle(color: Colors.white),
                  ),
                ],
              ),

              const SizedBox(height: 12),
              const Divider(height: 1),
              const SizedBox(height: 12),

              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Date',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey[600],
                        ),
                      ),
                      Text(
                        invoice.getFormattedDate(),
                        style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Amount',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey[600],
                        ),
                      ),
                      Text(
                        '₹${invoice.grandTotal.toStringAsFixed(2)}',
                        style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF2E7D32),
                        ),
                      ),
                    ],
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Items',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey[600],
                        ),
                      ),
                      Text(
                        '${invoice.items.length} items',
                        style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Tax',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey[600],
                        ),
                      ),
                      Text(
                        '₹${invoice.totalTaxAmount.toStringAsFixed(2)}',
                        style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ],
              ),

              const SizedBox(height: 12),

              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                decoration: BoxDecoration(
                  color: Colors.grey[100],
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  invoice.cgstAmount > 0
                      ? 'CGST/SGST (Intrastate)'
                      : 'IGST (Interstate)',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey[700],
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),

              const SizedBox(height: 12),

              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton.icon(
                    onPressed: () async {
                      final updatedInvoice =
                          await Navigator.push<InvoiceModel>(
                        context,
                        MaterialPageRoute(
                          builder: (context) =>
                              InvoiceFormScreen(invoice: invoice),
                        ),
                      );
                      if (updatedInvoice != null) {
                        _loadInvoices();
                        _showSuccess('Invoice updated successfully');
                      }
                    },
                    icon: const Icon(Icons.edit, size: 18),
                    label: const Text('Edit'),
                  ),
                  const SizedBox(width: 8),
                  TextButton.icon(
                    onPressed: () => _deleteInvoice(invoice.id),
                    icon: const Icon(Icons.delete, size: 18, color: Colors.red),
                    label: const Text(
                      'Delete',
                      style: TextStyle(color: Colors.red),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
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

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }
}
