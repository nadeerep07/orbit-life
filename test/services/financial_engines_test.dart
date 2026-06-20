import 'package:flutter_test/flutter_test.dart';
import 'package:my_budget_pro/domain/entities/settings_entity.dart';
import 'package:my_budget_pro/domain/entities/emi_tracker_entity.dart';
import 'package:my_budget_pro/domain/entities/borrow_lend_entity.dart';
import 'package:my_budget_pro/domain/entities/account_entity.dart';
import 'package:my_budget_pro/core/services/obligation_analysis_engine.dart';
import 'package:my_budget_pro/core/services/savings_recommendation_engine.dart';
import 'package:my_budget_pro/core/services/debt_optimization_engine.dart';
import 'package:my_budget_pro/core/services/spendable_wallet_engine.dart';
import 'package:my_budget_pro/core/services/daily_spending_engine.dart';
import 'package:my_budget_pro/core/services/financial_health_engine.dart';

void main() {
  group('ObligationAnalysisEngine Tests', () {
    test('calculate active EMIs and recurring category budgets', () {
      final emis = [
        EmiTrackerEntity(
          id: 'emi_1',
          title: 'Car Loan',
          provider: 'HDFC',
          totalAmount: 100000,
          startDate: DateTime.now(),
          monthlyEmi: 5000,
          totalMonths: 24,
          paidMonths: 5,
        ),
        EmiTrackerEntity(
          id: 'emi_2',
          title: 'Finished Loan',
          provider: 'SBI',
          totalAmount: 50000,
          startDate: DateTime.now(),
          monthlyEmi: 2000,
          totalMonths: 12,
          paidMonths: 12, // finished, should not count
        ),
      ];

      final settings = const SettingsEntity.defaultSettings().copyWith(
        categoryBudgets: {
          'Rent Allocation': 12000,
          'Electricity Bill': 3000,
          'Groceries': 4000, // variable, should not count
        },
      );

      final analysis = ObligationAnalysisEngine.analyze(emis: emis, settings: settings);

      expect(analysis.totalObligations, equals(20000.0)); // 5000 emi + 12000 rent + 3000 electricity
      expect(analysis.obligations.length, equals(3));
    });
  });

  group('SavingsRecommendationEngine Tests', () {
    test('calculate savings targets under constraints', () {
      final settings = const SettingsEntity.defaultSettings().copyWith(
        emergencyFundGoal: 50000,
      );

      // Low savings (current 5000 / goal 50000) -> boost recommended rate
      final recs = SavingsRecommendationEngine.calculate(
        incomeAmount: 50000,
        totalObligations: 20000,
        outstandingDebt: 10000,
        currentSavings: 5000,
        settings: settings,
      );

      expect(recs.minimum, isNonNegative);
      expect(recs.recommended, greaterThanOrEqualTo(recs.minimum));
      expect(recs.stretch, greaterThanOrEqualTo(recs.recommended));
    });
  });

  group('DebtOptimizationEngine Tests', () {
    test('calculate debt payoff recommendations', () {
      final borrowLends = [
        BorrowLendEntity(
          id: 'bl_1',
          personName: 'Alice',
          phoneNumber: '1234567890',
          amount: 10000,
          type: 'borrowed',
          date: DateTime.now().subtract(const Duration(days: 45)),
          dueDate: DateTime.now().subtract(const Duration(days: 5)), // overdue
          status: 'pending',
          accountId: 'cash',
        ),
      ];

      final accounts = [
        const AccountEntity(id: 'sbi', name: 'SBI', openingBalance: 10000),
        const AccountEntity(id: 'cc', name: 'Super Money Credit Card', openingBalance: 0),
      ];

      final balances = {
        'sbi': 5000.0,
        'cc': -4000.0, // negative balance credit card debt
      };

      final recs = DebtOptimizationEngine.calculate(
        borrowLends: borrowLends,
        accounts: accounts,
        accountBalances: balances,
        incomeAmount: 50000,
        totalObligations: 20000,
      );

      expect(recs.minimumPayment, greaterThan(0));
      expect(recs.recommendedPayment, greaterThanOrEqualTo(recs.minimumPayment));
    });
  });

  group('SpendableWalletEngine Tests', () {
    test('subtract obligations, savings, and debt correctly', () {
      final wallet = SpendableWalletEngine.calculate(
        incomeAmount: 60000,
        totalObligations: 20000,
        savingsAllocation: 10000,
        debtAllocation: 5000,
      );

      expect(wallet.totalSpendableAmount, equals(25000.0));
    });
  });

  group('DailySpendingEngine Tests', () {
    test('calculate safe limits', () {
      final report = DailySpendingEngine.calculate(
        spendableWalletAmount: 30000,
        currentMonthSpent: 8000,
        currentTotalBalance: 15000,
        currentDate: DateTime(2026, 6, 20), // 11 days remaining (20 to 30)
      );

      expect(report.dailyLimit, equals(2000.0)); // (30000 - 8000) / 11
      expect(report.weeklyLimit, equals(14000.0));
    });
  });

  group('FinancialHealthEngine Tests', () {
    test('evaluate score and generate recommendations', () {
      final report = FinancialHealthEngine.calculate(
        monthlyIncome: 50000,
        monthlyExpenses: 25000,
        outstandingDebt: 10000,
        currentEmergencyFund: 15000,
        targetEmergencyFund: 30000,
        totalBudgetLimit: 30000,
        categoryBudgets: {'Food': 5000, 'Rent': 10000},
        categorySpent: {'Food': 4000, 'Rent': 10000},
      );

      expect(report.score, greaterThanOrEqualTo(0));
      expect(report.score, lessThanOrEqualTo(100));
      expect(report.feedback, isNotEmpty);
      expect(report.improvements, isNotEmpty);
    });
  });
}
