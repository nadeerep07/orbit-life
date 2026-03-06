import 'package:hive/hive.dart';
import '../../domain/entities/investment_entity.dart';

part 'investment_model.g.dart';

@HiveType(typeId: 15)
class InvestmentModel extends HiveObject {
  @HiveField(0)
  final String id;

  @HiveField(1)
  final String name;

  @HiveField(2)
  final String type;

  @HiveField(3)
  final double investedAmount;

  @HiveField(4)
  final double currentValue;

  @HiveField(5)
  final double? quantity;

  @HiveField(6)
  final double? buyPrice;

  @HiveField(7)
  final DateTime date;

  @HiveField(8)
  final String notes;

  @HiveField(9, defaultValue: null)
  final double? interestRate;

  @HiveField(10, defaultValue: 'cash')
  final String accountId;

  InvestmentModel({
    required this.id,
    required this.name,
    required this.type,
    required this.investedAmount,
    required this.currentValue,
    this.quantity,
    this.buyPrice,
    required this.date,
    this.notes = '',
    this.interestRate,
    this.accountId = 'cash',
  });

  factory InvestmentModel.fromEntity(InvestmentEntity entity) {
    return InvestmentModel(
      id: entity.id,
      name: entity.name,
      type: entity.type,
      investedAmount: entity.investedAmount,
      currentValue: entity.currentValue,
      quantity: entity.quantity,
      buyPrice: entity.buyPrice,
      date: entity.date,
      notes: entity.notes,
      interestRate: entity.interestRate,
      accountId: entity.accountId,
    );
  }

  InvestmentEntity toEntity() {
    return InvestmentEntity(
      id: id,
      name: name,
      type: type,
      investedAmount: investedAmount,
      currentValue: currentValue,
      quantity: quantity,
      buyPrice: buyPrice,
      date: date,
      notes: notes,
      interestRate: interestRate,
      accountId: accountId,
    );
  }
}
