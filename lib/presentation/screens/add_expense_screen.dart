import 'package:flutter/material.dart';
import 'package:intl/intl.dart' as intl;
import 'package:provider/provider.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../domain/entities/expense_entity.dart';
import '../../features/credit_card/presentation/blocs/credit_card_bloc.dart';
import '../viewmodels/accounts_view_model.dart';
import '../viewmodels/budget_view_model.dart';
import '../viewmodels/expense_view_model.dart';
import '../../core/utils/currency_formatter.dart';
import '../widgets/custom_snackbar.dart';
import '../widgets/scanner_preview_dialog.dart';

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
  DateTime _selectedDate = DateTime.now();

  @override
  void initState() {
    super.initState();
    if (widget.existingExpense != null) {
      final e = widget.existingExpense!;
      _amountController.text = e.amount == 0 ? '' : e.amount.toStringAsFixed(0);
      _descController.text = e.description;
      _selectedCategory = e.categoryId;
      _selectedAccount = e.accountId;
      _selectedDate = e.date;
    }
  }

  @override
  Widget build(BuildContext context) {
    final budgetVM = context.watch<BudgetViewModel>();
    final accountsVM = context.watch<AccountsViewModel>();
    final isEditing = widget.existingExpense != null;

    if (_selectedAccount == null && accountsVM.accounts.isNotEmpty) {
      _selectedAccount = accountsVM.accounts.first.id;
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(
          isEditing ? 'Edit Expense' : 'Add Expense',
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        elevation: 0,
        actions: [
          if (!isEditing)
            IconButton(
              icon: const Icon(Icons.document_scanner_rounded),
              tooltip: 'Scan receipt or screenshot',
              onPressed: () {
                ScannerPreviewDialog.show(
                  context,
                  onScanCompleted: (amount, merchant, date) {
                    setState(() {
                      _amountController.text = amount.toStringAsFixed(2);
                      _descController.text = merchant;
                      _selectedDate = date;
                    });
                  },
                );
              },
            ),
          const SizedBox(width: 8),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Hero Amount Card ───────────────────────────────────────────────
            Container(
              padding: const EdgeInsets.all(22),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF1E1E2C), Color(0xFF2A2A3D)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(26),
                border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.3),
                    blurRadius: 18,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'ENTER AMOUNT',
                    style: TextStyle(
                      color: Colors.white60,
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 1.2,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.baseline,
                    textBaseline: TextBaseline.alphabetic,
                    children: [
                      Text(
                        currencySymbol,
                        style: TextStyle(
                          color: Theme.of(context).colorScheme.primary,
                          fontSize: 34,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: TextField(
                          controller: _amountController,
                          keyboardType: const TextInputType.numberWithOptions(decimal: true),
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 40,
                            fontWeight: FontWeight.w900,
                            letterSpacing: -0.5,
                          ),
                          decoration: const InputDecoration(
                            hintText: '0',
                            hintStyle: TextStyle(color: Colors.white30),
                            border: InputBorder.none,
                            enabledBorder: InputBorder.none,
                            focusedBorder: InputBorder.none,
                            fillColor: Colors.transparent,
                            isDense: true,
                            contentPadding: EdgeInsets.zero,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  const Divider(color: Colors.white12),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      const Icon(Icons.notes_rounded, color: Colors.white54, size: 18),
                      const SizedBox(width: 10),
                      Expanded(
                        child: TextField(
                          controller: _descController,
                          style: const TextStyle(color: Colors.white, fontSize: 14),
                          decoration: const InputDecoration(
                            hintText: 'What is this expense for? (Optional)',
                            hintStyle: TextStyle(color: Colors.white38, fontSize: 14),
                            border: InputBorder.none,
                            enabledBorder: InputBorder.none,
                            focusedBorder: InputBorder.none,
                            fillColor: Colors.transparent,
                            isDense: true,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            const SizedBox(height: 20),

            // ── Category Dropdown ─────────────────────────────────────────────
            DropdownButtonFormField<String>(
              value: _selectedCategory,
              decoration: InputDecoration(
                labelText: 'Category',
                prefixIcon: const Icon(Icons.category_rounded, size: 20),
                filled: true,
                fillColor: Theme.of(context).cardColor,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: BorderSide(color: Theme.of(context).dividerColor.withValues(alpha: 0.1)),
                ),
              ),
              items: budgetVM.categories.map((c) {
                return DropdownMenuItem(
                  value: c.id,
                  child: Text(c.name, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
                );
              }).toList(),
              onChanged: (val) => setState(() => _selectedCategory = val),
            ),

            const SizedBox(height: 16),

            // ── Payment Method Dropdown ───────────────────────────────────────
            DropdownButtonFormField<String>(
              value: _selectedAccount,
              decoration: InputDecoration(
                labelText: 'Payment Method',
                prefixIcon: const Icon(Icons.account_balance_wallet_rounded, size: 20),
                filled: true,
                fillColor: Theme.of(context).cardColor,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: BorderSide(color: Theme.of(context).dividerColor.withValues(alpha: 0.1)),
                ),
              ),
              items: accountsVM.accounts.map((a) {
                double displayBalance = a.openingBalance;
                if (a.id == 'supermoney') {
                  final ccState = context.watch<CreditCardBloc>().state;
                  if (ccState is CreditCardLoadedState) {
                    displayBalance = ccState.account.availableCredit;
                  }
                }
                return DropdownMenuItem(
                  value: a.id,
                  child: Text(
                    '${a.name} ($currencySymbol${displayBalance.toStringAsFixed(0)})',
                    style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
                  ),
                );
              }).toList(),
              onChanged: (val) => setState(() => _selectedAccount = val),
            ),

            const SizedBox(height: 16),

            // ── Date Selector ─────────────────────────────────────────────────
            InkWell(
              onTap: _pickDate,
              borderRadius: BorderRadius.circular(16),
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Theme.of(context).cardColor,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: Theme.of(context).dividerColor.withValues(alpha: 0.1)),
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Icon(Icons.calendar_month_rounded, color: Theme.of(context).colorScheme.primary, size: 18),
                    ),
                    const SizedBox(width: 12),
                    const Text('Transaction Date', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
                    const Spacer(),
                    Text(
                      intl.DateFormat('MMM dd, yyyy - hh:mm a').format(_selectedDate),
                      style: TextStyle(
                        color: Theme.of(context).colorScheme.primary,
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 28),

            // ── Action Button ──────────────────────────────────────────────────
            SizedBox(
              width: double.infinity,
              height: 52,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Theme.of(context).colorScheme.primary,
                  foregroundColor: Colors.white,
                  elevation: 2,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                ),
                onPressed: _saveExpense,
                child: Text(
                  isEditing ? 'UPDATE EXPENSE' : 'SAVE EXPENSE',
                  style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w900, letterSpacing: 0.8),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _pickDate() async {
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
    if (_selectedAccount == null) {
      _showError('Please select a payment method.');
      return;
    }

    final accountsVM = context.read<AccountsViewModel>();

    // Validate Balance constraint
    final acc = accountsVM.accounts.firstWhere(
      (a) => a.id == _selectedAccount,
      orElse: () => accountsVM.accounts.first,
    );
    double accountBalance = acc.openingBalance;
    if (_selectedAccount == 'supermoney') {
      final ccState = context.read<CreditCardBloc>().state;
      if (ccState is CreditCardLoadedState) {
        accountBalance = ccState.account.availableCredit;
      }
    }
    final oldAmount = (widget.existingExpense != null && widget.existingExpense!.accountId == _selectedAccount)
        ? widget.existingExpense!.amount
        : 0;
    if (accountBalance + oldAmount - amount < 0) {
      _showError(_selectedAccount == 'supermoney'
          ? 'Insufficient available credit.'
          : 'Insufficient account balance.');
      return;
    }

    final expense = ExpenseEntity(
      id: widget.existingExpense?.id ?? DateTime.now().millisecondsSinceEpoch.toString(),
      categoryId: _selectedCategory!,
      amount: amount,
      description: _descController.text,
      date: _selectedDate,
      accountId: _selectedAccount!,
      isFromSavings: false,
    );

    if (widget.existingExpense != null) {
      await context.read<ExpenseViewModel>().updateExpense(expense);
    } else {
      await context.read<ExpenseViewModel>().addExpense(expense);
    }

    if (mounted) Navigator.pop(context);
  }

  void _showError(String msg) {
    if (mounted) {
      AppSnackBar.show(
        context,
        message: msg,
        isError: true,
      );
    }
  }
}
