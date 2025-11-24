import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:uuid/uuid.dart';
import '../controllers/company_controller.dart';
import '../models/company_model.dart';

class CompanySetupView extends StatelessWidget {
  final bool isInitialSetup;

  CompanySetupView({super.key, this.isInitialSetup = false});

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
      appBar: AppBar(title: const Text("Setup New Firm")),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: ListView(
          children: [
            TextField(controller: nameC, decoration: const InputDecoration(labelText: "Firm Name")),
            TextField(controller: gstinC, decoration: const InputDecoration(labelText: "GSTIN")),
            TextField(controller: addressC, decoration: const InputDecoration(labelText: "Address")),
            TextField(controller: phoneC, decoration: const InputDecoration(labelText: "Phone")),
            const Divider(),
            const Text("Opening Balances"),
            TextField(controller: cashC, decoration: const InputDecoration(labelText: "Cash Opening Balance"), keyboardType: TextInputType.number),
            TextField(controller: bankC, decoration: const InputDecoration(labelText: "Bank Opening Balance"), keyboardType: TextInputType.number),
            const SizedBox(height: 20),
            ElevatedButton(
                onPressed: () {
                  if (nameC.text.isEmpty) {
                    Get.snackbar("Error", "Firm Name is required");
                    return;
                  }
                  final c = Company(
                      id: const Uuid().v4(),
                      name: nameC.text,
                      gstin: gstinC.text,
                      address: addressC.text,
                      phone: phoneC.text,
                      openingCashBalance: double.tryParse(cashC.text) ?? 0,
                      openingBankBalance: double.tryParse(bankC.text) ?? 0
                  );
                  ctrl.addCompany(c);

                  // Only go back if we are in a navigation stack (not initial setup)
                  if (!isInitialSetup) {
                    Get.back();
                  }
                },
                child: const Text("Create Firm")
            )
          ],
        ),
      ),
    );
  }
}