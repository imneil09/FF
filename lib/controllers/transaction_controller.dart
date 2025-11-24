import 'package:get/get.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/transaction_model.dart';
import '../models/product_model.dart';
import 'company_controller.dart';
import '../services/pdf_service.dart';

class TransactionController extends GetxController {
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final CompanyController _cCtrl = Get.find();

  RxList<AppTransaction> transactions = <AppTransaction>[].obs;
  RxDouble currentCash = 0.0.obs;
  RxDouble currentBank = 0.0.obs;

  @override
  void onInit() {
    super.onInit();
    ever(_cCtrl.currentCompany, (_) => fetchTransactions());
    ever(transactions, (_) => calculateLedger());
    fetchTransactions();
  }

  void fetchTransactions() {
    if (_cCtrl.currentCompany.value == null) return;
    _db.collection('transactions')
        .where('companyId', isEqualTo: _cCtrl.currentCompany.value!.id)
        .orderBy('date', descending: true)
        .snapshots()
        .listen((snap) {
      transactions.value = snap.docs.map((d) => AppTransaction.fromJson(d.data())).toList();
      calculateLedger();
    });
  }

  void calculateLedger() {
    if (_cCtrl.currentCompany.value == null) return;
    double cash = _cCtrl.currentCompany.value!.openingCashBalance;
    double bank = _cCtrl.currentCompany.value!.openingBankBalance;

    for (var t in transactions) {
      if (t.paymentMode == 'Cash') {
        cash += (t.type == 'sale') ? t.amount : -t.amount;
      } else if (t.paymentMode == 'Bank') {
        bank += (t.type == 'sale') ? t.amount : -t.amount;
      }
    }
    currentCash.value = cash;
    currentBank.value = bank;
  }

  Future<void> recordSale({
    required Product product,
    required int qty,
    required double sellPrice,
    required String paymentMode,
    String? partyId,
    String? partyName
  }) async {
    if (_cCtrl.currentCompany.value == null) return;

    final tx = AppTransaction(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        companyId: _cCtrl.currentCompany.value!.id,
        type: 'sale',
        amount: sellPrice * qty,
        paymentMode: paymentMode,
        date: DateTime.now(),
        productId: product.id,
        productName: product.name,
        quantity: qty,
        buyPriceAtTime: product.buyPrice,
        partyId: partyId,
        partyName: partyName,
        remarks: 'Sale: ${product.name} x $qty'
    );

    WriteBatch batch = _db.batch();
    batch.set(_db.collection('transactions').doc(tx.id), tx.toJson());
    batch.update(_db.collection('products').doc(product.id), {
      'currentStock': FieldValue.increment(-qty)
    });

    await batch.commit();
    PdfService.generateInvoice(_cCtrl.currentCompany.value!, tx);
  }

  Future<void> recordExpense({
    required String desc,
    required double amount,
    required String paymentMode,
    String? partyId,
    String? partyName
  }) async {
    if (_cCtrl.currentCompany.value == null) return;

    final tx = AppTransaction(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        companyId: _cCtrl.currentCompany.value!.id,
        type: 'expense',
        amount: amount,
        paymentMode: paymentMode,
        date: DateTime.now(),
        partyId: partyId,
        partyName: partyName,
        remarks: desc
    );

    await _db.collection('transactions').doc(tx.id).set(tx.toJson());
    // PdfService.generateVoucher(...) // Optional for expenses
  }
}