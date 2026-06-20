import 'package:hive/hive.dart';
import '../../domain/entities/settings_entity.dart';

part 'settings_model.g.dart';

@HiveType(typeId: 18)
class SettingsModel extends HiveObject {
  @HiveField(0)
  final String currencyCode;

  @HiveField(1)
  final String currencySymbol;

  @HiveField(2)
  final double monthlyBudgetLimit;

  @HiveField(3)
  final Map<String, double> categoryBudgets;

  @HiveField(4)
  final double savingsGoal;

  @HiveField(5)
  final double emergencyFundGoal;

  @HiveField(6)
  final bool enableNotifications;

  @HiveField(7)
  final String backupFrequency;

  // New nullable fields for backward compatibility
  @HiveField(8)
  final bool? enableAutoAllocation;

  @HiveField(9)
  final String? financialMode;

  @HiveField(10)
  final List<String>? customModePriorities;

  @HiveField(11)
  final bool? dailyLimitRollover;

  @HiveField(12)
  final bool? enableBiometrics;

  @HiveField(13)
  final String? securityPin;

  SettingsModel({
    required this.currencyCode,
    required this.currencySymbol,
    required this.monthlyBudgetLimit,
    required this.categoryBudgets,
    required this.savingsGoal,
    required this.emergencyFundGoal,
    required this.enableNotifications,
    required this.backupFrequency,
    this.enableAutoAllocation = true,
    this.financialMode = 'growth',
    this.customModePriorities = const ['obligations', 'savings', 'debt', 'spending'],
    this.dailyLimitRollover = true,
    this.enableBiometrics = false,
    this.securityPin = '',
  });

  factory SettingsModel.fromEntity(SettingsEntity entity) {
    return SettingsModel(
      currencyCode: entity.currencyCode,
      currencySymbol: entity.currencySymbol,
      monthlyBudgetLimit: entity.monthlyBudgetLimit,
      categoryBudgets: entity.categoryBudgets,
      savingsGoal: entity.savingsGoal,
      emergencyFundGoal: entity.emergencyFundGoal,
      enableNotifications: entity.enableNotifications,
      backupFrequency: entity.backupFrequency,
      enableAutoAllocation: entity.enableAutoAllocation,
      financialMode: entity.financialMode,
      customModePriorities: entity.customModePriorities,
      dailyLimitRollover: entity.dailyLimitRollover,
      enableBiometrics: entity.enableBiometrics,
      securityPin: entity.securityPin,
    );
  }

  SettingsEntity toEntity() {
    return SettingsEntity(
      currencyCode: currencyCode,
      currencySymbol: currencySymbol,
      monthlyBudgetLimit: monthlyBudgetLimit,
      categoryBudgets: Map<String, double>.from(categoryBudgets),
      savingsGoal: savingsGoal,
      emergencyFundGoal: emergencyFundGoal,
      enableNotifications: enableNotifications,
      backupFrequency: backupFrequency,
      enableAutoAllocation: enableAutoAllocation ?? true,
      financialMode: financialMode ?? 'growth',
      customModePriorities: customModePriorities != null
          ? List<String>.from(customModePriorities!)
          : const ['obligations', 'savings', 'debt', 'spending'],
      dailyLimitRollover: dailyLimitRollover ?? true,
      enableBiometrics: enableBiometrics ?? false,
      securityPin: securityPin ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'currencyCode': currencyCode,
      'currencySymbol': currencySymbol,
      'monthlyBudgetLimit': monthlyBudgetLimit,
      'categoryBudgets': categoryBudgets,
      'savingsGoal': savingsGoal,
      'emergencyFundGoal': emergencyFundGoal,
      'enableNotifications': enableNotifications,
      'backupFrequency': backupFrequency,
      'enableAutoAllocation': enableAutoAllocation ?? true,
      'financialMode': financialMode ?? 'growth',
      'customModePriorities': customModePriorities ?? const ['obligations', 'savings', 'debt', 'spending'],
      'dailyLimitRollover': dailyLimitRollover ?? true,
      'enableBiometrics': enableBiometrics ?? false,
      'securityPin': securityPin ?? '',
    };
  }

  factory SettingsModel.fromJson(Map<String, dynamic> json) {
    return SettingsModel(
      currencyCode: json['currencyCode'] as String,
      currencySymbol: json['currencySymbol'] as String,
      monthlyBudgetLimit: (json['monthlyBudgetLimit'] as num).toDouble(),
      categoryBudgets: Map<String, double>.from(
        (json['categoryBudgets'] as Map).map(
          (k, v) => MapEntry(k as String, (v as num).toDouble()),
        ),
      ),
      savingsGoal: (json['savingsGoal'] as num).toDouble(),
      emergencyFundGoal: (json['emergencyFundGoal'] as num).toDouble(),
      enableNotifications: json['enableNotifications'] as bool,
      backupFrequency: json['backupFrequency'] as String,
      enableAutoAllocation: json['enableAutoAllocation'] as bool? ?? true,
      financialMode: json['financialMode'] as String? ?? 'growth',
      customModePriorities: json['customModePriorities'] != null
          ? List<String>.from(json['customModePriorities'] as List)
          : const ['obligations', 'savings', 'debt', 'spending'],
      dailyLimitRollover: json['dailyLimitRollover'] as bool? ?? true,
      enableBiometrics: json['enableBiometrics'] as bool? ?? false,
      securityPin: json['securityPin'] as String? ?? '',
    );
  }
}
