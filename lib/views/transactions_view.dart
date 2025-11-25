import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import '../controllers/transaction_controller.dart';
import '../controllers/inventory_controller.dart';
import '../controllers/party_controller.dart';
import '../models/product_model.dart';
import '../models/party_model.dart';

class TransactionsView extends StatelessWidget {
  // FIX: Use getters
  TransactionController get tCtrl => Get.find();
  InventoryController get iCtrl => Get.find();
  PartyController get pCtrl => Get.find();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            color: Colors.white,
            child: Row(
              children: [
                Expanded(child: _buildActionButton(
                    "New Sale", Icons.add_shopping_cart, Colors.green, () => _saleDialog()
                )),
                const SizedBox(width: 12),
                Expanded(child: _buildActionButton(
                    "Record Expense", Icons.receipt_long, Colors.red, () => _expenseDialog()
                )),
              ],
            ),
          ),
          Expanded(
            child: Obx(() {
              if (tCtrl.transactions.isEmpty) {
                return Center(
                  child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                    Icon(Icons.history, size: 64, color: Colors.grey.shade300),
                    const SizedBox(height: 16),
                    Text("No transactions yet", style: TextStyle(color: Colors.grey.shade500)),
                  ]),
                );
              }
              return ListView.builder(
                padding: const EdgeInsets.only(top: 8, bottom: 80),
                itemCount: tCtrl.transactions.length,
                itemBuilder: (ctx, i) {
                  final t = tCtrl.transactions[i];
                  final isSale = t.type == 'sale';
                  return Card(
                    elevation: 0,
                    color: Colors.white,
                    margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                    shape: RoundedRectangleBorder(
                        side: BorderSide(color: Colors.grey.shade200),
                        borderRadius: BorderRadius.circular(12)
                    ),
                    child: ListTile(
                      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      leading: CircleAvatar(
                        backgroundColor: isSale ? Colors.green.shade50 : Colors.red.shade50,
                        radius: 24,
                        child: Icon(
                            isSale ? Icons.arrow_outward : Icons.arrow_downward,
                            color: isSale ? Colors.green : Colors.red,
                            size: 20
                        ),
                      ),
                      title: Text(t.remarks, style: const TextStyle(fontWeight: FontWeight.bold)),
                      subtitle: Padding(
                        padding: const EdgeInsets.only(top: 4),
                        child: Row(children: [
                          Icon(Icons.calendar_today, size: 12, color: Colors.grey.shade500),
                          const SizedBox(width: 4),
                          Text(DateFormat('dd MMM, hh:mm a').format(t.date),
                              style: TextStyle(color: Colors.grey.shade600, fontSize: 12)),
                        ]),
                      ),
                      trailing: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Text(
                            "${isSale ? '+' : '-'} ₹${t.amount.toStringAsFixed(0)}",
                            style: TextStyle(
                                fontWeight: FontWeight.w900,
                                fontSize: 16,
                                color: isSale ? Colors.green.shade700 : Colors.red.shade700
                            ),
                          ),
                          Container(
                            margin: const EdgeInsets.only(top: 4),
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                            decoration: BoxDecoration(
                                color: Colors.grey.shade100,
                                borderRadius: BorderRadius.circular(4)
                            ),
                            child: Text(t.paymentMode.toUpperCase(),
                                style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.grey.shade700)),
                          )
                        ],
                      ),
                    ),
                  );
                },
              );
            }),
          )
        ],
      ),
    );
  }

  Widget _buildActionButton(String label, IconData icon, Color color, VoidCallback onTap) {
    return Material(
      color: color.withOpacity(0.1),
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 20),
          child: Column(children: [
            Icon(icon, color: color, size: 28),
            const SizedBox(height: 8),
            Text(label, style: TextStyle(color: color, fontWeight: FontWeight.bold))
          ]),
        ),
      ),
    );
  }

  void _saleDialog() {
    Product? selProd;
    Party? selParty;
    final qtyC = TextEditingController();
    final priceC = TextEditingController();
    String mode = 'Cash';

    Get.defaultDialog(
        title: "New Sale",
        titlePadding: const EdgeInsets.only(top: 20),
        contentPadding: const EdgeInsets.all(20),
        content: SingleChildScrollView(child: Column(children: [
          DropdownButtonFormField<Product>(
            decoration: const InputDecoration(labelText: "Product", prefixIcon: Icon(Icons.inventory_2)),
            items: iCtrl.products.map((p) => DropdownMenuItem(value: p, child: Text(p.name))).toList(),
            onChanged: (v) { selProd = v; priceC.text = v!.estSellPrice.toString(); },
          ),
          const SizedBox(height: 12),
          Row(children: [
            Expanded(child: TextField(controller: qtyC, decoration: const InputDecoration(labelText: "Qty", prefixIcon: Icon(Icons.numbers)), keyboardType: TextInputType.number)),
            const SizedBox(width: 12),
            Expanded(child: TextField(controller: priceC, decoration: const InputDecoration(labelText: "Price", prefixIcon: Icon(Icons.currency_rupee)), keyboardType: TextInputType.number)),
          ]),
          const SizedBox(height: 12),
          DropdownButtonFormField<Party>(
            decoration: const InputDecoration(labelText: "Party (Optional)", prefixIcon: Icon(Icons.person)),
            items: pCtrl.parties.map((p) => DropdownMenuItem(value: p, child: Text(p.name))).toList(),
            onChanged: (v) => selParty = v,
          ),
          const SizedBox(height: 12),
          DropdownButtonFormField<String>(
            decoration: const InputDecoration(labelText: "Mode", prefixIcon: Icon(Icons.payment)),
            value: mode,
            items: ['Cash', 'Bank', 'Credit'].map((e) => DropdownMenuItem(value: e, child: Text(e))).toList(),
            onChanged: (v) => mode = v!,
          ),
        ])),
        confirm: SizedBox(
          width: double.infinity,
          child: ElevatedButton(onPressed: () {
            if(selProd != null && qtyC.text.isNotEmpty) {
              tCtrl.recordSale(
                  product: selProd!,
                  qty: int.parse(qtyC.text),
                  sellPrice: double.parse(priceC.text),
                  paymentMode: mode,
                  partyId: selParty?.id,
                  partyName: selParty?.name
              );
              Get.back();
            }
          }, child: const Text("Confirm Sale")),
        )
    );
  }

  void _expenseDialog() {
    final descC = TextEditingController();
    final amtC = TextEditingController();
    Party? selParty;
    String mode = 'Cash';

    Get.defaultDialog(
        title: "Record Expense",
        titlePadding: const EdgeInsets.only(top: 20),
        contentPadding: const EdgeInsets.all(20),
        content: SingleChildScrollView(child: Column(children: [
          TextField(controller: descC, decoration: const InputDecoration(labelText: "Description", prefixIcon: Icon(Icons.description))),
          const SizedBox(height: 12),
          TextField(controller: amtC, decoration: const InputDecoration(labelText: "Amount", prefixIcon: Icon(Icons.currency_rupee)), keyboardType: TextInputType.number),
          const SizedBox(height: 12),
          DropdownButtonFormField<Party>(
            decoration: const InputDecoration(labelText: "Vendor (Optional)", prefixIcon: Icon(Icons.store)),
            items: pCtrl.parties.map((p) => DropdownMenuItem(value: p, child: Text(p.name))).toList(),
            onChanged: (v) => selParty = v,
          ),
          const SizedBox(height: 12),
          DropdownButtonFormField<String>(
            decoration: const InputDecoration(labelText: "Mode", prefixIcon: Icon(Icons.payment)),
            value: mode,
            items: ['Cash', 'Bank'].map((e) => DropdownMenuItem(value: e, child: Text(e))).toList(),
            onChanged: (v) => mode = v!,
          ),
        ])),
        confirm: SizedBox(
          width: double.infinity,
          child: ElevatedButton(onPressed: () {
            if(descC.text.isNotEmpty) {
              tCtrl.recordExpense(
                  desc: descC.text,
                  amount: double.tryParse(amtC.text) ?? 0,
                  paymentMode: mode,
                  partyId: selParty?.id,
                  partyName: selParty?.name
              );
              Get.back();
            }
          }, child: const Text("Save Expense")),
        )
    );
  }
}