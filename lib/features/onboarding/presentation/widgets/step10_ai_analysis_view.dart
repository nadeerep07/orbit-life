import 'package:flutter/material.dart';
import '../../domain/entities/financial_analysis_result.dart';
import '../../domain/entities/smart_budget_result.dart';

class Step10AiAnalysisView extends StatelessWidget {
  final FinancialAnalysisResult? analysis;
  final SmartBudgetResult? smartBudget;
  final Function(String categoryName, double amount) onCustomBudgetUpdated;
  final VoidCallback onContinue;

  const Step10AiAnalysisView({
    super.key,
    required this.analysis,
    required this.smartBudget,
    required this.onCustomBudgetUpdated,
    required this.onContinue,
  });

  void _showEditBudgetDialog(BuildContext context, SmartCategoryBudget budgetItem) {
    final ctrl = TextEditingController(text: budgetItem.recommendedAmount.toStringAsFixed(0));
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text('Customize ${budgetItem.categoryName} Budget'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              budgetItem.reasonExplanation,
              style: const TextStyle(fontSize: 11, color: Colors.grey),
            ),
            const SizedBox(height: 14),
            TextField(
              controller: ctrl,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: 'Monthly Budget Amount (₹)',
                border: OutlineInputBorder(),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () {
              final val = double.tryParse(ctrl.text.trim()) ?? budgetItem.recommendedAmount;
              onCustomBudgetUpdated(budgetItem.categoryName, val);
              Navigator.pop(ctx);
            },
            child: const Text('Apply'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final health = analysis;
    final budget = smartBudget;

    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: const Color(0xFFF59E0B).withValues(alpha: 0.15),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.auto_awesome_rounded, color: Color(0xFFF59E0B), size: 24),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'AI Financial Analysis & Smart Budget',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: isDark ? Colors.white : const Color(0xFF0F172A),
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Explainable AI insights generated from your financial profile.',
                      style: TextStyle(
                        fontSize: 12,
                        color: isDark ? Colors.white70 : const Color(0xFF64748B),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),

          // Health Score Card
          if (health != null)
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    const Color(0xFF3B82F6).withValues(alpha: 0.15),
                    const Color(0xFF10B981).withValues(alpha: 0.15),
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: const Color(0xFF3B82F6).withValues(alpha: 0.3)),
              ),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('Financial Health Score', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                          const SizedBox(height: 4),
                          Row(
                            children: [
                              Text(
                                '${health.healthScore}',
                                style: const TextStyle(fontSize: 36, fontWeight: FontWeight.w800, color: Color(0xFF3B82F6)),
                              ),
                              const Text(' / 100', style: TextStyle(fontSize: 16, color: Colors.grey)),
                            ],
                          ),
                        ],
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: health.riskLevel == 'Low' ? const Color(0xFF10B981).withValues(alpha: 0.2) : Colors.amber.withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          '${health.riskLevel} Risk Profile',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                            color: health.riskLevel == 'Low' ? const Color(0xFF10B981) : Colors.amber,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const Divider(height: 24),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      _buildMetricStat('Savings Rate', '${health.savingsRate.toStringAsFixed(0)}%'),
                      _buildMetricStat('Debt Ratio', '${health.debtToIncomeRatio.toStringAsFixed(0)}%'),
                      _buildMetricStat('Emergency', '${health.emergencyFundCoverageMonths.toStringAsFixed(1)} mos'),
                      _buildMetricStat('Free Cash', '₹${health.monthlyFreeCash.toStringAsFixed(0)}'),
                    ],
                  ),
                ],
              ),
            ),

          const SizedBox(height: 24),

          // Explainable AI Reasoning Cards
          if (health != null) ...[
            const Text('Why OrbitLife Recommends This:', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
            const SizedBox(height: 10),
            ...health.metricExplanations.entries.map((e) {
              return Container(
                margin: const EdgeInsets.only(bottom: 8),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: isDark ? Colors.white.withValues(alpha: 0.03) : Colors.black.withValues(alpha: 0.02),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: isDark ? Colors.white10 : Colors.black12),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.lightbulb_outline_rounded, color: Color(0xFFF59E0B), size: 18),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(e.key, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
                          const SizedBox(height: 2),
                          Text(e.value, style: const TextStyle(fontSize: 11, color: Colors.grey)),
                        ],
                      ),
                    ),
                  ],
                ),
              );
            }),
          ],

          const SizedBox(height: 24),

          // Recommended Smart Budgets Section
          if (budget != null) ...[
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Smart Recommended Budgets', style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold)),
                Text('${budget.overallConfidence.toStringAsFixed(0)}% Confidence', style: const TextStyle(fontSize: 11, color: Color(0xFF10B981), fontWeight: FontWeight.bold)),
              ],
            ),
            const SizedBox(height: 12),
            ...budget.categoryBudgets.map((cat) {
              return Card(
                margin: const EdgeInsets.only(bottom: 8),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                child: ListTile(
                  title: Text(cat.categoryName, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                  subtitle: Text(cat.reasonExplanation, style: const TextStyle(fontSize: 10, color: Colors.grey)),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text('₹${cat.recommendedAmount.toStringAsFixed(0)}', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Color(0xFF3B82F6))),
                      IconButton(
                        icon: const Icon(Icons.tune_rounded, size: 18),
                        onPressed: () => _showEditBudgetDialog(context, cat),
                      ),
                    ],
                  ),
                ),
              );
            }),
          ],

        ],
      ),
    );
  }

  Widget _buildMetricStat(String label, String value) {
    return Column(
      children: [
        Text(value, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
        const SizedBox(height: 2),
        Text(label, style: const TextStyle(fontSize: 10, color: Colors.grey)),
      ],
    );
  }
}
