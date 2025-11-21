import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:intl/intl.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';

void main() {
  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => FirmProvider()),
      ],
      child: const FirmFlowApp(),
    ),
  );
}

// --- CONSTANTS ---
final inrFormatter = NumberFormat.currency(locale: 'en_IN', symbol: '₹', decimalDigits: 0);
final dateFormatter = DateFormat('dd MMM yyyy');

// --- MODELS ---

class Firm {
  int id;
  String name;
  String address;
  String phone;

  Firm({required this.id, required this.name, this.address = '', this.phone = ''});

  Map<String, dynamic> toJson() => {'id': id, 'name': name, 'address': address, 'phone': phone};
  factory Firm.fromJson(Map<String, dynamic> json) => Firm(
      id: json['id'], name: json['name'], address: json['address'] ?? '', phone: json['phone'] ?? ''
  );
}

class Item {
  int id;
  int firmId;
  String name;
  int qty;
  double buyPrice;
  double sellPrice;

  Item({required this.id, required this.firmId, required this.name, required this.qty, required this.buyPrice, required this.sellPrice});

  Map<String, dynamic> toJson() => {'id': id, 'firmId': firmId, 'name': name, 'qty': qty, 'buyPrice': buyPrice, 'sellPrice': sellPrice};
  factory Item.fromJson(Map<String, dynamic> json) => Item(
      id: json['id'], firmId: json['firmId'], name: json['name'], qty: json['qty'],
      buyPrice: (json['buyPrice'] as num).toDouble(), sellPrice: (json['sellPrice'] as num).toDouble()
  );
}

class Transaction {
  int id;
  int firmId;
  String desc;
  double amount;
  String type; // 'in' (Income) or 'out' (Expense)
  String mode; // 'cash' or 'bank'
  String date;
  int? linkedPartyId;
  int? linkedItemId;

  Transaction({required this.id, required this.firmId, required this.desc, required this.amount, required this.type, required this.mode, required this.date, this.linkedPartyId, this.linkedItemId});

  Map<String, dynamic> toJson() => {
    'id': id, 'firmId': firmId, 'desc': desc, 'amount': amount, 'type': type, 'mode': mode, 'date': date,
    'linkedPartyId': linkedPartyId, 'linkedItemId': linkedItemId
  };
  factory Transaction.fromJson(Map<String, dynamic> json) => Transaction(
      id: json['id'], firmId: json['firmId'], desc: json['desc'], amount: (json['amount'] as num).toDouble(),
      type: json['type'], mode: json['mode'], date: json['date'],
      linkedPartyId: json['linkedPartyId'], linkedItemId: json['linkedItemId']
  );
}

class Party {
  int id;
  int firmId;
  String name;
  String phone;
  String address;
  double openingBalance;

  Party({required this.id, required this.firmId, required this.name, required this.phone, this.address = '', this.openingBalance = 0.0});

  Map<String, dynamic> toJson() => {'id': id, 'firmId': firmId, 'name': name, 'phone': phone, 'address': address, 'openingBalance': openingBalance};
  factory Party.fromJson(Map<String, dynamic> json) => Party(
      id: json['id'], firmId: json['firmId'], name: json['name'], phone: json['phone'],
      address: json['address'] ?? '', openingBalance: (json['openingBalance'] ?? 0.0).toDouble()
  );
}

// --- STATE MANAGEMENT ---

class FirmProvider with ChangeNotifier {
  List<Firm> _firms = [];
  List<Item> _inventory = [];
  List<Transaction> _transactions = [];
  List<Party> _parties = [];
  int _activeFirmId = 0;

  FirmProvider() { _loadData(); }

  // Getters
  List<Firm> get firms => _firms;
  int get activeFirmId => _activeFirmId;
  Firm? get currentFirm => _firms.isEmpty ? null : _firms.firstWhere((f) => f.id == _activeFirmId, orElse: () => _firms.first);
  List<Item> get firmInventory => _inventory.where((i) => i.firmId == _activeFirmId).toList();
  List<Transaction> get firmTransactions => _transactions.where((t) => t.firmId == _activeFirmId).toList();
  List<Party> get firmParties => _parties.where((p) => p.firmId == _activeFirmId).toList();

  double get cashInHand => _calculateBalance('cash');
  double get cashInBank => _calculateBalance('bank');
  double get stockValue => firmInventory.fold(0, (sum, i) => sum + (i.qty * i.buyPrice));

  double _calculateBalance(String mode) {
    return firmTransactions.where((t) => t.mode == mode)
        .fold(0.0, (sum, t) => t.type == 'in' ? sum + t.amount : sum - t.amount);
  }

  // --- ACTIONS ---

  // Firm
  void addFirm(String name, String address, String phone) {
    final newFirm = Firm(id: DateTime.now().millisecondsSinceEpoch, name: name, address: address, phone: phone);
    _firms.add(newFirm);
    _activeFirmId = newFirm.id;
    _saveData();
  }

  void editFirm(int id, String name, String address, String phone) {
    final index = _firms.indexWhere((f) => f.id == id);
    if (index != -1) {
      _firms[index].name = name;
      _firms[index].address = address;
      _firms[index].phone = phone;
      _saveData();
    }
  }

  void deleteFirm(int id) {
    _firms.removeWhere((f) => f.id == id);
    if (_firms.isNotEmpty) _activeFirmId = _firms.first.id;
    else _activeFirmId = 0;
    _saveData();
  }

  void setActiveFirm(int id) {
    _activeFirmId = id;
    _saveData();
  }

  // Stock (Auto-Transaction Logic)
  void addStock(String name, int qty, double buyPrice, double sellPrice, String paymentMode, int? existingItemId) {
    int itemId = existingItemId ?? DateTime.now().millisecondsSinceEpoch;

    // 1. Update Inventory
    if (existingItemId != null) {
      final index = _inventory.indexWhere((i) => i.id == existingItemId);
      if (index != -1) {
        _inventory[index].qty += qty;
        _inventory[index].buyPrice = buyPrice;
        _inventory[index].sellPrice = sellPrice;
      }
    } else {
      _inventory.add(Item(id: itemId, firmId: _activeFirmId, name: name, qty: qty, buyPrice: buyPrice, sellPrice: sellPrice));
    }

    // 2. Create Auto-Transaction (Expense)
    double totalCost = qty * buyPrice;
    if (totalCost > 0) {
      addTransaction(Transaction(
          id: DateTime.now().millisecondsSinceEpoch + 1,
          firmId: _activeFirmId,
          desc: "Stock In: $name x $qty",
          amount: totalCost,
          type: 'out',
          mode: paymentMode,
          date: DateTime.now().toIso8601String(),
          linkedItemId: itemId
      ));
    }
    _saveData();
  }

  void sellStock(int itemId, int qty, double soldAtPrice, String paymentMode, int? partyId) {
    final index = _inventory.indexWhere((i) => i.id == itemId);
    if (index == -1) return;

    // 1. Decrease Inventory
    _inventory[index].qty = (_inventory[index].qty - qty).clamp(0, 999999);

    // 2. Create Auto-Transaction (Income)
    double totalSale = qty * soldAtPrice;
    addTransaction(Transaction(
        id: DateTime.now().millisecondsSinceEpoch,
        firmId: _activeFirmId,
        desc: "Sale: ${_inventory[index].name} x $qty",
        amount: totalSale,
        type: 'in',
        mode: paymentMode,
        date: DateTime.now().toIso8601String(),
        linkedItemId: itemId,
        linkedPartyId: partyId
    ));
    _saveData();
  }

  void deleteItem(int id) {
    _inventory.removeWhere((i) => i.id == id);
    _saveData();
  }

  // Transaction
  void addTransaction(Transaction t) {
    _transactions.insert(0, t);
    _saveData();
  }

  void editTransaction(Transaction t) {
    final index = _transactions.indexWhere((tx) => tx.id == t.id);
    if (index != -1) {
      _transactions[index] = t;
      _saveData();
    }
  }

  void deleteTransaction(int id) {
    _transactions.removeWhere((t) => t.id == id);
    _saveData();
  }

  // Party
  void addParty(Party p) {
    _parties.add(p);
    _saveData();
  }

  void editParty(Party p) {
    final index = _parties.indexWhere((pa) => pa.id == p.id);
    if (index != -1) {
      _parties[index] = p;
      _saveData();
    }
  }

  void deleteParty(int id) {
    _parties.removeWhere((p) => p.id == id);
    _saveData();
  }

  // Storage
  Future<void> _loadData() async {
    final prefs = await SharedPreferences.getInstance();

    final firmsStr = prefs.getString('firms');
    if (firmsStr != null) _firms = (json.decode(firmsStr) as List).map((i) => Firm.fromJson(i)).toList();
    if (_firms.isEmpty) _firms.add(Firm(id: 1, name: "My Business", address: "City, India"));

    _activeFirmId = prefs.getInt('activeFirmId') ?? _firms.first.id;

    final invStr = prefs.getString('inventory');
    if (invStr != null) _inventory = (json.decode(invStr) as List).map((i) => Item.fromJson(i)).toList();

    final txStr = prefs.getString('transactions');
    if (txStr != null) _transactions = (json.decode(txStr) as List).map((i) => Transaction.fromJson(i)).toList();

    final partyStr = prefs.getString('parties');
    if (partyStr != null) _parties = (json.decode(partyStr) as List).map((i) => Party.fromJson(i)).toList();

    notifyListeners();
  }

  Future<void> _saveData() async {
    final prefs = await SharedPreferences.getInstance();
    prefs.setString('firms', json.encode(_firms));
    prefs.setInt('activeFirmId', _activeFirmId);
    prefs.setString('inventory', json.encode(_inventory));
    prefs.setString('transactions', json.encode(_transactions));
    prefs.setString('parties', json.encode(_parties));
    notifyListeners();
  }
}

// --- PDF GENERATOR ---

class PdfGenerator {
  static Future<void> generateInvoice(Firm firm, Party party, List<Transaction> selectedTxs) async {
    final pdf = pw.Document();
    // Standard fonts for compatibility
    final font = await PdfGoogleFonts.nunitoRegular();
    final boldFont = await PdfGoogleFonts.nunitoBold();

    final totalAmount = selectedTxs.fold(0.0, (sum, t) => sum + t.amount);

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        theme: pw.ThemeData.withFont(base: font, bold: boldFont),
        build: (context) => [
          // Header / Letterhead
          pw.Column(
              children: [
                pw.Row(
                    mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                    children: [
                      pw.Column(crossAxisAlignment: pw.CrossAxisAlignment.start, children: [
                        pw.Text(firm.name, style: pw.TextStyle(fontSize: 20, fontWeight: pw.FontWeight.bold, color: PdfColors.blue800)),
                        pw.Text(firm.address),
                        pw.Text("Ph: ${firm.phone}"),
                      ]),
                      pw.Container(
                        padding: const pw.EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        decoration: pw.BoxDecoration(border: pw.Border.all(color: PdfColors.blue800), borderRadius: pw.BorderRadius.circular(4)),
                        child: pw.Text("INVOICE", style: pw.TextStyle(fontWeight: pw.FontWeight.bold, color: PdfColors.blue800)),
                      )
                    ]
                ),
                pw.SizedBox(height: 10),
                pw.Divider(color: PdfColors.blue800),
              ]
          ),
          pw.SizedBox(height: 20),

          // Bill To
          pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
            children: [
              pw.Column(crossAxisAlignment: pw.CrossAxisAlignment.start, children: [
                pw.Text("Bill To:", style: pw.TextStyle(fontWeight: pw.FontWeight.bold, color: PdfColors.grey700)),
                pw.Text(party.name, style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 16)),
                pw.Text(party.phone),
                pw.Text(party.address),
              ]),
              pw.Column(crossAxisAlignment: pw.CrossAxisAlignment.end, children: [
                pw.Text("Date: ${DateFormat('dd MMM yyyy').format(DateTime.now())}"),
              ]),
            ],
          ),
          pw.SizedBox(height: 30),

          // Table
          pw.Table.fromTextArray(
            headerDecoration: const pw.BoxDecoration(color: PdfColors.blue50),
            headerStyle: pw.TextStyle(fontWeight: pw.FontWeight.bold, color: PdfColors.blue900),
            cellAlignment: pw.Alignment.centerLeft,
            headers: ['Date', 'Description', 'Type', 'Amount'],
            data: selectedTxs.map((t) => [
              DateFormat('dd/MM/yyyy').format(DateTime.parse(t.date)),
              t.desc,
              t.type == 'in' ? 'Credit' : 'Debit',
              inrFormatter.format(t.amount)
            ]).toList(),
          ),
          pw.SizedBox(height: 10),
          pw.Divider(),

          // Total
          pw.Align(
              alignment: pw.Alignment.centerRight,
              child: pw.Row(
                  mainAxisSize: pw.MainAxisSize.min,
                  children: [
                    pw.Text("Total: ", style: pw.TextStyle(fontSize: 14, fontWeight: pw.FontWeight.bold)),
                    pw.Text(inrFormatter.format(totalAmount), style: pw.TextStyle(fontSize: 18, fontWeight: pw.FontWeight.bold, color: PdfColors.blue800)),
                  ]
              )
          ),
          pw.Spacer(),

          // Footer
          pw.Divider(),
          pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
              children: [
                pw.Text("Generated by FirmFlow", style: const pw.TextStyle(fontSize: 10, color: PdfColors.grey)),
                pw.Text("Authorized Signature", style: const pw.TextStyle(fontSize: 12)),
              ]
          )
        ],
      ),
    );

    await Printing.layoutPdf(onLayout: (format) async => pdf.save());
  }
}

// --- MAIN UI SCREENS ---

class FirmFlowApp extends StatelessWidget {
  const FirmFlowApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'FirmFlow Pro',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.indigo),
        useMaterial3: true,
      ),
      home: const MainScreen(),
    );
  }
}

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});
  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int _selectedIndex = 0;
  final List<Widget> _screens = [const DashboardScreen(), const InventoryScreen(), const FinanceScreen(), const PartiesScreen()];

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<FirmProvider>(context);
    final firm = provider.currentFirm;

    return Scaffold(
      appBar: AppBar(
        title: GestureDetector(
          onTap: () => _manageFirm(context),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(firm?.name ?? "FirmFlow", style: const TextStyle(fontWeight: FontWeight.bold)),
            if (firm != null) Text(firm!.address.isEmpty ? "Tap to manage firm" : firm!.address, style: const TextStyle(fontSize: 10)),
          ]),
        ),
        actions: [
          PopupMenuButton<int>(
            icon: const Icon(Icons.business),
            onSelected: (id) => id == -1 ? _addFirm(context) : provider.setActiveFirm(id),
            itemBuilder: (ctx) => [
              ...provider.firms.map((f) => PopupMenuItem(value: f.id, child: Text(f.name))),
              const PopupMenuDivider(),
              const PopupMenuItem(value: -1, child: Row(children: [Icon(Icons.add, size: 18), Text(" Add Firm")])),
            ],
          )
        ],
      ),
      body: _screens[_selectedIndex],
      bottomNavigationBar: NavigationBar(
        selectedIndex: _selectedIndex,
        onDestinationSelected: (i) => setState(() => _selectedIndex = i),
        destinations: const [
          NavigationDestination(icon: Icon(Icons.dashboard_outlined), selectedIcon: Icon(Icons.dashboard), label: 'Home'),
          NavigationDestination(icon: Icon(Icons.inventory_2_outlined), selectedIcon: Icon(Icons.inventory_2), label: 'Stock'),
          NavigationDestination(icon: Icon(Icons.account_balance_wallet_outlined), selectedIcon: Icon(Icons.account_balance_wallet), label: 'Finance'),
          NavigationDestination(icon: Icon(Icons.people_outline), selectedIcon: Icon(Icons.people), label: 'Parties'),
        ],
      ),
    );
  }

  void _addFirm(BuildContext context) {
    final c1 = TextEditingController(), c2 = TextEditingController(), c3 = TextEditingController();
    showDialog(context: context, builder: (ctx) => AlertDialog(
      title: const Text("New Firm"),
      content: Column(mainAxisSize: MainAxisSize.min, children: [
        TextField(controller: c1, decoration: const InputDecoration(labelText: "Name")),
        TextField(controller: c2, decoration: const InputDecoration(labelText: "Address")),
        TextField(controller: c3, decoration: const InputDecoration(labelText: "Phone")),
      ]),
      actions: [
        TextButton(onPressed: () => Navigator.pop(ctx), child: const Text("Cancel")),
        FilledButton(onPressed: () {
          if (c1.text.isNotEmpty) Provider.of<FirmProvider>(context, listen: false).addFirm(c1.text, c2.text, c3.text);
          Navigator.pop(ctx);
        }, child: const Text("Create")),
      ],
    ));
  }

  void _manageFirm(BuildContext context) {
    final p = Provider.of<FirmProvider>(context, listen: false);
    final f = p.currentFirm;
    if (f == null) return;
    final c1 = TextEditingController(text: f.name), c2 = TextEditingController(text: f.address), c3 = TextEditingController(text: f.phone);
    showDialog(context: context, builder: (ctx) => AlertDialog(
      title: const Text("Edit Firm"),
      content: Column(mainAxisSize: MainAxisSize.min, children: [
        TextField(controller: c1, decoration: const InputDecoration(labelText: "Name")),
        TextField(controller: c2, decoration: const InputDecoration(labelText: "Address")),
        TextField(controller: c3, decoration: const InputDecoration(labelText: "Phone")),
      ]),
      actions: [
        TextButton(onPressed: () { p.deleteFirm(f.id); Navigator.pop(ctx); }, child: const Text("Delete", style: TextStyle(color: Colors.red))),
        FilledButton(onPressed: () {
          p.editFirm(f.id, c1.text, c2.text, c3.text); Navigator.pop(ctx);
        }, child: const Text("Save")),
      ],
    ));
  }
}

// --- 1. DASHBOARD ---
class DashboardScreen extends StatelessWidget {
  const DashboardScreen({super.key});
  @override
  Widget build(BuildContext context) {
    final p = Provider.of<FirmProvider>(context);
    return ListView(padding: const EdgeInsets.all(16), children: [
      Row(children: [
        Expanded(child: _StatCard(title: "Cash Box", value: inrFormatter.format(p.cashInHand), color: Colors.green, icon: Icons.money)),
        const SizedBox(width: 10),
        Expanded(child: _StatCard(title: "Bank", value: inrFormatter.format(p.cashInBank), color: Colors.blue, icon: Icons.account_balance)),
      ]),
      const SizedBox(height: 10),
      _StatCard(title: "Total Stock Value", value: inrFormatter.format(p.stockValue), color: Colors.orange, icon: Icons.inventory),
      const SizedBox(height: 20),
      const Text("Recent Activity", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
      ...p.firmTransactions.take(5).map((t) => ListTile(
        leading: Icon(t.type == 'in' ? Icons.arrow_downward : Icons.arrow_upward, color: t.type == 'in' ? Colors.green : Colors.red),
        title: Text(t.desc),
        subtitle: Text(dateFormatter.format(DateTime.parse(t.date))),
        trailing: Text(inrFormatter.format(t.amount), style: TextStyle(fontWeight: FontWeight.bold, color: t.type == 'in' ? Colors.green : Colors.red)),
      )),
    ]);
  }
}
class _StatCard extends StatelessWidget {
  final String title, value; final MaterialColor color; final IconData icon;
  const _StatCard({required this.title, required this.value, required this.color, required this.icon});
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: color.shade50, borderRadius: BorderRadius.circular(12), border: Border.all(color: color.shade100)),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Icon(icon, color: color), const SizedBox(height: 8),
        Text(title, style: TextStyle(color: color.shade700)),
        Text(value, style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: color.shade900)),
      ]),
    );
  }
}

// --- 2. STOCK ---
class InventoryScreen extends StatelessWidget {
  const InventoryScreen({super.key});
  @override
  Widget build(BuildContext context) {
    final p = Provider.of<FirmProvider>(context);
    return Scaffold(
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _stockInDialog(context, null),
        label: const Text("Stock In"), icon: const Icon(Icons.add_shopping_cart),
      ),
      body: ListView.builder(
        itemCount: p.firmInventory.length,
        itemBuilder: (ctx, i) {
          final item = p.firmInventory[i];
          return Card(
            margin: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
            child: ListTile(
              title: Text(item.name, style: const TextStyle(fontWeight: FontWeight.bold)),
              subtitle: Text("Qty: ${item.qty} | Sell: ${inrFormatter.format(item.sellPrice)}"),
              trailing: Row(mainAxisSize: MainAxisSize.min, children: [
                IconButton(icon: const Icon(Icons.sell, color: Colors.indigo), onPressed: () => _sellDialog(context, item)),
                PopupMenuButton(onSelected: (v) {
                  if (v == 'edit') _stockInDialog(context, item);
                  if (v == 'del') p.deleteItem(item.id);
                }, itemBuilder: (c) => [
                  const PopupMenuItem(value: 'edit', child: Text("Add More / Edit")),
                  const PopupMenuItem(value: 'del', child: Text("Delete")),
                ])
              ]),
            ),
          );
        },
      ),
    );
  }

  void _stockInDialog(BuildContext context, Item? item) {
    final nameC = TextEditingController(text: item?.name), qtyC = TextEditingController(), buyC = TextEditingController(text: item?.buyPrice.toString()), sellC = TextEditingController(text: item?.sellPrice.toString());
    String mode = 'cash';
    showDialog(context: context, builder: (ctx) => StatefulBuilder(builder: (context, setState) => AlertDialog(
      title: Text(item == null ? "New Stock In" : "Update Stock"),
      content: SingleChildScrollView(child: Column(mainAxisSize: MainAxisSize.min, children: [
        if (item == null) TextField(controller: nameC, decoration: const InputDecoration(labelText: "Item Name")),
        TextField(controller: qtyC, decoration: const InputDecoration(labelText: "Quantity To Add"), keyboardType: TextInputType.number),
        TextField(controller: buyC, decoration: const InputDecoration(labelText: "Buy Price (Per Unit)"), keyboardType: TextInputType.number),
        TextField(controller: sellC, decoration: const InputDecoration(labelText: "Sell Price (Per Unit)"), keyboardType: TextInputType.number),
        const SizedBox(height: 10), const Text("Payment From:"),
        Row(children: [
          Expanded(child: RadioListTile(value: 'cash', groupValue: mode, onChanged: (v) => setState(() => mode = v!), title: const Text("Cash"))),
          Expanded(child: RadioListTile(value: 'bank', groupValue: mode, onChanged: (v) => setState(() => mode = v!), title: const Text("Bank"))),
        ]),
        const Text("This creates an Expense Transaction automatically.", style: TextStyle(fontSize: 10, color: Colors.grey)),
      ])),
      actions: [
        TextButton(onPressed: () => Navigator.pop(ctx), child: const Text("Cancel")),
        FilledButton(onPressed: () {
          Provider.of<FirmProvider>(context, listen: false).addStock(nameC.text, int.tryParse(qtyC.text)??0, double.tryParse(buyC.text)??0, double.tryParse(sellC.text)??0, mode, item?.id);
          Navigator.pop(ctx);
        }, child: const Text("Stock In")),
      ],
    )));
  }

  void _sellDialog(BuildContext context, Item item) {
    final qtyC = TextEditingController(), priceC = TextEditingController(text: item.sellPrice.toString());
    String mode = 'cash';
    int? partyId;
    showDialog(context: context, builder: (ctx) => StatefulBuilder(builder: (context, setState) => AlertDialog(
      title: Text("Sell ${item.name}"),
      content: SingleChildScrollView(child: Column(mainAxisSize: MainAxisSize.min, children: [
        Text("Current Stock: ${item.qty}"),
        TextField(controller: qtyC, decoration: const InputDecoration(labelText: "Qty Sold"), keyboardType: TextInputType.number),
        TextField(controller: priceC, decoration: const InputDecoration(labelText: "Total Sale Price"), keyboardType: TextInputType.number),
        DropdownButtonFormField<int>(
          decoration: const InputDecoration(labelText: "Select Party (Optional)"),
          items: Provider.of<FirmProvider>(context, listen: false).firmParties.map((p) => DropdownMenuItem(value: p.id, child: Text(p.name))).toList(),
          onChanged: (v) => partyId = v,
        ),
        Row(children: [
          Expanded(child: RadioListTile(value: 'cash', groupValue: mode, onChanged: (v) => setState(() => mode = v!), title: const Text("Cash"))),
          Expanded(child: RadioListTile(value: 'bank', groupValue: mode, onChanged: (v) => setState(() => mode = v!), title: const Text("Bank"))),
        ]),
      ])),
      actions: [
        FilledButton(onPressed: () {
          Provider.of<FirmProvider>(context, listen: false).sellStock(item.id, int.tryParse(qtyC.text)??0, double.tryParse(priceC.text)??0, mode, partyId);
          Navigator.pop(ctx);
        }, child: const Text("Sell")),
      ],
    )));
  }
}

// --- 3. FINANCE ---
class FinanceScreen extends StatelessWidget {
  const FinanceScreen({super.key});
  @override
  Widget build(BuildContext context) {
    final p = Provider.of<FirmProvider>(context);
    return Scaffold(
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _txDialog(context, null),
        label: const Text("Add Entry"), icon: const Icon(Icons.post_add),
      ),
      body: ListView.builder(
        itemCount: p.firmTransactions.length,
        itemBuilder: (ctx, i) {
          final t = p.firmTransactions[i];
          return ListTile(
            leading: CircleAvatar(backgroundColor: t.type == 'in' ? Colors.green[100] : Colors.red[100], child: Icon(t.type == 'in' ? Icons.arrow_downward : Icons.arrow_upward, color: t.type == 'in' ? Colors.green : Colors.red)),
            title: Text(t.desc), subtitle: Text("${t.mode.toUpperCase()} • ${dateFormatter.format(DateTime.parse(t.date))}"),
            trailing: Row(mainAxisSize: MainAxisSize.min, children: [
              Text(inrFormatter.format(t.amount)),
              PopupMenuButton(onSelected: (v) {
                if (v == 'edit') _txDialog(context, t);
                if (v == 'del') p.deleteTransaction(t.id);
              }, itemBuilder: (c) => [const PopupMenuItem(value: 'edit', child: Text("Edit")), const PopupMenuItem(value: 'del', child: Text("Delete"))])
            ]),
          );
        },
      ),
    );
  }

  void _txDialog(BuildContext context, Transaction? t) {
    final descC = TextEditingController(text: t?.desc), amtC = TextEditingController(text: t?.amount.toString());
    String type = t?.type ?? 'in', mode = t?.mode ?? 'cash';
    showDialog(context: context, builder: (ctx) => StatefulBuilder(builder: (context, setState) => AlertDialog(
      title: Text(t == null ? "New Transaction" : "Edit Transaction"),
      content: Column(mainAxisSize: MainAxisSize.min, children: [
        TextField(controller: descC, decoration: const InputDecoration(labelText: "Description")),
        TextField(controller: amtC, decoration: const InputDecoration(labelText: "Amount"), keyboardType: TextInputType.number),
        Row(children: [
          Expanded(child: ChoiceChip(label: const Text("Income"), selected: type == 'in', onSelected: (b) => setState(() => type = 'in'))),
          const SizedBox(width: 5),
          Expanded(child: ChoiceChip(label: const Text("Expense"), selected: type == 'out', onSelected: (b) => setState(() => type = 'out'))),
        ]),
        Row(children: [
          Expanded(child: RadioListTile(value: 'cash', groupValue: mode, onChanged: (v) => setState(() => mode = v!), title: const Text("Cash"))),
          Expanded(child: RadioListTile(value: 'bank', groupValue: mode, onChanged: (v) => setState(() => mode = v!), title: const Text("Bank"))),
        ]),
      ]),
      actions: [
        FilledButton(onPressed: () {
          final tx = Transaction(id: t?.id ?? DateTime.now().millisecondsSinceEpoch, firmId: Provider.of<FirmProvider>(context, listen: false).activeFirmId, desc: descC.text, amount: double.tryParse(amtC.text)??0, type: type, mode: mode, date: DateTime.now().toIso8601String());
          if (t == null) Provider.of<FirmProvider>(context, listen: false).addTransaction(tx);
          else Provider.of<FirmProvider>(context, listen: false).editTransaction(tx);
          Navigator.pop(ctx);
        }, child: const Text("Save")),
      ],
    )));
  }
}

// --- 4. PARTIES ---
class PartiesScreen extends StatelessWidget {
  const PartiesScreen({super.key});
  @override
  Widget build(BuildContext context) {
    final p = Provider.of<FirmProvider>(context);
    return Scaffold(
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _partyDialog(context, null),
        label: const Text("Add Party"), icon: const Icon(Icons.person_add),
      ),
      body: ListView.builder(
        itemCount: p.firmParties.length,
        itemBuilder: (ctx, i) {
          final party = p.firmParties[i];
          return Card(
            child: ListTile(
              title: Text(party.name, style: const TextStyle(fontWeight: FontWeight.bold)),
              subtitle: Text(party.phone),
              trailing: Row(mainAxisSize: MainAxisSize.min, children: [
                const Icon(Icons.chevron_right),
                PopupMenuButton(onSelected: (v) {
                  if (v == 'edit') _partyDialog(context, party);
                  if (v == 'del') p.deleteParty(party.id);
                }, itemBuilder: (c) => [const PopupMenuItem(value: 'edit', child: Text("Edit")), const PopupMenuItem(value: 'del', child: Text("Delete"))])
              ]),
              onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => PartyDetailScreen(party: party))),
            ),
          );
        },
      ),
    );
  }

  void _partyDialog(BuildContext context, Party? p) {
    final nC = TextEditingController(text: p?.name), phC = TextEditingController(text: p?.phone), aC = TextEditingController(text: p?.address), oC = TextEditingController(text: p?.openingBalance.toString());
    showDialog(context: context, builder: (ctx) => AlertDialog(
      title: Text(p == null ? "Add Party" : "Edit Party"),
      content: SingleChildScrollView(child: Column(mainAxisSize: MainAxisSize.min, children: [
        TextField(controller: nC, decoration: const InputDecoration(labelText: "Name")),
        TextField(controller: phC, decoration: const InputDecoration(labelText: "Phone")),
        TextField(controller: aC, decoration: const InputDecoration(labelText: "Address")),
        TextField(controller: oC, decoration: const InputDecoration(labelText: "Opening Balance (+ Receive / - Pay)"), keyboardType: TextInputType.number),
      ])),
      actions: [
        FilledButton(onPressed: () {
          final party = Party(id: p?.id ?? DateTime.now().millisecondsSinceEpoch, firmId: Provider.of<FirmProvider>(context, listen: false).activeFirmId, name: nC.text, phone: phC.text, address: aC.text, openingBalance: double.tryParse(oC.text)??0);
          if (p == null) Provider.of<FirmProvider>(context, listen: false).addParty(party);
          else Provider.of<FirmProvider>(context, listen: false).editParty(party);
          Navigator.pop(ctx);
        }, child: const Text("Save")),
      ],
    ));
  }
}

class PartyDetailScreen extends StatefulWidget {
  final Party party;
  const PartyDetailScreen({super.key, required this.party});
  @override
  State<PartyDetailScreen> createState() => _PartyDetailScreenState();
}

class _PartyDetailScreenState extends State<PartyDetailScreen> {
  Set<int> selectedTx = {};

  @override
  Widget build(BuildContext context) {
    final p = Provider.of<FirmProvider>(context);
    final txs = p.firmTransactions.where((t) => t.linkedPartyId == widget.party.id).toList();

    return Scaffold(
      appBar: AppBar(title: Text(widget.party.name), actions: [
        if (selectedTx.isNotEmpty) IconButton(icon: const Icon(Icons.picture_as_pdf), onPressed: () {
          final list = txs.where((t) => selectedTx.contains(t.id)).toList();
          PdfGenerator.generateInvoice(p.currentFirm!, widget.party, list);
        })
      ]),
      body: Column(children: [
        Padding(padding: const EdgeInsets.all(16), child: Text("Opening Bal: ${inrFormatter.format(widget.party.openingBalance)}", style: const TextStyle(fontWeight: FontWeight.bold))),
        const Divider(),
        Container(color: Colors.blue[50], padding: const EdgeInsets.all(8), width: double.infinity, child: const Text("Select transactions to generate Invoice", textAlign: TextAlign.center, style: TextStyle(color: Colors.blue))),
        Expanded(child: ListView.builder(
          itemCount: txs.length,
          itemBuilder: (ctx, i) {
            final t = txs[i];
            return CheckboxListTile(
              value: selectedTx.contains(t.id),
              onChanged: (v) => setState(() => v! ? selectedTx.add(t.id) : selectedTx.remove(t.id)),
              title: Text(t.desc),
              subtitle: Text(dateFormatter.format(DateTime.parse(t.date))),
              secondary: Text(inrFormatter.format(t.amount), style: TextStyle(color: t.type == 'in' ? Colors.green : Colors.red, fontWeight: FontWeight.bold)),
            );
          },
        ))
      ]),
    );
  }
}