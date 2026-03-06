import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:uuid/uuid.dart';
import '../theme/app_theme.dart';
import '../viewmodels/borrow_lend_view_model.dart';
import '../viewmodels/accounts_view_model.dart';
import '../../domain/entities/borrow_lend_entity.dart';

class AddBorrowLendScreen extends StatefulWidget {
  const AddBorrowLendScreen({super.key});

  @override
  State<AddBorrowLendScreen> createState() => _AddBorrowLendScreenState();
}

class _AddBorrowLendScreenState extends State<AddBorrowLendScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameCtrl = TextEditingController();
  final _phoneCtrl = TextEditingController();
  final _amountCtrl = TextEditingController();
  final _noteCtrl = TextEditingController();

  String _type = 'lent';
  DateTime _date = DateTime.now();
  DateTime? _dueDate;
  String? _selectedAccountId;

  @override
  Widget build(BuildContext context) {
    final accounts = context.watch<AccountsViewModel>().accounts;

    if (_selectedAccountId == null && accounts.isNotEmpty) {
      _selectedAccountId = accounts.first.id;
    }

    return Scaffold(
      appBar: AppBar(title: const Text('Add Entry')),
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
                    // Type Selector
                    Row(
                      children: [
                        Expanded(
                          child: RadioListTile<String>(
                            title: const Text('Lent'),
                            value: 'lent',
                            groupValue: _type,
                            onChanged: (val) {
                              if (val != null) setState(() => _type = val);
                            },
                            contentPadding: EdgeInsets.zero,
                          ),
                        ),
                        Expanded(
                          child: RadioListTile<String>(
                            title: const Text('Borrowed'),
                            value: 'borrowed',
                            groupValue: _type,
                            onChanged: (val) {
                              if (val != null) setState(() => _type = val);
                            },
                            contentPadding: EdgeInsets.zero,
                          ),
                        ),
                      ],
                    ),
                    const Divider(),
                    TextFormField(
                      controller: _nameCtrl,
                      decoration: const InputDecoration(
                        labelText: 'Person Name',
                      ),
                      validator: (v) =>
                          v == null || v.isEmpty ? 'Required' : null,
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: _phoneCtrl,
                      decoration: const InputDecoration(
                        labelText: 'Phone Number (Unique Identifier)',
                      ),
                      keyboardType: TextInputType.phone,
                      validator: (v) =>
                          v == null || v.isEmpty ? 'Required' : null,
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: _amountCtrl,
                      decoration: const InputDecoration(
                        labelText: 'Amount (₹)',
                      ),
                      keyboardType: TextInputType.number,
                      validator: (v) => v == null || double.tryParse(v) == null
                          ? 'Invalid Amount'
                          : null,
                    ),
                    const SizedBox(height: 12),
                    DropdownButtonFormField<String>(
                      decoration: InputDecoration(
                        labelText: _type == 'lent'
                            ? 'Account Used (to lend)'
                            : 'Account Received To',
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
                    const SizedBox(height: 12),
                    ListTile(
                      contentPadding: EdgeInsets.zero,
                      title: Text(
                        'Date: ${DateFormat('dd MMM yyyy').format(_date)}',
                      ),
                      trailing: const Icon(Icons.calendar_today),
                      onTap: () async {
                        final picked = await showDatePicker(
                          context: context,
                          initialDate: _date,
                          firstDate: DateTime(2000),
                          lastDate: DateTime(2100),
                        );
                        if (picked != null) setState(() => _date = picked);
                      },
                    ),
                    const Divider(),
                    ListTile(
                      contentPadding: EdgeInsets.zero,
                      title: Text(
                        _dueDate == null
                            ? 'Set Due Date (Optional)'
                            : 'Due: ${DateFormat('dd MMM yyyy').format(_dueDate!)}',
                      ),
                      trailing: _dueDate == null
                          ? const Icon(Icons.calendar_today)
                          : IconButton(
                              icon: const Icon(Icons.clear),
                              onPressed: () => setState(() => _dueDate = null),
                            ),
                      onTap: () async {
                        final picked = await showDatePicker(
                          context: context,
                          initialDate: _dueDate ?? DateTime.now(),
                          firstDate: DateTime.now(),
                          lastDate: DateTime(2100),
                        );
                        if (picked != null) setState(() => _dueDate = picked);
                      },
                    ),
                    const Divider(),
                    TextFormField(
                      controller: _noteCtrl,
                      decoration: const InputDecoration(
                        labelText: 'Note (Optional)',
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
                  'Save Entry',
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
      final entry = BorrowLendEntity(
        id: const Uuid().v4(),
        personName: _nameCtrl.text.trim(),
        phoneNumber: _phoneCtrl.text.trim(),
        amount: double.parse(_amountCtrl.text),
        type: _type,
        date: _date,
        dueDate: _dueDate,
        note: _noteCtrl.text.trim(),
        status: 'pending',
        accountId: _selectedAccountId!,
      );

      context.read<BorrowLendViewModel>().addEntry(entry);
      Navigator.pop(context);
    }
  }
}
