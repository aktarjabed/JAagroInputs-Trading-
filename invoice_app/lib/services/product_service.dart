import '../models/product_model.dart';
import 'database_helper.dart';

class ProductService {
  final _db = InvoiceDatabase.instance;

  Future<int> createProduct(ProductModel product) async {
    final db = await _db.database;
    return await db.insert('hsn_codes', product.toMap()..remove('id'));
  }

  Future<List<ProductModel>> getAllProducts() async {
    final db = await _db.database;
    final result = await db.query('hsn_codes', orderBy: 'hsn_code ASC');
    return result.map((map) => ProductModel.fromMap(map)).toList();
  }

  Future<int> updateProduct(ProductModel product) async {
    final db = await _db.database;
    return await db.update(
      'hsn_codes',
      product.toMap(),
      where: 'id = ?',
      whereArgs: [product.id],
    );
  }

  Future<int> deleteProduct(int id) async {
    final db = await _db.database;
    return await db.delete(
      'hsn_codes',
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future<List<ProductModel>> searchProducts(String query) async {
    final db = await _db.database;
    final result = await db.query(
      'hsn_codes',
      where: 'product_name LIKE ? OR hsn_code LIKE ?',
      whereArgs: ['%$query%', '%$query%'],
    );
    return result.map((map) => ProductModel.fromMap(map)).toList();
  }

  Future<List<ProductModel>> getProductsByCategory(String category) async {
    final db = await _db.database;
    final result = await db.query(
      'hsn_codes',
      where: 'product_category = ?',
      whereArgs: [category],
    );
    return result.map((map) => ProductModel.fromMap(map)).toList();
  }
}
