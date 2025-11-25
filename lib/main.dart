import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:firebase_core/firebase_core.dart';
import 'views/dashboard_view.dart';
import 'controllers/company_controller.dart';
import 'controllers/transaction_controller.dart';
import 'controllers/inventory_controller.dart';
import 'controllers/party_controller.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  try {
    await Firebase.initializeApp();
  } catch (e) {
    debugPrint("Firebase initialization failed: $e");
  }
  runApp(const FirmFlowApp());
}

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
        scaffoldBackgroundColor: Colors.grey.shade50,

        // Modern Card Theme
        cardTheme: CardTheme(
          elevation: 2,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          color: Colors.white,
          surfaceTintColor: Colors.white,
        ),

        // Modern Input Decoration
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: Colors.grey.shade100,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide.none,
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide.none,
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: Colors.indigo, width: 2),
          ),
          contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          prefixIconColor: Colors.indigo.shade400,
        ),

        // Modern Button Theme
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.indigo,
            foregroundColor: Colors.white,
            elevation: 2,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
            textStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
          ),
        ),

        // AppBar Theme
        appBarTheme: const AppBarTheme(
          centerTitle: false,
          elevation: 0,
          backgroundColor: Colors.indigo,
          foregroundColor: Colors.white,
        ),
      ),
      initialBinding: AppBinding(),
      home: DashboardView(),
    );
  }
}