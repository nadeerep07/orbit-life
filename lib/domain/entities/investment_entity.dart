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
  ];
}
