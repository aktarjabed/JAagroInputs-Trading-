// lib/services/invoice_service.dart
// COMPLETE - PRODUCTION READY
// Service Layer for Invoice Management

import '../models/invoice_model.dart';
import 'database_helper.dart';

class InvoiceService {
  final _db = InvoiceDatabase.instance;

  Future<String> createInvoice(InvoiceModel invoice) async {
    return await _db.insertInvoice(invoice);
  }

  Future<InvoiceModel?> getInvoice(String id) async {
    return await _db.getInvoice(id);
  }

  Future<List<InvoiceModel>> getAllInvoices() async {
    return await _db.getAllInvoices();
  }

  Future<void> updateInvoice(InvoiceModel invoice) async {
    await _db.updateInvoice(invoice);
  }

  Future<void> deleteInvoice(String id) async {
    await _db.deleteInvoice(id);
  }

  Future<Map<String, dynamic>> getInvoiceStatistics() async {
    return await _db.getInvoiceStatistics();
  }
}
