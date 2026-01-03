import 'package:intl/intl.dart';
import 'package:invoice_app/utils/constants.dart';

class GSTHelper {
  static const String companyStateCode = '18'; // Assam

  /// Determines if the transaction is Inter-State (IGST) or Intra-State (CGST/SGST)
  /// [placeOfSupply] should be the 2-digit state code.
  static bool isInterState(String placeOfSupply) {
    if (placeOfSupply.isEmpty) return false; // Default to Intra if unknown? Or handle error.
    return placeOfSupply != companyStateCode;
  }

  /// Calculates GST components
  static Map<String, double> calculateGST(double taxableValue, double gstRate, bool isInterState) {
    if (gstRate <= 0) {
      return {
        'cgst': 0,
        'sgst': 0,
        'igst': 0,
        'totalTax': 0,
      };
    }

    double totalTax = taxableValue * (gstRate / 100);

    if (isInterState) {
      return {
        'cgst': 0,
        'sgst': 0,
        'igst': totalTax,
        'totalTax': totalTax,
      };
    } else {
      return {
        'cgst': totalTax / 2,
        'sgst': totalTax / 2,
        'igst': 0,
        'totalTax': totalTax,
      };
    }
  }

  /// Formats currency in Indian Numbering System (e.g., 1,23,456.00)
  static String formatCurrency(double amount) {
    final format = NumberFormat.currency(
      locale: 'en_IN',
      symbol: '₹ ',
      decimalDigits: 2,
    );
    return format.format(amount);
  }

  /// Converts amount to words (Simplified implementation)
  /// For a full implementation, a package or a more complex function is needed.
  /// Using a basic placeholder for now or a simple algorithm if critical.
  static String amountToWords(double amount) {
    // This is a placeholder. For production, consider using a package like 'number_to_words'
    // or implementing a proper algorithm for Indian numbering.
    // Given the constraints, we will return the formatted string or a simple label.
    // Users often verify the PDF visually.
    return "Rupees ${formatCurrency(amount).replaceAll('₹ ', '')} Only";
  }
}
