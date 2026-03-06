import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../domain/entities/emi_tracker_entity.dart';
import '../../core/services/notification_service.dart';
import '../viewmodels/emi_tracker_view_model.dart';
import '../viewmodels/accounts_view_model.dart';

class AddEmiScreen extends StatefulWidget {
  final EmiTrackerEntity? existingEmi;

  const AddEmiScreen({super.key, this.existingEmi});

  @override
  State<AddEmiScreen> createState() => _AddEmiScreenState();
}

class _AddEmiScreenState extends State<AddEmiScreen> {
  final _titleController = TextEditingController();
  final _providerController = TextEditingController();
  final _totalAmountController = TextEditingController();
  final _monthlyEmiController = TextEditingController();
  final _totalMonthsController = TextEditingController();
  final _notesController = TextEditingController();

  DateTime _startDate = DateTime.now();
  DateTime? _dueDate;
  bool _isPayLater = false;
  bool _enableReminder = false;
  String? _selectedAccountId;

  bool get _isEditing => widget.existingEmi != null;

  @override
  void initState() {
    super.initState();
    if (_isEditing) {
      final emi = widget.existingEmi!;
      _titleController.text = emi.title;
      _providerController.text = emi.provider;
      _totalAmountController.text = emi.totalAmount.toStringAsFixed(0);
      _notesController.text = emi.notes;
      _startDate = emi.startDate;
      _isPayLater = emi.isPayLater;
      _enableReminder = emi.isReminderEnabled;

      if (emi.isPayLater) {
        _dueDate = emi.dueDate;
      } else {
        _monthlyEmiController.text = emi.monthlyEmi.toStringAsFixed(0);
        _totalMonthsController.text = emi.totalMonths.toString();
      }
      _selectedAccountId = emi.accountId;
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _providerController.dispose();
    _totalAmountController.dispose();
    _monthlyEmiController.dispose();
    _totalMonthsController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final accounts = context.watch<AccountsViewModel>().accounts;

    if (_selectedAccountId == null && accounts.isNotEmpty) {
      _selectedAccountId = accounts.first.id;
    }

    return Scaffold(
      appBar: AppBar(title: Text(_isEditing ? "Edit Entry" : "Add Entry")),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            /// Type toggle
            Row(
              children: [
                Expanded(
                  child: _buildTypeChip(
                    label: "EMI",
                    icon: Icons.calendar_month,
                    selected: !_isPayLater,
                    onTap: () => setState(() => _isPayLater = false),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildTypeChip(
                    label: "Pay Later",
                    icon: Icons.credit_card,
                    selected: _isPayLater,
                    onTap: () => setState(() => _isPayLater = true),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 24),

            TextField(
              controller: _titleController,
              decoration: InputDecoration(
                labelText: _isPayLater ? "Purchase Name" : "Loan / EMI Name",
                hintText: _isPayLater
                    ? "e.g. Amazon order #1234"
                    : "e.g. iPhone 15 EMI",
              ),
            ),
            const SizedBox(height: 16),

            TextField(
              controller: _providerController,
              decoration: InputDecoration(
                labelText: "Provider",
                hintText: _isPayLater
                    ? "e.g. Amazon Pay Later, Super Money"
                    : "e.g. HDFC Credit Card",
              ),
            ),
            const SizedBox(height: 16),

            TextField(
              controller: _totalAmountController,
              keyboardType: const TextInputType.numberWithOptions(
                decimal: true,
              ),
              decoration: const InputDecoration(
                labelText: "Total Amount (₹)",
                hintText: "e.g. 5499",
              ),
            ),

            /// EMI-only fields
            if (!_isPayLater) ...[
              const SizedBox(height: 16),
              TextField(
                controller: _monthlyEmiController,
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: true,
                ),
                decoration: const InputDecoration(
                  labelText: "Monthly EMI (₹)",
                  hintText: "e.g. 7000",
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: _totalMonthsController,
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: true,
                ),
                decoration: const InputDecoration(
                  labelText: "Total Months",
                  hintText: "e.g. 12",
                ),
              ),
            ],

            const SizedBox(height: 16),

            /// Start date
            ListTile(
              contentPadding: EdgeInsets.zero,
              title: Text(_isPayLater ? "Purchase Date" : "Start Date"),
              subtitle: Text(DateFormat("dd MMM yyyy").format(_startDate)),
              trailing: const Icon(Icons.calendar_today),
              onTap: () async {
                final picked = await showDatePicker(
                  context: context,
                  initialDate: _startDate,
                  firstDate: DateTime(2020),
                  lastDate: DateTime(2100),
                );
                if (picked != null) {
                  setState(() => _startDate = picked);
                }
              },
            ),

            /// Due date (Pay Later only)
            if (_isPayLater) ...[
              ListTile(
                contentPadding: EdgeInsets.zero,
                title: const Text("Due Date"),
                subtitle: Text(
                  _dueDate != null
                      ? DateFormat("dd MMM yyyy").format(_dueDate!)
                      : "Tap to set due date",
                ),
                trailing: const Icon(Icons.event),
                onTap: () async {
                  final picked = await showDatePicker(
                    context: context,
                    initialDate:
                        _dueDate ??
                        DateTime.now().add(const Duration(days: 30)),
                    firstDate: DateTime(2020),
                    lastDate: DateTime(2100),
                  );
                  if (picked != null) {
                    setState(() => _dueDate = picked);
                  }
                },
              ),
            ],

            const SizedBox(height: 8),

            DropdownButtonFormField<String>(
              decoration: InputDecoration(
                labelText: _isPayLater ? "Paid for From" : "EMI Paid From",
              ),
              initialValue: _selectedAccountId,
              items: accounts.map((acc) {
                return DropdownMenuItem(value: acc.id, child: Text(acc.name));
              }).toList(),
              onChanged: (val) {
                setState(() => _selectedAccountId = val);
              },
              validator: (v) => v == null ? 'Select an account' : null,
            ),
            const SizedBox(height: 16),

            TextField(
              controller: _notesController,
              maxLines: 2,
              decoration: const InputDecoration(
                labelText: "Notes (optional)",
                hintText: "Any additional notes...",
              ),
            ),

            const SizedBox(height: 16),

            /// Reminder toggle
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              title: Text(
                _isPayLater ? "Payment Reminder" : "Monthly EMI Reminder",
              ),
              subtitle: Text(
                _isPayLater
                    ? "Get notified a day before due date"
                    : "Get notified a day before each EMI due",
              ),
              value: _enableReminder,
              onChanged: (val) => setState(() => _enableReminder = val),
            ),

            const SizedBox(height: 24),

            ElevatedButton(
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              onPressed: _save,
              child: Text(
                _isEditing ? "Update" : "Save",
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTypeChip({
    required String label,
    required IconData icon,
    required bool selected,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: _isEditing ? null : onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(vertical: 14),
        decoration: BoxDecoration(
          color: selected
              ? Theme.of(context).colorScheme.primary.withOpacity(0.12)
              : Theme.of(context).colorScheme.surfaceContainerHighest,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: selected
                ? Theme.of(context).colorScheme.primary
                : Colors.transparent,
            width: 2,
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              size: 20,
              color: selected
                  ? Theme.of(context).colorScheme.primary
                  : Theme.of(context).colorScheme.onSurfaceVariant,
            ),
            const SizedBox(width: 8),
            Text(
              label,
              style: TextStyle(
                fontWeight: FontWeight.w600,
                color: selected
                    ? Theme.of(context).colorScheme.primary
                    : Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _save() {
    final title = _titleController.text.trim();
    final provider = _providerController.text.trim();
    final totalAmount = double.tryParse(_totalAmountController.text) ?? 0;
    final notes = _notesController.text.trim();

    if (title.isEmpty || totalAmount <= 0 || _selectedAccountId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text("Please fill all required fields."),
          backgroundColor: Theme.of(context).colorScheme.error,
        ),
      );
      return;
    }

    if (!_isPayLater) {
      final monthlyEmi = double.tryParse(_monthlyEmiController.text) ?? 0;
      final totalMonths = int.tryParse(_totalMonthsController.text) ?? 0;

      if (monthlyEmi <= 0 || totalMonths <= 0) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text("Please fill EMI amount and months."),
            backgroundColor: Theme.of(context).colorScheme.error,
          ),
        );
        return;
      }

      final emi = EmiTrackerEntity(
        id: _isEditing
            ? widget.existingEmi!.id
            : DateTime.now().millisecondsSinceEpoch.toString(),
        title: title,
        provider: provider,
        totalAmount: totalAmount,
        monthlyEmi: monthlyEmi,
        totalMonths: totalMonths,
        paidMonths: _isEditing ? widget.existingEmi!.paidMonths : 0,
        startDate: _startDate,
        notes: notes,
        isPayLater: false,
        isReminderEnabled: _enableReminder,
        accountId: _selectedAccountId!,
      );

      _saveEntity(emi);

      if (_enableReminder) {
        _scheduleEmiReminders(emi);
      }
    } else {
      final emi = EmiTrackerEntity(
        id: _isEditing
            ? widget.existingEmi!.id
            : DateTime.now().millisecondsSinceEpoch.toString(),
        title: title,
        provider: provider,
        totalAmount: totalAmount,
        startDate: _startDate,
        notes: notes,
        isPayLater: true,
        dueDate: _dueDate,
        isPaid: _isEditing ? widget.existingEmi!.isPaid : false,
        isReminderEnabled: _enableReminder,
        accountId: _selectedAccountId!,
      );

      _saveEntity(emi);

      if (_enableReminder && _dueDate != null) {
        _schedulePayLaterReminder(emi);
      }
    }

    Navigator.pop(context);
  }

  void _saveEntity(EmiTrackerEntity emi) {
    final vm = context.read<EmiTrackerViewModel>();
    if (_isEditing) {
      vm.updateEmi(emi);
    } else {
      vm.addEmi(emi);
    }
  }

  void _scheduleEmiReminders(EmiTrackerEntity emi) {
    final notificationService = NotificationService();

    for (int i = emi.paidMonths; i < emi.totalMonths; i++) {
      final dueDate = DateTime(
        emi.startDate.year,
        emi.startDate.month + i,
        emi.startDate.day,
      );

      // Default reminder: 9:00 AM, one day before due date
      DateTime reminderDate = DateTime(
        dueDate.year,
        dueDate.month,
        dueDate.day,
        9,
        0,
        0,
      ).subtract(const Duration(days: 1));

      // If that 9 AM time has already passed, but the due date is still in the future,
      // schedule the reminder for 10 seconds from now so the user still gets it.
      if (!reminderDate.isAfter(DateTime.now()) &&
          dueDate.isAfter(DateTime.now())) {
        reminderDate = DateTime.now().add(const Duration(seconds: 10));
      }

      if (reminderDate.isAfter(DateTime.now())) {
        notificationService.scheduleNotification(
          id: emi.id.hashCode + i,
          title: "EMI Due Tomorrow",
          body:
              "Your EMI of ₹${emi.monthlyEmi.toStringAsFixed(0)} for ${emi.title} is due tomorrow.",
          scheduledDate: reminderDate,
        );
      }
    }
  }

  void _schedulePayLaterReminder(EmiTrackerEntity emi) {
    if (emi.dueDate == null) return;

    // Default reminder: 9:00 AM, one day before due date
    DateTime reminderDate = DateTime(
      emi.dueDate!.year,
      emi.dueDate!.month,
      emi.dueDate!.day,
      9,
      0,
      0,
    ).subtract(const Duration(days: 1));

    // If that 9 AM time has already passed, but the due date is still in the future,
    // schedule the reminder for 10 seconds from now so the user still gets it.
    if (!reminderDate.isAfter(DateTime.now()) &&
        emi.dueDate!.isAfter(DateTime.now())) {
      reminderDate = DateTime.now().add(const Duration(seconds: 10));
    }

    if (reminderDate.isAfter(DateTime.now())) {
      NotificationService().scheduleNotification(
        id: emi.id.hashCode,
        title: "Payment Due Tomorrow",
        body:
            "Your payment of ₹${emi.totalAmount.toStringAsFixed(0)} for ${emi.title} (${emi.provider}) is due tomorrow.",
        scheduledDate: reminderDate,
      );
    }
  }
}
