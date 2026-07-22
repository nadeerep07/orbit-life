import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../core/utils/currency_formatter.dart';
import '../viewmodels/goals_view_model.dart';
import '../viewmodels/income_view_model.dart';
import '../viewmodels/expense_view_model.dart';
import '../viewmodels/savings_view_model.dart';
import '../viewmodels/accounts_view_model.dart';
import '../../core/services/ai_service.dart';
import 'add_goal_screen.dart';
import '../widgets/custom_snackbar.dart';
import 'package:flutter/services.dart';

class GoalsScreen extends StatefulWidget {
  const GoalsScreen({super.key});

  @override
  State<GoalsScreen> createState() => _GoalsScreenState();
}

class _GoalsScreenState extends State<GoalsScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<GoalsViewModel>().loadGoals();
      context.read<IncomeViewModel>().loadIncomes();
      context.read<ExpenseViewModel>().loadExpenses();
    });
  }

  @override
  Widget build(BuildContext context) {
    final goalVM = context.watch<GoalsViewModel>();
    final theme = Theme.of(context);
    final isDarkMode = theme.brightness == Brightness.dark;

    // Summary numbers
    final totalGoals = goalVM.goals.length;
    final completed = goalVM.goals.where((g) => g.currentSavings >= g.targetAmount).length;

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        title: const Text(
          'Financial Goals',
          style: TextStyle(fontWeight: FontWeight.w900, fontSize: 20),
        ),
        centerTitle: false,
        elevation: 0,
        backgroundColor: Colors.transparent,
        actions: [
          // AI planner button
          Padding(
            padding: const EdgeInsets.only(right: 8),
            child: IconButton(
              onPressed: () => _showAiRecommendations(context),
              tooltip: 'AI Financial Planner',
              icon: Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: theme.colorScheme.primary.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(Icons.auto_awesome_rounded, size: 18, color: theme.colorScheme.primary),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.only(right: 12),
            child: ElevatedButton.icon(
              onPressed: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const AddGoalScreen()),
              ),
              icon: const Icon(Icons.add_rounded, size: 16),
              label: const Text('Add Goal', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
              style: ElevatedButton.styleFrom(
                backgroundColor: theme.colorScheme.primary,
                foregroundColor: Colors.white,
                elevation: 0,
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              ),
            ),
          ),
        ],
      ),
      body: goalVM.isLoading
          ? Center(child: CircularProgressIndicator(color: theme.colorScheme.primary))
          : goalVM.goals.isEmpty
              ? _buildEmptyState(context, isDarkMode)
              : SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // ── Overview Banner ────────────────────────────────────
                      if (totalGoals > 0)
                        Container(
                          padding: const EdgeInsets.all(18),
                          margin: const EdgeInsets.only(bottom: 20),
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: isDarkMode
                                  ? [const Color(0xFF0F172A), const Color(0xFF1E293B)]
                                  : [const Color(0xFFF8FAFC), Colors.white],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ),
                            borderRadius: BorderRadius.circular(24),
                            border: Border.all(
                              color: isDarkMode ? const Color(0xFF334155) : const Color(0xFFE2E8F0),
                            ),
                          ),
                          child: Row(
                            children: [
                              Expanded(
                                child: _OverviewStat(
                                  label: 'TOTAL',
                                  value: '$totalGoals',
                                  unit: 'goals',
                                  color: theme.colorScheme.primary,
                                ),
                              ),
                              Container(width: 1, height: 36, color: isDarkMode ? const Color(0xFF334155) : const Color(0xFFE2E8F0)),
                              Expanded(
                                child: _OverviewStat(
                                  label: 'ACHIEVED',
                                  value: '$completed',
                                  unit: 'goals',
                                  color: const Color(0xFF10B981),
                                ),
                              ),
                              Container(width: 1, height: 36, color: isDarkMode ? const Color(0xFF334155) : const Color(0xFFE2E8F0)),
                              Expanded(
                                child: _OverviewStat(
                                  label: 'IN PROGRESS',
                                  value: '${totalGoals - completed}',
                                  unit: 'goals',
                                  color: const Color(0xFFF59E0B),
                                ),
                              ),
                            ],
                          ),
                        ),

                      // ── Goal Cards ─────────────────────────────────────────
                      ...goalVM.goals.asMap().entries.map((entry) {
                        final index = entry.key;
                        final goal = entry.value;

                        final progress = (goal.currentSavings / goal.targetAmount).clamp(0.0, 1.0);
                        final remaining = goal.targetAmount - goal.currentSavings;
                        final isCompleted = goal.currentSavings >= goal.targetAmount;

                        final goalColors = [
                          theme.colorScheme.primary,
                          const Color(0xFF10B981),
                          const Color(0xFFF59E0B),
                          const Color(0xFF8B5CF6),
                          const Color(0xFFF43F5E),
                          const Color(0xFF06B6D4),
                        ];
                        final goalColor = goalColors[index % goalColors.length];

                        // Time remaining label
                        String? timeLabel;
                        bool isOverdue = false;
                        if (goal.targetDate != null) {
                          final diff = goal.targetDate!.difference(DateTime.now());
                          if (diff.isNegative && !isCompleted) {
                            isOverdue = true;
                            timeLabel = 'Overdue';
                          } else if (diff.inDays <= 30) {
                            timeLabel = '${diff.inDays}d left';
                          } else {
                            final months = (diff.inDays / 30).floor();
                            timeLabel = '${months}mo left';
                          }
                        }

                        return Dismissible(
                          key: Key(goal.id),
                          direction: DismissDirection.endToStart,
                          background: Container(
                            alignment: Alignment.centerRight,
                            padding: const EdgeInsets.only(right: 24),
                            decoration: BoxDecoration(
                              color: const Color(0xFFEF4444),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: const Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(Icons.delete_outline_rounded, color: Colors.white, size: 24),
                                SizedBox(height: 4),
                                Text('Delete', style: TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold)),
                              ],
                            ),
                          ),
                          onDismissed: (_) {
                            goalVM.deleteGoal(goal.id);
                            AppSnackBar.show(context, message: 'Goal "${goal.name}" deleted.', isError: false);
                          },
                          child: Container(
                            margin: const EdgeInsets.only(bottom: 16),
                            padding: const EdgeInsets.all(18),
                            decoration: BoxDecoration(
                              color: isDarkMode ? const Color(0xFF1E293B) : Colors.white,
                              borderRadius: BorderRadius.circular(24),
                              border: Border.all(
                                color: isOverdue
                                    ? const Color(0xFFEF4444).withOpacity(0.4)
                                    : isCompleted
                                        ? const Color(0xFF10B981).withOpacity(0.4)
                                        : isDarkMode ? const Color(0xFF334155) : const Color(0xFFE2E8F0),
                                width: isOverdue || isCompleted ? 1.5 : 1,
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withOpacity(isDarkMode ? 0.15 : 0.03),
                                  blurRadius: 12,
                                  offset: const Offset(0, 4),
                                ),
                              ],
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                // Header row
                                Row(
                                  children: [
                                    // Colored Icon Circle
                                    Container(
                                      padding: const EdgeInsets.all(10),
                                      decoration: BoxDecoration(
                                        color: goalColor.withOpacity(0.12),
                                        shape: BoxShape.circle,
                                      ),
                                      child: Icon(Icons.flag_rounded, color: goalColor, size: 18),
                                    ),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            goal.name,
                                            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                          const SizedBox(height: 2),
                                          Text(
                                            'Target: $currencySymbol${goal.targetAmount.toStringAsFixed(0)}',
                                            style: TextStyle(
                                              fontSize: 11,
                                              color: isDarkMode ? Colors.white54 : Colors.black54,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                    // Time / Status badge
                                    if (isCompleted)
                                      Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                        decoration: BoxDecoration(
                                          color: const Color(0xFF10B981).withOpacity(0.12),
                                          borderRadius: BorderRadius.circular(20),
                                        ),
                                        child: const Text(
                                          '🎉 Done',
                                          style: TextStyle(color: Color(0xFF10B981), fontWeight: FontWeight.bold, fontSize: 11),
                                        ),
                                      )
                                    else if (timeLabel != null)
                                      Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                        decoration: BoxDecoration(
                                          color: isOverdue
                                              ? const Color(0xFFEF4444).withOpacity(0.12)
                                              : const Color(0xFFF59E0B).withOpacity(0.12),
                                          borderRadius: BorderRadius.circular(20),
                                        ),
                                        child: Text(
                                          timeLabel,
                                          style: TextStyle(
                                            color: isOverdue ? const Color(0xFFEF4444) : const Color(0xFFF59E0B),
                                            fontWeight: FontWeight.bold,
                                            fontSize: 11,
                                          ),
                                        ),
                                      ),
                                    const SizedBox(width: 8),
                                    // Edit button
                                    GestureDetector(
                                      onTap: () => Navigator.push(
                                        context,
                                        MaterialPageRoute(builder: (_) => AddGoalScreen(existingGoal: goal)),
                                      ),
                                      child: Container(
                                        padding: const EdgeInsets.all(6),
                                        decoration: BoxDecoration(
                                          color: isDarkMode ? const Color(0xFF334155) : const Color(0xFFF1F5F9),
                                          shape: BoxShape.circle,
                                        ),
                                        child: Icon(Icons.edit_rounded, size: 14, color: isDarkMode ? Colors.white70 : Colors.black54),
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 18),

                                // Progress bar
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text(
                                      '$currencySymbol${goal.currentSavings.toStringAsFixed(0)} saved',
                                      style: TextStyle(
                                        fontSize: 12,
                                        fontWeight: FontWeight.bold,
                                        color: isDarkMode ? Colors.white70 : Colors.black87,
                                      ),
                                    ),
                                    Text(
                                      '${(progress * 100).toStringAsFixed(0)}%',
                                      style: TextStyle(
                                        fontSize: 12,
                                        fontWeight: FontWeight.bold,
                                        color: isCompleted ? const Color(0xFF10B981) : goalColor,
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 8),
                                ClipRRect(
                                  borderRadius: BorderRadius.circular(6),
                                  child: LinearProgressIndicator(
                                    value: progress,
                                    minHeight: 8,
                                    backgroundColor: isDarkMode ? Colors.white10 : Colors.black12,
                                    color: isCompleted ? const Color(0xFF10B981) : goalColor,
                                  ),
                                ),
                                const SizedBox(height: 12),

                                // Remaining + Due Date row
                                Row(
                                  children: [
                                    Expanded(
                                      child: Text(
                                        isCompleted
                                            ? 'Goal fully achieved!'
                                            : 'Remaining: $currencySymbol${remaining.toStringAsFixed(0)}',
                                        style: TextStyle(
                                          fontSize: 11,
                                          fontWeight: FontWeight.w600,
                                          color: isCompleted
                                              ? const Color(0xFF10B981)
                                              : isDarkMode ? Colors.white54 : Colors.black54,
                                        ),
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                    if (goal.targetDate != null)
                                      Text(
                                        'Due ${DateFormat("MMM yyyy").format(goal.targetDate!)}',
                                        style: TextStyle(
                                          fontSize: 10,
                                          color: isDarkMode ? Colors.white38 : Colors.black38,
                                        ),
                                      ),
                                  ],
                                ),
                                if (!isCompleted) ...[
                                  const SizedBox(height: 14),
                                  SizedBox(
                                    width: double.infinity,
                                    child: OutlinedButton.icon(
                                      onPressed: () => _addSavingsSheet(context, goal),
                                      icon: Icon(Icons.add_rounded, size: 16, color: goalColor),
                                      label: Text(
                                        'Add Savings',
                                        style: TextStyle(color: goalColor, fontWeight: FontWeight.bold, fontSize: 13),
                                      ),
                                      style: OutlinedButton.styleFrom(
                                        side: BorderSide(color: goalColor.withOpacity(0.4)),
                                        padding: const EdgeInsets.symmetric(vertical: 12),
                                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                                      ),
                                    ),
                                  ),
                                ],
                              ],
                            ),
                          ),
                        );
                      }),
                    ],
                  ),
                ),
    );
  }

  Widget _buildEmptyState(BuildContext context, bool isDarkMode) {
    final theme = Theme.of(context);
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(28),
              decoration: BoxDecoration(
                color: theme.colorScheme.primary.withOpacity(0.08),
                shape: BoxShape.circle,
              ),
              child: Icon(Icons.flag_rounded, size: 52, color: theme.colorScheme.primary),
            ),
            const SizedBox(height: 24),
            const Text(
              'No Goals Set Yet',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 10),
            Text(
              'Set a financial goal like "Buy iPhone" or "Emergency Fund" to start tracking your progress.',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 13, color: isDarkMode ? Colors.white54 : Colors.black54, height: 1.4),
            ),
            const SizedBox(height: 28),
            ElevatedButton.icon(
              onPressed: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const AddGoalScreen()),
              ),
              icon: const Icon(Icons.add_rounded),
              label: const Text('Create First Goal', style: TextStyle(fontWeight: FontWeight.bold)),
              style: ElevatedButton.styleFrom(
                backgroundColor: theme.colorScheme.primary,
                foregroundColor: Colors.white,
                elevation: 0,
                padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 14),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _addSavingsSheet(BuildContext context, goal) {
    final ctrl = TextEditingController();
    final accountsVM = context.read<AccountsViewModel>();
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    String? selectedAccountId = accountsVM.accounts.isNotEmpty ? accountsVM.accounts.first.id : null;
    final borderColor = isDarkMode ? const Color(0xFF334155) : const Color(0xFFE2E8F0);
    final cardBg = isDarkMode ? const Color(0xFF0F172A) : Colors.white;
    final textPrimary = isDarkMode ? Colors.white : const Color(0xFF0F172A);
    final textSecondary = isDarkMode ? const Color(0xFF94A3B8) : const Color(0xFF64748B);
    final double remainingTarget = (goal.targetAmount - goal.currentSavings).clamp(0.0, double.infinity);

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        final keyboardOffset = MediaQuery.of(ctx).viewInsets.bottom;
        return StatefulBuilder(
          builder: (ctx, setSheetState) => Container(
            padding: EdgeInsets.only(top: 24, left: 20, right: 20, bottom: 24 + keyboardOffset),
            decoration: BoxDecoration(
              color: cardBg,
              borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
              border: Border.all(color: borderColor, width: 1.2),
            ),
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Center(
                    child: Container(
                      width: 48, height: 4,
                      decoration: BoxDecoration(
                        color: isDarkMode ? Colors.white24 : Colors.black12,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                  const SizedBox(height: 18),
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            colors: [Color(0xFF10B981), Color(0xFF059669)],
                          ),
                          borderRadius: BorderRadius.circular(16),
                          boxShadow: [
                            BoxShadow(
                              color: const Color(0xFF10B981).withValues(alpha: 0.3),
                              blurRadius: 8,
                              offset: const Offset(0, 3),
                            ),
                          ],
                        ),
                        child: const Icon(Icons.savings_rounded, color: Colors.white, size: 22),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Deposit to Goal', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: textPrimary)),
                            const SizedBox(height: 2),
                            Text('${goal.name} (Remaining: ${CurrencyFormatter.format(remainingTarget)})', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w500, color: textSecondary)),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),

                  // Quick Shortcut Chips
                  Text(
                    'QUICK DEPOSIT SHORTCUTS',
                    style: TextStyle(fontSize: 10, fontWeight: FontWeight.w800, letterSpacing: 1.0, color: textSecondary),
                  ),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      _buildGoalShortcutChip('+₹500', 500, ctrl, setSheetState, isDarkMode, textPrimary),
                      _buildGoalShortcutChip('+₹1,000', 1000, ctrl, setSheetState, isDarkMode, textPrimary),
                      _buildGoalShortcutChip('+₹5,000', 5000, ctrl, setSheetState, isDarkMode, textPrimary),
                      if (remainingTarget > 0)
                        InkWell(
                          onTap: () {
                            setSheetState(() {
                              ctrl.text = remainingTarget.toStringAsFixed(0);
                            });
                          },
                          borderRadius: BorderRadius.circular(12),
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
                            decoration: BoxDecoration(
                              color: const Color(0xFF10B981).withValues(alpha: 0.15),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: const Color(0xFF10B981), width: 1),
                            ),
                            child: const Text(
                              'Full Target',
                              style: TextStyle(fontSize: 12, fontWeight: FontWeight.w800, color: Color(0xFF10B981)),
                            ),
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 18),

                  // Amount Input Field
                  TextField(
                    controller: ctrl,
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: textPrimary),
                    decoration: InputDecoration(
                      labelText: 'Deposit Amount ($currencySymbol)',
                      prefixText: '$currencySymbol ',
                      prefixStyle: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF10B981)),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(16)),
                    ),
                  ),
                  const SizedBox(height: 20),

                  // Account Selector Label
                  Text(
                    'DEDUCT FROM ACCOUNT',
                    style: TextStyle(fontSize: 10, fontWeight: FontWeight.w800, letterSpacing: 1.0, color: textSecondary),
                  ),
                  const SizedBox(height: 8),

                  // Visual Account Picker Cards
                  if (accountsVM.accounts.isEmpty)
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: const Color(0xFFEF4444).withValues(alpha: 0.08),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Text('No accounts available.', style: TextStyle(color: Color(0xFFEF4444), fontSize: 13)),
                    )
                  else
                    SizedBox(
                      height: 65,
                      child: ListView.builder(
                        scrollDirection: Axis.horizontal,
                        itemCount: accountsVM.accounts.length,
                        itemBuilder: (context, index) {
                          final a = accountsVM.accounts[index];
                          final isSelected = selectedAccountId == a.id;
                          return GestureDetector(
                            onTap: () => setSheetState(() => selectedAccountId = a.id),
                            child: Container(
                              width: 140,
                              margin: const EdgeInsets.only(right: 10),
                              padding: const EdgeInsets.all(10),
                              decoration: BoxDecoration(
                                color: isSelected
                                    ? const Color(0xFF10B981).withValues(alpha: 0.15)
                                    : (isDarkMode ? const Color(0xFF1E293B) : const Color(0xFFF8FAFC)),
                                borderRadius: BorderRadius.circular(14),
                                border: Border.all(
                                  color: isSelected ? const Color(0xFF10B981) : borderColor,
                                  width: isSelected ? 1.8 : 1.0,
                                ),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Row(
                                    children: [
                                      Icon(Icons.account_balance_wallet_rounded, size: 14, color: isSelected ? const Color(0xFF10B981) : textSecondary),
                                      const SizedBox(width: 4),
                                      Expanded(
                                        child: Text(a.name, style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: textPrimary), overflow: TextOverflow.ellipsis),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 2),
                                  Text(CurrencyFormatter.format(a.openingBalance), style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: textSecondary)),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
                    ),

                  const SizedBox(height: 24),

                  Container(
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [Color(0xFF10B981), Color(0xFF059669)],
                      ),
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFF10B981).withValues(alpha: 0.35),
                          blurRadius: 10,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: ElevatedButton.icon(
                      onPressed: () {
                        final val = double.tryParse(ctrl.text);
                        if (val == null || val <= 0) {
                          AppSnackBar.show(ctx, message: 'Enter a valid amount.', isError: true);
                          return;
                        }
                        if (selectedAccountId == null) {
                          AppSnackBar.show(ctx, message: 'Select a source account.', isError: true);
                          return;
                        }
                        final selectedAcc = accountsVM.accounts.firstWhere((a) => a.id == selectedAccountId);
                        if (selectedAcc.openingBalance < val) {
                          AppSnackBar.show(context, message: 'Insufficient balance in selected account.', isError: true);
                          return;
                        }
                        context.read<GoalsViewModel>().addSavingsToGoal(goal.id, val, selectedAccountId!);
                        Navigator.pop(ctx);
                        AppSnackBar.show(context, message: '$currencySymbol${val.toStringAsFixed(0)} added to "${goal.name}"!', isError: false);
                      },
                      icon: const Icon(Icons.check_circle_rounded, color: Colors.white, size: 18),
                      label: const Text('Confirm Deposit', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 15, color: Colors.white)),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.transparent,
                        shadowColor: Colors.transparent,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildGoalShortcutChip(
    String label,
    double increment,
    TextEditingController ctrl,
    StateSetter setSheetState,
    bool isDarkMode,
    Color textPrimary,
  ) {
    return InkWell(
      onTap: () {
        final current = double.tryParse(ctrl.text) ?? 0.0;
        setSheetState(() {
          ctrl.text = (current + increment).toStringAsFixed(0);
        });
      },
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
        decoration: BoxDecoration(
          color: isDarkMode ? const Color(0xFF1E293B) : const Color(0xFFF1F5F9),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: isDarkMode ? const Color(0xFF334155) : const Color(0xFFE2E8F0)),
        ),
        child: Text(label, style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: textPrimary)),
      ),
    );
  }

  void _showAiRecommendations(BuildContext context) async {
    final goalVM = context.read<GoalsViewModel>();

    if (goalVM.goals.isEmpty) {
      AppSnackBar.show(context, message: 'Please add at least one goal to get AI advice.', isError: true);
      return;
    }

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) {
        final isDarkMode = Theme.of(context).brightness == Brightness.dark;
        return AlertDialog(
          backgroundColor: isDarkMode ? const Color(0xFF1E293B) : Colors.white,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
          content: Row(
            children: [
              CircularProgressIndicator(color: Theme.of(context).colorScheme.primary),
              const SizedBox(width: 16),
              const Text('Generating AI Plan...', style: TextStyle(fontWeight: FontWeight.w600)),
            ],
          ),
        );
      },
    );

    final aiService = AIService();
    final incomeVM = context.read<IncomeViewModel>();
    final expenseVM = context.read<ExpenseViewModel>();
    final savingsVM = context.read<SavingsViewModel>();

    final totalIncome = incomeVM.totalIncomeAllTime;
    final totalExpenses = expenseVM.expenses.fold<double>(0.0, (sum, item) => sum + item.amount);
    final totalSavings = savingsVM.savings?.currentBalance ?? 0.0;

    final goalsData = goalVM.goals.map((g) {
      int? monthsRemaining;
      if (g.targetDate != null) {
        final diff = g.targetDate!.difference(DateTime.now());
        final m = (diff.inDays / 30).ceil();
        if (m > 0) monthsRemaining = m;
      }
      return {
        'name': g.name,
        'targetAmount': g.targetAmount,
        'currentSavings': g.currentSavings,
        'monthsRemaining': monthsRemaining,
      };
    }).toList();

    final navigator = Navigator.of(context);

    final recs = await aiService.getGoalRecommendations(
      totalIncome: totalIncome > 0 ? totalIncome : 0,
      totalExpenses: totalExpenses,
      currentSavings: totalSavings,
      financialGoals: goalsData,
    );

    if (!mounted) return;
    navigator.pop();

    if (context.mounted) {
      _showRecommendationSheet(context, recs);
    }
  }

  void _showRecommendationSheet(BuildContext context, String recs) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => Container(
        padding: const EdgeInsets.fromLTRB(20, 24, 20, 32),
        height: MediaQuery.of(context).size.height * 0.7,
        decoration: BoxDecoration(
          color: isDarkMode ? const Color(0xFF0F172A) : Colors.white,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
          border: Border.all(
            color: isDarkMode ? const Color(0xFF334155) : const Color(0xFFE2E8F0),
            width: 1.2,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 48, height: 4,
                decoration: BoxDecoration(
                  color: isDarkMode ? Colors.white24 : Colors.black12,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 20),
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.primary.withOpacity(0.1),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(Icons.auto_awesome_rounded, color: Theme.of(context).colorScheme.primary, size: 18),
                ),
                const SizedBox(width: 12),
                const Expanded(
                  child: Text('AI Smart Plan', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900)),
                ),
                IconButton(
                  icon: const Icon(Icons.copy_rounded, size: 18),
                  tooltip: 'Copy Advice',
                  onPressed: () {
                    Clipboard.setData(ClipboardData(text: recs));
                    AppSnackBar.show(context, message: 'Advice copied to clipboard', isError: false);
                  },
                ),
              ],
            ),
            Divider(height: 28, color: isDarkMode ? const Color(0xFF334155) : const Color(0xFFE2E8F0)),
            Expanded(
              child: SingleChildScrollView(
                child: Text(recs, style: const TextStyle(fontSize: 14, height: 1.7, letterSpacing: 0.2)),
              ),
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () => Navigator.pop(context),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Theme.of(context).colorScheme.primary,
                  foregroundColor: Colors.white,
                  elevation: 0,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                ),
                child: const Text('Got it', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _OverviewStat extends StatelessWidget {
  final String label;
  final String value;
  final String unit;
  final Color color;

  const _OverviewStat({required this.label, required this.value, required this.unit, required this.color});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(label, style: TextStyle(fontSize: 8, fontWeight: FontWeight.bold, color: color, letterSpacing: 0.5)),
        const SizedBox(height: 4),
        Text(value, style: TextStyle(fontSize: 22, fontWeight: FontWeight.w900, color: color)),
        Text(unit, style: TextStyle(fontSize: 10, color: color.withOpacity(0.7))),
      ],
    );
  }
}
