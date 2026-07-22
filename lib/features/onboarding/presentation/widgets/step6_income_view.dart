import 'package:flutter/material.dart';
import '../../domain/entities/onboarding_draft.dart';
import 'salary_waterfall_header_card.dart';

class Step6IncomeView extends StatefulWidget {
  final List<IncomeDraftItem> incomes;
  final OnboardingDraft draft;
  final ValueChanged<List<IncomeDraftItem>> onIncomesUpdated;
  final VoidCallback onContinue;

  const Step6IncomeView({
    super.key,
    required this.incomes,
    required this.draft,
    required this.onIncomesUpdated,
    required this.onContinue,
  });

  @override
  State<Step6IncomeView> createState() => _Step6IncomeViewState();
}

class _Step6IncomeViewState extends State<Step6IncomeView> {
  final _presets = [
    {'name': 'Monthly Salary', 'category': 'Salary', 'amount': 50000.0, 'freq': 'Monthly'},
    {'name': 'Freelance Income', 'category': 'Freelance', 'amount': 25000.0, 'freq': 'Monthly'},
    {'name': 'Business Revenue', 'category': 'Business', 'amount': 50000.0, 'freq': 'Monthly'},
    {'name': 'Rental Income', 'category': 'Rental', 'amount': 15000.0, 'freq': 'Monthly'},
    {'name': 'Dividend / Interest', 'category': 'Interest', 'amount': 5000.0, 'freq': 'Monthly'},
  ];

  double get _totalMonthlyIncome {
    return widget.incomes.fold<double>(0.0, (sum, item) {
      if (item.frequency == 'Weekly') return sum + (item.amount * 4);
      if (item.frequency == 'Biweekly') return sum + (item.amount * 2);
      return sum + item.amount;
    });
  }

  double get _totalEmis => widget.draft.emis.fold<double>(0.0, (s, e) => s + e.monthlyAmount);
  double get _monthlySavingsTarget => widget.draft.savingsEntries.fold<double>(0.0, (s, e) => s + e.monthlyContribution);
  double get _recurringExpenses => widget.draft.recurringExpenses.fold<double>(0.0, (s, o) => s + o.amount);

  void _addPreset(Map<String, dynamic> p) {
    final item = IncomeDraftItem(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      sourceName: p['name'] as String,
      amount: p['amount'] as double,
      category: p['category'] as String,
      frequency: p['freq'] as String,
    );
    final updated = List<IncomeDraftItem>.from(widget.incomes)..add(item);
    widget.onIncomesUpdated(updated);
  }

  void _showAddIncomeDialog({IncomeDraftItem? editItem, int? editIdx}) {
    final nameCtrl = TextEditingController(text: editItem?.sourceName ?? '');
    final amountCtrl = TextEditingController(text: editItem != null ? editItem.amount.toStringAsFixed(0) : '');
    String category = editItem?.category ?? 'Salary';
    String freq = editItem?.frequency ?? 'Monthly';

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
                              color: const Color(0xFF10B981).withValues(alpha: 0.2),
                              borderRadius: BorderRadius.circular(14),
                            ),
                            child: const Icon(Icons.south_west_rounded, color: Color(0xFF34D399), size: 22),
                          ),
                          const SizedBox(width: 12),
                          Text(
                            editItem == null ? 'Add Income Inflow' : 'Edit Income Inflow',
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
                      labelText: 'Income Source Name',
                      hintText: 'e.g. Primary Salary, Freelance Tech',
                      hintStyle: const TextStyle(color: Colors.white38, fontSize: 13),
                      labelStyle: const TextStyle(color: Colors.white70),
                      prefixIcon: const Icon(Icons.work_outline_rounded, color: Color(0xFF34D399), size: 20),
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
                      labelText: 'Income Category',
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
                      'Salary',
                      'Freelance',
                      'Business',
                      'Rental',
                      'Interest',
                      'Dividends',
                      'Other',
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
                            labelText: 'Amount (₹)',
                            labelStyle: const TextStyle(color: Colors.white70, fontSize: 12),
                            prefixIcon: const Icon(Icons.currency_rupee_rounded, color: Color(0xFF34D399), size: 18),
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
                        child: DropdownButtonFormField<String>(
                          initialValue: freq,
                          dropdownColor: const Color(0xFF0F172A),
                          style: const TextStyle(color: Colors.white),
                          decoration: InputDecoration(
                            labelText: 'Frequency',
                            labelStyle: const TextStyle(color: Colors.white70, fontSize: 12),
                            prefixIcon: const Icon(Icons.repeat_rounded, color: Color(0xFF38BDF8), size: 18),
                            filled: true,
                            fillColor: const Color(0xFF0F172A),
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(16)),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(16),
                              borderSide: const BorderSide(color: Color(0xFF26334D)),
                            ),
                          ),
                          items: ['Monthly', 'Weekly', 'Biweekly', 'Yearly'].map((f) => DropdownMenuItem(value: f, child: Text(f))).toList(),
                          onChanged: (val) {
                            if (val != null) setBottomSheetState(() => freq = val);
                          },
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
                              colors: [Color(0xFF059669), Color(0xFF10B981)],
                            ),
                            borderRadius: BorderRadius.circular(14),
                            boxShadow: [
                              BoxShadow(
                                color: const Color(0xFF10B981).withValues(alpha: 0.35),
                                blurRadius: 12,
                                offset: const Offset(0, 4),
                              ),
                            ],
                          ),
                          child: ElevatedButton(
                            onPressed: () {
                              if (nameCtrl.text.trim().isEmpty) return;
                              final amount = double.tryParse(amountCtrl.text.trim()) ?? 0.0;

                              final item = IncomeDraftItem(
                                id: editItem?.id ?? DateTime.now().millisecondsSinceEpoch.toString(),
                                sourceName: nameCtrl.text.trim(),
                                amount: amount,
                                category: category,
                                frequency: freq,
                              );

                              final updated = List<IncomeDraftItem>.from(widget.incomes);
                              if (editIdx != null) {
                                updated[editIdx] = item;
                              } else {
                                updated.add(item);
                              }
                              widget.onIncomesUpdated(updated);
                              Navigator.pop(ctx);
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.transparent,
                              shadowColor: Colors.transparent,
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                              padding: const EdgeInsets.symmetric(vertical: 16),
                              foregroundColor: Colors.white,
                            ),
                            child: const Text('Save Inflow', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
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
    final updated = List<IncomeDraftItem>.from(widget.incomes)..removeAt(index);
    widget.onIncomesUpdated(updated);
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Monthly Inflow Pool',
            style: TextStyle(
              fontSize: 26,
              fontWeight: FontWeight.w800,
              color: Colors.white,
              letterSpacing: -0.5,
            ),
          ),
          const SizedBox(height: 6),
          const Text(
            'Specify your monthly salary and income inflows. This establishes your financial waterfall budget base.',
            style: TextStyle(
              fontSize: 13,
              color: Color(0xFF94A3B8),
              height: 1.4,
            ),
          ),
          const SizedBox(height: 20),

          // Live Salary Waterfall Header Card
          SalaryWaterfallHeaderCard(
            totalIncome: _totalMonthlyIncome,
            totalEmis: _totalEmis,
            monthlySavingsTarget: _monthlySavingsTarget,
            recurringExpenses: _recurringExpenses,
            currentStepFocus: 'income',
          ),

          const SizedBox(height: 16),
          const Text('Quick Income Presets:', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.white70)),
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
                    avatar: const Icon(Icons.add_rounded, size: 14, color: Color(0xFF34D399)),
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
                  'Inflow Sources (${widget.incomes.length})',
                  style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: Colors.white),
                ),
              ),
              const SizedBox(width: 8),
              OutlinedButton.icon(
                onPressed: () => _showAddIncomeDialog(),
                style: OutlinedButton.styleFrom(
                  foregroundColor: const Color(0xFF34D399),
                  side: const BorderSide(color: Color(0xFF34D399)),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                icon: const Icon(Icons.add_rounded, size: 18),
                label: const Text('Add Income'),
              ),
            ],
          ),
          const SizedBox(height: 12),

          if (widget.incomes.isEmpty)
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
                  Icon(Icons.south_west_rounded, size: 36, color: Color(0xFF475569)),
                  SizedBox(height: 10),
                  Text(
                    'No income sources added yet. Tap quick presets above or add your monthly salary.',
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
              itemCount: widget.incomes.length,
              itemBuilder: (ctx, idx) {
                final item = widget.incomes[idx];
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
                          color: const Color(0xFF10B981).withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: const Icon(Icons.south_west_rounded, color: Color(0xFF34D399), size: 22),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              item.sourceName,
                              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: Colors.white),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              '${item.category} • ${item.frequency}',
                              style: const TextStyle(fontSize: 11, color: Color(0xFF94A3B8)),
                            ),
                          ],
                        ),
                      ),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Text(
                            '₹${item.amount.toStringAsFixed(0)}',
                            style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 16, color: Color(0xFF34D399)),
                          ),
                          Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              InkWell(
                                onTap: () => _showAddIncomeDialog(editItem: item, editIdx: idx),
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
