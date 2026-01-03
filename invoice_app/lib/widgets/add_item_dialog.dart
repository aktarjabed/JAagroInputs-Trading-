import 'package:flutter/material.dart';
import 'package:invoice_app/database/database_helper.dart';
import 'package:invoice_app/models/invoice_item.dart';
import 'package:flutter_typeahead/flutter_typeahead.dart';

class AddItemDialog extends StatefulWidget {
  final Function(InvoiceItem) onAdd;
  final InvoiceItem? initialItem;

  const AddItemDialog({super.key, required this.onAdd, this.initialItem});

  @override
  State<AddItemDialog> createState() => _AddItemDialogState();
}

class _AddItemDialogState extends State<AddItemDialog> {
  final _formKey = GlobalKey<FormState>();
  final descriptionController = TextEditingController();
  final hsnController = TextEditingController();
  final quantityController = TextEditingController();
  final unitController = TextEditingController();
  final rateController = TextEditingController();
  double gstRate = 0.0;

  @override
  void initState() {
    super.initState();
    if (widget.initialItem != null) {
      descriptionController.text = widget.initialItem!.description;
      hsnController.text = widget.initialItem!.hsnCode;
      quantityController.text = widget.initialItem!.quantity.toString();
      unitController.text = widget.initialItem!.unit;
      rateController.text = widget.initialItem!.rate.toString();
      gstRate = widget.initialItem!.gstRate;
    }
  }

  @override
  void dispose() {
    descriptionController.dispose();
    hsnController.dispose();
    quantityController.dispose();
    unitController.dispose();
    rateController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      child: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  widget.initialItem == null ? 'Add Item' : 'Edit Item',
                  style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 16),
                TypeAheadField<Map<String, dynamic>>(
                  builder: (context, controller, focusNode) {
                    descriptionController.text = controller.text;
                    return TextFormField(
                      controller: controller,
                      focusNode: focusNode,
                      decoration: const InputDecoration(labelText: 'Description *'),
                      validator: (v) => v == null || v.isEmpty ? 'Required' : null,
                    );
                  },
                  suggestionsCallback: (pattern) async {
                    if (pattern.isEmpty) return [];
                    return await DatabaseHelper.instance.searchHSN(pattern);
                  },
                  itemBuilder: (context, suggestion) {
                    return ListTile(
                      title: Text(suggestion['description']),
                      subtitle: Text('HSN: ${suggestion['code']} | GST: ${suggestion['gst_rate']}%'),
                    );
                  },
                  onSelected: (suggestion) {
                    descriptionController.text = suggestion['description'];
                    hsnController.text = suggestion['code'];
                    unitController.text = suggestion['unit'];
                    setState(() {
                      gstRate = (suggestion['gst_rate'] as num).toDouble();
                    });
                  },
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: TextFormField(
                        controller: hsnController,
                        decoration: const InputDecoration(labelText: 'HSN Code *'),
                        validator: (v) => v == null || v.isEmpty ? 'Required' : null,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: TextFormField(
                        controller: unitController,
                        decoration: const InputDecoration(labelText: 'Unit *'),
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
                        controller: quantityController,
                        decoration: const InputDecoration(labelText: 'Quantity *'),
                        keyboardType: const TextInputType.numberWithOptions(decimal: true),
                        validator: (v) {
                          if (v == null || v.isEmpty) return 'Required';
                          if (double.tryParse(v) == null || double.parse(v) <= 0) {
                            return 'Invalid quantity';
                          }
                          return null;
                        },
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: TextFormField(
                        controller: rateController,
                        decoration: const InputDecoration(labelText: 'Rate (₹) *'),
                        keyboardType: const TextInputType.numberWithOptions(decimal: true),
                        validator: (v) {
                          if (v == null || v.isEmpty) return 'Required';
                          if (double.tryParse(v) == null || double.parse(v) <= 0) {
                            return 'Invalid rate';
                          }
                          return null;
                        },
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                DropdownButtonFormField<double>(
                  value: gstRate,
                  decoration: const InputDecoration(labelText: 'GST Rate'),
                  items: [0.0, 5.0, 12.0, 18.0, 28.0].map((rate) {
                    return DropdownMenuItem(
                      value: rate,
                      child: Text('$rate%'),
                    );
                  }).toList(),
                  onChanged: (value) {
                    setState(() => gstRate = value!);
                  },
                ),
                const SizedBox(height: 24),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: const Text('Cancel'),
                    ),
                    const SizedBox(width: 16),
                    ElevatedButton(
                      onPressed: () {
                        if (_formKey.currentState!.validate()) {
                          final item = InvoiceItem(
                            description: descriptionController.text.trim(),
                            hsnCode: hsnController.text.trim(),
                            quantity: double.parse(quantityController.text),
                            unit: unitController.text.trim(),
                            rate: double.parse(rateController.text),
                            gstRate: gstRate,
                          );
                          widget.onAdd(item);
                          Navigator.pop(context);
                        }
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green,
                        foregroundColor: Colors.white,
                      ),
                      child: const Text('Save'),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
