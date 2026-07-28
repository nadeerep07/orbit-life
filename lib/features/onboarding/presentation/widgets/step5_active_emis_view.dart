import 'package:flutter/material.dart';
import '../../domain/entities/onboarding_draft.dart';
import 'salary_waterfall_header_card.dart';

class Step5ActiveEmisView extends StatefulWidget {
  final List<EmiDraftItem> emis;
  final OnboardingDraft draft;
  final bool hasEmis;
  final ValueChanged<bool> onToggleHasEmis;
  final ValueChanged<List<EmiDraftItem>> onEmisUpdated;
  final VoidCallback onContinue;

  const Step5ActiveEmisView({
    super.key,
    required this.emis,
    required this.draft,
    required this.hasEmis,
    required this.onToggleHasEmis,
    required this.onEmisUpdated,
    required this.onContinue,
  });

  @override
  State<Step5ActiveEmisView> createState() => _Step5ActiveEmisViewState();
}

class _Step5ActiveEmisViewState extends State<Step5ActiveEmisView> {
  double get _totalMonthlyEmi => widget.emis.fold<double>(0.0, (sum, e) => sum + e.monthlyAmount);
  double get _totalOutstanding => widget.emis.fold<double>(0.0, (sum, e) => sum + e.outstandingAmount);

  double get _totalIncome {
    return widget.draft.incomes.fold<double>(0.0, (sum, item) {
      if (item.frequency == 'Weekly') return sum + (item.amount * 4);
      if (item.frequency == 'Biweekly') return sum + (item.amount * 2);
      return sum + item.amount;
    });
  }

  double get _monthlySavingsTarget => widget.draft.savingsEntries.fold<double>(0.0, (s, e) => s + e.monthlyContribution);
  double get _recurringExpenses => widget.draft.recurringExpenses.fold<double>(0.0, (s, o) => s + o.amount);

  void _showAddEmiDialog({EmiDraftItem? editItem, int? editIdx}) {
    final titleCtrl = TextEditingController(text: editItem?.title ?? '');
    final bankCtrl = TextEditingController(text: editItem?.bank ?? '');
    final monthlyCtrl = TextEditingController(text: editItem != null ? editItem.monthlyAmount.toStringAsFixed(0) : '');
    final outstandingCtrl = TextEditingController(text: editItem != null ? editItem.outstandingAmount.toStringAsFixed(0) : '');
    final rateCtrl = TextEditingController(text: editItem != null ? editItem.interestRate.toStringAsFixed(1) : '10.5');
    final monthsCtrl = TextEditingController(text: (editItem?.remainingMonths ?? 12).toString());
    final dueDayCtrl = TextEditingController(text: (editItem?.nextDueDateDay ?? 5).toString());
    bool autoReminder = editItem?.autoReminder ?? true;

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
                              color: const Color(0xFFEC4899).withValues(alpha: 0.2),
                              borderRadius: BorderRadius.circular(14),
                            ),
                            child: const Icon(Icons.receipt_long_rounded, color: Color(0xFFF472B6), size: 22),
                          ),
                          const SizedBox(width: 12),
                          Text(
                            editItem == null ? 'Add Priority EMI / Loan' : 'Edit EMI Obligation',
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
                      labelText: 'Loan / EMI Title',
                      hintText: 'e.g. Home Loan, Car EMI, iPhone Loan',
                      hintStyle: const TextStyle(color: Colors.white38, fontSize: 13),
                      labelStyle: const TextStyle(color: Colors.white70),
                      prefixIcon: const Icon(Icons.description_outlined, color: Color(0xFFF472B6), size: 20),
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

                  TextField(
                    controller: bankCtrl,
                    style: const TextStyle(color: Colors.white),
                    decoration: InputDecoration(
                      labelText: 'Lender / Bank Name',
                      hintText: 'e.g. HDFC Bank, ICICI Bank, Bajaj Finserv',
                      hintStyle: const TextStyle(color: Colors.white38, fontSize: 13),
                      labelStyle: const TextStyle(color: Colors.white70),
                      prefixIcon: const Icon(Icons.account_balance_outlined, color: Color(0xFF60A5FA), size: 20),
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

                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: monthlyCtrl,
                          keyboardType: TextInputType.number,
                          style: const TextStyle(color: Colors.white),
                          decoration: InputDecoration(
                            labelText: 'Monthly EMI (₹/mo)',
                            labelStyle: const TextStyle(color: Colors.white70, fontSize: 12),
                            prefixIcon: const Icon(Icons.currency_rupee_rounded, color: Color(0xFFEC4899), size: 18),
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
                          controller: outstandingCtrl,
                          keyboardType: TextInputType.number,
                          style: const TextStyle(color: Colors.white),
                          decoration: InputDecoration(
                            labelText: 'Total Outstanding (₹)',
                            labelStyle: const TextStyle(color: Colors.white70, fontSize: 12),
                            prefixIcon: const Icon(Icons.money_off_rounded, color: Color(0xFFF59E0B), size: 18),
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
                  const SizedBox(height: 14),

                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: rateCtrl,
                          keyboardType: TextInputType.number,
                          style: const TextStyle(color: Colors.white),
                          decoration: InputDecoration(
                            labelText: 'Interest Rate (% p.a.)',
                            labelStyle: const TextStyle(color: Colors.white70, fontSize: 12),
                            prefixIcon: const Icon(Icons.percent_rounded, color: Color(0xFF38BDF8), size: 18),
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
                          controller: monthsCtrl,
                          keyboardType: TextInputType.number,
                          style: const TextStyle(color: Colors.white),
                          decoration: InputDecoration(
                            labelText: 'Remaining Months',
                            labelStyle: const TextStyle(color: Colors.white70, fontSize: 12),
                            prefixIcon: const Icon(Icons.timer_outlined, color: Color(0xFFA855F7), size: 18),
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
                  const SizedBox(height: 14),

                  Container(
                    decoration: BoxDecoration(
                      color: const Color(0xFF0F172A),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: const Color(0xFF26334D)),
                    ),
                    child: SwitchListTile(
                      title: const Text('Enable Auto-Payment Reminders', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Colors.white)),
                      subtitle: const Text('Sends smart notification 3 days before due date', style: TextStyle(fontSize: 11, color: Colors.white54)),
                      value: autoReminder,
                      activeThumbColor: const Color(0xFFEC4899),
                      onChanged: (val) => setBottomSheetState(() => autoReminder = val),
                    ),
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
                              colors: [Color(0xFFDB2777), Color(0xFFEC4899)],
                            ),
                            borderRadius: BorderRadius.circular(14),
                            boxShadow: [
                              BoxShadow(
                                color: const Color(0xFFEC4899).withValues(alpha: 0.35),
                                blurRadius: 12,
                                offset: const Offset(0, 4),
                              ),
                            ],
                          ),
                          child: ElevatedButton(
                            onPressed: () {
                              if (titleCtrl.text.trim().isEmpty) return;
                              final monthly = double.tryParse(monthlyCtrl.text.trim()) ?? 0.0;
                              final outstanding = double.tryParse(outstandingCtrl.text.trim()) ?? 0.0;
                              final rate = double.tryParse(rateCtrl.text.trim()) ?? 10.5;
                              final remaining = int.tryParse(monthsCtrl.text.trim()) ?? 12;
                              final dueDay = int.tryParse(dueDayCtrl.text.trim()) ?? 5;

                              final item = EmiDraftItem(
                                id: editItem?.id ?? DateTime.now().millisecondsSinceEpoch.toString(),
                                title: titleCtrl.text.trim(),
                                bank: bankCtrl.text.trim(),
                                monthlyAmount: monthly,
                                outstandingAmount: outstanding,
                                interestRate: rate,
                                remainingMonths: remaining,
                                nextDueDateDay: dueDay,
                                autoReminder: autoReminder,
                              );

                              final updated = List<EmiDraftItem>.from(widget.emis);
                              if (editIdx != null) {
                                updated[editIdx] = item;
                              } else {
                                updated.add(item);
                              }
                              widget.onEmisUpdated(updated);
                              Navigator.pop(ctx);
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.transparent,
                              shadowColor: Colors.transparent,
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                              padding: const EdgeInsets.symmetric(vertical: 16),
                              foregroundColor: Colors.white,
                            ),
                            child: const Text('Save EMI Obligation', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
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
    final updated = List<EmiDraftItem>.from(widget.emis)..removeAt(index);
    widget.onEmisUpdated(updated);
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Priority 1: Active EMIs & Debt',
            style: TextStyle(
              fontSize: 26,
              fontWeight: FontWeight.w800,
              color: Colors.white,
              letterSpacing: -0.5,
            ),
          ),
          const SizedBox(height: 6),
          const Text(
            'EMIs are Priority 1 deductions subtracted directly from your monthly salary inflow.',
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
            totalEmis: _totalMonthlyEmi,
            monthlySavingsTarget: _monthlySavingsTarget,
            recurringExpenses: _recurringExpenses,
            currentStepFocus: 'emis',
          ),

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
              title: const Text('I have active monthly EMIs or loans', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Colors.white)),
              subtitle: const Text('Toggle off if you are 100% debt-free', style: TextStyle(fontSize: 11, color: Colors.white54)),
              value: widget.hasEmis,
              activeThumbColor: const Color(0xFFEC4899),
              onChanged: (val) => widget.onToggleHasEmis(val),
            ),
          ),

          if (widget.hasEmis) ...[
            const SizedBox(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    'Active Loan EMIs (${widget.emis.length})',
                    style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: Colors.white),
                  ),
                ),
                const SizedBox(width: 8),
                OutlinedButton.icon(
                  onPressed: () => _showAddEmiDialog(),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: const Color(0xFFF472B6),
                    side: const BorderSide(color: Color(0xFFF472B6)),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  icon: const Icon(Icons.add_rounded, size: 18),
                  label: const Text('Add EMI'),
                ),
              ],
            ),
            const SizedBox(height: 12),

            if (widget.emis.isEmpty)
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
                    Icon(Icons.receipt_long_outlined, size: 36, color: Color(0xFF475569)),
                    SizedBox(height: 10),
                    Text(
                      'No EMIs added yet. Tap Add EMI above to input your monthly loan commitments.',
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
                itemCount: widget.emis.length,
                itemBuilder: (ctx, idx) {
                  final e = widget.emis[idx];
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
                            color: const Color(0xFFEC4899).withValues(alpha: 0.2),
                            borderRadius: BorderRadius.circular(14),
                          ),
                          child: const Icon(Icons.receipt_long_rounded, color: Color(0xFFF472B6), size: 22),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                e.title,
                                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: Colors.white),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                '${e.bank} • ${e.remainingMonths} mos remaining @ ${e.interestRate}%',
                                style: const TextStyle(fontSize: 11, color: Color(0xFF94A3B8)),
                              ),
                            ],
                          ),
                        ),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Text(
                              '₹${e.monthlyAmount.toStringAsFixed(0)}/mo',
                              style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 16, color: Color(0xFFF472B6)),
                            ),
                            Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                InkWell(
                                  onTap: () => _showAddEmiDialog(editItem: e, editIdx: idx),
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
