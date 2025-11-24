import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../controllers/company_controller.dart';
import '../controllers/transaction_controller.dart';
import 'inventory_view.dart';
import 'transactions_view.dart';
import 'parties_view.dart';
import 'company_setup_view.dart';

class DashboardView extends StatelessWidget {
  // Use Get.find because AppBinding already created them
  final cCtrl = Get.find<CompanyController>();
  final tCtrl = Get.find<TransactionController>();

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      if (cCtrl.companies.isEmpty) {
        // Force create company. Pass true to indicate this is the initial setup.
        return CompanySetupView(isInitialSetup: true);
      }

      return DefaultTabController(
        length: 3,
        child: Scaffold(
          appBar: AppBar(
            title: GestureDetector(
              onTap: () => _showCompanySwitcher(),
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(cCtrl.currentCompany.value?.name ?? "Loading..."),
                Text("Tripura (16) - Tap to switch", style: TextStyle(fontSize: 10)),
              ]),
            ),
            bottom: const TabBar(tabs: [
              Tab(icon: Icon(Icons.inventory), text: "Inventory"),
              Tab(icon: Icon(Icons.swap_horiz), text: "Transactions"),
              Tab(icon: Icon(Icons.people), text: "Parties"),
            ]),
            actions: [
              // Pass false (default) because this is a pushed route, so we CAN go back
              IconButton(
                  icon: const Icon(Icons.add_business),
                  onPressed: () => Get.to(() => CompanySetupView())
              )
            ],
          ),
          body: TabBarView(children: [
            InventoryView(),
            TransactionsView(),
            PartiesView(),
          ]),
          bottomNavigationBar: Container(
            height: 60,
            color: Colors.indigo.shade50,
            child: Row(mainAxisAlignment: MainAxisAlignment.spaceEvenly, children: [
              Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                const Text("CASH", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 10)),
                Text("Rs. ${tCtrl.currentCash.value.toStringAsFixed(0)}", style: const TextStyle(color: Colors.green, fontWeight: FontWeight.bold, fontSize: 16))
              ]),
              const VerticalDivider(),
              Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                const Text("BANK", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 10)),
                Text("Rs. ${tCtrl.currentBank.value.toStringAsFixed(0)}", style: const TextStyle(color: Colors.blue, fontWeight: FontWeight.bold, fontSize: 16))
              ])
            ]),
          ),
        ),
      );
    });
  }

  void _showCompanySwitcher() {
    Get.bottomSheet(Container(
      color: Colors.white,
      child: ListView(
        shrinkWrap: true,
        children: cCtrl.companies.map((c) => ListTile(
          title: Text(c.name),
          trailing: c.id == cCtrl.currentCompany.value?.id ? const Icon(Icons.check) : null,
          onTap: () {
            cCtrl.switchCompany(c);
            Get.back();
          },
        )).toList(),
      ),
    ));
  }
}