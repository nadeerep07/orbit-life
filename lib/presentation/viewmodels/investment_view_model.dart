import 'package:flutter/material.dart';
import '../../domain/entities/investment_entity.dart';
import '../../domain/repositories/investment_repository.dart';
import '../../core/services/notification_service.dart';
import 'accounts_view_model.dart';

class InvestmentViewModel extends ChangeNotifier {
  final InvestmentRepository _repository;

  List<InvestmentEntity> _investments = [];
  List<InvestmentEntity> get investments => _investments;

  bool _isLoading = false;
  bool get isLoading => _isLoading;

  final AccountsViewModel _accountsViewModel;

  InvestmentViewModel(this._repository, this._accountsViewModel);

  Future<void> loadInvestments() async {
    _isLoading = true;
    notifyListeners();

    _investments = await _repository.getInvestments();
    _investments.sort((a, b) => b.date.compareTo(a.date));

    _isLoading = false;
    notifyListeners();
  }

  Future<void> addInvestment(
    InvestmentEntity investment, {
    bool enableSipReminder = false,
  }) async {
    await _repository.addInvestment(investment);

    if (enableSipReminder && investment.type == 'sip') {
      await _scheduleSipReminder(investment);
    }

    // Deduct invested amount from the selected account
    await _accountsViewModel.updateAccountBalance(
      investment.accountId,
      -investment.investedAmount,
    );

    await loadInvestments();
  }

  Future<void> updateInvestment(InvestmentEntity investment) async {
    await _repository.updateInvestment(investment);
    await loadInvestments();
  }

  Future<void> deleteInvestment(String id) async {
    final investment = _investments.firstWhere((inv) => inv.id == id);
    await _repository.deleteInvestment(id);

    // Refund invested amount to the account
    await _accountsViewModel.updateAccountBalance(
      investment.accountId,
      investment.investedAmount,
    );

    await NotificationService().cancelNotification(id.hashCode.abs());
    await loadInvestments();
  }

  double get totalInvested {
    return _investments.fold(0.0, (sum, inv) => sum + inv.investedAmount);
  }

  double get currentPortfolioValue {
    return _investments.fold(
      0.0,
      (sum, inv) => sum + inv.calculatedCurrentValue,
    );
  }

  double get totalProfitLoss {
    return currentPortfolioValue - totalInvested;
  }

  Future<void> _scheduleSipReminder(InvestmentEntity investment) async {
    final id = investment.id.hashCode.abs();

    DateTime nextMonth = DateTime.now().add(const Duration(days: 30));
    DateTime scheduleTime = DateTime(
      nextMonth.year,
      nextMonth.month,
      nextMonth.day,
      10,
      0,
    );

    String title = 'SIP Reminder';
    String body =
        'Your ₹${investment.investedAmount.toStringAsFixed(0)} ${investment.name} SIP is due tomorrow.';

    await NotificationService().scheduleNotification(
      id: id,
      title: title,
      body: body,
      scheduledDate: scheduleTime,
    );
  }
}
