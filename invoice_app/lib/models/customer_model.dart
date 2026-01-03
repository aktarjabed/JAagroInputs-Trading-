class CustomerModel {
  final String id;
  final String buyerName;
  final String gstin;
  final String pan;
  final String state;
  final String buyerType;
  final String contactPerson;
  final String phone;
  final String email;
  final String address;
  final double creditLimit;
  final double outstandingBalance;
  final DateTime createdAt;
  final DateTime updatedAt;

  CustomerModel({
    required this.id,
    required this.buyerName,
    required this.gstin,
    required this.pan,
    required this.state,
    required this.buyerType,
    required this.contactPerson,
    required this.phone,
    required this.email,
    required this.address,
    this.creditLimit = 0.0,
    this.outstandingBalance = 0.0,
    required this.createdAt,
    required this.updatedAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'buyer_name': buyerName,
      'gstin': gstin,
      'pan': pan,
      'state': state,
      'buyer_type': buyerType,
      'contact_person': contactPerson,
      'phone': phone,
      'email': email,
      'address': address,
      'credit_limit': creditLimit,
      'outstanding_balance': outstandingBalance,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  static CustomerModel fromMap(Map<String, dynamic> map) {
    return CustomerModel(
      id: map['id'],
      buyerName: map['buyer_name'],
      gstin: map['gstin'],
      pan: map['pan'],
      state: map['state'],
      buyerType: map['buyer_type'],
      contactPerson: map['contact_person'],
      phone: map['phone'],
      email: map['email'],
      address: map['address'],
      creditLimit: map['credit_limit'] ?? 0.0,
      outstandingBalance: map['outstanding_balance'] ?? 0.0,
      createdAt: DateTime.parse(map['created_at']),
      updatedAt: DateTime.parse(map['updated_at']),
    );
  }
}
