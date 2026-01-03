// lib/models/invoice_model.dart
// COMPLETE - PRODUCTION READY
// Data Models for Invoice & Invoice Items

import 'package:intl/intl.dart';

class InvoiceModel {
  final String id;
  final String invoiceNumber;
  final DateTime date;
  final String buyerName;
  final String buyerGSTIN;
  final String buyerPAN;
  final String buyerState;
  final String buyerType;
  final String buyerContactPerson;
  final String placeOfSupply;
  final String supplyType;
  final String reverseChargeMechanism;
  final List<InvoiceItemModel> items;
  final double subtotal;
  final double cgstAmount;
  final double sgstAmount;
  final double igstAmount;
  final double totalTaxAmount;
  final double discountAmount;
  final double grandTotal;
  final String amountInWords;
  final String paymentTerms;
  final DateTime paymentDueDate;
  final String status;
  final String deliveryAddress;
  final DateTime? deliveryDate;
  final String poReferenceNumber;
  final String eWayBillNumber;
  final String transporterName;
  final String vehicleNumber;
  final DateTime createdAt;
  final DateTime updatedAt;

  InvoiceModel({
    required this.id,
    required this.invoiceNumber,
    required this.date,
    required this.buyerName,
    required this.buyerGSTIN,
    required this.buyerPAN,
    required this.buyerState,
    required this.buyerType,
    required this.buyerContactPerson,
    required this.placeOfSupply,
    required this.supplyType,
    required this.reverseChargeMechanism,
    required this.items,
    required this.subtotal,
    required this.cgstAmount,
    required this.sgstAmount,
    required this.igstAmount,
    required this.totalTaxAmount,
    required this.discountAmount,
    required this.grandTotal,
    required this.amountInWords,
    required this.paymentTerms,
    required this.paymentDueDate,
    required this.status,
    this.deliveryAddress = '',
    this.deliveryDate,
    this.poReferenceNumber = '',
    this.eWayBillNumber = '',
    this.transporterName = '',
    this.vehicleNumber = '',
    required this.createdAt,
    required this.updatedAt,
  });

  String getFormattedDate() {
    return DateFormat('dd-MMM-yyyy').format(date);
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'invoice_number': invoiceNumber,
      'date': date.toIso8601String(),
      'buyer_name': buyerName,
      'buyer_gstin': buyerGSTIN,
      'buyer_pan': buyerPAN,
      'buyer_state': buyerState,
      'buyer_type': buyerType,
      'buyer_contact_person': buyerContactPerson,
      'place_of_supply': placeOfSupply,
      'supply_type': supplyType,
      'reverse_charge_mechanism': reverseChargeMechanism,
      'subtotal': subtotal,
      'cgst_amount': cgstAmount,
      'sgst_amount': sgstAmount,
      'igst_amount': igstAmount,
      'total_tax_amount': totalTaxAmount,
      'discount_amount': discountAmount,
      'grand_total': grandTotal,
      'amount_in_words': amountInWords,
      'payment_terms': paymentTerms,
      'payment_due_date': paymentDueDate.toIso8601String(),
      'status': status,
      'delivery_address': deliveryAddress,
      'delivery_date': deliveryDate?.toIso8601String(),
      'po_reference_number': poReferenceNumber,
      'e_way_bill_number': eWayBillNumber,
      'transporter_name': transporterName,
      'vehicle_number': vehicleNumber,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  static InvoiceModel fromMap(Map<String, dynamic> map, List<Map<String, dynamic>> itemMaps) {
    return InvoiceModel(
      id: map['id'],
      invoiceNumber: map['invoice_number'],
      date: DateTime.parse(map['date']),
      buyerName: map['buyer_name'],
      buyerGSTIN: map['buyer_gstin'],
      buyerPAN: map['buyer_pan'],
      buyerState: map['buyer_state'],
      buyerType: map['buyer_type'],
      buyerContactPerson: map['buyer_contact_person'],
      placeOfSupply: map['place_of_supply'],
      supplyType: map['supply_type'],
      reverseChargeMechanism: map['reverse_charge_mechanism'],
      items: itemMaps.map((itemMap) => InvoiceItemModel.fromMap(itemMap)).toList(),
      subtotal: map['subtotal'],
      cgstAmount: map['cgst_amount'],
      sgstAmount: map['sgst_amount'],
      igstAmount: map['igst_amount'],
      totalTaxAmount: map['total_tax_amount'],
      discountAmount: map['discount_amount'],
      grandTotal: map['grand_total'],
      amountInWords: map['amount_in_words'],
      paymentTerms: map['payment_terms'],
      paymentDueDate: DateTime.parse(map['payment_due_date']),
      status: map['status'],
      deliveryAddress: map['delivery_address'] ?? '',
      deliveryDate: map['delivery_date'] != null ? DateTime.parse(map['delivery_date']) : null,
      poReferenceNumber: map['po_reference_number'] ?? '',
      eWayBillNumber: map['e_way_bill_number'] ?? '',
      transporterName: map['transporter_name'] ?? '',
      vehicleNumber: map['vehicle_number'] ?? '',
      createdAt: DateTime.parse(map['created_at']),
      updatedAt: DateTime.parse(map['updated_at']),
    );
  }
}

class InvoiceItemModel {
  final String id;
  final String hsnCode;
  final String productName;
  final String? productCategory;
  final double quantity;
  final String unit;
  final double rate;
  final double lineTotal;
  final String? batchNumber;
  final String? expiryDate;
  final String? qualityGrade;
  final String? storageLocation;

  InvoiceItemModel({
    required this.id,
    required this.hsnCode,
    required this.productName,
    this.productCategory,
    required this.quantity,
    required this.unit,
    required this.rate,
    this.batchNumber,
    this.expiryDate,
    this.qualityGrade,
    this.storageLocation,
  }) : lineTotal = quantity * rate;

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'hsn_code': hsnCode,
      'product_name': productName,
      'product_category': productCategory,
      'quantity': quantity,
      'unit': unit,
      'rate': rate,
      'line_total': lineTotal,
      'batch_number': batchNumber,
      'expiry_date': expiryDate,
      'quality_grade': qualityGrade,
      'storage_location': storageLocation,
    };
  }

  static InvoiceItemModel fromMap(Map<String, dynamic> map) {
    return InvoiceItemModel(
      id: map['id'],
      hsnCode: map['hsn_code'],
      productName: map['product_name'],
      productCategory: map['product_category'],
      quantity: map['quantity'],
      unit: map['unit'],
      rate: map['rate'],
      batchNumber: map['batch_number'],
      expiryDate: map['expiry_date'],
      qualityGrade: map['quality_grade'],
      storageLocation: map['storage_location'],
    );
  }
}
