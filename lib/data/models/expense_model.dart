import 'package:hive/hive.dart';
import '../../domain/entities/expense_entity.dart';

part 'expense_model.g.dart';

@HiveType(typeId: 1)
class ExpenseModel extends HiveObject {
  @HiveField(0)
  final String id;

  @HiveField(1)
  final String categoryId;

  @HiveField(2)
  final double amount;

  @HiveField(3)
  final String description;

  @HiveField(4)
  final DateTime date;

  @HiveField(5)
  final String accountId;

  @HiveField(6)
  final bool isFromSavings;

  @HiveField(7)
  final String? source;

  ExpenseModel({
    required this.id,
    required this.categoryId,
    required this.amount,
    required this.description,
    required this.date,
    required this.accountId,
    this.isFromSavings = false,
    this.source,
  });

  factory ExpenseModel.fromEntity(ExpenseEntity entity) {
    return ExpenseModel(
      id: entity.id,
      categoryId: entity.categoryId,
      amount: entity.amount,
      description: entity.description,
      date: entity.date,
      accountId: entity.accountId,
      isFromSavings: entity.isFromSavings,
      source: entity.source,
    );
  }

  ExpenseEntity toEntity() {
    return ExpenseEntity(
      id: id,
      categoryId: categoryId,
      amount: amount,
      description: description,
      date: date,
      accountId: accountId,
      isFromSavings: isFromSavings,
      source: source,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'categoryId': categoryId,
      'amount': amount,
      'description': description,
      'date': date.toIso8601String(),
      'accountId': accountId,
      'isFromSavings': isFromSavings,
      'source': source,
    };
  }

  factory ExpenseModel.fromJson(Map<String, dynamic> json) {
    return ExpenseModel(
      id: json['id'] as String,
      categoryId: json['categoryId'] as String,
      amount: (json['amount'] as num).toDouble(),
      description: json['description'] as String? ?? '',
      date: DateTime.parse(json['date'] as String),
      accountId: json['accountId'] as String,
      isFromSavings: json['isFromSavings'] as bool? ?? false,
      source: json['source'] as String?,
    );
  }
}
