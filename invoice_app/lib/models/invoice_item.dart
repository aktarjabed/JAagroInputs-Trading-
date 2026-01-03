import 'dart:convert';
import 'package:flutter/foundation.dart';

class InvoiceItem {
  String description;
  String hsnCode;
  double quantity;
  String unit;
  double rate;
  double gstRate;

  InvoiceItem({
    required this.description,
    required this.hsnCode,
    required this.quantity,
    required this.unit,
    required this.rate,
    required this.gstRate,
  });

  double get amount => quantity * rate;
  double get gstAmount => amount * (gstRate / 100);
  double get total => amount + gstAmount;

  Map<String, dynamic> toJson() => {
        'description': description,
        'hsnCode': hsnCode,
        'quantity': quantity,
        'unit': unit,
        'rate': rate,
        'gstRate': gstRate,
      };

  factory InvoiceItem.fromJson(Map<String, dynamic> json) => InvoiceItem(
        description: json['description'],
        hsnCode: json['hsnCode'],
        quantity: (json['quantity'] as num).toDouble(),
        unit: json['unit'],
        rate: (json['rate'] as num).toDouble(),
        gstRate: (json['gstRate'] as num).toDouble(),
      );

  static List<InvoiceItem> parseItems(String itemsJson) {
    try {
      final List<dynamic> decoded = jsonDecode(itemsJson);
      return decoded.map((item) => InvoiceItem.fromJson(item)).toList();
    } catch (e) {
      debugPrint('Error parsing items: $e');
      return [];
    }
  }

  InvoiceItem copyWith({
    String? description,
    String? hsnCode,
    double? quantity,
    String? unit,
    double? rate,
    double? gstRate,
  }) {
    return InvoiceItem(
      description: description ?? this.description,
      hsnCode: hsnCode ?? this.hsnCode,
      quantity: quantity ?? this.quantity,
      unit: unit ?? this.unit,
      rate: rate ?? this.rate,
      gstRate: gstRate ?? this.gstRate,
    );
  }
}
