import 'package:equatable/equatable.dart';

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
  ];
}
