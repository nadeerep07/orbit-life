import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:my_budget_pro/core/utils/app_routes.dart';
import '../bloc/onboarding_bloc.dart';
import '../bloc/onboarding_event.dart';
import '../bloc/onboarding_state.dart';
import '../widgets/step1_welcome_view.dart';
import '../widgets/step1_5_starting_point_view.dart';
import '../widgets/step2_accounts_view.dart';
import '../widgets/step3_credit_card_view.dart';
import '../widgets/step4_import_fd_view.dart';
import '../widgets/step5_active_emis_view.dart';
import '../widgets/step6_income_view.dart';
import '../widgets/step7_recurring_expenses_view.dart';
import '../widgets/step8_investments_view.dart';
import '../widgets/step8_5_savings_view.dart';
import '../widgets/step9_goals_view.dart';
import '../widgets/step10_ai_analysis_view.dart';
import '../widgets/review_summary_view.dart';
import '../widgets/final_completion_view.dart';

class OnboardingWizardScreen extends StatefulWidget {
  const OnboardingWizardScreen({super.key});

  @override
  State<OnboardingWizardScreen> createState() => _OnboardingWizardScreenState();
}

class _OnboardingWizardScreenState extends State<OnboardingWizardScreen> {
  @override
  void initState() {
    super.initState();
    context.read<OnboardingBloc>().add(LoadOnboardingDraftEvent());
  }

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<OnboardingBloc, OnboardingState>(
      listener: (context, state) {
        if (state.status == OnboardingStatus.completed) {
          Navigator.pushNamedAndRemoveUntil(context, AppRoutes.dashboard, (route) => false);
        } else if (state.status == OnboardingStatus.error && state.errorMessage != null) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Onboarding Error: ${state.errorMessage}'),
              backgroundColor: Colors.redAccent,
            ),
          );
        }
      },
      builder: (context, state) {
        if (state.status == OnboardingStatus.loading || state.status == OnboardingStatus.initial) {
          return const Scaffold(
            backgroundColor: Color(0xFF0B0F19),
            body: Center(
              child: CircularProgressIndicator(color: Color(0xFF3B82F6)),
            ),
          );
        }

        final currentStepVal = state.draft.currentStep;
        final currentNumber = state.currentStepNumber;
        final totalNumber = state.totalSteps;
        final progressVal = currentNumber / totalNumber;

        return Scaffold(
          backgroundColor: const Color(0xFF0B0F19),
          body: SafeArea(
            child: Column(
              children: [
                // Top Floating Glassmorphic Progress Header
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                  decoration: BoxDecoration(
                    color: const Color(0xFF151C2C).withValues(alpha: 0.8),
                    border: const Border(
                      bottom: BorderSide(color: Color(0xFF26334D)),
                    ),
                  ),
                  child: Column(
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                                decoration: BoxDecoration(
                                  gradient: const LinearGradient(
                                    colors: [Color(0xFF2563EB), Color(0xFF7C3AED)],
                                  ),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Text(
                                  'Step $currentNumber of $totalNumber',
                                  style: const TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.white,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          Row(
                            children: [
                              InkWell(
                                onTap: () {
                                  context.read<OnboardingBloc>().add(SaveDraftEvent());
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                      content: Text('Draft saved successfully! You can resume anytime.'),
                                      backgroundColor: Color(0xFF10B981),
                                    ),
                                  );
                                },
                                borderRadius: BorderRadius.circular(10),
                                child: Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFF1E293B),
                                    borderRadius: BorderRadius.circular(10),
                                    border: Border.all(color: const Color(0xFF334155)),
                                  ),
                                  child: const Row(
                                    children: [
                                      Icon(Icons.bookmark_border_rounded, size: 14, color: Colors.white70),
                                      SizedBox(width: 4),
                                      Text(
                                        'Save Draft',
                                        style: TextStyle(fontSize: 11, color: Colors.white70, fontWeight: FontWeight.bold),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                              if (!state.isFirstStep && !state.isLastStep) ...[
                                const SizedBox(width: 8),
                                TextButton(
                                  onPressed: () {
                                    context.read<OnboardingBloc>().add(SkipStepEvent());
                                  },
                                  style: TextButton.styleFrom(
                                    foregroundColor: const Color(0xFF94A3B8),
                                    visualDensity: VisualDensity.compact,
                                  ),
                                  child: const Text('Skip', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
                                ),
                              ],
                            ],
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(6),
                        child: LinearProgressIndicator(
                          value: progressVal,
                          minHeight: 5,
                          backgroundColor: const Color(0xFF1E293B),
                          valueColor: const AlwaysStoppedAnimation<Color>(Color(0xFF3B82F6)),
                        ),
                      ),
                    ],
                  ),
                ),

                // Main Content View
                Expanded(
                  child: Theme(
                    data: ThemeData.dark().copyWith(
                      scaffoldBackgroundColor: const Color(0xFF0B0F19),
                      colorScheme: const ColorScheme.dark(
                        primary: Color(0xFF3B82F6),
                        surface: Color(0xFF151C2C),
                      ),
                    ),
                    child: AnimatedSwitcher(
                      duration: const Duration(milliseconds: 300),
                      child: KeyedSubtree(
                        key: ValueKey(currentStepVal),
                        child: _buildStepView(context, state, currentStepVal),
                      ),
                    ),
                  ),
                ),

                // Floating Glassmorphic Bottom Navigation Dock
                if (!state.isFirstStep && !state.isLastStep)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
                    decoration: BoxDecoration(
                      color: const Color(0xFF151C2C).withValues(alpha: 0.95),
                      border: const Border(
                        top: BorderSide(color: Color(0xFF26334D)),
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.4),
                          blurRadius: 16,
                          offset: const Offset(0, -4),
                        ),
                      ],
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        OutlinedButton.icon(
                          onPressed: () {
                            context.read<OnboardingBloc>().add(PreviousStepEvent());
                          },
                          style: OutlinedButton.styleFrom(
                            side: const BorderSide(color: Color(0xFF334155)),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                            foregroundColor: Colors.white70,
                          ),
                          icon: const Icon(Icons.arrow_back_rounded, size: 18),
                          label: const Text('Previous', style: TextStyle(fontWeight: FontWeight.bold)),
                        ),
                        Container(
                          decoration: BoxDecoration(
                            gradient: const LinearGradient(
                              colors: [Color(0xFF2563EB), Color(0xFF3B82F6)],
                            ),
                            borderRadius: BorderRadius.circular(14),
                            boxShadow: [
                              BoxShadow(
                                color: const Color(0xFF2563EB).withValues(alpha: 0.4),
                                blurRadius: 12,
                                offset: const Offset(0, 4),
                              ),
                            ],
                          ),
                          child: ElevatedButton.icon(
                            onPressed: () {
                              context.read<OnboardingBloc>().add(NextStepEvent());
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.transparent,
                              shadowColor: Colors.transparent,
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
                              foregroundColor: Colors.white,
                            ),
                            label: Text('Continue', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 15)),
                            icon: const Icon(Icons.arrow_forward_rounded, size: 18),
                          ),
                        ),
                      ],
                    ),
                  ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildStepView(BuildContext context, OnboardingState state, int stepVal) {
    final bloc = context.read<OnboardingBloc>();

    switch (stepVal) {
      case 1:
        return Step1WelcomeView(
          onContinue: () => bloc.add(NextStepEvent()),
        );
      case 2:
        return StepStartingPointView(
          selectedChoice: state.draft.startingChoice,
          onChoiceSelected: (choice) => bloc.add(SelectStartingPointEvent(choice)),
          onContinue: () => bloc.add(NextStepEvent()),
        );
      case 3:
        return Step2AccountsView(
          accounts: state.draft.accounts,
          onAccountsUpdated: (accs) => bloc.add(UpdateAccountsEvent(accs)),
          onContinue: () => bloc.add(NextStepEvent()),
        );
      case 4:
        return Step3CreditCardView(
          creditCard: state.draft.creditCard,
          hasCreditCards: state.draft.hasCreditCards,
          onToggleHasCreditCards: (val) => bloc.add(ToggleSectionEvent(sectionKey: 'creditCards', enabled: val)),
          onCreditCardUpdated: (cc) => bloc.add(UpdateCreditCardEvent(cc)),
          onContinue: () => bloc.add(NextStepEvent()),
        );
      case 5:
        return Step4ImportFdView(
          fdLots: state.draft.fdLots,
          onFdLotsUpdated: (fds) => bloc.add(UpdateFdLotsEvent(fds)),
          onContinue: () => bloc.add(NextStepEvent()),
        );
      case 6:
        return Step5ActiveEmisView(
          emis: state.draft.emis,
          draft: state.draft,
          hasEmis: state.draft.hasEmis,
          onToggleHasEmis: (val) => bloc.add(ToggleSectionEvent(sectionKey: 'emis', enabled: val)),
          onEmisUpdated: (emis) => bloc.add(UpdateEmisEvent(emis)),
          onContinue: () => bloc.add(NextStepEvent()),
        );
      case 7:
        return Step6IncomeView(
          incomes: state.draft.incomes,
          draft: state.draft,
          onIncomesUpdated: (incs) => bloc.add(UpdateIncomesEvent(incs)),
          onContinue: () => bloc.add(NextStepEvent()),
        );
      case 8:
        return Step7RecurringExpensesView(
          recurringExpenses: state.draft.recurringExpenses,
          draft: state.draft,
          onObligationsUpdated: (obs) => bloc.add(UpdateObligationsEvent(obs)),
          onContinue: () => bloc.add(NextStepEvent()),
        );
      case 9:
        return Step8InvestmentsView(
          investments: state.draft.investments,
          hasInvestments: state.draft.hasInvestments,
          onToggleHasInvestments: (val) => bloc.add(ToggleSectionEvent(sectionKey: 'investments', enabled: val)),
          onInvestmentsUpdated: (invs) => bloc.add(UpdateInvestmentsEvent(invs)),
          onContinue: () => bloc.add(NextStepEvent()),
        );
      case 14:
        return StepSavingsView(
          savingsEntries: state.draft.savingsEntries,
          fdLots: state.draft.fdLots,
          draft: state.draft,
          hasSavings: state.draft.hasSavings,
          onToggleHasSavings: (val) => bloc.add(ToggleSectionEvent(sectionKey: 'savings', enabled: val)),
          onSavingsUpdated: (savings) => bloc.add(UpdateSavingsEvent(savings)),
          onTargetSavingsChanged: (val) => bloc.add(UpdateSavingsEvent(state.draft.savingsEntries, targetMonthlySavings: val)),
          onContinue: () => bloc.add(NextStepEvent()),
        );
      case 10:
        return Step9GoalsView(
          goals: state.draft.goals,
          hasGoals: state.draft.hasGoals,
          onToggleHasGoals: (val) => bloc.add(ToggleSectionEvent(sectionKey: 'goals', enabled: val)),
          onGoalsUpdated: (goals) => bloc.add(UpdateGoalsEvent(goals)),
          onContinue: () => bloc.add(NextStepEvent()),
        );
      case 11:
        return Step10AiAnalysisView(
          analysis: state.analysis,
          smartBudget: state.smartBudget,
          onCustomBudgetUpdated: (name, amt) => bloc.add(UpdateCustomCategoryBudgetEvent(categoryName: name, amount: amt)),
          onContinue: () => bloc.add(NextStepEvent()),
        );
      case 12:
        return ReviewSummaryView(
          draft: state.draft,
          smartBudget: state.smartBudget,
          onEditStep: (targetStep) {
            final updatedDraft = state.draft.copyWith(currentStep: targetStep);
            bloc.add(LoadOnboardingDraftEvent());
            bloc.add(SelectStartingPointEvent(updatedDraft.startingChoice));
          },
          onContinue: () => bloc.add(NextStepEvent()),
        );
      case 13:
        return FinalCompletionView(
          draft: state.draft,
          analysis: state.analysis,
          isSubmitting: state.status == OnboardingStatus.submitting,
          onLaunch: () => bloc.add(CompleteOnboardingEvent()),
        );
      default:
        return Step1WelcomeView(onContinue: () => bloc.add(NextStepEvent()));
    }
  }
}
