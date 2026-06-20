import 'package:flutter/material.dart';
import '../../domain/entities/account_entity.dart';
import '../../domain/entities/transaction_entity.dart';
import '../../domain/repositories/account_repository.dart';
import '../../domain/repositories/transaction_repository.dart';

import 'package:hive/hive.dart';
import '../../data/models/account_model.dart';

class AccountsViewModel extends ChangeNotifier {
  final AccountRepository _accountRepository;
  final TransactionRepository _transactionRepository;

  List<AccountEntity> _accounts = [];
  List<AccountEntity> get accounts => _accounts;

  bool _isLoading = false;
  bool get isLoading => _isLoading;

  AccountsViewModel(this._accountRepository, this._transactionRepository) {
    Hive.box<AccountModel>('accounts').watch().listen((event) {
      loadAccounts(silent: true);
    });
  }

  Future<void> loadAccounts({bool silent = false}) async {
    if (!silent) {
      _isLoading = true;
      notifyListeners();
    }

    _accounts = await _accountRepository.getAccounts();

    // Setup predefined accounts if none exist
    if (_accounts.isEmpty) {
      final defaults = [
        const AccountEntity(id: 'sbi', name: 'SBI', openingBalance: 0),
        const AccountEntity(id: 'hdfc', name: 'HDFC', openingBalance: 0),
        const AccountEntity(
          id: 'airtel',
          name: 'Airtel Payment Bank',
          openingBalance: 0,
        ),
        const AccountEntity(
          id: 'supermoney',
          name: 'Super Money Credit Card',
          openingBalance: 0,
        ),
        const AccountEntity(id: 'cash', name: 'Cash', openingBalance: 0),
      ];

      for (var acc in defaults) {
        await _accountRepository.addAccount(acc);
      }
      _accounts = defaults;
    }

    _isLoading = false;
    notifyListeners();
  }

  Future<void> updateAccountBalance(String id, double difference) async {
    final accountIndex = _accounts.indexWhere((acc) => acc.id == id);
    if (accountIndex != -1) {
      // Log this as a balance adjustment transaction so the audit history is correct
      final tx = TransactionEntity(
        id: 'adj_${DateTime.now().millisecondsSinceEpoch}',
        amount: difference.abs(),
        type: difference > 0 ? TransactionType.income : TransactionType.expense,
        accountId: id,
        categoryOrSource: 'Balance Adjustment',
        date: DateTime.now(),
        description: 'Manual balance adjustment',
        referenceId: 'manual_adjustment',
      );
      await _transactionRepository.addTransaction(tx);
      await loadAccounts();
    }
  }

  double get totalBalance {
    return _accounts.fold(0.0, (sum, acc) => sum + acc.openingBalance);
  }
}
