import 'package:flutter/material.dart';
import '../../domain/entities/onboarding_draft.dart';

class Step8InvestmentsView extends StatefulWidget {
  final List<InvestmentDraftItem> investments;
  final bool hasInvestments;
  final ValueChanged<bool> onToggleHasInvestments;
  final ValueChanged<List<InvestmentDraftItem>> onInvestmentsUpdated;
  final VoidCallback onContinue;

  const Step8InvestmentsView({
    super.key,
    required this.investments,
    required this.hasInvestments,
    required this.onToggleHasInvestments,
    required this.onInvestmentsUpdated,
    required this.onContinue,
  });

  @override
  State<Step8InvestmentsView> createState() => _Step8InvestmentsViewState();
}

class _Step8InvestmentsViewState extends State<Step8InvestmentsView> {

  final _presets = [
    {'title': 'Nifty 50 Index Mutual Fund', 'type': 'Mutual Funds', 'amount': 150000.0, 'rate': 13.5},
    {'title': 'Bluechip Stocks', 'type': 'Stocks', 'amount': 75000.0, 'rate': 15.0},
    {'title': 'Sovereign Gold Bond', 'type': 'Gold', 'amount': 50000.0, 'rate': 9.0},
    {'title': 'Public Provident Fund (PPF)', 'type': 'PF', 'amount': 200000.0, 'rate': 7.1},
    {'title': 'National Pension Scheme (NPS)', 'type': 'NPS', 'amount': 100000.0, 'rate': 10.0},
    {'title': 'Recurring Deposit (RD)', 'type': 'Recurring Deposits', 'amount': 30000.0, 'rate': 6.8},
  ];

  double get _totalInvestmentsValue => widget.investments.fold<double>(0.0, (sum, i) => sum + i.amount);

  void _addPreset(Map<String, dynamic> p) {
    final item = InvestmentDraftItem(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      title: p['title'] as String,
      type: p['type'] as String,
      amount: p['amount'] as double,
      returnsRate: p['rate'] as double,
    );
    final updated = List<InvestmentDraftItem>.from(widget.investments)..add(item);
    widget.onInvestmentsUpdated(updated);
  }

  void _showAddDialog({InvestmentDraftItem? editItem, int? editIdx}) {
    final titleCtrl = TextEditingController(text: editItem?.title ?? '');
    final amountCtrl = TextEditingController(text: editItem != null ? editItem.amount.toStringAsFixed(0) : '');
    final rateCtrl = TextEditingController(text: editItem != null ? editItem.returnsRate.toStringAsFixed(1) : '12.0');
    String type = editItem?.type ?? 'Mutual Funds';

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(22)),
          title: Text(editItem == null ? 'Add Investment' : 'Edit Investment'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: titleCtrl,
                  decoration: const InputDecoration(labelText: 'Investment Name (e.g. Flexi Cap MF)', border: OutlineInputBorder()),
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<String>(
                  value: type,
                  decoration: const InputDecoration(labelText: 'Type', border: OutlineInputBorder()),
                  items: [
                    'Mutual Funds',
                    'Stocks',
                    'Gold',
                    'Crypto',
                    'PF',
                    'NPS',
                    'FD',
                    'Recurring Deposits',
                    'Cash Reserve',
                  ].map((t) => DropdownMenuItem(value: t, child: Text(t))).toList(),
                  onChanged: (val) {
                    if (val != null) setDialogState(() => type = val);
                  },
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: amountCtrl,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(labelText: 'Current Portfolio Amount (₹)', border: OutlineInputBorder()),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: rateCtrl,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(labelText: 'Expected Return Rate (% p.a.)', border: OutlineInputBorder()),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
            ElevatedButton(
              onPressed: () {
                if (titleCtrl.text.trim().isEmpty) return;
                final amount = double.tryParse(amountCtrl.text.trim()) ?? 0.0;
                final rate = double.tryParse(rateCtrl.text.trim()) ?? 12.0;

                final item = InvestmentDraftItem(
                  id: editItem?.id ?? DateTime.now().millisecondsSinceEpoch.toString(),
                  title: titleCtrl.text.trim(),
                  type: type,
                  amount: amount,
                  returnsRate: rate,
                );

                final updated = List<InvestmentDraftItem>.from(widget.investments);
                if (editIdx != null) {
                  updated[editIdx] = item;
                } else {
                  updated.add(item);
                }
                widget.onInvestmentsUpdated(updated);
                Navigator.pop(ctx);
              },
              child: const Text('Save Investment'),
            ),
          ],
        ),
      ),
    );
  }

  void _removeItem(int index) {
    final updated = List<InvestmentDraftItem>.from(widget.investments)..removeAt(index);
    widget.onInvestmentsUpdated(updated);
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Investment Portfolio (Optional)',
            style: TextStyle(
              fontSize: 26,
              fontWeight: FontWeight.bold,
              color: isDark ? Colors.white : const Color(0xFF0F172A),
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'Add Mutual Funds, Stocks, Gold, Crypto, PF, & NPS to complete your Net Worth calculation.',
            style: TextStyle(
              fontSize: 13,
              color: isDark ? Colors.white70 : const Color(0xFF64748B),
            ),
          ),
          const SizedBox(height: 20),

          // Enable Switch Card
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              color: isDark ? Colors.white.withValues(alpha: 0.03) : Colors.black.withValues(alpha: 0.02),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: isDark ? Colors.white10 : Colors.black12),
            ),
            child: SwitchListTile(
              contentPadding: EdgeInsets.zero,
              title: const Text('I have existing investments', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
              subtitle: const Text('Toggle off to skip portfolio setup', style: TextStyle(fontSize: 11)),
              value: widget.hasInvestments,
              onChanged: (val) => widget.onToggleHasInvestments(val),
            ),
          ),

          if (widget.hasInvestments) ...[
            const SizedBox(height: 20),

            // Live Investment Portfolio Card
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF4C1D95), Color(0xFF5B21B6), Color(0xFF7C3AED)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(22),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF7C3AED).withValues(alpha: 0.3),
                    blurRadius: 16,
                    offset: const Offset(0, 6),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('TOTAL INVESTMENT HOLDINGS', style: TextStyle(color: Colors.white70, fontSize: 10, fontWeight: FontWeight.bold, letterSpacing: 1.0)),
                      Icon(Icons.show_chart_rounded, color: Colors.white70, size: 22),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '₹${_totalInvestmentsValue.toStringAsFixed(0)}',
                    style: const TextStyle(color: Colors.white, fontSize: 30, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('Portfolio Items: ${widget.investments.length}', style: const TextStyle(color: Colors.white70, fontSize: 11)),
                      const Text('Long-term Assets', style: TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold)),
                    ],
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),
            const Text('Quick Templates:', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: _presets.map((p) {
                  return Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: ActionChip(
                      avatar: const Icon(Icons.add_rounded, size: 16, color: Color(0xFF8B5CF6)),
                      label: Text(p['title'] as String, style: const TextStyle(fontSize: 11)),
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
                    'Portfolio Items (${widget.investments.length})',
                    style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
                  ),
                ),
                const SizedBox(width: 8),
                OutlinedButton.icon(
                  onPressed: () => _showAddDialog(),
                  icon: const Icon(Icons.add_rounded, size: 18),
                  label: const Text('Add Investment'),
                ),
              ],
            ),
            const SizedBox(height: 12),

            if (widget.investments.isEmpty)
              Container(
                padding: const EdgeInsets.all(24),
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: isDark ? Colors.white.withValues(alpha: 0.02) : Colors.black.withValues(alpha: 0.02),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: isDark ? Colors.white10 : Colors.black12),
                ),
                child: const Text(
                  'No investments added. Tap quick templates above or add custom holdings.',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 12, color: Colors.grey),
                ),
              )
            else
              ListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: widget.investments.length,
                itemBuilder: (ctx, idx) {
                  final inv = widget.investments[idx];
                  return Card(
                    margin: const EdgeInsets.only(bottom: 10),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    child: ListTile(
                      leading: CircleAvatar(
                        backgroundColor: Colors.purple.withValues(alpha: 0.2),
                        child: const Icon(Icons.trending_up_rounded, color: Colors.purple, size: 20),
                      ),
                      title: Text(inv.title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                      subtitle: Text('${inv.type} • Est. return ${inv.returnsRate}%', style: const TextStyle(fontSize: 11)),
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text('₹${inv.amount.toStringAsFixed(0)}', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Colors.purple)),
                          IconButton(
                            icon: const Icon(Icons.edit_outlined, size: 18),
                            onPressed: () => _showAddDialog(editItem: inv, editIdx: idx),
                          ),
                          IconButton(
                            icon: const Icon(Icons.delete_outline_rounded, size: 18, color: Colors.redAccent),
                            onPressed: () => _removeItem(idx),
                          ),
                        ],
                      ),
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
