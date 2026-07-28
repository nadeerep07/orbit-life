import 'package:equatable/equatable.dart';

enum StatementStatus { pending, partiallyPaid, paid, overdue, late }

class CreditCardStatementEntity extends Equatable {
  final String id;
  final int month;
  final int year;
  final DateTime statementDate;
  final DateTime dueDate;
  final double openingOutstanding;
  final double newPurchases;
  final double payments;
  final double adjustments;
  final double cashbackEarned;
  final double closingOutstanding;
  final double minimumDue;
  final double paidAmount;
  final StatementStatus status;

  const CreditCardStatementEntity({
    required this.id,
    required this.month,
    required this.year,
    required this.statementDate,
    required this.dueDate,
    required this.openingOutstanding,
    required this.newPurchases,
    required this.payments,
    required this.adjustments,
    required this.cashbackEarned,
    required this.closingOutstanding,
    required this.minimumDue,
    this.paidAmount = 0.0,
    required this.status,
  });

  double get remainingOutstanding => (closingOutstanding - paidAmount).clamp(0.0, double.infinity);

  CreditCardStatementEntity copyWith({
    String? id,
    int? month,
    int? year,
    DateTime? statementDate,
    DateTime? dueDate,
    double? openingOutstanding,
    double? newPurchases,
    double? payments,
    double? adjustments,
    double? cashbackEarned,
    double? closingOutstanding,
    double? minimumDue,
    double? paidAmount,
    StatementStatus? status,
  }) {
    return CreditCardStatementEntity(
      id: id ?? this.id,
      month: month ?? this.month,
      year: year ?? this.year,
      statementDate: statementDate ?? this.statementDate,
      dueDate: dueDate ?? this.dueDate,
      openingOutstanding: openingOutstanding ?? this.openingOutstanding,
      newPurchases: newPurchases ?? this.newPurchases,
      payments: payments ?? this.payments,
      adjustments: adjustments ?? this.adjustments,
      cashbackEarned: cashbackEarned ?? this.cashbackEarned,
      closingOutstanding: closingOutstanding ?? this.closingOutstanding,
      minimumDue: minimumDue ?? this.minimumDue,
      paidAmount: paidAmount ?? this.paidAmount,
      status: status ?? this.status,
    );
  }

  @override
  List<Object?> get props => [
        id,
        month,
        year,
        statementDate,
        dueDate,
        openingOutstanding,
        newPurchases,
        payments,
        adjustments,
        cashbackEarned,
        closingOutstanding,
        minimumDue,
        paidAmount,
        status,
      ];
}
