// lib/services/tax_calculator_service.dart

import '../models/invoice_model.dart';

class TaxCalculatorService {
  /// Groups tax amounts by their GST rate.
  ///
  /// Calculates the tax component for each item based on its rate, quantity, and GST percentage.
  /// Returns a map where the key is the GST rate (e.g., 5.0, 18.0) and the value is the total tax amount for that rate.
  Map<double, double> groupTaxByRate(List<InvoiceItem> items, {required bool isInterstate}) {
    Map<double, double> taxGroups = {};

    for (var item in items) {
      // Calculate tax amount for this line item: (Rate * Quantity) * (GST% / 100)
      double calculatedTax = (item.quantity * item.rate) * (item.gstRate / 100);

      taxGroups[item.gstRate] = (taxGroups[item.gstRate] ?? 0) + calculatedTax;
    }

    return taxGroups;
  }
}
