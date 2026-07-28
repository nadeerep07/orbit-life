import 'package:hive/hive.dart';
import '../../domain/entities/cashback_transaction_entity.dart';

part 'cashback_transaction_model.g.dart';

@HiveType(typeId: 23)
class CashbackTransactionModel extends HiveObject {
  @HiveField(0)
  final String id;

  @HiveField(1)
  final String transactionId;

  @HiveField(2)
  final double amount;

  @HiveField(3)
  final double cashbackAmount;

  @HiveField(4)
  final DateTime date;

  @HiveField(5)
  final DateTime matureDate;

  @HiveField(6)
  String status;

  @HiveField(7)
  String description;

  CashbackTransactionModel({
    required this.id,
    required this.transactionId,
    required this.amount,
    required this.cashbackAmount,
    required this.date,
    required this.matureDate,
    required this.status,
    this.description = '',
  });

  factory CashbackTransactionModel.fromEntity(CashbackTransactionEntity entity) {
    return CashbackTransactionModel(
      id: entity.id,
      transactionId: entity.transactionId,
      amount: entity.amount,
      cashbackAmount: entity.cashbackAmount,
      date: entity.date,
      matureDate: entity.matureDate,
      status: entity.status.name,
      description: entity.description,
    );
  }

  CashbackTransactionEntity toEntity() {
    final parsedStatus = CashbackStatus.values.firstWhere(
      (e) => e.name == status,
      orElse: () => CashbackStatus.pending,
    );
    return CashbackTransactionEntity(
      id: id,
      transactionId: transactionId,
      amount: amount,
      cashbackAmount: cashbackAmount,
      date: date,
      matureDate: matureDate,
      status: parsedStatus,
      description: description,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'transactionId': transactionId,
      'amount': amount,
      'cashbackAmount': cashbackAmount,
      'date': date.toIso8601String(),
      'matureDate': matureDate.toIso8601String(),
      'status': status,
      'description': description,
    };
  }

  factory CashbackTransactionModel.fromJson(Map<String, dynamic> json) {
    DateTime parseDate(dynamic d) {
      if (d is String) return DateTime.parse(d);
      if (d is DateTime) return d;
      try {
        return (d as dynamic).toDate();
      } catch (_) {}
      return DateTime.now();
    }
    return CashbackTransactionModel(
      id: json['id'] as String,
      transactionId: json['transactionId'] as String,
      amount: (json['amount'] as num).toDouble(),
      cashbackAmount: (json['cashbackAmount'] as num).toDouble(),
      date: parseDate(json['date']),
      matureDate: parseDate(json['matureDate']),
      status: json['status'] as String,
      description: (json['description'] as String?) ?? '',
    );
  }
}
