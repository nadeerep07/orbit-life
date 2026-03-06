import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:uuid/uuid.dart';
import '../theme/app_theme.dart';
import '../viewmodels/investment_view_model.dart';
import '../viewmodels/accounts_view_model.dart';
import '../../domain/entities/investment_entity.dart';

class AddInvestmentScreen extends StatefulWidget {
  const AddInvestmentScreen({super.key});

  @override
  State<AddInvestmentScreen> createState() => _AddInvestmentScreenState();
}

class _AddInvestmentScreenState extends State<AddInvestmentScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameCtrl = TextEditingController();
  final _investedAmountCtrl = TextEditingController();
  final _currentValueCtrl = TextEditingController();
  final _quantityCtrl = TextEditingController();
  final _buyPriceCtrl = TextEditingController();
  final _noteCtrl = TextEditingController();
  final _interestRateCtrl = TextEditingController();

  String _type = 'stock';
  DateTime _date = DateTime.now();
  bool _enableSipReminder = false;
  String? _selectedAccountId;

  @override
  Widget build(BuildContext context) {
    final accounts = context.watch<AccountsViewModel>().accounts;

    if (_selectedAccountId == null && accounts.isNotEmpty) {
      _selectedAccountId = accounts.first.id;
    }

    return Scaffold(
      appBar: AppBar(title: const Text('Add Investment')),
      body: SafeArea(
        child: Form(
          key: _formKey,
          child: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              IOSCard(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    DropdownButtonFormField<String>(
                      decoration: const InputDecoration(
                        labelText: 'Investment Type',
                      ),
                      initialValue: _type,
                      items: const [
                        DropdownMenuItem(value: 'stock', child: Text('Stocks')),
                        DropdownMenuItem(
                          value: 'sip',
                          child: Text('SIP / Mutual Funds'),
                        ),
                        DropdownMenuItem(
                          value: 'fd',
                          child: Text('Fixed Deposit (FD)'),
                        ),
                        DropdownMenuItem(
                          value: 'other',
                          child: Text('Other (Gold, Crypto, etc)'),
                        ),
                      ],
                      onChanged: (val) {
                        if (val != null) setState(() => _type = val);
                      },
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: _nameCtrl,
                      decoration: const InputDecoration(
                        labelText: 'Investment Name',
                      ),
                      validator: (v) =>
                          v == null || v.isEmpty ? 'Required' : null,
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: _investedAmountCtrl,
                      decoration: const InputDecoration(
                        labelText: 'Total Invested Amount (₹)',
                      ),
                      keyboardType: const TextInputType.numberWithOptions(
                        decimal: true,
                      ),
                      validator: (v) => v == null || double.tryParse(v) == null
                          ? 'Invalid Amount'
                          : null,
                    ),
                    if (_type != 'fd') ...[
                      const SizedBox(height: 12),
                      TextFormField(
                        controller: _currentValueCtrl,
                        decoration: const InputDecoration(
                          labelText: 'Current Value (₹)',
                        ),
                        keyboardType: const TextInputType.numberWithOptions(
                          decimal: true,
                        ),
                        validator: (v) =>
                            v == null || double.tryParse(v) == null
                            ? 'Invalid Amount'
                            : null,
                      ),
                    ],
                    if (_type == 'fd') ...[
                      const SizedBox(height: 12),
                      TextFormField(
                        controller: _interestRateCtrl,
                        decoration: const InputDecoration(
                          labelText: 'Annual Interest Rate (%)',
                        ),
                        keyboardType: const TextInputType.numberWithOptions(
                          decimal: true,
                        ),
                        validator: (v) =>
                            v == null || double.tryParse(v) == null
                            ? 'Invalid Rate'
                            : null,
                      ),
                    ],
                    if (_type == 'stock') ...[
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Expanded(
                            child: TextFormField(
                              controller: _quantityCtrl,
                              decoration: const InputDecoration(
                                labelText: 'Quantity (Optional)',
                              ),
                              keyboardType: TextInputType.number,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: TextFormField(
                              controller: _buyPriceCtrl,
                              decoration: const InputDecoration(
                                labelText: 'Buy Price (Optional)',
                              ),
                              keyboardType: TextInputType.number,
                            ),
                          ),
                        ],
                      ),
                    ],
                    const SizedBox(height: 12),
                    DropdownButtonFormField<String>(
                      decoration: const InputDecoration(
                        labelText: 'Payment Method (Account)',
                      ),
                      initialValue: _selectedAccountId,
                      items: accounts.map((acc) {
                        return DropdownMenuItem(
                          value: acc.id,
                          child: Text(acc.name),
                        );
                      }).toList(),
                      onChanged: (val) {
                        setState(() => _selectedAccountId = val);
                      },
                      validator: (v) => v == null ? 'Select an account' : null,
                    ),
                    if (_type == 'sip') ...[
                      const SizedBox(height: 12),
                      SwitchListTile(
                        title: const Text('Enable Monthly SIP Reminder'),
                        value: _enableSipReminder,
                        onChanged: (val) =>
                            setState(() => _enableSipReminder = val),
                        contentPadding: EdgeInsets.zero,
                      ),
                    ],
                    const SizedBox(height: 12),
                    ListTile(
                      contentPadding: EdgeInsets.zero,
                      title: Text(
                        'Start Date: ${DateFormat('dd MMM yyyy').format(_date)}',
                      ),
                      trailing: const Icon(Icons.calendar_today),
                      onTap: () async {
                        final picked = await showDatePicker(
                          context: context,
                          initialDate: _date,
                          firstDate: DateTime(2000),
                          lastDate: DateTime.now(),
                        );
                        if (picked != null) setState(() => _date = picked);
                      },
                    ),
                    const Divider(),
                    TextFormField(
                      controller: _noteCtrl,
                      decoration: const InputDecoration(
                        labelText: 'Notes (Optional)',
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: _save,
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: const Text(
                  'Save Investment',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _save() {
    if (_formKey.currentState!.validate() && _selectedAccountId != null) {
      final inv = InvestmentEntity(
        id: const Uuid().v4(),
        name: _nameCtrl.text.trim(),
        type: _type,
        investedAmount: double.parse(_investedAmountCtrl.text),
        currentValue: _type == 'fd'
            ? double.parse(_investedAmountCtrl.text)
            : double.parse(_currentValueCtrl.text),
        quantity: _quantityCtrl.text.isNotEmpty
            ? double.tryParse(_quantityCtrl.text)
            : null,
        buyPrice: _buyPriceCtrl.text.isNotEmpty
            ? double.tryParse(_buyPriceCtrl.text)
            : null,
        interestRate: _type == 'fd' && _interestRateCtrl.text.isNotEmpty
            ? double.tryParse(_interestRateCtrl.text)
            : null,
        date: _date,
        notes: _noteCtrl.text.trim(),
        accountId: _selectedAccountId!,
      );

      context.read<InvestmentViewModel>().addInvestment(
        inv,
        enableSipReminder: _enableSipReminder,
      );
      Navigator.pop(context);
    }
  }
}
