import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:uuid/uuid.dart';
import '../viewmodels/borrow_lend_view_model.dart';
import '../viewmodels/accounts_view_model.dart';
import '../../core/utils/currency_formatter.dart';
import '../../domain/entities/borrow_lend_entity.dart';
import '../widgets/custom_snackbar.dart';

class AddBorrowLendScreen extends StatefulWidget {
  final BorrowLendEntity? editEntry;

  const AddBorrowLendScreen({super.key, this.editEntry});

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
  void initState() {
    super.initState();
    if (widget.editEntry != null) {
      _nameCtrl.text = widget.editEntry!.personName;
      _phoneCtrl.text = widget.editEntry!.phoneNumber;
      _amountCtrl.text = widget.editEntry!.amount.toString();
      _noteCtrl.text = widget.editEntry!.note;
      _type = widget.editEntry!.type;
      _date = widget.editEntry!.date;
      _dueDate = widget.editEntry!.dueDate;
      _selectedAccountId = widget.editEntry!.accountId;
    }
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _phoneCtrl.dispose();
    _amountCtrl.dispose();
    _noteCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final accounts = context.watch<AccountsViewModel>().accounts;
    final theme = Theme.of(context);
    final isDarkMode = theme.brightness == Brightness.dark;

    if (_selectedAccountId == null && accounts.isNotEmpty) {
      _selectedAccountId = accounts.first.id;
    }

    final isLent = _type == 'lent';
    final accentColor = isLent ? const Color(0xFF10B981) : const Color(0xFFF43F5E);
    final cardBgColor = isDarkMode ? const Color(0xFF1E293B) : Colors.white;
    final borderColor = isDarkMode ? const Color(0xFF334155) : const Color(0xFFE2E8F0);
    final textMutedColor = isDarkMode ? Colors.white54 : Colors.black54;

    final inputBorder = OutlineInputBorder(
      borderRadius: BorderRadius.circular(14),
      borderSide: BorderSide(color: borderColor),
    );
    final focusedBorder = OutlineInputBorder(
      borderRadius: BorderRadius.circular(14),
      borderSide: BorderSide(color: theme.colorScheme.primary, width: 1.5),
    );

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        title: Text(
          widget.editEntry == null ? 'New Entry' : 'Edit Entry',
          style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 20),
        ),
        centerTitle: false,
        elevation: 0,
        backgroundColor: Colors.transparent,
      ),
      body: SafeArea(
        child: Form(
          key: _formKey,
          child: ListView(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            children: [
              // ── Type Selector ───────────────────────────────────────────
              Container(
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  color: isDarkMode ? const Color(0xFF1E293B) : const Color(0xFFF1F5F9),
                  borderRadius: BorderRadius.circular(18),
                ),
                child: Row(
                  children: ['lent', 'borrowed'].map((t) {
                    final selected = _type == t;
                    final color = t == 'lent' ? const Color(0xFF10B981) : const Color(0xFFF43F5E);
                    return Expanded(
                      child: GestureDetector(
                        onTap: () => setState(() => _type = t),
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 200),
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          decoration: BoxDecoration(
                            color: selected ? color : Colors.transparent,
                            borderRadius: BorderRadius.circular(14),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                t == 'lent' ? Icons.north_east_rounded : Icons.south_west_rounded,
                                size: 16,
                                color: selected ? Colors.white : textMutedColor,
                              ),
                              const SizedBox(width: 8),
                              Text(
                                t == 'lent' ? 'Money Lent' : 'Money Borrowed',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 13,
                                  color: selected ? Colors.white : textMutedColor,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    );
                  }).toList(),
                ),
              ),
              const SizedBox(height: 20),

              // ── Context Badge ───────────────────────────────────────────
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                decoration: BoxDecoration(
                  color: accentColor.withOpacity(0.08),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: accentColor.withOpacity(0.2)),
                ),
                child: Row(
                  children: [
                    Icon(
                      isLent ? Icons.north_east_rounded : Icons.south_west_rounded,
                      color: accentColor,
                      size: 14,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      isLent
                          ? 'You are lending money — they owe you'
                          : 'You borrowed money — you owe them',
                      style: TextStyle(color: accentColor, fontSize: 12, fontWeight: FontWeight.w600),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              // ── Section: Contact Details ─────────────────────────────────
              _SectionLabel(label: 'Contact Details'),
              const SizedBox(height: 12),

              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: cardBgColor,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: borderColor),
                ),
                child: Column(
                  children: [
                    TextFormField(
                      controller: _nameCtrl,
                      textCapitalization: TextCapitalization.words,
                      decoration: InputDecoration(
                        labelText: 'Person Name',
                        prefixIcon: const Icon(Icons.person_outline_rounded),
                        border: inputBorder,
                        enabledBorder: inputBorder,
                        focusedBorder: focusedBorder,
                        filled: true,
                        fillColor: Colors.transparent,
                      ),
                      validator: (v) => v == null || v.isEmpty ? 'Name is required' : null,
                    ),
                    const SizedBox(height: 14),
                    TextFormField(
                      controller: _phoneCtrl,
                      keyboardType: TextInputType.phone,
                      decoration: InputDecoration(
                        labelText: 'Phone Number (Unique ID)',
                        prefixIcon: const Icon(Icons.phone_outlined),
                        border: inputBorder,
                        enabledBorder: inputBorder,
                        focusedBorder: focusedBorder,
                        filled: true,
                        fillColor: Colors.transparent,
                      ),
                      validator: (v) => v == null || v.isEmpty ? 'Phone is required' : null,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),

              // ── Section: Transaction Details ─────────────────────────────
              _SectionLabel(label: 'Transaction Details'),
              const SizedBox(height: 12),

              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: cardBgColor,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: borderColor),
                ),
                child: Column(
                  children: [
                    TextFormField(
                      controller: _amountCtrl,
                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                      decoration: InputDecoration(
                        labelText: 'Amount ($currencySymbol)',
                        prefixIcon: const Icon(Icons.monetization_on_outlined),
                        border: inputBorder,
                        enabledBorder: inputBorder,
                        focusedBorder: focusedBorder,
                        filled: true,
                        fillColor: Colors.transparent,
                      ),
                      validator: (v) => v == null || double.tryParse(v) == null
                          ? 'Enter a valid amount'
                          : null,
                    ),
                    const SizedBox(height: 14),
                    DropdownButtonFormField<String>(
                      decoration: InputDecoration(
                        labelText: isLent ? 'Account Debited (lend from)' : 'Account Credited (received to)',
                        prefixIcon: const Icon(Icons.credit_card_rounded),
                        border: inputBorder,
                        enabledBorder: inputBorder,
                        focusedBorder: focusedBorder,
                        filled: true,
                        fillColor: Colors.transparent,
                      ),
                      value: _selectedAccountId,
                      items: accounts.map((acc) => DropdownMenuItem(
                        value: acc.id,
                        child: Text(acc.name),
                      )).toList(),
                      onChanged: (val) => setState(() => _selectedAccountId = val),
                      validator: (v) => v == null ? 'Select an account' : null,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),

              // ── Section: Dates ───────────────────────────────────────────
              _SectionLabel(label: 'Dates'),
              const SizedBox(height: 12),

              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: cardBgColor,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: borderColor),
                ),
                child: Column(
                  children: [
                    // Transaction Date
                    _DateRow(
                      label: 'Transaction Date',
                      icon: Icons.calendar_today_rounded,
                      value: DateFormat('dd MMM yyyy').format(_date),
                      onTap: () async {
                        final picked = await showDatePicker(
                          context: context,
                          initialDate: _date,
                          firstDate: DateTime(2000),
                          lastDate: DateTime(2100),
                        );
                        if (picked != null) setState(() => _date = picked);
                      },
                      isDarkMode: isDarkMode,
                    ),
                    Divider(height: 24, color: borderColor),
                    // Due Date
                    _DateRow(
                      label: _dueDate == null ? 'Set Due Date (Optional)' : 'Due Date',
                      icon: Icons.event_rounded,
                      value: _dueDate == null ? 'Tap to set' : DateFormat('dd MMM yyyy').format(_dueDate!),
                      onTap: () async {
                        final picked = await showDatePicker(
                          context: context,
                          initialDate: _dueDate ?? DateTime.now().add(const Duration(days: 7)),
                          firstDate: DateTime.now(),
                          lastDate: DateTime(2100),
                        );
                        if (picked != null) setState(() => _dueDate = picked);
                      },
                      trailing: _dueDate != null
                          ? GestureDetector(
                              onTap: () => setState(() => _dueDate = null),
                              child: Icon(Icons.close_rounded, size: 16, color: textMutedColor),
                            )
                          : null,
                      isDarkMode: isDarkMode,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),

              // ── Section: Notes ───────────────────────────────────────────
              _SectionLabel(label: 'Notes (Optional)'),
              const SizedBox(height: 12),
              TextFormField(
                controller: _noteCtrl,
                maxLines: 3,
                decoration: InputDecoration(
                  hintText: 'Add a note about this transaction...',
                  prefixIcon: const Padding(
                    padding: EdgeInsets.only(bottom: 40),
                    child: Icon(Icons.notes_rounded),
                  ),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide(color: borderColor)),
                  enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide(color: borderColor)),
                  focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide(color: theme.colorScheme.primary, width: 1.5)),
                  filled: true,
                  fillColor: cardBgColor,
                ),
              ),
              const SizedBox(height: 32),

              // ── Save Button ──────────────────────────────────────────────
              ElevatedButton(
                onPressed: _save,
                style: ElevatedButton.styleFrom(
                  backgroundColor: accentColor,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  elevation: 0,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                ),
                child: Text(
                  widget.editEntry == null ? 'Save Entry' : 'Update Entry',
                  style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
                ),
              ),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }

  void _save() {
    if (_formKey.currentState!.validate() && _selectedAccountId != null) {
      if (widget.editEntry == null) {
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
      } else {
        final entry = widget.editEntry!.copyWith(
          personName: _nameCtrl.text.trim(),
          phoneNumber: _phoneCtrl.text.trim(),
          amount: double.parse(_amountCtrl.text),
          type: _type,
          date: _date,
          dueDate: _dueDate,
          note: _noteCtrl.text.trim(),
          accountId: _selectedAccountId!,
        );
        context.read<BorrowLendViewModel>().updateEntry(entry);
      }

      AppSnackBar.show(context,
        message: widget.editEntry == null
            ? 'Entry saved successfully!'
            : 'Entry updated successfully!',
        isError: false,
      );
      Navigator.pop(context);
    }
  }
}

class _SectionLabel extends StatelessWidget {
  final String label;
  const _SectionLabel({required this.label});

  @override
  Widget build(BuildContext context) {
    return Text(
      label.toUpperCase(),
      style: TextStyle(
        fontSize: 10,
        fontWeight: FontWeight.bold,
        color: Theme.of(context).brightness == Brightness.dark
            ? Colors.white38
            : Colors.black38,
        letterSpacing: 0.8,
      ),
    );
  }
}

class _DateRow extends StatelessWidget {
  final String label;
  final IconData icon;
  final String value;
  final VoidCallback onTap;
  final Widget? trailing;
  final bool isDarkMode;

  const _DateRow({
    required this.label,
    required this.icon,
    required this.value,
    required this.onTap,
    this.trailing,
    required this.isDarkMode,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(10),
      child: Row(
        children: [
          Icon(icon, size: 20, color: theme.colorScheme.primary),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 10,
                    color: isDarkMode ? Colors.white54 : Colors.black54,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  value,
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                ),
              ],
            ),
          ),
          trailing ?? Icon(Icons.chevron_right_rounded, size: 18, color: isDarkMode ? Colors.white38 : Colors.black38),
        ],
      ),
    );
  }
}
