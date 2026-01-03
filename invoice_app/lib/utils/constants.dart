// lib/utils/constants.dart
// COMPLETE - PRODUCTION READY
// Application Constants & Static Data

class Constants {
  // Indian States (All 36)
  static const List<String> indianStates = [
    'Andaman and Nicobar Islands',
    'Andhra Pradesh',
    'Arunachal Pradesh',
    'Assam',
    'Bihar',
    'Chandigarh',
    'Chhattisgarh',
    'Dadra and Nagar Haveli',
    'Daman and Diu',
    'Delhi',
    'Goa',
    'Gujarat',
    'Haryana',
    'Himachal Pradesh',
    'Jammu and Kashmir',
    'Jharkhand',
    'Karnataka',
    'Kerala',
    'Ladakh',
    'Lakshadweep',
    'Madhya Pradesh',
    'Maharashtra',
    'Manipur',
    'Meghalaya',
    'Mizoram',
    'Nagaland',
    'Odisha',
    'Puducherry',
    'Punjab',
    'Rajasthan',
    'Sikkim',
    'Tamil Nadu',
    'Telangana',
    'Tripura',
    'Uttar Pradesh',
    'Uttarakhand',
    'West Bengal',
  ];

  // Buyer Types
  static const List<String> buyerTypes = [
    'Trader',
    'Manufacturer',
    'Wholesaler',
    'Retailer',
    'Distributor',
    'End User',
    'Government',
    'Export',
  ];

  // Measurement Units
  static const List<String> units = [
    'kg',
    'quintal',
    'ton',
    'liters',
    'piece',
    'bag',
    'box',
    'carton',
  ];

  // Quality Grades
  static const List<String> qualityGrades = [
    'FAQ',
    'Premium',
    'Good',
    'Fair',
    'Standard',
  ];

  // Payment Terms
  static const List<String> paymentTerms = [
    'Net 15',
    'Net 30',
    'Net 60',
    'Advance Payment',
    'Cash on Delivery',
    'Credit',
  ];

  // Invoice Statuses
  static const List<String> invoiceStatuses = [
    'Draft',
    'Sent',
    'Paid',
    'Cancelled',
  ];

  // Supply Types
  static const List<String> supplyTypes = [
    'Taxable',
    'Exempt',
    'Mixed',
  ];

  // Company Details
  static const String companyName = 'JA AGRO INPUTS & TRADING';
  static const String companyGSTIN = '18CCFPB3144R1Z5';
  static const String companyPAN = 'CCFPB3144R';
  static const String companyAddress = 'Dhanehari II, P.O - Saidpur(Mukam), Cachar';
  static const String companyCity = 'Silchar';
  static const String companyState = 'Assam';
  static const String companyPincode = '788013';
  static const String companyPhone = '8133878179';
  static const String companyEmail = 'jaagro@example.com';

  // Bank Details
  static const String bankName = 'State Bank of India';
  static const String bankAccountNumber = '36893269388';
  static const String bankIFSC = 'SBIN0001803';

  // App Settings
  static const String appName = 'JA Agro Invoice';
  static const String appVersion = '1.0.0';
  static const String defaultCurrency = '₹';

  // Date Formats
  static const String displayDateFormat = 'dd-MMM-yyyy';
  static const String isoDateFormat = 'yyyy-MM-dd';
  static const String invoiceDateFormat = 'ddMMyyyy';

  // Validation Patterns
  static const String gstinPattern = r'^\d{2}[A-Z]{5}\d{4}[A-Z]\d[A-Z\d]$';
  static const String panPattern = r'^[A-Z]{5}\d{4}[A-Z]$';
  static const String emailPattern = r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$';
  static const String phonePattern = r'^[6-9]\d{9}$';
  static const String pincodePattern = r'^\d{6}$';
  static const String ifscPattern = r'^[A-Z]{4}0[A-Z0-9]{6}$';

  // Color Scheme
  static const int primaryColorValue = 0xFF2E7D32;
  static const int accentColorValue = 0xFF4CAF50;
  static const int errorColorValue = 0xFFD32F2F;
  static const int warningColorValue = 0xFFFFA726;
  static const int successColorValue = 0xFF66BB6A;

  // Limits
  static const int maxLineItems = 50;
  static const int maxInvoiceNumberLength = 20;
  static const double maxDiscountPercentage = 100.0;
  static const double maxGrandTotal = 10000000.0; // 1 Crore

  // Messages
  static const String noInvoicesMessage = 'No invoices yet. Create your first invoice!';
  static const String noSearchResultsMessage = 'No invoices match your search';
  static const String deleteConfirmMessage = 'Are you sure you want to delete this invoice?';
  static const String unsavedChangesMessage = 'You have unsaved changes. Discard them?';

  // Error Messages
  static const String networkErrorMessage = 'Network error. Please check your connection.';
  static const String databaseErrorMessage = 'Database error. Please try again.';
  static const String validationErrorMessage = 'Please fix the errors and try again.';
  static const String unknownErrorMessage = 'An unknown error occurred.';
}
