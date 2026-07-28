import 'package:hive/hive.dart';
import '../../domain/entities/credit_card_statement_entity.dart';

part 'credit_card_statement_model.g.dart';

@HiveType(typeId: 22)
class CreditCardStatementModel extends HiveObject {
  @HiveField(0)
  final String id;

  @HiveField(1)
  final int month;

  @HiveField(2)
  final int year;

  @HiveField(3)
  final DateTime statementDate;

  @HiveField(4)
  final DateTime dueDate;

  @HiveField(5)
  final double openingOutstanding;

  @HiveField(6)
  final double newPurchases;

  @HiveField(7)
  final double payments;

  @HiveField(8)
  final double adjustments;

  @HiveField(9)
  final double cashbackEarned;

  @HiveField(10)
  final double closingOutstanding;

  @HiveField(11)
  final double minimumDue;

  @HiveField(12)
  double paidAmount;

  @HiveField(13)
  String status;

  CreditCardStatementModel({
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
    required this.paidAmount,
    required this.status,
  });

  factory CreditCardStatementModel.fromEntity(CreditCardStatementEntity entity) {
    return CreditCardStatementModel(
      id: entity.id,
      month: entity.month,
      year: entity.year,
      statementDate: entity.statementDate,
      dueDate: entity.dueDate,
      openingOutstanding: entity.openingOutstanding,
      newPurchases: entity.newPurchases,
      payments: entity.payments,
      adjustments: entity.adjustments,
      cashbackEarned: entity.cashbackEarned,
      closingOutstanding: entity.closingOutstanding,
      minimumDue: entity.minimumDue,
      paidAmount: entity.paidAmount,
      status: entity.status.name,
    );
  }

  CreditCardStatementEntity toEntity() {
    final parsedStatus = StatementStatus.values.firstWhere(
      (e) => e.name == status,
      orElse: () => StatementStatus.pending,
    );
    return CreditCardStatementEntity(
      id: id,
      month: month,
      year: year,
      statementDate: statementDate,
      dueDate: dueDate,
      openingOutstanding: openingOutstanding,
      newPurchases: newPurchases,
      payments: payments,
      adjustments: adjustments,
      cashbackEarned: cashbackEarned,
      closingOutstanding: closingOutstanding,
      minimumDue: minimumDue,
      paidAmount: paidAmount,
      status: parsedStatus,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'month': month,
      'year': year,
      'statementDate': statementDate.toIso8601String(),
      'dueDate': dueDate.toIso8601String(),
      'openingOutstanding': openingOutstanding,
      'newPurchases': newPurchases,
      'payments': payments,
      'adjustments': adjustments,
      'cashbackEarned': cashbackEarned,
      'closingOutstanding': closingOutstanding,
      'minimumDue': minimumDue,
      'paidAmount': paidAmount,
      'status': status,
    };
  }

  factory CreditCardStatementModel.fromJson(Map<String, dynamic> json) {
    DateTime parseDate(dynamic d) {
      if (d is String) return DateTime.parse(d);
      if (d is DateTime) return d;
      try {
        return (d as dynamic).toDate();
      } catch (_) {}
      return DateTime.now();
    }
    return CreditCardStatementModel(
      id: json['id'] as String,
      month: json['month'] as int,
      year: json['year'] as int,
      statementDate: parseDate(json['statementDate']),
      dueDate: parseDate(json['dueDate']),
      openingOutstanding: (json['openingOutstanding'] as num).toDouble(),
      newPurchases: (json['newPurchases'] as num).toDouble(),
      payments: (json['payments'] as num).toDouble(),
      adjustments: (json['adjustments'] as num).toDouble(),
      cashbackEarned: (json['cashbackEarned'] as num).toDouble(),
      closingOutstanding: (json['closingOutstanding'] as num).toDouble(),
      minimumDue: (json['minimumDue'] as num).toDouble(),
      paidAmount: (json['paidAmount'] as num).toDouble(),
      status: json['status'] as String,
    );
  }
}
