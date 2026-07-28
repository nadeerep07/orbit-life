import 'package:equatable/equatable.dart';

class TransactionItemEntity extends Equatable {
  final String id;
  final double amount;
  final bool isCredit;
  final String categoryOrSource;
  final DateTime date;
  final String description;
  final String moduleType;
  final String accountId;

  const TransactionItemEntity({
    required this.id,
    required this.amount,
    required this.isCredit,
    required this.categoryOrSource,
    required this.date,
    required this.description,
    required this.moduleType,
    required this.accountId,
  });

  @override
  List<Object?> get props => [
    id,
    amount,
    isCredit,
    categoryOrSource,
    date,
    description,
    moduleType,
    accountId,
  ];
}
