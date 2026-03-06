import 'package:equatable/equatable.dart';

class BorrowLendTransactionEntity extends Equatable {
  final String id;
  final double amount;
  final String type; // 'received' or 'repaid' or 'lent' or 'borrowed'
  final DateTime date;
  final String accountId;

  const BorrowLendTransactionEntity({
    required this.id,
    required this.amount,
    required this.type,
    required this.date,
    this.accountId = 'cash',
  });

  @override
  List<Object?> get props => [id, amount, type, date, accountId];
}
