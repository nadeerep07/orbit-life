import '../../domain/entities/transaction_item_entity.dart';
import '../../domain/repositories/transaction_repository.dart';
import '../datasources/local_data_source.dart';

class TransactionRepositoryImpl implements TransactionRepository {
  final LocalDataSource localDataSource;

  TransactionRepositoryImpl(this.localDataSource);

  @override
  Future<List<TransactionItemEntity>> getTransactionsByAccount(
    String accountId,
  ) async {
    final List<TransactionItemEntity> allTransactions = [];

    // 1. Incomes
    final incomes = await localDataSource.getIncomes();
    for (var i in incomes.where((e) => e.accountId == accountId)) {
      allTransactions.add(
        TransactionItemEntity(
          id: i.id,
          amount: i.amount,
          isCredit: true,
          categoryOrSource: i.source,
          date: i.date,
          description: i.description,
          moduleType: 'income',
          accountId: i.accountId,
        ),
      );
    }

    // 2. Expenses
    final expenses = await localDataSource.getExpenses();
    for (var e in expenses.where((exp) => exp.accountId == accountId)) {
      allTransactions.add(
        TransactionItemEntity(
          id: e.id,
          amount: e.amount,
          isCredit: false,
          categoryOrSource: 'Expense',
          date: e.date,
          description: e.description,
          moduleType: 'expense',
          accountId: e.accountId,
        ),
      );
    }

    // 3. Transfers
    final transfers = await localDataSource.getTransfers();
    for (var t in transfers) {
      if (t.fromAccountId == accountId) {
        allTransactions.add(
          TransactionItemEntity(
            id: t.id + '_out',
            amount: t.amount,
            isCredit: false,
            categoryOrSource: 'Transfer Out',
            date: t.date,
            description: t.description,
            moduleType: 'transfer',
            accountId: t.fromAccountId,
          ),
        );
      }
      if (t.toAccountId == accountId) {
        allTransactions.add(
          TransactionItemEntity(
            id: t.id + '_in',
            amount: t.amount,
            isCredit: true,
            categoryOrSource: 'Transfer In',
            date: t.date,
            description: t.description,
            moduleType: 'transfer',
            accountId: t.toAccountId,
          ),
        );
      }
    }

    // 4. Borrow & Lend
    final borrowLends = await localDataSource.getBorrowLends();
    for (var bl in borrowLends) {
      // Main entry
      if (bl.accountId == accountId) {
        // 'lent': money went OUT of your account → Debit
        // 'borrowed': money came IN to your account → Credit
        final bool isCredit = bl.type == 'borrowed';
        allTransactions.add(
          TransactionItemEntity(
            id: bl.id,
            amount: bl.amount,
            isCredit: isCredit,
            categoryOrSource: bl.type == 'lent'
                ? 'Lent to ${bl.personName}'
                : 'Borrowed from ${bl.personName}',
            date: bl.date,
            description: bl.note,
            moduleType: 'borrow_lend',
            accountId: bl.accountId,
          ),
        );
      }

      // Partial payment transactions
      for (var tx in bl.transactions) {
        if (tx.accountId == accountId) {
          // 'received': borrower paid back → Credit (money comes back to you)
          // 'repaid': you repaid the lender → Debit (money leaves your account)
          final bool isCredit = tx.type == 'received';
          allTransactions.add(
            TransactionItemEntity(
              id: tx.id,
              amount: tx.amount,
              isCredit: isCredit,
              categoryOrSource: tx.type == 'received'
                  ? 'Received from ${bl.personName}'
                  : 'Repaid to ${bl.personName}',
              date: tx.date,
              description: '',
              moduleType: 'borrow_lend',
              accountId: tx.accountId,
            ),
          );
        }
      }
    }

    // 5. Investments
    final investments = await localDataSource.getInvestments();
    for (var inv in investments.where((e) => e.accountId == accountId)) {
      allTransactions.add(
        TransactionItemEntity(
          id: inv.id,
          amount: inv.investedAmount,
          isCredit: false, // Money out of account → Debit
          categoryOrSource: 'Investment - ${inv.name}',
          date: inv.date,
          description: inv.notes,
          moduleType: 'investment',
          accountId: inv.accountId,
        ),
      );
    }

    // 6. EMI / Pay Later — only show payments made, NOT the initial loan credit
    final emis = await localDataSource.getEmis();
    for (var emi in emis.where((e) => e.accountId == accountId)) {
      if (!emi.isPayLater && emi.paidMonths > 0) {
        // Each paid installment is a Debit from the account
        for (int i = 0; i < emi.paidMonths; i++) {
          final paymentDate = DateTime(
            emi.startDate.year,
            emi.startDate.month + i + 1,
            emi.startDate.day,
          );
          allTransactions.add(
            TransactionItemEntity(
              id: '${emi.id}_payment_$i',
              amount: emi.monthlyEmi,
              isCredit: false,
              categoryOrSource: 'EMI - ${emi.title}',
              date: paymentDate,
              description: 'Installment ${i + 1} of ${emi.totalMonths}',
              moduleType: 'emi',
              accountId: emi.accountId,
            ),
          );
        }
      } else if (emi.isPayLater && emi.isPaid) {
        allTransactions.add(
          TransactionItemEntity(
            id: '${emi.id}_paid',
            amount: emi.totalAmount,
            isCredit: false,
            categoryOrSource: 'Pay Later - ${emi.provider}',
            date: emi.dueDate ?? DateTime.now(),
            description: 'Settled',
            moduleType: 'emi',
            accountId: emi.accountId,
          ),
        );
      }
    }

    // Sort newest to oldest
    allTransactions.sort((a, b) => b.date.compareTo(a.date));

    return allTransactions;
  }
}
