import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../viewmodels/savings_view_model.dart';
import '../viewmodels/expense_view_model.dart';
import '../viewmodels/accounts_view_model.dart';
import '../../core/utils/currency_formatter.dart';
import '../widgets/custom_snackbar.dart';

class SavingsScreen extends StatelessWidget {
  const SavingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final savingsVM = context.watch<SavingsViewModel>();
    final expenseVM = context.watch<ExpenseViewModel>();
    final theme = Theme.of(context);
    final isDarkMode = theme.brightness == Brightness.dark;

    final savings = savingsVM.savings;
    final currentBalance = savings?.currentBalance ?? 0.0;
    final totalAdded = savings?.totalAdded ?? 0.0;
    final totalDebited = savings?.totalDebited ?? 0.0;

    final savingsExpenses = expenseVM.expenses.where((e) => e.isFromSavings).toList();
    savingsExpenses.sort((a, b) => b.date.compareTo(a.date));

    final cardBgColor = isDarkMode ? const Color(0xFF1E293B) : Colors.white;
    final borderColor = isDarkMode ? const Color(0xFF334155) : const Color(0xFFE2E8F0);
    final textMutedColor = isDarkMode ? Colors.white54 : Colors.black54;

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        title: const Text(
          'Savings',
          style: TextStyle(fontWeight: FontWeight.w900, fontSize: 20),
        ),
        centerTitle: false,
        elevation: 0,
        backgroundColor: Colors.transparent,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // ── Hero Balance Card ──────────────────────────────────────────
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: isDarkMode
                      ? [const Color(0xFF0D1B2A), const Color(0xFF1B2838)]
                      : [const Color(0xFFECFDF5), Colors.white],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(28),
                border: Border.all(
                  color: isDarkMode
                      ? const Color(0xFF10B981).withOpacity(0.25)
                      : const Color(0xFFA7F3D0),
                  width: 1.5,
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(isDarkMode ? 0.4 : 0.05),
                    blurRadius: 20,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: const Color(0xFF10B981).withOpacity(0.15),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.savings_rounded, color: Color(0xFF10B981), size: 20),
                      ),
                      const SizedBox(width: 10),
                      Text(
                        'SAVINGS BALANCE',
                        style: TextStyle(
                          fontSize: 9,
                          fontWeight: FontWeight.bold,
                          color: textMutedColor,
                          letterSpacing: 0.8,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),
                  Text(
                    '$currencySymbol${currentBalance.toStringAsFixed(2)}',
                    style: TextStyle(
                      fontSize: 36,
                      fontWeight: FontWeight.w900,
                      color: isDarkMode ? Colors.white : const Color(0xFF065F46),
                      letterSpacing: -0.5,
                    ),
                  ),
                  const SizedBox(height: 18),
                  Row(
                    children: [
                      Expanded(
                        child: _MiniStat(
                          label: 'DEPOSITED',
                          amount: totalAdded,
                          color: const Color(0xFF10B981),
                          icon: Icons.add_circle_outline_rounded,
                          isDarkMode: isDarkMode,
                        ),
                      ),
                      Container(width: 1, height: 36, color: borderColor),
                      Expanded(
                        child: _MiniStat(
                          label: 'WITHDRAWN',
                          amount: totalDebited,
                          color: const Color(0xFFEF4444),
                          icon: Icons.remove_circle_outline_rounded,
                          isDarkMode: isDarkMode,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 18),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: () => _showAddFundsSheet(context),
                      icon: const Icon(Icons.add_rounded, size: 18),
                      label: const Text(
                        'Add Funds to Savings',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF10B981),
                        foregroundColor: Colors.white,
                        elevation: 0,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 28),

            // ── Expenses History Header ────────────────────────────────────
            const Padding(
              padding: EdgeInsets.only(left: 4, bottom: 14),
              child: Text(
                'Savings Expense History',
                style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
              ),
            ),

            // ── Empty State ───────────────────────────────────────────────
            if (savingsExpenses.isEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 40),
                child: Column(
                  children: [
                    Icon(Icons.receipt_long_rounded, size: 48, color: textMutedColor),
                    const SizedBox(height: 12),
                    Text(
                      'No expenses from savings yet.',
                      style: TextStyle(color: textMutedColor, fontSize: 13),
                    ),
                  ],
                ),
              ),

            // ── Expense Cards ─────────────────────────────────────────────
            ...savingsExpenses.map((exp) => Container(
              margin: const EdgeInsets.only(bottom: 12),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              decoration: BoxDecoration(
                color: cardBgColor,
                borderRadius: BorderRadius.circular(18),
                border: Border.all(color: borderColor),
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: const Color(0xFFEF4444).withOpacity(0.1),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.arrow_outward_rounded, color: Color(0xFFEF4444), size: 16),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          exp.description.isEmpty ? 'Savings Expense' : exp.description,
                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                        ),
                        const SizedBox(height: 3),
                        Text(
                          DateFormat('dd MMM yyyy · hh:mm a').format(exp.date),
                          style: TextStyle(color: textMutedColor, fontSize: 11),
                        ),
                      ],
                    ),
                  ),
                  Text(
                    '-$currencySymbol${exp.amount.toStringAsFixed(0)}',
                    style: const TextStyle(
                      fontWeight: FontWeight.w900,
                      color: Color(0xFFEF4444),
                      fontSize: 15,
                    ),
                  ),
                ],
              ),
            )),
          ],
        ),
      ),
    );
  }

  void _showAddFundsSheet(BuildContext context) {
    final ctrl = TextEditingController();
    final accountsVM = context.read<AccountsViewModel>();
    String? selectedAccountId = accountsVM.accounts.isNotEmpty ? accountsVM.accounts.first.id : null;
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final borderColor = isDarkMode ? const Color(0xFF334155) : const Color(0xFFE2E8F0);
    final inputBorder = OutlineInputBorder(
      borderRadius: BorderRadius.circular(14),
      borderSide: BorderSide(color: borderColor),
    );

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        final keyboardOffset = MediaQuery.of(ctx).viewInsets.bottom;
        final theme = Theme.of(ctx);
        return StatefulBuilder(
          builder: (ctx, setSheetState) => Container(
            padding: EdgeInsets.only(
              top: 24,
              left: 20,
              right: 20,
              bottom: 24 + keyboardOffset,
            ),
            decoration: BoxDecoration(
              color: isDarkMode ? const Color(0xFF0F172A) : Colors.white,
              borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
              border: Border.all(color: borderColor, width: 1.2),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Drag handle
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
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: const Color(0xFF10B981).withOpacity(0.12),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.savings_rounded, color: Color(0xFF10B981), size: 18),
                    ),
                    const SizedBox(width: 12),
                    Text(
                      'Add Funds to Savings',
                      style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w900),
                    ),
                  ],
                ),
                const SizedBox(height: 24),
                // Amount field
                TextField(
                  controller: ctrl,
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  decoration: InputDecoration(
                    labelText: 'Amount ($currencySymbol)',
                    prefixIcon: const Icon(Icons.monetization_on_outlined),
                    border: inputBorder,
                    enabledBorder: inputBorder,
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                      borderSide: const BorderSide(color: Color(0xFF10B981), width: 1.5),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                // Account dropdown — full width, no overflow
                if (accountsVM.accounts.isEmpty)
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: const Color(0xFFEF4444).withOpacity(0.08),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Text(
                      'No accounts available to fund savings.',
                      style: TextStyle(color: Color(0xFFEF4444), fontSize: 13),
                    ),
                  )
                else
                  DropdownButtonFormField<String>(
                    decoration: InputDecoration(
                      labelText: 'Source Account',
                      prefixIcon: const Icon(Icons.credit_card_rounded),
                      border: inputBorder,
                      enabledBorder: inputBorder,
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(14),
                        borderSide: const BorderSide(color: Color(0xFF10B981), width: 1.5),
                      ),
                    ),
                    isExpanded: true, // ← Fixes the overflow
                    value: selectedAccountId,
                    items: accountsVM.accounts.map((a) {
                      return DropdownMenuItem(
                        value: a.id,
                        child: Text(
                          '${a.name}  ·  $currencySymbol${a.openingBalance.toStringAsFixed(0)}',
                          overflow: TextOverflow.ellipsis,
                        ),
                      );
                    }).toList(),
                    onChanged: (val) => setSheetState(() => selectedAccountId = val),
                  ),
                const SizedBox(height: 24),
                ElevatedButton(
                  onPressed: () {
                    final val = double.tryParse(ctrl.text);
                    if (val == null || val <= 0) {
                      AppSnackBar.show(ctx, message: 'Enter a valid amount.', isError: true);
                      return;
                    }
                    if (selectedAccountId == null) {
                      AppSnackBar.show(ctx, message: 'Select a source account.', isError: true);
                      return;
                    }
                    final selectedAcc = accountsVM.accounts.firstWhere((a) => a.id == selectedAccountId);
                    if (selectedAcc.openingBalance < val) {
                      AppSnackBar.show(context, message: 'Insufficient balance in selected account.', isError: true);
                      return;
                    }
                    context.read<SavingsViewModel>().addToSavings(val, selectedAccountId!);
                    Navigator.pop(ctx);
                    AppSnackBar.show(context,
                      message: '$currencySymbol${val.toStringAsFixed(0)} added to savings!',
                      isError: false,
                    );
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF10B981),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    elevation: 0,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  ),
                  child: const Text('Confirm Deposit', style: TextStyle(fontWeight: FontWeight.bold)),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _MiniStat extends StatelessWidget {
  final String label;
  final double amount;
  final Color color;
  final IconData icon;
  final bool isDarkMode;

  const _MiniStat({
    required this.label,
    required this.amount,
    required this.color,
    required this.icon,
    required this.isDarkMode,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      child: Row(
        children: [
          Icon(icon, color: color, size: 16),
          const SizedBox(width: 8),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: TextStyle(fontSize: 8, fontWeight: FontWeight.bold, color: color, letterSpacing: 0.5),
              ),
              const SizedBox(height: 2),
              Text(
                '$currencySymbol${amount.toStringAsFixed(0)}',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w900,
                  color: isDarkMode ? Colors.white : Colors.black87,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
