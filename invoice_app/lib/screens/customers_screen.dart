import 'package:flutter/material.dart';
import '../models/customer_model.dart';
import '../services/customer_service.dart';
import 'customer_form.dart';

class CustomersScreen extends StatefulWidget {
  const CustomersScreen({Key? key}) : super(key: key);

  @override
  State<CustomersScreen> createState() => _CustomersScreenState();
}

class _CustomersScreenState extends State<CustomersScreen> {
  final _customerService = CustomerService();
  final _searchController = TextEditingController();
  List<CustomerModel> _customers = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadCustomers();
  }

  Future<void> _loadCustomers() async {
    setState(() => _isLoading = true);
    final customers = await _customerService.getAllCustomers();
    if (mounted) {
      setState(() {
        _customers = customers;
        _isLoading = false;
      });
    }
  }

  Future<void> _searchCustomers(String query) async {
    if (query.isEmpty) {
      _loadCustomers();
      return;
    }
    setState(() => _isLoading = true);
    final customers = await _customerService.searchCustomers(query);
    if (mounted) {
      setState(() {
        _customers = customers;
        _isLoading = false;
      });
    }
  }

  Future<void> _deleteCustomer(CustomerModel customer) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Customer'),
        content: Text('Are you sure you want to delete ${customer.buyerName}?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      await _customerService.deleteCustomer(customer.id);
      _loadCustomers();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Customer deleted successfully')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Customers'),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Search customers...',
                prefixIcon: const Icon(Icons.search),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                suffixIcon: _searchController.text.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: () {
                          _searchController.clear();
                          _loadCustomers();
                        },
                      )
                    : null,
              ),
              onChanged: _searchCustomers,
            ),
          ),
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _customers.isEmpty
                    ? const Center(child: Text('No customers found'))
                    : ListView.separated(
                        itemCount: _customers.length,
                        separatorBuilder: (context, index) => const Divider(),
                        itemBuilder: (context, index) {
                          final customer = _customers[index];
                          return ListTile(
                            leading: CircleAvatar(
                              child: Text(customer.buyerName[0].toUpperCase()),
                            ),
                            title: Text(customer.buyerName),
                            subtitle: Text(
                              'GSTIN: ${customer.gstin}\nState: ${customer.state}',
                            ),
                            isThreeLine: true,
                            trailing: PopupMenuButton(
                              itemBuilder: (context) => [
                                const PopupMenuItem(value: 'edit', child: Text('Edit')),
                                const PopupMenuItem(value: 'delete', child: Text('Delete')),
                              ],
                              onSelected: (value) {
                                if (value == 'edit') {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (context) => CustomerFormScreen(customer: customer),
                                    ),
                                  ).then((v) => v == true ? _loadCustomers() : null);
                                } else if (value == 'delete') {
                                  _deleteCustomer(customer);
                                }
                              },
                            ),
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => CustomerFormScreen(customer: customer),
                                ),
                              ).then((v) => v == true ? _loadCustomers() : null);
                            },
                          );
                        },
                      ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const CustomerFormScreen()),
          ).then((v) => v == true ? _loadCustomers() : null);
        },
        child: const Icon(Icons.add),
      ),
    );
  }
}
