import 'package:equatable/equatable.dart';
import '../../domain/entities/onboarding_draft.dart';
import '../../domain/entities/financial_analysis_result.dart';
import '../../domain/entities/smart_budget_result.dart';

enum OnboardingStatus { initial, loading, active, submitting, completed, error }

class OnboardingState extends Equatable {
  final OnboardingStatus status;
  final OnboardingDraft draft;
  final FinancialAnalysisResult? analysis;
  final SmartBudgetResult? smartBudget;
  final Map<String, double> customCategoryOverrides;
  final String? errorMessage;

  const OnboardingState({
    this.status = OnboardingStatus.initial,
    this.draft = const OnboardingDraft(),
    this.analysis,
    this.smartBudget,
    this.customCategoryOverrides = const {},
    this.errorMessage,
  });

  /// Computes active step indices and total steps based on draft configuration
  List<int> get activeSteps {
    if (draft.startingChoice == 'fresh') {
      return [1, 2, 12, 13]; // Welcome, Start Choice, Review, Final Summary
    }

    final steps = <int>[1, 2, 3]; // Welcome, Start Choice, Accounts
    if (draft.hasCreditCards) {
      steps.add(4); // Credit Card
      steps.add(5); // FD History
    }
    steps.add(7); // Income Inflow Pool (e.g. ₹50,000 Salary)
    if (draft.hasEmis) {
      steps.add(6); // Active EMIs (Priority 1 Deduction)
    }
    if (draft.hasSavings) {
      steps.add(14); // Savings Target (Priority 2 Deduction)
    }
    steps.add(8); // Recurring Expenses (Priority 3 Living Outflows)
    if (draft.hasInvestments) {
      steps.add(9); // Investments
    }
    if (draft.hasGoals) {
      steps.add(10); // Goals
    }
    steps.add(11); // AI Salary Waterfall Analysis & Smart Budget
    steps.add(12); // Pre-final Review
    steps.add(13); // Final Summary

    return steps;
  }

  int get currentStepNumber {
    final steps = activeSteps;
    final idx = steps.indexOf(draft.currentStep);
    return idx != -1 ? idx + 1 : 1;
  }

  int get totalSteps => activeSteps.length;

  bool get isFirstStep => draft.currentStep == 1;
  bool get isLastStep => draft.currentStep == activeSteps.last;

  OnboardingState copyWith({
    OnboardingStatus? status,
    OnboardingDraft? draft,
    FinancialAnalysisResult? analysis,
    SmartBudgetResult? smartBudget,
    Map<String, double>? customCategoryOverrides,
    String? errorMessage,
  }) {
    return OnboardingState(
      status: status ?? this.status,
      draft: draft ?? this.draft,
      analysis: analysis ?? this.analysis,
      smartBudget: smartBudget ?? this.smartBudget,
      customCategoryOverrides: customCategoryOverrides ?? this.customCategoryOverrides,
      errorMessage: errorMessage ?? this.errorMessage,
    );
  }

  @override
  List<Object?> get props => [
        status,
        draft,
        analysis,
        smartBudget,
        customCategoryOverrides,
        errorMessage,
      ];
}
