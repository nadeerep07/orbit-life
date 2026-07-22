import 'package:flutter/material.dart';
import '../../domain/entities/onboarding_draft.dart';
import 'salary_waterfall_header_card.dart';

class Step7RecurringExpensesView extends StatefulWidget {
  final List<ObligationDraftItem> recurringExpenses;
  final OnboardingDraft draft;
  final ValueChanged<List<ObligationDraftItem>> onObligationsUpdated;
  final VoidCallback onContinue;

  const Step7RecurringExpensesView({
    super.key,
    required this.recurringExpenses,
    required this.draft,
    required this.onObligationsUpdated,
    required this.onContinue,
  });

  @override
  State<Step7RecurringExpensesView> createState() => _Step7RecurringExpensesViewState();
}

class _Step7RecurringExpensesViewState extends State<Step7RecurringExpensesView> {
  final _presets = [
    {'name': 'House Rent', 'category': 'Housing & Rent', 'amount': 18000.0},
    {'name': 'Groceries & Food', 'category': 'Food & Dining', 'amount': 8000.0},
    {'name': 'Fuel / Vehicle', 'category': 'Transport & Fuel', 'amount': 4000.0},
    {'name': 'Electricity Bill', 'category': 'Utilities & Bills', 'amount': 2500.0},
    {'name': 'Internet & Wifi', 'category': 'Utilities & Bills', 'amount': 1000.0},
    {'name': 'Insurance Premium', 'category': 'Utilities & Bills', 'amount': 3500.0},
    {'name': 'OTT & Subscriptions', 'category': 'Subscriptions', 'amount': 800.0},
    {'name': 'Phone Bill', 'category': 'Utilities & Bills', 'amount': 600.0},
    {'name': 'School / Course Fees', 'category': 'Education', 'amount': 5000.0},
    {'name': 'Medical & Medicines', 'category': 'Health & Medical', 'amount': 2000.0},
  ];

  double get _totalFixedExpenses => widget.recurringExpenses.fold<double>(0.0, (sum, o) => sum + o.amount);

  double get _totalIncome {
    return widget.draft.incomes.fold<double>(0.0, (sum, item) {
      if (item.frequency == 'Weekly') return sum + (item.amount * 4);
      if (item.frequency == 'Biweekly') return sum + (item.amount * 2);
      return sum + item.amount;
    });
  }

  double get _totalEmis => widget.draft.emis.fold<double>(0.0, (s, e) => s + e.monthlyAmount);
  double get _monthlySavingsTarget => widget.draft.savingsEntries.fold<double>(0.0, (s, e) => s + e.monthlyContribution);

  void _addPreset(Map<String, dynamic> p) {
    final item = ObligationDraftItem(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      name: p['name'] as String,
      amount: p['amount'] as double,
      category: p['category'] as String,
    );
    final updated = List<ObligationDraftItem>.from(widget.recurringExpenses)..add(item);
    widget.onObligationsUpdated(updated);
  }

  void _showAddDialog({ObligationDraftItem? editItem, int? editIdx}) {
    final nameCtrl = TextEditingController(text: editItem?.name ?? '');
    final amountCtrl = TextEditingController(text: editItem != null ? editItem.amount.toStringAsFixed(0) : '');
    String category = editItem?.category ?? 'Housing & Rent';
    final dueDayCtrl = TextEditingController(text: (editItem?.dueDay ?? 1).toString());

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setBottomSheetState) {
          final bottomPadding = MediaQuery.of(ctx).viewInsets.bottom;
          return Container(
            padding: EdgeInsets.fromLTRB(24, 16, 24, 24 + bottomPadding),
            decoration: const BoxDecoration(
              color: Color(0xFF151C2C),
              borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
              boxShadow: [
                BoxShadow(color: Colors.black54, blurRadius: 24, offset: Offset(0, -6)),
              ],
            ),
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Center(
                    child: Container(
                      width: 44,
                      height: 5,
                      decoration: BoxDecoration(
                        color: const Color(0xFF334155),
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                  ),
                  const SizedBox(height: 18),

                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              color: const Color(0xFFF59E0B).withValues(alpha: 0.2),
                              borderRadius: BorderRadius.circular(14),
                            ),
                            child: const Icon(Icons.north_east_rounded, color: Color(0xFFFBBF24), size: 22),
                          ),
                          const SizedBox(width: 12),
                          Text(
                            editItem == null ? 'Add Living Expense' : 'Edit Living Expense',
                            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white),
                          ),
                        ],
                      ),
                      IconButton(
                        onPressed: () => Navigator.pop(ctx),
                        icon: const Icon(Icons.close_rounded, color: Colors.white54),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),

                  TextField(
                    controller: nameCtrl,
                    style: const TextStyle(color: Colors.white),
                    decoration: InputDecoration(
                      labelText: 'Expense Name',
                      hintText: 'e.g. House Rent, Groceries, Electricity',
                      hintStyle: const TextStyle(color: Colors.white38, fontSize: 13),
                      labelStyle: const TextStyle(color: Colors.white70),
                      prefixIcon: const Icon(Icons.shopping_bag_outlined, color: Color(0xFFFBBF24), size: 20),
                      filled: true,
                      fillColor: const Color(0xFF0F172A),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(16)),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(16),
                        borderSide: const BorderSide(color: Color(0xFF26334D)),
                      ),
                    ),
                  ),
                  const SizedBox(height: 14),

                  DropdownButtonFormField<String>(
                    initialValue: category,
                    dropdownColor: const Color(0xFF0F172A),
                    style: const TextStyle(color: Colors.white),
                    decoration: InputDecoration(
                      labelText: 'Expense Category',
                      labelStyle: const TextStyle(color: Colors.white70),
                      prefixIcon: const Icon(Icons.category_outlined, color: Color(0xFF60A5FA), size: 20),
                      filled: true,
                      fillColor: const Color(0xFF0F172A),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(16)),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(16),
                        borderSide: const BorderSide(color: Color(0xFF26334D)),
                      ),
                    ),
                    items: [
                      'Housing & Rent',
                      'Food & Dining',
                      'Transport & Fuel',
                      'Utilities & Bills',
                      'Subscriptions',
                      'Education',
                      'Health & Medical',
                      'Shopping',
                      'General',
                    ].map((c) => DropdownMenuItem(value: c, child: Text(c))).toList(),
                    onChanged: (val) {
                      if (val != null) setBottomSheetState(() => category = val);
                    },
                  ),
                  const SizedBox(height: 14),

                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: amountCtrl,
                          keyboardType: TextInputType.number,
                          style: const TextStyle(color: Colors.white),
                          decoration: InputDecoration(
                            labelText: 'Monthly Expense (₹)',
                            labelStyle: const TextStyle(color: Colors.white70, fontSize: 12),
                            prefixIcon: const Icon(Icons.currency_rupee_rounded, color: Color(0xFFFBBF24), size: 18),
                            filled: true,
                            fillColor: const Color(0xFF0F172A),
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(16)),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(16),
                              borderSide: const BorderSide(color: Color(0xFF26334D)),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: TextField(
                          controller: dueDayCtrl,
                          keyboardType: TextInputType.number,
                          style: const TextStyle(color: Colors.white),
                          decoration: InputDecoration(
                            labelText: 'Due Day (1-31)',
                            labelStyle: const TextStyle(color: Colors.white70, fontSize: 12),
                            prefixIcon: const Icon(Icons.calendar_today_rounded, color: Color(0xFF38BDF8), size: 18),
                            filled: true,
                            fillColor: const Color(0xFF0F172A),
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(16)),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(16),
                              borderSide: const BorderSide(color: Color(0xFF26334D)),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 24),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed: () => Navigator.pop(ctx),
                          style: OutlinedButton.styleFrom(
                            side: const BorderSide(color: Color(0xFF334155)),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            foregroundColor: Colors.white70,
                          ),
                          child: const Text('Cancel', style: TextStyle(fontWeight: FontWeight.bold)),
                        ),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Container(
                          decoration: BoxDecoration(
                            gradient: const LinearGradient(
                              colors: [Color(0xFFD97706), Color(0xFFF59E0B)],
                            ),
                            borderRadius: BorderRadius.circular(14),
                            boxShadow: [
                              BoxShadow(
                                color: const Color(0xFFF59E0B).withValues(alpha: 0.35),
                                blurRadius: 12,
                                offset: const Offset(0, 4),
                              ),
                            ],
                          ),
                          child: ElevatedButton(
                            onPressed: () {
                              if (nameCtrl.text.trim().isEmpty) return;
                              final amount = double.tryParse(amountCtrl.text.trim()) ?? 0.0;
                              final dueDay = int.tryParse(dueDayCtrl.text.trim()) ?? 1;

                              final item = ObligationDraftItem(
                                id: editItem?.id ?? DateTime.now().millisecondsSinceEpoch.toString(),
                                name: nameCtrl.text.trim(),
                                amount: amount,
                                category: category,
                                dueDay: dueDay,
                              );

                              final updated = List<ObligationDraftItem>.from(widget.recurringExpenses);
                              if (editIdx != null) {
                                updated[editIdx] = item;
                              } else {
                                updated.add(item);
                              }
                              widget.onObligationsUpdated(updated);
                              Navigator.pop(ctx);
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.transparent,
                              shadowColor: Colors.transparent,
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                              padding: const EdgeInsets.symmetric(vertical: 16),
                              foregroundColor: Colors.white,
                            ),
                            child: const Text('Save Expense', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  void _removeItem(int index) {
    final updated = List<ObligationDraftItem>.from(widget.recurringExpenses)..removeAt(index);
    widget.onObligationsUpdated(updated);
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Priority 3: Living Expenses',
            style: TextStyle(
              fontSize: 26,
              fontWeight: FontWeight.w800,
              color: Colors.white,
              letterSpacing: -0.5,
            ),
          ),
          const SizedBox(height: 6),
          const Text(
            'Add your recurring living expenses (Rent, Food, Fuel, Utilities). These are budgeted out of your remaining spendable fund.',
            style: TextStyle(
              fontSize: 13,
              color: Color(0xFF94A3B8),
              height: 1.4,
            ),
          ),
          const SizedBox(height: 20),

          // Live Salary Waterfall Header Card
          SalaryWaterfallHeaderCard(
            totalIncome: _totalIncome,
            totalEmis: _totalEmis,
            monthlySavingsTarget: _monthlySavingsTarget,
            recurringExpenses: _totalFixedExpenses,
            currentStepFocus: 'expenses',
          ),

          const SizedBox(height: 16),
          const Text('Quick Expense Presets:', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.white70)),
          const SizedBox(height: 8),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: _presets.map((p) {
                return Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: ActionChip(
                    backgroundColor: const Color(0xFF1E293B),
                    side: const BorderSide(color: Color(0xFF334155)),
                    avatar: const Icon(Icons.add_rounded, size: 14, color: Color(0xFFFBBF24)),
                    label: Text(p['name'] as String, style: const TextStyle(fontSize: 11, color: Colors.white, fontWeight: FontWeight.w600)),
                    onPressed: () => _addPreset(p),
                  ),
                );
              }).toList(),
            ),
          ),
          const SizedBox(height: 24),

          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  'Living Expenses (${widget.recurringExpenses.length})',
                  style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: Colors.white),
                ),
              ),
              const SizedBox(width: 8),
              OutlinedButton.icon(
                onPressed: () => _showAddDialog(),
                style: OutlinedButton.styleFrom(
                  foregroundColor: const Color(0xFFFBBF24),
                  side: const BorderSide(color: Color(0xFFFBBF24)),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                icon: const Icon(Icons.add_rounded, size: 18),
                label: const Text('Add Expense'),
              ),
            ],
          ),
          const SizedBox(height: 12),

          if (widget.recurringExpenses.isEmpty)
            Container(
              padding: const EdgeInsets.all(28),
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: const Color(0xFF151C2C),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: const Color(0xFF26334D)),
              ),
              child: const Column(
                children: [
                  Icon(Icons.north_east_rounded, size: 36, color: Color(0xFF475569)),
                  SizedBox(height: 10),
                  Text(
                    'No expenses added yet. Tap quick presets above to add rent, food, or utility commitments.',
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 12, color: Color(0xFF94A3B8), height: 1.4),
                  ),
                ],
              ),
            )
          else
            ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: widget.recurringExpenses.length,
              itemBuilder: (ctx, idx) {
                final item = widget.recurringExpenses[idx];
                return Container(
                  margin: const EdgeInsets.only(bottom: 10),
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: const Color(0xFF151C2C),
                    borderRadius: BorderRadius.circular(18),
                    border: Border.all(color: const Color(0xFF26334D)),
                  ),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF59E0B).withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: const Icon(Icons.north_east_rounded, color: Color(0xFFFBBF24), size: 22),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              item.name,
                              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: Colors.white),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              '${item.category} • Due Day ${item.dueDay}',
                              style: const TextStyle(fontSize: 11, color: Color(0xFF94A3B8)),
                            ),
                          ],
                        ),
                      ),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Text(
                            '₹${item.amount.toStringAsFixed(0)}/mo',
                            style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 16, color: Color(0xFFFBBF24)),
                          ),
                          Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              InkWell(
                                onTap: () => _showAddDialog(editItem: item, editIdx: idx),
                                child: const Padding(
                                  padding: EdgeInsets.all(4),
                                  child: Icon(Icons.edit_outlined, size: 16, color: Color(0xFF60A5FA)),
                                ),
                              ),
                              const SizedBox(width: 4),
                              InkWell(
                                onTap: () => _removeItem(idx),
                                child: const Padding(
                                  padding: EdgeInsets.all(4),
                                  child: Icon(Icons.delete_outline_rounded, size: 16, color: Colors.redAccent),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ],
                  ),
                );
              },
            ),
        ],
      ),
    );
  }
}
