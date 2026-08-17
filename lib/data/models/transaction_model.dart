import 'package:hive/hive.dart';
import '../../domain/entities/transaction_entity.dart';

part 'transaction_model.g.dart';

@HiveType(typeId: 17)
class TransactionModel extends HiveObject {
  @HiveField(0)
  final String id;

  @HiveField(1)
  final double amount;

  @HiveField(2)
  final String type; // Serialized TransactionType

  @HiveField(3)
  final String accountId;

  @HiveField(4)
  final String? targetAccountId;

  @HiveField(5)
  final String categoryOrSource;

  @HiveField(6)
  final DateTime date;

  @HiveField(7)
  final String description;

  @HiveField(8)
  final String referenceId;

  TransactionModel({
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

  factory TransactionModel.fromEntity(TransactionEntity entity) {
    return TransactionModel(
      id: entity.id,
      amount: entity.amount,
      type: entity.type.name,
      accountId: entity.accountId,
      targetAccountId: entity.targetAccountId,
      categoryOrSource: entity.categoryOrSource,
      date: entity.date,
      description: entity.description,
      referenceId: entity.referenceId,
    );
  }

  TransactionEntity toEntity() {
    final tType = TransactionType.values.firstWhere(
      (e) => e.name == type,
      orElse: () => TransactionType.expense,
    );
    return TransactionEntity(
      id: id,
      amount: amount,
      type: tType,
      accountId: accountId,
      targetAccountId: targetAccountId,
      categoryOrSource: categoryOrSource,
      date: date,
      description: description,
      referenceId: referenceId,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'amount': amount,
      'type': type,
      'accountId': accountId,
      'targetAccountId': targetAccountId,
      'categoryOrSource': categoryOrSource,
      'date': date.toIso8601String(),
      'description': description,
      'referenceId': referenceId,
    };
  }

  factory TransactionModel.fromJson(Map<String, dynamic> json) {
    return TransactionModel(
      id: (json['id'] as String?) ?? '',
      amount: ((json['amount'] ?? 0) as num).toDouble(),
      type: (json['type'] as String?) ?? 'expense',
      accountId: (json['accountId'] as String?) ?? 'default',
      targetAccountId: json['targetAccountId'] as String?,
      categoryOrSource: (json['categoryOrSource'] as String?) ?? (json['categoryId'] as String?) ?? (json['source'] as String?) ?? 'General',
      date: json['date'] != null ? DateTime.parse(json['date'] as String) : DateTime.now(),
      description: (json['description'] as String?) ?? (json['title'] as String?) ?? (json['notes'] as String?) ?? '',
      referenceId: (json['referenceId'] as String?) ?? '',
    );
  }
}
