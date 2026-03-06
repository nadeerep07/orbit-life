import 'package:flutter/material.dart';
import 'package:intl/intl.dart' as intl;
import 'package:provider/provider.dart';
import '../../domain/entities/expense_entity.dart';
import '../theme/app_theme.dart';
import '../viewmodels/accounts_view_model.dart';
import '../viewmodels/budget_view_model.dart';
import '../viewmodels/expense_view_model.dart';
import '../viewmodels/savings_view_model.dart';

class AddExpenseScreen extends StatefulWidget {
  final ExpenseEntity? existingExpense;
  const AddExpenseScreen({super.key, this.existingExpense});

  @override
  State<AddExpenseScreen> createState() => _AddExpenseScreenState();
}

class _AddExpenseScreenState extends State<AddExpenseScreen> {
  final _amountController = TextEditingController();
  final _descController = TextEditingController();

  String? _selectedCategory;
  String? _selectedAccount;
  bool _isFromSavings = false;
  DateTime _selectedDate = DateTime.now();

  @override
  void initState() {
    super.initState();
    if (widget.existingExpense != null) {
      final e = widget.existingExpense!;
      _amountController.text = e.amount.toString();
      _descController.text = e.description;
      _selectedCategory = e.categoryId;
      _isFromSavings = e.isFromSavings;
      _selectedAccount = e.isFromSavings ? null : e.accountId;
      _selectedDate = e.date;
    }
  }

  @override
  Widget build(BuildContext context) {
    final budgetVM = context.watch<BudgetViewModel>();
    final accountsVM = context.watch<AccountsViewModel>();

    return Scaffold(
      appBar: AppBar(
        title: Text(
          widget.existingExpense == null ? 'Add Expense' : 'Edit Expense',
        ),
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
                    style: const TextStyle(
                      fontSize: 32,
                      fontWeight: FontWeight.bold,
                    ),
                    decoration: const InputDecoration(
                      hintText: '₹0',
                      border: InputBorder.none,
                      enabledBorder: InputBorder.none,
                      focusedBorder: InputBorder.none,
                      fillColor: Colors.transparent,
                    ),
                  ),
                  const Divider(),
                  TextField(
                    controller: _descController,
                    decoration: const InputDecoration(
                      hintText: 'Description',
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
                    decoration: const InputDecoration(labelText: 'Category'),
                    initialValue: _selectedCategory,
                    items: budgetVM.categories.map((c) {
                      return DropdownMenuItem(value: c.id, child: Text(c.name));
                    }).toList(),
                    onChanged: (val) => setState(() => _selectedCategory = val),
                  ),
                  const SizedBox(height: 16),
                  DropdownButtonFormField<String>(
                    decoration: const InputDecoration(
                      labelText: 'Payment Method',
                    ),
                    initialValue: _selectedAccount,
                    items: accountsVM.accounts.map((a) {
                      return DropdownMenuItem(value: a.id, child: Text(a.name));
                    }).toList(),
                    onChanged: _isFromSavings
                        ? null
                        : (val) => setState(() => _selectedAccount = val),
                  ),
                  const SizedBox(height: 16),
                  SwitchListTile(
                    title: const Text('Paid from Savings'),
                    value: _isFromSavings,
                    activeThumbColor: Theme.of(context).colorScheme.primary,
                    onChanged: (val) {
                      setState(() {
                        _isFromSavings = val;
                        if (val) _selectedAccount = null;
                      });
                    },
                  ),
                  const SizedBox(height: 16),
                  ListTile(
                    title: const Text('Date'),
                    trailing: Text(
                      intl.DateFormat(
                        'MMM dd, yyyy - hh:mm a',
                      ).format(_selectedDate),
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
                      if (date != null) {
                        if (!mounted) return;
                        final time = await showTimePicker(
                          context: context,
                          initialTime: TimeOfDay.fromDateTime(_selectedDate),
                        );
                        if (time != null) {
                          setState(() {
                            _selectedDate = DateTime(
                              date.year,
                              date.month,
                              date.day,
                              time.hour,
                              time.minute,
                            );
                          });
                        }
                      }
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
                onPressed: _saveExpense,
                child: Text(
                  widget.existingExpense == null
                      ? 'Save Expense'
                      : 'Update Expense',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _saveExpense() async {
    final amount = double.tryParse(_amountController.text);
    if (amount == null || amount <= 0) {
      _showError('Please enter a valid amount.');
      return;
    }
    if (_selectedCategory == null) {
      _showError('Please select a category.');
      return;
    }
    if (!_isFromSavings && _selectedAccount == null) {
      _showError('Please select a payment method.');
      return;
    }

    final accountsVM = context.read<AccountsViewModel>();
    final savingsVM = context.read<SavingsViewModel>();

    // Validate Balance constraint
    // We get current balance and add back the old amount if editing, then subtract the new amount
    if (_isFromSavings) {
      final currentBal = savingsVM.savings?.currentBalance ?? 0;
      final oldAmount =
          (widget.existingExpense != null &&
              widget.existingExpense!.isFromSavings)
          ? widget.existingExpense!.amount
          : 0;
      if (currentBal + oldAmount - amount < 0) {
        _showError('Insufficient savings balance.');
        return;
      }
    } else {
      final acc = accountsVM.accounts.firstWhere(
        (a) => a.id == _selectedAccount,
      );
      final oldAmount =
          (widget.existingExpense != null &&
              !widget.existingExpense!.isFromSavings &&
              widget.existingExpense!.accountId == _selectedAccount)
          ? widget.existingExpense!.amount
          : 0;
      if (acc.openingBalance + oldAmount - amount < 0) {
        _showError('Insufficient account balance.');
        return;
      }
    }

    final expense = ExpenseEntity(
      id:
          widget.existingExpense?.id ??
          DateTime.now().millisecondsSinceEpoch.toString(),
      categoryId: _selectedCategory!,
      amount: amount,
      description: _descController.text,
      date: _selectedDate,
      accountId: _isFromSavings ? 'savings' : _selectedAccount!,
      isFromSavings: _isFromSavings,
    );

    if (widget.existingExpense != null) {
      // Reverse previous transaction
      final old = widget.existingExpense!;
      if (old.isFromSavings) {
        await context.read<SavingsViewModel>().addToSavings(old.amount);
      } else {
        await context.read<AccountsViewModel>().updateAccountBalance(
          old.accountId,
          old.amount,
        );
      }
      // Apply new transaction
      await context.read<ExpenseViewModel>().updateExpense(expense);
      if (_isFromSavings) {
        await context.read<SavingsViewModel>().deductFromSavings(amount);
      } else {
        await context.read<AccountsViewModel>().updateAccountBalance(
          _selectedAccount!,
          -amount,
        );
      }
    } else {
      await context.read<ExpenseViewModel>().addExpense(expense);
      if (_isFromSavings) {
        await context.read<SavingsViewModel>().deductFromSavings(amount);
      } else {
        await context.read<AccountsViewModel>().updateAccountBalance(
          _selectedAccount!,
          -amount,
        );
      }
    }

    if (mounted) Navigator.pop(context);
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
