import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../theme/app_theme.dart';
import '../viewmodels/goals_view_model.dart';
import '../viewmodels/income_view_model.dart';
import '../viewmodels/expense_view_model.dart';
import '../viewmodels/savings_view_model.dart';
import '../../core/services/ai_service.dart';
import 'add_goal_screen.dart';

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

    return Scaffold(
      appBar: AppBar(
        title: const Text("Financial Goals"),
        actions: [
          IconButton(
            icon: const Icon(Icons.auto_awesome),
            tooltip: "AI Financial Planner",
            onPressed: () => _showAiRecommendations(context),
          ),
        ],
      ),

      body: goalVM.isLoading
          ? const Center(child: CircularProgressIndicator())
          : goalVM.goals.isEmpty
          ? _buildEmptyState(context)
          : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: goalVM.goals.length,
              itemBuilder: (context, index) {
                final goal = goalVM.goals[index];

                final progress = (goal.currentSavings / goal.targetAmount)
                    .clamp(0.0, 1.0);

                final remaining = goal.targetAmount - goal.currentSavings;

                return Dismissible(
                  key: Key(goal.id),

                  direction: DismissDirection.endToStart,

                  background: Container(
                    alignment: Alignment.centerRight,
                    padding: const EdgeInsets.only(right: 20),
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.error,
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: const Icon(Icons.delete, color: Colors.white),
                  ),

                  onDismissed: (_) {
                    goalVM.deleteGoal(goal.id);
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text("Goal deleted")),
                    );
                  },

                  child: Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: IOSCard(
                      padding: const EdgeInsets.all(16),

                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,

                        children: [
                          /// Title
                          Row(
                            children: [
                              Expanded(
                                child: Text(
                                  goal.name,
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 18,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),

                              IconButton(
                                icon: const Icon(Icons.edit, size: 20),
                                onPressed: () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (_) =>
                                          AddGoalScreen(existingGoal: goal),
                                    ),
                                  );
                                },
                              ),
                            ],
                          ),

                          const SizedBox(height: 8),

                          /// Target
                          Text(
                            "Target: ₹${goal.targetAmount.toStringAsFixed(0)}",
                            style: TextStyle(
                              color: Theme.of(
                                context,
                              ).colorScheme.onSurfaceVariant,
                            ),
                          ),

                          const SizedBox(height: 16),

                          /// Saved + percentage
                          Row(
                            children: [
                              Expanded(
                                child: Text(
                                  "Saved: ₹${goal.currentSavings.toStringAsFixed(0)}",
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),

                              Text(
                                "${(progress * 100).toStringAsFixed(1)}%",
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: Theme.of(context).colorScheme.primary,
                                ),
                              ),
                            ],
                          ),

                          const SizedBox(height: 8),

                          /// Progress bar
                          LinearProgressIndicator(
                            value: progress,
                            minHeight: 8,
                            borderRadius: BorderRadius.circular(4),
                            backgroundColor: Theme.of(
                              context,
                            ).colorScheme.surfaceContainerHighest,
                          ),

                          const SizedBox(height: 16),

                          /// Remaining + date
                          Row(
                            children: [
                              Expanded(
                                child: Text(
                                  remaining > 0
                                      ? "Remaining: ₹${remaining.toStringAsFixed(0)}"
                                      : "Goal Achieved 🎉",
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    color: remaining > 0 ? null : Colors.green,
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),

                              if (goal.targetDate != null)
                                Text(
                                  "Due: ${DateFormat("MMM yyyy").format(goal.targetDate!)}",
                                  style: TextStyle(
                                    color: Theme.of(
                                      context,
                                    ).colorScheme.onSurfaceVariant,
                                    fontSize: 12,
                                  ),
                                ),
                            ],
                          ),

                          const Divider(height: 24),

                          /// Add savings button
                          SizedBox(
                            width: double.infinity,
                            child: OutlinedButton.icon(
                              icon: const Icon(Icons.add),
                              label: const Text("Add Savings"),
                              onPressed: () => _addSavingsDialog(context, goal),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),

      floatingActionButton: FloatingActionButton(
        child: const Icon(Icons.add),

        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const AddGoalScreen()),
          );
        },
      ),
    );
  }

  /// Empty state

  Widget _buildEmptyState(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,

        children: [
          Icon(
            Icons.flag_outlined,
            size: 80,
            color: Theme.of(
              context,
            ).colorScheme.onSurfaceVariant.withOpacity(.5),
          ),

          const SizedBox(height: 16),

          Text(
            "No Active Goals",
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
          ),

          const SizedBox(height: 8),

          Text(
            "Create a goal like 'Buy iPhone' to start tracking.",
            style: TextStyle(
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }

  /// Add savings dialog

  void _addSavingsDialog(BuildContext context, goal) {
    final ctrl = TextEditingController();

    showDialog(
      context: context,

      builder: (ctx) => AlertDialog(
        title: Text("Add Savings to ${goal.name}"),

        content: TextField(
          controller: ctrl,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          decoration: const InputDecoration(labelText: "Amount (₹)"),
        ),

        actions: [
          TextButton(
            child: const Text("Cancel"),
            onPressed: () => Navigator.pop(ctx),
          ),

          ElevatedButton(
            child: const Text("Add"),

            onPressed: () {
              final val = double.tryParse(ctrl.text);

              if (val != null && val > 0) {
                context.read<GoalsViewModel>().addSavingsToGoal(goal.id, val);

                Navigator.pop(ctx);
              }
            },
          ),
        ],
      ),
    );
  }

  /// AI planner

  void _showAiRecommendations(BuildContext context) async {
    final goalVM = context.read<GoalsViewModel>();

    if (goalVM.goals.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text("Please add at least one goal to get AI advice."),
          backgroundColor: Theme.of(context).colorScheme.error,
        ),
      );
      return;
    }

    final aiService = AIService();
    final incomeVM = context.read<IncomeViewModel>();
    final expenseVM = context.read<ExpenseViewModel>();
    final savingsVM = context.read<SavingsViewModel>();

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => const AlertDialog(
        content: Row(
          children: [
            CircularProgressIndicator(),
            SizedBox(width: 16),
            Text("Generating AI Plan..."),
          ],
        ),
      ),
    );

    final totalIncome = incomeVM.totalIncomeAllTime;
    final totalExpenses = expenseVM.expenses.fold<double>(
      0.0,
      (sum, item) => sum + item.amount,
    );
    final totalSavings = savingsVM.savings?.currentBalance ?? 0.0;

    final goalsData = goalVM.goals.map((g) {
      int? monthsRemaining;
      if (g.targetDate != null) {
        final now = DateTime.now();
        final diff = g.targetDate!.difference(now);
        final m = (diff.inDays / 30).ceil();
        if (m > 0) monthsRemaining = m;
      }

      return {
        "name": g.name,
        "targetAmount": g.targetAmount,
        "currentSavings": g.currentSavings,
        "monthsRemaining": monthsRemaining,
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
    navigator.pop(); // Dismiss loading dialog

    if (context.mounted) {
      _showRecommendationBottomSheet(context, recs);
    }
  }

  void _showRecommendationBottomSheet(BuildContext context, String recs) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (_) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
        height: MediaQuery.of(context).size.height * .65,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.auto_awesome,
                  color: Theme.of(context).colorScheme.primary,
                ),
                const SizedBox(width: 12),
                const Expanded(
                  child: Text(
                    "AI Smart Plan",
                    style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.copy),
                  tooltip: "Copy Advice",
                  onPressed: () {
                    Clipboard.setData(ClipboardData(text: recs));
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text("Advice copied to clipboard"),
                      ),
                    );
                  },
                ),
              ],
            ),
            const Divider(height: 32),
            Expanded(
              child: SingleChildScrollView(
                child: Text(
                  recs,
                  style: const TextStyle(
                    fontSize: 16,
                    height: 1.6,
                    letterSpacing: 0.3,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                onPressed: () => Navigator.pop(context),
                child: const Text(
                  "Got it",
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
