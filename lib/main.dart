import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:firebase_core/firebase_core.dart';
// import 'firebase_options.dart'; // REMOVED: Re-enable this after running 'flutterfire configure'

import 'views/dashboard_view.dart';
import 'controllers/company_controller.dart';
import 'controllers/transaction_controller.dart';
import 'controllers/inventory_controller.dart';
import 'controllers/party_controller.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  try {
    // Initializing without 'options' relies on google-services.json (Android) or GoogleService-Info.plist (iOS).
    // Run 'flutterfire configure' to generate the options file for better cross-platform support.
    await Firebase.initializeApp();
  } catch (e) {
    debugPrint("Firebase initialization failed: $e");
  }

  runApp(const FirmFlowApp());
}

// Bindings ensure all controllers are created when the app starts
class AppBinding extends Bindings {
  @override
  void dependencies() {
    Get.put(CompanyController());
    Get.put(InventoryController());
    Get.put(PartyController());
    Get.put(TransactionController());
  }
}

class FirmFlowApp extends StatelessWidget {
  const FirmFlowApp({super.key});

  @override
  Widget build(BuildContext context) {
    return GetMaterialApp(
      title: 'FirmFlow',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        colorSchemeSeed: Colors.indigo,
      ),
      initialBinding: AppBinding(), // Load dependencies here
      home: DashboardView(),
    );
  }
}