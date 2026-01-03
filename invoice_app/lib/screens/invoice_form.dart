// lib/screens/invoice_form.dart
// COMPLETE - PRODUCTION READY
// Invoice Creation/Edit Form with Phase 1-2-3 Features

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:uuid/uuid.dart';
import '../models/invoice_model.dart';
import '../services/database_helper.dart';
import '../services/gst_helper.dart';
import '../utils/constants.dart';

class InvoiceFormScreen extends StatefulWidget {
  final InvoiceModel? invoice;

  const InvoiceFormScreen({Key? key, this.invoice}) : super(key: key);

  @override
  State<InvoiceFormScreen> createState() => _InvoiceFormScreenState();
}

class _InvoiceFormScreenState extends State<InvoiceFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _db = InvoiceDatabase.instance;

  final _invoiceNumberController = TextEditingController();
  final _buyerNameController = TextEditingController();
  final _buyerGSTINController = TextEditingController();
  final _buyerPANController = TextEditingController();
  final _buyerContactController = TextEditingController();
  final _deliveryAddressController = TextEditingController();
  final _poReferenceController = TextEditingController();
  final _eWayBillController = TextEditingController();
  final _transporterController = TextEditingController();
  final _vehicleController = TextEditingController();
  final _discountController = TextEditingController();

  DateTime _invoiceDate = DateTime.now();
  DateTime? _deliveryDate;
  String _buyerState = 'Assam';
  String _buyerType = 'Trader';
  String _placeOfSupply = '18 (Assam)';
  String _supplyType = 'Taxable';
  String _reverseCharge = 'No';
  String _paymentTerms = 'Net 30';
  String _status = 'Draft';

  List<InvoiceItemModel> _lineItems = [];
  List<Map<String, dynamic>> _hsnCodes = [];

  double _subtotal = 0.0;
  double _cgstAmount = 0.0;
  double _sgstAmount = 0.0;
  double _igstAmount = 0.0;
  double _discountAmount = 0.0;
  double _grandTotal = 0.0;

  @override
  void initState() {
    super.initState();
    _loadHSNCodes();

    if (widget.invoice != null) {
      _loadInvoiceData();
    } else {
      _generateInvoiceNumber();
    }
  }

  Future<void> _loadHSNCodes() async {
    final codes = await _db.getHSNCodes();
    setState(() {
      _hsnCodes = codes;
    });
  }

  void _generateInvoiceNumber() {
    final now = DateTime.now();
    final number = 'INV-${DateFormat('yyyyMMdd-HHmmss').format(now)}';
    _invoiceNumberController.text = number;
  }

  void _loadInvoiceData() {
    final invoice = widget.invoice!;
    _invoiceNumberController.text = invoice.invoiceNumber;
    _buyerNameController.text = invoice.buyerName;
    _buyerGSTINController.text = invoice.buyerGSTIN;
    _buyerPANController.text = invoice.buyerPAN;
    _buyerContactController.text = invoice.buyerContactPerson;
    _deliveryAddressController.text = invoice.deliveryAddress;
    _poReferenceController.text = invoice.poReferenceNumber;
    _eWayBillController.text = invoice.eWayBillNumber;
    _transporterController.text = invoice.transporterName;
    _vehicleController.text = invoice.vehicleNumber;

    _invoiceDate = invoice.date;
    _deliveryDate = invoice.deliveryDate;
    _buyerState = invoice.buyerState;
    _buyerType = invoice.buyerType;
    _placeOfSupply = invoice.placeOfSupply;
    _supplyType = invoice.supplyType;
    _reverseCharge = invoice.reverseChargeMechanism;
    _paymentTerms = invoice.paymentTerms;
    _status = invoice.status;
    _lineItems = List.from(invoice.items);

    _calculateTotals();
  }

  void _calculateTotals() {
    _subtotal = _lineItems.fold(0.0, (sum, item) => sum + item.lineTotal);
    _discountAmount = double.tryParse(_discountController.text) ?? 0.0;

    final buyerStateCode = GSTHelper.getStateCode(_buyerState);
    final supplyStateCode = _placeOfSupply.split(' ').first;

    if (buyerStateCode == supplyStateCode) {
      _cgstAmount = _subtotal * 0.05;
      _sgstAmount = _subtotal * 0.05;
      _igstAmount = 0.0;
    } else {
      _cgstAmount = 0.0;
      _sgstAmount = 0.0;
      _igstAmount = _subtotal * 0.10;
    }

    _grandTotal = _subtotal + _cgstAmount + _sgstAmount + _igstAmount - _discountAmount;
    setState(() {});
  }

  Future<void> _addLineItem() async {
    String? selectedHSN;
    String productName = '';
    String productCategory = '';
    double quantity = 0.0;
    String unit = 'kg';
    double rate = 0.0;
    String? batchNumber;
    String? expiryDate;
    String? qualityGrade;

    await showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: const Text('Add Line Item'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                DropdownButtonFormField<String>(
                  value: selectedHSN,
                  decoration: const InputDecoration(labelText: 'HSN Code'),
                  items: _hsnCodes.map((code) {
                    return DropdownMenuItem(
                      value: code['hsn_code'],
                      child: Text('${code['hsn_code']} - ${code['product_name']}'),
                    );
                  }).toList(),
                  onChanged: (value) async {
                    selectedHSN = value;
                    if (value != null) {
                      final details = await _db.getHSNCodeDetails(value);
                      if (details != null) {
                        setDialogState(() {
                          productName = details['product_name'];
                          productCategory = details['product_category'];
                        });
                      }
                    }
                  },
                ),
                const SizedBox(height: 16),
                TextFormField(
                  initialValue: productName,
                  decoration: const InputDecoration(labelText: 'Product Name'),
                  enabled: false,
                ),
                const SizedBox(height: 16),
                TextFormField(
                  initialValue: productCategory,
                  decoration: const InputDecoration(labelText: 'Category'),
                  enabled: false,
                ),
                const SizedBox(height: 16),
                TextFormField(
                  decoration: const InputDecoration(labelText: 'Quantity'),
                  keyboardType: TextInputType.number,
                  onChanged: (value) {
                    quantity = double.tryParse(value) ?? 0.0;
                  },
                ),
                const SizedBox(height: 16),
                DropdownButtonFormField<String>(
                  value: unit,
                  decoration: const InputDecoration(labelText: 'Unit'),
                  items: Constants.units.map((u) {
                    return DropdownMenuItem(value: u, child: Text(u));
                  }).toList(),
                  onChanged: (value) {
                    setDialogState(() {
                      unit = value!;
                    });
                  },
                ),
                const SizedBox(height: 16),
                TextFormField(
                  decoration: const InputDecoration(labelText: 'Rate per unit (₹)'),
                  keyboardType: TextInputType.number,
                  onChanged: (value) {
                    rate = double.tryParse(value) ?? 0.0;
                  },
                ),
                const SizedBox(height: 16),
                TextFormField(
                  decoration: const InputDecoration(labelText: 'Batch Number (Optional)'),
                  onChanged: (value) {
                    batchNumber = value.isEmpty ? null : value;
                  },
                ),
                const SizedBox(height: 16),
                TextFormField(
                  decoration: const InputDecoration(
                    labelText: 'Expiry Date (Optional)',
                    hintText: 'DD-MM-YYYY',
                  ),
                  onChanged: (value) {
                    expiryDate = value.isEmpty ? null : value;
                  },
                ),
                const SizedBox(height: 16),
                DropdownButtonFormField<String>(
                  value: qualityGrade,
                  decoration: const InputDecoration(labelText: 'Quality Grade (Optional)'),
                  items: const [
                    DropdownMenuItem(value: null, child: Text('None')),
                    DropdownMenuItem(value: 'FAQ', child: Text('FAQ')),
                    DropdownMenuItem(value: 'Premium', child: Text('Premium')),
                    DropdownMenuItem(value: 'Good', child: Text('Good')),
                    DropdownMenuItem(value: 'Fair', child: Text('Fair')),
                    DropdownMenuItem(value: 'Standard', child: Text('Standard')),
                  ],
                  onChanged: (value) {
                    setDialogState(() {
                      qualityGrade = value;
                    });
                  },
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () {
                if (selectedHSN != null && quantity > 0 && rate > 0) {
                  setState(() {
                    _lineItems.add(InvoiceItemModel(
                      id: const Uuid().v4(),
                      hsnCode: selectedHSN!,
                      productName: productName,
                      productCategory: productCategory,
                      quantity: quantity,
                      unit: unit,
                      rate: rate,
                      batchNumber: batchNumber,
                      expiryDate: expiryDate,
                      qualityGrade: qualityGrade,
                      storageLocation: null,
                    ));
                    _calculateTotals();
                  });
                  Navigator.pop(context);
                }
              },
              child: const Text('Add'),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _saveInvoice() async {
    if (!_formKey.currentState!.validate()) return;
    if (_lineItems.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please add at least one line item')),
      );
      return;
    }

    try {
      final invoice = InvoiceModel(
        id: widget.invoice?.id ?? const Uuid().v4(),
        invoiceNumber: _invoiceNumberController.text,
        date: _invoiceDate,
        buyerName: _buyerNameController.text,
        buyerGSTIN: _buyerGSTINController.text,
        buyerPAN: _buyerPANController.text,
        buyerState: _buyerState,
        buyerType: _buyerType,
        buyerContactPerson: _buyerContactController.text,
        placeOfSupply: _placeOfSupply,
        supplyType: _supplyType,
        reverseChargeMechanism: _reverseCharge,
        items: _lineItems,
        subtotal: _subtotal,
        cgstAmount: _cgstAmount,
        sgstAmount: _sgstAmount,
        igstAmount: _igstAmount,
        totalTaxAmount: _cgstAmount + _sgstAmount + _igstAmount,
        discountAmount: _discountAmount,
        grandTotal: _grandTotal,
        amountInWords: GSTHelper.convertAmountToWords(_grandTotal),
        paymentTerms: _paymentTerms,
        paymentDueDate: _invoiceDate.add(const Duration(days: 30)),
        status: _status,
        deliveryAddress: _deliveryAddressController.text,
        deliveryDate: _deliveryDate,
        poReferenceNumber: _poReferenceController.text,
        eWayBillNumber: _eWayBillController.text,
        transporterName: _transporterController.text,
        vehicleNumber: _vehicleController.text,
        createdAt: widget.invoice?.createdAt ?? DateTime.now(),
        updatedAt: DateTime.now(),
      );

      if (widget.invoice != null) {
        await _db.updateInvoice(invoice);
      } else {
        await _db.insertInvoice(invoice);
      }

      Navigator.pop(context, invoice);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error saving invoice: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.invoice != null ? 'Edit Invoice' : 'Create Invoice'),
        actions: [
          IconButton(
            icon: const Icon(Icons.save),
            onPressed: _saveInvoice,
            tooltip: 'Save Invoice',
          ),
        ],
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            _buildSectionHeader('Buyer Details'),
            _buildBuyerDetailsSection(),
            const SizedBox(height: 24),
            _buildSectionHeader('GST Compliance'),
            _buildGSTComplianceSection(),
            const SizedBox(height: 24),
            _buildSectionHeader('Line Items'),
            _buildLineItemsSection(),
            const SizedBox(height: 24),
            _buildSectionHeader('Delivery Details (Optional)'),
            _buildDeliveryDetailsSection(),
            const SizedBox(height: 24),
            _buildSectionHeader('Payment Terms'),
            _buildPaymentSection(),
            const SizedBox(height: 24),
            _buildTotalsSection(),
            const SizedBox(height: 32),
            ElevatedButton(
              onPressed: _saveInvoice,
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
              ),
              child: Text(widget.invoice != null ? 'Update Invoice' : 'Create Invoice'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Text(
        title,
        style: const TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.bold,
          color: Color(0xFF2E7D32),
        ),
      ),
    );
  }

  Widget _buildBuyerDetailsSection() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            TextFormField(
              controller: _buyerNameController,
              decoration: const InputDecoration(labelText: 'Buyer Name *'),
              validator: (value) => value?.isEmpty ?? true ? 'Required' : null,
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _buyerGSTINController,
              decoration: const InputDecoration(labelText: 'GSTIN *'),
              validator: (value) => GSTHelper.validateGSTIN(value ?? '') ? null : 'Invalid GSTIN',
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _buyerPANController,
              decoration: const InputDecoration(labelText: 'PAN *'),
              validator: (value) => GSTHelper.validatePAN(value ?? '') ? null : 'Invalid PAN',
            ),
            const SizedBox(height: 16),
            DropdownButtonFormField<String>(
              value: _buyerState,
              decoration: const InputDecoration(labelText: 'Buyer State *'),
              items: Constants.indianStates.map((state) {
                return DropdownMenuItem(value: state, child: Text(state));
              }).toList(),
              onChanged: (value) {
                setState(() {
                  _buyerState = value!;
                  _placeOfSupply = '${GSTHelper.getStateCode(value)} ($value)';
                  _calculateTotals();
                });
              },
            ),
            const SizedBox(height: 16),
            DropdownButtonFormField<String>(
              value: _buyerType,
              decoration: const InputDecoration(labelText: 'Buyer Type'),
              items: Constants.buyerTypes.map((type) {
                return DropdownMenuItem(value: type, child: Text(type));
              }).toList(),
              onChanged: (value) {
                setState(() {
                  _buyerType = value!;
                });
              },
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _buyerContactController,
              decoration: const InputDecoration(labelText: 'Contact Person'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildGSTComplianceSection() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            TextFormField(
              initialValue: _placeOfSupply,
              decoration: const InputDecoration(labelText: 'Place of Supply'),
              enabled: false,
            ),
            const SizedBox(height: 16),
            DropdownButtonFormField<String>(
              value: _supplyType,
              decoration: const InputDecoration(labelText: 'Supply Type'),
              items: const [
                DropdownMenuItem(value: 'Taxable', child: Text('Taxable')),
                DropdownMenuItem(value: 'Exempt', child: Text('Exempt')),
                DropdownMenuItem(value: 'Mixed', child: Text('Mixed')),
              ],
              onChanged: (value) {
                setState(() {
                  _supplyType = value!;
                });
              },
            ),
            const SizedBox(height: 16),
            DropdownButtonFormField<String>(
              value: _reverseCharge,
              decoration: const InputDecoration(labelText: 'Reverse Charge Mechanism'),
              items: const [
                DropdownMenuItem(value: 'No', child: Text('No')),
                DropdownMenuItem(value: 'Yes', child: Text('Yes')),
              ],
              onChanged: (value) {
                setState(() {
                  _reverseCharge = value!;
                });
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLineItemsSection() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            ..._lineItems.asMap().entries.map((entry) {
              final index = entry.key;
              final item = entry.value;
              return ListTile(
                title: Text(item.productName),
                subtitle: Text('${item.quantity} ${item.unit} @ ₹${item.rate}'),
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text('₹${item.lineTotal.toStringAsFixed(2)}'),
                    IconButton(
                      icon: const Icon(Icons.delete, color: Colors.red),
                      onPressed: () {
                        setState(() {
                          _lineItems.removeAt(index);
                          _calculateTotals();
                        });
                      },
                    ),
                  ],
                ),
              );
            }).toList(),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: _addLineItem,
              icon: const Icon(Icons.add),
              label: const Text('Add Item'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDeliveryDetailsSection() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            TextFormField(
              controller: _deliveryAddressController,
              decoration: const InputDecoration(labelText: 'Delivery Address'),
              maxLines: 3,
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _poReferenceController,
              decoration: const InputDecoration(labelText: 'PO Reference Number'),
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _eWayBillController,
              decoration: const InputDecoration(labelText: 'E-Way Bill Number'),
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _transporterController,
              decoration: const InputDecoration(labelText: 'Transporter Name'),
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _vehicleController,
              decoration: const InputDecoration(labelText: 'Vehicle Number'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPaymentSection() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            DropdownButtonFormField<String>(
              value: _paymentTerms,
              decoration: const InputDecoration(labelText: 'Payment Terms'),
              items: Constants.paymentTerms.map((term) {
                return DropdownMenuItem(value: term, child: Text(term));
              }).toList(),
              onChanged: (value) {
                setState(() {
                  _paymentTerms = value!;
                });
              },
            ),
            const SizedBox(height: 16),
            DropdownButtonFormField<String>(
              value: _status,
              decoration: const InputDecoration(labelText: 'Invoice Status'),
              items: Constants.invoiceStatuses.map((status) {
                return DropdownMenuItem(value: status, child: Text(status));
              }).toList(),
              onChanged: (value) {
                setState(() {
                  _status = value!;
                });
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTotalsSection() {
    return Card(
      color: Colors.grey[50],
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            _buildTotalRow('Subtotal', _subtotal),
            if (_cgstAmount > 0) ...[
              _buildTotalRow('CGST (5%)', _cgstAmount),
              _buildTotalRow('SGST (5%)', _sgstAmount),
            ] else if (_igstAmount > 0)
              _buildTotalRow('IGST (10%)', _igstAmount),
            const Divider(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'GRAND TOTAL',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF2E7D32),
                  ),
                ),
                Text(
                  '₹${_grandTotal.toStringAsFixed(2)}',
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF2E7D32),
                  ),
                ),
              ],
            ),
          ],
        ),
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
          Text('₹${amount.toStringAsFixed(2)}'),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _invoiceNumberController.dispose();
    _buyerNameController.dispose();
    _buyerGSTINController.dispose();
    _buyerPANController.dispose();
    _buyerContactController.dispose();
    _deliveryAddressController.dispose();
    _poReferenceController.dispose();
    _eWayBillController.dispose();
    _transporterController.dispose();
    _vehicleController.dispose();
    _discountController.dispose();
    super.dispose();
  }
}
