import 'package:get/get.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/transaction_model.dart';
import '../models/product_model.dart';
import 'company_controller.dart';
import 'inventory_controller.dart';
import '../services/pdf_service.dart'; // We will create this next

class TransactionController extends GetxController {
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final CompanyController _companyCtrl = Get.find();
  final InventoryController _invCtrl = Get.find();

  RxList<AppTransaction> transactions = <AppTransaction>[].obs;

  // Ledger Observables
  RxDouble currentCash = 0.0.obs;
  RxDouble currentBank = 0.0.obs;

  @override
  void onInit() {
    super.onInit();
    ever(_companyCtrl.currentCompany, (_) => fetchTransactions());
    ever(transactions, (_) => calculateLedger());
    fetchTransactions();
  }

  void fetchTransactions() {
    if (_companyCtrl.currentCompany.value == null) return;

    _db.collection('transactions')
        .where('companyId', isEqualTo: _companyCtrl.currentCompany.value!.id)
        .orderBy('date', descending: true)
        .snapshots()
        .listen((snapshot) {
      transactions.value = snapshot.docs.map((doc) => AppTransaction.fromJson(doc.data())).toList();
      calculateLedger();
    });
  }

  void calculateLedger() {
    if (_companyCtrl.currentCompany.value == null) return;

    double cash = _companyCtrl.currentCompany.value!.openingCashBalance;
    double bank = _companyCtrl.currentCompany.value!.openingBankBalance;

    for (var t in transactions) {
      if (t.paymentMode == 'Cash') {
        // Sale (In) adds to cash, Expense (Out) subtracts
        cash += (t.type == 'sale') ? t.amount : -t.amount;
      } else {
        bank += (t.type == 'sale') ? t.amount : -t.amount;
      }
    }
    currentCash.value = cash;
    currentBank.value = bank;
  }

  // --- LOGIC: PRODUCT OUT / SELL ---
  Future<void> recordSale({
    required Product product,
    required int qty,
    required double sellPrice,
    required String paymentMode,
    String? partyName
  }) async {
    if (_companyCtrl.currentCompany.value == null) return;

    // 1. Create Transaction Object
    final tx = AppTransaction(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        companyId: _companyCtrl.currentCompany.value!.id,
        type: 'sale',
        amount: sellPrice * qty,
        paymentMode: paymentMode,
        date: DateTime.now(),
        productId: product.id,
        quantity: qty,
        partyName: partyName ?? 'Cash Sale',
        remarks: 'Sold ${product.name} x $qty'
    );

    // 2. Run Batch Write (Atomic Operation)
    WriteBatch batch = _db.batch();

    // A. Add Transaction
    DocumentReference txRef = _db.collection('transactions').doc(tx.id);
    batch.set(txRef, tx.toJson());

    // B. Reduce Inventory
    DocumentReference prodRef = _db.collection('products').doc(product.id);
    batch.update(prodRef, {
      'currentStock': FieldValue.increment(-qty)
    });

    await batch.commit();

    // 3. Generate PDF
    PdfService.generateInvoice(_companyCtrl.currentCompany.value!, tx, product);
  }

  // --- LOGIC: EXPENSE ---
  Future<void> recordExpense({
    required String desc,
    required double amount,
    required String paymentMode,
    String? partyName
  }) async {
    final tx = AppTransaction(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        companyId: _companyCtrl.currentCompany.value!.id,
        type: 'expense',
        amount: amount,
        paymentMode: paymentMode,
        date: DateTime.now(),
        partyName: partyName,
        remarks: desc
    );

    await _db.collection('transactions').doc(tx.id).set(tx.toJson());
    // PdfService.generateExpenseBill(...) // Optional
  }
}