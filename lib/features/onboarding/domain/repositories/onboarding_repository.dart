import '../entities/onboarding_draft.dart';
import '../entities/financial_analysis_result.dart';
import '../entities/smart_budget_result.dart';

abstract class OnboardingRepository {
  Future<OnboardingDraft?> getDraft();
  Future<void> saveDraft(OnboardingDraft draft);
  Future<void> clearDraft();
  Future<bool> isOnboardingCompleted();
  Future<void> setOnboardingCompleted(bool completed);
  
  FinancialAnalysisResult analyzeFinancialHealth(OnboardingDraft draft);
  SmartBudgetResult generateSmartBudget(OnboardingDraft draft, {Map<String, double>? customOverrides});
  
  Future<void> commitOnboardingData({
    required OnboardingDraft draft,
    required SmartBudgetResult smartBudget,
  });
}
