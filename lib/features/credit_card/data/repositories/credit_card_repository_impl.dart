import 'package:uuid/uuid.dart';
import '../../../../domain/entities/transaction_entity.dart';
import '../../../../domain/repositories/transaction_repository.dart';
import '../../domain/entities/credit_card_account_entity.dart';
import '../../domain/entities/fd_lot_entity.dart';
import '../../domain/entities/credit_card_statement_entity.dart';
import '../../domain/entities/cashback_transaction_entity.dart';
import '../../domain/repositories/credit_card_repository.dart';
import '../datasources/credit_card_local_data_source.dart';
import '../models/credit_card_account_model.dart';
import '../models/fd_lot_model.dart';
import '../models/credit_card_statement_model.dart';
import '../models/cashback_transaction_model.dart';

class CreditCardRepositoryImpl implements CreditCardRepository {
  final CreditCardLocalDataSource localDataSource;
  final TransactionRepository transactionRepository;
  final Uuid _uuid = const Uuid();

  CreditCardRepositoryImpl({
    required this.localDataSource,
    required this.transactionRepository,
  });

  @override
  Future<CreditCardAccountEntity> getCreditCardAccount() async {
    final model = await localDataSource.getCreditCardAccount();
    if (model == null) {
      final initial = CreditCardAccountEntity.zero();
      await saveCreditCardAccount(initial);
      return initial;
    }
    return model.toEntity();
  }

  @override
  Future<void> saveCreditCardAccount(CreditCardAccountEntity account) async {
    final model = CreditCardAccountModel.fromEntity(account);
    await localDataSource.saveCreditCardAccount(model);
  }

  @override
  Stream<void> watchCreditCardAccount() {
    return localDataSource.watchCreditCardAccount();
  }

  @override
  Future<List<FdLotEntity>> getFdLots() async {
    final models = await localDataSource.getFdLots();
    final entities = models.map((m) => m.toEntity()).toList();

    // Perform interest compounding calculations dynamically
    final updatedList = <FdLotEntity>[];
    for (var fd in entities) {
      if (fd.status == FdStatus.active || fd.status == FdStatus.locked) {
        final currentCalculatedVal = fd.calculateCurrentValAt(DateTime.now());
        // Check for maturity auto-renewal
        if (DateTime.now().isAfter(fd.maturityDate) && fd.autoRenew) {
          final renewedHistory = List<DateTime>.from(fd.renewHistory)..add(fd.maturityDate);
          final renewed = fd.copyWith(
            depositDate: DateTime.now(),
            maturityDate: DateTime.now().add(const Duration(days: 365)),
            currentValue: currentCalculatedVal,
            status: FdStatus.renewed,
            renewHistory: renewedHistory,
          );
          await localDataSource.updateFdLot(FdLotModel.fromEntity(renewed));
          updatedList.add(renewed);
        } else {
          final updated = fd.copyWith(currentValue: currentCalculatedVal);
          updatedList.add(updated);
        }
      } else {
        updatedList.add(fd);
      }
    }
    return updatedList;
  }

  @override
  Future<FdLotEntity> depositFd({
    required double amount,
    required DateTime depositDate,
    required String remarks,
    String? sourceAccountId,
  }) async {
    final fdId = 'fd_${_uuid.v4()}';
    final lockUntil = depositDate.add(const Duration(days: 7));
    final maturityDate = depositDate.add(const Duration(days: 365));

    final newLot = FdLotEntity(
      id: fdId,
      principal: amount,
      currentValue: amount,
      depositDate: depositDate,
      maturityDate: maturityDate,
      lockUntil: lockUntil,
      interestRate: 6.0,
      status: FdStatus.locked,
      autoRenew: true,
      remarks: remarks,
    );

    // Save FD lot
    await localDataSource.addFdLot(FdLotModel.fromEntity(newLot));

    // Increase Credit Limit by 90% of principal
    final creditIncrease = amount * 0.90;
    final account = await getCreditCardAccount();
    final updatedAccount = account.copyWith(
      creditLimit: account.creditLimit + creditIncrease,
      availableCredit: account.availableCredit + creditIncrease,
      lastUpdated: DateTime.now(),
    );
    await saveCreditCardAccount(updatedAccount);

    // Log funding transfer in Unified Ledger if source bank account is provided
    if (sourceAccountId != null && sourceAccountId.isNotEmpty) {
      final tx = TransactionEntity(
        id: 'tx_fd_${_uuid.v4()}',
        amount: amount,
        type: TransactionType.transfer,
        accountId: sourceAccountId,
        targetAccountId: 'supermoney',
        categoryOrSource: 'FD Deposit Funding',
        date: depositDate,
        description: 'Funded FD deposit #${newLot.id.substring(0, 8)}',
        referenceId: newLot.id,
      );
      await transactionRepository.addTransaction(tx);
    }

    return newLot;
  }

  @override
  Future<void> withdrawFd(String fdId) async {
    final lots = await getFdLots();
    final lot = lots.firstWhere(
      (l) => l.id == fdId,
      orElse: () => throw Exception('FD Lot not found'),
    );

    if (lot.isLocked) {
      throw Exception('Cannot withdraw locked FD. Unlocks in ${lot.daysUntilUnlock} days.');
    }

    final account = await getCreditCardAccount();
    final creditReduction = lot.creditLimitContribution;

    // Validation: Used Credit cannot exceed resulting credit limit
    final resultingLimit = account.creditLimit - creditReduction;
    if (account.usedCredit > resultingLimit) {
      throw Exception(
        'Withdrawal blocked: Used Credit (₹${account.usedCredit.toStringAsFixed(0)}) exceeds resulting Credit Limit (₹${resultingLimit.toStringAsFixed(0)}). Pay off card balance first.',
      );
    }

    // Mark FD as withdrawn
    final updatedLot = lot.copyWith(status: FdStatus.withdrawn);
    await localDataSource.updateFdLot(FdLotModel.fromEntity(updatedLot));

    // Reduce Credit Limit & Available Credit
    final updatedAccount = account.copyWith(
      creditLimit: resultingLimit.clamp(0.0, double.infinity),
      availableCredit: (account.availableCredit - creditReduction).clamp(0.0, double.infinity),
      lastUpdated: DateTime.now(),
    );
    await saveCreditCardAccount(updatedAccount);
  }

  @override
  Future<List<CreditCardStatementEntity>> getStatements() async {
    final models = await localDataSource.getStatements();
    return models.map((m) => m.toEntity()).toList();
  }

  @override
  Future<CreditCardStatementEntity> generateMonthlyStatement(int month, int year) async {
    final statements = await getStatements();
    final existing = statements.where((s) => s.month == month && s.year == year).firstOrNull;
    if (existing != null) return existing;

    final account = await getCreditCardAccount();
    final statementDate = DateTime(year, month, account.statementDateDay);
    final dueDate = DateTime(year, month, account.dueDateDay);

    final statementId = 'stmt_${year}_$month';
    final openingOutstanding = account.usedCredit;
    final newPurchases = 0.0;
    final payments = 0.0;
    final closingOutstanding = (openingOutstanding + newPurchases - payments).clamp(0.0, double.infinity);
    final minimumDue = (closingOutstanding * 0.05).clamp(500.0, closingOutstanding);

    final newStatement = CreditCardStatementEntity(
      id: statementId,
      month: month,
      year: year,
      statementDate: statementDate,
      dueDate: dueDate,
      openingOutstanding: openingOutstanding,
      newPurchases: newPurchases,
      payments: payments,
      adjustments: 0.0,
      cashbackEarned: 0.0,
      closingOutstanding: closingOutstanding,
      minimumDue: minimumDue,
      paidAmount: 0.0,
      status: closingOutstanding == 0 ? StatementStatus.paid : StatementStatus.pending,
    );

    await localDataSource.addStatement(CreditCardStatementModel.fromEntity(newStatement));
    return newStatement;
  }

  @override
  Future<void> makeCardPayment({
    required String sourceAccountId,
    required double amount,
    required DateTime date,
    required String reference,
  }) async {
    if (amount <= 0) throw Exception('Payment amount must be greater than 0');

    final account = await getCreditCardAccount();
    final newUsedCredit = (account.usedCredit - amount).clamp(0.0, double.infinity);
    final newAvailableCredit = (account.availableCredit + amount).clamp(0.0, account.creditLimit);

    final updatedAccount = account.copyWith(
      usedCredit: newUsedCredit,
      availableCredit: newAvailableCredit,
      lastUpdated: DateTime.now(),
    );
    await saveCreditCardAccount(updatedAccount);

    // Create Transfer transaction in Unified Ledger: Bank Account -> supermoney
    final tx = TransactionEntity(
      id: 'tx_pay_${_uuid.v4()}',
      amount: amount,
      type: TransactionType.transfer,
      accountId: sourceAccountId,
      targetAccountId: 'supermoney',
      categoryOrSource: 'Credit Card Bill Payment',
      date: date,
      description: reference.isEmpty ? 'Credit Card Settlement' : reference,
      referenceId: 'cc_payment',
    );
    await transactionRepository.addTransaction(tx);

    // Update active pending statement if exists
    final statements = await getStatements();
    final pendingStmt = statements.where((s) => s.status == StatementStatus.pending || s.status == StatementStatus.partiallyPaid).firstOrNull;
    if (pendingStmt != null) {
      final updatedPaid = pendingStmt.paidAmount + amount;
      final isFullyPaid = updatedPaid >= pendingStmt.closingOutstanding;
      final updatedStmt = pendingStmt.copyWith(
        paidAmount: updatedPaid,
        status: isFullyPaid ? StatementStatus.paid : StatementStatus.partiallyPaid,
      );
      await localDataSource.updateStatement(CreditCardStatementModel.fromEntity(updatedStmt));
    }
  }

  @override
  Future<List<CashbackTransactionEntity>> getCashbackTransactions() async {
    final models = await localDataSource.getCashbackTransactions();
    return models.map((m) => m.toEntity()).toList();
  }

  @override
  Future<void> redeemCashback({
    required double amount,
    required String destinationType,
    String? targetAccountId,
  }) async {
    final account = await getCreditCardAccount();
    if (amount > account.cashbackAvailable) {
      throw Exception('Insufficient cashback balance');
    }

    final updatedAccount = account.copyWith(
      cashbackAvailable: (account.cashbackAvailable - amount).clamp(0.0, double.infinity),
      lastUpdated: DateTime.now(),
    );
    await saveCreditCardAccount(updatedAccount);

    if (destinationType == 'credit_payment') {
      await makeCardPayment(
        sourceAccountId: 'cashback_wallet',
        amount: amount,
        date: DateTime.now(),
        reference: 'Cashback Reward Credit Payment',
      );
    } else if (destinationType == 'fd') {
      await depositFd(
        amount: amount,
        depositDate: DateTime.now(),
        remarks: 'Funded via Cashback Redemption',
      );
    } else {
      // Bank account crediting (defaulting to SBI or specified targetAccountId)
      final destBankId = (targetAccountId != null && targetAccountId.isNotEmpty) ? targetAccountId : 'sbi';
      final tx = TransactionEntity(
        id: 'tx_cb_${_uuid.v4()}',
        amount: amount,
        type: TransactionType.income,
        accountId: destBankId,
        categoryOrSource: 'Cashback Reward',
        date: DateTime.now(),
        description: 'SuperMoney Cashback Credit to ${destBankId.toUpperCase()}',
        referenceId: 'cashback_redemption',
      );
      await transactionRepository.addTransaction(tx);
    }
  }

  @override
  Future<void> processDailyInterestCompounding() async {
    await getFdLots(); // Automatically calculates compounding and auto-renewals
  }
}
