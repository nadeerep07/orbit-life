import 'package:hive/hive.dart';
import '../../domain/entities/borrow_lend_transaction_entity.dart';

part 'borrow_lend_transaction_model.g.dart';

@HiveType(typeId: 16)
class BorrowLendTransactionModel extends HiveObject {
  @HiveField(0)
  final String id;

  @HiveField(1)
  final double amount;

  @HiveField(2)
  final String type;

  @HiveField(3)
  final DateTime date;

  @HiveField(4, defaultValue: 'cash')
  final String accountId;

  BorrowLendTransactionModel({
    required this.id,
    required this.amount,
    required this.type,
    required this.date,
    this.accountId = 'cash',
  });

  factory BorrowLendTransactionModel.fromEntity(
    BorrowLendTransactionEntity entity,
  ) {
    return BorrowLendTransactionModel(
      id: entity.id,
      amount: entity.amount,
      type: entity.type,
      date: entity.date,
      accountId: entity.accountId,
    );
  }

  BorrowLendTransactionEntity toEntity() {
    return BorrowLendTransactionEntity(
      id: id,
      amount: amount,
      type: type,
      date: date,
      accountId: accountId,
    );
  }
}
