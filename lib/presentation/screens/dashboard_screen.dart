import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/utils/app_routes.dart';
import '../viewmodels/accounts_view_model.dart';
import '../viewmodels/expense_view_model.dart';
import '../viewmodels/income_view_model.dart';
import '../viewmodels/month_view_model.dart';
import '../viewmodels/auth_view_model.dart';
import '../viewmodels/settings_view_model.dart';
import '../viewmodels/emi_tracker_view_model.dart';
import '../viewmodels/borrow_lend_view_model.dart';
import '../viewmodels/savings_view_model.dart';
import 'package:intl/intl.dart';
import '../../core/utils/currency_formatter.dart';
import '../../core/services/obligation_analysis_engine.dart';
import '../../core/services/savings_recommendation_engine.dart';
import '../../core/services/debt_optimization_engine.dart';
import '../../core/services/spendable_wallet_engine.dart';
import '../../core/services/daily_spending_engine.dart';
import '../../core/services/financial_health_engine.dart';

class DashboardScreen extends StatelessWidget {
  const DashboardScreen({super.key});

  String _getGreeting() {
    final hour = DateTime.now().hour;
    if (hour < 12) return 'Good Morning';
    if (hour < 17) return 'Good Afternoon';
    return 'Good Evening';
  }

  @override
  Widget build(BuildContext context) {
    final expenseVM = context.watch<ExpenseViewModel>();
    final accountsVM = context.watch<AccountsViewModel>();
    final incomeVM = context.watch<IncomeViewModel>();
    final monthVM = context.watch<MonthViewModel>();
    final authVM = context.watch<AuthViewModel>();
    final settingsVM = context.watch<SettingsViewModel>();
    final emiVM = context.watch<EmiTrackerViewModel>();
    final blVM = context.watch<BorrowLendViewModel>();
    final savingsVM = context.watch<SavingsViewModel>();

    final user = authVM.currentUser;
    final userName = user != null ? (user.displayName ?? 'User') : 'User';
    final now = monthVM.currentMonth;
    final settings = settingsVM.settings;

    // ── Dynamic Financial Engine Integrations ────────────────────────
    final double totalSpent = expenseVM.getTotalSpentInMonth(now);
    final double totalBalance = accountsVM.totalBalance;
    final double totalIncome = incomeVM.getTotalIncomeForMonth(now);
    final double actualSavings = savingsVM.savings?.currentBalance ?? 0.0;

    // 1. Obligations
    final obligationsAnalysis = ObligationAnalysisEngine.analyze(
      emis: emiVM.emis,
      settings: settings,
    );

    // 2. Outstanding debt
    final double outstandingDebt = blVM.entries
        .where((bl) => bl.type == 'borrowed' && bl.status == 'pending')
        .fold(0.0, (sum, bl) => sum + bl.remainingAmount);

    // 3. Savings recommendations
    final savingsRec = SavingsRecommendationEngine.calculate(
      incomeAmount: totalIncome,
      totalObligations: obligationsAnalysis.totalObligations,
      outstandingDebt: outstandingDebt,
      currentSavings: actualSavings,
      settings: settings,
    );

    // 4. Debt recommendations
    final accountBalances = {for (var a in accountsVM.accounts) a.id: a.openingBalance};
    final debtRec = DebtOptimizationEngine.calculate(
      borrowLends: blVM.entries,
      accounts: accountsVM.accounts,
      accountBalances: accountBalances,
      incomeAmount: totalIncome,
      totalObligations: obligationsAnalysis.totalObligations,
    );

    // Determine allocations depending on active Mode
    double savingsAlloc = savingsRec.minimum;
    double debtAlloc = debtRec.minimumPayment;
    if (settings.financialMode == 'recovery') {
      debtAlloc = debtRec.recommendedPayment;
    } else if (settings.financialMode == 'growth') {
      savingsAlloc = savingsRec.recommended;
    } else if (settings.financialMode == 'survival') {
      savingsAlloc = 0.0;
      debtAlloc = debtRec.minimumPayment;
    }

    // 5. Spendable Wallet
    final spendableWallet = SpendableWalletEngine.calculate(
      incomeAmount: totalIncome,
      totalObligations: obligationsAnalysis.totalObligations,
      savingsAllocation: savingsAlloc,
      debtAllocation: debtAlloc,
    );

    // 6. Daily limit math
    final dailySpendingReport = DailySpendingEngine.calculate(
      spendableWalletAmount: spendableWallet.totalSpendableAmount > 0 
          ? spendableWallet.totalSpendableAmount 
          : settings.monthlyBudgetLimit,
      currentMonthSpent: totalSpent,
      currentTotalBalance: totalBalance,
      currentDate: DateTime.now(),
    );

    final categorySpent = {
      for (var catId in settings.categoryBudgets.keys)
        catId: expenseVM.getTotalSpentForCategoryInMonth(catId, now)
    };

    // 7. Health score math
    final healthReport = FinancialHealthEngine.calculate(
      monthlyIncome: totalIncome,
      monthlyExpenses: totalSpent,
      outstandingDebt: outstandingDebt,
      currentEmergencyFund: actualSavings,
      targetEmergencyFund: settings.emergencyFundGoal,
      totalBudgetLimit: settings.monthlyBudgetLimit,
      categoryBudgets: settings.categoryBudgets,
      categorySpent: categorySpent,
    );

    return Scaffold(
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showQuickAddSheet(context),
        backgroundColor: Theme.of(context).colorScheme.primary,
        foregroundColor: Colors.white,
        elevation: 4,
        shape: const CircleBorder(),
        child: const Icon(Icons.add, size: 28),
      ),
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // ── Header Greeting & Profile ──────────────────────────────
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                child: Row(
                  children: [
                    CircleAvatar(
                      radius: 20,
                      backgroundImage: user != null && user.photoUrl != null
                          ? NetworkImage(user.photoUrl!)
                          : null,
                      backgroundColor: Theme.of(context).colorScheme.primary.withOpacity(0.12),
                      child: user == null || user.photoUrl == null
                          ? Text(
                              userName[0].toUpperCase(),
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                color: Theme.of(context).colorScheme.primary,
                              ),
                            )
                          : null,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            _getGreeting(),
                            style: const TextStyle(fontSize: 12, color: Colors.grey, fontWeight: FontWeight.w500),
                          ),
                          Text(
                            userName,
                            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.calendar_month_outlined),
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
              ),

              // ── Dynamic Daily Limit & Wallet Card ────────────────────────
              Container(
                margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      Theme.of(context).colorScheme.primary,
                      Theme.of(context).colorScheme.primary.withOpacity(0.85),
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(24),
                  boxShadow: [
                    BoxShadow(
                      color: Theme.of(context).colorScheme.primary.withOpacity(0.25),
                      blurRadius: 15,
                      offset: const Offset(0, 8),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          "TODAY'S SAFE SPENDING LIMIT",
                          style: TextStyle(
                            color: Colors.white70,
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 1.2,
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                            color: Colors.white24,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            settings.financialMode.toUpperCase(),
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 9,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      '$currencySymbol${dailySpendingReport.dailyLimit.toStringAsFixed(0)}',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 36,
                        fontWeight: FontWeight.bold,
                        letterSpacing: -0.5,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Weekly Limit: $currencySymbol${dailySpendingReport.weeklyLimit.toStringAsFixed(0)}',
                          style: const TextStyle(color: Colors.white70, fontSize: 12),
                        ),
                        Text(
                          'Wallet: $currencySymbol${totalBalance.toStringAsFixed(0)}',
                          style: const TextStyle(color: Colors.white70, fontSize: 12, fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              // ── Smart Dynamic Insights Carousel ────────────────────────────
              _buildSmartInsightsCarousel(context, healthReport),

              // ── Financial Health Gauge ────────────────────────────────────
              _buildHealthGaugeCard(context, healthReport),

              // ── Quick Navigation Services ─────────────────────────────────
              _buildGroupedModules(context),

              // ── Recent Transaction Logs ──────────────────────────────────
              _buildRecentFeed(context, expenseVM, incomeVM),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSmartInsightsCarousel(BuildContext context, HealthReport report) {
    return Container(
      height: 70,
      margin: const EdgeInsets.only(top: 8, bottom: 8),
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: report.improvements.length,
        itemBuilder: (ctx, idx) {
          return Container(
            width: 280,
            margin: const EdgeInsets.only(right: 12),
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.primary.withOpacity(0.05),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Theme.of(context).colorScheme.primary.withOpacity(0.12)),
            ),
            child: Row(
              children: [
                Icon(Icons.lightbulb_outline, color: Theme.of(context).colorScheme.primary, size: 20),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    report.improvements[idx],
                    style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildHealthGaugeCard(BuildContext context, HealthReport report) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: BorderSide(color: Theme.of(context).dividerColor.withOpacity(0.08)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Stack(
              alignment: Alignment.center,
              children: [
                SizedBox(
                  width: 60,
                  height: 60,
                  child: CircularProgressIndicator(
                    value: report.score / 100,
                    strokeWidth: 6,
                    backgroundColor: Colors.grey.withOpacity(0.12),
                    valueColor: AlwaysStoppedAnimation<Color>(
                      report.score >= 80 
                          ? Colors.green 
                          : (report.score >= 50 ? Colors.orange : Colors.red),
                    ),
                  ),
                ),
                Text(
                  '${report.score}',
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                ),
              ],
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('FINANCIAL HEALTH SCORE', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.grey)),
                  const SizedBox(height: 4),
                  Text(
                    report.feedback.firstOrNull ?? 'Keep tracking obligations and savings targets.',
                    style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildGroupedModules(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'FINANCIAL UTILITIES',
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.bold,
              letterSpacing: 1.2,
              color: Colors.grey,
            ),
          ),
          const SizedBox(height: 12),
          GridView.count(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            crossAxisCount: 4,
            mainAxisSpacing: 16,
            crossAxisSpacing: 16,
            children: [
              _buildFeatureTile(context, Icons.account_balance_wallet, 'Accounts', AppRoutes.accounts),
              _buildFeatureTile(context, Icons.trending_up, 'Incomes', AppRoutes.income),
              _buildFeatureTile(context, Icons.trending_down, 'Expenses', AppRoutes.allExpenses),
              _buildFeatureTile(context, Icons.analytics, 'Analytics', AppRoutes.analytics),
              _buildFeatureTile(context, Icons.pie_chart, 'Budgets', AppRoutes.budget),
              _buildFeatureTile(context, Icons.savings, 'Savings', AppRoutes.savings),
              _buildFeatureTile(context, Icons.alarm, 'EMI Tracker', AppRoutes.emiCalculator),
              _buildFeatureTile(context, Icons.handshake, 'Debt Logs', AppRoutes.borrowLend),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildFeatureTile(BuildContext context, IconData icon, String label, String route) {
    return InkWell(
      onTap: () => Navigator.pushNamed(context, route),
      borderRadius: BorderRadius.circular(16),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.primary.withOpacity(0.08),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: Theme.of(context).colorScheme.primary, size: 22),
          ),
          const SizedBox(height: 6),
          Text(
            label,
            style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600),
            textAlign: TextAlign.center,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  Widget _buildRecentFeed(BuildContext context, ExpenseViewModel expenseVM, IncomeViewModel incomeVM) {
    // Merge latest 2 expenses and 2 incomes
    final latestExpenses = expenseVM.expenses.take(2).toList();
    final latestIncomes = incomeVM.incomes.take(2).toList();

    final feedItems = <Map<String, dynamic>>[];
    for (var e in latestExpenses) {
      feedItems.add({'title': e.description.isEmpty ? 'Expense' : e.description, 'amount': e.amount, 'isCredit': false, 'date': e.date});
    }
    for (var i in latestIncomes) {
      feedItems.add({'title': i.source, 'amount': i.amount, 'isCredit': true, 'date': i.date});
    }

    feedItems.sort((a, b) => (b['date'] as DateTime).compareTo(a['date'] as DateTime));

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'RECENT LOGS FEED',
                style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, letterSpacing: 1.2, color: Colors.grey),
              ),
              GestureDetector(
                onTap: () => Navigator.pushNamed(context, AppRoutes.allExpenses),
                child: Text(
                  'See All',
                  style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Theme.of(context).colorScheme.primary),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          if (feedItems.isEmpty)
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: Theme.of(context).dividerColor.withOpacity(0.03),
                borderRadius: BorderRadius.circular(16),
              ),
              child: const Text('No transactions recorded yet.', textAlign: TextAlign.center, style: TextStyle(color: Colors.grey)),
            )
          else
            ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: feedItems.length,
              separatorBuilder: (_, __) => const SizedBox(height: 8),
              itemBuilder: (ctx, idx) {
                final item = feedItems[idx];
                final isCredit = item['isCredit'] as bool;
                return Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Theme.of(context).cardColor,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: Theme.of(context).dividerColor.withOpacity(0.05)),
                  ),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: (isCredit ? Colors.green : Colors.red).withOpacity(0.08),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          isCredit ? Icons.arrow_downward : Icons.arrow_upward,
                          color: isCredit ? Colors.green : Colors.red,
                          size: 16,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(item['title'] as String, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                            const SizedBox(height: 4),
                            Text(
                              DateFormat('MMM dd, yyyy').format(item['date'] as DateTime),
                              style: const TextStyle(fontSize: 11, color: Colors.grey),
                            ),
                          ],
                        ),
                      ),
                      Text(
                        '${isCredit ? '+' : '-'}$currencySymbol${(item['amount'] as double).toStringAsFixed(0)}',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: isCredit ? Colors.green : Colors.red,
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
        ],
      ),
    );
  }

  void _showQuickAddSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      barrierColor: Colors.black.withOpacity(0.5),
      isScrollControlled: true,
      builder: (ctx) {
        final theme = Theme.of(context);
        return Container(
          decoration: BoxDecoration(
            color: theme.scaffoldBackgroundColor,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.15),
                blurRadius: 10,
                offset: const Offset(0, -4),
              ),
            ],
          ),
          child: SafeArea(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(24, 12, 24, 24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Center(
                    child: Container(
                      width: 40,
                      height: 4,
                      margin: const EdgeInsets.only(bottom: 24),
                      decoration: BoxDecoration(
                        color: theme.dividerColor.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                  Text(
                    'Quick Add',
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                      fontSize: 18,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 24),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      _QuickAddButton(
                        icon: Icons.trending_down,
                        label: 'Add Expense',
                        color: Colors.red,
                        onTap: () {
                          Navigator.pop(ctx);
                          Navigator.pushNamed(context, AppRoutes.addExpense);
                        },
                      ),
                      _QuickAddButton(
                        icon: Icons.trending_up,
                        label: 'Add Income',
                        color: Colors.green,
                        onTap: () {
                          Navigator.pop(ctx);
                          Navigator.pushNamed(context, AppRoutes.income);
                        },
                      ),
                      _QuickAddButton(
                        icon: Icons.swap_horiz,
                        label: 'Transfer',
                        color: Colors.blue,
                        onTap: () {
                          Navigator.pop(ctx);
                          Navigator.pushNamed(context, AppRoutes.transfer);
                        },
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

class _QuickAddButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;

  const _QuickAddButton({
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        width: 100,
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: color.withOpacity(isDark ? 0.15 : 0.08),
                shape: BoxShape.circle,
              ),
              child: Icon(
                icon,
                color: color,
                size: 28,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              label,
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}

class MonthPicker extends StatelessWidget {
  final DateTime initialDate;
  const MonthPicker({super.key, required this.initialDate});

  @override
  Widget build(BuildContext context) {
    return Container();
  }
}

Future<DateTime?> showMonthPicker(BuildContext context, DateTime initialDate) async {
  final now = DateTime.now();
  return showDatePicker(
    context: context,
    initialDate: initialDate,
    firstDate: DateTime(now.year - 5),
    lastDate: DateTime(now.year + 5),
    initialDatePickerMode: DatePickerMode.year,
  );
}
