import '../entities/transaction_item_entity.dart';

abstract class TransactionRepository {
  Future<List<TransactionItemEntity>> getTransactionsByAccount(
    String accountId,
  );
}
