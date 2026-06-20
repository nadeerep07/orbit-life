import '../../domain/entities/transaction_entity.dart';
import '../../domain/repositories/transaction_repository.dart';
import '../datasources/local_data_source.dart';
import '../models/transaction_model.dart';
import '../models/account_model.dart';
import '../models/savings_model.dart';

class TransactionRepositoryImpl implements TransactionRepository {
  final LocalDataSource localDataSource;

  TransactionRepositoryImpl(this.localDataSource);

  @override
  Future<List<TransactionEntity>> getAllTransactions() async {
    final models = await localDataSource.getTransactions();
    return models.map((m) => m.toEntity()).toList();
  }

  @override
  Future<List<TransactionEntity>> getTransactionsByAccount(
    String accountId,
  ) async {
    final all = await getAllTransactions();
    return all.where((t) {
      return t.accountId == accountId || t.targetAccountId == accountId;
    }).toList();
  }

  @override
  Future<void> addTransaction(TransactionEntity transaction) async {
    final model = TransactionModel.fromEntity(transaction);
    await localDataSource.addTransaction(model);
    await recalculateBalances();
  }

  @override
  Future<void> updateTransaction(TransactionEntity transaction) async {
    final model = TransactionModel.fromEntity(transaction);
    await localDataSource.addTransaction(model); // Put overwrites in Hive
    await recalculateBalances();
  }

  @override
  Future<void> deleteTransaction(String transactionId) async {
    await localDataSource.deleteTransaction(transactionId);
    await recalculateBalances();
  }

  @override
  Future<void> deleteTransactionsByReference(String referenceId) async {
    final models = await localDataSource.getTransactions();
    final toDelete = models.where((m) => m.referenceId == referenceId).toList();
    for (var m in toDelete) {
      await localDataSource.deleteTransaction(m.id);
    }
    await recalculateBalances();
  }

  @override
  Future<void> recalculateBalances() async {
    // 1. Fetch all transactions and accounts
    final transactions = await getAllTransactions();
    final accounts = await localDataSource.getAccounts();

    // 2. Compute dynamic balances for accounts
    for (var acc in accounts) {
      double balance = 0.0;
      for (var tx in transactions) {
        if (tx.accountId == acc.id) {
          // Money leaving account (Debit) or coming in as Income/Borrow (Credit)
          if (tx.type == TransactionType.income ||
              tx.type == TransactionType.borrow) {
            balance += tx.amount;
          } else {
            balance -= tx.amount;
          }
        }
        if (tx.targetAccountId == acc.id) {
          // Money coming into account from a transfer (Credit)
          if (tx.type == TransactionType.transfer ||
              tx.type == TransactionType.savings) {
            balance += tx.amount;
          }
        }
      }

      // Update the account balance
      final updatedAcc = AccountModel(
        id: acc.id,
        name: acc.name,
        openingBalance: balance,
      );
      await localDataSource.updateAccount(updatedAcc);
    }

    // 3. Compute dynamic balance for savings
    double totalAdded = 0.0;
    double totalDebited = 0.0;
    for (var tx in transactions) {
      if (tx.targetAccountId == 'savings') {
        totalAdded += tx.amount;
      }
      if (tx.accountId == 'savings') {
        totalDebited += tx.amount;
      }
    }

    final updatedSavings = SavingsModel(
      id: 'main_savings',
      totalAdded: totalAdded,
      totalDebited: totalDebited,
    );
    await localDataSource.updateSavings(updatedSavings);
  }
}
