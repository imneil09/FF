import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:uuid/uuid.dart';
import '../controllers/inventory_controller.dart';
import '../controllers/company_controller.dart';
import '../models/product_model.dart';

class InventoryView extends StatelessWidget {
  final iCtrl = Get.put(InventoryController());
  final CompanyController cCtrl = Get.find();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showProductDialog(),
        child: Icon(Icons.add),
      ),
      body: Obx(() => ListView.builder(
        itemCount: iCtrl.products.length,
        itemBuilder: (ctx, i) {
          final p = iCtrl.products[i];
          return Card(
            child: ListTile(
              title: Text(p.name, style: TextStyle(fontWeight: FontWeight.bold)),
              subtitle: Text("HSN: ${p.hsn}"),
              trailing: Column(mainAxisAlignment: MainAxisAlignment.center, crossAxisAlignment: CrossAxisAlignment.end, children: [
                Text("Stock: ${p.currentStock}", style: TextStyle(fontWeight: FontWeight.bold, color: p.currentStock < 5 ? Colors.red : Colors.green)),
                Text("Est. Sell: Rs. ${p.estSellPrice}"),
              ]),
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
        content: SingleChildScrollView(child: Column(children: [
          TextField(controller: nC, decoration: InputDecoration(labelText: "Product Name")),
          TextField(controller: hC, decoration: InputDecoration(labelText: "HSN Code")),
          TextField(controller: stC, decoration: InputDecoration(labelText: "Current Stock"), keyboardType: TextInputType.number),
          TextField(controller: sC, decoration: InputDecoration(labelText: "Est. Sell Price"), keyboardType: TextInputType.number),
          TextField(controller: bC, decoration: InputDecoration(labelText: "Buy Price (Optional)"), keyboardType: TextInputType.number),
        ])),
        confirm: ElevatedButton(onPressed: () {
          if(nC.text.isEmpty) return;
          final p = Product(
              id: Uuid().v4(),
              companyId: cCtrl.currentCompany.value!.id,
              name: nC.text,
              hsn: hC.text,
              currentStock: int.tryParse(stC.text) ?? 0,
              estSellPrice: double.tryParse(sC.text) ?? 0,
              buyPrice: double.tryParse(bC.text) ?? 0
          );
          iCtrl.addProduct(p);
          Get.back();
        }, child: Text("Save"))
    );
  }
}