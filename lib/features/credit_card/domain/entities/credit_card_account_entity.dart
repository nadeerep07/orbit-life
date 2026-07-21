import 'package:equatable/equatable.dart';

class CreditCardAccountEntity extends Equatable {
  final String id;
  final String name;
  final double creditLimit;
  final double availableCredit;
  final double usedCredit;
  final double cashbackPending;
  final double cashbackAvailable;
  final double cashbackRedeemed;
  final double lifetimeCashback;
  final int statementDateDay;
  final int dueDateDay;
  final bool initialCreditMigrated;
  final DateTime lastUpdated;

  const CreditCardAccountEntity({
    this.id = 'supermoney',
    this.name = 'Credit Card',
    required this.creditLimit,
    required this.availableCredit,
    required this.usedCredit,
    this.cashbackPending = 371.38,
    this.cashbackAvailable = 166.08,
    this.cashbackRedeemed = 741.92,
    this.lifetimeCashback = 1279.38,
    this.statementDateDay = 1,
    this.dueDateDay = 15,
    this.initialCreditMigrated = true,
    required this.lastUpdated,
  });

  /// Default initial seeded state matching exact user parameters:
  /// Limit: ₹21,204 | Used: ₹14,414 | Available: ₹6,790
  /// Lifetime Cashback: ₹1,279.38 | Redeemed: ₹741.92 | Pending (On the way): ₹371.38 | Redeemable: ₹166.08
  factory CreditCardAccountEntity.initialSeeded() {
    return CreditCardAccountEntity(
      id: 'supermoney',
      name: 'Credit Card',
      creditLimit: 21204.0,
      availableCredit: 6790.0,
      usedCredit: 14414.0,
      cashbackPending: 371.38,
      cashbackAvailable: 166.08,
      cashbackRedeemed: 741.92,
      lifetimeCashback: 1279.38,
      statementDateDay: 1,
      dueDateDay: 15,
      initialCreditMigrated: true,
      lastUpdated: DateTime.now(),
    );
  }

  /// Calculates the next due date based on statement cutoff cycle.
  /// Transactions after statement cutoff date (e.g. July 1st) settle in the following month (e.g. August 15th).
  DateTime get nextDueDate {
    final now = DateTime.now();
    if (now.day >= statementDateDay) {
      return DateTime(now.year, now.month + 1, dueDateDay);
    }
    return DateTime(now.year, now.month, dueDateDay);
  }

  bool get isOverdue {
    if (usedCredit <= 0) return false;
    return DateTime.now().isAfter(nextDueDate);
  }

  CreditCardAccountEntity copyWith({
    String? id,
    String? name,
    double? creditLimit,
    double? availableCredit,
    double? usedCredit,
    double? cashbackPending,
    double? cashbackAvailable,
    double? cashbackRedeemed,
    double? lifetimeCashback,
    int? statementDateDay,
    int? dueDateDay,
    bool? initialCreditMigrated,
    DateTime? lastUpdated,
  }) {
    return CreditCardAccountEntity(
      id: id ?? this.id,
      name: name ?? this.name,
      creditLimit: creditLimit ?? this.creditLimit,
      availableCredit: availableCredit ?? this.availableCredit,
      usedCredit: usedCredit ?? this.usedCredit,
      cashbackPending: cashbackPending ?? this.cashbackPending,
      cashbackAvailable: cashbackAvailable ?? this.cashbackAvailable,
      cashbackRedeemed: cashbackRedeemed ?? this.cashbackRedeemed,
      lifetimeCashback: lifetimeCashback ?? this.lifetimeCashback,
      statementDateDay: statementDateDay ?? this.statementDateDay,
      dueDateDay: dueDateDay ?? this.dueDateDay,
      initialCreditMigrated: initialCreditMigrated ?? this.initialCreditMigrated,
      lastUpdated: lastUpdated ?? this.lastUpdated,
    );
  }

  @override
  List<Object?> get props => [
        id,
        name,
        creditLimit,
        availableCredit,
        usedCredit,
        cashbackPending,
        cashbackAvailable,
        cashbackRedeemed,
        lifetimeCashback,
        statementDateDay,
        dueDateDay,
        initialCreditMigrated,
        lastUpdated,
      ];
}
