class AppTransaction {
  String id;
  String companyId;
  String type; // 'sale', 'expense'
  double amount;
  String paymentMode; // 'Cash', 'Bank', 'Credit'
  DateTime date;

  // Sales Specific
  String? productId;
  String? productName;
  int? quantity;
  double? buyPriceAtTime; // To lock profit calculation

  // Common
  String? partyId;
  String? partyName;
  String remarks;

  AppTransaction({
    required this.id, required this.companyId, required this.type,
    required this.amount, required this.paymentMode, required this.date,
    this.productId, this.productName, this.quantity, this.buyPriceAtTime,
    this.partyId, this.partyName, this.remarks = '',
  });

  Map<String, dynamic> toJson() => {
    'id': id, 'companyId': companyId, 'type': type,
    'amount': amount, 'paymentMode': paymentMode, 'date': date.toIso8601String(),
    'productId': productId, 'productName': productName, 'quantity': quantity,
    'buyPriceAtTime': buyPriceAtTime,
    'partyId': partyId, 'partyName': partyName, 'remarks': remarks,
  };

  factory AppTransaction.fromJson(Map<String, dynamic> json) => AppTransaction(
    id: json['id'], companyId: json['companyId'], type: json['type'],
    amount: (json['amount'] ?? 0).toDouble(), paymentMode: json['paymentMode'],
    date: DateTime.parse(json['date']),
    productId: json['productId'], productName: json['productName'],
    quantity: json['quantity'],
    buyPriceAtTime: (json['buyPriceAtTime'] ?? 0).toDouble(),
    partyId: json['partyId'], partyName: json['partyName'], remarks: json['remarks'] ?? '',
  );
}