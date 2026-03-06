import 'package:hive/hive.dart';
import '../../data/datasources/local_data_source.dart';
import '../../domain/repositories/transaction_repository.dart';
import '../../data/models/borrow_lend_model.dart';
import '../../data/models/borrow_lend_transaction_model.dart';
import '../../data/models/account_model.dart';

class DataFixer {
  static Future<void> runFixes(
    LocalDataSource localDataSource,
    TransactionRepository transactionRepository,
  ) async {
    final settingsBox = await Hive.openBox('settingsBox');
    final bool hasRunFixes = settingsBox.get(
      'data_fixer_v1',
      defaultValue: false,
    );

    if (hasRunFixes) return; // Only run once

    // 1. Fix orphaned BorrowLendTransaction accountIds
    // Previously, adding a partial payment didn't specify accountId, defaulting to 'cash'.
    try {
      final borrowLends = await localDataSource.getBorrowLends();
      bool anyFixed = false;

      for (var bl in borrowLends) {
        if (bl.accountId != 'cash') {
          for (int i = 0; i < bl.transactions.length; i++) {
            if (bl.transactions[i].accountId == 'cash') {
              // Fix it to match the parent account
              bl.transactions[i] = BorrowLendTransactionModel(
                id: bl.transactions[i].id,
                amount: bl.transactions[i].amount,
                type: bl.transactions[i].type,
                date: bl.transactions[i].date,
                accountId: bl.accountId,
              );
              anyFixed = true;
            }
          }
        }
      }

      if (anyFixed) {
        // Save the fixed models back to Hive
        final box = await Hive.openBox<BorrowLendModel>('borrow_lends_box');
        for (var bl in borrowLends) {
          await box.put(bl.id, bl);
        }
      }
    } catch (e) {
      print('Error fixing BorrowLendTransactions: $e');
    }

    // 2. Resync all account balances from the true ledger
    // Because balances mutated incrementally over time, bugs caused drift.
    // TransactionRepository builds the exact true ledger from all modules.
    try {
      final accounts = await localDataSource.getAccounts();

      for (var acc in accounts) {
        final txs = await transactionRepository.getTransactionsByAccount(
          acc.id,
        );

        double actualBalance = 0;
        for (var tx in txs) {
          if (tx.isCredit) {
            actualBalance += tx.amount;
          } else {
            actualBalance -= tx.amount;
          }
        }

        // Apply true balance over the existing incorrect openingBalance
        if (acc.openingBalance != actualBalance) {
          final fixedAcc = AccountModel(
            id: acc.id,
            name: acc.name,
            openingBalance: actualBalance,
          );
          await localDataSource.updateAccount(fixedAcc);
        }
      }
    } catch (e) {
      print('Error resyncing account balances: $e');
    }

    await settingsBox.put('data_fixer_v1', true);
  }
}
