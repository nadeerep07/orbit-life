import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:fl_chart/fl_chart.dart';
import '../theme/app_theme.dart';
import '../viewmodels/budget_view_model.dart';
import '../viewmodels/expense_view_model.dart';
import '../viewmodels/month_view_model.dart';
import 'package:intl/intl.dart';
import '../../core/utils/currency_formatter.dart';

class AnalyticsScreen extends StatelessWidget {
  const AnalyticsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final expenseVM = context.watch<ExpenseViewModel>();
    final budgetVM = context.watch<BudgetViewModel>();
    final monthVM = context.watch<MonthViewModel>();
    final now = monthVM.currentMonth;

    final totalBudget = budgetVM.categories.fold(
      0.0,
      (sum, cat) => sum + cat.monthlyBudget,
    );
    final totalSpent = expenseVM.getTotalSpentInMonth(now);

    List<PieChartSectionData> pieSections = [];
    final colors = [
      Theme.of(context).colorScheme.primary,
      Colors.green,
      Theme.of(context).colorScheme.error,
      Colors.orange,
      Colors.purple,
      Colors.teal,
    ];

    for (int i = 0; i < budgetVM.categories.length; i++) {
      final cat = budgetVM.categories[i];
      final spent = expenseVM.getTotalSpentForCategoryInMonth(cat.id, now);
      if (spent > 0) {
        pieSections.add(
          PieChartSectionData(
            color: colors[i % colors.length],
            value: spent,
            title: '${(spent / totalSpent * 100).toStringAsFixed(1)}%',
            radius: 50,
            titleStyle: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
        );
      }
    }

    return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('Analytics'),
            Text(
              DateFormat('MMMM yyyy').format(now),
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.normal,
              ),
            ),
          ],
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            IOSCard(
              child: Column(
                children: [
                  const Text(
                    'Monthly Overview',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 16),
                  if (pieSections.isEmpty)
                    Padding(
                      padding: const EdgeInsets.all(32.0),
                      child: Text(
                        'No expenses recorded this month.',
                        style: TextStyle(
                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                        ),
                      ),
                    )
                  else
                    SizedBox(
                      height: 200,
                      child: PieChart(
                        PieChartData(
                          sectionsSpace: 2,
                          centerSpaceRadius: 40,
                          sections: pieSections,
                        ),
                      ),
                    ),
                  const SizedBox(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      _LegendItem(
                        color: Theme.of(context).colorScheme.primary,
                        label: 'Budget\n$currencySymbol${totalBudget.toStringAsFixed(0)}',
                      ),
                      _LegendItem(
                        color: Theme.of(context).colorScheme.error,
                        label: 'Spent\n$currencySymbol${totalSpent.toStringAsFixed(0)}',
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            IOSCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Category Breakdown',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 16),
                  ...budgetVM.categories.map((cat) {
                    final spent = expenseVM.getTotalSpentForCategoryInMonth(
                      cat.id,
                      now,
                    );
                    if (spent <= 0) return const SizedBox.shrink();
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 8.0),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            cat.name,
                            style: const TextStyle(fontWeight: FontWeight.w500),
                          ),
                          Text(
                            '$currencySymbol${spent.toStringAsFixed(0)}',
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                        ],
                      ),
                    );
                  }),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _LegendItem extends StatelessWidget {
  final Color color;
  final String label;

  const _LegendItem({required this.color, required this.label});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 12,
          height: 12,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 8),
        Text(
          label,
          style: TextStyle(
            fontSize: 13,
            color: Theme.of(context).colorScheme.onSurfaceVariant,
          ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }
}
