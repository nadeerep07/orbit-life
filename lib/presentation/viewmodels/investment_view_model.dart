import 'package:flutter/material.dart';
import '../../domain/entities/investment_entity.dart';
import '../../domain/entities/transaction_entity.dart';
import '../../domain/repositories/investment_repository.dart';
import '../../domain/repositories/transaction_repository.dart';
import '../../core/services/notification_service.dart';
import '../../core/utils/currency_formatter.dart';

class InvestmentViewModel extends ChangeNotifier {
  final InvestmentRepository _repository;
  final TransactionRepository _transactionRepository;

  List<InvestmentEntity> _investments = [];
  List<InvestmentEntity> get investments => _investments;

  bool _isLoading = false;
  bool get isLoading => _isLoading;

  InvestmentViewModel(this._repository, this._transactionRepository);

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

    // Record investment transaction
    final tx = TransactionEntity(
      id: investment.id,
      amount: investment.investedAmount,
      type: TransactionType.investment,
      accountId: investment.accountId,
      categoryOrSource: 'Investment - ${investment.name}',
      date: investment.date,
      description: investment.notes,
      referenceId: investment.id,
    );
    await _transactionRepository.addTransaction(tx);

    await loadInvestments();
  }

  Future<void> updateInvestment(InvestmentEntity investment) async {
    await _repository.updateInvestment(investment);

    // Update investment transaction (automatically handles balance changes on edit)
    final tx = TransactionEntity(
      id: investment.id,
      amount: investment.investedAmount,
      type: TransactionType.investment,
      accountId: investment.accountId,
      categoryOrSource: 'Investment - ${investment.name}',
      date: investment.date,
      description: investment.notes,
      referenceId: investment.id,
    );
    await _transactionRepository.updateTransaction(tx);

    await loadInvestments();
  }

  Future<void> deleteInvestment(String id) async {
    await _repository.deleteInvestment(id);

    // Delete transaction to refund the balance automatically
    await _transactionRepository.deleteTransaction(id);

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
        'Your $currencySymbol${investment.investedAmount.toStringAsFixed(0)} ${investment.name} SIP is due tomorrow.';

    await NotificationService().scheduleNotification(
      id: id,
      title: title,
      body: body,
      scheduledDate: scheduleTime,
    );
  }
}
