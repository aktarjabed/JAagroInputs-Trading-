class Constants {
  // State Codes for GST
  static const Map<String, String> stateCodes = {
    '01': 'Jammu & Kashmir',
    '02': 'Himachal Pradesh',
    '03': 'Punjab',
    '04': 'Chandigarh',
    '05': 'Uttarakhand',
    '06': 'Haryana',
    '07': 'Delhi',
    '08': 'Rajasthan',
    '09': 'Uttar Pradesh',
    '10': 'Bihar',
    '11': 'Sikkim',
    '12': 'Arunachal Pradesh',
    '13': 'Nagaland',
    '14': 'Manipur',
    '15': 'Mizoram',
    '16': 'Tripura',
    '17': 'Meghalaya',
    '18': 'Assam',
    '19': 'West Bengal',
    '20': 'Jharkhand',
    '21': 'Odisha',
    '22': 'Chhattisgarh',
    '23': 'Madhya Pradesh',
    '24': 'Gujarat',
    '25': 'Daman & Diu',
    '26': 'Dadra & Nagar Haveli',
    '27': 'Maharashtra',
    '29': 'Karnataka',
    '30': 'Goa',
    '31': 'Lakshadweep',
    '32': 'Kerala',
    '33': 'Tamil Nadu',
    '34': 'Puducherry',
    '35': 'Andaman & Nicobar Islands',
    '36': 'Telangana',
    '37': 'Andhra Pradesh',
    '38': 'Ladakh',
    '97': 'Other Territory',
  };

  static String getStateCode(String stateName) {
    var entry = stateCodes.entries.firstWhere(
      (element) => element.value.toLowerCase() == stateName.toLowerCase(),
      orElse: () => const MapEntry('', ''),
    );
    return entry.key; // Returns key (code) like '18' for Assam
  }

  static String getStateName(String code) {
    return stateCodes[code] ?? code;
  }

  // HSN Categories
  static const Map<String, String> hsnCategories = {
    '0701': 'Vegetables',
    '0702': 'Vegetables',
    '0703': 'Vegetables',
    '0704': 'Vegetables',
    '0705': 'Vegetables',
    '0706': 'Vegetables',
    '0707': 'Vegetables',
    '0708': 'Vegetables',
    '0709': 'Vegetables',
    '0710': 'Vegetables',
    '0801': 'Fruits',
    '0803': 'Fruits',
    '0804': 'Fruits',
    '0805': 'Fruits',
    '0806': 'Fruits',
    '0807': 'Fruits',
    '0808': 'Fruits',
    '0809': 'Fruits',
    '1001': 'Cereals',
    '1005': 'Cereals',
    '1006': 'Cereals',
    '1202': 'Pulses',
    '3101': 'Fertilizers',
    '3102': 'Fertilizers',
    '3103': 'Fertilizers',
    '3104': 'Fertilizers',
    '3105': 'Fertilizers',
    '3808': 'Pesticides',
    '8201': 'Tools',
    '8424': 'Machinery',
    '8432': 'Machinery',
    '5607': 'Packaging',
    '3920': 'Packaging',
  };

  static const List<String> productCategories = [
    'Vegetables',
    'Fruits',
    'Cereals',
    'Pulses',
    'Fertilizers',
    'Pesticides',
    'Seeds',
    'Tools',
    'Machinery',
    'Packaging',
    'Others',
  ];

  static const List<String> units = [
    'Kg',
    'Quintal',
    'Ton',
    'Liter',
    'Bag',
    'Piece',
    'Dozen',
    'Box',
    'Packet',
  ];

  static const List<String> qualityGrades = [
    'FAQ', // Fair Average Quality
    'Premium',
    'Good',
    'Medium',
    'Fair',
  ];

  static const List<String> supplyTypes = [
    'Taxable',
    'Exempt',
    'Mixed',
    'Nil Rated',
    'Non-GST',
  ];
}
