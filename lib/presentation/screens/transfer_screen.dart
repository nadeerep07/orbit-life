import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../domain/entities/transfer_entity.dart';
import '../theme/app_theme.dart';
import '../viewmodels/accounts_view_model.dart';
import '../viewmodels/savings_view_model.dart';
import '../viewmodels/transfer_view_model.dart';
import 'transfer_history_screen.dart';

class TransferScreen extends StatefulWidget {
  const TransferScreen({super.key});

  @override
  State<TransferScreen> createState() => _TransferScreenState();
}

class _TransferScreenState extends State<TransferScreen> {
  final _amountController = TextEditingController();
  final _noteController = TextEditingController();

  String? _fromAccount;
  String? _toAccount;
  DateTime _selectedDate = DateTime.now();

  @override
  Widget build(BuildContext context) {
    final accountsVM = context.watch<AccountsViewModel>();

    // Build simple list of dropdown items (all accounts + savings)
    final allOptions = [
      ...accountsVM.accounts.map((a) => {'id': a.id, 'name': a.name}),
      {'id': 'savings', 'name': 'Savings'},
    ];

    return Scaffold(
      appBar: AppBar(
        title: const Text('Transfer Money'),
        actions: [
          IconButton(
            icon: const Icon(Icons.history),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => const TransferHistoryScreen(),
                ),
              );
            },
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            IOSCard(
              child: Column(
                children: [
                  TextField(
                    controller: _amountController,
                    keyboardType: const TextInputType.numberWithOptions(
                      decimal: true,
                    ),
                    style: TextStyle(
                      fontSize: 32,
                      fontWeight: FontWeight.bold,
                      color: Theme.of(context).colorScheme.primary,
                    ),
                    decoration: const InputDecoration(
                      hintText: '₹0',
                      border: InputBorder.none,
                      enabledBorder: InputBorder.none,
                      focusedBorder: InputBorder.none,
                      fillColor: Colors.transparent,
                      prefixText: '₹ ',
                    ),
                  ),
                  const Divider(),
                  TextField(
                    controller: _noteController,
                    decoration: const InputDecoration(
                      hintText: 'Notes (Optional)',
                      border: InputBorder.none,
                      enabledBorder: InputBorder.none,
                      focusedBorder: InputBorder.none,
                      fillColor: Colors.transparent,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            IOSCard(
              child: Column(
                children: [
                  DropdownButtonFormField<String>(
                    decoration: const InputDecoration(
                      labelText: 'From Account',
                    ),
                    initialValue: _fromAccount,
                    items: allOptions.map((opt) {
                      return DropdownMenuItem(
                        value: opt['id'],
                        child: Text(opt['name']!),
                      );
                    }).toList(),
                    onChanged: (val) {
                      setState(() {
                        _fromAccount = val;
                        if (_fromAccount == _toAccount) {
                          _toAccount = null; // Prevent self transfer
                        }
                      });
                    },
                  ),
                  const SizedBox(height: 16),
                  Center(
                    child: Container(
                      decoration: BoxDecoration(
                        color: Theme.of(
                          context,
                        ).colorScheme.primary.withOpacity(0.1),
                        shape: BoxShape.circle,
                      ),
                      child: IconButton(
                        icon: const Icon(Icons.swap_vert),
                        color: Theme.of(context).colorScheme.primary,
                        onPressed: () {
                          setState(() {
                            final temp = _fromAccount;
                            _fromAccount = _toAccount;
                            _toAccount = temp;
                          });
                        },
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  DropdownButtonFormField<String>(
                    decoration: const InputDecoration(labelText: 'To Account'),
                    initialValue: _toAccount,
                    items: allOptions.map((opt) {
                      return DropdownMenuItem(
                        value: opt['id'],
                        child: Text(opt['name']!),
                      );
                    }).toList(),
                    onChanged: (val) {
                      setState(() {
                        _toAccount = val;
                        if (_toAccount == _fromAccount) {
                          _fromAccount = null;
                        }
                      });
                    },
                  ),
                  const SizedBox(height: 16),
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    title: const Text('Date'),
                    trailing: Text(
                      DateFormat('dd MMM yyyy').format(_selectedDate),
                      style: TextStyle(
                        color: Theme.of(context).colorScheme.primary,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    onTap: () async {
                      final date = await showDatePicker(
                        context: context,
                        initialDate: _selectedDate,
                        firstDate: DateTime(2000),
                        lastDate: DateTime.now(),
                      );
                      if (date != null) setState(() => _selectedDate = date);
                    },
                  ),
                ],
              ),
            ),
            const SizedBox(height: 32),
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Theme.of(context).colorScheme.primary,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                onPressed: _saveTransfer,
                child: const Text(
                  'Complete Transfer',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _saveTransfer() async {
    final amount = double.tryParse(_amountController.text);
    if (amount == null || amount <= 0) {
      _showError('Please enter a valid amount');
      return;
    }
    if (_fromAccount == null || _toAccount == null) {
      _showError('Please select both from and to accounts');
      return;
    }

    final transferVM = context.read<TransferViewModel>();
    final accountsVM = context.read<AccountsViewModel>();
    final savingsVM = context.read<SavingsViewModel>();

    // Validate if the source account has enough balance
    if (_fromAccount == 'savings') {
      final bal = savingsVM.savings?.currentBalance ?? 0;
      if (amount > bal) {
        _showError('Insufficient balance in Savings');
        return;
      }
    } else {
      final acc = accountsVM.accounts.firstWhere((a) => a.id == _fromAccount);
      if (amount > acc.openingBalance) {
        _showError('Insufficient balance in \${acc.name}');
        return;
      }
    }

    final transfer = TransferEntity(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      fromAccountId: _fromAccount!,
      toAccountId: _toAccount!,
      amount: amount,
      date: _selectedDate,
      description: _noteController.text,
    );

    await transferVM.addTransfer(transfer);

    if (mounted) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Transfer successful!')));
      Navigator.pop(context);
    }
  }

  void _showError(String msg) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(msg),
          backgroundColor: Theme.of(context).colorScheme.error,
        ),
      );
    }
  }
}
