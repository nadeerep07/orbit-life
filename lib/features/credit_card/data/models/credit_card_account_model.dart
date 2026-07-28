import 'package:hive/hive.dart';
import '../../domain/entities/credit_card_account_entity.dart';

part 'credit_card_account_model.g.dart';

@HiveType(typeId: 21)
class CreditCardAccountModel extends HiveObject {
  @HiveField(0)
  final String id;

  @HiveField(1)
  final String name;

  @HiveField(2)
  double creditLimit;

  @HiveField(3)
  double availableCredit;

  @HiveField(4)
  double usedCredit;

  @HiveField(5)
  double? cashbackPending;

  @HiveField(6)
  double? cashbackAvailable;

  @HiveField(7)
  double? lifetimeCashback;

  @HiveField(8)
  int statementDateDay;

  @HiveField(9)
  int dueDateDay;

  @HiveField(10)
  bool initialCreditMigrated;

  @HiveField(11)
  DateTime lastUpdated;

  @HiveField(12)
  double? cashbackRedeemed;

  CreditCardAccountModel({
    required this.id,
    required this.name,
    required this.creditLimit,
    required this.availableCredit,
    required this.usedCredit,
    this.cashbackPending = 371.38,
    this.cashbackAvailable = 166.08,
    this.lifetimeCashback = 1279.38,
    required this.statementDateDay,
    required this.dueDateDay,
    required this.initialCreditMigrated,
    required this.lastUpdated,
    this.cashbackRedeemed = 741.92,
  });

  factory CreditCardAccountModel.fromEntity(CreditCardAccountEntity entity) {
    return CreditCardAccountModel(
      id: entity.id,
      name: entity.name,
      creditLimit: entity.creditLimit,
      availableCredit: entity.availableCredit,
      usedCredit: entity.usedCredit,
      cashbackPending: entity.cashbackPending,
      cashbackAvailable: entity.cashbackAvailable,
      lifetimeCashback: entity.lifetimeCashback,
      statementDateDay: entity.statementDateDay,
      dueDateDay: entity.dueDateDay,
      initialCreditMigrated: entity.initialCreditMigrated,
      lastUpdated: entity.lastUpdated,
      cashbackRedeemed: entity.cashbackRedeemed,
    );
  }

  CreditCardAccountEntity toEntity() {
    return CreditCardAccountEntity(
      id: id,
      name: name,
      creditLimit: creditLimit,
      availableCredit: availableCredit,
      usedCredit: usedCredit,
      cashbackPending: cashbackPending ?? 371.38,
      cashbackAvailable: cashbackAvailable ?? 166.08,
      cashbackRedeemed: cashbackRedeemed ?? 741.92,
      lifetimeCashback: lifetimeCashback ?? 1279.38,
      statementDateDay: statementDateDay,
      dueDateDay: dueDateDay,
      initialCreditMigrated: initialCreditMigrated,
      lastUpdated: lastUpdated,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'creditLimit': creditLimit,
      'availableCredit': availableCredit,
      'usedCredit': usedCredit,
      'cashbackPending': cashbackPending,
      'cashbackAvailable': cashbackAvailable,
      'lifetimeCashback': lifetimeCashback,
      'statementDateDay': statementDateDay,
      'dueDateDay': dueDateDay,
      'initialCreditMigrated': initialCreditMigrated,
      'lastUpdated': lastUpdated.toIso8601String(),
      'cashbackRedeemed': cashbackRedeemed,
    };
  }

  factory CreditCardAccountModel.fromJson(Map<String, dynamic> json) {
    DateTime parseDate(dynamic d) {
      if (d is String) return DateTime.parse(d);
      if (d is DateTime) return d;
      try {
        return (d as dynamic).toDate();
      } catch (_) {}
      return DateTime.now();
    }
    return CreditCardAccountModel(
      id: json['id'] as String,
      name: json['name'] as String,
      creditLimit: (json['creditLimit'] as num).toDouble(),
      availableCredit: (json['availableCredit'] as num).toDouble(),
      usedCredit: (json['usedCredit'] as num).toDouble(),
      cashbackPending: json['cashbackPending'] != null ? (json['cashbackPending'] as num).toDouble() : 371.38,
      cashbackAvailable: json['cashbackAvailable'] != null ? (json['cashbackAvailable'] as num).toDouble() : 166.08,
      lifetimeCashback: json['lifetimeCashback'] != null ? (json['lifetimeCashback'] as num).toDouble() : 1279.38,
      statementDateDay: json['statementDateDay'] as int,
      dueDateDay: json['dueDateDay'] as int,
      initialCreditMigrated: (json['initialCreditMigrated'] as bool?) ?? false,
      lastUpdated: parseDate(json['lastUpdated']),
      cashbackRedeemed: json['cashbackRedeemed'] != null ? (json['cashbackRedeemed'] as num).toDouble() : 741.92,
    );
  }
}
