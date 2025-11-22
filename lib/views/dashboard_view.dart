import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../controllers/transaction_controller.dart';
import '../controllers/company_controller.dart';
import 'inventory_view.dart';
import 'transactions_view.dart';

class DashboardView extends StatelessWidget {
  final txCtrl = Get.put(TransactionController());
  final compCtrl = Get.put(CompanyController());

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          title: Obx(() => Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(compCtrl.currentCompany.value?.name ?? "Select Company"),
              Text("Tripura (16)", style: TextStyle(fontSize: 12)),
            ],
          )),
          actions: [
            // Company Switcher logic here
            IconButton(icon: Icon(Icons.business), onPressed: () { /* Show Dialog to add/switch company */ })
          ],
          bottom: const TabBar(
            tabs: [
              Tab(icon: Icon(Icons.inventory), text: "Inventory"),
              Tab(icon: Icon(Icons.swap_horiz), text: "Transact"),
            ],
          ),
        ),
        body: const TabBarView(
          children: [
            InventoryView(),
            TransactionsView(),
          ],
        ),
        bottomNavigationBar: Container(
          color: Colors.indigo.shade50,
          padding: EdgeInsets.all(10),
          child: Obx(() => Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              Text("Cash: ₹${txCtrl.currentCash.value.toStringAsFixed(0)}", style: TextStyle(color: Colors.green, fontWeight: FontWeight.bold)),
              Text("Bank: ₹${txCtrl.currentBank.value.toStringAsFixed(0)}", style: TextStyle(color: Colors.blue, fontWeight: FontWeight.bold)),
            ],
          )),
        ),
      ),
    );
  }
}