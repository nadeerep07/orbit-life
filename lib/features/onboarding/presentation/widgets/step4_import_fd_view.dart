import 'package:flutter/material.dart';
import '../../domain/entities/onboarding_draft.dart';

class Step4ImportFdView extends StatefulWidget {
  final List<FdLotDraftItem> fdLots;
  final ValueChanged<List<FdLotDraftItem>> onFdLotsUpdated;
  final VoidCallback onContinue;

  const Step4ImportFdView({
    super.key,
    required this.fdLots,
    required this.onFdLotsUpdated,
    required this.onContinue,
  });

  @override
  State<Step4ImportFdView> createState() => _Step4ImportFdViewState();
}

class _Step4ImportFdViewState extends State<Step4ImportFdView> {

  double get _totalFdPrincipal => widget.fdLots.fold<double>(0.0, (sum, f) => sum + f.principal);
  double get _totalFdValue => widget.fdLots.fold<double>(0.0, (sum, f) => sum + (f.currentValue ?? f.principal));

  void _showAddFdDialog({FdLotDraftItem? editItem, int? editIdx}) {
    final principalCtrl = TextEditingController(text: editItem != null ? editItem.principal.toStringAsFixed(0) : '');
    final rateCtrl = TextEditingController(text: editItem != null ? editItem.interestRate.toStringAsFixed(1) : '7.5');
    final currentValCtrl = TextEditingController(text: editItem?.currentValue != null ? editItem!.currentValue!.toStringAsFixed(0) : '');
    final bankCtrl = TextEditingController(text: editItem?.bank ?? '');
    final remarksCtrl = TextEditingController(text: editItem?.remarks ?? 'Historical Fixed Deposit');
    DateTime selectedDate = editItem?.depositDate ?? DateTime.now().subtract(const Duration(days: 180));

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(22)),
          title: Text(editItem == null ? 'Import Existing FD Lot' : 'Edit FD Lot'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.amber.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.amber.withValues(alpha: 0.3)),
                  ),
                  child: const Row(
                    children: [
                      Icon(Icons.shield_outlined, size: 18, color: Colors.amber),
                      SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          'Imported historical FDs preserve your existing credit limit without double-counting towards card allocation.',
                          style: TextStyle(fontSize: 11, color: Colors.amber),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 14),
                TextField(
                  controller: principalCtrl,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(labelText: 'Deposit Amount (₹)', border: OutlineInputBorder()),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: rateCtrl,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(labelText: 'Interest Rate (% p.a.)', border: OutlineInputBorder()),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: currentValCtrl,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(labelText: 'Current Accrued Value (Optional)', border: OutlineInputBorder()),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: bankCtrl,
                  decoration: const InputDecoration(labelText: 'Bank / Financial Institution', border: OutlineInputBorder()),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: remarksCtrl,
                  decoration: const InputDecoration(labelText: 'Remarks / FD Receipt Tag', border: OutlineInputBorder()),
                ),
                const SizedBox(height: 12),
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  title: const Text('Deposit Start Date', style: TextStyle(fontSize: 12)),
                  subtitle: Text('${selectedDate.day}/${selectedDate.month}/${selectedDate.year}', style: const TextStyle(fontWeight: FontWeight.bold)),
                  trailing: const Icon(Icons.calendar_today_rounded, size: 18, color: Color(0xFF3B82F6)),
                  onTap: () async {
                    final picked = await showDatePicker(
                      context: ctx,
                      initialDate: selectedDate,
                      firstDate: DateTime(2010),
                      lastDate: DateTime.now(),
                    );
                    if (picked != null) {
                      setDialogState(() => selectedDate = picked);
                    }
                  },
                ),
              ],
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
            ElevatedButton(
              onPressed: () {
                final principal = double.tryParse(principalCtrl.text.trim()) ?? 0.0;
                if (principal <= 0) return;

                final rate = double.tryParse(rateCtrl.text.trim()) ?? 7.5;
                final currValText = currentValCtrl.text.trim();
                final double? currVal = currValText.isNotEmpty ? double.tryParse(currValText) : null;

                final item = FdLotDraftItem(
                  id: editItem?.id ?? DateTime.now().millisecondsSinceEpoch.toString(),
                  principal: principal,
                  depositDate: selectedDate,
                  interestRate: rate,
                  bank: bankCtrl.text.trim(),
                  remarks: remarksCtrl.text.trim(),
                  currentValue: currVal,
                  isImportedHistoricalFd: true,
                  migrationLot: true,
                );

                final updated = List<FdLotDraftItem>.from(widget.fdLots);
                if (editIdx != null) {
                  updated[editIdx] = item;
                } else {
                  updated.add(item);
                }
                widget.onFdLotsUpdated(updated);
                Navigator.pop(ctx);
              },
              child: const Text('Save FD Lot'),
            ),
          ],
        ),
      ),
    );
  }

  void _removeItem(int index) {
    final updated = List<FdLotDraftItem>.from(widget.fdLots)..removeAt(index);
    widget.onFdLotsUpdated(updated);
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
            'Import Existing FD History',
            style: TextStyle(
              fontSize: 26,
              fontWeight: FontWeight.bold,
              color: isDark ? Colors.white : const Color(0xFF0F172A),
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'Import active or matured fixed deposits to track compounding growth without affecting your current credit limit.',
            style: TextStyle(
              fontSize: 13,
              color: isDark ? Colors.white70 : const Color(0xFF64748B),
            ),
          ),
          const SizedBox(height: 20),

          // Total FD Summary Metric Card
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF78350F), Color(0xFFB45309), Color(0xFFD97706)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(22),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFFD97706).withValues(alpha: 0.3),
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
                    Text('TOTAL HISTORICAL FD ASSETS', style: TextStyle(color: Colors.white70, fontSize: 10, fontWeight: FontWeight.bold, letterSpacing: 1.0)),
                    Icon(Icons.savings_rounded, color: Colors.white70, size: 22),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  '₹${_totalFdValue.toStringAsFixed(0)}',
                  style: const TextStyle(color: Colors.white, fontSize: 30, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 12),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('Principal Deposited: ₹${_totalFdPrincipal.toStringAsFixed(0)}', style: const TextStyle(color: Colors.white70, fontSize: 11)),
                    Text('Total FD Lots: ${widget.fdLots.length}', style: const TextStyle(color: Colors.white70, fontSize: 11, fontWeight: FontWeight.bold)),
                  ],
                ),
              ],
            ),
          ),

          const SizedBox(height: 24),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  'Imported FD Lots (${widget.fdLots.length})',
                  style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
                ),
              ),
              const SizedBox(width: 8),
              OutlinedButton.icon(
                onPressed: () => _showAddFdDialog(),
                icon: const Icon(Icons.add_rounded, size: 18),
                label: const Text('Import FD Lot'),
              ),
            ],
          ),
          const SizedBox(height: 12),

          if (widget.fdLots.isEmpty)
            Container(
              padding: const EdgeInsets.all(24),
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: isDark ? Colors.white.withValues(alpha: 0.02) : Colors.black.withValues(alpha: 0.02),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: isDark ? Colors.white10 : Colors.black12),
              ),
              child: const Text(
                'No historical FDs added yet. Tap "Import FD Lot" to record active fixed deposits.',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 12, color: Colors.grey),
              ),
            )
          else
            ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: widget.fdLots.length,
              itemBuilder: (ctx, idx) {
                final fd = widget.fdLots[idx];
                return Card(
                  margin: const EdgeInsets.only(bottom: 10),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  child: ListTile(
                    leading: CircleAvatar(
                      backgroundColor: Colors.amber.withValues(alpha: 0.2),
                      child: const Icon(Icons.savings_rounded, color: Colors.amber, size: 20),
                    ),
                    title: Text('₹${fd.principal.toStringAsFixed(0)} @ ${fd.interestRate}% p.a.', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                    subtitle: Text('${fd.bank.isNotEmpty ? "${fd.bank} • " : ""}${fd.remarks}', style: const TextStyle(fontSize: 11)),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(
                          icon: const Icon(Icons.edit_outlined, size: 18),
                          onPressed: () => _showAddFdDialog(editItem: fd, editIdx: idx),
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
      ),
    );
  }
}
