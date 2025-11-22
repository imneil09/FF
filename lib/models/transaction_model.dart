class AppTransaction {
  String id;
  String companyId;
  String type; // 'sale' or 'expense'
  double amount;
  String paymentMode; // 'Cash' or 'Bank'
  DateTime date;
  String? partyName;
  String? productId; // Only for sales
  int? quantity;     // Only for sales
  String remarks;

  AppTransaction({
    required this.id,
    required this.companyId,
    required this.type,
    required this.amount,
    required this.paymentMode,
    required this.date,
    this.partyName,
    this.productId,
    this.quantity,
    this.remarks = '',
  });

  Map<String, dynamic> toJson() => {
    'id': id,
    'companyId': companyId,
    'type': type,
    'amount': amount,
    'paymentMode': paymentMode,
    'date': date.toIso8601String(),
    'partyName': partyName,
    'productId': productId,
    'quantity': quantity,
    'remarks': remarks,
  };

  factory AppTransaction.fromJson(Map<String, dynamic> json) => AppTransaction(
    id: json['id'],
    companyId: json['companyId'],
    type: json['type'],
    amount: (json['amount'] ?? 0).toDouble(),
    paymentMode: json['paymentMode'],
    date: DateTime.parse(json['date']),
    partyName: json['partyName'],
    productId: json['productId'],
    quantity: json['quantity'],
    remarks: json['remarks'] ?? '',
  );
}