import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../blocs/credit_card_bloc.dart';
import '../blocs/fd_lots_bloc.dart';
import '../../../../presentation/widgets/custom_snackbar.dart';
import '../../../../core/utils/currency_formatter.dart';
import '../../../../presentation/viewmodels/accounts_view_model.dart';

class AddFdDepositScreen extends StatefulWidget {
  const AddFdDepositScreen({super.key});

  @override
  State<AddFdDepositScreen> createState() => _AddFdDepositScreenState();
}

class _AddFdDepositScreenState extends State<AddFdDepositScreen> {
  final _amountController = TextEditingController();
  final _remarksController = TextEditingController();
  DateTime _depositDate = DateTime.now();
  String? _selectedSourceAccount;

  @override
  void dispose() {
    _amountController.dispose();
    _remarksController.dispose();
    super.dispose();
  }

  void _onConfirmDeposit() {
    final amount = double.tryParse(_amountController.text);
    if (amount == null || amount <= 0) {
      AppSnackBar.show(
        context,
        message: 'Please enter a valid deposit amount',
        isError: true,
      );
      return;
    }

    context.read<FdLotsBloc>().add(
          DepositFdEvent(
            amount: amount,
            depositDate: _depositDate,
            remarks: _remarksController.text,
            sourceAccountId: _selectedSourceAccount,
          ),
        );

    context.read<CreditCardBloc>().add(LoadCreditCardAccountEvent());
    context.read<AccountsViewModel>().loadAccounts();
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final accountsVM = context.watch<AccountsViewModel>();
    final amount = double.tryParse(_amountController.text) ?? 0.0;
    final creditBoost = amount * 0.90;
    final lockDate = _depositDate.add(const Duration(days: 7));
    final maturityDate = _depositDate.add(const Duration(days: 365));

    return Scaffold(
      appBar: AppBar(
        title: const Text('Add Fixed Deposit (FD)', style: TextStyle(fontWeight: FontWeight.bold)),
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // ── Hero Amount Input Card ───────────────────────────────────────
            Container(
              padding: const EdgeInsets.all(22),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF0F172A), Color(0xFF1E293B)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(26),
                border: Border.all(color: Colors.amberAccent.withValues(alpha: 0.25)),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.35),
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
                        'NEW FD PRINCIPAL DEPOSIT',
                        style: TextStyle(color: Colors.amberAccent, fontSize: 10, fontWeight: FontWeight.bold, letterSpacing: 1.1),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: Colors.amberAccent.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Text(
                          '+90% CREDIT LIMIT',
                          style: TextStyle(color: Colors.amberAccent, fontSize: 9, fontWeight: FontWeight.bold),
                        ),
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
                        style: const TextStyle(color: Colors.amberAccent, fontSize: 32, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: TextField(
                          controller: _amountController,
                          keyboardType: const TextInputType.numberWithOptions(decimal: true),
                          style: const TextStyle(color: Colors.white, fontSize: 38, fontWeight: FontWeight.w900),
                          decoration: const InputDecoration(
                            hintText: '5000',
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

            const SizedBox(height: 24),

            // ── Source Account Chips ─────────────────────────────────────────
            const Text(
              'FUNDING SOURCE BANK ACCOUNT',
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

            // ── Date & Remarks ───────────────────────────────────────────────
            InkWell(
              onTap: () async {
                final picked = await showDatePicker(
                  context: context,
                  initialDate: _depositDate,
                  firstDate: DateTime(2020),
                  lastDate: DateTime(2100),
                );
                if (picked != null) setState(() => _depositDate = picked);
              },
              borderRadius: BorderRadius.circular(16),
              child: Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: Theme.of(context).cardColor,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: Theme.of(context).dividerColor.withValues(alpha: 0.1)),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.calendar_month_rounded, size: 20, color: Colors.amberAccent),
                    const SizedBox(width: 10),
                    Text(
                      'Deposit Date: ${DateFormat('dd MMMM yyyy').format(_depositDate)}',
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 12),

            TextField(
              controller: _remarksController,
              decoration: InputDecoration(
                hintText: 'Remarks / Memo (Optional)',
                prefixIcon: const Icon(Icons.note_rounded, size: 20),
                filled: true,
                fillColor: Theme.of(context).cardColor,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: BorderSide(color: Theme.of(context).dividerColor.withValues(alpha: 0.1)),
                ),
              ),
            ),

            const SizedBox(height: 20),

            // ── Realtime Deposit Preview Card ────────────────────────────────
            Container(
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.06),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.12)),
              ),
              child: Column(
                children: [
                  _buildPreviewRow('Credit Limit Boost (+90%)', '+$currencySymbol${creditBoost.toStringAsFixed(0)}', Colors.green),
                  const Divider(),
                  _buildPreviewRow('Lock Period (7 Days)', 'Locked until ${DateFormat('dd MMM yyyy').format(lockDate)}', Colors.orange),
                  const Divider(),
                  _buildPreviewRow('Auto-Maturity Date (1 Year)', DateFormat('dd MMM yyyy').format(maturityDate), Colors.blue),
                  const Divider(),
                  _buildPreviewRow('Interest Rate', '6.0% p.a. Compounded Daily', Colors.teal),
                ],
              ),
            ),

            const SizedBox(height: 28),

            SizedBox(
              height: 52,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.amberAccent,
                  foregroundColor: Colors.black,
                  elevation: 2,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                ),
                onPressed: _onConfirmDeposit,
                child: const Text('CONFIRM & CREATE FD', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w900, letterSpacing: 0.8)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPreviewRow(String label, String value, Color valueColor) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Colors.grey)),
          Text(value, style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: valueColor)),
        ],
      ),
    );
  }
}
