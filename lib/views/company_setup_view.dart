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
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (isInitialSetup)
              const Padding(
                padding: EdgeInsets.only(bottom: 24),
                child: Text(
                  "Welcome to FirmFlow!\nLet's get your business set up.",
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.indigo),
                ),
              ),

            Card(
              elevation: 0,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16), side: BorderSide(color: Colors.grey.shade200)),
              margin: EdgeInsets.zero,
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(children: [
                  TextField(controller: nameC, decoration: const InputDecoration(labelText: "Firm Name", prefixIcon: Icon(Icons.business))),
                  const SizedBox(height: 16),
                  TextField(controller: gstinC, decoration: const InputDecoration(labelText: "GSTIN (Optional)", prefixIcon: Icon(Icons.receipt_long))),
                  const SizedBox(height: 16),
                  TextField(controller: addressC, decoration: const InputDecoration(labelText: "Address", prefixIcon: Icon(Icons.location_on))),
                  const SizedBox(height: 16),
                  TextField(controller: phoneC, decoration: const InputDecoration(labelText: "Phone", prefixIcon: Icon(Icons.phone))),
                ]),
              ),
            ),

            const Padding(
              padding: EdgeInsets.symmetric(vertical: 20),
              child: Text("Opening Balances", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.grey)),
            ),

            Card(
              elevation: 0,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16), side: BorderSide(color: Colors.grey.shade200)),
              margin: EdgeInsets.zero,
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(children: [
                  TextField(controller: cashC, decoration: const InputDecoration(labelText: "Cash in Hand", prefixIcon: Icon(Icons.money)), keyboardType: TextInputType.number),
                  const SizedBox(height: 16),
                  TextField(controller: bankC, decoration: const InputDecoration(labelText: "Bank Balance", prefixIcon: Icon(Icons.account_balance)), keyboardType: TextInputType.number),
                ]),
              ),
            ),
            const SizedBox(height: 32),
            ElevatedButton(
                onPressed: () {
                  if (nameC.text.isEmpty) {
                    Get.snackbar("Required", "Firm Name is required", backgroundColor: Colors.red.shade100, colorText: Colors.red.shade900);
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