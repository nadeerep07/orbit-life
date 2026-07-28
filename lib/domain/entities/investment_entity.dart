import 'package:equatable/equatable.dart';

class InvestmentEntity extends Equatable {
  final String id;
  final String name;
  final String type; // 'stock', 'sip', 'other'
  final double investedAmount;
  final double currentValue;
  final double? quantity;
  final double? buyPrice;
  final DateTime date;
  final String notes;
  final double? interestRate;
  final String accountId;

  const InvestmentEntity({
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

  @override
  List<Object?> get props => [
    id,
    name,
    type,
    investedAmount,
    currentValue,
    quantity,
    buyPrice,
    date,
    notes,
    interestRate,
    accountId,
  ];

  double get calculatedCurrentValue {
    if (type == 'fd' && interestRate != null) {
      final days = DateTime.now().difference(date).inDays;
      if (days > 0) {
        final dailyInterest = (investedAmount * (interestRate! / 100)) / 365;
        return investedAmount + (dailyInterest * days);
      }
      return investedAmount;
    }
    return currentValue;
  }
}
