import 'package:invoice_app/models/invoice_item.dart';

class InvoiceModel {
  int? id;
  String invoiceNumber;
  DateTime invoiceDate;

  // Customer Details
  String customerName;
  String customerAddress;
  String customerCity;
  String customerState;
  String customerPincode;
  String? customerGstin;

  // GST Compliance (Phase 1)
  String placeOfSupply;
  String reverseCharge; // 'Yes' or 'No'
  String supplyType;    // 'Taxable', 'Exempt', etc.

  List<InvoiceItem> items;

  // Totals
  double subtotalVegetables;
  double subtotalFertilizers;
  double cgst;
  double sgst;
  double igst;
  double roundOffAmount;
  double grandTotal;

  String? pdfPath;
  DateTime createdAt;

  InvoiceModel({
    this.id,
    required this.invoiceNumber,
    required this.invoiceDate,
    required this.customerName,
    required this.customerAddress,
    required this.customerCity,
    required this.customerState,
    required this.customerPincode,
    this.customerGstin,
    required this.placeOfSupply,
    required this.reverseCharge,
    required this.supplyType,
    required this.items,
    required this.subtotalVegetables,
    required this.subtotalFertilizers,
    required this.cgst,
    required this.sgst,
    required this.igst,
    this.roundOffAmount = 0.0,
    required this.grandTotal,
    this.pdfPath,
    required this.createdAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'invoice_number': invoiceNumber,
      'invoice_date': invoiceDate.toIso8601String(), // Or format used in DB
      'customer_name': customerName,
      'customer_address': customerAddress,
      'customer_city': customerCity,
      'customer_state': customerState,
      'customer_pincode': customerPincode,
      'customer_gstin': customerGstin,
      'place_of_supply': placeOfSupply,
      'reverse_charge': reverseCharge,
      'supply_type': supplyType,
      'subtotal_vegetables': subtotalVegetables,
      'subtotal_fertilizers': subtotalFertilizers,
      'cgst': cgst,
      'sgst': sgst,
      'igst': igst,
      'round_off_amount': roundOffAmount,
      'grand_total': grandTotal,
      'pdf_path': pdfPath,
      'created_at': createdAt.toIso8601String(),
    };
  }

  factory InvoiceModel.fromMap(Map<String, dynamic> map, List<InvoiceItem> items) {
    return InvoiceModel(
      id: map['id'],
      invoiceNumber: map['invoice_number'],
      invoiceDate: DateTime.tryParse(map['invoice_date']) ?? DateTime.now(), // Adjust based on DB storage format
      customerName: map['customer_name'],
      customerAddress: map['customer_address'],
      customerCity: map['customer_city'],
      customerState: map['customer_state'],
      customerPincode: map['customer_pincode'],
      customerGstin: map['customer_gstin'],
      placeOfSupply: map['place_of_supply'] ?? '',
      reverseCharge: map['reverse_charge'] ?? 'No',
      supplyType: map['supply_type'] ?? 'Taxable',
      items: items,
      subtotalVegetables: (map['subtotal_vegetables'] as num).toDouble(),
      subtotalFertilizers: (map['subtotal_fertilizers'] as num).toDouble(),
      cgst: (map['cgst'] as num).toDouble(),
      sgst: (map['sgst'] as num).toDouble(),
      igst: (map['igst'] as num).toDouble(),
      roundOffAmount: (map['round_off_amount'] as num?)?.toDouble() ?? 0.0,
      grandTotal: (map['grand_total'] as num).toDouble(),
      pdfPath: map['pdf_path'],
      createdAt: DateTime.tryParse(map['created_at']) ?? DateTime.now(),
    );
  }
}
