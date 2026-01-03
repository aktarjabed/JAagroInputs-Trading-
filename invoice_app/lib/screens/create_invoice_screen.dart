import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'dart:convert';
import 'package:invoice_app/database/database_helper.dart';
import 'package:invoice_app/models/invoice_item.dart';
import 'package:invoice_app/widgets/add_item_dialog.dart';
import 'package:flutter_typeahead/flutter_typeahead.dart';

class CreateInvoiceScreen extends StatefulWidget {
  const CreateInvoiceScreen({super.key});

  @override
  State<CreateInvoiceScreen> createState() => _CreateInvoiceScreenState();
}

class _CreateInvoiceScreenState extends State<CreateInvoiceScreen> {
  final _formKey = GlobalKey<FormState>();
  final invoiceNumberController = TextEditingController();
  final customerNameController = TextEditingController();
  final customerAddressController = TextEditingController();
  final customerCityController = TextEditingController();
  final customerStateController = TextEditingController(text: 'Assam');
  final customerPincodeController = TextEditingController();
  final customerGstinController = TextEditingController();

  DateTime selectedDate = DateTime.now();
  List<InvoiceItem> items = [];
  bool isCheckingInvoice = false;
  bool isSaving = false;

  @override
  void initState() {
    super.initState();
    _generateInvoiceNumber();
  }

  void _generateInvoiceNumber() {
    final now = DateTime.now();
    final format = DateFormat('yyyyMMdd-HHmmss');
    invoiceNumberController.text = 'INV-${format.format(now)}';
  }

  @override
  void dispose() {
    invoiceNumberController.dispose();
    customerNameController.dispose();
    customerAddressController.dispose();
    customerCityController.dispose();
    customerStateController.dispose();
    customerPincodeController.dispose();
    customerGstinController.dispose();
    super.dispose();
  }

  Future<void> checkInvoiceNumber() async {
    if (invoiceNumberController.text.isEmpty) return;

    setState(() => isCheckingInvoice = true);

    try {
      final exists = await DatabaseHelper.instance.checkInvoiceExists(
        invoiceNumberController.text,
      );

      setState(() => isCheckingInvoice = false);

      if (exists && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Invoice number already exists!'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      setState(() => isCheckingInvoice = false);
    }
  }

  void addItem() {
    showDialog(
      context: context,
      builder: (context) => AddItemDialog(
        onAdd: (item) {
          setState(() => items.add(item));
        },
      ),
    );
  }

  void editItem(int index) {
    showDialog(
      context: context,
      builder: (context) => AddItemDialog(
        initialItem: items[index],
        onAdd: (item) {
          setState(() => items[index] = item);
        },
      ),
    );
  }

  double calculateSubtotal(double gstRate) {
    return items
        .where((item) => item.gstRate == gstRate)
        .fold(0.0, (sum, item) => sum + item.amount);
  }

  Map<String, double> calculateTotals() {
    final subtotalVeg = calculateSubtotal(0.0);
    final subtotalFert = items
        .where((item) => item.gstRate > 0)
        .fold(0.0, (sum, item) => sum + item.amount);

    final isInterstate = customerStateController.text.trim().toLowerCase() != 'assam';

    double cgst = 0, sgst = 0, igst = 0;

    if (isInterstate) {
      igst = items
          .where((item) => item.gstRate > 0)
          .fold(0.0, (sum, item) => sum + item.gstAmount);
    } else {
      final totalGst = items
          .where((item) => item.gstRate > 0)
          .fold(0.0, (sum, item) => sum + item.gstAmount);
      cgst = totalGst / 2;
      sgst = totalGst / 2;
    }

    final grandTotal = subtotalVeg + subtotalFert + cgst + sgst + igst;

    return {
      'subtotalVeg': subtotalVeg,
      'subtotalFert': subtotalFert,
      'cgst': cgst,
      'sgst': sgst,
      'igst': igst,
      'grandTotal': grandTotal,
    };
  }

  Future<void> saveInvoice() async {
    if (!_formKey.currentState!.validate()) return;
    if (items.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please add at least one item')),
      );
      return;
    }

    setState(() => isSaving = true);

    try {
      final exists = await DatabaseHelper.instance.checkInvoiceExists(
        invoiceNumberController.text,
      );

      if (exists) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Invoice number already exists!'),
              backgroundColor: Colors.red,
            ),
          );
        }
        setState(() => isSaving = false);
        return;
      }

      final totals = calculateTotals();

      final invoice = {
        'invoice_number': invoiceNumberController.text,
        'invoice_date': DateFormat('dd/MM/yyyy').format(selectedDate),
        'customer_name': customerNameController.text.trim(),
        'customer_address': customerAddressController.text.trim(),
        'customer_city': customerCityController.text.trim(),
        'customer_state': customerStateController.text.trim(),
        'customer_pincode': customerPincodeController.text.trim(),
        'customer_gstin': customerGstinController.text.trim(),
        'items': jsonEncode(items.map((e) => e.toJson()).toList()),
        'subtotal_vegetables': totals['subtotalVeg'],
        'subtotal_fertilizers': totals['subtotalFert'],
        'cgst': totals['cgst'],
        'sgst': totals['sgst'],
        'igst': totals['igst'],
        'grand_total': totals['grandTotal'],
        'created_at': DateTime.now().toIso8601String(),
      };

      final customer = {
        'name': customerNameController.text.trim(),
        'address': customerAddressController.text.trim(),
        'city': customerCityController.text.trim(),
        'state': customerStateController.text.trim(),
        'pincode': customerPincodeController.text.trim(),
        'gstin': customerGstinController.text.trim(),
      };

      await DatabaseHelper.instance.insertInvoice(invoice, customer);

      setState(() => isSaving = false);

      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Invoice saved successfully!')),
        );
      }
    } catch (e) {
      setState(() => isSaving = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error saving invoice: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final totals = calculateTotals();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Create Invoice'),
        backgroundColor: Colors.green[700],
        foregroundColor: Colors.white,
        actions: [
          if (isSaving)
            const Center(
              child: Padding(
                padding: EdgeInsets.all(16),
                child: SizedBox(
                  width: 24,
                  height: 24,
                  child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                ),
              ),
            )
          else
            IconButton(
              icon: const Icon(Icons.save),
              onPressed: saveInvoice,
            ),
        ],
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            const Text(
              'Invoice Details',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: invoiceNumberController,
              decoration: InputDecoration(
                labelText: 'Invoice Number *',
                suffixIcon: isCheckingInvoice
                    ? const Padding(
                        padding: EdgeInsets.all(12),
                        child: SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        ),
                      )
                    : IconButton(
                        icon: const Icon(Icons.refresh),
                        onPressed: _generateInvoiceNumber,
                        tooltip: 'Generate New Number',
                      ),
              ),
              validator: (v) {
                if (v == null || v.isEmpty) return 'Required';
                if (!RegExp(r'^INV-\d{8}-\d{6}$').hasMatch(v)) {
                  return 'Invalid format (INV-YYYYMMDD-HHMMSS)';
                }
                return null;
              },
              onChanged: (v) {
                if (v.isNotEmpty) checkInvoiceNumber();
              },
            ),
            const SizedBox(height: 16),
            InkWell(
              onTap: () async {
                final date = await showDatePicker(
                  context: context,
                  initialDate: selectedDate,
                  firstDate: DateTime(2020),
                  lastDate: DateTime(2030),
                );
                if (date != null) {
                  setState(() => selectedDate = date);
                }
              },
              child: InputDecorator(
                decoration: const InputDecoration(labelText: 'Invoice Date'),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(DateFormat('dd/MM/yyyy').format(selectedDate)),
                    const Icon(Icons.calendar_today, size: 20),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),

            const Text(
              'Customer Details',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            TypeAheadField<Map<String, dynamic>>(
              builder: (context, controller, focusNode) {
                customerNameController.text = controller.text;
                return TextFormField(
                  controller: controller,
                  focusNode: focusNode,
                  decoration: const InputDecoration(labelText: 'Customer Name *'),
                  validator: (v) => v == null || v.isEmpty ? 'Required' : null,
                );
              },
              suggestionsCallback: (pattern) async {
                if (pattern.isEmpty) return [];
                return await DatabaseHelper.instance.searchCustomers(pattern);
              },
              itemBuilder: (context, suggestion) {
                return ListTile(
                  title: Text(suggestion['name']),
                  subtitle: Text('${suggestion['city']}, ${suggestion['state']}'),
                );
              },
              onSelected: (suggestion) {
                customerNameController.text = suggestion['name'];
                customerAddressController.text = suggestion['address'];
                customerCityController.text = suggestion['city'];
                customerStateController.text = suggestion['state'];
                customerPincodeController.text = suggestion['pincode'];
                if (suggestion['gstin'] != null) {
                  customerGstinController.text = suggestion['gstin'];
                }
              },
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: customerAddressController,
              decoration: const InputDecoration(labelText: 'Address *'),
              maxLines: 2,
              validator: (v) => v == null || v.isEmpty ? 'Required' : null,
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: TextFormField(
                    controller: customerCityController,
                    decoration: const InputDecoration(labelText: 'City *'),
                    validator: (v) => v == null || v.isEmpty ? 'Required' : null,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: TextFormField(
                    controller: customerStateController,
                    decoration: const InputDecoration(labelText: 'State *'),
                    validator: (v) => v == null || v.isEmpty ? 'Required' : null,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: TextFormField(
                    controller: customerPincodeController,
                    decoration: const InputDecoration(labelText: 'Pincode *'),
                    keyboardType: TextInputType.number,
                    validator: (v) {
                      if (v == null || v.isEmpty) return 'Required';
                      if (v.length != 6) return 'Invalid pincode';
                      return null;
                    },
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: TextFormField(
                    controller: customerGstinController,
                    decoration: const InputDecoration(labelText: 'GSTIN (Optional)'),
                    textCapitalization: TextCapitalization.characters,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),

            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Items',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                ElevatedButton.icon(
                  onPressed: addItem,
                  icon: const Icon(Icons.add),
                  label: const Text('Add Item'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green,
                    foregroundColor: Colors.white,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            if (items.isEmpty)
              const Center(
                child: Padding(
                  padding: EdgeInsets.all(32),
                  child: Text('No items added yet'),
                ),
              )
            else
              ...items.asMap().entries.map((entry) {
                final index = entry.key;
                final item = entry.value;
                return Card(
                  margin: const EdgeInsets.only(bottom: 8),
                  child: ListTile(
                    title: Text(item.description),
                    subtitle: Text(
                      'HSN: ${item.hsnCode} | ${item.quantity} ${item.unit} @ ₹${item.rate.toStringAsFixed(2)} | GST: ${item.gstRate}%',
                    ),
                    trailing: SizedBox(
                      width: 120,
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            '₹${item.total.toStringAsFixed(2)}',
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                          ),
                          IconButton(
                            icon: const Icon(Icons.edit, size: 20),
                            onPressed: () => editItem(index),
                          ),
                          IconButton(
                            icon: const Icon(Icons.delete, color: Colors.red, size: 20),
                            onPressed: () {
                              setState(() => items.removeAt(index));
                            },
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              }),

            if (items.isNotEmpty) ...[
              const SizedBox(height: 24),
              const Divider(thickness: 2),
              const SizedBox(height: 16),

              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.grey[100],
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Column(
                  children: [
                    _buildTotalRow('Vegetables (0% GST)', totals['subtotalVeg']!),
                    _buildTotalRow('Other Items', totals['subtotalFert']!),
                    if (totals['cgst']! > 0) ...[
                      const Divider(),
                      _buildTotalRow('CGST', totals['cgst']!),
                      _buildTotalRow('SGST', totals['sgst']!),
                    ],
                    if (totals['igst']! > 0) ...[
                      const Divider(),
                      _buildTotalRow('IGST (Interstate)', totals['igst']!),
                    ],
                    const Divider(thickness: 2),
                    _buildTotalRow(
                      'Grand Total',
                      totals['grandTotal']!,
                      isBold: true,
                      fontSize: 20,
                    ),
                  ],
                ),
              ),
            ],
            const SizedBox(height: 80),
          ],
        ),
      ),
    );
  }

  Widget _buildTotalRow(String label, double amount, {bool isBold = false, double fontSize = 16}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: fontSize,
              fontWeight: isBold ? FontWeight.bold : FontWeight.normal,
            ),
          ),
          Text(
            '₹ ${NumberFormat('#,##,##0.00').format(amount)}',
            style: TextStyle(
              fontSize: fontSize,
              fontWeight: isBold ? FontWeight.bold : FontWeight.normal,
            ),
          ),
        ],
      );
    );
  }
}
