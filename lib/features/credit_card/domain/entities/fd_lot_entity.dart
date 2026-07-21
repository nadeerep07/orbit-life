import 'dart:math';
import 'package:equatable/equatable.dart';

enum FdStatus { locked, active, matured, withdrawn, renewed }

class FdLotEntity extends Equatable {
  final String id;
  final double principal;
  final double currentValue;
  final DateTime depositDate;
  final DateTime maturityDate;
  final DateTime lockUntil;
  final double interestRate;
  final FdStatus status;
  final bool autoRenew;
  final List<DateTime> renewHistory;
  final String remarks;

  const FdLotEntity({
    required this.id,
    required this.principal,
    required this.currentValue,
    required this.depositDate,
    required this.maturityDate,
    required this.lockUntil,
    this.interestRate = 6.0,
    required this.status,
    this.autoRenew = true,
    this.renewHistory = const [],
    this.remarks = '',
  });

  bool get isLocked => DateTime.now().isBefore(lockUntil);

  int get daysUntilUnlock {
    final diff = lockUntil.difference(DateTime.now()).inSeconds;
    if (diff <= 0) return 0;
    return (diff / 86400).ceil();
  }

  int get daysRemainingToMaturity {
    final diff = maturityDate.difference(DateTime.now()).inSeconds;
    if (diff <= 0) return 0;
    return (diff / 86400).ceil();
  }

  /// 90% of principal grants towards credit limit
  double get creditLimitContribution => principal * 0.90;

  double get interestEarned => (currentValue - principal).clamp(0.0, double.infinity);

  /// Daily compounded interest calculation: A = P * (1 + (r/365))^t
  static double calculateCompoundedValueAt({
    required double principal,
    required double rate,
    required DateTime depositDate,
    required DateTime targetDate,
  }) {
    if (targetDate.isBefore(depositDate)) return principal;
    final days = targetDate.difference(depositDate).inDays;
    final dailyRate = (rate / 100.0) / 365.0;
    return principal * pow(1.0 + dailyRate, days);
  }

  double calculateCurrentValAt(DateTime date) {
    return calculateCompoundedValueAt(
      principal: principal,
      rate: interestRate,
      depositDate: depositDate,
      targetDate: date,
    );
  }

  double get todaysInterest {
    final now = DateTime.now();
    final todayVal = calculateCurrentValAt(now);
    final yesterdayVal = calculateCurrentValAt(now.subtract(const Duration(days: 1)));
    return (todayVal - yesterdayVal).clamp(0.0, double.infinity);
  }

  double get tomorrowsEstimatedInterest {
    final now = DateTime.now();
    final todayVal = calculateCurrentValAt(now);
    final tomorrowVal = calculateCurrentValAt(now.add(const Duration(days: 1)));
    return (tomorrowVal - todayVal).clamp(0.0, double.infinity);
  }

  double get annualReturnProjection => principal * (interestRate / 100.0);

  FdLotEntity copyWith({
    String? id,
    double? principal,
    double? currentValue,
    DateTime? depositDate,
    DateTime? maturityDate,
    DateTime? lockUntil,
    double? interestRate,
    FdStatus? status,
    bool? autoRenew,
    List<DateTime>? renewHistory,
    String? remarks,
  }) {
    return FdLotEntity(
      id: id ?? this.id,
      principal: principal ?? this.principal,
      currentValue: currentValue ?? this.currentValue,
      depositDate: depositDate ?? this.depositDate,
      maturityDate: maturityDate ?? this.maturityDate,
      lockUntil: lockUntil ?? this.lockUntil,
      interestRate: interestRate ?? this.interestRate,
      status: status ?? this.status,
      autoRenew: autoRenew ?? this.autoRenew,
      renewHistory: renewHistory ?? this.renewHistory,
      remarks: remarks ?? this.remarks,
    );
  }

  @override
  List<Object?> get props => [
        id,
        principal,
        currentValue,
        depositDate,
        maturityDate,
        lockUntil,
        interestRate,
        status,
        autoRenew,
        renewHistory,
        remarks,
      ];
}
