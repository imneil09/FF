class Party {
  String id;
  String companyId;
  String name;
  String phone;
  String address;
  String gstin;
  String type; // 'customer', 'vendor'

  Party({
    required this.id, required this.companyId, required this.name,
    required this.phone, required this.address, required this.gstin, required this.type
  });

  Map<String, dynamic> toJson() => {
    'id': id, 'companyId': companyId, 'name': name,
    'phone': phone, 'address': address, 'gstin': gstin, 'type': type
  };

  factory Party.fromJson(Map<String, dynamic> json) => Party(
      id: json['id'], companyId: json['companyId'], name: json['name'],
      phone: json['phone'], address: json['address'], gstin: json['gstin'], type: json['type']
  );
}