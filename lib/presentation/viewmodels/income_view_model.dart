import 'package:flutter/material.dart';
import '../../domain/entities/income_entity.dart';
import '../../domain/entities/transaction_entity.dart';
import '../../domain/repositories/income_repository.dart';
import '../../domain/repositories/transaction_repository.dart';
import '../../core/services/obligation_analysis_engine.dart';
import '../../core/services/savings_recommendation_engine.dart';
import '../../core/services/debt_optimization_engine.dart';
import '../../domain/entities/settings_entity.dart';
import '../../domain/entities/emi_tracker_entity.dart';
import '../../domain/entities/borrow_lend_entity.dart';
import '../../domain/entities/account_entity.dart';

class IncomeViewModel extends ChangeNotifier {
  final IncomeRepository _incomeRepository;
  final TransactionRepository _transactionRepository;

  List<IncomeEntity> _incomes = [];
  List<IncomeEntity> get incomes => _incomes;

  bool _isLoading = false;
  bool get isLoading => _isLoading;

  IncomeViewModel(this._incomeRepository, this._transactionRepository);

  Future<void> loadIncomes() async {
    _isLoading = true;
    notifyListeners();

    _incomes = await _incomeRepository.getIncomes();
    _incomes.sort((a, b) => b.date.compareTo(a.date));

    _isLoading = false;
    notifyListeners();
  }

  Future<void> addIncome(IncomeEntity income) async {
    await _incomeRepository.addIncome(income);

    final tx = TransactionEntity(
      id: income.id,
      amount: income.amount,
      type: TransactionType.income,
      accountId: income.accountId,
      categoryOrSource: income.source,
      date: income.date,
      description: income.description,
      referenceId: income.id,
    );
    await _transactionRepository.addTransaction(tx);

    await loadIncomes();
  }

  Future<void> updateIncome(IncomeEntity income) async {
    await _incomeRepository.updateIncome(income);

    final tx = TransactionEntity(
      id: income.id,
      amount: income.amount,
      type: TransactionType.income,
      accountId: income.accountId,
      categoryOrSource: income.source,
      date: income.date,
      description: income.description,
      referenceId: income.id,
    );
    await _transactionRepository.updateTransaction(tx);

    await loadIncomes();
  }

  Future<void> deleteIncome(String id) async {
    await _incomeRepository.deleteIncome(id);
    await _transactionRepository.deleteTransaction(id);
    await loadIncomes();
  }

  List<IncomeEntity> getIncomesForMonth(DateTime month) {
    return _incomes
        .where((i) => i.date.year == month.year && i.date.month == month.month)
        .toList();
  }

  double getTotalIncomeForMonth(DateTime month) {
    return getIncomesForMonth(
      month,
    ).fold(0.0, (sum, item) => sum + item.amount);
  }

  double get totalIncomeAllTime {
    return _incomes.fold(0.0, (sum, item) => sum + item.amount);
  }

  // Dynamic Allocation Calculation orchestrator
  Map<String, dynamic> calculateAllocationPreview({
    required double incomeAmount,
    required SettingsEntity settings,
    required List<EmiTrackerEntity> emis,
    required List<BorrowLendEntity> borrowLends,
    required List<AccountEntity> accounts,
    required Map<String, double> accountBalances,
    required double currentSavings,
  }) {
    // 1. Obligations
    final obligationsAnalysis = ObligationAnalysisEngine.analyze(
      emis: emis,
      settings: settings,
    );

    // 2. Outstanding borrowed debt
    double outstandingDebt = borrowLends
        .where((bl) => bl.type == 'borrowed' && bl.status == 'pending')
        .fold(0.0, (sum, bl) => sum + bl.remainingAmount);

    // 3. Savings Recommendation
    final savingsRec = SavingsRecommendationEngine.calculate(
      incomeAmount: incomeAmount,
      totalObligations: obligationsAnalysis.totalObligations,
      outstandingDebt: outstandingDebt,
      currentSavings: currentSavings,
      settings: settings,
    );

    // 4. Debt Recommendation
    final debtRec = DebtOptimizationEngine.calculate(
      borrowLends: borrowLends,
      accounts: accounts,
      accountBalances: accountBalances,
      incomeAmount: incomeAmount,
      totalObligations: obligationsAnalysis.totalObligations,
    );

    return {
      'obligations': obligationsAnalysis,
      'savings': savingsRec,
      'debt': debtRec,
    };
  }
}
