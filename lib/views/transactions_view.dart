import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../controllers/transaction_controller.dart';
import '../controllers/inventory_controller.dart';
import '../models/product_model.dart';

class TransactionsView extends StatelessWidget {
  const TransactionsView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Row(
              children: [
                Expanded(child: ElevatedButton.icon(
                  icon: Icon(Icons.shopping_cart_checkout),
                  label: Text("PRODUCT OUT (SALE)"),
                  style: ElevatedButton.styleFrom(backgroundColor: Colors.green.shade100),
                  onPressed: () => _showSaleDialog(context),
                )),
                SizedBox(width: 10),
                Expanded(child: ElevatedButton.icon(
                  icon: Icon(Icons.receipt),
                  label: Text("EXPENSE"),
                  style: ElevatedButton.styleFrom(backgroundColor: Colors.red.shade100),
                  onPressed: () => _showExpenseDialog(context),
                )),
              ],
            ),
          ),
          Expanded(child: _buildTransactionList()),
        ],
      ),
    );
  }

  Widget _buildTransactionList() {
    final txCtrl = Get.find<TransactionController>();
    return Obx(() => ListView.builder(
      itemCount: txCtrl.transactions.length,
      itemBuilder: (context, index) {
        final tx = txCtrl.transactions[index];
        return ListTile(
          leading: Icon(
              tx.type == 'sale' ? Icons.arrow_circle_up : Icons.arrow_circle_down,
              color: tx.type == 'sale' ? Colors.green : Colors.red
          ),
          title: Text(tx.remarks),
          subtitle: Text(tx.paymentMode),
          trailing: Text(
              "₹ ${tx.amount}",
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)
          ),
        );
      },
    ));
  }

  void _showSaleDialog(BuildContext context) {
    final invCtrl = Get.find<InventoryController>();
    final txCtrl = Get.find<TransactionController>();

    Product? selectedProduct;
    final qtyC = TextEditingController();
    final priceC = TextEditingController();
    String mode = 'Cash';

    Get.defaultDialog(
        title: "Product Out / Sale",
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Product Dropdown
              DropdownButtonFormField<Product>(
                items: invCtrl.products.map((p) => DropdownMenuItem(value: p, child: Text(p.name))).toList(),
                onChanged: (val) {
                  selectedProduct = val;
                  priceC.text = val?.estSellPrice.toString() ?? '0';
                },
                decoration: InputDecoration(labelText: "Select Product"),
              ),
              TextField(controller: qtyC, decoration: InputDecoration(labelText: "Quantity"), keyboardType: TextInputType.number),
              TextField(controller: priceC, decoration: InputDecoration(labelText: "Final Sell Price"), keyboardType: TextInputType.number),

              // Payment Mode
              DropdownButtonFormField<String>(
                value: mode,
                items: ['Cash', 'Bank'].map((e) => DropdownMenuItem(value: e, child: Text(e))).toList(),
                onChanged: (v) => mode = v!,
                decoration: InputDecoration(labelText: "Payment Mode"),
              ),
            ],
          ),
        ),
        confirm: ElevatedButton(
            onPressed: () {
              if (selectedProduct != null && qtyC.text.isNotEmpty) {
                txCtrl.recordSale(
                    product: selectedProduct!,
                    qty: int.parse(qtyC.text),
                    sellPrice: double.parse(priceC.text),
                    paymentMode: mode
                );
                Get.back();
                Get.snackbar("Success", "Sale recorded & PDF Generated");
              }
            },
            child: Text("Confirm Sale")
        )
    );
  }

  void _showExpenseDialog(BuildContext context) {
    final txCtrl = Get.find<TransactionController>();
    final descC = TextEditingController();
    final amtC = TextEditingController();
    String mode = 'Cash';

    Get.defaultDialog(
        title: "Record Expense",
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(controller: descC, decoration: InputDecoration(labelText: "Expense Type / Description")),
            TextField(controller: amtC, decoration: InputDecoration(labelText: "Amount"), keyboardType: TextInputType.number),
            DropdownButtonFormField<String>(
              value: mode,
              items: ['Cash', 'Bank'].map((e) => DropdownMenuItem(value: e, child: Text(e))).toList(),
              onChanged: (v) => mode = v!,
              decoration: InputDecoration(labelText: "Payment From"),
            ),
          ],
        ),
        confirm: ElevatedButton(
            onPressed: () {
              txCtrl.recordExpense(
                  desc: descC.text,
                  amount: double.parse(amtC.text),
                  paymentMode: mode
              );
              Get.back();
            },
            child: Text("Save Expense")
        )
    );
  }
}