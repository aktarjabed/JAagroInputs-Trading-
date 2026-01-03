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

  Future<String> getNextInvoiceNumber() async {
    final db = await _db.database;
    final result = await db.rawQuery(
      'SELECT invoice_number FROM invoices ORDER BY created_at DESC LIMIT 1'
    );

    final currentYear = DateTime.now().year;

    if (result.isEmpty) {
      return 'JA${currentYear}001'; // First invoice
    }

    String lastNumber = result.first['invoice_number'] as String;

    // Check if format matches "JA2025001" (length 9)
    if (lastNumber.length != 9 || !lastNumber.startsWith('JA')) {
       return 'JA${currentYear}001'; // Fallback if format is weird
    }

    try {
      // Extract number: JA2025001 -> 001 (substring(6))
      int numPart = int.parse(lastNumber.substring(6));
      numPart++; // Increment

      // Format back: 2 -> JA2025002
      return 'JA$currentYear${numPart.toString().padLeft(3, '0')}';
    } catch (e) {
      return 'JA${currentYear}001'; // Fallback on parse error
    }
  }
}
