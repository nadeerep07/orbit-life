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
    try {
      Hive.box<AccountModel>('accounts').watch().listen((event) {
        loadAccounts(silent: true);
      });
    } catch (_) {}
    try {
      if (Hive.isBoxOpen('credit_card_account_box')) {
        Hive.box('credit_card_account_box').watch().listen((event) {
          loadAccounts(silent: true);
        });
      }
    } catch (_) {}
  }

  Future<void> loadAccounts({bool silent = false}) async {
    if (!silent) {
      _isLoading = true;
      if (hasListeners) {
        notifyListeners();
      }
    }

    _accounts = await _accountRepository.getAccounts();

    // Sync supermoney credit card available credit if present
    try {
      if (await Hive.boxExists('credit_card_account_box')) {
        final ccBox = await Hive.openBox('credit_card_account_box');
        final ccAcc = ccBox.get('supermoney_account');
        if (ccAcc != null) {
          final double ccAvailable = (ccAcc.availableCredit as num).toDouble();
          final idx = _accounts.indexWhere((acc) => acc.id == 'supermoney');
          if (idx != -1 && _accounts[idx].openingBalance != ccAvailable) {
            final updated = AccountEntity(
              id: 'supermoney',
              name: 'Credit Card',
              openingBalance: ccAvailable,
            );
            await _accountRepository.updateAccount(updated);
            _accounts[idx] = updated;
          }
        }
      }
    } catch (_) {}

    // Ensure supermoney account displays as 'Credit Card'
    final superMoneyIdx = _accounts.indexWhere((acc) => acc.id == 'supermoney');
    if (superMoneyIdx != -1 && _accounts[superMoneyIdx].name != 'Credit Card') {
      final updated = AccountEntity(
        id: _accounts[superMoneyIdx].id,
        name: 'Credit Card',
        openingBalance: _accounts[superMoneyIdx].openingBalance,
      );
      await _accountRepository.updateAccount(updated);
      _accounts[superMoneyIdx] = updated;
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

  List<AccountEntity> get liquidAccounts {
    return _accounts.where((acc) {
      final nameLower = acc.name.toLowerCase();
      return acc.id != 'supermoney' &&
          !nameLower.contains('credit card') &&
          !nameLower.contains('supermoney') &&
          !nameLower.contains('super money');
    }).toList();
  }

  double get totalLiquidBalance {
    return liquidAccounts.fold(0.0, (sum, acc) => sum + acc.openingBalance);
  }

  double get totalBalance {
    // Only count actual liquid bank & cash balances for Safe Daily Limit and Net Balance!
    return totalLiquidBalance;
  }
}
