import 'package:flutter/material.dart';
import '../../domain/entities/savings_entity.dart';
import '../../domain/entities/transaction_entity.dart';
import '../../domain/repositories/savings_repository.dart';
import '../../domain/repositories/transaction_repository.dart';

import 'package:hive/hive.dart';
import '../../data/models/savings_model.dart';

class SavingsViewModel extends ChangeNotifier {
  final SavingsRepository _savingsRepository;
  final TransactionRepository _transactionRepository;

  SavingsEntity? _savings;
  SavingsEntity? get savings => _savings;

  bool _isLoading = false;
  bool get isLoading => _isLoading;

  SavingsViewModel(this._savingsRepository, this._transactionRepository) {
    Hive.box<SavingsModel>('savingsBox').watch().listen((event) {
      loadSavings(silent: true);
    });
  }

  Future<void> loadSavings({bool silent = false}) async {
    if (!silent) {
      _isLoading = true;
      notifyListeners();
    }

    _savings = await _savingsRepository.getSavings();
    if (_savings == null) {
      _savings = const SavingsEntity(id: 'main_savings', totalAdded: 0, totalDebited: 0);
      await _savingsRepository.updateSavings(_savings!);
    }

    _isLoading = false;
    notifyListeners();
  }

  Future<void> addToSavings(double amount, String accountId) async {
    final tx = TransactionEntity(
      id: 'savings_add_${DateTime.now().millisecondsSinceEpoch}',
      amount: amount,
      type: TransactionType.savings,
      accountId: accountId,
      targetAccountId: 'savings',
      categoryOrSource: 'Add to Savings',
      date: DateTime.now(),
      description: 'Transfer to savings pool',
      referenceId: 'savings_transfer',
    );
    await _transactionRepository.addTransaction(tx);
    await loadSavings();
  }

  Future<void> deductFromSavings(double amount) async {
    // No-op. Recalculation is automatically handled by the unified Transaction Engine
    // when an expense is created with accountId = 'savings'.
    await loadSavings();
  }
}
