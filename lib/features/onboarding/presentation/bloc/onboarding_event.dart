import 'package:equatable/equatable.dart';
import '../../domain/entities/onboarding_draft.dart';

abstract class OnboardingEvent extends Equatable {
  const OnboardingEvent();

  @override
  List<Object?> get props => [];
}

class LoadOnboardingDraftEvent extends OnboardingEvent {}

class SelectStartingPointEvent extends OnboardingEvent {
  final String choice; // 'fresh' or 'full'
  const SelectStartingPointEvent(this.choice);

  @override
  List<Object?> get props => [choice];
}

class ToggleSectionEvent extends OnboardingEvent {
  final String sectionKey; // 'creditCards', 'emis', 'investments', 'goals'
  final bool enabled;

  const ToggleSectionEvent({required this.sectionKey, required this.enabled});

  @override
  List<Object?> get props => [sectionKey, enabled];
}

class UpdateAccountsEvent extends OnboardingEvent {
  final List<AccountDraftItem> accounts;
  const UpdateAccountsEvent(this.accounts);

  @override
  List<Object?> get props => [accounts];
}

class UpdateCreditCardEvent extends OnboardingEvent {
  final CreditCardDraftItem? creditCard;
  const UpdateCreditCardEvent(this.creditCard);

  @override
  List<Object?> get props => [creditCard];
}

class UpdateFdLotsEvent extends OnboardingEvent {
  final List<FdLotDraftItem> fdLots;
  const UpdateFdLotsEvent(this.fdLots);

  @override
  List<Object?> get props => [fdLots];
}

class UpdateEmisEvent extends OnboardingEvent {
  final List<EmiDraftItem> emis;
  const UpdateEmisEvent(this.emis);

  @override
  List<Object?> get props => [emis];
}

class UpdateIncomesEvent extends OnboardingEvent {
  final List<IncomeDraftItem> incomes;
  const UpdateIncomesEvent(this.incomes);

  @override
  List<Object?> get props => [incomes];
}

class UpdateObligationsEvent extends OnboardingEvent {
  final List<ObligationDraftItem> recurringExpenses;
  const UpdateObligationsEvent(this.recurringExpenses);

  @override
  List<Object?> get props => [recurringExpenses];
}

class UpdateInvestmentsEvent extends OnboardingEvent {
  final List<InvestmentDraftItem> investments;
  const UpdateInvestmentsEvent(this.investments);

  @override
  List<Object?> get props => [investments];
}

class UpdateGoalsEvent extends OnboardingEvent {
  final List<GoalDraftItem> goals;
  const UpdateGoalsEvent(this.goals);

  @override
  List<Object?> get props => [goals];
}

class UpdateSavingsEvent extends OnboardingEvent {
  final List<SavingsDraftItem> savingsEntries;
  final double? targetMonthlySavings;

  const UpdateSavingsEvent(this.savingsEntries, {this.targetMonthlySavings});

  @override
  List<Object?> get props => [savingsEntries, targetMonthlySavings];
}

class UpdateCustomCategoryBudgetEvent extends OnboardingEvent {
  final String categoryName;
  final double amount;

  const UpdateCustomCategoryBudgetEvent({required this.categoryName, required this.amount});

  @override
  List<Object?> get props => [categoryName, amount];
}

class NextStepEvent extends OnboardingEvent {}

class PreviousStepEvent extends OnboardingEvent {}

class SkipStepEvent extends OnboardingEvent {}

class SaveDraftEvent extends OnboardingEvent {}

class CompleteOnboardingEvent extends OnboardingEvent {}
