import 'package:flutter/material.dart';
import '../../domain/entities/investment_entity.dart';
import '../../domain/repositories/investment_repository.dart';
import '../../core/services/notification_service.dart';

class InvestmentViewModel extends ChangeNotifier {
  final InvestmentRepository _repository;

  List<InvestmentEntity> _investments = [];
  List<InvestmentEntity> get investments => _investments;

  bool _isLoading = false;
  bool get isLoading => _isLoading;

  InvestmentViewModel(this._repository);

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

    await loadInvestments();
  }

  Future<void> updateInvestment(InvestmentEntity investment) async {
    await _repository.updateInvestment(investment);
    await loadInvestments();
  }

  Future<void> deleteInvestment(String id) async {
    await _repository.deleteInvestment(id);
    await NotificationService().cancelNotification(id.hashCode.abs());
    await loadInvestments();
  }

  double get totalInvested {
    return _investments.fold(0.0, (sum, inv) => sum + inv.investedAmount);
  }

  double get currentPortfolioValue {
    return _investments.fold(0.0, (sum, inv) => sum + inv.currentValue);
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
