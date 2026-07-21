import '../entities/credit_card_account_entity.dart';
import '../entities/fd_lot_entity.dart';
import '../entities/credit_card_statement_entity.dart';
import '../entities/cashback_transaction_entity.dart';

abstract class CreditCardRepository {
  Future<CreditCardAccountEntity> getCreditCardAccount();
  Future<void> saveCreditCardAccount(CreditCardAccountEntity account);

  Future<List<FdLotEntity>> getFdLots();
  Future<FdLotEntity> depositFd({
    required double amount,
    required DateTime depositDate,
    required String remarks,
    String? sourceAccountId,
  });

  Future<void> withdrawFd(String fdId);

  Future<List<CreditCardStatementEntity>> getStatements();
  Future<CreditCardStatementEntity> generateMonthlyStatement(int month, int year);

  Future<void> makeCardPayment({
    required String sourceAccountId,
    required double amount,
    required DateTime date,
    required String reference,
  });

  Future<List<CashbackTransactionEntity>> getCashbackTransactions();
  Future<void> redeemCashback({
    required double amount,
    required String destinationType, // 'bank', 'fd', 'credit_payment'
    String? targetAccountId,
  });

  Future<void> processDailyInterestCompounding();
}
