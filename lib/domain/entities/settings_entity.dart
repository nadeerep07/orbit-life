import 'package:equatable/equatable.dart';

class SettingsEntity extends Equatable {
  final String currencyCode;
  final String currencySymbol;
  final double monthlyBudgetLimit;
  final Map<String, double> categoryBudgets;
  final double savingsGoal;
  final double emergencyFundGoal;
  final bool enableNotifications;
  final String backupFrequency;

  // New financial intelligence fields
  final bool enableAutoAllocation;
  final String financialMode; // 'survival', 'recovery', 'growth', 'custom'
  final List<String> customModePriorities; // order of buckets: obligations, savings, debt, spending
  final bool dailyLimitRollover;
  final bool enableBiometrics;
  final String securityPin;

  const SettingsEntity({
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

  const SettingsEntity.defaultSettings()
      : currencyCode = 'INR',
        currencySymbol = '₹',
        monthlyBudgetLimit = 15000.0,
        categoryBudgets = const {},
        savingsGoal = 50000.0,
        emergencyFundGoal = 100000.0,
        enableNotifications = true,
        backupFrequency = 'weekly',
        enableAutoAllocation = true,
        financialMode = 'growth',
        customModePriorities = const ['obligations', 'savings', 'debt', 'spending'],
        dailyLimitRollover = true,
        enableBiometrics = false,
        securityPin = '';

  SettingsEntity copyWith({
    String? currencyCode,
    String? currencySymbol,
    double? monthlyBudgetLimit,
    Map<String, double>? categoryBudgets,
    double? savingsGoal,
    double? emergencyFundGoal,
    bool? enableNotifications,
    String? backupFrequency,
    bool? enableAutoAllocation,
    String? financialMode,
    List<String>? customModePriorities,
    bool? dailyLimitRollover,
    bool? enableBiometrics,
    String? securityPin,
  }) {
    return SettingsEntity(
      currencyCode: currencyCode ?? this.currencyCode,
      currencySymbol: currencySymbol ?? this.currencySymbol,
      monthlyBudgetLimit: monthlyBudgetLimit ?? this.monthlyBudgetLimit,
      categoryBudgets: categoryBudgets ?? this.categoryBudgets,
      savingsGoal: savingsGoal ?? this.savingsGoal,
      emergencyFundGoal: emergencyFundGoal ?? this.emergencyFundGoal,
      enableNotifications: enableNotifications ?? this.enableNotifications,
      backupFrequency: backupFrequency ?? this.backupFrequency,
      enableAutoAllocation: enableAutoAllocation ?? this.enableAutoAllocation,
      financialMode: financialMode ?? this.financialMode,
      customModePriorities: customModePriorities ?? this.customModePriorities,
      dailyLimitRollover: dailyLimitRollover ?? this.dailyLimitRollover,
      enableBiometrics: enableBiometrics ?? this.enableBiometrics,
      securityPin: securityPin ?? this.securityPin,
    );
  }

  @override
  List<Object?> get props => [
        currencyCode,
        currencySymbol,
        monthlyBudgetLimit,
        categoryBudgets,
        savingsGoal,
        emergencyFundGoal,
        enableNotifications,
        backupFrequency,
        enableAutoAllocation,
        financialMode,
        customModePriorities,
        dailyLimitRollover,
        enableBiometrics,
        securityPin,
      ];
}
