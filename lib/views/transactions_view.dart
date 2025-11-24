import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../controllers/transaction_controller.dart';
import '../controllers/inventory_controller.dart';
import '../controllers/party_controller.dart';
import '../models/product_model.dart';
import '../models/party_model.dart';
import 'package:intl/intl.dart';

class TransactionsView extends StatelessWidget {
  final tCtrl = Get.find<TransactionController>();
  final iCtrl = Get.find<InventoryController>();
  final pCtrl = Get.find<PartyController>();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(children: [
        Padding(
          padding: EdgeInsets.all(8),
          child: Row(children: [
            Expanded(child: ElevatedButton.icon(
              style: ElevatedButton.styleFrom(backgroundColor: Colors.green.shade100),
              icon: Icon(Icons.outbox, color: Colors.green),
              label: Text("PRODUCT OUT (SALE)", style: TextStyle(color: Colors.green)),
              onPressed: () => _saleDialog(),
            )),
            SizedBox(width: 10),
            Expanded(child: ElevatedButton.icon(
              style: ElevatedButton.styleFrom(backgroundColor: Colors.red.shade100),
              icon: Icon(Icons.money_off, color: Colors.red),
              label: Text("EXPENSE", style: TextStyle(color: Colors.red)),
              onPressed: () => _expenseDialog(),
            )),
          ]),
        ),
        Expanded(child: Obx(() => ListView.builder(
          itemCount: tCtrl.transactions.length,
          itemBuilder: (ctx, i) {
            final t = tCtrl.transactions[i];
            return ListTile(
              leading: CircleAvatar(
                backgroundColor: t.type == 'sale' ? Colors.green.shade100 : Colors.red.shade100,
                child: Icon(t.type == 'sale' ? Icons.arrow_upward : Icons.arrow_downward, size: 16),
              ),
              title: Text(t.remarks),
              subtitle: Text("${DateFormat('dd MMM').format(t.date)} • ${t.partyName ?? '-'}"),
              trailing: Column(mainAxisAlignment: MainAxisAlignment.center, crossAxisAlignment: CrossAxisAlignment.end, children: [
                Text("Rs. ${t.amount}", style: TextStyle(fontWeight: FontWeight.bold)),
                Text(t.paymentMode, style: TextStyle(fontSize: 10, color: Colors.grey)),
              ]),
            );
          },
        )))
      ]),
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
        content: SingleChildScrollView(child: Column(children: [
          DropdownButtonFormField<Product>(
            hint: Text("Select Product"),
            items: iCtrl.products.map((p) => DropdownMenuItem(value: p, child: Text(p.name))).toList(),
            onChanged: (v) { selProd = v; priceC.text = v!.estSellPrice.toString(); },
          ),
          TextField(controller: qtyC, decoration: InputDecoration(labelText: "Quantity"), keyboardType: TextInputType.number),
          TextField(controller: priceC, decoration: InputDecoration(labelText: "Final Sell Price"), keyboardType: TextInputType.number),
          DropdownButtonFormField<Party>(
            hint: Text("Select Party (Optional)"),
            items: pCtrl.parties.map((p) => DropdownMenuItem(value: p, child: Text(p.name))).toList(),
            onChanged: (v) => selParty = v,
          ),
          DropdownButtonFormField<String>(
            value: mode,
            items: ['Cash', 'Bank', 'Credit'].map((e) => DropdownMenuItem(value: e, child: Text(e))).toList(),
            onChanged: (v) => mode = v!,
          ),
        ])),
        confirm: ElevatedButton(onPressed: () {
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
        }, child: Text("Confirm Sale"))
    );
  }

  void _expenseDialog() {
    final descC = TextEditingController();
    final amtC = TextEditingController();
    Party? selParty;
    String mode = 'Cash';

    Get.defaultDialog(
        title: "Record Expense",
        content: SingleChildScrollView(child: Column(children: [
          TextField(controller: descC, decoration: InputDecoration(labelText: "Expense Description")),
          TextField(controller: amtC, decoration: InputDecoration(labelText: "Amount"), keyboardType: TextInputType.number),
          DropdownButtonFormField<Party>(
            hint: Text("Select Vendor (Optional)"),
            items: pCtrl.parties.map((p) => DropdownMenuItem(value: p, child: Text(p.name))).toList(),
            onChanged: (v) => selParty = v,
          ),
          DropdownButtonFormField<String>(
            value: mode,
            items: ['Cash', 'Bank'].map((e) => DropdownMenuItem(value: e, child: Text(e))).toList(),
            onChanged: (v) => mode = v!,
          ),
        ])),
        confirm: ElevatedButton(onPressed: () {
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
        }, child: Text("Save Expense"))
    );
  }
}