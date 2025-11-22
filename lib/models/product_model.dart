class Product {
  String id;
  String companyId;
  String name;
  String hsn;
  double estSellPrice;
  double buyPrice;
  int currentStock;

  Product({
    required this.id,
    required this.companyId,
    required this.name,
    required this.hsn,
    required this.estSellPrice,
    required this.buyPrice,
    required this.currentStock,
  });

  Map<String, dynamic> toJson() => {
    'id': id,
    'companyId': companyId,
    'name': name,
    'hsn': hsn,
    'estSellPrice': estSellPrice,
    'buyPrice': buyPrice,
    'currentStock': currentStock,
  };

  factory Product.fromJson(Map<String, dynamic> json) => Product(
    id: json['id'],
    companyId: json['companyId'],
    name: json['name'],
    hsn: json['hsn'],
    estSellPrice: (json['estSellPrice'] ?? 0).toDouble(),
    buyPrice: (json['buyPrice'] ?? 0).toDouble(),
    currentStock: json['currentStock'] ?? 0,
  );
}