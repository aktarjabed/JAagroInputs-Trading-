import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../models/customer_model.dart';
import '../services/customer_service.dart';
import '../utils/constants.dart';
import '../services/gst_helper.dart';
import '../utils/validators.dart';

class CustomerFormScreen extends StatefulWidget {
  final CustomerModel? customer;

  const CustomerFormScreen({Key? key, this.customer}) : super(key: key);

  @override
  State<CustomerFormScreen> createState() => _CustomerFormScreenState();
}

class _CustomerFormScreenState extends State<CustomerFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _customerService = CustomerService();

  late TextEditingController _nameController;
  late TextEditingController _gstinController;
  late TextEditingController _panController;
  late TextEditingController _contactController;
  late TextEditingController _phoneController;
  late TextEditingController _emailController;
  late TextEditingController _addressController;
  late TextEditingController _creditLimitController;

  String _selectedState = 'Assam';
  String _selectedType = 'Trader';

  @override
  void initState() {
    super.initState();
    final c = widget.customer;
    _nameController = TextEditingController(text: c?.buyerName ?? '');
    _gstinController = TextEditingController(text: c?.gstin ?? '');
    _panController = TextEditingController(text: c?.pan ?? '');
    _contactController = TextEditingController(text: c?.contactPerson ?? '');
    _phoneController = TextEditingController(text: c?.phone ?? '');
    _emailController = TextEditingController(text: c?.email ?? '');
    _addressController = TextEditingController(text: c?.address ?? '');
    _creditLimitController = TextEditingController(text: c?.creditLimit.toString() ?? '0');

    if (c != null) {
      _selectedState = c.state;
      _selectedType = c.buyerType;
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _gstinController.dispose();
    _panController.dispose();
    _contactController.dispose();
    _phoneController.dispose();
    _emailController.dispose();
    _addressController.dispose();
    _creditLimitController.dispose();
    super.dispose();
  }

  void _onGSTINChanged(String value) {
    if (value.length >= 2) {
      final stateCode = value.substring(0, 2);
      final stateName = GSTHelper.getStateName(stateCode);
      if (stateName != 'Unknown') {
        setState(() {
          _selectedState = stateName;
        });
      }
    }
    if (value.length >= 12) {
      final pan = value.substring(2, 12);
      _panController.text = pan;
    }
  }

  Future<void> _saveCustomer() async {
    if (!_formKey.currentState!.validate()) return;

    final customer = CustomerModel(
      id: widget.customer?.id ?? '', // ID handled by service for new
      buyerName: _nameController.text.trim(),
      gstin: _gstinController.text.trim().toUpperCase(),
      pan: _panController.text.trim().toUpperCase(),
      state: _selectedState,
      buyerType: _selectedType,
      contactPerson: _contactController.text.trim(),
      phone: _phoneController.text.trim(),
      email: _emailController.text.trim(),
      address: _addressController.text.trim(),
      creditLimit: double.tryParse(_creditLimitController.text) ?? 0.0,
      createdAt: widget.customer?.createdAt ?? DateTime.now(),
      updatedAt: DateTime.now(),
    );

    try {
      if (widget.customer == null) {
        await _customerService.createCustomer(customer);
      } else {
        await _customerService.updateCustomer(customer);
      }
      if (mounted) Navigator.pop(context, true);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error saving customer: $e'), backgroundColor: Colors.red),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.customer == null ? 'Add Customer' : 'Edit Customer'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              TextFormField(
                controller: _nameController,
                decoration: const InputDecoration(labelText: 'Customer Name *', border: OutlineInputBorder()),
                validator: (v) => Validators.validateRequired(v, 'Customer Name'),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: _gstinController,
                      decoration: const InputDecoration(labelText: 'GSTIN *', border: OutlineInputBorder()),
                      textCapitalization: TextCapitalization.characters,
                      onChanged: _onGSTINChanged,
                      validator: (v) {
                        final req = Validators.validateRequired(v, 'GSTIN');
                        if (req != null) return req;
                        return Validators.validateGSTIN(v);
                      },
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: TextFormField(
                      controller: _panController,
                      decoration: const InputDecoration(labelText: 'PAN', border: OutlineInputBorder()),
                      textCapitalization: TextCapitalization.characters,
                      readOnly: true, // Auto-filled from GSTIN
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: DropdownButtonFormField<String>(
                      value: _selectedState,
                      decoration: const InputDecoration(labelText: 'State', border: OutlineInputBorder()),
                      items: Constants.indianStates.map((s) => DropdownMenuItem(value: s, child: Text(s))).toList(),
                      onChanged: (v) => setState(() => _selectedState = v!),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: DropdownButtonFormField<String>(
                      value: _selectedType,
                      decoration: const InputDecoration(labelText: 'Type', border: OutlineInputBorder()),
                      items: Constants.buyerTypes.map((t) => DropdownMenuItem(value: t, child: Text(t))).toList(),
                      onChanged: (v) => setState(() => _selectedType = v!),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _contactController,
                decoration: const InputDecoration(labelText: 'Contact Person *', border: OutlineInputBorder()),
                validator: (v) => Validators.validateRequired(v, 'Contact Person'),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: _phoneController,
                      decoration: const InputDecoration(labelText: 'Phone *', border: OutlineInputBorder()),
                      keyboardType: TextInputType.phone,
                      validator: (v) {
                        final req = Validators.validateRequired(v, 'Phone');
                        if (req != null) return req;
                        return Validators.validatePhone(v);
                      },
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: TextFormField(
                      controller: _emailController,
                      decoration: const InputDecoration(labelText: 'Email', border: OutlineInputBorder()),
                      keyboardType: TextInputType.emailAddress,
                      validator: Validators.validateEmail,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _addressController,
                decoration: const InputDecoration(labelText: 'Address *', border: OutlineInputBorder()),
                maxLines: 3,
                validator: (v) => Validators.validateRequired(v, 'Address'),
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _creditLimitController,
                decoration: const InputDecoration(labelText: 'Credit Limit (₹)', border: OutlineInputBorder()),
                keyboardType: TextInputType.number,
                inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'[0-9.]'))],
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  onPressed: _saveCustomer,
                  child: const Text('Save Customer', style: TextStyle(fontSize: 16)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
