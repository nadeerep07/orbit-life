import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:provider/provider.dart';
import '../blocs/credit_card_bloc.dart';
import '../blocs/statement_bloc.dart';
import '../../../../presentation/widgets/custom_snackbar.dart';
import '../../../../core/utils/currency_formatter.dart';
import '../../../../presentation/viewmodels/accounts_view_model.dart';

class CreditCardPaymentScreen extends StatefulWidget {
  const CreditCardPaymentScreen({super.key});

  @override
  State<CreditCardPaymentScreen> createState() => _CreditCardPaymentScreenState();
}

class _CreditCardPaymentScreenState extends State<CreditCardPaymentScreen> {
  final _amountController = TextEditingController();
  final _refController = TextEditingController();
  String? _selectedSourceAccount;

  @override
  void dispose() {
    _amountController.dispose();
    _refController.dispose();
    super.dispose();
  }

  void _onConfirmPayment() {
    final amount = double.tryParse(_amountController.text);
    if (amount == null || amount <= 0) {
      AppSnackBar.show(
        context,
        message: 'Please enter a valid payment amount',
        isError: true,
      );
      return;
    }
    if (_selectedSourceAccount == null) {
      AppSnackBar.show(
        context,
        message: 'Please select a source bank account',
        isError: true,
      );
      return;
    }

    context.read<StatementBloc>().add(
          MakeCardPaymentEvent(
            sourceAccountId: _selectedSourceAccount!,
            amount: amount,
            date: DateTime.now(),
            reference: _refController.text,
          ),
        );

    context.read<CreditCardBloc>().add(LoadCreditCardAccountEvent());
    context.read<AccountsViewModel>().loadAccounts();
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final accountsVM = context.watch<AccountsViewModel>();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Credit Card Payment', style: TextStyle(fontWeight: FontWeight.bold)),
        elevation: 0,
      ),
      body: BlocBuilder<CreditCardBloc, CreditCardState>(
        builder: (context, state) {
          double usedCredit = 0.0;
          double minDue = 500.0;
          if (state is CreditCardLoadedState) {
            usedCredit = state.account.usedCredit;
            minDue = (usedCredit * 0.05).clamp(500.0, usedCredit > 0 ? usedCredit : 500.0);
          }

          return SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // ── Hero Amount Input Card ───────────────────────────────────────
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
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text(
                            'BILL PAYMENT AMOUNT',
                            style: TextStyle(color: Colors.white60, fontSize: 10, fontWeight: FontWeight.bold, letterSpacing: 1.1),
                          ),
                          Text(
                            'Total Due: $currencySymbol${usedCredit.toStringAsFixed(0)}',
                            style: TextStyle(color: Theme.of(context).colorScheme.primary, fontSize: 11, fontWeight: FontWeight.bold),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.baseline,
                        textBaseline: TextBaseline.alphabetic,
                        children: [
                          Text(
                            currencySymbol,
                            style: TextStyle(color: Theme.of(context).colorScheme.primary, fontSize: 32, fontWeight: FontWeight.bold),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: TextField(
                              controller: _amountController,
                              keyboardType: const TextInputType.numberWithOptions(decimal: true),
                              style: const TextStyle(color: Colors.white, fontSize: 38, fontWeight: FontWeight.w900),
                              decoration: const InputDecoration(
                                hintText: '0',
                                hintStyle: TextStyle(color: Colors.white30),
                                border: InputBorder.none,
                                isDense: true,
                                contentPadding: EdgeInsets.zero,
                              ),
                              onChanged: (_) => setState(() {}),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 16),

                // ── Quick Presets Chips ──────────────────────────────────────────
                Row(
                  children: [
                    Expanded(
                      child: InkWell(
                        onTap: () => setState(() => _amountController.text = minDue.toStringAsFixed(0)),
                        borderRadius: BorderRadius.circular(14),
                        child: Container(
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          decoration: BoxDecoration(
                            color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.2)),
                          ),
                          child: Column(
                            children: [
                              const Text('MIN DUE', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.grey)),
                              const SizedBox(height: 2),
                              Text('$currencySymbol${minDue.toStringAsFixed(0)}', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Theme.of(context).colorScheme.primary)),
                            ],
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: InkWell(
                        onTap: () => setState(() => _amountController.text = usedCredit.toStringAsFixed(0)),
                        borderRadius: BorderRadius.circular(14),
                        child: Container(
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          decoration: BoxDecoration(
                            color: Theme.of(context).colorScheme.primary,
                            borderRadius: BorderRadius.circular(14),
                          ),
                          child: Column(
                            children: [
                              const Text('FULL OUTSTANDING', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.white70)),
                              const SizedBox(height: 2),
                              Text('$currencySymbol${usedCredit.toStringAsFixed(0)}', style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.white)),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 24),

                // ── Source Bank Account Chips ─────────────────────────────────────
                const Text(
                  'PAY FROM BANK ACCOUNT',
                  style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.grey, letterSpacing: 1.1),
                ),
                const SizedBox(height: 10),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: accountsVM.accounts.where((a) => a.id != 'supermoney').map((a) {
                    final isSelected = _selectedSourceAccount == a.id;
                    return InkWell(
                      onTap: () => setState(() => _selectedSourceAccount = a.id),
                      borderRadius: BorderRadius.circular(14),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                        decoration: BoxDecoration(
                          color: isSelected ? Theme.of(context).colorScheme.primary : Theme.of(context).cardColor,
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(
                            color: isSelected ? Theme.of(context).colorScheme.primary : Theme.of(context).dividerColor.withValues(alpha: 0.1),
                          ),
                        ),
                        child: Text(
                          '${a.name} ($currencySymbol${a.openingBalance.toStringAsFixed(0)})',
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: isSelected ? FontWeight.bold : FontWeight.w600,
                            color: isSelected ? Colors.white : Theme.of(context).textTheme.bodyMedium?.color,
                          ),
                        ),
                      ),
                    );
                  }).toList(),
                ),

                const SizedBox(height: 18),

                // ── Notes / Reference Field ───────────────────────────────────────
                TextField(
                  controller: _refController,
                  decoration: InputDecoration(
                    hintText: 'Transaction Reference / Notes (Optional)',
                    prefixIcon: const Icon(Icons.note_rounded, size: 20),
                    filled: true,
                    fillColor: Theme.of(context).cardColor,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(16),
                      borderSide: BorderSide(color: Theme.of(context).dividerColor.withValues(alpha: 0.1)),
                    ),
                  ),
                ),

                const SizedBox(height: 28),

                SizedBox(
                  height: 52,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Theme.of(context).colorScheme.primary,
                      foregroundColor: Colors.white,
                      elevation: 2,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    ),
                    onPressed: _onConfirmPayment,
                    child: const Text('PAY CREDIT CARD BILL NOW', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w900, letterSpacing: 0.8)),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
