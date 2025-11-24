import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:uuid/uuid.dart';
import '../controllers/party_controller.dart';
import '../controllers/company_controller.dart';
import '../models/party_model.dart';

class PartiesView extends StatelessWidget {
  final pCtrl = Get.find<PartyController>();
  final cCtrl = Get.find<CompanyController>();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      floatingActionButton: FloatingActionButton(
        onPressed: () => _addPartyDialog(),
        child: Icon(Icons.person_add),
      ),
      body: Obx(() => ListView.builder(
        itemCount: pCtrl.parties.length,
        itemBuilder: (ctx, i) {
          final p = pCtrl.parties[i];
          return ListTile(
            leading: Icon(Icons.person),
            title: Text(p.name),
            subtitle: Text(p.phone),
            trailing: Text(p.type.toUpperCase(), style: TextStyle(fontSize: 10)),
          );
        },
      )),
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
        content: SingleChildScrollView(child: Column(children: [
          TextField(controller: nC, decoration: InputDecoration(labelText: "Name")),
          TextField(controller: pC, decoration: InputDecoration(labelText: "Phone")),
          TextField(controller: aC, decoration: InputDecoration(labelText: "Address")),
          TextField(controller: gC, decoration: InputDecoration(labelText: "GSTIN")),
          DropdownButtonFormField<String>(
            value: type,
            items: ['customer', 'vendor'].map((e) => DropdownMenuItem(value: e, child: Text(e.toUpperCase()))).toList(),
            onChanged: (v) => type = v!,
          ),
        ])),
        confirm: ElevatedButton(onPressed: () {
          if(nC.text.isEmpty) return;
          final p = Party(
              id: Uuid().v4(),
              companyId: cCtrl.currentCompany.value!.id,
              name: nC.text,
              phone: pC.text,
              address: aC.text,
              gstin: gC.text,
              type: type
          );
          pCtrl.addParty(p);
          Get.back();
        }, child: Text("Save"))
    );
  }
}