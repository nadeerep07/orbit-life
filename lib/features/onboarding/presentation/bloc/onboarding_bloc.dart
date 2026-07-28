import 'package:flutter_bloc/flutter_bloc.dart';
import '../../domain/entities/onboarding_draft.dart';
import '../../domain/repositories/onboarding_repository.dart';
import 'onboarding_event.dart';
import 'onboarding_state.dart';

class OnboardingBloc extends Bloc<OnboardingEvent, OnboardingState> {
  final OnboardingRepository repository;

  OnboardingBloc({required this.repository}) : super(const OnboardingState()) {
    on<LoadOnboardingDraftEvent>(_onLoadDraft);
    on<SelectStartingPointEvent>(_onSelectStartingPoint);
    on<ToggleSectionEvent>(_onToggleSection);
    on<UpdateAccountsEvent>(_onUpdateAccounts);
    on<UpdateCreditCardEvent>(_onUpdateCreditCard);
    on<UpdateFdLotsEvent>(_onUpdateFdLots);
    on<UpdateEmisEvent>(_onUpdateEmis);
    on<UpdateIncomesEvent>(_onUpdateIncomes);
    on<UpdateObligationsEvent>(_onUpdateObligations);
    on<UpdateInvestmentsEvent>(_onUpdateInvestments);
    on<UpdateSavingsEvent>(_onUpdateSavings);
    on<UpdateGoalsEvent>(_onUpdateGoals);
    on<UpdateCustomCategoryBudgetEvent>(_onUpdateCustomCategoryBudget);
    on<NextStepEvent>(_onNextStep);
    on<PreviousStepEvent>(_onPreviousStep);
    on<SkipStepEvent>(_onSkipStep);
    on<SaveDraftEvent>(_onSaveDraft);
    on<CompleteOnboardingEvent>(_onCompleteOnboarding);
  }

  Future<void> _onLoadDraft(
    LoadOnboardingDraftEvent event,
    Emitter<OnboardingState> emit,
  ) async {
    emit(state.copyWith(status: OnboardingStatus.loading));
    try {
      final savedDraft = await repository.getDraft();
      final draft = savedDraft ?? state.draft;
      final analysis = repository.analyzeFinancialHealth(draft);
      final budget = repository.generateSmartBudget(
        draft,
        customOverrides: state.customCategoryOverrides,
      );

      emit(state.copyWith(
        status: OnboardingStatus.active,
        draft: draft,
        analysis: analysis,
        smartBudget: budget,
      ));
    } catch (e) {
      emit(state.copyWith(
        status: OnboardingStatus.error,
        errorMessage: e.toString(),
      ));
    }
  }

  Future<void> _onSelectStartingPoint(
    SelectStartingPointEvent event,
    Emitter<OnboardingState> emit,
  ) async {
    final updatedDraft = state.draft.copyWith(startingChoice: event.choice);
    await repository.saveDraft(updatedDraft);
    _recalculateState(emit, updatedDraft);
  }

  Future<void> _onToggleSection(
    ToggleSectionEvent event,
    Emitter<OnboardingState> emit,
  ) async {
    var updatedDraft = state.draft;
    switch (event.sectionKey) {
      case 'creditCards':
        updatedDraft = updatedDraft.copyWith(hasCreditCards: event.enabled);
        break;
      case 'emis':
        updatedDraft = updatedDraft.copyWith(hasEmis: event.enabled);
        break;
      case 'investments':
        updatedDraft = updatedDraft.copyWith(hasInvestments: event.enabled);
        break;
      case 'savings':
        updatedDraft = updatedDraft.copyWith(hasSavings: event.enabled);
        break;
      case 'goals':
        updatedDraft = updatedDraft.copyWith(hasGoals: event.enabled);
        break;
    }
    await repository.saveDraft(updatedDraft);
    _recalculateState(emit, updatedDraft);
  }

  Future<void> _onUpdateAccounts(
    UpdateAccountsEvent event,
    Emitter<OnboardingState> emit,
  ) async {
    final updated = state.draft.copyWith(accounts: event.accounts);
    await repository.saveDraft(updated);
    _recalculateState(emit, updated);
  }

  Future<void> _onUpdateCreditCard(
    UpdateCreditCardEvent event,
    Emitter<OnboardingState> emit,
  ) async {
    final updated = state.draft.copyWith(creditCard: event.creditCard);
    await repository.saveDraft(updated);
    _recalculateState(emit, updated);
  }

  Future<void> _onUpdateFdLots(
    UpdateFdLotsEvent event,
    Emitter<OnboardingState> emit,
  ) async {
    final updated = state.draft.copyWith(fdLots: event.fdLots);
    await repository.saveDraft(updated);
    _recalculateState(emit, updated);
  }

  Future<void> _onUpdateEmis(
    UpdateEmisEvent event,
    Emitter<OnboardingState> emit,
  ) async {
    final updated = state.draft.copyWith(emis: event.emis);
    await repository.saveDraft(updated);
    _recalculateState(emit, updated);
  }

  Future<void> _onUpdateIncomes(
    UpdateIncomesEvent event,
    Emitter<OnboardingState> emit,
  ) async {
    final updated = state.draft.copyWith(incomes: event.incomes);
    await repository.saveDraft(updated);
    _recalculateState(emit, updated);
  }

  Future<void> _onUpdateObligations(
    UpdateObligationsEvent event,
    Emitter<OnboardingState> emit,
  ) async {
    final updated = state.draft.copyWith(recurringExpenses: event.recurringExpenses);
    await repository.saveDraft(updated);
    _recalculateState(emit, updated);
  }

  Future<void> _onUpdateInvestments(
    UpdateInvestmentsEvent event,
    Emitter<OnboardingState> emit,
  ) async {
    final updated = state.draft.copyWith(investments: event.investments);
    await repository.saveDraft(updated);
    _recalculateState(emit, updated);
  }

  Future<void> _onUpdateSavings(
    UpdateSavingsEvent event,
    Emitter<OnboardingState> emit,
  ) async {
    final updated = state.draft.copyWith(
      savingsEntries: event.savingsEntries,
      targetMonthlySavings: event.targetMonthlySavings ?? state.draft.targetMonthlySavings,
    );
    await repository.saveDraft(updated);
    _recalculateState(emit, updated);
  }

  Future<void> _onUpdateGoals(
    UpdateGoalsEvent event,
    Emitter<OnboardingState> emit,
  ) async {
    final updated = state.draft.copyWith(goals: event.goals);
    await repository.saveDraft(updated);
    _recalculateState(emit, updated);
  }

  Future<void> _onUpdateCustomCategoryBudget(
    UpdateCustomCategoryBudgetEvent event,
    Emitter<OnboardingState> emit,
  ) async {
    final newOverrides = Map<String, double>.from(state.customCategoryOverrides);
    newOverrides[event.categoryName] = event.amount;
    final budget = repository.generateSmartBudget(
      state.draft,
      customOverrides: newOverrides,
    );
    emit(state.copyWith(
      customCategoryOverrides: newOverrides,
      smartBudget: budget,
    ));
  }

  Future<void> _onNextStep(
    NextStepEvent event,
    Emitter<OnboardingState> emit,
  ) async {
    final activeSteps = state.activeSteps;
    final currentStep = state.draft.currentStep;
    final currentIdx = activeSteps.indexOf(currentStep);

    if (currentIdx != -1 && currentIdx < activeSteps.length - 1) {
      final nextStepVal = activeSteps[currentIdx + 1];
      final updatedDraft = state.draft.copyWith(currentStep: nextStepVal);
      await repository.saveDraft(updatedDraft);
      _recalculateState(emit, updatedDraft);
    }
  }

  Future<void> _onPreviousStep(
    PreviousStepEvent event,
    Emitter<OnboardingState> emit,
  ) async {
    final activeSteps = state.activeSteps;
    final currentStep = state.draft.currentStep;
    final currentIdx = activeSteps.indexOf(currentStep);

    if (currentIdx > 0) {
      final prevStepVal = activeSteps[currentIdx - 1];
      final updatedDraft = state.draft.copyWith(currentStep: prevStepVal);
      await repository.saveDraft(updatedDraft);
      _recalculateState(emit, updatedDraft);
    }
  }

  Future<void> _onSkipStep(
    SkipStepEvent event,
    Emitter<OnboardingState> emit,
  ) async {
    add(NextStepEvent());
  }

  Future<void> _onSaveDraft(
    SaveDraftEvent event,
    Emitter<OnboardingState> emit,
  ) async {
    await repository.saveDraft(state.draft);
  }

  Future<void> _onCompleteOnboarding(
    CompleteOnboardingEvent event,
    Emitter<OnboardingState> emit,
  ) async {
    emit(state.copyWith(status: OnboardingStatus.submitting));
    try {
      final budget = state.smartBudget ?? repository.generateSmartBudget(state.draft);
      await repository.commitOnboardingData(
        draft: state.draft,
        smartBudget: budget,
      );
      emit(state.copyWith(
        status: OnboardingStatus.completed,
        draft: state.draft.copyWith(isCompleted: true),
      ));
    } catch (e) {
      emit(state.copyWith(
        status: OnboardingStatus.error,
        errorMessage: e.toString(),
      ));
    }
  }

  void _recalculateState(Emitter<OnboardingState> emit, OnboardingDraft draft) {
    final analysis = repository.analyzeFinancialHealth(draft);
    final budget = repository.generateSmartBudget(
      draft,
      customOverrides: state.customCategoryOverrides,
    );
    emit(state.copyWith(
      status: OnboardingStatus.active,
      draft: draft,
      analysis: analysis,
      smartBudget: budget,
    ));
  }
}
