import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../theme/app_theme.dart';
import '../viewmodels/accounts_view_model.dart';

class AccountsScreen extends StatelessWidget {
  const AccountsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final accountsVM = context.watch<AccountsViewModel>();

    return Scaffold(
      appBar: AppBar(title: const Text('Accounts')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            IOSCard(
              child: Column(
                children: [
                  Text(
                    'Total Balance',
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '₹${accountsVM.totalBalance.toStringAsFixed(2)}',
                    style: TextStyle(
                      fontSize: 32,
                      fontWeight: FontWeight.bold,
                      color: Theme.of(context).colorScheme.primary,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            const Padding(
              padding: EdgeInsets.only(left: 8.0),
              child: Text(
                'Payment Methods',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
            ),
            const SizedBox(height: 8),
            ...accountsVM.accounts.map(
              (acc) => _buildAccountItem(
                context,
                acc.name,
                acc.openingBalance,
                acc.id,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAccountItem(
    BuildContext context,
    String name,
    double balance,
    String id,
  ) {
    return IOSCard(
      child: ListTile(
        contentPadding: EdgeInsets.zero,
        leading: CircleAvatar(
          backgroundColor: Theme.of(
            context,
          ).colorScheme.primary.withOpacity(0.1),
          child: Icon(
            Icons.account_balance_wallet,
            color: Theme.of(context).colorScheme.primary,
          ),
        ),
        title: Text(name, style: const TextStyle(fontWeight: FontWeight.w600)),
        subtitle: Text('Balance: ₹${balance.toStringAsFixed(2)}'),
        trailing: IconButton(
          icon: Icon(
            Icons.add_circle_outline,
            color: Theme.of(context).colorScheme.primary,
          ),
          onPressed: () => _updateBalanceDialog(context, id),
        ),
        onTap: () {
          final accountsVM = context.read<AccountsViewModel>();
          final account = accountsVM.accounts.firstWhere((a) => a.id == id);
          Navigator.pushNamed(context, '/accountDetail', arguments: account);
        },
      ),
    );
  }

  void _updateBalanceDialog(BuildContext context, String accountId) {
    final ctrl = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Update Balance'),
        content: TextField(
          controller: ctrl,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          decoration: const InputDecoration(
            labelText: 'Amount to Add (can be negative)',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              final amount = double.tryParse(ctrl.text);
              if (amount != null) {
                context.read<AccountsViewModel>().updateAccountBalance(
                  accountId,
                  amount,
                );
                Navigator.pop(ctx);
              }
            },
            child: const Text('Update'),
          ),
        ],
      ),
    );
  }
}
