import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:uuid/uuid.dart';
import '../controllers/inventory_controller.dart';
import '../controllers/company_controller.dart';
import '../models/product_model.dart';

class InventoryView extends StatelessWidget {
  // FIX: Use getters
  InventoryController get iCtrl => Get.find();
  CompanyController get cCtrl => Get.find();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showProductDialog(),
        icon: const Icon(Icons.add),
        label: const Text("Add Product"),
        backgroundColor: Colors.indigo,
        foregroundColor: Colors.white,
      ),
      body: Obx(() => ListView.builder(
        padding: const EdgeInsets.only(bottom: 80, top: 8),
        itemCount: iCtrl.products.length,
        itemBuilder: (ctx, i) {
          final p = iCtrl.products[i];
          final isLowStock = p.currentStock < 5;
          return Card(
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Row(
                children: [
                  Container(
                    width: 50, height: 50,
                    decoration: BoxDecoration(
                      color: Colors.indigo.shade50,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Center(child: Text(p.name[0].toUpperCase(), style: TextStyle(fontWeight: FontWeight.bold, color: Colors.indigo, fontSize: 20))),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      Text(p.name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                      Text("HSN: ${p.hsn}", style: TextStyle(color: Colors.grey.shade600, fontSize: 12)),
                    ]),
                  ),
                  Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                          color: isLowStock ? Colors.red.shade100 : Colors.green.shade100,
                          borderRadius: BorderRadius.circular(6)
                      ),
                      child: Text(
                        isLowStock ? "Low Stock: ${p.currentStock}" : "Stock: ${p.currentStock}",
                        style: TextStyle(
                            color: isLowStock ? Colors.red.shade800 : Colors.green.shade800,
                            fontSize: 10, fontWeight: FontWeight.bold
                        ),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text("₹ ${p.estSellPrice}", style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                  ]),
                ],
              ),
            ),
          );
        },
      )),
    );
  }

  void _showProductDialog() {
    final nC = TextEditingController();
    final hC = TextEditingController();
    final sC = TextEditingController();
    final bC = TextEditingController();
    final stC = TextEditingController();

    Get.defaultDialog(
        title: "Add Product",
        titlePadding: const EdgeInsets.only(top: 20),
        contentPadding: const EdgeInsets.all(20),
        content: SingleChildScrollView(child: Column(children: [
          TextField(controller: nC, decoration: const InputDecoration(labelText: "Product Name", prefixIcon: Icon(Icons.tag))),
          const SizedBox(height: 12),
          TextField(controller: hC, decoration: const InputDecoration(labelText: "HSN Code", prefixIcon: Icon(Icons.code))),
          const SizedBox(height: 12),
          Row(children: [
            Expanded(child: TextField(controller: stC, decoration: const InputDecoration(labelText: "Stock", prefixIcon: Icon(Icons.inventory)), keyboardType: TextInputType.number)),
            const SizedBox(width: 12),
            Expanded(child: TextField(controller: sC, decoration: const InputDecoration(labelText: "Sell Price", prefixIcon: Icon(Icons.currency_rupee)), keyboardType: TextInputType.number)),
          ]),
          const SizedBox(height: 12),
          TextField(controller: bC, decoration: const InputDecoration(labelText: "Buy Price (Optional)", prefixIcon: Icon(Icons.currency_rupee)), keyboardType: TextInputType.number),
        ])),
        confirm: SizedBox(
          width: double.infinity,
          child: ElevatedButton(onPressed: () {
            if(nC.text.isEmpty) return;
            final p = Product(
                id: const Uuid().v4(),
                companyId: cCtrl.currentCompany.value!.id,
                name: nC.text,
                hsn: hC.text,
                currentStock: int.tryParse(stC.text) ?? 0,
                estSellPrice: double.tryParse(sC.text) ?? 0,
                buyPrice: double.tryParse(bC.text) ?? 0
            );
            iCtrl.addProduct(p);
            Get.back();
          }, child: const Text("Save Product")),
        )
    );
  }
}