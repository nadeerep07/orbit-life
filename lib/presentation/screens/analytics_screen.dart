import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';
import '../viewmodels/budget_view_model.dart';
import '../viewmodels/expense_view_model.dart';
import '../viewmodels/month_view_model.dart';
import '../../core/utils/currency_formatter.dart';
import '../../domain/entities/category_entity.dart';
import '../viewmodels/settings_view_model.dart';

class AnalyticsScreen extends StatelessWidget {
  const AnalyticsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDarkMode = theme.brightness == Brightness.dark;
    
    final expenseVM = context.watch<ExpenseViewModel>();
    final budgetVM = context.watch<BudgetViewModel>();
    final monthVM = context.watch<MonthViewModel>();
    final settingsVM = context.watch<SettingsViewModel>();
    final now = monthVM.currentMonth;
    final settings = settingsVM.settings;

    final totalBudget = settings.monthlyBudgetLimit;
    final totalSpent = expenseVM.getTotalSpentInMonth(now);

    final cardBgColor = isDarkMode ? const Color(0xFF1E293B) : Colors.white;
    final borderColor = isDarkMode ? const Color(0xFF334155) : const Color(0xFFE2E8F0);
    final textMutedColor = isDarkMode ? Colors.white54 : Colors.black54;

    // Rich modern palette for category chart sections
    final categoryColors = [
      theme.colorScheme.primary,
      const Color(0xFF10B981), // Emerald Green
      const Color(0xFFF43F5E), // Rose Red
      const Color(0xFFF59E0B), // Amber Yellow
      const Color(0xFF8B5CF6), // Violet Purple
      const Color(0xFF06B6D4), // Cyan Blue
      const Color(0xFFEC4899), // Pink
      const Color(0xFF3B82F6), // Blue
    ];

    List<PieChartSectionData> pieSections = [];
    final List<Map<String, dynamic>> categorySpentList = [];

    for (int i = 0; i < budgetVM.categories.length; i++) {
      final cat = budgetVM.categories[i];
      final spent = expenseVM.getTotalSpentForCategoryInMonth(cat.id, now);
      if (spent > 0) {
        final color = categoryColors[i % categoryColors.length];
        pieSections.add(
          PieChartSectionData(
            color: color,
            value: spent,
            title: '', // Keep clean, title will be in legend/list
            radius: 18,
            showTitle: false,
          ),
        );
        categorySpentList.add({
          'category': cat,
          'spent': spent,
          'color': color,
          'percentage': totalSpent > 0 ? (spent / totalSpent * 100) : 0.0,
        });
      }
    }

    // Sort categories from highest spent to lowest
    categorySpentList.sort((a, b) => (b['spent'] as double).compareTo(a['spent'] as double));

    final budgetProgress = totalBudget > 0 ? (totalSpent / totalBudget) : 0.0;
    final budgetPercentString = (budgetProgress * 100).toStringAsFixed(0);

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'Analytics',
              style: TextStyle(fontWeight: FontWeight.w900, fontSize: 20),
            ),
            Text(
              DateFormat('MMMM yyyy').format(now),
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w500,
                color: theme.colorScheme.primary,
              ),
            ),
          ],
        ),
        centerTitle: false,
        elevation: 0,
        backgroundColor: Colors.transparent,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // ── Double Header Summary Cards ─────────────────────────────────
            Row(
              children: [
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: isDarkMode 
                            ? [const Color(0xFF0F172A), const Color(0xFF1E293B)]
                            : [const Color(0xFFF8FAFC), Colors.white],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: borderColor),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(Icons.account_balance_wallet_rounded, 
                              color: theme.colorScheme.primary, size: 16),
                            const SizedBox(width: 8),
                            Text(
                              'TOTAL BUDGET',
                              style: TextStyle(fontSize: 9, fontWeight: FontWeight.bold, color: textMutedColor, letterSpacing: 0.5),
                            ),
                          ],
                        ),
                        const SizedBox(height: 10),
                        Text(
                          '$currencySymbol${totalBudget.toStringAsFixed(0)}',
                          style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w900),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: isDarkMode
                            ? [const Color(0xFF1E1E2C), const Color(0xFF2D1E2F)]
                            : [const Color(0xFFFFF1F2), Colors.white],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: isDarkMode 
                            ? const Color(0xFFE11D48).withOpacity(0.3) 
                            : const Color(0xFFFECDD3),
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            const Icon(Icons.shopping_bag_rounded, 
                              color: Color(0xFFE11D48), size: 16),
                            const SizedBox(width: 8),
                            Text(
                              'TOTAL SPENT',
                              style: TextStyle(fontSize: 9, fontWeight: FontWeight.bold, color: textMutedColor, letterSpacing: 0.5),
                            ),
                          ],
                        ),
                        const SizedBox(height: 10),
                        Text(
                          '$currencySymbol${totalSpent.toStringAsFixed(0)}',
                          style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w900),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // ── Budget Used Linear Progress Card ──────────────────────────────
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: cardBgColor,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: borderColor),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Budget Spent Utilization',
                        style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: budgetProgress > 1.0 
                              ? const Color(0xFFF87171).withOpacity(0.15)
                              : theme.colorScheme.primary.withOpacity(0.12),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          '$budgetPercentString%',
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                            color: budgetProgress > 1.0 ? const Color(0xFFEF4444) : theme.colorScheme.primary,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(6),
                    child: LinearProgressIndicator(
                      value: budgetProgress.clamp(0.0, 1.0),
                      minHeight: 8,
                      backgroundColor: isDarkMode ? Colors.white10 : Colors.black12,
                      color: budgetProgress > 1.0 
                          ? const Color(0xFFEF4444) 
                          : theme.colorScheme.primary,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // ── Interactive Doughnut Chart Overview ──────────────────────────
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: cardBgColor,
                borderRadius: BorderRadius.circular(24),
                border: Border.all(color: borderColor),
              ),
              child: Column(
                children: [
                  const Align(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      'Monthly Breakdown Share',
                      style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
                    ),
                  ),
                  const SizedBox(height: 24),
                  if (pieSections.isEmpty)
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 40.0),
                      child: Column(
                        children: [
                          Icon(Icons.auto_graph_rounded, color: textMutedColor, size: 48),
                          const SizedBox(height: 16),
                          Text(
                            'No expenses logged this month.',
                            style: TextStyle(color: textMutedColor, fontSize: 13),
                          ),
                        ],
                      ),
                    )
                  else ...[
                    SizedBox(
                      height: 200,
                      child: Stack(
                        alignment: Alignment.center,
                        children: [
                          PieChart(
                            PieChartData(
                              sectionsSpace: 3,
                              centerSpaceRadius: 65,
                              sections: pieSections,
                            ),
                          ),
                          Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                'TOTAL SPENT',
                                style: TextStyle(
                                  fontSize: 9, 
                                  fontWeight: FontWeight.bold, 
                                  color: textMutedColor, 
                                  letterSpacing: 0.5
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                '$currencySymbol${totalSpent.toStringAsFixed(0)}',
                                style: const TextStyle(
                                  fontSize: 24, 
                                  fontWeight: FontWeight.w900
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 20),
                    // Wrapping Category Tag List
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      alignment: WrapAlignment.center,
                      children: categorySpentList.map((item) {
                        final cat = item['category'] as CategoryEntity;
                        final color = item['color'] as Color;
                        final percent = item['percentage'] as double;
                        return Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                          decoration: BoxDecoration(
                            color: color.withOpacity(0.08),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: color.withOpacity(0.2), width: 1),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Container(
                                width: 8,
                                height: 8,
                                decoration: BoxDecoration(color: color, shape: BoxShape.circle),
                              ),
                              const SizedBox(width: 6),
                              Text(
                                '${cat.name} (${percent.toStringAsFixed(0)}%)',
                                style: TextStyle(
                                  fontSize: 10, 
                                  fontWeight: FontWeight.w600,
                                  color: isDarkMode ? Colors.white : Colors.black87
                                ),
                              ),
                            ],
                          ),
                        );
                      }).toList(),
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(height: 16),

            // ── Interactive List of Category Progress Breakdowns ────────────
            if (categorySpentList.isNotEmpty) ...[
              const Padding(
                padding: EdgeInsets.only(left: 4, bottom: 12),
                child: Text(
                  'Category Breakdown details',
                  style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
                ),
              ),
              ...categorySpentList.map((item) {
                final cat = item['category'] as CategoryEntity;
                final spent = item['spent'] as double;
                final color = item['color'] as Color;
                final percent = item['percentage'] as double;

                final categoryLimit = settings.categoryBudgets[cat.id] ?? cat.monthlyBudget;
                final catProgress = categoryLimit > 0 ? (spent / categoryLimit) : 0.0;
                final isOverBudget = spent > categoryLimit && categoryLimit > 0;

                return Container(
                  margin: const EdgeInsets.only(bottom: 12),
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: cardBgColor,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: borderColor),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Row(
                            children: [
                              Container(
                                width: 10,
                                height: 10,
                                decoration: BoxDecoration(color: color, shape: BoxShape.circle),
                              ),
                              const SizedBox(width: 8),
                              Text(
                                cat.name,
                                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                              ),
                              const SizedBox(width: 6),
                              Text(
                                '${percent.toStringAsFixed(0)}% of total',
                                style: TextStyle(color: textMutedColor, fontSize: 10),
                              ),
                            ],
                          ),
                          Text(
                            '$currencySymbol${spent.toStringAsFixed(0)}',
                            style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 13),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(4),
                        child: LinearProgressIndicator(
                          value: catProgress.clamp(0.0, 1.0),
                          minHeight: 5,
                          backgroundColor: isDarkMode ? Colors.white10 : Colors.black12,
                          color: isOverBudget ? const Color(0xFFEF4444) : color,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            categoryLimit > 0 
                                ? 'Limit: $currencySymbol${categoryLimit.toStringAsFixed(0)}' 
                                : 'No Limit set',
                            style: TextStyle(color: textMutedColor, fontSize: 10),
                          ),
                          if (categoryLimit > 0)
                            Text(
                              isOverBudget 
                                  ? 'Exceeded by $currencySymbol${(spent - categoryLimit).toStringAsFixed(0)}' 
                                  : '${(catProgress * 100).toStringAsFixed(0)}% used',
                              style: TextStyle(
                                color: isOverBudget ? const Color(0xFFEF4444) : textMutedColor, 
                                fontSize: 10,
                                fontWeight: isOverBudget ? FontWeight.bold : FontWeight.normal
                              ),
                            ),
                        ],
                      ),
                    ],
                  ),
                );
              }),
            ],
          ],
        ),
      ),
    );
  }
}
