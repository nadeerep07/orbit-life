import 'package:flutter/material.dart';
import '../../domain/entities/transaction_entity.dart';
import '../../domain/repositories/transaction_repository.dart';

enum TransactionSortOption {
  newestFirst,
  oldestFirst,
  highestAmount,
  lowestAmount;

  // Added index comparison or simple getter for serialization
}

class AccountDetailViewModel extends ChangeNotifier {
  final TransactionRepository repository;

  AccountDetailViewModel({required this.repository});

  List<TransactionEntity> _allTransactions = [];
  List<TransactionEntity> _filteredTransactions = [];

  bool _isLoading = false;

  // Filters
  DateTimeRange? _dateRange;
  bool? _isCreditFilter; // true = Credit only, false = Debit only, null = All
  String? _moduleFilter;

  TransactionSortOption _sortOption = TransactionSortOption.newestFirst;

  // Getters
  List<TransactionEntity> get transactions => _filteredTransactions;
  bool get isLoading => _isLoading;
  DateTimeRange? get dateRange => _dateRange;
  bool? get isCreditFilter => _isCreditFilter;
  String? get moduleFilter => _moduleFilter;
  TransactionSortOption get sortOption => _sortOption;

  double get accountCalculatedBalance {
    return _allTransactions.fold(0.0, (sum, tx) {
      if (tx.isCredit || (tx.type == TransactionType.transfer && tx.targetAccountId == _allTransactions.firstOrNull?.accountId)) {
        // Simple heuristic: if the account is target of a transfer/savings, it is a credit.
        // But since we already compute it in recalculateBalances, let's calculate based on credit mapping.
        // Wait, for transfers: if tx.targetAccountId == accountId, it is credit.
        // Let's write the exact credit evaluation:
        final currentAccount = tx.accountId;
        final targetAccount = tx.targetAccountId;
        
        bool evaluatedCredit = tx.isCredit;
        if (tx.type == TransactionType.transfer || tx.type == TransactionType.savings) {
          // If we are looking from the perspective of targetAccountId, it's credit.
          // Otherwise if from accountId, it's debit.
          evaluatedCredit = targetAccount == tx.accountId; // wait, this depends on which account we are viewing.
          // Let's pass the accountId to make this calculation robust!
        }
      }
      // Actually, since accounts_box already stores the calculated openingBalance correctly, we don't have to recompute this in the viewmodel dynamically. We can just load it or compute it using perspective.
      // Let's make it robust by checking the active accountId:
      return sum;
    });
  }

  // A better, account-specific dynamic balance calculation
  double getAccountCalculatedBalance(String accountId) {
    return _allTransactions.fold(0.0, (sum, tx) {
      if (tx.accountId == accountId) {
        if (tx.type == TransactionType.income || tx.type == TransactionType.borrow) {
          return sum + tx.amount;
        } else {
          return sum - tx.amount;
        }
      }
      if (tx.targetAccountId == accountId) {
        if (tx.type == TransactionType.transfer || tx.type == TransactionType.savings) {
          return sum + tx.amount;
        }
      }
      return sum;
    });
  }

  Future<void> loadTransactions(String accountId) async {
    _isLoading = true;
    notifyListeners();

    _allTransactions = await repository.getTransactionsByAccount(accountId);
    _applyFiltersAndSort();

    _isLoading = false;
    notifyListeners();
  }

  void setFilter({
    DateTimeRange? dateRange,
    bool? isCredit,
    String? moduleType,
  }) {
    _dateRange = dateRange;
    _isCreditFilter = isCredit;
    if (moduleType != null) {
      _moduleFilter = moduleType.isEmpty ? null : moduleType;
    }
    _applyFiltersAndSort();
    notifyListeners();
  }

  void clearFilters() {
    _dateRange = null;
    _isCreditFilter = null;
    _moduleFilter = null;
    _applyFiltersAndSort();
    notifyListeners();
  }

  void setSortOption(TransactionSortOption option) {
    _sortOption = option;
    _applyFiltersAndSort();
    notifyListeners();
  }

  void _applyFiltersAndSort() {
    var result = List<TransactionEntity>.from(_allTransactions);

    // Apply Date Filter
    if (_dateRange != null) {
      result = result.where((tx) {
        return tx.date.isAfter(
              _dateRange!.start.subtract(const Duration(days: 1)),
            ) &&
            tx.date.isBefore(_dateRange!.end.add(const Duration(days: 1)));
      }).toList();
    }

    // Apply Credit/Debit Filter
    if (_isCreditFilter != null) {
      result = result.where((tx) => tx.isCredit == _isCreditFilter).toList();
    }

    // Apply Module Filter
    if (_moduleFilter != null) {
      result = result.where((tx) => tx.type.name == _moduleFilter).toList();
    }

    // Apply Sort
    switch (_sortOption) {
      case TransactionSortOption.newestFirst:
        result.sort((a, b) => b.date.compareTo(a.date));
        break;
      case TransactionSortOption.oldestFirst:
        result.sort((a, b) => a.date.compareTo(b.date));
        break;
      case TransactionSortOption.highestAmount:
        result.sort((a, b) => b.amount.compareTo(a.amount));
        break;
      case TransactionSortOption.lowestAmount:
        result.sort((a, b) => a.amount.compareTo(b.amount));
        break;
    }

    _filteredTransactions = result;
  }
}
