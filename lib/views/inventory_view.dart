import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../controllers/inventory_controller.dart';
import '../models/product_model.dart';
import '../controllers/company_controller.dart';

class InventoryView extends StatelessWidget {
  const InventoryView({super.key});

  @override
  Widget build(BuildContext context) {
    final ctrl = Get.put(InventoryController());
    final compCtrl = Get.find<CompanyController>();

    return Scaffold(
      floatingActionButton: FloatingActionButton(
        child: Icon(Icons.add),
        onPressed: () => _showAddProductDialog(context, ctrl, compCtrl),
      ),
      body: Obx(() {
        if (ctrl.products.isEmpty) return Center(child: Text("No Products"));
        return ListView.builder(
          itemCount: ctrl.products.length,
          itemBuilder: (ctx, i) {
            final p = ctrl.products[i];
            return ListTile(
              title: Text(p.name),
              subtitle: Text("HSN: ${p.hsn} | Est Sell: ₹${p.estSellPrice}"),
              trailing: Chip(
                label: Text("${p.currentStock}", style: TextStyle(color: Colors.white)),
                backgroundColor: p.currentStock < 5 ? Colors.red : Colors.green,
              ),
            );
          },
        );
      }),
    );
  }

  void _showAddProductDialog(BuildContext context, InventoryController ctrl, CompanyController cCtrl) {
    final nameC = TextEditingController();
    final stockC = TextEditingController();
    final sellC = TextEditingController();

    Get.defaultDialog(
        title: "New Product",
        content: Column(children: [
          TextField(controller: nameC, decoration: InputDecoration(labelText: "Name")),
          TextField(controller: stockC, decoration: InputDecoration(labelText: "Opening Stock"), keyboardType: TextInputType.number),
          TextField(controller: sellC, decoration: InputDecoration(labelText: "Est. Sell Price"), keyboardType: TextInputType.number),
        ]),
        confirm: ElevatedButton(
            onPressed: () {
              final p = Product(
                  id: DateTime.now().millisecondsSinceEpoch.toString(),
                  companyId: cCtrl.currentCompany.value!.id,
                  name: nameC.text,
                  hsn: "0000", // Add Input for this
                  estSellPrice: double.tryParse(sellC.text) ?? 0,
                  buyPrice: 0, // Add input
                  currentStock: int.tryParse(stockC.text) ?? 0
              );
              ctrl.addProduct(p);
              Get.back();
            },
            child: Text("Save")
        )
    );
  }
}