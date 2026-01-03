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

  static String getStateCode(String stateName) {
    return stateCodes[stateName] ?? '00';
  }

  static String getStateName(String code) {
    return stateCodes.entries
        .firstWhere(
          (entry) => entry.value == code,
          orElse: () => const MapEntry('Unknown', '00'),
        )
        .key;
  }

  static bool validateGSTIN(String gstin) {
    if (gstin.length != 15) return false;

    final stateCode = gstin.substring(0, 2);
    final pan = gstin.substring(2, 12);
    final entityNumber = gstin.substring(12, 13);
    final z = gstin.substring(13, 14);
    final checksum = gstin.substring(14, 15);

    if (!stateCodes.values.contains(stateCode)) return false;
    if (!RegExp(r'^[A-Z]{5}[0-9]{4}[A-Z]$').hasMatch(pan)) return false;
    if (!RegExp(r'^[1-9A-Z]$').hasMatch(entityNumber)) return false;
    if (z != 'Z') return false;
    if (!RegExp(r'^[0-9A-Z]$').hasMatch(checksum)) return false;

    return true;
  }

  static bool validatePAN(String pan) {
    if (pan.length != 10) return false;
    return RegExp(r'^[A-Z]{5}[0-9]{4}[A-Z]$').hasMatch(pan);
  }

  static double calculateCGST(double amount, double rate) {
    return amount * (rate / 100);
  }

  static double calculateSGST(double amount, double rate) {
    return amount * (rate / 100);
  }

  static double calculateIGST(double amount, double rate) {
    return amount * (rate / 100);
  }

  static bool isIntrastate(String supplierState, String buyerState) {
    final supplierCode = getStateCode(supplierState);
    final buyerCode = getStateCode(buyerState);
    return supplierCode == buyerCode;
  }

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

  static double getGSTRateByHSN(String hsnCode) {
    if (hsnCode.startsWith('07')) return 0.0;
    if (hsnCode.startsWith('10')) return 5.0;
    if (hsnCode == '0713') return 0.0;
    if (hsnCode.startsWith('12')) return 5.0;
    if (hsnCode.startsWith('09')) return 5.0;
    if (hsnCode.startsWith('31')) return 5.0;
    if (hsnCode == '3808') return 18.0;
    if (hsnCode == '1209') return 5.0;
    return 18.0;
  }

  static Map<String, double> calculateTax({
    required double amount,
    required String supplierState,
    required String buyerState,
    required double gstRate,
  }) {
    if (isIntrastate(supplierState, buyerState)) {
      final cgst = calculateCGST(amount, gstRate / 2);
      final sgst = calculateSGST(amount, gstRate / 2);
      return {
        'cgst': cgst,
        'sgst': sgst,
        'igst': 0.0,
        'total': cgst + sgst,
      };
    } else {
      final igst = calculateIGST(amount, gstRate);
      return {
        'cgst': 0.0,
        'sgst': 0.0,
        'igst': igst,
        'total': igst,
      };
    }
  }

  static bool validateEmail(String email) {
    return RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(email);
  }

  static bool validatePhone(String phone) {
    return RegExp(r'^[6-9]\d{9}$').hasMatch(phone);
  }

  static bool validatePincode(String pincode) {
    return RegExp(r'^\d{6}$').hasMatch(pincode);
  }

  static bool validateIFSC(String ifsc) {
    return RegExp(r'^[A-Z]{4}0[A-Z0-9]{6}$').hasMatch(ifsc);
  }

  static List<String> getAllStates() {
    return stateCodes.keys.toList()..sort();
  }

  static List<String> getAllStateCodes() {
    return stateCodes.values.toList()..sort();
  }
}
