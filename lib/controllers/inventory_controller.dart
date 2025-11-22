import 'package:get/get.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/product_model.dart';
import 'company_controller.dart';

class InventoryController extends GetxController {
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final CompanyController _companyCtrl = Get.find();
  RxList<Product> products = <Product>[].obs;

  @override
  void onInit() {
    super.onInit();
    // Listen to company changes to fetch relevant products
    ever(_companyCtrl.currentCompany, (_) => fetchProducts());
    fetchProducts();
  }

  void fetchProducts() {
    if (_companyCtrl.currentCompany.value == null) return;

    _db.collection('products')
        .where('companyId', isEqualTo: _companyCtrl.currentCompany.value!.id)
        .snapshots()
        .listen((snapshot) {
      products.value = snapshot.docs.map((doc) => Product.fromJson(doc.data())).toList();
    });
  }

  Future<void> addProduct(Product product) async {
    await _db.collection('products').doc(product.id).set(product.toJson());
  }

  // Helper to get product name by ID
  String getProductName(String id) {
    final p = products.firstWhereOrNull((element) => element.id == id);
    return p?.name ?? 'Unknown Product';
  }
}