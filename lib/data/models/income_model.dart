import 'package:hive/hive.dart';
import '../../domain/entities/income_entity.dart';

part 'income_model.g.dart';

@HiveType(typeId: 4)
class IncomeModel extends HiveObject {
  @HiveField(0)
  final String id;

  @HiveField(1)
  final String source;

  @HiveField(2)
  final String description;

  @HiveField(3)
  final double amount;

  @HiveField(4)
  final DateTime date;

  @HiveField(5)
  final String accountId;

  IncomeModel({
    required this.id,
    required this.source,
    required this.description,
    required this.amount,
    required this.date,
    required this.accountId,
  });

  factory IncomeModel.fromEntity(IncomeEntity entity) {
    return IncomeModel(
      id: entity.id,
      source: entity.source,
      description: entity.description,
      amount: entity.amount,
      date: entity.date,
      accountId: entity.accountId,
    );
  }

  IncomeEntity toEntity() {
    return IncomeEntity(
      id: id,
      source: source,
      description: description,
      amount: amount,
      date: date,
      accountId: accountId,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'source': source,
      'description': description,
      'amount': amount,
      'date': date.toIso8601String(),
      'accountId': accountId,
    };
  }

  factory IncomeModel.fromJson(Map<String, dynamic> json) {
    return IncomeModel(
      id: (json['id'] as String?) ?? '',
      source: (json['source'] as String?) ?? 'Income',
      description: (json['description'] as String?) ?? '',
      amount: ((json['amount'] ?? 0) as num).toDouble(),
      date: json['date'] != null ? DateTime.parse(json['date'] as String) : DateTime.now(),
      accountId: (json['accountId'] as String?) ?? 'default',
    );
  }
}
