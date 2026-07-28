import 'package:equatable/equatable.dart';

enum TransactionType {
  income,
  expense,
  transfer,
  investment,
  emi,
  borrow,
  lend,
  savings,
  service,
}

class TransactionEntity extends Equatable {
  final String id;
  final double amount;
  final TransactionType type;
  final String accountId;
  final String? targetAccountId;
  final String categoryOrSource;
  final DateTime date;
  final String description;
  final String referenceId;

  const TransactionEntity({
    required this.id,
    required this.amount,
    required this.type,
    required this.accountId,
    this.targetAccountId,
    required this.categoryOrSource,
    required this.date,
    required this.description,
    required this.referenceId,
  });

  bool get isCredit {
    switch (type) {
      case TransactionType.income:
      case TransactionType.borrow:
        return true;
      case TransactionType.expense:
      case TransactionType.investment:
      case TransactionType.emi:
      case TransactionType.lend:
      case TransactionType.service:
        return false;
      case TransactionType.transfer:
      case TransactionType.savings:
        // Handled dynamically in statement queries based on direction
        return false;
    }
  }

  @override
  List<Object?> get props => [
        id,
        amount,
        type,
        accountId,
        targetAccountId,
        categoryOrSource,
        date,
        description,
        referenceId,
      ];
}
