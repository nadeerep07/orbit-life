import 'package:flutter/material.dart';
import '../../domain/entities/onboarding_draft.dart';
import '../../domain/entities/smart_budget_result.dart';

class ReviewSummaryView extends StatelessWidget {
  final OnboardingDraft draft;
  final SmartBudgetResult? smartBudget;
  final Function(int stepIndex) onEditStep;
  final VoidCallback onContinue;

  const ReviewSummaryView({
    super.key,
    required this.draft,
    required this.smartBudget,
    required this.onEditStep,
    required this.onContinue,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Banner Badge
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  const Color(0xFF3B82F6).withValues(alpha: 0.15),
                  const Color(0xFF10B981).withValues(alpha: 0.15),
                ],
              ),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: const Color(0xFF3B82F6).withValues(alpha: 0.3)),
            ),
            child: const Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.fact_check_rounded, size: 16, color: Color(0xFF3B82F6)),
                SizedBox(width: 8),
                Text(
                  'FINAL AUDIT & PREVIEW',
                  style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Color(0xFF3B82F6), letterSpacing: 0.5),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          Text(
            'Review Your Financial Profile',
            style: TextStyle(
              fontSize: 26,
              fontWeight: FontWeight.bold,
              color: isDark ? Colors.white : const Color(0xFF0F172A),
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'Review your configured financial snapshot before committing to OrbitLife.',
            style: TextStyle(
              fontSize: 13,
              color: isDark ? Colors.white70 : const Color(0xFF64748B),
            ),
          ),
          const SizedBox(height: 24),

          _buildSectionCard(
            context,
            icon: Icons.tune_rounded,
            color: const Color(0xFF3B82F6),
            title: 'Starting Point Mode',
            content: draft.startingChoice == 'fresh' ? 'Start Fresh (Zero setup)' : 'Existing Financial Life (Full setup)',
            stepIndex: 2,
          ),
          _buildSectionCard(
            context,
            icon: Icons.account_balance_rounded,
            color: const Color(0xFF10B981),
            title: 'Accounts (${draft.accounts.length})',
            content: draft.accounts.isEmpty ? 'No accounts added' : draft.accounts.map((a) => '• ${a.name}: ₹${a.currentBalance.toStringAsFixed(0)} (${a.accountType})').join('\n'),
            stepIndex: 3,
          ),
          if (draft.hasCreditCards)
            _buildSectionCard(
              context,
              icon: Icons.credit_card_rounded,
              color: const Color(0xFF6366F1),
              title: 'Secured Credit Card',
              content: draft.creditCard != null ? '• ${draft.creditCard!.name}\n  Limit: ₹${draft.creditCard!.creditLimit.toStringAsFixed(0)} | Used: ₹${draft.creditCard!.usedCredit.toStringAsFixed(0)}' : 'None',
              stepIndex: 4,
            ),
          if (draft.hasCreditCards && draft.fdLots.isNotEmpty)
            _buildSectionCard(
              context,
              icon: Icons.savings_rounded,
              color: Colors.amber,
              title: 'Historical FD Lots (${draft.fdLots.length})',
              content: draft.fdLots.map((f) => '• ₹${f.principal.toStringAsFixed(0)} @ ${f.interestRate}% [Preserved Limit]').join('\n'),
              stepIndex: 5,
            ),
          if (draft.hasEmis)
            _buildSectionCard(
              context,
              icon: Icons.receipt_long_rounded,
              color: const Color(0xFFEC4899),
              title: 'Active EMIs & Loans (${draft.emis.length})',
              content: draft.emis.isEmpty ? 'No EMIs added' : draft.emis.map((e) => '• ${e.title}: ₹${e.monthlyAmount.toStringAsFixed(0)}/mo (${e.remainingMonths} mos remaining)').join('\n'),
              stepIndex: 6,
            ),
          _buildSectionCard(
            context,
            icon: Icons.south_west_rounded,
            color: const Color(0xFF10B981),
            title: 'Monthly Income (${draft.incomes.length})',
            content: draft.incomes.isEmpty ? 'No income sources added' : draft.incomes.map((i) => '• ${i.sourceName}: ₹${i.amount.toStringAsFixed(0)} (${i.frequency})').join('\n'),
            stepIndex: 7,
          ),
          _buildSectionCard(
            context,
            icon: Icons.north_east_rounded,
            color: Colors.redAccent,
            title: 'Recurring Expenses (${draft.recurringExpenses.length})',
            content: draft.recurringExpenses.isEmpty ? 'No fixed obligations added' : draft.recurringExpenses.map((o) => '• ${o.name}: ₹${o.amount.toStringAsFixed(0)}/mo').join('\n'),
            stepIndex: 8,
          ),
          if (draft.hasInvestments)
            _buildSectionCard(
              context,
              icon: Icons.show_chart_rounded,
              color: const Color(0xFF8B5CF6),
              title: 'Investments (${draft.investments.length})',
              content: draft.investments.isEmpty ? 'No investments added' : draft.investments.map((inv) => '• ${inv.title}: ₹${inv.amount.toStringAsFixed(0)} (${inv.type})').join('\n'),
              stepIndex: 9,
            ),
          if (draft.hasSavings)
            _buildSectionCard(
              context,
              icon: Icons.savings_rounded,
              color: const Color(0xFF10B981),
              title: 'Savings Storage Vehicles (${draft.savingsEntries.length})',
              content: draft.savingsEntries.isEmpty ? 'No savings vehicles added' : draft.savingsEntries.map((s) => '• ${s.title}: ₹${s.amount.toStringAsFixed(0)} (${s.storageType})').join('\n'),
              stepIndex: 14,
            ),
          if (draft.hasGoals)
            _buildSectionCard(
              context,
              icon: Icons.flag_rounded,
              color: const Color(0xFF14B8A6),
              title: 'Financial Goals (${draft.goals.length})',
              content: draft.goals.isEmpty ? 'No goals added' : draft.goals.map((g) => '• ${g.title}: Target ₹${g.targetAmount.toStringAsFixed(0)}').join('\n'),
              stepIndex: 10,
            ),
          if (smartBudget != null)
            _buildSectionCard(
              context,
              icon: Icons.auto_awesome_rounded,
              color: const Color(0xFFF59E0B),
              title: 'Smart Category Budgets',
              content: smartBudget!.categoryBudgets.map((b) => '• ${b.categoryName}: ₹${b.recommendedAmount.toStringAsFixed(0)}/mo').join('\n'),
              stepIndex: 11,
            ),

        ],
      ),
    );
  }

  Widget _buildSectionCard(
    BuildContext context, {
    required IconData icon,
    required Color color,
    required String title,
    required String content,
    required int stepIndex,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? Colors.white.withValues(alpha: 0.03) : Colors.black.withValues(alpha: 0.02),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: isDark ? Colors.white.withValues(alpha: 0.08) : Colors.black.withValues(alpha: 0.08),
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.15),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: color, size: 20),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: isDark ? Colors.white : const Color(0xFF0F172A),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  content,
                  style: TextStyle(
                    fontSize: 12,
                    color: isDark ? Colors.white70 : const Color(0xFF475569),
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            icon: const Icon(Icons.edit_outlined, size: 18, color: Color(0xFF3B82F6)),
            onPressed: () => onEditStep(stepIndex),
          ),
        ],
      ),
    );
  }
}
