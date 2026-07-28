import 'package:flutter/material.dart';
import '../../core/utils/currency_formatter.dart';
import '../../domain/entities/settings_entity.dart';
import '../../domain/repositories/settings_repository.dart';

class SettingsViewModel extends ChangeNotifier {
  final SettingsRepository _repository;

  SettingsEntity _settings = const SettingsEntity.defaultSettings();
  SettingsEntity get settings => _settings;

  bool _isLoading = false;
  bool get isLoading => _isLoading;

  SettingsViewModel(this._repository) {
    loadSettings();
  }

  Future<void> loadSettings() async {
    _isLoading = true;
    notifyListeners();

    _settings = await _repository.getSettings();
    currencySymbol = _settings.currencySymbol;

    _isLoading = false;
    notifyListeners();
  }

  Future<void> saveSettings(SettingsEntity newSettings) async {
    _settings = newSettings;
    currencySymbol = newSettings.currencySymbol;
    notifyListeners();
    await _repository.saveSettings(newSettings);
  }

  Future<void> updateCurrency(String code, String symbol) async {
    final updated = _settings.copyWith(
      currencyCode: code,
      currencySymbol: symbol,
    );
    await saveSettings(updated);
  }

  Future<void> updateMonthlyBudget(double limit) async {
    final updated = _settings.copyWith(monthlyBudgetLimit: limit);
    await saveSettings(updated);
  }

  Future<void> updateCategoryBudget(String categoryId, double limit) async {
    final budgets = Map<String, double>.from(_settings.categoryBudgets);
    budgets[categoryId] = limit;
    final updated = _settings.copyWith(categoryBudgets: budgets);
    await saveSettings(updated);
  }

  Future<void> updateSavingsGoal(double goal) async {
    final updated = _settings.copyWith(savingsGoal: goal);
    await saveSettings(updated);
  }

  Future<void> updateEmergencyFundGoal(double goal) async {
    final updated = _settings.copyWith(emergencyFundGoal: goal);
    await saveSettings(updated);
  }

  Future<void> updateAutoAllocation(bool enabled) async {
    final updated = _settings.copyWith(enableAutoAllocation: enabled);
    await saveSettings(updated);
  }

  Future<void> updateFinancialMode(String mode) async {
    final updated = _settings.copyWith(financialMode: mode);
    await saveSettings(updated);
  }

  Future<void> updateCustomModePriorities(List<String> priorities) async {
    final updated = _settings.copyWith(customModePriorities: priorities);
    await saveSettings(updated);
  }

  Future<void> updateDailyLimitRollover(bool rollover) async {
    final updated = _settings.copyWith(dailyLimitRollover: rollover);
    await saveSettings(updated);
  }

  Future<void> updateBiometrics(bool enabled) async {
    final updated = _settings.copyWith(enableBiometrics: enabled);
    await saveSettings(updated);
  }

  Future<void> updateSecurityPin(String pin) async {
    final updated = _settings.copyWith(securityPin: pin);
    await saveSettings(updated);
  }
}
