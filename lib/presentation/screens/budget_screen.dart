import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../theme/app_theme.dart';
import '../viewmodels/budget_view_model.dart';
import '../viewmodels/expense_view_model.dart';
import '../viewmodels/month_view_model.dart';
import 'package:intl/intl.dart';

class BudgetScreen extends StatelessWidget {
  const BudgetScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final budgetVM = context.watch<BudgetViewModel>();
    final expenseVM = context.watch<ExpenseViewModel>();
    final monthVM = context.watch<MonthViewModel>();
    final now = monthVM.currentMonth;

    return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('Budgets & Categories'),
            Text(
              DateFormat('MMMM yyyy').format(now),
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.normal,
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: () => _showAddCategoryDialog(context, now),
          ),
        ],
      ),
      body: budgetVM.categories.isEmpty
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.category_outlined,
                    size: 80,
                    color: Theme.of(
                      context,
                    ).colorScheme.onSurfaceVariant.withOpacity(0.5),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'No categories yet.',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Tap + to add a category for ${DateFormat('MMMM').format(now)}.',
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            )
          : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: budgetVM.categories.length,
              itemBuilder: (context, index) {
                final cat = budgetVM.categories[index];
                final spent = expenseVM.getTotalSpentForCategoryInMonth(
                  cat.id,
                  now,
                );
                final remaining = cat.monthlyBudget - spent;
                final percentUsed = (spent / cat.monthlyBudget).clamp(0.0, 1.0);

                return IOSCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            cat.name,
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                          ),
                          Row(
                            children: [
                              Text(
                                '₹${cat.monthlyBudget.toStringAsFixed(0)} / mo',
                                style: TextStyle(
                                  color: Theme.of(
                                    context,
                                  ).colorScheme.onSurfaceVariant,
                                ),
                              ),
                              PopupMenuButton<String>(
                                icon: Icon(
                                  Icons.more_vert,
                                  size: 20,
                                  color: Theme.of(
                                    context,
                                  ).colorScheme.onSurfaceVariant,
                                ),
                                onSelected: (value) {
                                  if (value == 'edit') {
                                    _showEditCategoryDialog(context, cat, now);
                                  } else if (value == 'delete') {
                                    _confirmDeleteCategory(context, cat, now);
                                  }
                                },
                                itemBuilder: (context) => [
                                  const PopupMenuItem(
                                    value: 'edit',
                                    child: Text('Edit'),
                                  ),
                                  const PopupMenuItem(
                                    value: 'delete',
                                    child: Text('Delete'),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      LinearProgressIndicator(
                        value: percentUsed,
                        backgroundColor: Theme.of(
                          context,
                        ).scaffoldBackgroundColor,
                        color: percentUsed > 0.8
                            ? Theme.of(context).colorScheme.error
                            : Theme.of(context).colorScheme.primary,
                        minHeight: 8,
                        borderRadius: BorderRadius.circular(4),
                      ),
                      const SizedBox(height: 12),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text('Spent: ₹${spent.toStringAsFixed(0)}'),
                          Text(
                            'Left: ₹${remaining.toStringAsFixed(0)}',
                            style: TextStyle(
                              color: remaining < 0
                                  ? Theme.of(context).colorScheme.error
                                  : Colors.green,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                );
              },
            ),
    );
  }

  void _showAddCategoryDialog(BuildContext context, DateTime currentMonth) {
    final nameCtrl = TextEditingController();
    final budgetCtrl = TextEditingController();

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Add Category'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: nameCtrl,
              decoration: const InputDecoration(labelText: 'Name'),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: budgetCtrl,
              decoration: const InputDecoration(labelText: 'Monthly Budget'),
              keyboardType: const TextInputType.numberWithOptions(
                decimal: true,
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              final budget = double.tryParse(budgetCtrl.text);
              if (nameCtrl.text.isNotEmpty && budget != null) {
                context.read<BudgetViewModel>().addCategory(
                  nameCtrl.text,
                  budget,
                  currentMonth,
                );
                Navigator.pop(ctx);
              }
            },
            child: const Text('Add'),
          ),
        ],
      ),
    );
  }

  void _showEditCategoryDialog(
    BuildContext context,
    cat,
    DateTime currentMonth,
  ) {
    final nameCtrl = TextEditingController(text: cat.name);
    final budgetCtrl = TextEditingController(
      text: cat.monthlyBudget.toString(),
    );

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Edit Category'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: nameCtrl,
              decoration: const InputDecoration(labelText: 'Name'),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: budgetCtrl,
              decoration: const InputDecoration(labelText: 'Monthly Budget'),
              keyboardType: const TextInputType.numberWithOptions(
                decimal: true,
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              final budget = double.tryParse(budgetCtrl.text);
              if (nameCtrl.text.isNotEmpty && budget != null) {
                final updatedCat = cat.copyWith(
                  // Re-create with new values while preserving ID.
                  name: nameCtrl.text,
                  monthlyBudget: budget,
                );
                // Passing the updated entity to ViewModel
                context.read<BudgetViewModel>().updateCategory(
                  updatedCat,
                  currentMonth,
                );
                Navigator.pop(ctx);
              }
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  void _confirmDeleteCategory(
    BuildContext context,
    cat,
    DateTime currentMonth,
  ) {
    final expenseVM = context.read<ExpenseViewModel>();
    final expenses = expenseVM
        .getExpensesForMonth(currentMonth)
        .where((e) => e.categoryId == cat.id)
        .toList();

    if (expenses.isNotEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Cannot delete category in use (${expenses.length} expenses)',
          ),
        ),
      );
      return;
    }

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Category?'),
        content: Text('Are you sure you want to delete "${cat.name}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              context.read<BudgetViewModel>().deleteCategory(
                cat.id,
                currentMonth,
              );
              Navigator.pop(ctx);
            },
            child: Text(
              'Delete',
              style: TextStyle(color: Theme.of(context).colorScheme.error),
            ),
          ),
        ],
      ),
    );
  }
}
