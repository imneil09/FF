class Company {
  String id;
  String name;
  String gstin;
  String address;
  String phone;
  double openingCashBalance;
  double openingBankBalance;

  Company({
    required this.id,
    required this.name,
    required this.gstin,
    required this.address,
    required this.phone,
    required this.openingCashBalance,
    required this.openingBankBalance,
  });

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'gstin': gstin,
    'address': address,
    'phone': phone,
    'openingCashBalance': openingCashBalance,
    'openingBankBalance': openingBankBalance,
  };

  factory Company.fromJson(Map<String, dynamic> json) => Company(
    id: json['id'],
    name: json['name'],
    gstin: json['gstin'],
    address: json['address'],
    phone: json['phone'],
    openingCashBalance: (json['openingCashBalance'] ?? 0).toDouble(),
    openingBankBalance: (json['openingBankBalance'] ?? 0).toDouble(),
  );
}