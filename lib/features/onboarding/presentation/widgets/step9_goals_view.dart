import 'package:flutter/material.dart';
import '../../domain/entities/onboarding_draft.dart';

class Step9GoalsView extends StatefulWidget {
  final List<GoalDraftItem> goals;
  final bool hasGoals;
  final ValueChanged<bool> onToggleHasGoals;
  final ValueChanged<List<GoalDraftItem>> onGoalsUpdated;
  final VoidCallback onContinue;

  const Step9GoalsView({
    super.key,
    required this.goals,
    required this.hasGoals,
    required this.onToggleHasGoals,
    required this.onGoalsUpdated,
    required this.onContinue,
  });

  @override
  State<Step9GoalsView> createState() => _Step9GoalsViewState();
}

class _Step9GoalsViewState extends State<Step9GoalsView> {
  final _presets = [
    {'title': '6-Month Emergency Fund', 'target': 250000.0, 'category': 'Emergency Fund'},
    {'title': 'Europe Trip Vacation', 'target': 150000.0, 'category': 'Vacation'},
    {'title': 'New Car Down Payment', 'target': 300000.0, 'category': 'Vehicle'},
    {'title': 'House Down Payment', 'target': 1000000.0, 'category': 'House'},
    {'title': 'Child Higher Education', 'target': 500000.0, 'category': 'Education'},
    {'title': 'Retirement Corpus', 'target': 5000000.0, 'category': 'Retirement'},
  ];

  double get _totalTargetAmount => widget.goals.fold<double>(0.0, (sum, g) => sum + g.targetAmount);

  void _addPreset(Map<String, dynamic> p) {
    final item = GoalDraftItem(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      title: p['title'] as String,
      targetAmount: p['target'] as double,
      currentSaved: 0.0,
      targetDate: DateTime.now().add(const Duration(days: 365)),
      category: p['category'] as String,
    );
    final updated = List<GoalDraftItem>.from(widget.goals)..add(item);
    widget.onGoalsUpdated(updated);
  }

  void _showAddDialog({GoalDraftItem? editItem, int? editIdx}) {
    final titleCtrl = TextEditingController(text: editItem?.title ?? '');
    final targetCtrl = TextEditingController(text: editItem != null ? editItem.targetAmount.toStringAsFixed(0) : '');
    final savedCtrl = TextEditingController(text: editItem != null ? editItem.currentSaved.toStringAsFixed(0) : '0');
    String category = editItem?.category ?? 'Emergency Fund';
    DateTime targetDate = editItem?.targetDate ?? DateTime.now().add(const Duration(days: 365));

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
                BoxShadow(
                  color: Colors.black54,
                  blurRadius: 24,
                  offset: Offset(0, -6),
                ),
              ],
            ),
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Top Drag Handle
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
                              color: const Color(0xFF14B8A6).withValues(alpha: 0.2),
                              borderRadius: BorderRadius.circular(14),
                            ),
                            child: const Icon(Icons.flag_rounded, color: Color(0xFF14B8A6), size: 22),
                          ),
                          const SizedBox(width: 12),
                          Text(
                            editItem == null ? 'Add Financial Goal' : 'Edit Financial Goal',
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

                  // Goal Title Input
                  TextField(
                    controller: titleCtrl,
                    style: const TextStyle(color: Colors.white),
                    decoration: InputDecoration(
                      labelText: 'Goal Title',
                      hintText: 'e.g. Emergency Fund, House Down Payment',
                      hintStyle: const TextStyle(color: Colors.white38, fontSize: 13),
                      labelStyle: const TextStyle(color: Colors.white70),
                      prefixIcon: const Icon(Icons.flag_outlined, color: Color(0xFF14B8A6), size: 20),
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

                  // Category Dropdown
                  DropdownButtonFormField<String>(
                    initialValue: category,
                    dropdownColor: const Color(0xFF0F172A),
                    style: const TextStyle(color: Colors.white),
                    decoration: InputDecoration(
                      labelText: 'Goal Category',
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
                      'Emergency Fund',
                      'Vacation',
                      'House',
                      'Vehicle',
                      'Education',
                      'Marriage',
                      'Retirement',
                      'Custom Goals',
                    ].map((c) => DropdownMenuItem(value: c, child: Text(c))).toList(),
                    onChanged: (val) {
                      if (val != null) setBottomSheetState(() => category = val);
                    },
                  ),
                  const SizedBox(height: 14),

                  // Amounts Row (Target Amount & Saved So Far)
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: targetCtrl,
                          keyboardType: TextInputType.number,
                          style: const TextStyle(color: Colors.white),
                          decoration: InputDecoration(
                            labelText: 'Target Goal Amount (₹)',
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
                        child: TextField(
                          controller: savedCtrl,
                          keyboardType: TextInputType.number,
                          style: const TextStyle(color: Colors.white),
                          decoration: InputDecoration(
                            labelText: 'Saved So Far (₹)',
                            labelStyle: const TextStyle(color: Colors.white70, fontSize: 12),
                            prefixIcon: const Icon(Icons.account_balance_wallet_outlined, color: Color(0xFFF59E0B), size: 18),
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

                  // Target Milestone Date Tile
                  Container(
                    decoration: BoxDecoration(
                      color: const Color(0xFF0F172A),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: const Color(0xFF26334D)),
                    ),
                    child: ListTile(
                      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                      title: const Text('Target Milestone Date', style: TextStyle(fontSize: 12, color: Colors.white70)),
                      subtitle: Text(
                        '${targetDate.day}/${targetDate.month}/${targetDate.year}',
                        style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: Colors.white),
                      ),
                      trailing: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: const Color(0xFF14B8A6).withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: const Icon(Icons.calendar_today_rounded, size: 18, color: Color(0xFF14B8A6)),
                      ),
                      onTap: () async {
                        final picked = await showDatePicker(
                          context: ctx,
                          initialDate: targetDate,
                          firstDate: DateTime.now(),
                          lastDate: DateTime.now().add(const Duration(days: 3650)),
                          builder: (context, child) {
                            return Theme(
                              data: ThemeData.dark().copyWith(
                                colorScheme: const ColorScheme.dark(
                                  primary: Color(0xFF14B8A6),
                                  surface: Color(0xFF151C2C),
                                ),
                              ),
                              child: child!,
                            );
                          },
                        );
                        if (picked != null) {
                          setBottomSheetState(() => targetDate = picked);
                        }
                      },
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
                              colors: [Color(0xFF0D9488), Color(0xFF14B8A6)],
                            ),
                            borderRadius: BorderRadius.circular(14),
                            boxShadow: [
                              BoxShadow(
                                color: const Color(0xFF14B8A6).withValues(alpha: 0.35),
                                blurRadius: 12,
                                offset: const Offset(0, 4),
                              ),
                            ],
                          ),
                          child: ElevatedButton(
                            onPressed: () {
                              if (titleCtrl.text.trim().isEmpty) return;
                              final target = double.tryParse(targetCtrl.text.trim()) ?? 0.0;
                              final saved = double.tryParse(savedCtrl.text.trim()) ?? 0.0;

                              final item = GoalDraftItem(
                                id: editItem?.id ?? DateTime.now().millisecondsSinceEpoch.toString(),
                                title: titleCtrl.text.trim(),
                                targetAmount: target,
                                currentSaved: saved,
                                targetDate: targetDate,
                                category: category,
                              );

                              final updated = List<GoalDraftItem>.from(widget.goals);
                              if (editIdx != null) {
                                updated[editIdx] = item;
                              } else {
                                updated.add(item);
                              }
                              widget.onGoalsUpdated(updated);
                              Navigator.pop(ctx);
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.transparent,
                              shadowColor: Colors.transparent,
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                              padding: const EdgeInsets.symmetric(vertical: 16),
                              foregroundColor: Colors.white,
                            ),
                            child: const Text('Save Goal Milestone', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
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
    final updated = List<GoalDraftItem>.from(widget.goals)..removeAt(index);
    widget.onGoalsUpdated(updated);
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Financial Goals',
            style: TextStyle(
              fontSize: 26,
              fontWeight: FontWeight.w800,
              color: Colors.white,
              letterSpacing: -0.5,
            ),
          ),
          const SizedBox(height: 6),
          const Text(
            'Define target milestones for Emergency Fund, Vacation, House, Vehicle, or Retirement.',
            style: TextStyle(
              fontSize: 13,
              color: Color(0xFF94A3B8),
              height: 1.4,
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
              title: const Text('I have financial targets & goals', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Colors.white)),
              subtitle: const Text('Toggle off to skip goal milestones', style: TextStyle(fontSize: 11, color: Colors.white54)),
              value: widget.hasGoals,
              activeThumbColor: const Color(0xFF3B82F6),
              onChanged: (val) => widget.onToggleHasGoals(val),
            ),
          ),

          if (widget.hasGoals) ...[
            const SizedBox(height: 20),

            // Live Target Metric Card
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(22),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF0F766E), Color(0xFF0D9488), Color(0xFF14B8A6)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(24),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF14B8A6).withValues(alpha: 0.35),
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
                      Text('TOTAL TARGET MILESTONES', style: TextStyle(color: Colors.white70, fontSize: 10, fontWeight: FontWeight.bold, letterSpacing: 1.2)),
                      Icon(Icons.flag_rounded, color: Colors.white70, size: 22),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '₹${_totalTargetAmount.toStringAsFixed(0)}',
                    style: const TextStyle(color: Colors.white, fontSize: 32, fontWeight: FontWeight.w800),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('Active Targets: ${widget.goals.length}', style: const TextStyle(color: Colors.white70, fontSize: 11)),
                      const Text('Milestones Configured', style: TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold)),
                    ],
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),
            const Text('Quick Goal Presets:', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.white70)),
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
                      avatar: const Icon(Icons.flag_rounded, size: 14, color: Color(0xFF14B8A6)),
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
                    'Added Goals (${widget.goals.length})',
                    style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: Colors.white),
                  ),
                ),
                const SizedBox(width: 8),
                OutlinedButton.icon(
                  onPressed: () => _showAddDialog(),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: const Color(0xFF14B8A6),
                    side: const BorderSide(color: Color(0xFF14B8A6)),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  icon: const Icon(Icons.add_rounded, size: 18),
                  label: const Text('Add Goal'),
                ),
              ],
            ),
            const SizedBox(height: 12),

            if (widget.goals.isEmpty)
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
                    Icon(Icons.flag_outlined, size: 36, color: Color(0xFF475569)),
                    SizedBox(height: 10),
                    Text(
                      'No goals added yet. Tap quick goal presets above or create custom targets.',
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
                itemCount: widget.goals.length,
                itemBuilder: (ctx, idx) {
                  final g = widget.goals[idx];
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
                            color: const Color(0xFF14B8A6).withValues(alpha: 0.2),
                            borderRadius: BorderRadius.circular(14),
                          ),
                          child: const Icon(Icons.flag_rounded, color: Color(0xFF14B8A6), size: 22),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                g.title,
                                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: Colors.white),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                '${g.category} • Target ₹${g.targetAmount.toStringAsFixed(0)}',
                                style: const TextStyle(fontSize: 11, color: Color(0xFF94A3B8)),
                              ),
                            ],
                          ),
                        ),
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            InkWell(
                              onTap: () => _showAddDialog(editItem: g, editIdx: idx),
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
                  );
                },
              ),
          ],
        ],
      ),
    );
  }
}
