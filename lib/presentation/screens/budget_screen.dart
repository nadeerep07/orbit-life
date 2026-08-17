import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../theme/app_theme.dart';
import '../viewmodels/budget_view_model.dart';
import '../viewmodels/expense_view_model.dart';
import '../viewmodels/month_view_model.dart';
import '../viewmodels/settings_view_model.dart';
import 'package:intl/intl.dart';
import '../../core/utils/currency_formatter.dart';
import '../../core/utils/responsive.dart';
import '../widgets/custom_snackbar.dart';
import '../widgets/modern_budget_target_dialog.dart';

class BudgetScreen extends StatelessWidget {
  const BudgetScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final budgetVM = context.watch<BudgetViewModel>();
    final expenseVM = context.watch<ExpenseViewModel>();
    final monthVM = context.watch<MonthViewModel>();
    final settingsVM = context.watch<SettingsViewModel>();
    
    final now = monthVM.currentMonth;
    final settings = settingsVM.settings;
    final r = Responsive(context);
    final theme = Theme.of(context);
    final isDarkMode = theme.brightness == Brightness.dark;

    final cardBgColor = isDarkMode ? const Color(0xFF1E293B) : Colors.white;
    final borderColor = isDarkMode ? const Color(0xFF334155) : const Color(0xFFE2E8F0);
    final textMutedColor = isDarkMode ? Colors.white54 : Colors.black54;

    // Calculate total allocated budget
    final totalAllocated = budgetVM.categories.fold(
      0.0,
      (sum, cat) => sum + (settings.categoryBudgets[cat.id] ?? cat.monthlyBudget),
    );
    final globalLimit = settings.monthlyBudgetLimit;

    // Modern color array for circular indicators
    final colors = [
      theme.colorScheme.primary,
      const Color(0xFF10B981), // Emerald
      const Color(0xFFF43F5E), // Rose
      const Color(0xFFF59E0B), // Amber
      const Color(0xFF8B5CF6), // Violet
      const Color(0xFF06B6D4), // Cyan
    ];

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'Budgets & Categories',
              style: TextStyle(fontWeight: FontWeight.w900, fontSize: 18),
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
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 12),
            child: Center(
              child: ElevatedButton.icon(
                onPressed: () => _showAddCategorySheet(context, now, settingsVM),
                icon: const Icon(Icons.add_rounded, size: 16),
                label: const Text('Add', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
                style: ElevatedButton.styleFrom(
                  backgroundColor: theme.colorScheme.primary,
                  foregroundColor: Colors.white,
                  elevation: 0,
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                ),
              ),
            ),
          ),
        ],
      ),
      body: Align(
        alignment: Alignment.topCenter,
        child: ConstrainedBox(
          constraints: BoxConstraints(maxWidth: r.contentMaxWidth),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // ── Header Allocation Statistics Banner ───────────────────────
              Padding(
                padding: EdgeInsets.symmetric(horizontal: r.horizontalPadding, vertical: 12),
                child: Container(
                  padding: const EdgeInsets.all(18),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: isDarkMode 
                          ? [const Color(0xFF0F172A), const Color(0xFF1E293B)]
                          : [const Color(0xFFF8FAFC), Colors.white],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(24),
                    border: Border.all(color: borderColor),
                  ),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: theme.colorScheme.primary.withOpacity(0.12),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(Icons.pie_chart_rounded, color: theme.colorScheme.primary, size: 24),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'ALLOCATED BUDGET',
                              style: TextStyle(
                                fontSize: 9,
                                fontWeight: FontWeight.bold,
                                color: textMutedColor,
                                letterSpacing: 0.5,
                              ),
                            ),
                            const SizedBox(height: 6),
                            Row(
                              crossAxisAlignment: CrossAxisAlignment.baseline,
                              textBaseline: TextBaseline.alphabetic,
                              children: [
                                Text(
                                  '$currencySymbol${totalAllocated.toStringAsFixed(0)}',
                                  style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w900),
                                ),
                                Text(
                                  ' / $currencySymbol${globalLimit.toStringAsFixed(0)} global limit',
                                  style: TextStyle(fontSize: 11, color: textMutedColor, fontWeight: FontWeight.w500),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              // ── Category List Area ─────────────────────────────────────────
              Expanded(
                child: budgetVM.categories.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Container(
                              padding: const EdgeInsets.all(24),
                              decoration: BoxDecoration(
                                color: borderColor.withOpacity(0.3),
                                shape: BoxShape.circle,
                              ),
                              child: Icon(
                                Icons.category_outlined,
                                size: 52,
                                color: textMutedColor,
                              ),
                            ),
                            const SizedBox(height: 20),
                            const Text(
                              'No Categories Configured',
                              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'Tap "+ Add" above to structure category limits.',
                              style: TextStyle(color: textMutedColor, fontSize: 13),
                            ),
                          ],
                        ),
                      )
                    : ListView.builder(
                        padding: EdgeInsets.symmetric(horizontal: r.horizontalPadding, vertical: 8),
                        itemCount: budgetVM.categories.length,
                        itemBuilder: (context, index) {
                          final cat = budgetVM.categories[index];
                          final spent = expenseVM.getTotalSpentForCategoryInMonth(cat.id, now);
                          
                          // Load limits from Settings overrides
                          final limit = settings.categoryBudgets[cat.id] ?? cat.monthlyBudget;
                          final remaining = limit - spent;
                          final percentUsed = limit > 0 ? (spent / limit).clamp(0.0, 1.0) : 0.0;
                          
                          final color = colors[index % colors.length];

                          return Container(
                            margin: const EdgeInsets.only(bottom: 14),
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: cardBgColor,
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(color: borderColor),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withOpacity(isDarkMode ? 0.2 : 0.03),
                                  blurRadius: 10,
                                  offset: const Offset(0, 4),
                                ),
                              ],
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Row(
                                      children: [
                                        Container(
                                          width: 12,
                                          height: 12,
                                          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
                                        ),
                                        const SizedBox(width: 10),
                                        Text(
                                          cat.name,
                                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                                        ),
                                      ],
                                    ),
                                    Row(
                                      children: [
                                        Text(
                                          '$currencySymbol${limit.toStringAsFixed(0)} / mo',
                                          style: TextStyle(
                                            fontWeight: FontWeight.bold,
                                            fontSize: 12,
                                            color: isDarkMode ? Colors.white70 : Colors.black87,
                                          ),
                                        ),
                                        const SizedBox(width: 4),
                                        PopupMenuButton<String>(
                                          icon: Icon(Icons.more_vert_rounded, size: 20, color: textMutedColor),
                                          padding: EdgeInsets.zero,
                                          onSelected: (value) {
                                            if (value == 'edit') {
                                              _showEditCategorySheet(context, cat, now, settingsVM);
                                            } else if (value == 'delete') {
                                              _confirmDeleteCategory(context, cat, now, settingsVM);
                                            }
                                          },
                                          itemBuilder: (context) => [
                                            const PopupMenuItem(
                                              value: 'edit',
                                              child: Row(
                                                children: [
                                                  Icon(Icons.edit_outlined, size: 18),
                                                  SizedBox(width: 8),
                                                  Text('Edit Limit'),
                                                ],
                                              ),
                                            ),
                                            const PopupMenuItem(
                                              value: 'delete',
                                              child: Row(
                                                children: [
                                                  Icon(Icons.delete_outline_rounded, size: 18, color: Colors.red),
                                                  SizedBox(width: 8),
                                                  Text('Delete', style: TextStyle(color: Colors.red)),
                                                ],
                                              ),
                                            ),
                                          ],
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 12),
                                ClipRRect(
                                  borderRadius: BorderRadius.circular(6),
                                  child: LinearProgressIndicator(
                                    value: percentUsed,
                                    minHeight: 8,
                                    backgroundColor: isDarkMode ? Colors.white10 : Colors.black12,
                                    color: percentUsed > 0.85
                                        ? const Color(0xFFEF4444)
                                        : color,
                                  ),
                                ),
                                const SizedBox(height: 12),
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text(
                                      'Spent: $currencySymbol${spent.toStringAsFixed(0)}',
                                      style: TextStyle(color: textMutedColor, fontSize: 11),
                                    ),
                                    Text(
                                      remaining < 0
                                          ? 'Exceeded by $currencySymbol${(remaining.abs()).toStringAsFixed(0)}'
                                          : 'Remaining: $currencySymbol${remaining.toStringAsFixed(0)}',
                                      style: TextStyle(
                                        color: remaining < 0 ? const Color(0xFFEF4444) : const Color(0xFF10B981),
                                        fontWeight: FontWeight.bold,
                                        fontSize: 11,
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          );
                        },
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showAddCategorySheet(BuildContext context, DateTime currentMonth, SettingsViewModel settingsVM) {
    final nameCtrl = TextEditingController();
    final budgetCtrl = TextEditingController();
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final cardBg = isDarkMode ? const Color(0xFF0F172A) : Colors.white;
    final borderColor = isDarkMode ? const Color(0xFF334155) : const Color(0xFFE2E8F0);
    final textPrimary = isDarkMode ? Colors.white : const Color(0xFF0F172A);
    final textSecondary = isDarkMode ? const Color(0xFF94A3B8) : const Color(0xFF64748B);

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        final keyboardOffset = MediaQuery.of(ctx).viewInsets.bottom;
        return StatefulBuilder(
          builder: (ctx, setSheetState) => Container(
            padding: EdgeInsets.only(
              top: 24,
              left: 20,
              right: 20,
              bottom: 24 + keyboardOffset,
            ),
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
                      width: 48,
                      height: 4,
                      decoration: BoxDecoration(
                        color: isDarkMode ? Colors.white24 : Colors.black12,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                    borderRadius: BorderRadius.circular(24),
                    border: Border.all(color: borderColor),
                  ),
                  const SizedBox(height: 18),
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            colors: [Color(0xFF8B5CF6), Color(0xFF6366F1)],
                          ),
                          borderRadius: BorderRadius.circular(16),
                          boxShadow: [
                            BoxShadow(
                              color: const Color(0xFF8B5CF6).withValues(alpha: 0.35),
                              blurRadius: 8,
                              offset: const Offset(0, 3),
                            ),
                          ],
                        ),
                        child: const Icon(Icons.category_rounded, color: Colors.white, size: 22),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Create Category', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: textPrimary)),
                            const SizedBox(height: 2),
                            Text('Add a new category with a monthly spending cap.', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w500, color: textSecondary)),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  TextField(
                    controller: nameCtrl,
                    style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: textPrimary),
                    decoration: InputDecoration(
                      labelText: 'Category Name (e.g. Dining, Fuel)',
                      prefixIcon: const Icon(Icons.label_outline_rounded),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(16)),
                    ),
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: budgetCtrl,
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: textPrimary),
                    decoration: InputDecoration(
                      labelText: 'Monthly Spending Limit ($currencySymbol)',
                      prefixText: '$currencySymbol ',
                      prefixStyle: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF8B5CF6)),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(16)),
                    ),
                  ),
                  const SizedBox(height: 14),

                  // Quick Presets
                  Text(
                    'QUICK LIMIT PRESETS',
                    style: TextStyle(fontSize: 10, fontWeight: FontWeight.w800, letterSpacing: 1.0, color: textSecondary),
                  ),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      _buildPresetChip('+₹2,000', 2000, budgetCtrl, setSheetState, isDarkMode, textPrimary),
                      _buildPresetChip('+₹5,000', 5000, budgetCtrl, setSheetState, isDarkMode, textPrimary),
                      _buildPresetChip('+₹10,000', 10000, budgetCtrl, setSheetState, isDarkMode, textPrimary),
                      _buildPresetChip('+₹25,000', 25000, budgetCtrl, setSheetState, isDarkMode, textPrimary),
                    ],
                  ),

                  const SizedBox(height: 24),
                  Container(
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [Color(0xFF8B5CF6), Color(0xFF6366F1)],
                      ),
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFF8B5CF6).withValues(alpha: 0.35),
                          blurRadius: 10,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: ElevatedButton.icon(
                      onPressed: () async {
                        final budget = double.tryParse(budgetCtrl.text);
                        if (nameCtrl.text.isNotEmpty && budget != null) {
                          final budgetVM = context.read<BudgetViewModel>();
                          
                          // Save category reference
                          await budgetVM.addCategory(nameCtrl.text, budget, currentMonth);
                          
                          // Find category to seed Settings limit config mapping
                          final createdCat = budgetVM.categories.firstWhere(
                            (c) => c.name.toLowerCase() == nameCtrl.text.trim().toLowerCase(),
                            orElse: () => budgetVM.categories.last,
                          );
                          await settingsVM.updateCategoryBudget(createdCat.id, budget);

                          if (context.mounted) {
                            Navigator.pop(ctx);
                            AppSnackBar.show(context, message: 'Category "${nameCtrl.text}" created successfully.', isError: false);
                          }
                        }
                      },
                      icon: const Icon(Icons.add_circle_rounded, color: Colors.white, size: 18),
                      label: const Text('Create Category', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 15, color: Colors.white)),
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

  Widget _buildPresetChip(
    String label,
    double increment,
    TextEditingController ctrl,
    StateSetter setSheetState,
    bool isDark,
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
          color: isDark ? const Color(0xFF1E293B) : const Color(0xFFF1F5F9),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0)),
        ),
        child: Text(label, style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: textPrimary)),
      ),
    );
  }

  void _showEditCategorySheet(BuildContext context, cat, DateTime currentMonth, SettingsViewModel settingsVM) {
    final currentLimit = settingsVM.settings.categoryBudgets[cat.id] ?? cat.monthlyBudget;
    
    ModernBudgetTargetDialog.show(
      context: context,
      type: BudgetTargetType.categoryLimit,
      initialValue: currentLimit,
      categoryName: cat.name,
      monthlyBudgetLimit: settingsVM.settings.monthlyBudgetLimit,
      onSave: (newBudget) async {
        final updatedCat = cat.copyWith(
          monthlyBudget: newBudget,
        );
        
        // Save Category Entity
        await context.read<BudgetViewModel>().updateCategory(updatedCat, currentMonth);
        
        // Update Settings Limit Mapping
        await settingsVM.updateCategoryBudget(cat.id, newBudget);

        if (context.mounted) {
          AppSnackBar.show(context, message: 'Category limit saved successfully.', isError: false);
        }
      },
    );
  }

  void _confirmDeleteCategory(BuildContext context, cat, DateTime currentMonth, SettingsViewModel settingsVM) {
    final expenseVM = context.read<ExpenseViewModel>();
    final theme = Theme.of(context);
    final isDarkMode = theme.brightness == Brightness.dark;
    
    final expenses = expenseVM
        .getExpensesForMonth(currentMonth)
        .where((e) => e.categoryId == cat.id)
        .toList();

    if (expenses.isNotEmpty) {
      AppSnackBar.show(
        context,
        message: 'Cannot delete category in use (${expenses.length} expenses)',
        isError: true,
      );
      return;
    }

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        final cardBg = isDarkMode ? const Color(0xFF0F172A) : Colors.white;
        final borderColor = isDarkMode ? const Color(0xFF334155) : const Color(0xFFE2E8F0);
        final textPrimary = isDarkMode ? Colors.white : const Color(0xFF0F172A);
        final textSecondary = isDarkMode ? const Color(0xFF94A3B8) : const Color(0xFF64748B);

        return Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: cardBg,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
            border: Border.all(color: borderColor, width: 1.2),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Center(
                child: Container(
                  width: 48,
                  height: 4,
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
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: const Color(0xFFEF4444).withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: const Color(0xFFEF4444).withValues(alpha: 0.25)),
                    ),
                    child: const Icon(Icons.delete_forever_rounded, color: Color(0xFFEF4444), size: 24),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Delete Category?', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: textPrimary)),
                        const SizedBox(height: 2),
                        Text('Permanently remove "${cat.name}".', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w500, color: textSecondary)),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Text(
                'Are you sure you want to delete this category? Expense logs using this category will remain, but the category budget limit configuration will be removed.',
                style: TextStyle(fontSize: 13, color: textSecondary, height: 1.4),
              ),
              const SizedBox(height: 24),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Navigator.pop(ctx),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        side: BorderSide(color: borderColor),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                      ),
                      child: Text('Cancel', style: TextStyle(fontWeight: FontWeight.bold, color: textPrimary)),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () async {
                        context.read<BudgetViewModel>().deleteCategory(cat.id, currentMonth);
                        Navigator.pop(ctx);
                        AppSnackBar.show(context, message: 'Category deleted.', isError: false);
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFFEF4444),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                        elevation: 0,
                      ),
                      child: const Text('Delete', style: TextStyle(fontWeight: FontWeight.w800)),
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }
}
