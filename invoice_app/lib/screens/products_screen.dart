import 'package:flutter/material.dart';
import '../models/product_model.dart';
import '../services/product_service.dart';
import 'product_form.dart';

class ProductsScreen extends StatefulWidget {
  const ProductsScreen({Key? key}) : super(key: key);

  @override
  State<ProductsScreen> createState() => _ProductsScreenState();
}

class _ProductsScreenState extends State<ProductsScreen> {
  final _productService = ProductService();
  final _searchController = TextEditingController();
  List<ProductModel> _products = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadProducts();
  }

  Future<void> _loadProducts() async {
    setState(() => _isLoading = true);
    final products = await _productService.getAllProducts();
    if (mounted) {
      setState(() {
        _products = products;
        _isLoading = false;
      });
    }
  }

  Future<void> _searchProducts(String query) async {
    if (query.isEmpty) {
      _loadProducts();
      return;
    }
    setState(() => _isLoading = true);
    final products = await _productService.searchProducts(query);
    if (mounted) {
      setState(() {
        _products = products;
        _isLoading = false;
      });
    }
  }

  Future<void> _deleteProduct(ProductModel product) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Product'),
        content: Text('Are you sure you want to delete ${product.productName}?'),
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
      if (product.id != null) {
        await _productService.deleteProduct(product.id!);
        _loadProducts();
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Product deleted successfully')),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Products (HSN)'),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Search products or HSN...',
                prefixIcon: const Icon(Icons.search),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                suffixIcon: _searchController.text.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: () {
                          _searchController.clear();
                          _loadProducts();
                        },
                      )
                    : null,
              ),
              onChanged: _searchProducts,
            ),
          ),
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _products.isEmpty
                    ? const Center(child: Text('No products found'))
                    : ListView.separated(
                        itemCount: _products.length,
                        separatorBuilder: (context, index) => const Divider(),
                        itemBuilder: (context, index) {
                          final product = _products[index];
                          return ListTile(
                            leading: CircleAvatar(
                              child: Text(product.gstRate.toStringAsFixed(0)),
                              backgroundColor: Colors.green[100],
                              foregroundColor: Colors.green[800],
                            ),
                            title: Text(product.productName),
                            subtitle: Text(
                              'HSN: ${product.hsnCode} | Cat: ${product.productCategory}',
                            ),
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
                                      builder: (context) => ProductFormScreen(product: product),
                                    ),
                                  ).then((v) => v == true ? _loadProducts() : null);
                                } else if (value == 'delete') {
                                  _deleteProduct(product);
                                }
                              },
                            ),
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => ProductFormScreen(product: product),
                                ),
                              ).then((v) => v == true ? _loadProducts() : null);
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
            MaterialPageRoute(builder: (context) => const ProductFormScreen()),
          ).then((v) => v == true ? _loadProducts() : null);
        },
        child: const Icon(Icons.add),
      ),
    );
  }
}
