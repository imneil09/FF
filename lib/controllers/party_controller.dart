import 'package:get/get.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/party_model.dart';
import 'company_controller.dart';

class PartyController extends GetxController {
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final CompanyController _cCtrl = Get.find();
  RxList<Party> parties = <Party>[].obs;

  @override
  void onInit() {
    super.onInit();
    ever(_cCtrl.currentCompany, (_) => fetchParties());
    fetchParties();
  }

  void fetchParties() {
    if (_cCtrl.currentCompany.value == null) return;
    _db.collection('parties')
        .where('companyId', isEqualTo: _cCtrl.currentCompany.value!.id)
        .snapshots()
        .listen((snap) {
      parties.value = snap.docs.map((d) => Party.fromJson(d.data())).toList();
    });
  }

  Future<void> addParty(Party p) async {
    await _db.collection('parties').doc(p.id).set(p.toJson());
  }
}