import 'package:get/get.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/company_model.dart';

class CompanyController extends GetxController {
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  Rx<Company?> currentCompany = Rx<Company?>(null);
  RxList<Company> companies = <Company>[].obs;

  @override
  void onInit() {
    super.onInit();
    fetchCompanies();
  }

  void fetchCompanies() {
    _db.collection('companies').snapshots().listen((snapshot) {
      companies.value = snapshot.docs.map((doc) => Company.fromJson(doc.data())).toList();
      // Auto-select first company if none selected
      if (currentCompany.value == null && companies.isNotEmpty) {
        currentCompany.value = companies.first;
      }
    });
  }

  Future<void> addCompany(Company company) async {
    await _db.collection('companies').doc(company.id).set(company.toJson());
  }

  void switchCompany(Company company) {
    currentCompany.value = company;
    // Trigger reloads in other controllers here if needed
  }
}