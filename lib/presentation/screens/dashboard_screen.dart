import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/utils/app_routes.dart';
import '../../core/utils/responsive.dart';
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
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../features/credit_card/presentation/blocs/credit_card_bloc.dart';

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

    final r = Responsive(context);

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: SafeArea(
        child: Stack(
          children: [
            Center(
              child: ConstrainedBox(
                constraints: BoxConstraints(maxWidth: r.contentMaxWidth),
                child: SingleChildScrollView(
                  padding: EdgeInsets.only(
                    top: r.isTabletOrDesktop ? 16 : 8,
                    bottom: 96,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // ── Header Greeting & Profile ──────────────────────────────
              Padding(
                padding: EdgeInsets.symmetric(horizontal: r.horizontalPadding, vertical: 12),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(2),
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: LinearGradient(
                          colors: [
                            Theme.of(context).colorScheme.primary,
                            Theme.of(context).colorScheme.secondary,
                          ],
                        ),
                      ),
                      child: CircleAvatar(
                        radius: r.isTabletOrDesktop ? 26 : 20,
                        backgroundImage: user != null && user.photoUrl != null
                            ? NetworkImage(user.photoUrl!)
                            : null,
                        backgroundColor: Theme.of(context).cardColor,
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
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            _getGreeting(),
                            style: TextStyle(
                              fontSize: 12,
                              color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6),
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          Text(
                            userName,
                            style: TextStyle(fontSize: r.isTabletOrDesktop ? 20 : 17, fontWeight: FontWeight.bold),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                    // Month selector pill
                    InkWell(
                      onTap: () async {
                        final selectedDate = await showMonthPicker(
                          context,
                          monthVM.currentMonth,
                        );
                        if (selectedDate != null) {
                          monthVM.changeMonth(selectedDate);
                        }
                      },
                      borderRadius: BorderRadius.circular(20),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.08),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                            color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.15),
                          ),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.calendar_today_rounded,
                              size: 14,
                              color: Theme.of(context).colorScheme.primary,
                            ),
                            const SizedBox(width: 6),
                            Text(
                              DateFormat('MMM yyyy').format(now),
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                                color: Theme.of(context).colorScheme.primary,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    // const SizedBox(width: 8),
                    // Container(
                    //   decoration: BoxDecoration(
                    //     color: Theme.of(context).dividerColor.withValues(alpha: 0.06),
                    //     shape: BoxShape.circle,
                    //   ),
                    //   child: IconButton(
                    //     icon: const Icon(Icons.settings_outlined, size: 20),
                    //     onPressed: () => Navigator.pushNamed(context, AppRoutes.setting),
                    //   ),
                    // ),
                  ],
                ),
              ),

              // ── Compact Safe Daily Spending Limit Micro Bar ─────────────────────
              Padding(
                padding: EdgeInsets.symmetric(horizontal: r.horizontalPadding, vertical: 4),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.surfaceContainerHighest.withValues(alpha: 0.4),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: Theme.of(context).dividerColor.withValues(alpha: 0.08)),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.auto_awesome_rounded, size: 16, color: Theme.of(context).colorScheme.primary),
                      const SizedBox(width: 8),
                      Text(
                        'Safe Daily Limit: ',
                        style: TextStyle(
                          fontSize: 12,
                          color: Theme.of(context).textTheme.bodyMedium?.color?.withValues(alpha: 0.7),
                        ),
                      ),
                      Text(
                        '$currencySymbol${dailySpendingReport.dailyLimit.toStringAsFixed(0)}/day',
                        style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                      ),
                      const Spacer(),
                      Text(
                        'Spent: $currencySymbol${totalSpent.toStringAsFixed(0)}',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          color: Theme.of(context).colorScheme.primary,
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              // ── SuperMoney FD-Backed Secured Credit Card Banner ────────────────────
              _buildSuperMoneyCard(context),

              // ── Quick Financial Metrics Row ────────────────────────────
              _buildFinancialMetricsRow(
                context,
                balance: totalBalance,
                income: totalIncome,
                expenses: totalSpent,
                savings: actualSavings,
              ),

              // ── Smart Dynamic Insights Carousel ────────────────────────────
          //    _buildSmartInsightsCarousel(context, healthReport),

              // ── Quick Navigation Services ─────────────────────────────────
              const FinancialUtilitiesSection(),

              // ── Recent Transaction Logs ──────────────────────────────────
              _buildRecentFeed(context, expenseVM, incomeVM),
            ],
          ),
        ),
        ),
        ),
            
            // ── Premium Floating Glassmorphic Dock ──────────────────────────
            Align(
              alignment: Alignment.bottomCenter,
              child: Padding(
                padding: const EdgeInsets.only(bottom: 20),
                child: _buildFloatingGlassmorphicDock(context),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFinancialMetricsRow(
    BuildContext context, {
    required double balance,
    required double income,
    required double expenses,
    required double savings,
  }) {
    final r = Responsive(context);
    // On tablet show a grid row instead of horizontal scroll
    if (r.isTabletOrDesktop) {
      return Padding(
        padding: EdgeInsets.symmetric(horizontal: r.horizontalPadding, vertical: 8),
        child: Row(
          children: [
            _buildMetricCard(context, title: 'Net Balance', amount: balance, icon: Icons.account_balance_wallet_rounded, iconColor: Colors.blueAccent, bgColor: Colors.blueAccent.withValues(alpha: 0.08), onTap: () => Navigator.pushNamed(context, AppRoutes.accounts), flex: 1),
            const SizedBox(width: 12),
            _buildMetricCard(context, title: 'Income', amount: income, icon: Icons.south_west_rounded, iconColor: Colors.green, bgColor: Colors.green.withValues(alpha: 0.08), onTap: () => Navigator.pushNamed(context, AppRoutes.income), flex: 1),
            const SizedBox(width: 12),
            _buildMetricCard(context, title: 'Expenses', amount: expenses, icon: Icons.north_east_rounded, iconColor: Colors.redAccent, bgColor: Colors.redAccent.withValues(alpha: 0.08), onTap: () => Navigator.pushNamed(context, AppRoutes.allExpenses), flex: 1),
            const SizedBox(width: 12),
            _buildMetricCard(context, title: 'Savings', amount: savings, icon: Icons.savings_rounded, iconColor: Colors.teal, bgColor: Colors.teal.withValues(alpha: 0.08), onTap: () => Navigator.pushNamed(context, AppRoutes.savings), flex: 1),
          ],
        ),
      );
    }
    return Container(
      height: 95,
      margin: const EdgeInsets.symmetric(vertical: 4),
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        children: [
          _buildMetricCard(
            context,
            title: 'Net Balance',
            amount: balance,
            icon: Icons.account_balance_wallet_rounded,
            iconColor: Colors.blueAccent,
            bgColor: Colors.blueAccent.withValues(alpha: 0.08),
            onTap: () => Navigator.pushNamed(context, AppRoutes.accounts),
          ),
          _buildMetricCard(
            context,
            title: 'Income',
            amount: income,
            icon: Icons.south_west_rounded,
            iconColor: Colors.green,
            bgColor: Colors.green.withValues(alpha: 0.08),
            onTap: () => Navigator.pushNamed(context, AppRoutes.income),
          ),
          _buildMetricCard(
            context,
            title: 'Expenses',
            amount: expenses,
            icon: Icons.north_east_rounded,
            iconColor: Colors.redAccent,
            bgColor: Colors.redAccent.withValues(alpha: 0.08),
            onTap: () => Navigator.pushNamed(context, AppRoutes.allExpenses),
          ),
          _buildMetricCard(
            context,
            title: 'Savings',
            amount: savings,
            icon: Icons.savings_rounded,
            iconColor: Colors.teal,
            bgColor: Colors.teal.withValues(alpha: 0.08),
            onTap: () => Navigator.pushNamed(context, AppRoutes.savings),
          ),
        ],
      ),
    );
  }

  Widget _buildMetricCard(
    BuildContext context, {
    required String title,
    required double amount,
    required IconData icon,
    required Color iconColor,
    required Color bgColor,
    required VoidCallback onTap,
    int flex = 0,
  }) {
    final card = Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(18),
        side: BorderSide(color: Theme.of(context).dividerColor.withValues(alpha: 0.06)),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(18),
        child: Padding(
          padding: const EdgeInsets.all(10),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Text(
                      title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6),
                      ),
                    ),
                  ),
                  const SizedBox(width: 4),
                  Container(
                    padding: const EdgeInsets.all(4),
                    decoration: BoxDecoration(
                      color: bgColor,
                      shape: BoxShape.circle,
                    ),
                    child: Icon(icon, color: iconColor, size: 14),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              Text(
                '$currencySymbol${amount.toStringAsFixed(0)}',
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.bold,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ),
    );
    // Tablet row: use Expanded; mobile scroll: fixed width container
    if (flex > 0) {
      return Expanded(child: SizedBox(height: 85, child: card));
    }
    return Container(
      width: 145,
      margin: const EdgeInsets.only(right: 10),
      child: card,
    );
  }

  Widget _buildSmartInsightsCarousel(BuildContext context, HealthReport report) {
    if (report.improvements.isEmpty) return const SizedBox.shrink();
    return Container(
      height: 72,
      margin: const EdgeInsets.only(top: 8, bottom: 8),
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: report.improvements.length,
        itemBuilder: (ctx, idx) {
          return Container(
            width: 290,
            margin: const EdgeInsets.only(right: 12),
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.05),
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.12)),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(Icons.auto_awesome, color: Theme.of(context).colorScheme.primary, size: 18),
                ),
                const SizedBox(width: 10),
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
    final statusColor = report.score >= 80
        ? Colors.green
        : (report.score >= 50 ? Colors.orange : Colors.redAccent);
    final statusLabel = report.score >= 80
        ? 'Optimal'
        : (report.score >= 50 ? 'Stable' : 'Needs Action');

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(22),
        side: BorderSide(color: Theme.of(context).dividerColor.withValues(alpha: 0.08)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Row(
          children: [
            Stack(
              alignment: Alignment.center,
              children: [
                SizedBox(
                  width: 64,
                  height: 64,
                  child: CircularProgressIndicator(
                    value: report.score / 100,
                    strokeWidth: 7,
                    backgroundColor: Theme.of(context).dividerColor.withValues(alpha: 0.1),
                    valueColor: AlwaysStoppedAnimation<Color>(statusColor),
                  ),
                ),
                Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      '${report.score}',
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 17),
                    ),
                    const Text(
                      '/100',
                      style: TextStyle(fontSize: 9, color: Colors.grey),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(width: 18),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Text(
                        'FINANCIAL HEALTH',
                        style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, letterSpacing: 1.1, color: Colors.grey),
                      ),
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                        decoration: BoxDecoration(
                          color: statusColor.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          statusLabel,
                          style: TextStyle(fontSize: 9, fontWeight: FontWeight.bold, color: statusColor),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Text(
                    report.feedback.firstOrNull ?? 'Keep tracking obligations and savings targets.',
                    style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, height: 1.2),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSuperMoneyCard(BuildContext context) {
    return const SecuredCreditCardBanner();
  }

  Widget _buildRecentFeed(BuildContext context, ExpenseViewModel expenseVM, IncomeViewModel incomeVM) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    // Merge latest 3 expenses and 3 incomes
    final latestExpenses = expenseVM.expenses.take(3).toList();
    final latestIncomes = incomeVM.incomes.take(3).toList();

    final feedItems = <Map<String, dynamic>>[];
    for (var e in latestExpenses) {
      feedItems.add({
        'title': e.description.isEmpty ? 'Expense' : e.description,
        'amount': e.amount,
        'isCredit': false,
        'date': e.date,
        'category': e.categoryId.isNotEmpty ? e.categoryId : 'Expense',
      });
    }
    for (var i in latestIncomes) {
      feedItems.add({
        'title': i.source,
        'amount': i.amount,
        'isCredit': true,
        'date': i.date,
        'category': i.source,
      });
    }

    feedItems.sort((a, b) => (b['date'] as DateTime).compareTo(a['date'] as DateTime));
    final displayItems = feedItems.take(5).toList();

    final r = Responsive(context);
    final cardBg = isDark ? const Color(0xFF1E293B) : Colors.white;
    final borderColor = isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0);
    final textPrimary = isDark ? Colors.white : const Color(0xFF0F172A);
    final textSecondary = isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B);

    return Padding(
      padding: EdgeInsets.symmetric(horizontal: r.horizontalPadding, vertical: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Header Row with Activity Pulse Dot
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Container(
                    width: 7,
                    height: 7,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: const Color(0xFF10B981),
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFF10B981).withValues(alpha: 0.5),
                          blurRadius: 6,
                          spreadRadius: 1,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'RECENT LOGS FEED',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 1.1,
                      color: textSecondary,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text(
                      '${displayItems.length} Recent',
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
                        color: textPrimary,
                      ),
                    ),
                  ),
                ],
              ),
              GestureDetector(
                onTap: () => Navigator.pushNamed(context, AppRoutes.allExpenses),
                child: Row(
                  children: [
                    Text(
                      'See All',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: Theme.of(context).colorScheme.primary,
                      ),
                    ),
                    const SizedBox(width: 4),
                    Icon(
                      Icons.arrow_forward_rounded,
                      size: 14,
                      color: Theme.of(context).colorScheme.primary,
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          if (displayItems.isEmpty)
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: cardBg,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: borderColor),
              ),
              child: Text(
                'No transactions recorded yet.',
                textAlign: TextAlign.center,
                style: TextStyle(color: textSecondary, fontSize: 13),
              ),
            )
          else
            ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: displayItems.length,
              separatorBuilder: (_, __) => const SizedBox(height: 10),
              itemBuilder: (ctx, idx) {
                final item = displayItems[idx];
                final isCredit = item['isCredit'] as bool;
                final title = item['title'] as String;
                final date = item['date'] as DateTime;
                final amount = item['amount'] as double;
                final icon = _getLogIcon(title, isCredit);
                final accentColors = isCredit
                    ? const [Color(0xFF10B981), Color(0xFF059669)]
                    : const [Color(0xFFEF4444), Color(0xFFDC2626)];

                return Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: cardBg,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: borderColor, width: 1.2),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.04),
                        blurRadius: 8,
                        offset: const Offset(0, 3),
                      ),
                    ],
                  ),
                  child: Row(
                    children: [
                      // Gradient Category Icon Container
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [
                              accentColors.first.withValues(alpha: 0.15),
                              accentColors.last.withValues(alpha: 0.05),
                            ],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(
                            color: accentColors.first.withValues(alpha: 0.25),
                          ),
                        ),
                        child: Icon(
                          icon,
                          color: accentColors.first,
                          size: 20,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              title,
                              style: TextStyle(
                                fontWeight: FontWeight.w800,
                                fontSize: 14,
                                color: textPrimary,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: 2),
                            Row(
                              children: [
                                Text(
                                  DateFormat('dd MMM, yyyy').format(date),
                                  style: TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w500,
                                    color: textSecondary,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                        decoration: BoxDecoration(
                          color: accentColors.first.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Text(
                          '${isCredit ? '+' : '-'}${CurrencyFormatter.format(amount)}',
                          style: TextStyle(
                            fontWeight: FontWeight.w900,
                            fontSize: 14,
                            color: accentColors.first,
                          ),
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

  IconData _getLogIcon(String title, bool isCredit) {
    final lower = title.toLowerCase();
    if (isCredit) {
      if (lower.contains('salary') || lower.contains('pay') || lower.contains('job')) {
        return Icons.work_rounded;
      } else if (lower.contains('free') || lower.contains('gig')) {
        return Icons.laptop_mac_rounded;
      } else if (lower.contains('gift') || lower.contains('bonus')) {
        return Icons.card_giftcard_rounded;
      } else if (lower.contains('refund') || lower.contains('return')) {
        return Icons.replay_rounded;
      } else if (lower.contains('invest') || lower.contains('div')) {
        return Icons.trending_up_rounded;
      }
      return Icons.south_west_rounded;
    } else {
      if (lower.contains('food') || lower.contains('eat') || lower.contains('dine') || lower.contains('rest')) {
        return Icons.restaurant_rounded;
      } else if (lower.contains('shop') || lower.contains('buy') || lower.contains('cloth')) {
        return Icons.shopping_bag_rounded;
      } else if (lower.contains('cab') || lower.contains('auto') || lower.contains('fuel') || lower.contains('uber')) {
        return Icons.directions_car_rounded;
      } else if (lower.contains('bill') || lower.contains('elect') || lower.contains('recharge')) {
        return Icons.bolt_rounded;
      } else if (lower.contains('med') || lower.contains('health') || lower.contains('doctor')) {
        return Icons.medical_services_rounded;
      } else if (lower.contains('movie') || lower.contains('fun') || lower.contains('game')) {
        return Icons.movie_rounded;
      }
      return Icons.arrow_outward_rounded;
    }
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

  Widget _buildFloatingGlassmorphicDock(BuildContext context) {
    final theme = Theme.of(context);
    final isDarkMode = theme.brightness == Brightness.dark;
    
    final dockBgColor = isDarkMode 
        ? const Color(0xFF1E293B).withValues(alpha: 0.85) 
        : Colors.white.withValues(alpha: 0.85);
    final dockBorderColor = isDarkMode 
        ? const Color(0xFF334155).withValues(alpha: 0.5) 
        : const Color(0xFFE2E8F0).withValues(alpha: 0.5);
    final iconColor = isDarkMode ? Colors.white70 : const Color(0xFF475569);

    return Container(
      width: 320,
      height: 64,
      decoration: BoxDecoration(
        color: dockBgColor,
        borderRadius: BorderRadius.circular(32),
        border: Border.all(color: dockBorderColor, width: 1.5),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDarkMode ? 0.4 : 0.08),
            blurRadius: 24,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          // Button 1: Analytics
          _buildDockButton(
            context,
            icon: Icons.insights_rounded,
            label: 'Analytics',
            color: iconColor,
            onTap: () => Navigator.pushNamed(context, AppRoutes.analytics),
          ),
          
          // Center Button: Quick Add (Trigger sheet)
          GestureDetector(
            onTap: () => _showQuickAddSheet(context),
            child: Container(
              width: 50,
              height: 50,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    theme.colorScheme.primary,
                    theme.colorScheme.secondary,
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: theme.colorScheme.primary.withValues(alpha: 0.4),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: const Icon(
                Icons.add_rounded,
                color: Colors.white,
                size: 28,
              ),
            ),
          ),

          // Button 3: Settings
          _buildDockButton(
            context,
            icon: Icons.settings_rounded,
            label: 'Settings',
            color: iconColor,
            onTap: () => Navigator.pushNamed(context, AppRoutes.setting),
          ),
        ],
      ),
    );
  }

  Widget _buildDockButton(
    BuildContext context, {
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: color, size: 22),
            const SizedBox(height: 2),
            Text(
              label,
              style: TextStyle(
                fontSize: 9,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
          ],
        ),
      ),
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

class SecuredCreditCardBanner extends StatefulWidget {
  const SecuredCreditCardBanner({super.key});

  @override
  State<SecuredCreditCardBanner> createState() => _SecuredCreditCardBannerState();
}

class _SecuredCreditCardBannerState extends State<SecuredCreditCardBanner> {
  bool _isExpanded = false;

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    final cardGradient = isDarkMode
        ? const LinearGradient(
            colors: [Color(0xFF0F172A), Color(0xFF1E293B), Color(0xFF020617)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          )
        : const LinearGradient(
            colors: [Color(0xFFFFFFFF), Color(0xFFF8FAFC), Color(0xFFE2E8F0)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          );

    final titleColor = isDarkMode ? Colors.white : const Color(0xFF0F172A);
    final subTextColor = isDarkMode ? Colors.white60 : const Color(0xFF475569);
    final shadowColor = isDarkMode ? Colors.black.withValues(alpha: 0.45) : Colors.black.withValues(alpha: 0.08);
    final borderColor = isDarkMode
        ? Colors.amberAccent.withValues(alpha: 0.25)
        : const Color(0xFFD97706).withValues(alpha: 0.35);

    return BlocBuilder<CreditCardBloc, CreditCardState>(
      builder: (context, state) {
        if (state is CreditCardLoadedState) {
          final account = state.account;
          final utilization = account.creditLimit > 0
              ? (account.usedCredit / account.creditLimit).clamp(0.0, 1.0)
              : 0.0;

          return Container(
            margin: EdgeInsets.symmetric(horizontal: Responsive(context).horizontalPadding, vertical: 8),
            decoration: BoxDecoration(
              gradient: cardGradient,
              borderRadius: BorderRadius.circular(28),
              boxShadow: [
                BoxShadow(
                  color: shadowColor,
                  blurRadius: 20,
                  offset: const Offset(0, 10),
                ),
              ],
              border: Border.all(
                color: borderColor,
                width: 1.2,
              ),
            ),
            child: InkWell(
              onTap: () {
                setState(() {
                  _isExpanded = !_isExpanded;
                });
              },
              borderRadius: BorderRadius.circular(28),
              child: Padding(
                padding: const EdgeInsets.all(22),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(6),
                              decoration: BoxDecoration(
                                gradient: const LinearGradient(
                                  colors: [Color(0xFFF59E0B), Color(0xFFD97706)],
                                ),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: const Icon(Icons.credit_card_rounded, color: Colors.white, size: 16),
                            ),
                            const SizedBox(width: 10),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'CREDIT CARD SECURED',
                                  style: TextStyle(
                                    color: titleColor,
                                    fontSize: 13,
                                    fontWeight: FontWeight.w800,
                                    letterSpacing: 0.8,
                                  ),
                                ),
                                Text(
                                  'FD BACKED • 6.0% DAILY INTEREST',
                                  style: TextStyle(
                                    color: const Color(0xFFD97706),
                                    fontSize: 9,
                                    fontWeight: FontWeight.bold,
                                    letterSpacing: 0.6,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                        Row(
                          children: [
                            Icon(Icons.contactless_rounded, color: subTextColor, size: 20),
                            const SizedBox(width: 8),
                            Icon(
                              _isExpanded
                                  ? Icons.keyboard_arrow_up_rounded
                                  : Icons.keyboard_arrow_down_rounded,
                              color: titleColor,
                              size: 24,
                            ),
                          ],
                        ),
                      ],
                    ),
                    
                    if (!_isExpanded) ...[
                      const SizedBox(height: 12),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'Used: $currencySymbol${account.usedCredit.toStringAsFixed(0)} / $currencySymbol${account.creditLimit.toStringAsFixed(0)}',
                            style: TextStyle(color: subTextColor, fontSize: 11, fontWeight: FontWeight.bold),
                          ),
                          Text(
                            'Available: $currencySymbol${account.availableCredit.toStringAsFixed(0)}',
                            style: TextStyle(
                              color: utilization > 0.8 ? Colors.redAccent : const Color(0xFFD97706),
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ],

                    if (_isExpanded) ...[
                      const SizedBox(height: 20),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('Available Credit', style: TextStyle(color: subTextColor, fontSize: 11, fontWeight: FontWeight.w500)),
                              const SizedBox(height: 4),
                              Text(
                                '$currencySymbol${account.availableCredit.toStringAsFixed(0)}',
                                style: TextStyle(color: titleColor, fontSize: 28, fontWeight: FontWeight.w900),
                              ),
                            ],
                          ),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              Text('Used Credit', style: TextStyle(color: subTextColor, fontSize: 11, fontWeight: FontWeight.w500)),
                              const SizedBox(height: 4),
                              Text(
                                '$currencySymbol${account.usedCredit.toStringAsFixed(0)}',
                                style: TextStyle(
                                  color: utilization > 0.8 ? Colors.redAccent : (isDarkMode ? Colors.white70 : const Color(0xFF334155)),
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(6),
                        child: LinearProgressIndicator(
                          value: utilization,
                          minHeight: 6,
                          backgroundColor: isDarkMode ? Colors.white12 : Colors.black.withValues(alpha: 0.08),
                          valueColor: AlwaysStoppedAnimation<Color>(
                            utilization > 0.8 ? Colors.redAccent : const Color(0xFFD97706),
                          ),
                        ),
                      ),
                      const SizedBox(height: 18),
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: () => Navigator.pushNamed(context, AppRoutes.creditCardDashboard),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: isDarkMode ? const Color(0xFFF59E0B) : const Color(0xFF0F172A),
                            foregroundColor: isDarkMode ? Colors.black : Colors.white,
                            elevation: 0,
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text('Manage Credit Card & FDs', style: TextStyle(fontWeight: FontWeight.w900, fontSize: 13, color: isDarkMode ? Colors.black : Colors.white)),
                              const SizedBox(width: 8),
                              Icon(Icons.arrow_forward_rounded, size: 16, color: isDarkMode ? Colors.black : Colors.white),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          );
        }
        return const SizedBox.shrink();
      },
    );
  }
}

class FinancialUtilitiesSection extends StatefulWidget {
  const FinancialUtilitiesSection({super.key});

  @override
  State<FinancialUtilitiesSection> createState() => _FinancialUtilitiesSectionState();
}

class _FinancialUtilitiesSectionState extends State<FinancialUtilitiesSection> {
  bool _isExpanded = false;

  @override
  Widget build(BuildContext context) {
    final r = Responsive(context);
    final columns = r.isTabletOrDesktop ? 6 : 4;

    // Main features (always visible)
    final mainTiles = [
      _FeatureTileData(Icons.account_balance_wallet_outlined, 'Accounts', AppRoutes.accounts, Colors.blue),
      _FeatureTileData(Icons.arrow_circle_down_rounded, 'Incomes', AppRoutes.income, Colors.green),
      _FeatureTileData(Icons.arrow_circle_up_rounded, 'Expenses', AppRoutes.allExpenses, Colors.redAccent),
      _FeatureTileData(Icons.punch_clock_rounded, 'EMI Tracker', AppRoutes.emiCalculator, Colors.indigo),
      _FeatureTileData(Icons.pie_chart_outline_rounded, 'Budgets', AppRoutes.budget, Colors.amber),
      _FeatureTileData(Icons.handshake_rounded, 'Debt Logs', AppRoutes.borrowLend, Colors.orange),
      _FeatureTileData(Icons.flag_rounded, 'Goals', AppRoutes.goals, Colors.teal),
    ];

    // Extra features (visible when expanded)
    final extraTiles = [
      _FeatureTileData(Icons.credit_card_rounded, 'Credit Card', AppRoutes.creditCardDashboard, Colors.indigoAccent),
      _FeatureTileData(Icons.savings_outlined, 'Savings', AppRoutes.savings, Colors.teal),
      _FeatureTileData(Icons.insights_rounded, 'Analytics', AppRoutes.analytics, Colors.purple),
      _FeatureTileData(Icons.directions_car_rounded, 'Mileage', AppRoutes.mileage, Colors.blueGrey),
      _FeatureTileData(Icons.trending_up_rounded, 'Investments', AppRoutes.investments, Colors.cyan),
      _FeatureTileData(Icons.restaurant_rounded, 'Diet', AppRoutes.dietDashboard, Colors.lightGreen),
    ];

    final visibleTiles = <Widget>[];

    // Add main tiles
    for (final tile in mainTiles) {
      visibleTiles.add(_buildFeatureTile(context, tile.icon, tile.title, tile.route, tile.color));
    }

    if (_isExpanded) {
      // Add extra tiles when expanded
      for (final tile in extraTiles) {
        visibleTiles.add(_buildFeatureTile(context, tile.icon, tile.title, tile.route, tile.color));
      }
      // Add "Less" tile
      visibleTiles.add(
        _buildActionTile(
          context,
          Icons.keyboard_arrow_up_rounded,
          'Show Less',
          Colors.grey,
          () => setState(() => _isExpanded = false),
        ),
      );
    } else {
      // Add "More" tile
      visibleTiles.add(
        _buildActionTile(
          context,
          Icons.grid_view_rounded,
          'View All',
          Colors.grey,
          () => setState(() => _isExpanded = true),
        ),
      );
    }

    return Padding(
      padding: EdgeInsets.symmetric(horizontal: r.horizontalPadding, vertical: 12),
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
            crossAxisCount: columns,
            mainAxisSpacing: 16,
            crossAxisSpacing: 16,
            children: visibleTiles,
          ),
        ],
      ),
    );
  }

  Widget _buildFeatureTile(BuildContext context, IconData icon, String label, String route, Color accentColor) {
    return InkWell(
      onTap: () => Navigator.pushNamed(context, route),
      borderRadius: BorderRadius.circular(18),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(13),
            decoration: BoxDecoration(
              color: accentColor.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: accentColor, size: 22),
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

  Widget _buildActionTile(BuildContext context, IconData icon, String label, Color accentColor, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(18),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(13),
            decoration: BoxDecoration(
              color: accentColor.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: accentColor, size: 22),
          ),
          const SizedBox(height: 6),
          Text(
            label,
            style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.blueAccent),
            textAlign: TextAlign.center,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }
}

class _FeatureTileData {
  final IconData icon;
  final String title;
  final String route;
  final Color color;

  const _FeatureTileData(this.icon, this.title, this.route, this.color);
}
