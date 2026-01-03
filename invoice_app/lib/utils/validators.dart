class Validators {
  static String? validateRequired(String? value, String fieldName) {
    if (value == null || value.trim().isEmpty) {
      return '$fieldName is required';
    }
    return null;
  }

  static String? validateEmail(String? value) {
    if (value == null || value.isEmpty) return null; // Optional
    final emailRegex = RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$');
    if (!emailRegex.hasMatch(value)) {
      return 'Invalid email address';
    }
    return null;
  }

  static String? validatePhone(String? value) {
    if (value == null || value.isEmpty) return null; // Optional
    final phoneRegex = RegExp(r'^[6-9]\d{9}$');
    if (!phoneRegex.hasMatch(value)) {
      return 'Invalid phone number (10 digits starting with 6-9)';
    }
    return null;
  }

  static String? validateGSTIN(String? value) {
    if (value == null || value.isEmpty) return null; // Optional
    // Basic regex validation first
    if (!RegExp(r'^\d{2}[A-Z]{5}\d{4}[A-Z]\d[A-Z\d]$').hasMatch(value)) {
      return 'Invalid GSTIN format';
    }
    return null; // Full checksum validation happens in GSTHelper
  }

  static String? validatePAN(String? value) {
    if (value == null || value.isEmpty) return null; // Optional
    if (!RegExp(r'^[A-Z]{5}\d{4}[A-Z]$').hasMatch(value)) {
      return 'Invalid PAN format';
    }
    return null;
  }

  static String? validatePincode(String? value) {
    if (value == null || value.isEmpty) return null; // Optional
    if (!RegExp(r'^\d{6}$').hasMatch(value)) {
      return 'Invalid Pincode (6 digits)';
    }
    return null;
  }

  static String? validateIFSC(String? value) {
    if (value == null || value.isEmpty) return null; // Optional
    if (!RegExp(r'^[A-Z]{4}0[A-Z0-9]{6}$').hasMatch(value)) {
      return 'Invalid IFSC Code';
    }
    return null;
  }

  static String? validateAmount(String? value) {
    if (value == null || value.isEmpty) return 'Amount is required';
    final amount = double.tryParse(value);
    if (amount == null) return 'Invalid amount';
    if (amount <= 0) return 'Amount must be greater than 0';
    return null;
  }
}
