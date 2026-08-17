import 'package:flutter/foundation.dart';
import 'package:hive/hive.dart';
import '../../data/datasources/local_data_source.dart';
import '../../domain/repositories/transaction_repository.dart';
import '../../data/models/borrow_lend_model.dart';
import '../../data/models/borrow_lend_transaction_model.dart';
import '../../data/models/account_model.dart';
import '../../data/models/transaction_model.dart';
import '../../data/models/expense_model.dart';
import '../../data/models/income_model.dart';
import '../../features/credit_card/data/models/credit_card_account_model.dart';

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
        debugPrint('Error fixing BorrowLendTransactions: $e');
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
        debugPrint('Error migrating legacy database records: $e');
      }
    }

    // 3. Run Settings & Allocation V3 Migration: Ensure allocation & budget defaults are initialized safely
    final bool isMigrationV3Completed = settingsBox.get(
      'migration_v3_completed',
      defaultValue: false,
    );

    if (!isMigrationV3Completed) {
      try {
        final settings = await localDataSource.getSettings();
        if (settings != null) {
          bool needsUpdate = false;
          // Ensure auto allocation flag is set
          if (settings.enableAutoAllocation == null) {
            needsUpdate = true;
          }
          if (needsUpdate) {
            final updated = settings.copyWith(
              enableAutoAllocation: settings.enableAutoAllocation ?? true,
            );
            await localDataSource.saveSettings(updated);
          }
        }
        await settingsBox.put('migration_v3_completed', true);
      } catch (e) {
        debugPrint('Error running V3 migration: $e');
      }
    }

    // 4. Mark credit card migration flag as completed without seeding mock data
    await settingsBox.put('migration_credit_card_v1', true);

    // 5. Ensure existing stored credit card accounts are named 'Credit Card'
    try {
      if (await Hive.boxExists('credit_card_account_box')) {
        final ccBox = await Hive.openBox<CreditCardAccountModel>('credit_card_account_box');
        final ccAcc = ccBox.get('supermoney_account');
        if (ccAcc != null && ccAcc.name != 'Credit Card') {
          await ccBox.put(
            'supermoney_account',
            CreditCardAccountModel(
              id: ccAcc.id,
              name: 'Credit Card',
              creditLimit: ccAcc.creditLimit,
              availableCredit: ccAcc.availableCredit,
              usedCredit: ccAcc.usedCredit,
              cashbackPending: ccAcc.cashbackPending,
              cashbackAvailable: ccAcc.cashbackAvailable,
              cashbackRedeemed: ccAcc.cashbackRedeemed,
              lifetimeCashback: ccAcc.lifetimeCashback,
              statementDateDay: ccAcc.statementDateDay,
              dueDateDay: ccAcc.dueDateDay,
              initialCreditMigrated: ccAcc.initialCreditMigrated,
              lastUpdated: ccAcc.lastUpdated,
            ),
          );
        }
      }
      if (await Hive.boxExists('accounts_box')) {
        final accBox = await Hive.openBox<AccountModel>('accounts_box');
        final acc = accBox.get('supermoney');
        if (acc != null && acc.name != 'Credit Card') {
          await accBox.put(
            'supermoney',
            AccountModel(
              id: acc.id,
              name: 'Credit Card',
              openingBalance: acc.openingBalance,
            ),
          );
        }
      }
    } catch (e) {
      debugPrint('Error renaming credit card account in data fixer: $e');
    }

    // 6. Clean up false onboarding income and expense commitment records
    try {
      if (await Hive.boxExists('expenses')) {
        final expensesBox = await Hive.openBox<ExpenseModel>('expenses');
        final keysToRemove = <dynamic>[];
        for (var key in expensesBox.keys) {
          final exp = expensesBox.get(key);
          if (exp != null && exp.description.contains('(Recurring Monthly)')) {
            keysToRemove.add(key);
          }
        }
        for (var k in keysToRemove) {
          await expensesBox.delete(k);
        }
      }
      if (await Hive.boxExists('incomeBox')) {
        final incomeBox = await Hive.openBox<IncomeModel>('incomeBox');
        final keysToRemove = <dynamic>[];
        for (var key in incomeBox.keys) {
          final inc = incomeBox.get(key);
          if (inc != null && (inc.description.contains('(Monthly)') || inc.description.contains('(Weekly)') || inc.description.contains('(Biweekly)'))) {
            keysToRemove.add(key);
          }
        }
        for (var k in keysToRemove) {
          await incomeBox.delete(k);
        }
      }
      if (await Hive.boxExists('transactions_box')) {
        final txBox = await Hive.openBox<TransactionModel>('transactions_box');
        final keysToRemove = <dynamic>[];
        for (var key in txBox.keys) {
          final tx = txBox.get(key);
          if (tx != null && (tx.description.contains('(Recurring Monthly)') || (tx.type == 'income' && (tx.description.contains('(Monthly)') || tx.description.contains('(Weekly)') || tx.description.contains('(Biweekly)'))))) {
            keysToRemove.add(key);
          }
        }
        for (var k in keysToRemove) {
          await txBox.delete(k);
        }
      }
    } catch (e) {
      debugPrint('Error cleaning false onboarding records: $e');
    }

    // 7. Force resync balances across credit card & asset channels
    try {
      await transactionRepository.recalculateBalances();
    } catch (e) {
      debugPrint('Error resyncing balances in DataFixer: $e');
    }
  }
}
