import 'package:hive/hive.dart';
import '../../data/datasources/local_data_source.dart';
import '../../domain/repositories/transaction_repository.dart';
import '../../data/models/borrow_lend_model.dart';
import '../../data/models/borrow_lend_transaction_model.dart';
import '../../data/models/account_model.dart';
import '../../data/models/transaction_model.dart';

class DataFixer {
  static Future<void> runFixes(
    LocalDataSource localDataSource,
    TransactionRepository transactionRepository,
  ) async {
    final settingsBox = await Hive.openBox('settingsBox');

    // 1. Run Legacy V1 Fixes (fixes orphaned partial payment accounts)
    final bool hasRunFixes = settingsBox.get(
      'data_fixer_v1',
      defaultValue: false,
    );

    if (!hasRunFixes) {
      try {
        final borrowLends = await localDataSource.getBorrowLends();
        bool anyFixed = false;

        for (var bl in borrowLends) {
          if (bl.accountId != 'cash') {
            for (int i = 0; i < bl.transactions.length; i++) {
              if (bl.transactions[i].accountId == 'cash') {
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
          final box = await Hive.openBox<BorrowLendModel>('borrowLendBox');
          for (var bl in borrowLends) {
            await box.put(bl.id, bl);
          }
        }
      } catch (e) {
        print('Error fixing BorrowLendTransactions: $e');
      }
      await settingsBox.put('data_fixer_v1', true);
    }

    // 2. Run Ledger V2 Migration: compile legacy tables to the Unified Transaction log
    final bool isMigrationV2Completed = settingsBox.get(
      'migration_v2_completed',
      defaultValue: false,
    );

    if (!isMigrationV2Completed) {
      try {
        // 1. Incomes
        final incomes = await localDataSource.getIncomes();
        for (var i in incomes) {
          final tx = TransactionModel(
            id: i.id,
            amount: i.amount,
            type: 'income',
            accountId: i.accountId,
            categoryOrSource: i.source,
            date: i.date,
            description: i.description,
            referenceId: i.id,
          );
          await localDataSource.addTransaction(tx);
        }

        // 2. Expenses
        final expenses = await localDataSource.getExpenses();
        for (var e in expenses) {
          final tx = TransactionModel(
            id: e.id,
            amount: e.amount,
            type: 'expense',
            accountId: e.accountId,
            categoryOrSource: 'Expense',
            date: e.date,
            description: e.description,
            referenceId: e.id,
          );
          await localDataSource.addTransaction(tx);
        }

        // 3. Transfers
        final transfers = await localDataSource.getTransfers();
        for (var t in transfers) {
          final tx = TransactionModel(
            id: t.id,
            amount: t.amount,
            type: 'transfer',
            accountId: t.fromAccountId,
            targetAccountId: t.toAccountId,
            categoryOrSource: 'Transfer',
            date: t.date,
            description: t.description,
            referenceId: t.id,
          );
          await localDataSource.addTransaction(tx);
        }

        // 4. Borrow & Lend
        final borrowLends = await localDataSource.getBorrowLends();
        for (var bl in borrowLends) {
          final tx = TransactionModel(
            id: bl.id,
            amount: bl.amount,
            type: bl.type == 'lent' ? 'lend' : 'borrow',
            accountId: bl.accountId,
            categoryOrSource: bl.type == 'lent'
                ? 'Lent to ${bl.personName}'
                : 'Borrowed from ${bl.personName}',
            date: bl.date,
            description: bl.note,
            referenceId: bl.id,
          );
          await localDataSource.addTransaction(tx);

          for (var p in bl.transactions) {
            final pTx = TransactionModel(
              id: p.id,
              amount: p.amount,
              type: bl.type == 'lent' ? 'income' : 'expense',
              accountId: p.accountId,
              categoryOrSource: p.type == 'received'
                  ? 'Repayment received from ${bl.personName}'
                  : 'Repaid to ${bl.personName}',
              date: p.date,
              description: 'Partial repayment',
              referenceId: bl.id,
            );
            await localDataSource.addTransaction(pTx);
          }
        }

        // 5. Investments
        final investments = await localDataSource.getInvestments();
        for (var inv in investments) {
          final tx = TransactionModel(
            id: inv.id,
            amount: inv.investedAmount,
            type: 'investment',
            accountId: inv.accountId,
            categoryOrSource: 'Investment - ${inv.name}',
            date: inv.date,
            description: inv.notes,
            referenceId: inv.id,
          );
          await localDataSource.addTransaction(tx);
        }

        // 6. EMIs
        final emis = await localDataSource.getEmis();
        for (var emi in emis) {
          if (!emi.isPayLater && emi.paidMonths > 0) {
            for (int i = 0; i < emi.paidMonths; i++) {
              final paymentDate = DateTime(
                emi.startDate.year,
                emi.startDate.month + i + 1,
                emi.startDate.day,
              );
              final tx = TransactionModel(
                id: '${emi.id}_payment_$i',
                amount: emi.monthlyEmi,
                type: 'emi',
                accountId: emi.accountId,
                categoryOrSource: 'EMI - ${emi.title}',
                date: paymentDate,
                description: 'Installment ${i + 1} of ${emi.totalMonths}',
                referenceId: emi.id,
              );
              await localDataSource.addTransaction(tx);
            }
          } else if (emi.isPayLater && emi.isPaid) {
            final tx = TransactionModel(
              id: '${emi.id}_paid',
              amount: emi.totalAmount,
              type: 'emi',
              accountId: emi.accountId,
              categoryOrSource: 'Pay Later - ${emi.provider}',
              date: emi.dueDate ?? DateTime.now(),
              description: 'Settled',
              referenceId: emi.id,
            );
            await localDataSource.addTransaction(tx);
          }
        }

        // 7. Run recalculateBalances to build exact dynamic ledger balances
        await transactionRepository.recalculateBalances();

        // 8. Mark migration complete
        await settingsBox.put('migration_v2_completed', true);
      } catch (e) {
        print('Error migrating legacy database records: $e');
      }
    }
  }
}
