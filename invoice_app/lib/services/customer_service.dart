import 'package:uuid/uuid.dart';
import '../models/customer_model.dart';
import 'database_helper.dart';

class CustomerService {
  final _db = InvoiceDatabase.instance;

  Future<String> createCustomer(CustomerModel customer) async {
    final db = await _db.database;
    final id = const Uuid().v4();
    final newCustomer = CustomerModel(
      id: id,
      buyerName: customer.buyerName,
      gstin: customer.gstin,
      pan: customer.pan,
      state: customer.state,
      buyerType: customer.buyerType,
      contactPerson: customer.contactPerson,
      phone: customer.phone,
      email: customer.email,
      address: customer.address,
      creditLimit: customer.creditLimit,
      outstandingBalance: customer.outstandingBalance,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );

    await db.insert('buyer_profiles', newCustomer.toMap());
    return id;
  }

  Future<List<CustomerModel>> getAllCustomers() async {
    final db = await _db.database;
    final result = await db.query('buyer_profiles', orderBy: 'buyer_name ASC');
    return result.map((map) => CustomerModel.fromMap(map)).toList();
  }

  Future<CustomerModel?> getCustomer(String id) async {
    final db = await _db.database;
    final result = await db.query(
      'buyer_profiles',
      where: 'id = ?',
      whereArgs: [id],
    );

    if (result.isNotEmpty) {
      return CustomerModel.fromMap(result.first);
    }
    return null;
  }

  Future<int> updateCustomer(CustomerModel customer) async {
    final db = await _db.database;
    return await db.update(
      'buyer_profiles',
      customer.toMap()..['updated_at'] = DateTime.now().toIso8601String(),
      where: 'id = ?',
      whereArgs: [customer.id],
    );
  }

  Future<int> deleteCustomer(String id) async {
    final db = await _db.database;
    return await db.delete(
      'buyer_profiles',
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future<List<CustomerModel>> searchCustomers(String query) async {
    final db = await _db.database;
    final result = await db.query(
      'buyer_profiles',
      where: 'buyer_name LIKE ? OR gstin LIKE ?',
      whereArgs: ['%$query%', '%$query%'],
    );
    return result.map((map) => CustomerModel.fromMap(map)).toList();
  }
}
