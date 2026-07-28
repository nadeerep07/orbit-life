import 'dart:math';
import 'package:flutter/material.dart';
import '../../domain/entities/onboarding_draft.dart';
import 'salary_waterfall_header_card.dart';

class StepSavingsView extends StatefulWidget {
  final List<SavingsDraftItem> savingsEntries;
  final List<FdLotDraftItem> fdLots;
  final OnboardingDraft? draft;
  final bool hasSavings;
  final ValueChanged<bool> onToggleHasSavings;
  final ValueChanged<List<SavingsDraftItem>> onSavingsUpdated;
  final ValueChanged<double>? onTargetSavingsChanged;
  final VoidCallback onContinue;

  const StepSavingsView({
    super.key,
    required this.savingsEntries,
    this.fdLots = const [],
    this.draft,
    required this.hasSavings,
    required this.onToggleHasSavings,
    required this.onSavingsUpdated,
    this.onTargetSavingsChanged,
    required this.onContinue,
  });

  @override
  State<StepSavingsView> createState() => _StepSavingsViewState();
}

class _StepSavingsViewState extends State<StepSavingsView> {
  late TextEditingController _targetSavingsCtrl;

  final _presets = [
    {'title': 'Emergency Cash Reserve', 'type': 'Emergency Cash', 'amount': 30000.0, 'monthly': 2000.0},
    {'title': 'Gold & SGB Holdings', 'type': 'Gold / SGB', 'amount': 40000.0, 'monthly': 1500.0},
    {'title': 'Mutual Fund SIP Savings', 'type': 'Mutual Funds / SIP', 'amount': 100000.0, 'monthly': 10000.0},
    {'title': 'Additional Credit Card FD', 'type': 'Credit Card FD', 'amount': 25000.0, 'monthly': 5000.0},
  ];

  @override
  void initState() {
    super.initState();
    final initialTarget = widget.draft?.targetMonthlySavings != null && widget.draft!.targetMonthlySavings > 0
        ? widget.draft!.targetMonthlySavings
        : _totalMonthlySavingsOutflow;
    _targetSavingsCtrl = TextEditingController(text: initialTarget > 0 ? initialTarget.toStringAsFixed(0) : '');
  }

  @override
  void dispose() {
    _targetSavingsCtrl.dispose();
    super.dispose();
  }

  double get _totalFdAmount => widget.fdLots.fold<double>(0.0, (sum, f) => sum + (f.currentValue ?? f.principal));
  double get _customSavingsAccumulated => widget.savingsEntries.fold<double>(0.0, (sum, s) => sum + s.amount);
  double get _totalSavingsAccumulated => _totalFdAmount + _customSavingsAccumulated;
  double get _totalMonthlySavingsOutflow => widget.savingsEntries.fold<double>(0.0, (sum, s) => sum + s.monthlyContribution);

  double get _totalMonthlyIncome {
    if (widget.draft == null) return 0.0;
    return widget.draft!.incomes.fold<double>(0.0, (sum, item) {
      if (item.frequency == 'Weekly') return sum + (item.amount * 4);
      if (item.frequency == 'Biweekly') return sum + (item.amount * 2);
      return sum + item.amount;
    });
  }

  double get _effectiveMonthlySavingsGoal {
    final userSetTarget = double.tryParse(_targetSavingsCtrl.text.trim()) ?? 0.0;
    return max(userSetTarget, _totalMonthlySavingsOutflow);
  }

  void _addPreset(Map<String, dynamic> p) {
    final item = SavingsDraftItem(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      title: p['title'] as String,
      storageType: p['type'] as String,
      amount: p['amount'] as double,
      monthlyContribution: p['monthly'] as double,
    );
    final updated = List<SavingsDraftItem>.from(widget.savingsEntries)..add(item);
    widget.onSavingsUpdated(updated);
  }

  void _showAddDialog({SavingsDraftItem? editItem, int? editIdx}) {
    final titleCtrl = TextEditingController(text: editItem?.title ?? '');
    final amountCtrl = TextEditingController(text: editItem != null ? editItem.amount.toStringAsFixed(0) : '');
    final monthlyCtrl = TextEditingController(text: editItem != null ? editItem.monthlyContribution.toStringAsFixed(0) : '0');
    String type = editItem?.storageType ?? 'Emergency Cash';

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
                            child: const Icon(Icons.savings_rounded, color: Color(0xFF34D399), size: 22),
                          ),
                          const SizedBox(width: 12),
                          Text(
                            editItem == null ? 'Add Savings Storage Vehicle' : 'Edit Savings Vehicle',
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
                    controller: titleCtrl,
                    style: const TextStyle(color: Colors.white),
                    decoration: InputDecoration(
                      labelText: 'Savings Storage Name',
                      hintText: 'e.g. Liquid Cash, SGB Gold, Mutual Fund SIP',
                      hintStyle: const TextStyle(color: Colors.white38, fontSize: 13),
                      labelStyle: const TextStyle(color: Colors.white70),
                      prefixIcon: const Icon(Icons.savings_outlined, color: Color(0xFF34D399), size: 20),
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
                    initialValue: type,
                    dropdownColor: const Color(0xFF0F172A),
                    style: const TextStyle(color: Colors.white),
                    decoration: InputDecoration(
                      labelText: 'Storage Vehicle / Method',
                      labelStyle: const TextStyle(color: Colors.white70),
                      prefixIcon: const Icon(Icons.account_balance_wallet_outlined, color: Color(0xFF60A5FA), size: 20),
                      filled: true,
                      fillColor: const Color(0xFF0F172A),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(16)),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(16),
                        borderSide: const BorderSide(color: Color(0xFF26334D)),
                      ),
                    ),
                    items: [
                      'Credit Card FD',
                      'Bank FD',
                      'Savings Account',
                      'Emergency Cash',
                      'Gold / SGB',
                      'Mutual Funds / SIP',
                      'Custom Vehicle',
                    ].map((t) => DropdownMenuItem(value: t, child: Text(t))).toList(),
                    onChanged: (val) {
                      if (val != null) setBottomSheetState(() => type = val);
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
                            labelText: 'Accumulated Balance (₹)',
                            labelStyle: const TextStyle(color: Colors.white70, fontSize: 12),
                            prefixIcon: const Icon(Icons.currency_rupee_rounded, color: Color(0xFF10B981), size: 18),
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
                          controller: monthlyCtrl,
                          keyboardType: TextInputType.number,
                          style: const TextStyle(color: Colors.white),
                          decoration: InputDecoration(
                            labelText: 'Monthly Savings SIP (₹/mo)',
                            labelStyle: const TextStyle(color: Colors.white70, fontSize: 12),
                            prefixIcon: const Icon(Icons.repeat_rounded, color: Color(0xFF60A5FA), size: 18),
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
                              if (titleCtrl.text.trim().isEmpty) return;
                              final amount = double.tryParse(amountCtrl.text.trim()) ?? 0.0;
                              final monthly = double.tryParse(monthlyCtrl.text.trim()) ?? 0.0;

                              final item = SavingsDraftItem(
                                id: editItem?.id ?? DateTime.now().millisecondsSinceEpoch.toString(),
                                title: titleCtrl.text.trim(),
                                storageType: type,
                                amount: amount,
                                monthlyContribution: monthly,
                              );

                              final updated = List<SavingsDraftItem>.from(widget.savingsEntries);
                              if (editIdx != null) {
                                updated[editIdx] = item;
                              } else {
                                updated.add(item);
                              }
                              widget.onSavingsUpdated(updated);
                              Navigator.pop(ctx);
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.transparent,
                              shadowColor: Colors.transparent,
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                              padding: const EdgeInsets.symmetric(vertical: 16),
                              foregroundColor: Colors.white,
                            ),
                            child: const Text('Save Savings Item', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
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
    final updated = List<SavingsDraftItem>.from(widget.savingsEntries)..removeAt(index);
    widget.onSavingsUpdated(updated);
  }

  void _onTargetChanged(String text) {
    final val = double.tryParse(text.trim()) ?? 0.0;
    if (widget.onTargetSavingsChanged != null) {
      widget.onTargetSavingsChanged!(val);
    }
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Savings & Storage Vehicles',
            style: TextStyle(
              fontSize: 26,
              fontWeight: FontWeight.w800,
              color: Colors.white,
              letterSpacing: -0.5,
            ),
          ),
          const SizedBox(height: 6),
          const Text(
            'Set your Priority 2 monthly savings target and specify storage methods to compute dynamic monthly budget limits.',
            style: TextStyle(
              fontSize: 13,
              color: Color(0xFF94A3B8),
              height: 1.4,
            ),
          ),
          const SizedBox(height: 20),

          // Live Salary Waterfall Header Card
          if (widget.draft != null)
            SalaryWaterfallHeaderCard(
              totalIncome: _totalMonthlyIncome,
              totalEmis: widget.draft!.emis.fold(0.0, (s, e) => s + e.monthlyAmount),
              monthlySavingsTarget: _effectiveMonthlySavingsGoal,
              recurringExpenses: widget.draft!.recurringExpenses.fold(0.0, (s, o) => s + o.amount),
              currentStepFocus: 'savings',
            ),

          // Priority 2 Monthly Savings Goal Commitment Card
          Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              color: const Color(0xFF151C2C),
              borderRadius: BorderRadius.circular(22),
              border: Border.all(color: const Color(0xFF3B82F6).withValues(alpha: 0.5)),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF3B82F6).withValues(alpha: 0.15),
                  blurRadius: 16,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Row(
                  children: [
                    Icon(Icons.savings_rounded, color: Color(0xFF60A5FA), size: 20),
                    SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Priority 2: Monthly Savings Goal (SIP / Reserve)',
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Colors.white),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                const Text(
                  'This amount is deducted from your salary right after EMIs before living expenses are calculated.',
                  style: TextStyle(fontSize: 11, color: Color(0xFF94A3B8)),
                ),
                const SizedBox(height: 14),

                TextField(
                  controller: _targetSavingsCtrl,
                  keyboardType: TextInputType.number,
                  style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
                  decoration: InputDecoration(
                    hintText: 'e.g. 5000',
                    hintStyle: const TextStyle(color: Colors.white38, fontSize: 16),
                    prefixIcon: const Icon(Icons.currency_rupee_rounded, color: Color(0xFF60A5FA)),
                    suffixText: '/ month',
                    suffixStyle: const TextStyle(color: Colors.white70, fontSize: 12, fontWeight: FontWeight.bold),
                    filled: true,
                    fillColor: const Color(0xFF0F172A),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                      borderSide: const BorderSide(color: Color(0xFF26334D)),
                    ),
                  ),
                  onChanged: _onTargetChanged,
                ),
                const SizedBox(height: 12),

                // Quick Percentage Chips based on Monthly Income
                if (_totalMonthlyIncome > 0) ...[
                  const Text('Quick Allocation Chips:', style: TextStyle(fontSize: 11, color: Colors.white54, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 6),
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: [10, 15, 20, 25, 30].map((pct) {
                        final targetAmt = (_totalMonthlyIncome * (pct / 100)).roundToDouble();
                        final isSelected = (double.tryParse(_targetSavingsCtrl.text) ?? 0.0) == targetAmt;
                        return Padding(
                          padding: const EdgeInsets.only(right: 8),
                          child: ActionChip(
                            backgroundColor: isSelected ? const Color(0xFF2563EB) : const Color(0xFF1E293B),
                            side: BorderSide(color: isSelected ? const Color(0xFF60A5FA) : const Color(0xFF334155)),
                            label: Text(
                              '$pct% (₹${targetAmt.toStringAsFixed(0)})',
                              style: TextStyle(
                                fontSize: 11,
                                color: isSelected ? Colors.white : Colors.white70,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            onPressed: () {
                              setState(() {
                                _targetSavingsCtrl.text = targetAmt.toStringAsFixed(0);
                              });
                              _onTargetChanged(targetAmt.toStringAsFixed(0));
                            },
                          ),
                        );
                      }).toList(),
                    ),
                  ),
                ],
              ],
            ),
          ),

          const SizedBox(height: 16),

          // Smart No-Double-Counting Notice Banner
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: const Color(0xFF1E293B),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: const Color(0xFF3B82F6).withValues(alpha: 0.4)),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: const Color(0xFF3B82F6).withValues(alpha: 0.2),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.info_outline_rounded, color: Color(0xFF60A5FA), size: 20),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Zero Double-Counting Protection',
                        style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.white),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        _totalFdAmount > 0
                            ? 'Your ₹${_totalFdAmount.toStringAsFixed(0)} of imported FDs from Step 5 are automatically included in savings! No need to re-enter them.'
                            : 'No need to re-enter FDs already imported in earlier steps. Only add extra savings vehicles here.',
                        style: const TextStyle(fontSize: 11, color: Colors.white70, height: 1.3),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),

          // Enable Switch Card
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              color: const Color(0xFF151C2C),
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: const Color(0xFF26334D)),
            ),
            child: SwitchListTile(
              contentPadding: EdgeInsets.zero,
              title: const Text('Configure additional savings vehicles', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Colors.white)),
              subtitle: const Text('Toggle off if imported FDs are your only savings', style: TextStyle(fontSize: 11, color: Colors.white54)),
              value: widget.hasSavings,
              activeThumbColor: const Color(0xFF3B82F6),
              onChanged: (val) => widget.onToggleHasSavings(val),
            ),
          ),

          if (widget.hasSavings) ...[
            const SizedBox(height: 20),

            // Live Savings Summary Dashboard Card
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(22),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF064E3B), Color(0xFF047857), Color(0xFF10B981)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(24),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF10B981).withValues(alpha: 0.35),
                    blurRadius: 20,
                    offset: const Offset(0, 10),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'TOTAL COMBINED SAVINGS RESERVES',
                        style: TextStyle(color: Colors.white70, fontSize: 10, fontWeight: FontWeight.bold, letterSpacing: 1.2),
                      ),
                      Icon(Icons.shield_rounded, color: Colors.white70, size: 22),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '₹${_totalSavingsAccumulated.toStringAsFixed(0)}',
                    style: const TextStyle(color: Colors.white, fontSize: 32, fontWeight: FontWeight.w800),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Auto-Linked FDs: ₹${_totalFdAmount.toStringAsFixed(0)}',
                        style: const TextStyle(color: Colors.white70, fontSize: 11),
                      ),
                      Text(
                        'Monthly SIP: ₹${_effectiveMonthlySavingsGoal.toStringAsFixed(0)}/mo',
                        style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),
            const Text('Quick Add Extra Vehicles:', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.white70)),
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
                      label: Text(p['title'] as String, style: const TextStyle(fontSize: 11, color: Colors.white, fontWeight: FontWeight.w600)),
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
                    'Additional Vehicles (${widget.savingsEntries.length})',
                    style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: Colors.white),
                  ),
                ),
                const SizedBox(width: 8),
                OutlinedButton.icon(
                  onPressed: () => _showAddDialog(),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: const Color(0xFF34D399),
                    side: const BorderSide(color: Color(0xFF34D399)),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  icon: const Icon(Icons.add_rounded, size: 18),
                  label: const Text('Add Vehicle'),
                ),
              ],
            ),
            const SizedBox(height: 12),

            if (widget.savingsEntries.isEmpty)
              Container(
                padding: const EdgeInsets.all(24),
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: const Color(0xFF151C2C),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: const Color(0xFF26334D)),
                ),
                child: Column(
                  children: [
                    const Icon(Icons.check_circle_outline_rounded, size: 36, color: Color(0xFF34D399)),
                    const SizedBox(height: 8),
                    Text(
                      _totalFdAmount > 0
                          ? 'Your Step 5 FDs (₹${_totalFdAmount.toStringAsFixed(0)}) are already counted as savings!\nAdd extra non-FD vehicles above if you have liquid cash or SIPs.'
                          : 'No extra savings vehicles added. Tap a quick vehicle above if you have liquid cash reserves or SIP targets.',
                      textAlign: TextAlign.center,
                      style: const TextStyle(fontSize: 12, color: Color(0xFF94A3B8), height: 1.4),
                    ),
                  ],
                ),
              )
            else
              ListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: widget.savingsEntries.length,
                itemBuilder: (ctx, idx) {
                  final s = widget.savingsEntries[idx];
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
                          child: const Icon(Icons.savings_rounded, color: Color(0xFF34D399), size: 22),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                s.title,
                                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: Colors.white),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                '${s.storageType}${s.monthlyContribution > 0 ? " • ₹${s.monthlyContribution.toStringAsFixed(0)}/mo SIP" : ""}',
                                style: const TextStyle(fontSize: 11, color: Color(0xFF94A3B8)),
                              ),
                            ],
                          ),
                        ),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Text(
                              '₹${s.amount.toStringAsFixed(0)}',
                              style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 16, color: Color(0xFF34D399)),
                            ),
                            Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                InkWell(
                                  onTap: () => _showAddDialog(editItem: s, editIdx: idx),
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
        ],
      ),
    );
  }
}
