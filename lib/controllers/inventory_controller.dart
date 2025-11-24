import 'package:get/get.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/product_model.dart';
import 'company_controller.dart';

class InventoryController extends GetxController {
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final CompanyController _cCtrl = Get.find();
  RxList<Product> products = <Product>[].obs;

  @override
  void onInit() {
    super.onInit();
    ever(_cCtrl.currentCompany, (_) => fetchProducts());
    fetchProducts();
  }

  void fetchProducts() {
    if (_cCtrl.currentCompany.value == null) return;
    _db.collection('products')
        .where('companyId', isEqualTo: _cCtrl.currentCompany.value!.id)
        .snapshots()
        .listen((snap) {
      products.value = snap.docs.map((d) => Product.fromJson(d.data())).toList();
    });
  }

  Future<void> addProduct(Product p) async {
    await _db.collection('products').doc(p.id).set(p.toJson());
  }

  Future<void> deleteProduct(String id) async {
    await _db.collection('products').doc(id).delete();
  }
}