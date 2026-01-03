class ProductModel {
  final int? id;
  final String hsnCode;
  final String productName;
  final String productCategory;
  final double gstRate;

  ProductModel({
    this.id,
    required this.hsnCode,
    required this.productName,
    required this.productCategory,
    required this.gstRate,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'hsn_code': hsnCode,
      'product_name': productName,
      'product_category': productCategory,
      'gst_rate': gstRate,
    };
  }

  static ProductModel fromMap(Map<String, dynamic> map) {
    return ProductModel(
      id: map['id'],
      hsnCode: map['hsn_code'],
      productName: map['product_name'],
      productCategory: map['product_category'],
      gstRate: map['gst_rate'],
    );
  }
}
