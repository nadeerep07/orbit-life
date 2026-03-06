import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/utils/app_routes.dart';
import '../theme/app_theme.dart';
import '../viewmodels/accounts_view_model.dart';
import '../viewmodels/budget_view_model.dart';
import '../viewmodels/expense_view_model.dart';
import '../viewmodels/income_view_model.dart';
import '../viewmodels/month_view_model.dart';
import 'package:intl/intl.dart';

class DashboardScreen extends StatelessWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final expenseVM = context.watch<ExpenseViewModel>();
    final budgetVM = context.watch<BudgetViewModel>();
    final accountsVM = context.watch<AccountsViewModel>();
    final incomeVM = context.watch<IncomeViewModel>();
    final monthVM = context.watch<MonthViewModel>();

    final now = monthVM.currentMonth;

    final double totalBudget = budgetVM.categories.fold(
      0,
      (sum, cat) => sum + cat.monthlyBudget,
    );
    final double totalSpent = expenseVM.getTotalSpentInMonth(now);
    final double remaining = totalBudget - totalSpent;
    final double totalBalance = accountsVM.totalBalance;
    final double totalIncome = incomeVM.getTotalIncomeForMonth(now);

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        title: const Text('OrbitLife'),
        actions: [
          IconButton(
            icon: const Icon(Icons.calendar_month),
            onPressed: () async {
              final selectedDate = await showMonthPicker(
                context,
                monthVM.currentMonth,
              );
              if (selectedDate != null) {
                monthVM.changeMonth(selectedDate);
              }
            },
          ),
          IconButton(
            icon: const Icon(Icons.settings_outlined),
            onPressed: () => Navigator.pushNamed(context, AppRoutes.setting),
          ),
        ],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(vertical: 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _buildSummaryCard(
                context,
                totalBudget,
                totalIncome,
                totalSpent,
                remaining,
                now,
              ),
              const SizedBox(height: 16),
              _buildAccountsOverview(context, totalBalance),
              const SizedBox(height: 16),
              _buildActionGrid(context),
            ],
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => Navigator.pushNamed(context, AppRoutes.addExpense),
        child: const Icon(Icons.add),
      ),
    );
  }

  Widget _buildSummaryCard(
    BuildContext context,
    double totalBudget,
    double totalIncome,
    double spent,
    double remaining,
    DateTime currentMonth,
  ) {
    return IOSCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            DateFormat('MMMM yyyy').format(currentMonth),
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              fontWeight: FontWeight.w600,
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _buildColumn(
                context,
                'Income',
                '₹${totalIncome.toStringAsFixed(0)}',
                Colors.green,
              ),
              _buildColumn(
                context,
                'Spent',
                '₹${spent.toStringAsFixed(0)}',
                Theme.of(context).colorScheme.error,
              ),
              _buildColumn(
                context,
                'Remaining',
                '₹${remaining.toStringAsFixed(0)}',
                remaining >= 0
                    ? Theme.of(context).colorScheme.onSurface
                    : Theme.of(context).colorScheme.error,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildColumn(
    BuildContext context,
    String label,
    String value,
    Color valueColor,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            color: Theme.of(context).colorScheme.onSurfaceVariant,
            fontSize: 13,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: TextStyle(
            color: valueColor,
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }

  Widget _buildAccountsOverview(BuildContext context, double totalBalance) {
    return IOSCard(
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Total Balance',
                style: TextStyle(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                  fontSize: 13,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                '₹${totalBalance.toStringAsFixed(0)}',
                style: const TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          ElevatedButton(
            onPressed: () => Navigator.pushNamed(context, AppRoutes.accounts),
            style: ElevatedButton.styleFrom(
              backgroundColor: Theme.of(
                context,
              ).colorScheme.primary.withOpacity(0.1),
              foregroundColor: Theme.of(context).colorScheme.primary,
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: const Text('View Accounts'),
          ),
        ],
      ),
    );
  }

  Widget _buildActionGrid(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: GridView.count(
        crossAxisCount: 2,
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        mainAxisSpacing: 16,
        crossAxisSpacing: 16,
        childAspectRatio: 1.5,
        children: [
          _buildActionCard(
            context,
            'Income',
            Icons.account_balance_wallet,
            AppRoutes.income,
          ),
          _buildActionCard(
            context,
            'Budget',
            Icons.pie_chart_outline,
            AppRoutes.budget,
          ),
          _buildActionCard(
            context,
            'Analytics',
            Icons.bar_chart,
            AppRoutes.analytics,
          ),
          _buildActionCard(
            context,
            'Savings',
            Icons.savings_outlined,
            AppRoutes.savings,
          ),
          _buildActionCard(
            context,
            'All Expenses',
            Icons.list_alt,
            AppRoutes.allExpenses,
          ),
          _buildActionCard(
            context,
            'Mileage',
            Icons.directions_bike,
            AppRoutes.mileage,
          ),
          _buildActionCard(
            context,
            'Transfer',
            Icons.swap_horiz,
            AppRoutes.transfer,
          ),
          _buildActionCard(
            context,
            'Goals',
            Icons.flag_outlined,
            AppRoutes.goals,
          ),
          _buildActionCard(
            context,
            'EMI Tracker',
            Icons.credit_card,
            AppRoutes.emiCalculator,
          ),
          _buildActionCard(
            context,
            'Diet AI',
            Icons.restaurant_menu,
            AppRoutes.dietDashboard,
          ),
          _buildActionCard(
            context,
            'Borrow & Lend',
            Icons.handshake_outlined,
            AppRoutes.borrowLend,
          ),
          _buildActionCard(
            context,
            'Investments',
            Icons.trending_up,
            AppRoutes.investments,
          ),
        ],
      ),
    );
  }

  Widget _buildActionCard(
    BuildContext context,
    String title,
    IconData icon,
    String route,
  ) {
    return GestureDetector(
      onTap: () => Navigator.pushNamed(context, route),
      child: Container(
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surface,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Theme.of(context).brightness == Brightness.dark
                  ? Colors.transparent
                  : Colors.black.withOpacity(0.03),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: Theme.of(context).colorScheme.primary, size: 32),
            const SizedBox(height: 8),
            Text(title, style: const TextStyle(fontWeight: FontWeight.w600)),
          ],
        ),
      ),
    );
  }

  Future<DateTime?> showMonthPicker(
    BuildContext context,
    DateTime initialDate,
  ) async {
    return showDatePicker(
      context: context,
      initialDate: initialDate,
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
      initialDatePickerMode: DatePickerMode.year,
    );
  }
}
