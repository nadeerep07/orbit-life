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
import '../widgets/custom_snackbar.dart';

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

            // Dynamic Savings allocation card with precision controls
            _AllocationControlCard(
              title: 'Savings Pool Contribution',
              value: _savingsAlloc,
              maxVal: maxSavings > 0 ? maxSavings : 100.0,
              recommendMin: savingsRec.minimum,
              recommendTarget: savingsRec.recommended,
              onChanged: (val) => setState(() => _savingsAlloc = val),
            ),
            const SizedBox(height: 16),

            // Dynamic Debt paydown card with precision controls
            _AllocationControlCard(
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
      AppSnackBar.show(
        context,
        message: 'Salary allocation completed & logged successfully.',
        isError: false,
      );
      Navigator.pop(context); // close preview
    }
  }
}

class _AllocationControlCard extends StatefulWidget {
  final String title;
  final double value;
  final double maxVal;
  final double recommendMin;
  final double recommendTarget;
  final ValueChanged<double> onChanged;

  const _AllocationControlCard({
    required this.title,
    required this.value,
    required this.maxVal,
    required this.recommendMin,
    required this.recommendTarget,
    required this.onChanged,
  });

  @override
  State<_AllocationControlCard> createState() => _AllocationControlCardState();
}

class _AllocationControlCardState extends State<_AllocationControlCard> {
  late TextEditingController _textController;

  @override
  void initState() {
    super.initState();
    _textController = TextEditingController(text: widget.value.toStringAsFixed(0));
  }

  @override
  void didUpdateWidget(covariant _AllocationControlCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.value != widget.value) {
      final textVal = double.tryParse(_textController.text) ?? 0.0;
      if ((textVal - widget.value).abs() > 0.99) {
        _textController.text = widget.value.toStringAsFixed(0);
      }
    }
  }

  @override
  void dispose() {
    _textController.dispose();
    super.dispose();
  }

  void _updateAmount(double newVal) {
    final clamped = newVal.clamp(0.0, widget.maxVal);
    _textController.text = clamped.toStringAsFixed(0);
    widget.onChanged(clamped);
  }

  @override
  Widget build(BuildContext context) {
    final primaryColor = Theme.of(context).colorScheme.primary;
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: Theme.of(context).dividerColor.withValues(alpha: 0.08)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header title & Exact Numeric TextField
            Row(
              children: [
                Expanded(
                  child: Text(
                    widget.title,
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                  ),
                ),
                Container(
                  width: 110,
                  height: 38,
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                  decoration: BoxDecoration(
                    color: primaryColor.withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: primaryColor.withValues(alpha: 0.2)),
                  ),
                  child: Row(
                    children: [
                      Text(
                        currencySymbol,
                        style: TextStyle(fontWeight: FontWeight.bold, color: primaryColor),
                      ),
                      const SizedBox(width: 4),
                      Expanded(
                        child: TextField(
                          controller: _textController,
                          keyboardType: const TextInputType.numberWithOptions(decimal: true),
                          style: TextStyle(fontWeight: FontWeight.bold, color: primaryColor, fontSize: 14),
                          decoration: const InputDecoration(
                            isDense: true,
                            border: InputBorder.none,
                            contentPadding: EdgeInsets.zero,
                          ),
                          onChanged: (val) {
                            final parsed = double.tryParse(val);
                            if (parsed != null) {
                              widget.onChanged(parsed.clamp(0.0, widget.maxVal));
                            }
                          },
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),

            // Continuous Slider
            Slider(
              value: widget.value.clamp(0.0, widget.maxVal),
              min: 0.0,
              max: widget.maxVal > 0 ? widget.maxVal : 100.0,
              activeColor: primaryColor,
              onChanged: (val) => _updateAmount(val),
            ),

            // Step adjustment buttons (-$100, -$50, -$10, +$10, +$50, +$100)
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  _buildStepBtn(context, '-100', () => _updateAmount(widget.value - 100)),
                  _buildStepBtn(context, '-50', () => _updateAmount(widget.value - 50)),
                  _buildStepBtn(context, '-10', () => _updateAmount(widget.value - 10)),
                  const SizedBox(width: 12),
                  _buildStepBtn(context, '+10', () => _updateAmount(widget.value + 10)),
                  _buildStepBtn(context, '+50', () => _updateAmount(widget.value + 50)),
                  _buildStepBtn(context, '+100', () => _updateAmount(widget.value + 100)),
                ],
              ),
            ),
            const SizedBox(height: 12),

            // Preset Recommendation Chips
            Wrap(
              spacing: 6,
              runSpacing: 6,
              children: [
                _buildPresetChip(
                  context,
                  label: 'Min Rec: $currencySymbol${widget.recommendMin.toStringAsFixed(0)}',
                  isSelected: (widget.value - widget.recommendMin).abs() < 1,
                  onTap: () => _updateAmount(widget.recommendMin),
                ),
                _buildPresetChip(
                  context,
                  label: 'Target Rec: $currencySymbol${widget.recommendTarget.toStringAsFixed(0)}',
                  isSelected: (widget.value - widget.recommendTarget).abs() < 1,
                  onTap: () => _updateAmount(widget.recommendTarget),
                ),
                _buildPresetChip(
                  context,
                  label: '50%',
                  isSelected: (widget.value - (widget.maxVal * 0.5)).abs() < 1,
                  onTap: () => _updateAmount(widget.maxVal * 0.5),
                ),
                _buildPresetChip(
                  context,
                  label: 'Max',
                  isSelected: (widget.value - widget.maxVal).abs() < 1,
                  onTap: () => _updateAmount(widget.maxVal),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStepBtn(BuildContext context, String label, VoidCallback onTap) {
    return Padding(
      padding: const EdgeInsets.only(right: 4),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(6),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(
            color: Theme.of(context).dividerColor.withValues(alpha: 0.06),
            borderRadius: BorderRadius.circular(6),
            border: Border.all(color: Theme.of(context).dividerColor.withValues(alpha: 0.1)),
          ),
          child: Text(
            label,
            style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold),
          ),
        ),
      ),
    );
  }

  Widget _buildPresetChip(
    BuildContext context, {
    required String label,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    final primaryColor = Theme.of(context).colorScheme.primary;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        decoration: BoxDecoration(
          color: isSelected ? primaryColor : primaryColor.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected ? primaryColor : primaryColor.withValues(alpha: 0.15),
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.bold,
            color: isSelected ? Colors.white : primaryColor,
          ),
        ),
      ),
    );
  }
}
