import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../models/company_settings_model.dart';
import '../services/settings_service.dart';
import '../utils/constants.dart';
import '../utils/validators.dart';

class CompanySettingsTab extends StatefulWidget {
  const CompanySettingsTab({Key? key}) : super(key: key);

  @override
  State<CompanySettingsTab> createState() => _CompanySettingsTabState();
}

class _CompanySettingsTabState extends State<CompanySettingsTab> {
  final _formKey = GlobalKey<FormState>();
  final _settingsService = SettingsService();
  bool _isLoading = true;
  CompanySettingsModel? _currentSettings;

  late TextEditingController _nameController;
  late TextEditingController _gstinController;
  late TextEditingController _panController;
  late TextEditingController _addressController;
  late TextEditingController _cityController;
  late TextEditingController _pincodeController;
  late TextEditingController _phoneController;
  late TextEditingController _emailController;
  late TextEditingController _bankNameController;
  late TextEditingController _accNumController;
  late TextEditingController _ifscController;

  String _selectedState = 'Assam';

  @override
  void initState() {
    super.initState();
    _initializeControllers();
    _loadSettings();
  }

  void _initializeControllers() {
    _nameController = TextEditingController();
    _gstinController = TextEditingController();
    _panController = TextEditingController();
    _addressController = TextEditingController();
    _cityController = TextEditingController();
    _pincodeController = TextEditingController();
    _phoneController = TextEditingController();
    _emailController = TextEditingController();
    _bankNameController = TextEditingController();
    _accNumController = TextEditingController();
    _ifscController = TextEditingController();
  }

  Future<void> _loadSettings() async {
    final settings = await _settingsService.getSettings();
    if (mounted) {
      setState(() {
        _currentSettings = settings;
        _nameController.text = settings.companyName;
        _gstinController.text = settings.gstin;
        _panController.text = settings.pan;
        _addressController.text = settings.address;
        _cityController.text = settings.city;
        _selectedState = settings.state;
        _pincodeController.text = settings.pincode;
        _phoneController.text = settings.phone;
        _emailController.text = settings.email;
        _bankNameController.text = settings.bankName;
        _accNumController.text = settings.bankAccountNumber;
        _ifscController.text = settings.bankIFSC;
        _isLoading = false;
      });
    }
  }

  Future<void> _saveSettings() async {
    if (!_formKey.currentState!.validate()) return;

    final newSettings = CompanySettingsModel(
      id: _currentSettings?.id,
      companyName: _nameController.text.trim(),
      gstin: _gstinController.text.trim().toUpperCase(),
      pan: _panController.text.trim().toUpperCase(),
      address: _addressController.text.trim(),
      city: _cityController.text.trim(),
      state: _selectedState,
      pincode: _pincodeController.text.trim(),
      phone: _phoneController.text.trim(),
      email: _emailController.text.trim(),
      bankName: _bankNameController.text.trim(),
      bankAccountNumber: _accNumController.text.trim(),
      bankIFSC: _ifscController.text.trim().toUpperCase(),
    );

    try {
      await _settingsService.saveSettings(newSettings);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Settings saved successfully'), backgroundColor: Colors.green),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error saving settings: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) return const Center(child: CircularProgressIndicator());

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Company Details', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 16),
            TextFormField(
              controller: _nameController,
              decoration: const InputDecoration(labelText: 'Company Name *', border: OutlineInputBorder()),
              validator: (v) => Validators.validateRequired(v, 'Company Name'),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: TextFormField(
                    controller: _gstinController,
                    decoration: const InputDecoration(labelText: 'GSTIN *', border: OutlineInputBorder()),
                    textCapitalization: TextCapitalization.characters,
                    validator: (v) => Validators.validateRequired(v, 'GSTIN'),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: TextFormField(
                    controller: _panController,
                    decoration: const InputDecoration(labelText: 'PAN', border: OutlineInputBorder()),
                    textCapitalization: TextCapitalization.characters,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _addressController,
              decoration: const InputDecoration(labelText: 'Address *', border: OutlineInputBorder()),
              maxLines: 2,
              validator: (v) => Validators.validateRequired(v, 'Address'),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: TextFormField(
                    controller: _cityController,
                    decoration: const InputDecoration(labelText: 'City *', border: OutlineInputBorder()),
                    validator: (v) => Validators.validateRequired(v, 'City'),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: DropdownButtonFormField<String>(
                    value: _selectedState,
                    decoration: const InputDecoration(labelText: 'State', border: OutlineInputBorder()),
                    items: Constants.indianStates.map((s) => DropdownMenuItem(value: s, child: Text(s))).toList(),
                    onChanged: (v) => setState(() => _selectedState = v!),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: TextFormField(
                    controller: _pincodeController,
                    decoration: const InputDecoration(labelText: 'Pincode *', border: OutlineInputBorder()),
                    keyboardType: TextInputType.number,
                    validator: Validators.validatePincode,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: TextFormField(
                    controller: _phoneController,
                    decoration: const InputDecoration(labelText: 'Phone', border: OutlineInputBorder()),
                    keyboardType: TextInputType.phone,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _emailController,
              decoration: const InputDecoration(labelText: 'Email', border: OutlineInputBorder()),
              keyboardType: TextInputType.emailAddress,
              validator: Validators.validateEmail,
            ),
            const SizedBox(height: 32),
            const Text('Bank Details', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 16),
            TextFormField(
              controller: _bankNameController,
              decoration: const InputDecoration(labelText: 'Bank Name', border: OutlineInputBorder()),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: TextFormField(
                    controller: _accNumController,
                    decoration: const InputDecoration(labelText: 'Account Number', border: OutlineInputBorder()),
                    keyboardType: TextInputType.number,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: TextFormField(
                    controller: _ifscController,
                    decoration: const InputDecoration(labelText: 'IFSC Code', border: OutlineInputBorder()),
                    textCapitalization: TextCapitalization.characters,
                    validator: Validators.validateIFSC,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 32),
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                onPressed: _saveSettings,
                child: const Text('Save Settings', style: TextStyle(fontSize: 16)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    _nameController.dispose();
    _gstinController.dispose();
    _panController.dispose();
    _addressController.dispose();
    _cityController.dispose();
    _pincodeController.dispose();
    _phoneController.dispose();
    _emailController.dispose();
    _bankNameController.dispose();
    _accNumController.dispose();
    _ifscController.dispose();
    super.dispose();
  }
}
