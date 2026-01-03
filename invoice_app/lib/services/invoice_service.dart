// lib/services/invoice_service.dart
// COMPLETE - PRODUCTION READY
// Business Logic Layer for Invoice Operations

import '../models/invoice_model.dart';
import 'database_helper.dart';

class InvoiceService {
  final _db = InvoiceDatabase.instance;

  Future<List<InvoiceModel>> getAllInvoices() async {
    try {
      return await _db.getAllInvoices();
    } catch (e) {
      throw Exception('Failed to load invoices: $e');
    }
  }

  Future<InvoiceModel?> getInvoice(String id) async {
    try {
      return await _db.getInvoice(id);
    } catch (e) {
      throw Exception('Failed to load invoice: $e');
    }
  }

  Future<String> createInvoice(InvoiceModel invoice) async {
    try {
      _validateInvoice(invoice);
      return await _db.insertInvoice(invoice);
    } catch (e) {
      throw Exception('Failed to create invoice: $e');
    }
  }

  Future<int> updateInvoice(InvoiceModel invoice) async {
    try {
      _validateInvoice(invoice);
      return await _db.updateInvoice(invoice);
    } catch (e) {
      throw Exception('Failed to update invoice: $e');
    }
  }

  Future<int> deleteInvoice(String id) async {
    try {
      return await _db.deleteInvoice(id);
    } catch (e) {
      throw Exception('Failed to delete invoice: $e');
    }
  }

  Future<List<InvoiceModel>> searchInvoices(String query) async {
    try {
      final allInvoices = await getAllInvoices();

      if (query.isEmpty) return allInvoices;

      final lowercaseQuery = query.toLowerCase();

      return allInvoices.where((invoice) {
        return invoice.invoiceNumber.toLowerCase().contains(lowercaseQuery) ||
            invoice.buyerName.toLowerCase().contains(lowercaseQuery) ||
            invoice.buyerGSTIN.toLowerCase().contains(lowercaseQuery);
      }).toList();
    } catch (e) {
      throw Exception('Failed to search invoices: $e');
    }
  }

  Future<List<InvoiceModel>> filterByStatus(String status) async {
    try {
      final allInvoices = await getAllInvoices();

      if (status == 'All') return allInvoices;

      return allInvoices.where((invoice) => invoice.status == status).toList();
    } catch (e) {
      throw Exception('Failed to filter invoices: $e');
    }
  }

  Future<Map<String, dynamic>> getInvoiceStatistics() async {
    try {
      return await _db.getInvoiceStatistics();
    } catch (e) {
      throw Exception('Failed to get statistics: $e');
    }
  }

  Future<List<InvoiceModel>> getInvoicesByDateRange(
    DateTime startDate,
    DateTime endDate,
  ) async {
    try {
      final allInvoices = await getAllInvoices();

      return allInvoices.where((invoice) {
        return invoice.date.isAfter(startDate.subtract(const Duration(days: 1))) &&
            invoice.date.isBefore(endDate.add(const Duration(days: 1)));
      }).toList();
    } catch (e) {
      throw Exception('Failed to get invoices by date range: $e');
    }
  }

  Future<List<InvoiceModel>> getInvoicesByBuyer(String buyerGSTIN) async {
    try {
      final allInvoices = await getAllInvoices();

      return allInvoices.where((invoice) => invoice.buyerGSTIN == buyerGSTIN).toList();
    } catch (e) {
      throw Exception('Failed to get invoices by buyer: $e');
    }
  }

  Future<double> getTotalOutstanding() async {
    try {
      final allInvoices = await getAllInvoices();

      return allInvoices
          .where((invoice) => invoice.status != 'Paid' && invoice.status != 'Cancelled')
          .fold(0.0, (sum, invoice) => sum + invoice.grandTotal);
    } catch (e) {
      throw Exception('Failed to get total outstanding: $e');
    }
  }

  Future<double> getTotalPaid() async {
    try {
      final allInvoices = await getAllInvoices();

      return allInvoices
          .where((invoice) => invoice.status == 'Paid')
          .fold(0.0, (sum, invoice) => sum + invoice.grandTotal);
    } catch (e) {
      throw Exception('Failed to get total paid: $e');
    }
  }

  Future<Map<String, int>> getInvoiceCountByStatus() async {
    try {
      final allInvoices = await getAllInvoices();

      final Map<String, int> counts = {
        'Draft': 0,
        'Sent': 0,
        'Paid': 0,
        'Cancelled': 0,
      };

      for (final invoice in allInvoices) {
        counts[invoice.status] = (counts[invoice.status] ?? 0) + 1;
      }

      return counts;
    } catch (e) {
      throw Exception('Failed to get invoice count by status: $e');
    }
  }

  void _validateInvoice(InvoiceModel invoice) {
    if (invoice.invoiceNumber.isEmpty) {
      throw Exception('Invoice number is required');
    }

    if (invoice.buyerName.isEmpty) {
      throw Exception('Buyer name is required');
    }

    if (invoice.buyerGSTIN.isEmpty) {
      throw Exception('Buyer GSTIN is required');
    }

    if (invoice.buyerPAN.isEmpty) {
      throw Exception('Buyer PAN is required');
    }

    if (invoice.items.isEmpty) {
      throw Exception('At least one line item is required');
    }

    if (invoice.grandTotal <= 0) {
      throw Exception('Invoice total must be greater than zero');
    }
  }

  Future<InvoiceModel> duplicateInvoice(String invoiceId) async {
    try {
      final original = await getInvoice(invoiceId);
      if (original == null) {
        throw Exception('Invoice not found');
      }

      final duplicate = InvoiceModel(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        invoiceNumber: 'INV-${DateTime.now().millisecondsSinceEpoch}',
        date: DateTime.now(),
        buyerName: original.buyerName,
        buyerGSTIN: original.buyerGSTIN,
        buyerPAN: original.buyerPAN,
        buyerState: original.buyerState,
        buyerType: original.buyerType,
        buyerContactPerson: original.buyerContactPerson,
        placeOfSupply: original.placeOfSupply,
        supplyType: original.supplyType,
        reverseChargeMechanism: original.reverseChargeMechanism,
        items: original.items,
        subtotal: original.subtotal,
        cgstAmount: original.cgstAmount,
        sgstAmount: original.sgstAmount,
        igstAmount: original.igstAmount,
        totalTaxAmount: original.totalTaxAmount,
        discountAmount: original.discountAmount,
        grandTotal: original.grandTotal,
        amountInWords: original.amountInWords,
        paymentTerms: original.paymentTerms,
        paymentDueDate: DateTime.now().add(const Duration(days: 30)),
        status: 'Draft',
        deliveryAddress: original.deliveryAddress,
        deliveryDate: null,
        poReferenceNumber: '',
        eWayBillNumber: '',
        transporterName: original.transporterName,
        vehicleNumber: '',
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      await createInvoice(duplicate);
      return duplicate;
    } catch (e) {
      throw Exception('Failed to duplicate invoice: $e');
    }
  }

  Future<String> exportToCSV(List<InvoiceModel> invoices) async {
    try {
      final buffer = StringBuffer();

      buffer.writeln('Invoice Number,Date,Buyer Name,Buyer GSTIN,Amount,Tax,Total,Status');

      for (final invoice in invoices) {
        buffer.writeln(
          '${invoice.invoiceNumber},'
          '${invoice.getFormattedDate()},'
          '${invoice.buyerName},'
          '${invoice.buyerGSTIN},'
          '${invoice.subtotal.toStringAsFixed(2)},'
          '${invoice.totalTaxAmount.toStringAsFixed(2)},'
          '${invoice.grandTotal.toStringAsFixed(2)},'
          '${invoice.status}',
        );
      }

      return buffer.toString();
    } catch (e) {
      throw Exception('Failed to export to CSV: $e');
    }
  }

  Future<List<Map<String, dynamic>>> getHSNCodes() async {
    try {
      return await _db.getHSNCodes();
    } catch (e) {
      throw Exception('Failed to load HSN codes: $e');
    }
  }

  Future<Map<String, dynamic>?> getHSNCodeDetails(String hsnCode) async {
    try {
      return await _db.getHSNCodeDetails(hsnCode);
    } catch (e) {
      throw Exception('Failed to load HSN code details: $e');
    }
  }
}
