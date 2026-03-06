import 'package:equatable/equatable.dart';
import 'borrow_lend_transaction_entity.dart';

class BorrowLendEntity extends Equatable {
  final String id;
  final String personName;
  final String phoneNumber;
  final double amount;
  final String type; // 'lent' or 'borrowed'
  final DateTime date;
  final DateTime? dueDate;
  final String note;
  final String status; // 'pending' or 'completed'
  final String accountId; // account given from or received to
  final List<BorrowLendTransactionEntity> transactions;

  const BorrowLendEntity({
    required this.id,
    required this.personName,
    required this.phoneNumber,
    required this.amount,
    required this.type,
    required this.date,
    this.dueDate,
    this.note = '',
    required this.status,
    required this.accountId,
    this.transactions = const [],
  });

  @override
  List<Object?> get props => [
    id,
    personName,
    phoneNumber,
    amount,
    type,
    date,
    dueDate,
    note,
    status,
    accountId,
    transactions,
  ];

  double get totalPaid => transactions.fold(0.0, (sum, t) => sum + t.amount);
  double get remainingAmount => amount - totalPaid;

  BorrowLendEntity copyWith({
    String? id,
    String? personName,
    String? phoneNumber,
    double? amount,
    String? type,
    DateTime? date,
    DateTime? dueDate,
    String? note,
    String? status,
    String? accountId,
    List<BorrowLendTransactionEntity>? transactions,
  }) {
    return BorrowLendEntity(
      id: id ?? this.id,
      personName: personName ?? this.personName,
      phoneNumber: phoneNumber ?? this.phoneNumber,
      amount: amount ?? this.amount,
      type: type ?? this.type,
      date: date ?? this.date,
      dueDate: dueDate ?? this.dueDate,
      note: note ?? this.note,
      status: status ?? this.status,
      accountId: accountId ?? this.accountId,
      transactions: transactions ?? this.transactions,
    );
  }
}
