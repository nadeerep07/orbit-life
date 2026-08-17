import 'package:flutter/material.dart';
import '../../domain/entities/onboarding_draft.dart';

class Step3CreditCardView extends StatefulWidget {
  final CreditCardDraftItem? creditCard;
  final bool hasCreditCards;
  final ValueChanged<bool> onToggleHasCreditCards;
  final ValueChanged<CreditCardDraftItem?> onCreditCardUpdated;
  final VoidCallback onContinue;

  const Step3CreditCardView({
    super.key,
    required this.creditCard,
    required this.hasCreditCards,
    required this.onToggleHasCreditCards,
    required this.onCreditCardUpdated,
    required this.onContinue,
  });

  @override
  State<Step3CreditCardView> createState() => _Step3CreditCardViewState();
}

class _Step3CreditCardViewState extends State<Step3CreditCardView> {
  final _cardTemplates = [
    {'name': 'FD Secured Card', 'limit': 25000.0},
    {'name': 'IDFC WOW Secured', 'limit': 25000.0},
    {'name': 'OneCard FD Secured', 'limit': 50000.0},
    {'name': 'Kotak DreamDifferent', 'limit': 20000.0},
    {'name': 'Custom FD Card', 'limit': 10000.0},
  ];

  late TextEditingController _nameCtrl;
  late TextEditingController _limitCtrl;
  late TextEditingController _usedCtrl;
  late TextEditingController _statementDayCtrl;
  late TextEditingController _dueDayCtrl;

  @override
  void initState() {
    super.initState();
    final cc = widget.creditCard;
    _nameCtrl = TextEditingController(text: cc?.name ?? 'Secured Credit Card');
    _limitCtrl = TextEditingController(text: cc != null ? cc.creditLimit.toStringAsFixed(0) : '0');
    _usedCtrl = TextEditingController(text: cc != null ? cc.usedCredit.toStringAsFixed(0) : '0');
    _statementDayCtrl = TextEditingController(text: (cc?.statementDateDay ?? 1).toString());
    _dueDayCtrl = TextEditingController(text: (cc?.dueDateDay ?? 15).toString());

    _nameCtrl.addListener(_updateState);
    _limitCtrl.addListener(_updateState);
    _usedCtrl.addListener(_updateState);
    _statementDayCtrl.addListener(_updateState);
    _dueDayCtrl.addListener(_updateState);
  }

  void _updateState() {
    _saveCurrentState();
    setState(() {});
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _limitCtrl.dispose();
    _usedCtrl.dispose();
    _statementDayCtrl.dispose();
    _dueDayCtrl.dispose();
    super.dispose();
  }

  void _saveCurrentState() {
    if (!widget.hasCreditCards) {
      widget.onCreditCardUpdated(null);
      return;
    }

    final limit = double.tryParse(_limitCtrl.text.trim()) ?? 0.0;
    final used = double.tryParse(_usedCtrl.text.trim()) ?? 0.0;
    final available = (limit - used).clamp(0.0, limit);
    final stmtDay = int.tryParse(_statementDayCtrl.text.trim()) ?? 1;
    final dueDay = int.tryParse(_dueDayCtrl.text.trim()) ?? 15;

    final item = CreditCardDraftItem(
      id: widget.creditCard?.id ?? 'supermoney',
      name: _nameCtrl.text.trim().isEmpty ? 'Secured Credit Card' : _nameCtrl.text.trim(),
      creditLimit: limit,
      usedCredit: used,
      availableCredit: available,
      statementDateDay: stmtDay,
      dueDateDay: dueDay,
    );
    widget.onCreditCardUpdated(item);
  }

  void _applyTemplate(Map<String, dynamic> t) {
    _nameCtrl.text = t['name'] as String;
    _limitCtrl.text = (t['limit'] as double).toStringAsFixed(0);
  }

  @override
  Widget build(BuildContext context) {
    final cardName = _nameCtrl.text.trim().isEmpty ? 'Secured Credit Card' : _nameCtrl.text.trim();
    final limit = double.tryParse(_limitCtrl.text.trim()) ?? 0.0;
    final used = double.tryParse(_usedCtrl.text.trim()) ?? 0.0;
    final available = (limit - used).clamp(0.0, limit);
    final utilization = limit > 0 ? ((used / limit) * 100).clamp(0.0, 100.0) : 0.0;

    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'FD-Based Secured Credit Card',
            style: TextStyle(
              fontSize: 26,
              fontWeight: FontWeight.w800,
              color: Colors.white,
              letterSpacing: -0.5,
            ),
          ),
          const SizedBox(height: 6),
          const Text(
            'OrbitLife tracks your FD-backed card limits and utilization without manual calculations.',
            style: TextStyle(
              fontSize: 13,
              color: Color(0xFF94A3B8),
              height: 1.4,
            ),
          ),
          const SizedBox(height: 20),

          // Enable/Disable Switch Card
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              color: const Color(0xFF151C2C),
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: const Color(0xFF26334D)),
            ),
            child: SwitchListTile(
              contentPadding: EdgeInsets.zero,
              title: const Text('I use an FD-based Secured Credit Card', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Colors.white)),
              subtitle: const Text('Toggle off to skip credit card setup', style: TextStyle(fontSize: 11, color: Colors.white54)),
              value: widget.hasCreditCards,
              activeColor: const Color(0xFF3B82F6),
              onChanged: (val) => widget.onToggleHasCreditCards(val),
            ),
          ),

          if (widget.hasCreditCards) ...[
            const SizedBox(height: 20),

            // Live Visual Credit Card Mockup Widget
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(22),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF1E1B4B), Color(0xFF312E81), Color(0xFF4338CA)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(24),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF4338CA).withValues(alpha: 0.4),
                    blurRadius: 20,
                    offset: const Offset(0, 10),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        cardName.toUpperCase(),
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 1.2,
                          fontSize: 13,
                        ),
                      ),
                      const Icon(Icons.contactless_rounded, color: Colors.white70, size: 24),
                    ],
                  ),
                  const SizedBox(height: 20),
                  Row(
                    children: [
                      Container(
                        width: 38,
                        height: 28,
                        decoration: BoxDecoration(
                          color: const Color(0xFFF59E0B),
                          borderRadius: BorderRadius.circular(6),
                        ),
                      ),
                      const SizedBox(width: 14),
                      const Text(
                        '•••• •••• •••• 8842',
                        style: TextStyle(color: Colors.white70, letterSpacing: 2.5, fontSize: 13, fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                  const SizedBox(height: 22),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('CREDIT LIMIT', style: TextStyle(color: Colors.white54, fontSize: 9, fontWeight: FontWeight.bold)),
                          Text('₹${limit.toStringAsFixed(0)}', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w800, fontSize: 16)),
                        ],
                      ),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('AVAILABLE CREDIT', style: TextStyle(color: Colors.white54, fontSize: 9, fontWeight: FontWeight.bold)),
                          Text('₹${available.toStringAsFixed(0)}', style: const TextStyle(color: Color(0xFF34D399), fontWeight: FontWeight.w800, fontSize: 16)),
                        ],
                      ),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('USED CREDIT', style: TextStyle(color: Colors.white54, fontSize: 9, fontWeight: FontWeight.bold)),
                          Text('₹${used.toStringAsFixed(0)}', style: const TextStyle(color: Color(0xFFF87171), fontWeight: FontWeight.w800, fontSize: 16)),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(4),
                    child: LinearProgressIndicator(
                      value: utilization / 100,
                      minHeight: 6,
                      backgroundColor: Colors.white24,
                      valueColor: AlwaysStoppedAnimation<Color>(
                        utilization > 70 ? Colors.redAccent : (utilization > 30 ? Colors.amber : const Color(0xFF34D399)),
                      ),
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'Utilization Ratio: ${utilization.toStringAsFixed(0)}%',
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                      color: utilization > 70 ? Colors.redAccent : (utilization > 30 ? Colors.amber : const Color(0xFF34D399)),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),
            const Text('Card Quick Templates:', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.white70)),
            const SizedBox(height: 8),
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: _cardTemplates.map((t) {
                  return Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: ActionChip(
                      backgroundColor: const Color(0xFF1E293B),
                      side: const BorderSide(color: Color(0xFF334155)),
                      avatar: const Icon(Icons.credit_card_rounded, size: 14, color: Color(0xFF818CF8)),
                      label: Text(t['name'] as String, style: const TextStyle(fontSize: 11, color: Colors.white, fontWeight: FontWeight.w600)),
                      onPressed: () => _applyTemplate(t),
                    ),
                  );
                }).toList(),
              ),
            ),
            const SizedBox(height: 20),

            TextField(
              controller: _nameCtrl,
              style: const TextStyle(color: Colors.white),
              decoration: InputDecoration(
                labelText: 'Card Name',
                labelStyle: const TextStyle(color: Colors.white70),
                filled: true,
                fillColor: const Color(0xFF151C2C),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(16)),
              ),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _limitCtrl,
                    keyboardType: TextInputType.number,
                    style: const TextStyle(color: Colors.white),
                    decoration: InputDecoration(
                      labelText: 'Credit Limit (₹)',
                      labelStyle: const TextStyle(color: Colors.white70),
                      filled: true,
                      fillColor: const Color(0xFF151C2C),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(16)),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: TextField(
                    controller: _usedCtrl,
                    keyboardType: TextInputType.number,
                    style: const TextStyle(color: Colors.white),
                    decoration: InputDecoration(
                      labelText: 'Used Credit (₹)',
                      labelStyle: const TextStyle(color: Colors.white70),
                      filled: true,
                      fillColor: const Color(0xFF151C2C),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(16)),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _statementDayCtrl,
                    keyboardType: TextInputType.number,
                    style: const TextStyle(color: Colors.white),
                    decoration: InputDecoration(
                      labelText: 'Statement Day (1-31)',
                      labelStyle: const TextStyle(color: Colors.white70),
                      filled: true,
                      fillColor: const Color(0xFF151C2C),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(16)),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: TextField(
                    controller: _dueDayCtrl,
                    keyboardType: TextInputType.number,
                    style: const TextStyle(color: Colors.white),
                    decoration: InputDecoration(
                      labelText: 'Due Day (1-31)',
                      labelStyle: const TextStyle(color: Colors.white70),
                      filled: true,
                      fillColor: const Color(0xFF151C2C),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(16)),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}
