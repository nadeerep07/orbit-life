import 'package:hive/hive.dart';
import '../../domain/entities/transfer_entity.dart';

part 'transfer_model.g.dart';

@HiveType(typeId: 8)
class TransferModel extends HiveObject {
  @HiveField(0)
  final String id;

  @HiveField(1)
  final String fromAccountId;

  @HiveField(2)
  final String toAccountId;

  @HiveField(3)
  final double amount;

  @HiveField(4)
  final DateTime date;

  @HiveField(5)
  final String description;

  TransferModel({
    required this.id,
    required this.fromAccountId,
    required this.toAccountId,
    required this.amount,
    required this.date,
    required this.description,
  });

  factory TransferModel.fromEntity(TransferEntity entity) {
    return TransferModel(
      id: entity.id,
      fromAccountId: entity.fromAccountId,
      toAccountId: entity.toAccountId,
      amount: entity.amount,
      date: entity.date,
      description: entity.description,
    );
  }

  TransferEntity toEntity() {
    return TransferEntity(
      id: id,
      fromAccountId: fromAccountId,
      toAccountId: toAccountId,
      amount: amount,
      date: date,
      description: description,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'fromAccountId': fromAccountId,
      'toAccountId': toAccountId,
      'amount': amount,
      'date': date.toIso8601String(),
      'description': description,
    };
  }

  factory TransferModel.fromJson(Map<String, dynamic> json) {
    return TransferModel(
      id: json['id'] as String,
      fromAccountId: json['fromAccountId'] as String,
      toAccountId: json['toAccountId'] as String,
      amount: (json['amount'] as num).toDouble(),
      date: DateTime.parse(json['date'] as String),
      description: json['description'] as String? ?? '',
    );
  }
}
