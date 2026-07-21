import 'package:equatable/equatable.dart';

enum CashbackStatus { pending, eligible, credited, rejected, redeemed }

class CashbackTransactionEntity extends Equatable {
  final String id;
  final String transactionId;
  final double amount;
  final double cashbackAmount;
  final DateTime date;
  final DateTime matureDate;
  final CashbackStatus status;
  final String description;

  const CashbackTransactionEntity({
    required this.id,
    required this.transactionId,
    required this.amount,
    required this.cashbackAmount,
    required this.date,
    required this.matureDate,
    required this.status,
    this.description = '',
  });

  bool get isMatured => DateTime.now().isAfter(matureDate);

  CashbackTransactionEntity copyWith({
    String? id,
    String? transactionId,
    double? amount,
    double? cashbackAmount,
    DateTime? date,
    DateTime? matureDate,
    CashbackStatus? status,
    String? description,
  }) {
    return CashbackTransactionEntity(
      id: id ?? this.id,
      transactionId: transactionId ?? this.transactionId,
      amount: amount ?? this.amount,
      cashbackAmount: cashbackAmount ?? this.cashbackAmount,
      date: date ?? this.date,
      matureDate: matureDate ?? this.matureDate,
      status: status ?? this.status,
      description: description ?? this.description,
    );
  }

  @override
  List<Object?> get props => [
        id,
        transactionId,
        amount,
        cashbackAmount,
        date,
        matureDate,
        status,
        description,
      ];
}
