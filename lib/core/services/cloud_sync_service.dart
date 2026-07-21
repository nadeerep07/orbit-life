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
      debugPrint("CloudSyncService: Auto-sync completed.");
    } catch (e) {
      debugPrint("CloudSyncService error: $e");
    }
  }
}
