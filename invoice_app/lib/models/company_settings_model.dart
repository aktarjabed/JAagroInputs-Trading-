class CompanySettingsModel {
  final int? id;
  final String companyName;
  final String gstin;
  final String pan;
  final String address;
  final String city;
  final String state;
  final String pincode;
  final String phone;
  final String email;
  final String bankName;
  final String bankAccountNumber;
  final String bankIFSC;

  CompanySettingsModel({
    this.id,
    required this.companyName,
    required this.gstin,
    required this.pan,
    required this.address,
    required this.city,
    required this.state,
    required this.pincode,
    required this.phone,
    required this.email,
    required this.bankName,
    required this.bankAccountNumber,
    required this.bankIFSC,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'company_name': companyName,
      'gstin': gstin,
      'pan': pan,
      'address': address,
      'city': city,
      'state': state,
      'pincode': pincode,
      'phone': phone,
      'email': email,
      'bank_name': bankName,
      'bank_account_number': bankAccountNumber,
      'bank_ifsc': bankIFSC,
    };
  }

  static CompanySettingsModel fromMap(Map<String, dynamic> map) {
    return CompanySettingsModel(
      id: map['id'],
      companyName: map['company_name'],
      gstin: map['gstin'],
      pan: map['pan'],
      address: map['address'],
      city: map['city'],
      state: map['state'],
      pincode: map['pincode'],
      phone: map['phone'],
      email: map['email'],
      bank_name: map['bank_name'],
      bank_account_number: map['bank_account_number'],
      bank_ifsc: map['bank_ifsc'],
    );
  }
}
