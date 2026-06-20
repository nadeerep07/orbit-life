import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../theme/app_theme.dart';
import '../viewmodels/savings_view_model.dart';
import '../viewmodels/expense_view_model.dart';
import '../viewmodels/accounts_view_model.dart';
import 'package:intl/intl.dart';
import '../../core/utils/currency_formatter.dart';

class SavingsScreen extends StatelessWidget {
  const SavingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final savingsVM = context.watch<SavingsViewModel>();
    final expenseVM = context.watch<ExpenseViewModel>();

    final savings = savingsVM.savings;
    final currentBalance = savings?.currentBalance ?? 0.0;
    final totalAdded = savings?.totalAdded ?? 0.0;
    final totalDebited = savings?.totalDebited ?? 0.0;

    // Find expenses made from savings
    final savingsExpenses = expenseVM.expenses
        .where((e) => e.isFromSavings)
        .toList();

    return Scaffold(
      appBar: AppBar(title: const Text('Savings Dashboard')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            IOSCard(
              child: Column(
                children: [
                  Text(
                    'Total Savings Balance',
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '$currencySymbol${currentBalance.toStringAsFixed(2)}',
                    style: TextStyle(
                      fontSize: 36,
                      fontWeight: FontWeight.bold,
                      color: Theme.of(context).colorScheme.primary,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      _buildStat(
                        context,
                        'Total Added',
                        totalAdded,
                        Colors.green,
                      ),
                      _buildStat(
                        context,
                        'Total Debited',
                        totalDebited,
                        Theme.of(context).colorScheme.error,
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Theme.of(
                          context,
                        ).colorScheme.primary.withOpacity(0.1),
                        foregroundColor: Theme.of(context).colorScheme.primary,
                        elevation: 0,
                      ),
                      onPressed: () => _addFundsDialog(context),
                      icon: const Icon(Icons.add),
                      label: const Text('Add Funds to Savings'),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            const Align(
              alignment: Alignment.centerLeft,
              child: Padding(
                padding: EdgeInsets.only(left: 8.0, bottom: 8.0),
                child: Text(
                  'Savings Expenses History',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
              ),
            ),
            if (savingsExpenses.isEmpty)
              Padding(
                padding: const EdgeInsets.all(32.0),
                child: Text(
                  'No expenses from savings yet.',
                  style: TextStyle(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                ),
              ),
            ...savingsExpenses.map(
              (exp) => IOSCard(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 12,
                ),
                child: ListTile(
                  contentPadding: EdgeInsets.zero,
                  title: Text(
                    exp.description.isEmpty
                        ? 'Savings Expense'
                        : exp.description,
                  ),
                  subtitle: Text(
                    DateFormat('dd MMM yyyy - hh:mm a').format(exp.date),
                  ),
                  trailing: Text(
                    '-$currencySymbol${exp.amount.toStringAsFixed(0)}',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Theme.of(context).colorScheme.error,
                      fontSize: 16,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStat(
    BuildContext context,
    String label,
    double amount,
    Color amountColor,
  ) {
    return Column(
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
          '$currencySymbol${amount.toStringAsFixed(0)}',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 16,
            color: amountColor,
          ),
        ),
      ],
    );
  }

  void _addFundsDialog(BuildContext context) {
    final ctrl = TextEditingController();
    final accountsVM = context.read<AccountsViewModel>();
    String? selectedAccountId = accountsVM.accounts.isNotEmpty ? accountsVM.accounts.first.id : null;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          title: const Text('Add Funds to Savings'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: ctrl,
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                decoration: InputDecoration(labelText: 'Amount ($currencySymbol)'),
              ),
              const SizedBox(height: 16),
              if (accountsVM.accounts.isEmpty)
                const Text('No accounts available to fund savings.', style: TextStyle(color: Colors.red))
              else
                DropdownButtonFormField<String>(
                  decoration: const InputDecoration(labelText: 'Source Account'),
                  initialValue: selectedAccountId,
                  items: accountsVM.accounts.map((a) {
                    return DropdownMenuItem(
                      value: a.id,
                      child: Text('${a.name} (Bal: $currencySymbol${a.openingBalance.toStringAsFixed(0)})'),
                    );
                  }).toList(),
                  onChanged: (val) {
                    setDialogState(() {
                      selectedAccountId = val;
                    });
                  },
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
                final val = double.tryParse(ctrl.text);
                if (val == null || val <= 0) return;
                if (selectedAccountId == null) return;

                final selectedAcc = accountsVM.accounts.firstWhere((a) => a.id == selectedAccountId);
                if (selectedAcc.openingBalance < val) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: const Text('Insufficient balance in selected account.'),
                      backgroundColor: Theme.of(context).colorScheme.error,
                    ),
                  );
                  return;
                }

                context.read<SavingsViewModel>().addToSavings(val, selectedAccountId!);
                Navigator.pop(ctx);
              },
              child: const Text('Add'),
            ),
          ],
        ),
      ),
    );
  }
}
