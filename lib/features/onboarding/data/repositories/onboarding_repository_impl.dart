import 'dart:math';
import 'package:uuid/uuid.dart';
import '../../../../domain/repositories/account_repository.dart';
import '../../../../domain/repositories/category_repository.dart';
import '../../../../domain/repositories/expense_repository.dart';
import '../../../../domain/repositories/income_repository.dart';
import '../../../../domain/repositories/goal_repository.dart';
import '../../../../domain/repositories/emi_tracker_repository.dart';
import '../../../../domain/repositories/investment_repository.dart';
import '../../../../domain/repositories/settings_repository.dart';
import '../../../../domain/entities/account_entity.dart';
import '../../../../domain/entities/category_entity.dart';
import '../../../../domain/entities/expense_entity.dart';
import '../../../../domain/entities/income_entity.dart';
import '../../../../domain/entities/goal_entity.dart';
import '../../../../domain/entities/emi_tracker_entity.dart';
import '../../../../domain/entities/investment_entity.dart';
import '../../../credit_card/domain/repositories/credit_card_repository.dart';
import '../../../credit_card/domain/entities/credit_card_account_entity.dart';
import '../datasources/onboarding_local_data_source.dart';
import '../../domain/entities/onboarding_draft.dart';
import '../../domain/entities/financial_analysis_result.dart';
import '../../domain/entities/smart_budget_result.dart';
import '../../domain/repositories/onboarding_repository.dart';

class OnboardingRepositoryImpl implements OnboardingRepository {
  final OnboardingLocalDataSource localDataSource;
  final AccountRepository accountRepository;
  final CreditCardRepository creditCardRepository;
  final EmiTrackerRepository emiTrackerRepository;
  final IncomeRepository incomeRepository;
  final ExpenseRepository expenseRepository;
  final InvestmentRepository investmentRepository;
  final GoalRepository goalRepository;
  final CategoryRepository categoryRepository;
  final SettingsRepository? settingsRepository;
  final Uuid _uuid = const Uuid();

  OnboardingRepositoryImpl({
    required this.localDataSource,
    required this.accountRepository,
    required this.creditCardRepository,
    required this.emiTrackerRepository,
    required this.incomeRepository,
    required this.expenseRepository,
    required this.investmentRepository,
    required this.goalRepository,
    required this.categoryRepository,
    this.settingsRepository,
  });

  @override
  Future<OnboardingDraft?> getDraft() => localDataSource.getDraft();

  @override
  Future<void> saveDraft(OnboardingDraft draft) => localDataSource.saveDraft(draft);

  @override
  Future<void> clearDraft() => localDataSource.clearDraft();

  @override
  Future<bool> isOnboardingCompleted() => localDataSource.isOnboardingCompleted();

  @override
  Future<void> setOnboardingCompleted(bool completed) => localDataSource.setOnboardingCompleted(completed);

  @override
  FinancialAnalysisResult analyzeFinancialHealth(OnboardingDraft draft) {
    double totalLiquidCash = 0.0;
    for (var acc in draft.accounts) {
      if (acc.includeInNetWorth && !acc.importLater) {
        totalLiquidCash += acc.currentBalance;
      }
    }

    double totalInvestments = draft.investments.fold<double>(0.0, (sum, item) => sum + item.amount);
    double totalFdValue = draft.fdLots.fold<double>(0.0, (sum, item) => sum + (item.currentValue ?? item.principal));
    double ccUsed = draft.creditCard?.usedCredit ?? 0.0;
    double ccLimit = draft.creditCard?.creditLimit ?? 0.0;
    double totalDebt = draft.emis.fold<double>(0.0, (sum, item) => sum + item.outstandingAmount) + ccUsed;

    double netWorth = totalLiquidCash + totalInvestments + totalFdValue - totalDebt;

    double monthlyIncome = draft.incomes.fold<double>(0.0, (sum, item) {
      if (item.frequency == 'Weekly') return sum + (item.amount * 4);
      if (item.frequency == 'Biweekly') return sum + (item.amount * 2);
      return sum + item.amount;
    });

    double monthlyExpenses = draft.recurringExpenses.fold<double>(0.0, (sum, item) => sum + item.amount);
    double monthlyEmis = draft.emis.fold<double>(0.0, (sum, item) => sum + item.monthlyAmount);
    double monthlyFreeCash = max(0.0, monthlyIncome - monthlyExpenses - monthlyEmis);

    double debtToIncome = monthlyIncome > 0 ? ((monthlyEmis / monthlyIncome) * 100) : 0.0;
    double savingsRate = monthlyIncome > 0 ? max(0.0, (monthlyFreeCash / monthlyIncome) * 100) : 0.0;
    double creditUtilization = ccLimit > 0 ? ((ccUsed / ccLimit) * 100) : 0.0;
    double emergencyFundMonths = monthlyExpenses > 0 ? (totalLiquidCash / monthlyExpenses) : 0.0;

    int healthScore = 50;
    if (savingsRate >= 20) {
      healthScore += 15;
    } else if (savingsRate >= 10) healthScore += 8;

    if (debtToIncome <= 20) {
      healthScore += 15;
    } else if (debtToIncome <= 35) healthScore += 8;
    else healthScore -= 10;

    if (emergencyFundMonths >= 3) {
      healthScore += 15;
    } else if (emergencyFundMonths >= 1) healthScore += 5;

    if (creditUtilization <= 30) {
      healthScore += 10;
    } else if (creditUtilization > 70) healthScore -= 10;

    healthScore = max(10, min(99, healthScore));

    String riskLevel = 'Low';
    if (debtToIncome > 40 || emergencyFundMonths < 1) {
      riskLevel = 'High';
    } else if (debtToIncome > 25 || emergencyFundMonths < 3) riskLevel = 'Moderate';

    final Map<String, String> explanations = {
      'Health Score': 'Calculated based on your savings rate (${savingsRate.toStringAsFixed(0)}%), debt-to-income (${debtToIncome.toStringAsFixed(0)}%), and liquid emergency runway.',
      'Emergency Fund': 'You currently have ${emergencyFundMonths.toStringAsFixed(1)} months of fixed expenses saved in liquid cash balances.',
      'Debt Ratio': 'Your EMIs consume ${debtToIncome.toStringAsFixed(0)}% of your gross monthly income.',
      'Credit Utilization': ccLimit > 0
          ? 'You are utilizing ${creditUtilization.toStringAsFixed(0)}% of your available secured credit limit.'
          : 'No credit card utilization detected.',
      'Monthly Free Cash': '₹${monthlyFreeCash.toStringAsFixed(0)} remaining each month after covering fixed bills and active EMIs.',
    };

    return FinancialAnalysisResult(
      healthScore: healthScore,
      netWorth: netWorth,
      totalLiquidCash: totalLiquidCash,
      monthlyIncome: monthlyIncome,
      monthlyExpenses: monthlyExpenses,
      monthlyEmis: monthlyEmis,
      monthlyFreeCash: monthlyFreeCash,
      debtToIncomeRatio: debtToIncome,
      savingsRate: savingsRate,
      creditUtilizationRatio: creditUtilization,
      emergencyFundCoverageMonths: emergencyFundMonths,
      riskLevel: riskLevel,
      metricExplanations: explanations,
    );
  }

  @override
  SmartBudgetResult generateSmartBudget(OnboardingDraft draft, {Map<String, double>? customOverrides}) {
    double monthlyIncome = draft.incomes.fold<double>(0.0, (sum, item) {
      if (item.frequency == 'Weekly') return sum + (item.amount * 4);
      if (item.frequency == 'Biweekly') return sum + (item.amount * 2);
      return sum + item.amount;
    });

    if (monthlyIncome <= 0) monthlyIncome = 50000; // Baseline default fallback

    double totalEmis = draft.hasEmis ? draft.emis.fold<double>(0.0, (sum, item) => sum + item.monthlyAmount) : 0.0;
    double targetSavings = draft.hasSavings ? draft.savingsEntries.fold<double>(0.0, (sum, s) => sum + s.monthlyContribution) : 0.0;

    // Salary Waterfall Flow: Income - Priority 1 (EMIs) - Priority 2 (Savings Target) = Spendable Living Pool
    double netSpendablePool = max(0.0, monthlyIncome - totalEmis - targetSavings);
    double fixedObligations = draft.recurringExpenses.fold<double>(0.0, (sum, item) => sum + item.amount);

    final defaultAllocations = <String, double>{
      'Housing & Rent': 0.35 * netSpendablePool,
      'Food & Dining': 0.20 * netSpendablePool,
      'Transport & Fuel': 0.12 * netSpendablePool,
      'Utilities & Bills': 0.10 * netSpendablePool,
      'Shopping': 0.08 * netSpendablePool,
      'Entertainment & Leisure': 0.08 * netSpendablePool,
      'Health & Medical': 0.07 * netSpendablePool,
    };

    if (targetSavings > 0) {
      defaultAllocations['Savings Reserve'] = targetSavings;
    }

    for (var exp in draft.recurringExpenses) {
      if (exp.name.toLowerCase().contains('rent')) {
        defaultAllocations['Housing & Rent'] = max(defaultAllocations['Housing & Rent']!, exp.amount);
      } else if (exp.name.toLowerCase().contains('food')) {
        defaultAllocations['Food & Dining'] = max(defaultAllocations['Food & Dining']!, exp.amount);
      } else if (exp.name.toLowerCase().contains('fuel')) {
        defaultAllocations['Transport & Fuel'] = max(defaultAllocations['Transport & Fuel']!, exp.amount);
      }
    }

    final categories = <SmartCategoryBudget>[];
    double totalRecommended = 0.0;

    defaultAllocations.forEach((catName, recommended) {
      double finalAmount = customOverrides != null && customOverrides.containsKey(catName)
          ? customOverrides[catName]!
          : recommended;

      totalRecommended += finalAmount;
      categories.add(SmartCategoryBudget(
        categoryId: catName.toLowerCase().replaceAll(' ', '_'),
        categoryName: catName,
        recommendedAmount: finalAmount,
        currentAmount: 0.0,
        reasonExplanation: 'Priority waterfall allocation based on net spendable pool ₹${netSpendablePool.toStringAsFixed(0)} after EMIs & Savings.',
        confidencePercentage: 92.0,
        isLocked: false,
      ));
    });

    return SmartBudgetResult(
      categoryBudgets: categories,
      totalRecommendedBudget: totalRecommended,
      totalIncome: monthlyIncome,
      totalFixedObligations: fixedObligations + totalEmis,
      overallConfidence: 94.0,
    );
  }

  @override
  Future<void> commitOnboardingData({
    required OnboardingDraft draft,
    required SmartBudgetResult smartBudget,
  }) async {
    final now = DateTime.now();

    // 1. Commit Accounts
    if (draft.startingChoice == 'full' && draft.accounts.isNotEmpty) {
      for (var item in draft.accounts) {
        if (!item.importLater) {
          final account = AccountEntity(
            id: item.id.isEmpty ? _uuid.v4() : item.id,
            name: item.name,
            openingBalance: item.currentBalance,
          );
          await accountRepository.addAccount(account);
        }
      }
    }

    // 2. Commit Credit Card
    if (draft.startingChoice == 'full' && draft.hasCreditCards && draft.creditCard != null) {
      final cc = draft.creditCard!;
      final ccEntity = CreditCardAccountEntity(
        id: cc.id.isEmpty ? 'supermoney' : cc.id,
        name: cc.name,
        creditLimit: cc.creditLimit,
        availableCredit: cc.availableCredit,
        usedCredit: cc.usedCredit,
        statementDateDay: cc.statementDateDay,
        dueDateDay: cc.dueDateDay,
        initialCreditMigrated: true,
        lastUpdated: now,
      );
      await creditCardRepository.saveCreditCardAccount(ccEntity);

      // Create matching account representation if needed
      final ccAccountRepr = AccountEntity(
        id: ccEntity.id,
        name: ccEntity.name,
        openingBalance: ccEntity.availableCredit,
      );
      await accountRepository.addAccount(ccAccountRepr);
    }

    // 3. Commit FD Lots (Marked as MigrationLot = true & ImportedHistoricalFD = true)
    if (draft.startingChoice == 'full' && draft.hasCreditCards && draft.fdLots.isNotEmpty) {
      final hasExplicitCard = draft.creditCard != null;
      for (var lot in draft.fdLots) {
        await creditCardRepository.depositFd(
          amount: lot.principal,
          depositDate: lot.depositDate,
          remarks: '${lot.bank.isNotEmpty ? "${lot.bank} - " : ""}${lot.remarks} [ImportedHistoricalFD]',
          increaseCreditLimit: !hasExplicitCard,
        );
      }
    }

    // 4. Commit EMIs
    if (draft.startingChoice == 'full' && draft.hasEmis && draft.emis.isNotEmpty) {
      for (var emi in draft.emis) {
        final emiEntity = EmiTrackerEntity(
          id: emi.id.isEmpty ? _uuid.v4() : emi.id,
          title: emi.title,
          provider: emi.bank.isEmpty ? 'Lender' : emi.bank,
          totalAmount: emi.monthlyAmount * emi.remainingMonths,
          monthlyEmi: emi.monthlyAmount,
          totalMonths: emi.remainingMonths,
          paidMonths: 0,
          startDate: now.subtract(const Duration(days: 30)),
          notes: 'Active EMI from onboarding wizard',
        );
        await emiTrackerRepository.addEmi(emiEntity);
      }
    }

    // 5. Commit Incomes
    // Income sources in setup wizard represent baseline monthly income capacity for budget allocations,
    // Priority Waterfall metrics, and savings goal projections.
    // They are NOT credited as transactions on Day 1. No IncomeEntity transactions should be inserted here.

    // 6. Commit Recurring Expenses (Fixed Obligations)
    // Recurring expenses in setup wizard represent monthly budget commitments, NOT spent transactions.
    // They are used to calculate dynamic Category budget limits (Step 9) and safe spendable pools.
    // No ExpenseEntity transactions should be inserted here.

    // 7. Commit Investments
    if (draft.startingChoice == 'full' && draft.hasInvestments && draft.investments.isNotEmpty) {
      for (var inv in draft.investments) {
        final invEntity = InvestmentEntity(
          id: inv.id.isEmpty ? _uuid.v4() : inv.id,
          name: inv.title,
          type: inv.type,
          investedAmount: inv.amount,
          currentValue: inv.amount,
          date: now,
          interestRate: inv.returnsRate,
          notes: 'Configured during setup wizard',
        );
        await investmentRepository.addInvestment(invEntity);
      }
    }

    // 8. Commit Goals
    if (draft.startingChoice == 'full' && draft.hasGoals && draft.goals.isNotEmpty) {
      for (var g in draft.goals) {
        final goalEntity = GoalEntity(
          id: g.id.isEmpty ? _uuid.v4() : g.id,
          name: g.title,
          targetAmount: g.targetAmount,
          currentSavings: g.currentSaved,
          targetDate: g.targetDate,
        );
        await goalRepository.addGoal(goalEntity);
      }
    }

    // 9. Commit Smart Category Budgets
    for (var b in smartBudget.categoryBudgets) {
      final category = CategoryEntity(
        id: b.categoryId,
        name: b.categoryName,
        monthlyBudget: b.recommendedAmount,
        month: now.month,
        year: now.year,
      );
      await categoryRepository.addCategory(category);
    }

    // 10. Update Monthly Budget Limit & Savings Target in Settings to match user's real setup calculation
    if (settingsRepository != null) {
      try {
        final currentSettings = await settingsRepository!.getSettings();
        final updatedSettings = currentSettings.copyWith(
          monthlyBudgetLimit: smartBudget.totalRecommendedBudget,
          savingsGoal: draft.targetMonthlySavings > 0 ? draft.targetMonthlySavings : currentSettings.savingsGoal,
        );
        await settingsRepository!.saveSettings(updatedSettings);
      } catch (_) {}
    }

    // 11. Mark Onboarding Completed & Clear Draft
    await setOnboardingCompleted(true);
    await clearDraft();
  }
}
