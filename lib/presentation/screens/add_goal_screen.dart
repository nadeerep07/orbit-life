import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../core/utils/currency_formatter.dart';
import '../../domain/entities/goal_entity.dart';
import '../viewmodels/goals_view_model.dart';
import '../widgets/custom_snackbar.dart';

class AddGoalScreen extends StatefulWidget {
  final GoalEntity? existingGoal;
  const AddGoalScreen({super.key, this.existingGoal});

  @override
  State<AddGoalScreen> createState() => _AddGoalScreenState();
}

class _AddGoalScreenState extends State<AddGoalScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _amountController = TextEditingController();
  final _savingsController = TextEditingController();
  DateTime? _selectedDate;

  // Goal icon options for quick selection
  static const _iconOptions = [
    (icon: Icons.phone_iphone_rounded, label: 'Phone'),
    (icon: Icons.directions_car_rounded, label: 'Car'),
    (icon: Icons.home_rounded, label: 'Home'),
    (icon: Icons.flight_rounded, label: 'Travel'),
    (icon: Icons.school_rounded, label: 'Education'),
    (icon: Icons.local_hospital_rounded, label: 'Health'),
    (icon: Icons.savings_rounded, label: 'Savings'),
    (icon: Icons.celebration_rounded, label: 'Event'),
  ];

  int _selectedIconIndex = 6; // default: Savings

  @override
  void initState() {
    super.initState();
    if (widget.existingGoal != null) {
      final g = widget.existingGoal!;
      _nameController.text = g.name;
      _amountController.text = g.targetAmount.toStringAsFixed(0);
      _savingsController.text = g.currentSavings > 0 ? g.currentSavings.toStringAsFixed(0) : '';
      _selectedDate = g.targetDate;
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _amountController.dispose();
    _savingsController.dispose();
    super.dispose();
  }

  double get _progress {
    final target = double.tryParse(_amountController.text) ?? 0;
    final saved = double.tryParse(_savingsController.text) ?? 0;
    if (target <= 0) return 0;
    return (saved / target).clamp(0.0, 1.0);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDarkMode = theme.brightness == Brightness.dark;
    final isEditing = widget.existingGoal != null;

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
          isEditing ? 'Edit Goal' : 'New Goal',
          style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 20),
        ),
        centerTitle: false,
        elevation: 0,
        backgroundColor: Colors.transparent,
      ),
      body: SafeArea(
        child: Form(
          key: _formKey,
          onChanged: () => setState(() {}), // live preview refresh
          child: ListView(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            children: [
              // ── Live Preview Card ────────────────────────────────────────
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: isDarkMode
                        ? [const Color(0xFF0F172A), const Color(0xFF1E293B)]
                        : [theme.colorScheme.primary.withOpacity(0.06), Colors.white],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(
                    color: theme.colorScheme.primary.withOpacity(0.2),
                    width: 1.5,
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: theme.colorScheme.primary.withOpacity(0.12),
                            shape: BoxShape.circle,
                          ),
                          child: Icon(_iconOptions[_selectedIconIndex].icon, color: theme.colorScheme.primary, size: 20),
                        ),
                        const SizedBox(width: 12),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              _nameController.text.isEmpty ? 'Goal Name' : _nameController.text,
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 15,
                                color: _nameController.text.isEmpty ? textMutedColor : null,
                              ),
                            ),
                            Text(
                              _amountController.text.isEmpty
                                  ? 'Set a target amount'
                                  : 'Target: $currencySymbol${_amountController.text}',
                              style: TextStyle(fontSize: 11, color: textMutedColor),
                            ),
                          ],
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          '$currencySymbol${_savingsController.text.isEmpty ? "0" : _savingsController.text} saved',
                          style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: isDarkMode ? Colors.white70 : Colors.black87),
                        ),
                        Text(
                          '${(_progress * 100).toStringAsFixed(0)}%',
                          style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: theme.colorScheme.primary),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(6),
                      child: LinearProgressIndicator(
                        value: _progress,
                        minHeight: 8,
                        backgroundColor: isDarkMode ? Colors.white10 : Colors.black12,
                        color: theme.colorScheme.primary,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),

              // ── Icon Picker ──────────────────────────────────────────────
              _SectionLabel(label: 'Choose Icon', textMutedColor: textMutedColor),
              const SizedBox(height: 10),
              SizedBox(
                height: 72,
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  itemCount: _iconOptions.length,
                  separatorBuilder: (_, __) => const SizedBox(width: 10),
                  itemBuilder: (context, i) {
                    final opt = _iconOptions[i];
                    final selected = _selectedIconIndex == i;
                    return GestureDetector(
                      onTap: () => setState(() => _selectedIconIndex = i),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 180),
                        width: 64,
                        decoration: BoxDecoration(
                          color: selected
                              ? theme.colorScheme.primary.withOpacity(0.12)
                              : cardBgColor,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: selected ? theme.colorScheme.primary : borderColor,
                            width: selected ? 1.5 : 1,
                          ),
                        ),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(opt.icon,
                              size: 22,
                              color: selected ? theme.colorScheme.primary : textMutedColor,
                            ),
                            const SizedBox(height: 4),
                            Text(opt.label,
                              style: TextStyle(
                                fontSize: 8,
                                fontWeight: selected ? FontWeight.bold : FontWeight.normal,
                                color: selected ? theme.colorScheme.primary : textMutedColor,
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),
              const SizedBox(height: 22),

              // ── Goal Details ─────────────────────────────────────────────
              _SectionLabel(label: 'Goal Details', textMutedColor: textMutedColor),
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
                      controller: _nameController,
                      textCapitalization: TextCapitalization.words,
                      decoration: InputDecoration(
                        labelText: 'Goal Name',
                        hintText: 'e.g. Buy iPhone 16',
                        prefixIcon: const Icon(Icons.edit_outlined),
                        border: inputBorder,
                        enabledBorder: inputBorder,
                        focusedBorder: focusedBorder,
                      ),
                      validator: (v) => (v == null || v.trim().isEmpty) ? 'Please enter a goal name' : null,
                    ),
                    const SizedBox(height: 14),
                    TextFormField(
                      controller: _amountController,
                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                      decoration: InputDecoration(
                        labelText: 'Target Amount ($currencySymbol)',
                        hintText: '100000',
                        prefixIcon: const Icon(Icons.monetization_on_outlined),
                        border: inputBorder,
                        enabledBorder: inputBorder,
                        focusedBorder: focusedBorder,
                      ),
                      validator: (v) {
                        final val = double.tryParse(v ?? '');
                        if (val == null || val <= 0) return 'Enter a valid target amount';
                        return null;
                      },
                    ),
                    const SizedBox(height: 14),
                    TextFormField(
                      controller: _savingsController,
                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                      decoration: InputDecoration(
                        labelText: 'Already Saved ($currencySymbol)',
                        hintText: '0  (optional)',
                        prefixIcon: const Icon(Icons.savings_outlined),
                        border: inputBorder,
                        enabledBorder: inputBorder,
                        focusedBorder: focusedBorder,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),

              // ── Target Date ──────────────────────────────────────────────
              _SectionLabel(label: 'Target Date (Optional)', textMutedColor: textMutedColor),
              const SizedBox(height: 12),
              GestureDetector(
                onTap: () async {
                  final date = await showDatePicker(
                    context: context,
                    initialDate: _selectedDate ?? DateTime.now().add(const Duration(days: 30)),
                    firstDate: DateTime.now(),
                    lastDate: DateTime(2100),
                  );
                  if (date != null) setState(() => _selectedDate = date);
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                  decoration: BoxDecoration(
                    color: cardBgColor,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: borderColor),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.event_rounded, color: theme.colorScheme.primary, size: 20),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          _selectedDate == null
                              ? 'Tap to set deadline'
                              : DateFormat('dd MMMM yyyy').format(_selectedDate!),
                          style: TextStyle(
                            fontWeight: FontWeight.w600,
                            color: _selectedDate == null ? textMutedColor : null,
                          ),
                        ),
                      ),
                      if (_selectedDate != null)
                        GestureDetector(
                          onTap: () => setState(() => _selectedDate = null),
                          child: Icon(Icons.close_rounded, size: 16, color: textMutedColor),
                        )
                      else
                        Icon(Icons.chevron_right_rounded, size: 18, color: textMutedColor),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 32),

              // ── Save Button ──────────────────────────────────────────────
              ElevatedButton(
                onPressed: _saveGoal,
                style: ElevatedButton.styleFrom(
                  backgroundColor: theme.colorScheme.primary,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  elevation: 0,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                ),
                child: Text(
                  isEditing ? 'Update Goal' : 'Save Goal',
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

  void _saveGoal() {
    if (!_formKey.currentState!.validate()) return;

    final name = _nameController.text.trim();
    final amount = double.tryParse(_amountController.text) ?? 0;
    final savings = double.tryParse(_savingsController.text) ?? 0;

    if (amount <= 0) {
      AppSnackBar.show(context, message: 'Target amount must be greater than 0', isError: true);
      return;
    }

    final goal = GoalEntity(
      id: widget.existingGoal?.id ?? DateTime.now().millisecondsSinceEpoch.toString(),
      name: name,
      targetAmount: amount,
      currentSavings: savings,
      targetDate: _selectedDate,
    );

    final vm = context.read<GoalsViewModel>();
    if (widget.existingGoal == null) {
      vm.addGoal(goal);
    } else {
      vm.updateGoal(goal);
    }

    AppSnackBar.show(context,
      message: widget.existingGoal == null ? 'Goal "$name" created!' : 'Goal "$name" updated!',
      isError: false,
    );
    Navigator.pop(context);
  }
}

class _SectionLabel extends StatelessWidget {
  final String label;
  final Color textMutedColor;
  const _SectionLabel({required this.label, required this.textMutedColor});

  @override
  Widget build(BuildContext context) {
    return Text(
      label.toUpperCase(),
      style: TextStyle(fontSize: 9, fontWeight: FontWeight.bold, color: textMutedColor, letterSpacing: 0.8),
    );
  }
}
