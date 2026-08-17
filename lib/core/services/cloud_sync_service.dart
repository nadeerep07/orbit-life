import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import '../../data/datasources/remote_data_source.dart';
import '../../data/models/expense_model.dart';
import '../../data/models/category_model.dart';
import '../../data/models/account_model.dart';
import '../../data/models/savings_model.dart';
import '../../data/models/income_model.dart';
import '../../data/models/mileage_entry_model.dart';
import '../../data/models/transfer_model.dart';
import '../../data/models/goal_model.dart';
import '../../data/models/service_model.dart';
import '../../data/models/diet_model.dart';
import '../../data/models/transaction_model.dart';
import '../../data/models/borrow_lend_model.dart';
import '../../data/models/emi_tracker_model.dart';
import '../../data/models/investment_model.dart';
import '../../features/credit_card/data/models/credit_card_account_model.dart';
import '../../features/credit_card/data/models/fd_lot_model.dart';
import '../../features/credit_card/data/models/credit_card_statement_model.dart';
import '../../features/credit_card/data/models/cashback_transaction_model.dart';

class CloudSyncService {
  static Timer? _debounceTimer;
  static bool isSyncPaused = false;

  static void triggerSync() {
    if (isSyncPaused) return;
    _debounceTimer?.cancel();
    _debounceTimer = Timer(const Duration(milliseconds: 1500), () {
      if (isSyncPaused) return;
      syncToCloud();
    });
  }

  static Future<void> syncToCloud() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return; // Silent return if not logged in

    try {
      final remoteDataSource = FirebaseDataSource(FirebaseFirestore.instance);

      final categoriesBox = await Hive.openBox<CategoryModel>('categories');
      final expensesBox = await Hive.openBox<ExpenseModel>('expenses');
      final accountsBox = await Hive.openBox<AccountModel>('accounts');
      final savingsBox = await Hive.openBox<SavingsModel>('savingsBox');
      final incomesBox = await Hive.openBox<IncomeModel>('incomeBox');
      final mileageBox = await Hive.openBox<MileageEntryModel>('mileageBox');
      final transferBox = await Hive.openBox<TransferModel>('transferBox');
      final goalBox = await Hive.openBox<GoalModel>('goalBox');
      final serviceBox = await Hive.openBox<ServiceModel>('serviceBox');
      final dietProfileBox = await Hive.openBox<DietProfileModel>('dietProfileBox');
      final mealEntryBox = await Hive.openBox<MealEntryModel>('mealEntryBox');
      final transactionBox = await Hive.openBox<TransactionModel>('transactions_box');
      final borrowLendBox = await Hive.openBox<BorrowLendModel>('borrowLendBox');
      final emiTrackerBox = await Hive.openBox<EmiTrackerModel>('emiTrackerBox');
      final investmentBox = await Hive.openBox<InvestmentModel>('investmentBox');
      final ccAccountBox = await Hive.openBox<CreditCardAccountModel>('credit_card_account_box');
      final fdBox = await Hive.openBox<FdLotModel>('fd_lots_box');
      final statementBox = await Hive.openBox<CreditCardStatementModel>('credit_card_statements_box');
      final cashbackBox = await Hive.openBox<CashbackTransactionModel>('cashback_transactions_box');

      final categoriesJson = categoriesBox.values.map((e) => e.toJson()).toList();
      final expensesJson = expensesBox.values.map((e) => e.toJson()).toList();
      final accountsJson = accountsBox.values.map((e) => e.toJson()).toList();
      final savingsJson = savingsBox.values.isNotEmpty ? savingsBox.values.first.toJson() : null;
      final incomesJson = incomesBox.values.map((e) => e.toJson()).toList();
      final mileageJson = mileageBox.values.map((e) => e.toJson()).toList();
      final transfersJson = transferBox.values.map((e) => e.toJson()).toList();
      final goalsJson = goalBox.values.map((e) => e.toJson()).toList();
      final servicesJson = serviceBox.values.map((e) => e.toJson()).toList();
      final dietProfileJson = dietProfileBox.values.isNotEmpty ? dietProfileBox.values.first.toJson() : null;
      final mealEntriesJson = mealEntryBox.values.map((e) => e.toJson()).toList();
      final transactionsJson = transactionBox.values.map((e) => e.toJson()).toList();
      final borrowLendsJson = borrowLendBox.values.map((e) => e.toJson()).toList();
      final emisJson = emiTrackerBox.values.map((e) => e.toJson()).toList();
      final investmentsJson = investmentBox.values.map((e) => e.toJson()).toList();
      final creditCardAccountJson = ccAccountBox.values.isNotEmpty ? ccAccountBox.values.first.toJson() : null;
      final fdLotsJson = fdBox.values.map((e) => e.toJson()).toList();
      final statementsJson = statementBox.values.map((e) => e.toJson()).toList();
      final cashbacksJson = cashbackBox.values.map((e) => e.toJson()).toList();

      await remoteDataSource.backupData(
        userId: user.uid,
        categories: categoriesJson,
        expenses: expensesJson,
        accounts: accountsJson,
        savings: savingsJson,
        incomes: incomesJson,
        mileages: mileageJson,
        transfers: transfersJson,
        goals: goalsJson,
        services: servicesJson,
        dietProfile: dietProfileJson,
        mealEntries: mealEntriesJson,
        transactions: transactionsJson,
        borrowLends: borrowLendsJson,
        emis: emisJson,
        investments: investmentsJson,
        creditCardAccount: creditCardAccountJson,
        fdLots: fdLotsJson,
        statements: statementsJson,
        cashbacks: cashbacksJson,
      );
      debugPrint("CloudSyncService: Local -> Cloud Auto-sync completed.");
    } catch (e) {
      debugPrint("CloudSyncService error: $e");
    }
  }

  static StreamSubscription<DocumentSnapshot>? _remoteSubscription;

  /// Start Real-Time Live Sync from Firestore to Mobile App
  static void startLiveSync(String userId) {
    _remoteSubscription?.cancel();
    _remoteSubscription = FirebaseFirestore.instance
        .collection('users')
        .doc(userId)
        .snapshots()
        .listen((snapshot) async {
      if (!snapshot.exists || snapshot.data() == null) return;
      final data = snapshot.data() as Map<String, dynamic>;
      await applyRemoteDataToHive(data);
    }, onError: (err) {
      debugPrint("CloudSyncService live sync error: $err");
    });
    debugPrint("CloudSyncService: Real-Time Live Sync active for user: $userId");
  }

  static void stopLiveSync() {
    _remoteSubscription?.cancel();
    _remoteSubscription = null;
  }

  /// Apply incoming Firestore updates into Hive boxes
  static Future<void> applyRemoteDataToHive(Map<String, dynamic> data) async {
    isSyncPaused = true;
    try {
      if (data['categories'] != null) {
        final box = await Hive.openBox<CategoryModel>('categories');
        await box.clear();
        for (var item in (data['categories'] as List)) {
          final cat = CategoryModel.fromJson(Map<String, dynamic>.from(item));
          await box.put(cat.id, cat);
        }
      }

      if (data['expenses'] != null) {
        final box = await Hive.openBox<ExpenseModel>('expenses');
        await box.clear();
        for (var item in (data['expenses'] as List)) {
          final exp = ExpenseModel.fromJson(Map<String, dynamic>.from(item));
          await box.put(exp.id, exp);
        }
      }

      if (data['accounts'] != null) {
        final box = await Hive.openBox<AccountModel>('accounts');
        await box.clear();
        for (var item in (data['accounts'] as List)) {
          final acc = AccountModel.fromJson(Map<String, dynamic>.from(item));
          await box.put(acc.id, acc);
        }
      }

      if (data['incomes'] != null) {
        final box = await Hive.openBox<IncomeModel>('incomeBox');
        await box.clear();
        for (var item in (data['incomes'] as List)) {
          final inc = IncomeModel.fromJson(Map<String, dynamic>.from(item));
          await box.put(inc.id, inc);
        }
      }

      if (data['borrowLends'] != null) {
        final box = await Hive.openBox<BorrowLendModel>('borrowLendBox');
        await box.clear();
        for (var item in (data['borrowLends'] as List)) {
          final bl = BorrowLendModel.fromJson(Map<String, dynamic>.from(item));
          await box.put(bl.id, bl);
        }
      }

      if (data['emis'] != null) {
        final box = await Hive.openBox<EmiTrackerModel>('emiTrackerBox');
        await box.clear();
        for (var item in (data['emis'] as List)) {
          final emi = EmiTrackerModel.fromJson(Map<String, dynamic>.from(item));
          await box.put(emi.id, emi);
        }
      }

      if (data['creditCardAccount'] != null) {
        final box = await Hive.openBox<CreditCardAccountModel>('credit_card_account_box');
        await box.clear();
        final cc = CreditCardAccountModel.fromJson(Map<String, dynamic>.from(data['creditCardAccount']));
        await box.put('supermoney_account', cc);
      }

      if (data['fdLots'] != null) {
        final box = await Hive.openBox<FdLotModel>('fd_lots_box');
        await box.clear();
        for (var item in (data['fdLots'] as List)) {
          final fd = FdLotModel.fromJson(Map<String, dynamic>.from(item));
          await box.put(fd.id, fd);
        }
      }

      if (data['transactions'] != null) {
        final box = await Hive.openBox<TransactionModel>('transactions_box');
        await box.clear();
        for (var item in (data['transactions'] as List)) {
          final tx = TransactionModel.fromJson(Map<String, dynamic>.from(item));
          await box.put(tx.id, tx);
        }
      }
      debugPrint("CloudSyncService: Real-Time updates successfully applied to Hive!");
    } catch (e) {
      debugPrint("CloudSyncService applyRemoteDataToHive error: $e");
    } finally {
      isSyncPaused = false;
    }
  }
}
