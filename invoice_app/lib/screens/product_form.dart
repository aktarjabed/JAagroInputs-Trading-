import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../models/product_model.dart';
import '../services/product_service.dart';
import '../utils/validators.dart';

class ProductFormScreen extends StatefulWidget {
  final ProductModel? product;

  const ProductFormScreen({Key? key, this.product}) : super(key: key);

  @override
  State<ProductFormScreen> createState() => _ProductFormScreenState();
}

class _ProductFormScreenState extends State<ProductFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _productService = ProductService();

  late TextEditingController _hsnController;
  late TextEditingController _nameController;
  late TextEditingController _categoryController;
  late TextEditingController _rateController;

  final List<String> _categories = [
    'Vegetables',
    'Cereals',
    'Pulses',
    'Oil Seeds',
    'Seeds',
    'Spices',
    'Honey',
    'Organic Fertilizers',
    'Fertilizers',
    'Micronutrients',
    'Pesticides',
    'Animal Feed',
    'Bio Products',
    'Agro Accessories',
    'Others'
  ];

  @override
  void initState() {
    super.initState();
    final p = widget.product;
    _hsnController = TextEditingController(text: p?.hsnCode ?? '');
    _nameController = TextEditingController(text: p?.productName ?? '');
    _categoryController = TextEditingController(text: p?.productCategory ?? 'Vegetables');
    _rateController = TextEditingController(text: p?.gstRate.toString() ?? '0');
  }

  @override
  void dispose() {
    _hsnController.dispose();
    _nameController.dispose();
    _categoryController.dispose();
    _rateController.dispose();
    super.dispose();
  }

  Future<void> _saveProduct() async {
    if (!_formKey.currentState!.validate()) return;

    final product = ProductModel(
      id: widget.product?.id,
      hsnCode: _hsnController.text.trim(),
      productName: _nameController.text.trim(),
      productCategory: _categoryController.text.trim(),
      gstRate: double.tryParse(_rateController.text) ?? 0.0,
    );

    try {
      if (widget.product == null) {
        await _productService.createProduct(product);
      } else {
        await _productService.updateProduct(product);
      }
      if (mounted) Navigator.pop(context, true);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error saving product: $e'), backgroundColor: Colors.red),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.product == null ? 'Add Product' : 'Edit Product'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              TextFormField(
                controller: _hsnController,
                decoration: const InputDecoration(labelText: 'HSN Code *', border: OutlineInputBorder()),
                keyboardType: TextInputType.number,
                validator: (v) => Validators.validateRequired(v, 'HSN Code'),
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _nameController,
                decoration: const InputDecoration(labelText: 'Product Name *', border: OutlineInputBorder()),
                validator: (v) => Validators.validateRequired(v, 'Product Name'),
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<String>(
                value: _categories.contains(_categoryController.text) ? _categoryController.text : 'Others',
                decoration: const InputDecoration(labelText: 'Category', border: OutlineInputBorder()),
                items: _categories.map((c) => DropdownMenuItem(value: c, child: Text(c))).toList(),
                onChanged: (v) => _categoryController.text = v!,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _rateController,
                decoration: const InputDecoration(labelText: 'GST Rate (%)', border: OutlineInputBorder()),
                keyboardType: TextInputType.number,
                inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'[0-9.]'))],
                validator: (v) => Validators.validateAmount(v),
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  onPressed: _saveProduct,
                  child: const Text('Save Product', style: TextStyle(fontSize: 16)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
