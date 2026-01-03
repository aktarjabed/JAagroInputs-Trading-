import 'package:flutter/material.dart';
import 'package:invoice_app/database/database_helper.dart';
import 'package:invoice_app/models/invoice_item.dart';
import 'package:invoice_app/utils/constants.dart'; // Import Constants
import 'package:flutter_typeahead/flutter_typeahead.dart';
import 'package:intl/intl.dart';

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

  // Phase 2 Fields
  final batchController = TextEditingController();
  final categoryController = TextEditingController(); // Using controller for TypeAhead/TextFormField
  DateTime? expiryDate;
  String? qualityGrade; // Dropdown value

  double gstRate = 0.0;

  @override
  void initState() {
    super.initState();
    if (widget.initialItem != null) {
      final item = widget.initialItem!;
      descriptionController.text = item.description;
      hsnController.text = item.hsnCode;
      quantityController.text = item.quantity.toString();
      unitController.text = item.unit;
      rateController.text = item.rate.toString();
      gstRate = item.gstRate;

      // Phase 2
      batchController.text = item.batchNumber ?? '';
      categoryController.text = item.productCategory ?? '';
      expiryDate = item.expiryDate;
      qualityGrade = item.qualityGrade;
      // If quality grade from DB isn't in current list, it might be null or we should handle it.
      if (qualityGrade != null && !Constants.qualityGrades.contains(qualityGrade)) {
        qualityGrade = null; // Reset or handle custom
      }
    }
  }

  @override
  void dispose() {
    descriptionController.dispose();
    hsnController.dispose();
    quantityController.dispose();
    unitController.dispose();
    rateController.dispose();
    batchController.dispose();
    categoryController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      insetPadding: const EdgeInsets.all(16),
      child: Container(
        constraints: const BoxConstraints(maxWidth: 600),
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Form(
              key: _formKey,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    widget.initialItem == null ? 'Add Item' : 'Edit Item',
                    style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 24),

                  // ROW 1: Description (Searchable)
                  TypeAheadField<Map<String, dynamic>>(
                    builder: (context, controller, focusNode) {
                      descriptionController.text = controller.text;
                      return TextFormField(
                        controller: controller,
                        focusNode: focusNode,
                        decoration: const InputDecoration(
                          labelText: 'Product / Description *',
                          border: OutlineInputBorder(),
                        ),
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
                        subtitle: Text('HSN: ${suggestion['code']} | ${suggestion['category'] ?? ''}'),
                      );
                    },
                    onSelected: (suggestion) {
                      descriptionController.text = suggestion['description'];
                      hsnController.text = suggestion['code'];
                      unitController.text = suggestion['unit'];
                      setState(() {
                        gstRate = (suggestion['gst_rate'] as num).toDouble();
                        // Auto-fill Category
                        if (suggestion['category'] != null) {
                          categoryController.text = suggestion['category'];
                        } else {
                           // Try mapping from code if DB column was empty
                           categoryController.text = Constants.hsnCategories[suggestion['code']] ?? '';
                        }
                      });
                    },
                  ),
                  const SizedBox(height: 16),

                  // ROW 2: HSN, Category, Unit
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: TextFormField(
                          controller: hsnController,
                          decoration: const InputDecoration(
                            labelText: 'HSN Code *',
                            border: OutlineInputBorder(),
                          ),
                          validator: (v) => v == null || v.isEmpty ? 'Required' : null,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: TypeAheadField<String>(
                          builder: (context, controller, focusNode) {
                            categoryController.text = controller.text;
                            return TextFormField(
                              controller: controller,
                              focusNode: focusNode,
                              decoration: const InputDecoration(
                                labelText: 'Category',
                                border: OutlineInputBorder(),
                              ),
                            );
                          },
                          suggestionsCallback: (pattern) {
                            return Constants.productCategories.where(
                              (cat) => cat.toLowerCase().contains(pattern.toLowerCase())
                            );
                          },
                          itemBuilder: (context, suggestion) => ListTile(title: Text(suggestion)),
                          onSelected: (suggestion) => categoryController.text = suggestion,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: TypeAheadField<String>(
                          builder: (context, controller, focusNode) {
                            unitController.text = controller.text;
                            return TextFormField(
                              controller: controller,
                              focusNode: focusNode,
                              decoration: const InputDecoration(
                                labelText: 'Unit *',
                                border: OutlineInputBorder(),
                              ),
                              validator: (v) => v == null || v.isEmpty ? 'Required' : null,
                            );
                          },
                          suggestionsCallback: (pattern) {
                            return Constants.units.where(
                              (u) => u.toLowerCase().contains(pattern.toLowerCase())
                            );
                          },
                          itemBuilder: (context, suggestion) => ListTile(title: Text(suggestion)),
                          onSelected: (suggestion) => unitController.text = suggestion,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  // ROW 3: Quantity, Rate, GST
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: TextFormField(
                          controller: quantityController,
                          decoration: const InputDecoration(
                            labelText: 'Quantity *',
                            border: OutlineInputBorder(),
                          ),
                          keyboardType: const TextInputType.numberWithOptions(decimal: true),
                          validator: (v) {
                            if (v == null || v.isEmpty) return 'Required';
                            if (double.tryParse(v) == null || double.parse(v) <= 0) return 'Invalid';
                            return null;
                          },
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: TextFormField(
                          controller: rateController,
                          decoration: const InputDecoration(
                            labelText: 'Rate (₹) *',
                            border: OutlineInputBorder(),
                          ),
                          keyboardType: const TextInputType.numberWithOptions(decimal: true),
                          validator: (v) {
                            if (v == null || v.isEmpty) return 'Required';
                            if (double.tryParse(v) == null || double.parse(v) <= 0) return 'Invalid';
                            return null;
                          },
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: DropdownButtonFormField<double>(
                          value: gstRate,
                          decoration: const InputDecoration(
                            labelText: 'GST Rate',
                            border: OutlineInputBorder(),
                          ),
                          items: [0.0, 5.0, 12.0, 18.0, 28.0].map((rate) {
                            return DropdownMenuItem(
                              value: rate,
                              child: Text('$rate%'),
                            );
                          }).toList(),
                          onChanged: (value) => setState(() => gstRate = value!),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  // ROW 4: Batch, Expiry, Quality (Phase 2)
                  const Text('Agro Details (Phase 2)', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.grey)),
                  const SizedBox(height: 8),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: TextFormField(
                          controller: batchController,
                          decoration: const InputDecoration(
                            labelText: 'Batch / Lot #',
                            border: OutlineInputBorder(),
                            hintText: 'e.g., B-001',
                          ),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: InkWell(
                          onTap: () async {
                            final date = await showDatePicker(
                              context: context,
                              initialDate: expiryDate ?? DateTime.now().add(const Duration(days: 30)),
                              firstDate: DateTime(2020),
                              lastDate: DateTime(2030),
                            );
                            if (date != null) setState(() => expiryDate = date);
                          },
                          child: InputDecorator(
                            decoration: const InputDecoration(
                              labelText: 'Expiry Date',
                              border: OutlineInputBorder(),
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  expiryDate != null
                                    ? DateFormat('dd/MM/yyyy').format(expiryDate!)
                                    : 'Select Date'
                                ),
                                const Icon(Icons.calendar_today, size: 16),
                              ],
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: DropdownButtonFormField<String>(
                          value: qualityGrade,
                          decoration: const InputDecoration(
                            labelText: 'Quality Grade',
                            border: OutlineInputBorder(),
                          ),
                          items: Constants.qualityGrades.map((grade) {
                            return DropdownMenuItem(
                              value: grade,
                              child: Text(grade),
                            );
                          }).toList(),
                          onChanged: (value) => setState(() => qualityGrade = value),
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 32),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      TextButton(
                        onPressed: () => Navigator.pop(context),
                        child: const Text('Cancel', style: TextStyle(fontSize: 16)),
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
                              // Phase 2
                              productCategory: categoryController.text.trim().isEmpty ? null : categoryController.text.trim(),
                              batchNumber: batchController.text.trim().isEmpty ? null : batchController.text.trim(),
                              expiryDate: expiryDate,
                              qualityGrade: qualityGrade,
                            );
                            widget.onAdd(item);
                            Navigator.pop(context);
                          }
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.green,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 12),
                        ),
                        child: const Text('Save Item', style: TextStyle(fontSize: 16)),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
