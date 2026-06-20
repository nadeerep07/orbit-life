import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/utils/currency_formatter.dart';
import '../../domain/entities/income_entity.dart';
import '../viewmodels/income_view_model.dart';
import '../viewmodels/settings_view_model.dart';
import '../viewmodels/emi_tracker_view_model.dart';
import '../viewmodels/borrow_lend_view_model.dart';
import '../viewmodels/savings_view_model.dart';
import '../viewmodels/accounts_view_model.dart';
import '../../core/services/obligation_analysis_engine.dart';
import '../../core/services/savings_recommendation_engine.dart';
import '../../core/services/debt_optimization_engine.dart';
import '../../core/services/spendable_wallet_engine.dart';
import '../../core/services/daily_spending_engine.dart';

class AllocationPreviewScreen extends StatefulWidget {
  final IncomeEntity income;

  const AllocationPreviewScreen({super.key, required this.income});

  @override
  State<AllocationPreviewScreen> createState() => _AllocationPreviewScreenState();
}

class _AllocationPreviewScreenState extends State<AllocationPreviewScreen> {
  double _savingsAlloc = 0.0;
  double _debtAlloc = 0.0;
  bool _initialized = false;

  @override
  Widget build(BuildContext context) {
    final settingsVM = context.watch<SettingsViewModel>();
    final emiVM = context.watch<EmiTrackerViewModel>();
    final blVM = context.watch<BorrowLendViewModel>();
    final savingsVM = context.watch<SavingsViewModel>();
    final accountsVM = context.watch<AccountsViewModel>();
    final settings = settingsVM.settings;

    // 1. Calculate dynamic recommendations
    final obligationsAnalysis = ObligationAnalysisEngine.analyze(
      emis: emiVM.emis,
      settings: settings,
    );

    double outstandingDebt = blVM.entries
        .where((bl) => bl.type == 'borrowed' && bl.status == 'pending')
        .fold(0.0, (sum, bl) => sum + bl.remainingAmount);

    final savingsRec = SavingsRecommendationEngine.calculate(
      incomeAmount: widget.income.amount,
      totalObligations: obligationsAnalysis.totalObligations,
      outstandingDebt: outstandingDebt,
      currentSavings: savingsVM.savings?.currentBalance ?? 0.0,
      settings: settings,
    );

    final accountBalances = {for (var a in accountsVM.accounts) a.id: a.openingBalance};
    final debtRec = DebtOptimizationEngine.calculate(
      borrowLends: blVM.entries,
      accounts: accountsVM.accounts,
      accountBalances: accountBalances,
      incomeAmount: widget.income.amount,
      totalObligations: obligationsAnalysis.totalObligations,
    );

    // Initialize allocations on first render
    if (!_initialized) {
      // Default recommended targets matching selected operating strategy
      if (settings.financialMode == 'survival') {
        _savingsAlloc = savingsRec.minimum;
        _debtAlloc = debtRec.minimumPayment;
      } else if (settings.financialMode == 'recovery') {
        _savingsAlloc = savingsRec.minimum;
        _debtAlloc = debtRec.recommendedPayment;
      } else if (settings.financialMode == 'growth') {
        _savingsAlloc = savingsRec.recommended;
        _debtAlloc = debtRec.minimumPayment;
      } else {
        _savingsAlloc = savingsRec.recommended;
        _debtAlloc = debtRec.recommendedPayment;
      }
      _initialized = true;
    }

    // 2. Spendable Wallet calculation
    final spendableWallet = SpendableWalletEngine.calculate(
      incomeAmount: widget.income.amount,
      totalObligations: obligationsAnalysis.totalObligations,
      savingsAllocation: _savingsAlloc,
      debtAllocation: _debtAlloc,
    );

    // 3. Daily Spending limit math
    final dailySpendingReport = DailySpendingEngine.calculate(
      spendableWalletAmount: spendableWallet.totalSpendableAmount,
      currentMonthSpent: 0.0, // preview assumes fresh start
      currentTotalBalance: accountsVM.totalBalance,
      currentDate: DateTime.now(),
    );

    // Bounds for slider inputs
    final maxSavings = widget.income.amount - obligationsAnalysis.totalObligations - _debtAlloc;
    final maxDebt = widget.income.amount - obligationsAnalysis.totalObligations - _savingsAlloc;

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        title: const Text('Allocation Preview', style: TextStyle(fontWeight: FontWeight.bold)),
        elevation: 0,
        backgroundColor: Colors.transparent,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Income Summary header
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.primary.withOpacity(0.08),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Column(
                children: [
                  const Text('INCOMING INCOME TO ALLOCATE', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.grey)),
                  const SizedBox(height: 6),
                  Text(
                    '$currencySymbol${widget.income.amount.toStringAsFixed(0)}',
                    style: TextStyle(fontSize: 32, fontWeight: FontWeight.bold, color: Theme.of(context).colorScheme.primary),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // Detected Mandatory Obligations
            Card(
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
                side: BorderSide(color: Theme.of(context).dividerColor.withOpacity(0.06)),
              ),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('Mandatory Obligations', style: TextStyle(fontWeight: FontWeight.bold)),
                        Text(
                          '$currencySymbol${obligationsAnalysis.totalObligations.toStringAsFixed(0)}',
                          style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.redAccent),
                        ),
                      ],
                    ),
                    if (obligationsAnalysis.obligations.isNotEmpty) ...[
                      const SizedBox(height: 12),
                      const Divider(),
                      const SizedBox(height: 8),
                      ListView.builder(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: obligationsAnalysis.obligations.length,
                        itemBuilder: (ctx, idx) {
                          final item = obligationsAnalysis.obligations[idx];
                          return Padding(
                            padding: const EdgeInsets.symmetric(vertical: 4),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text('${item.title} (${item.type})', style: const TextStyle(fontSize: 12, color: Colors.grey)),
                                Text('$currencySymbol${item.amount.toStringAsFixed(0)}', style: const TextStyle(fontSize: 12, color: Colors.grey)),
                              ],
                            ),
                          );
                        },
                      ),
                    ],
                  ],
                ),
              ),
            ),
            const SizedBox(height: 12),

            // Dynamic Savings allocation slider
            _buildAllocationSlider(
              context,
              title: 'Savings Pool Contribution',
              value: _savingsAlloc,
              maxVal: maxSavings > 0 ? maxSavings : 100.0,
              recommendMin: savingsRec.minimum,
              recommendTarget: savingsRec.recommended,
              onChanged: (val) => setState(() => _savingsAlloc = val),
            ),
            const SizedBox(height: 12),

            // Dynamic Debt paydown slider
            _buildAllocationSlider(
              context,
              title: 'Debt Reduction Repayment',
              value: _debtAlloc,
              maxVal: maxDebt > 0 ? maxDebt : 100.0,
              recommendMin: debtRec.minimumPayment,
              recommendTarget: debtRec.recommendedPayment,
              onChanged: (val) => setState(() => _debtAlloc = val),
            ),
            const SizedBox(height: 20),

            // Dynamic Results Card
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Theme.of(context).cardColor,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: Theme.of(context).dividerColor.withOpacity(0.08)),
              ),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('Disposable Spendable Wallet', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                      Text(
                        '$currencySymbol${spendableWallet.totalSpendableAmount.toStringAsFixed(0)}',
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  const Divider(),
                  const SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('Safe Daily Spending Limit', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                      Text(
                        '$currencySymbol${dailySpendingReport.dailyLimit.toStringAsFixed(0)}/day',
                        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Theme.of(context).colorScheme.primary),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 32),

            // Confirm Allocation CTA
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              ),
              onPressed: () => _confirmAllocation(context, blVM, savingsVM),
              child: const Text('Confirm & Distribute Funds', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAllocationSlider(
    BuildContext context, {
    required String title,
    required double value,
    required double maxVal,
    required double recommendMin,
    required double recommendTarget,
    required ValueChanged<double> onChanged,
  }) {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: Theme.of(context).dividerColor.withOpacity(0.06)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(title, style: const TextStyle(fontWeight: FontWeight.w600)),
                Text(
                  '$currencySymbol${value.toStringAsFixed(0)}',
                  style: TextStyle(fontWeight: FontWeight.bold, color: Theme.of(context).colorScheme.primary),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Slider(
              value: value.clamp(0.0, maxVal),
              min: 0.0,
              max: maxVal,
              activeColor: Theme.of(context).colorScheme.primary,
              onChanged: onChanged,
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('Min Rec: $currencySymbol${recommendMin.toStringAsFixed(0)}', style: const TextStyle(fontSize: 11, color: Colors.grey)),
                Text('Target Rec: $currencySymbol${recommendTarget.toStringAsFixed(0)}', style: const TextStyle(fontSize: 11, color: Colors.grey)),
              ],
            ),
          ],
        ),
      ),
    );
  }

  void _confirmAllocation(
    BuildContext context,
    BorrowLendViewModel blVM,
    SavingsViewModel savingsVM,
  ) async {
    // 1. Add primary Income record
    await context.read<IncomeViewModel>().addIncome(widget.income);

    // 2. Perform Savings auto-transfer if allocation specified
    if (_savingsAlloc > 0.0) {
      await savingsVM.addToSavings(_savingsAlloc, widget.income.accountId);
    }

    // 3. Perform Debt payoff if allocation specified
    if (_debtAlloc > 0.0) {
      // Find first pending borrowed debt to apply the payment
      final firstPending = blVM.entries
          .where((bl) => bl.type == 'borrowed' && bl.status == 'pending')
          .firstOrNull;

      if (firstPending != null) {
        await blVM.addTransactionToEntry(
          entry: firstPending,
          amountToPay: _debtAlloc,
          accountIdToUpdate: widget.income.accountId,
          date: DateTime.now(),
        );
      }
    }

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Salary allocation completed & logged successfully.'),
          backgroundColor: Colors.green,
        ),
      );
      Navigator.pop(context); // close preview
    }
  }
}
