import '../../domain/entities/transaction_entity.dart';
import '../../domain/repositories/transaction_repository.dart';
import '../datasources/local_data_source.dart';
import '../models/transaction_model.dart';
import '../models/account_model.dart';
import '../models/savings_model.dart';
import '../../features/credit_card/data/datasources/credit_card_local_data_source.dart';
import '../../features/credit_card/data/models/credit_card_account_model.dart';

class TransactionRepositoryImpl implements TransactionRepository {
  final LocalDataSource localDataSource;
  final CreditCardLocalDataSource? creditCardLocalDataSource;

  TransactionRepositoryImpl(
    this.localDataSource, {
    this.creditCardLocalDataSource,
  });

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
    await _applyCreditCardTransaction(transaction, isReversal: false);
    await recalculateBalances();
  }

  @override
  Future<void> updateTransaction(TransactionEntity transaction) async {
    final models = await localDataSource.getTransactions();
    final existing = models.where((m) => m.id == transaction.id).firstOrNull;
    if (existing != null) {
      await _applyCreditCardTransaction(existing.toEntity(), isReversal: true);
    }
    final model = TransactionModel.fromEntity(transaction);
    await localDataSource.addTransaction(model); // Put overwrites in Hive
    await _applyCreditCardTransaction(transaction, isReversal: false);
    await recalculateBalances();
  }

  @override
  Future<void> deleteTransaction(String transactionId) async {
    final models = await localDataSource.getTransactions();
    final toDelete = models.where((m) => m.id == transactionId).firstOrNull;
    if (toDelete != null) {
      await _applyCreditCardTransaction(toDelete.toEntity(), isReversal: true);
    }
    await localDataSource.deleteTransaction(transactionId);
    await recalculateBalances();
  }

  @override
  Future<void> deleteTransactionsByReference(String referenceId) async {
    final models = await localDataSource.getTransactions();
    final toDelete = models.where((m) => m.referenceId == referenceId).toList();
    for (var m in toDelete) {
      await _applyCreditCardTransaction(m.toEntity(), isReversal: true);
      await localDataSource.deleteTransaction(m.id);
    }
    await recalculateBalances();
  }

  Future<void> _applyCreditCardTransaction(TransactionEntity tx, {required bool isReversal}) async {
    if (creditCardLocalDataSource == null) return;
    final cc = await creditCardLocalDataSource!.getCreditCardAccount();
    if (cc == null) return;

    double delta = 0.0;
    if (tx.accountId == cc.id) {
      if (tx.type == TransactionType.income || tx.type == TransactionType.borrow) {
        delta -= tx.amount;
      } else {
        delta += tx.amount;
      }
    }
    if (tx.targetAccountId == cc.id) {
      if (tx.type == TransactionType.transfer ||
          tx.type == TransactionType.savings ||
          tx.type == TransactionType.income) {
        delta -= tx.amount;
      }
    }

    if (delta == 0.0) return;
    if (isReversal) delta = -delta;

    final usedCredit = (cc.usedCredit + delta).clamp(0.0, cc.creditLimit);
    final availableCredit = (cc.creditLimit - usedCredit).clamp(0.0, cc.creditLimit);

    final updatedCc = CreditCardAccountModel(
      id: cc.id,
      name: cc.name,
      creditLimit: cc.creditLimit,
      availableCredit: availableCredit,
      usedCredit: usedCredit,
      cashbackPending: cc.cashbackPending,
      cashbackAvailable: cc.cashbackAvailable,
      cashbackRedeemed: cc.cashbackRedeemed,
      lifetimeCashback: cc.lifetimeCashback,
      statementDateDay: cc.statementDateDay,
      dueDateDay: cc.dueDateDay,
      initialCreditMigrated: cc.initialCreditMigrated,
      lastUpdated: DateTime.now(),
    );
    await creditCardLocalDataSource!.saveCreditCardAccount(updatedCc);

    final accounts = await localDataSource.getAccounts();
    final superMoneyAcc = accounts.where((a) => a.id == cc.id).firstOrNull;
    if (superMoneyAcc != null) {
      final updatedSuperMoney = AccountModel(
        id: superMoneyAcc.id,
        name: superMoneyAcc.name,
        openingBalance: availableCredit,
      );
      await localDataSource.updateAccount(updatedSuperMoney);
    }
  }

  @override
  Future<void> recalculateBalances() async {
    // 1. Fetch all transactions and accounts
    final transactions = await getAllTransactions();
    final accounts = await localDataSource.getAccounts();

    // 2. Compute dynamic balances for accounts
    for (var acc in accounts) {
      if (acc.id == 'supermoney') continue; // Credit card balance handled separately

      double balance = 0.0;
      for (var tx in transactions) {
        if (tx.accountId == acc.id) {
          if (tx.type == TransactionType.income ||
              tx.type == TransactionType.borrow) {
            balance += tx.amount;
          } else {
            balance -= tx.amount;
          }
        }
        if (tx.targetAccountId == acc.id) {
          if (tx.type == TransactionType.transfer ||
              tx.type == TransactionType.savings) {
            balance += tx.amount;
          }
        }
      }

      final updatedAcc = AccountModel(
        id: acc.id,
        name: acc.name,
        openingBalance: balance,
      );
      await localDataSource.updateAccount(updatedAcc);
    }

    // 3. Ensure Credit Card account representation matches available credit
    if (creditCardLocalDataSource != null) {
      final ccAccountModel = await creditCardLocalDataSource!.getCreditCardAccount();
      if (ccAccountModel != null) {
        final superMoneyAcc = accounts.where((a) => a.id == ccAccountModel.id).firstOrNull;
        if (superMoneyAcc != null && superMoneyAcc.openingBalance != ccAccountModel.availableCredit) {
          final updatedSuperMoney = AccountModel(
            id: superMoneyAcc.id,
            name: superMoneyAcc.name,
            openingBalance: ccAccountModel.availableCredit,
          );
          await localDataSource.updateAccount(updatedSuperMoney);
        }
      }
    }

    // 4. Compute dynamic balance for savings
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
