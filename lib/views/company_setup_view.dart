import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:uuid/uuid.dart';
import '../controllers/company_controller.dart';
import '../models/company_model.dart';

class CompanySetupView extends StatelessWidget {
  final CompanyController ctrl = Get.find();
  final nameC = TextEditingController();
  final gstinC = TextEditingController();
  final addressC = TextEditingController();
  final phoneC = TextEditingController();
  final cashC = TextEditingController();
  final bankC = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("Setup New Firm")),
      body: Padding(
        padding: EdgeInsets.all(16),
        child: ListView(
          children: [
            TextField(controller: nameC, decoration: InputDecoration(labelText: "Firm Name")),
            TextField(controller: gstinC, decoration: InputDecoration(labelText: "GSTIN")),
            TextField(controller: addressC, decoration: InputDecoration(labelText: "Address")),
            TextField(controller: phoneC, decoration: InputDecoration(labelText: "Phone")),
            Divider(),
            Text("Opening Balances"),
            TextField(controller: cashC, decoration: InputDecoration(labelText: "Cash Opening Balance"), keyboardType: TextInputType.number),
            TextField(controller: bankC, decoration: InputDecoration(labelText: "Bank Opening Balance"), keyboardType: TextInputType.number),
            SizedBox(height: 20),
            ElevatedButton(
                onPressed: () {
                  final c = Company(
                      id: Uuid().v4(),
                      name: nameC.text,
                      gstin: gstinC.text,
                      address: addressC.text,
                      phone: phoneC.text,
                      openingCashBalance: double.tryParse(cashC.text) ?? 0,
                      openingBankBalance: double.tryParse(bankC.text) ?? 0
                  );
                  ctrl.addCompany(c);
                  Get.back();
                },
                child: Text("Create Firm")
            )
          ],
        ),
      ),
    );
  }
}