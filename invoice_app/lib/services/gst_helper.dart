// lib/services/gst_helper.dart
// COMPLETE - PRODUCTION READY
// GST Calculations, Validations & Indian States Mapping

class GSTHelper {
  // All 36 Indian States with State Codes
  static const Map<String, String> stateCodes = {
    'Andaman and Nicobar Islands': '35',
    'Andhra Pradesh': '28',
    'Arunachal Pradesh': '12',
    'Assam': '18',
    'Bihar': '10',
    'Chandigarh': '04',
    'Chhattisgarh': '22',
    'Dadra and Nagar Haveli': '26',
    'Daman and Diu': '25',
    'Delhi': '07',
    'Goa': '30',
    'Gujarat': '24',
    'Haryana': '06',
    'Himachal Pradesh': '02',
    'Jammu and Kashmir': '01',
    'Jharkhand': '20',
    'Karnataka': '29',
    'Kerala': '32',
    'Ladakh': '38',
    'Lakshadweep': '31',
    'Madhya Pradesh': '23',
    'Maharashtra': '27',
    'Manipur': '14',
    'Meghalaya': '17',
    'Mizoram': '15',
    'Nagaland': '13',
    'Odisha': '21',
    'Puducherry': '34',
    'Punjab': '03',
    'Rajasthan': '08',
    'Sikkim': '11',
    'Tamil Nadu': '33',
    'Telangana': '36',
    'Tripura': '16',
    'Uttar Pradesh': '09',
    'Uttarakhand': '05',
    'West Bengal': '19',
  };

  // Get state code by state name
  static String getStateCode(String stateName) {
    return stateCodes[stateName] ?? '00';
  }

  // Get state name by code
  static String getStateName(String code) {
    return stateCodes.entries
        .firstWhere(
          (entry) => entry.value == code,
          orElse: () => const MapEntry('Unknown', '00'),
        )
        .key;
  }

  // Validate GSTIN format (15 characters)
  // Format: 2 digits (state code) + 10 chars (PAN) + 1 digit + 1 char (Z) + 1 digit/char
  static bool validateGSTIN(String gstin) {
    if (gstin.length != 15) return false;

    final stateCode = gstin.substring(0, 2);
    final pan = gstin.substring(2, 12);
    final entityNumber = gstin.substring(12, 13);
    final z = gstin.substring(13, 14);
    final checksum = gstin.substring(14, 15);

    // Validate state code
    if (!stateCodes.values.contains(stateCode)) return false;

    // Validate PAN format (first 5 letters, next 4 digits, last 1 letter)
    if (!RegExp(r'^[A-Z]{5}[0-9]{4}[A-Z]$').hasMatch(pan)) return false;

    // Validate entity number (1-9, A-Z)
    if (!RegExp(r'^[1-9A-Z]$').hasMatch(entityNumber)) return false;

    // Z should be 'Z'
    if (z != 'Z') return false;

    // Checksum (alphanumeric)
    if (!RegExp(r'^[0-9A-Z]$').hasMatch(checksum)) return false;

    return true;
  }

  // Validate PAN format
  // Format: 5 letters + 4 digits + 1 letter
  static bool validatePAN(String pan) {
    if (pan.length != 10) return false;
    return RegExp(r'^[A-Z]{5}[0-9]{4}[A-Z]$').hasMatch(pan);
  }

  // Calculate CGST (Central GST)
  static double calculateCGST(double amount, double rate) {
    return amount * (rate / 100);
  }

  // Calculate SGST (State GST)
  static double calculateSGST(double amount, double rate) {
    return amount * (rate / 100);
  }

  // Calculate IGST (Integrated GST)
  static double calculateIGST(double amount, double rate) {
    return amount * (rate / 100);
  }

  // Determine if transaction is intrastate or interstate
  static bool isIntrastate(String supplierState, String buyerState) {
    final supplierCode = getStateCode(supplierState);
    final buyerCode = getStateCode(buyerState);
    return supplierCode == buyerCode;
  }

  // Convert amount to words (Indian numbering system - Crore, Lakh)
  static String convertAmountToWords(double amount) {
    if (amount == 0) return 'Zero Rupees Only';

    final intPart = amount.floor();
    final decimalPart = ((amount - intPart) * 100).round();

    String words = _convertIntegerToWords(intPart);

    if (decimalPart > 0) {
      words += ' and ${_convertIntegerToWords(decimalPart)} Paise';
    }

    return '$words Only';
  }

  static String _convertIntegerToWords(int number) {
    if (number == 0) return 'Zero Rupees';

    final crore = number ~/ 10000000;
    final lakh = (number % 10000000) ~/ 100000;
    final thousand = (number % 100000) ~/ 1000;
    final hundred = (number % 1000) ~/ 100;
    final remainder = number % 100;

    String result = '';

    if (crore > 0) {
      result += '${_convertTwoDigits(crore)} Crore ';
    }

    if (lakh > 0) {
      result += '${_convertTwoDigits(lakh)} Lakh ';
    }

    if (thousand > 0) {
      result += '${_convertTwoDigits(thousand)} Thousand ';
    }

    if (hundred > 0) {
      result += '${_convertOneDigit(hundred)} Hundred ';
    }

    if (remainder > 0) {
      result += _convertTwoDigits(remainder);
    }

    return result.trim() + ' Rupees';
  }

  static String _convertOneDigit(int number) {
    const ones = [
      '', 'One', 'Two', 'Three', 'Four', 'Five', 'Six', 'Seven', 'Eight', 'Nine'
    ];
    return ones[number];
  }

  static String _convertTwoDigits(int number) {
    if (number < 10) return _convertOneDigit(number);
    if (number < 20) return _convertTeens(number);

    const tens = [
      '', '', 'Twenty', 'Thirty', 'Forty', 'Fifty', 'Sixty', 'Seventy', 'Eighty', 'Ninety'
    ];

    final tensPart = number ~/ 10;
    final onesPart = number % 10;

    String result = tens[tensPart];
    if (onesPart > 0) {
      result += ' ${_convertOneDigit(onesPart)}';
    }

    return result.trim();
  }

  static String _convertTeens(int number) {
    const teens = [
      'Ten', 'Eleven', 'Twelve', 'Thirteen', 'Fourteen',
      'Fifteen', 'Sixteen', 'Seventeen', 'Eighteen', 'Nineteen'
    ];
    return teens[number - 10];
  }

  // Get GST rate by HSN code (simplified)
  static double getGSTRateByHSN(String hsnCode) {
    // Vegetables (0701-0709)
    if (hsnCode.startsWith('07')) return 0.0;

    // Cereals (1001-1008)
    if (hsnCode.startsWith('10')) return 5.0;

    // Pulses (0713)
    if (hsnCode == '0713') return 0.0;

    // Oil Seeds (1201-1207)
    if (hsnCode.startsWith('12')) return 5.0;

    // Spices (0904-0910)
    if (hsnCode.startsWith('09')) return 5.0;

    // Fertilizers (3102-3105)
    if (hsnCode.startsWith('31')) return 5.0;

    // Pesticides (3808)
    if (hsnCode == '3808') return 18.0;

    // Seeds (1209)
    if (hsnCode == '1209') return 5.0;

    // Default
    return 18.0;
  }

  // Calculate total tax (CGST + SGST or IGST)
  static Map<String, double> calculateTax({
    required double amount,
    required String supplierState,
    required String buyerState,
    required double gstRate,
  }) {
    if (isIntrastate(supplierState, buyerState)) {
      // Intrastate - CGST + SGST
      final cgst = calculateCGST(amount, gstRate / 2);
      final sgst = calculateSGST(amount, gstRate / 2);
      return {
        'cgst': cgst,
        'sgst': sgst,
        'igst': 0.0,
        'total': cgst + sgst,
      };
    } else {
      // Interstate - IGST
      final igst = calculateIGST(amount, gstRate);
      return {
        'cgst': 0.0,
        'sgst': 0.0,
        'igst': igst,
        'total': igst,
      };
    }
  }

  // Validate email
  static bool validateEmail(String email) {
    return RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(email);
  }

  // Validate phone (10 digits)
  static bool validatePhone(String phone) {
    return RegExp(r'^[6-9]\d{9}$').hasMatch(phone);
  }

  // Validate pincode (6 digits)
  static bool validatePincode(String pincode) {
    return RegExp(r'^\d{6}$').hasMatch(pincode);
  }

  // Validate IFSC code
  static bool validateIFSC(String ifsc) {
    return RegExp(r'^[A-Z]{4}0[A-Z0-9]{6}$').hasMatch(ifsc);
  }

  // Get all state names
  static List<String> getAllStates() {
    return stateCodes.keys.toList()..sort();
  }

  // Get all state codes
  static List<String> getAllStateCodes() {
    return stateCodes.values.toList()..sort();
  }
}
