import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../domain/entities/goal_entity.dart';
import '../theme/app_theme.dart';
import '../viewmodels/goals_view_model.dart';

class AddGoalScreen extends StatefulWidget {
  final GoalEntity? existingGoal;
  const AddGoalScreen({super.key, this.existingGoal});

  @override
  State<AddGoalScreen> createState() => _AddGoalScreenState();
}

class _AddGoalScreenState extends State<AddGoalScreen> {
  final _nameController = TextEditingController();
  final _amountController = TextEditingController();
  final _savingsController = TextEditingController();
  DateTime? _selectedDate;

  @override
  void initState() {
    super.initState();
    if (widget.existingGoal != null) {
      final g = widget.existingGoal!;
      _nameController.text = g.name;
      _amountController.text = g.targetAmount.toString();
      _savingsController.text = g.currentSavings.toString();
      _selectedDate = g.targetDate;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.existingGoal == null ? 'Add Goal' : 'Edit Goal'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            IOSCard(
              child: Column(
                children: [
                  TextField(
                    controller: _nameController,
                    decoration: const InputDecoration(
                      labelText: 'Goal Name',
                      hintText: 'e.g. Buy iPhone',
                    ),
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: _amountController,
                    keyboardType: const TextInputType.numberWithOptions(
                      decimal: true,
                    ),
                    decoration: const InputDecoration(
                      labelText: 'Target Amount (₹)',
                      hintText: '120000',
                    ),
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: _savingsController,
                    keyboardType: const TextInputType.numberWithOptions(
                      decimal: true,
                    ),
                    decoration: const InputDecoration(
                      labelText: 'Current Savings (₹)',
                      hintText: '0',
                    ),
                  ),
                  const SizedBox(height: 16),
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    title: const Text('Target Date (Optional)'),
                    trailing: Text(
                      _selectedDate == null
                          ? 'Select'
                          : DateFormat('MMM yyyy').format(_selectedDate!),
                      style: TextStyle(
                        color: Theme.of(context).colorScheme.primary,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    onTap: () async {
                      final date = await showDatePicker(
                        context: context,
                        initialDate: _selectedDate ?? DateTime.now(),
                        firstDate: DateTime.now(),
                        lastDate: DateTime(2100),
                      );
                      if (date != null) setState(() => _selectedDate = date);
                    },
                  ),
                  if (_selectedDate != null)
                    TextButton(
                      onPressed: () => setState(() => _selectedDate = null),
                      child: const Text('Clear Date'),
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
                onPressed: _saveGoal,
                child: Text(
                  widget.existingGoal == null ? 'Save Goal' : 'Update Goal',
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

  void _saveGoal() {
    final name = _nameController.text.trim();
    final amount = double.tryParse(_amountController.text) ?? 0;
    final savings = double.tryParse(_savingsController.text) ?? 0;

    if (name.isEmpty) {
      _showError('Please enter a goal name');
      return;
    }
    if (amount <= 0) {
      _showError('Target amount must be greater than 0');
      return;
    }

    final goal = GoalEntity(
      id:
          widget.existingGoal?.id ??
          DateTime.now().millisecondsSinceEpoch.toString(),
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

    Navigator.pop(context);
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
