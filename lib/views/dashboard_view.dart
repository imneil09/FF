import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../controllers/company_controller.dart';
import '../controllers/transaction_controller.dart';
import 'inventory_view.dart';
import 'transactions_view.dart';
import 'parties_view.dart';
import 'company_setup_view.dart';

class DashboardView extends StatelessWidget {
  // FIX: Use 'get' to load these only when the Widget is built, not when it's constructed.
  CompanyController get cCtrl => Get.find();
  TransactionController get tCtrl => Get.find();

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      if (cCtrl.companies.isEmpty) {
        return CompanySetupView(isInitialSetup: true);
      }

      return DefaultTabController(
        length: 3,
        child: Scaffold(
          appBar: AppBar(
            title: GestureDetector(
              onTap: () => _showCompanySwitcher(),
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(cCtrl.currentCompany.value?.name ?? "FirmFlow",
                    style: const TextStyle(fontWeight: FontWeight.bold)),
                Row(children: [
                  const Icon(Icons.location_on, size: 12, color: Colors.white70),
                  const SizedBox(width: 4),
                  Text("Tripura (16) • Tap to switch",
                      style: const TextStyle(fontSize: 12, color: Colors.white70)),
                ]),
              ]),
            ),
            actions: [
              IconButton(
                icon: const CircleAvatar(
                  backgroundColor: Colors.white24,
                  child: Icon(Icons.add_business, color: Colors.white, size: 20),
                ),
                onPressed: () => Get.to(() => CompanySetupView()),
              )
            ],
            bottom: const TabBar(
              indicatorColor: Colors.white,
              indicatorWeight: 3,
              labelColor: Colors.white,
              unselectedLabelColor: Colors.white60,
              labelStyle: TextStyle(fontWeight: FontWeight.bold),
              tabs: [
                Tab(text: "Inventory"),
                Tab(text: "Transactions"),
                Tab(text: "Parties"),
              ],
            ),
          ),
          body: TabBarView(children: [
            InventoryView(),
            TransactionsView(),
            PartiesView(),
          ]),

          bottomNavigationBar: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              boxShadow: [
                BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, -4))
              ],
            ),
            child: SafeArea(
              child: Row(
                children: [
                  Expanded(
                    child: _buildBalanceCard(
                      "CASH IN HAND",
                      tCtrl.currentCash.value,
                      Colors.green.shade50,
                      Colors.green.shade800,
                      Icons.account_balance_wallet,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _buildBalanceCard(
                      "BANK BALANCE",
                      tCtrl.currentBank.value,
                      Colors.blue.shade50,
                      Colors.blue.shade800,
                      Icons.account_balance,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      );
    });
  }

  Widget _buildBalanceCard(String label, double amount, Color bg, Color color, IconData icon) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [
            Icon(icon, size: 14, color: color.withOpacity(0.7)),
            const SizedBox(width: 6),
            Text(label, style: TextStyle(color: color.withOpacity(0.7), fontSize: 10, fontWeight: FontWeight.bold)),
          ]),
          const SizedBox(height: 4),
          Text("₹ ${amount.toStringAsFixed(0)}",
              style: TextStyle(color: color, fontSize: 18, fontWeight: FontWeight.w800)
          ),
        ],
      ),
    );
  }

  void _showCompanySwitcher() {
    Get.bottomSheet(
      Container(
        padding: const EdgeInsets.all(20),
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text("Select Company", style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.grey.shade800)),
            const SizedBox(height: 16),
            Flexible(
              child: ListView(
                shrinkWrap: true,
                children: cCtrl.companies.map((c) => Container(
                  margin: const EdgeInsets.only(bottom: 8),
                  decoration: BoxDecoration(
                      color: c.id == cCtrl.currentCompany.value?.id ? Colors.indigo.shade50 : Colors.grey.shade50,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                          color: c.id == cCtrl.currentCompany.value?.id ? Colors.indigo : Colors.transparent
                      )
                  ),
                  child: ListTile(
                    leading: CircleAvatar(
                      backgroundColor: Colors.indigo.shade100,
                      child: Text(c.name[0].toUpperCase(), style: const TextStyle(color: Colors.indigo)),
                    ),
                    title: Text(c.name, style: const TextStyle(fontWeight: FontWeight.bold)),
                    trailing: c.id == cCtrl.currentCompany.value?.id ? const Icon(Icons.check_circle, color: Colors.indigo) : null,
                    onTap: () {
                      cCtrl.switchCompany(c);
                      Get.back();
                    },
                  ),
                )).toList(),
              ),
            ),
          ],
        ),
      ),
      isScrollControlled: true,
    );
  }
}