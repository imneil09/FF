import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:uuid/uuid.dart';
import '../controllers/party_controller.dart';
import '../controllers/company_controller.dart';
import '../models/party_model.dart';

class PartiesView extends StatelessWidget {
  // FIX: Use getters
  PartyController get pCtrl => Get.find();
  CompanyController get cCtrl => Get.find();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _addPartyDialog(),
        icon: const Icon(Icons.person_add),
        label: const Text("New Party"),
        backgroundColor: Colors.indigo,
        foregroundColor: Colors.white,
      ),
      body: Obx(() {
        if (pCtrl.parties.isEmpty) {
          return Center(
            child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
              Icon(Icons.people_outline, size: 64, color: Colors.grey.shade300),
              const SizedBox(height: 16),
              Text("No parties added", style: TextStyle(color: Colors.grey.shade500)),
            ]),
          );
        }
        return ListView.builder(
          padding: const EdgeInsets.only(bottom: 80, top: 8),
          itemCount: pCtrl.parties.length,
          itemBuilder: (ctx, i) {
            final p = pCtrl.parties[i];
            final isCustomer = p.type == 'customer';
            return Card(
              child: ListTile(
                leading: CircleAvatar(
                  backgroundColor: isCustomer ? Colors.blue.shade50 : Colors.orange.shade50,
                  foregroundColor: isCustomer ? Colors.blue : Colors.orange,
                  child: Text(p.name[0].toUpperCase(), style: const TextStyle(fontWeight: FontWeight.bold)),
                ),
                title: Text(p.name, style: const TextStyle(fontWeight: FontWeight.bold)),
                subtitle: Text(p.phone.isNotEmpty ? p.phone : "No Phone"),
                trailing: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                      color: Colors.grey.shade100,
                      borderRadius: BorderRadius.circular(6),
                      border: Border.all(color: Colors.grey.shade300)
                  ),
                  child: Text(p.type.toUpperCase(), style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold)),
                ),
              ),
            );
          },
        );
      }),
    );
  }

  void _addPartyDialog() {
    final nC = TextEditingController();
    final pC = TextEditingController();
    final aC = TextEditingController();
    final gC = TextEditingController();
    String type = 'customer';

    Get.defaultDialog(
        title: "Add Party",
        titlePadding: const EdgeInsets.only(top: 20),
        contentPadding: const EdgeInsets.all(20),
        content: SingleChildScrollView(child: Column(children: [
          TextField(controller: nC, decoration: const InputDecoration(labelText: "Name", prefixIcon: Icon(Icons.person))),
          const SizedBox(height: 12),
          TextField(controller: pC, decoration: const InputDecoration(labelText: "Phone", prefixIcon: Icon(Icons.phone))),
          const SizedBox(height: 12),
          TextField(controller: aC, decoration: const InputDecoration(labelText: "Address", prefixIcon: Icon(Icons.map))),
          const SizedBox(height: 12),
          TextField(controller: gC, decoration: const InputDecoration(labelText: "GSTIN (Optional)", prefixIcon: Icon(Icons.receipt))),
          const SizedBox(height: 12),
          DropdownButtonFormField<String>(
            decoration: const InputDecoration(labelText: "Type", prefixIcon: Icon(Icons.category)),
            value: type,
            items: ['customer', 'vendor'].map((e) => DropdownMenuItem(value: e, child: Text(e.toUpperCase()))).toList(),
            onChanged: (v) => type = v!,
          ),
        ])),
        confirm: SizedBox(
          width: double.infinity,
          child: ElevatedButton(onPressed: () {
            if(nC.text.isEmpty) return;
            final p = Party(
                id: const Uuid().v4(),
                companyId: cCtrl.currentCompany.value!.id,
                name: nC.text,
                phone: pC.text,
                address: aC.text,
                gstin: gC.text,
                type: type
            );
            pCtrl.addParty(p);
            Get.back();
          }, child: const Text("Save Party")),
        )
    );
  }
}