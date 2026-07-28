import 'package:flutter/material.dart';
import '../../domain/entities/onboarding_draft.dart';

class Step2AccountsView extends StatefulWidget {
  final List<AccountDraftItem> accounts;
  final ValueChanged<List<AccountDraftItem>> onAccountsUpdated;
  final VoidCallback onContinue;

  const Step2AccountsView({
    super.key,
    required this.accounts,
    required this.onAccountsUpdated,
    required this.onContinue,
  });

  @override
  State<Step2AccountsView> createState() => _Step2AccountsViewState();
}

class _Step2AccountsViewState extends State<Step2AccountsView> {
  final _templates = [
    {'name': 'SBI Savings', 'type': 'Savings Account', 'bank': 'State Bank of India', 'color': 0xFF3B82F6},
    {'name': 'HDFC Salary', 'type': 'Salary Account', 'bank': 'HDFC Bank', 'color': 0xFF0284C7},
    {'name': 'ICICI Savings', 'type': 'Savings Account', 'bank': 'ICICI Bank', 'color': 0xFFF97316},
    {'name': 'Axis Bank', 'type': 'Savings Account', 'bank': 'Axis Bank', 'color': 0xFFEC4899},
    {'name': 'Federal Bank', 'type': 'Savings Account', 'bank': 'Federal Bank', 'color': 0xFF10B981},
    {'name': 'Cash Wallet', 'type': 'Cash Wallet', 'bank': 'Physical Cash', 'color': 0xFF8B5CF6},
    {'name': 'Paytm Wallet', 'type': 'Digital Wallet', 'bank': 'Paytm Bank', 'color': 0xFF06B6D4},
  ];

  double get _totalLiquidCash => widget.accounts.fold<double>(0.0, (sum, a) => sum + a.currentBalance);

  void _addTemplate(Map<String, dynamic> t) {
    final newItem = AccountDraftItem(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      name: t['name'] as String,
      accountType: t['type'] as String,
      bank: t['bank'] as String,
      currentBalance: 0.0,
      colorHex: t['color'] as int,
    );
    final updated = List<AccountDraftItem>.from(widget.accounts)..add(newItem);
    widget.onAccountsUpdated(updated);
  }

  void _showAddAccountDialog({AccountDraftItem? editItem, int? editIdx}) {
    final nameCtrl = TextEditingController(text: editItem?.name ?? '');
    final bankCtrl = TextEditingController(text: editItem?.bank ?? '');
    final balanceCtrl = TextEditingController(text: editItem != null ? editItem.currentBalance.toStringAsFixed(0) : '');
    final notesCtrl = TextEditingController(text: editItem?.notes ?? '');
    String selectedType = editItem?.accountType ?? 'Savings Account';
    bool includeNetWorth = editItem?.includeInNetWorth ?? true;
    bool importLater = editItem?.importLater ?? false;

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
                              color: const Color(0xFF3B82F6).withValues(alpha: 0.2),
                              borderRadius: BorderRadius.circular(14),
                            ),
                            child: const Icon(Icons.account_balance_rounded, color: Color(0xFF60A5FA), size: 22),
                          ),
                          const SizedBox(width: 12),
                          Text(
                            editItem == null ? 'Add Financial Account' : 'Edit Financial Account',
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
                      labelText: 'Account Name',
                      hintText: 'e.g. HDFC Salary, SBI Main Savings',
                      hintStyle: const TextStyle(color: Colors.white38, fontSize: 13),
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
                  ),
                  const SizedBox(height: 14),

                  DropdownButtonFormField<String>(
                    initialValue: selectedType,
                    dropdownColor: const Color(0xFF0F172A),
                    style: const TextStyle(color: Colors.white),
                    decoration: InputDecoration(
                      labelText: 'Account Type',
                      labelStyle: const TextStyle(color: Colors.white70),
                      prefixIcon: const Icon(Icons.style_outlined, color: Color(0xFF34D399), size: 20),
                      filled: true,
                      fillColor: const Color(0xFF0F172A),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(16)),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(16),
                        borderSide: const BorderSide(color: Color(0xFF26334D)),
                      ),
                    ),
                    items: [
                      'Savings Account',
                      'Salary Account',
                      'Current Account',
                      'Cash Wallet',
                      'Digital Wallet',
                      'Payment Bank',
                      'Business Account',
                      'Travel Wallet',
                      'Custom',
                    ].map((t) => DropdownMenuItem(value: t, child: Text(t))).toList(),
                    onChanged: (val) {
                      if (val != null) setBottomSheetState(() => selectedType = val);
                    },
                  ),
                  const SizedBox(height: 14),

                  TextField(
                    controller: bankCtrl,
                    style: const TextStyle(color: Colors.white),
                    decoration: InputDecoration(
                      labelText: 'Bank / Financial Institution',
                      hintText: 'e.g. HDFC, ICICI, SBI, Axis',
                      hintStyle: const TextStyle(color: Colors.white38, fontSize: 13),
                      labelStyle: const TextStyle(color: Colors.white70),
                      prefixIcon: const Icon(Icons.business_rounded, color: Color(0xFFA855F7), size: 20),
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
                    controller: balanceCtrl,
                    keyboardType: TextInputType.number,
                    style: const TextStyle(color: Colors.white),
                    decoration: InputDecoration(
                      labelText: 'Current Balance Today (₹)',
                      labelStyle: const TextStyle(color: Colors.white70),
                      prefixIcon: const Icon(Icons.currency_rupee_rounded, color: Color(0xFF10B981), size: 20),
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

                  Container(
                    decoration: BoxDecoration(
                      color: const Color(0xFF0F172A),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: const Color(0xFF26334D)),
                    ),
                    child: Column(
                      children: [
                        SwitchListTile(
                          title: const Text('Include in Net Worth', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Colors.white)),
                          subtitle: const Text('Calculates towards total liquid net worth', style: TextStyle(fontSize: 11, color: Colors.white54)),
                          value: includeNetWorth,
                          activeThumbColor: const Color(0xFF3B82F6),
                          onChanged: (val) => setBottomSheetState(() => includeNetWorth = val),
                        ),
                        const Divider(height: 1, color: Color(0xFF26334D)),
                        SwitchListTile(
                          title: const Text('Import Statement Transactions Later', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Colors.white)),
                          subtitle: const Text('CSV/Excel statement auto-parser enabled', style: TextStyle(fontSize: 11, color: Colors.white54)),
                          value: importLater,
                          activeThumbColor: const Color(0xFF3B82F6),
                          onChanged: (val) => setBottomSheetState(() => importLater = val),
                        ),
                      ],
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
                              colors: [Color(0xFF2563EB), Color(0xFF3B82F6)],
                            ),
                            borderRadius: BorderRadius.circular(14),
                            boxShadow: [
                              BoxShadow(
                                color: const Color(0xFF2563EB).withValues(alpha: 0.35),
                                blurRadius: 12,
                                offset: const Offset(0, 4),
                              ),
                            ],
                          ),
                          child: ElevatedButton(
                            onPressed: () {
                              if (nameCtrl.text.trim().isEmpty) return;
                              final balance = double.tryParse(balanceCtrl.text.trim()) ?? 0.0;
                              final item = AccountDraftItem(
                                id: editItem?.id ?? DateTime.now().millisecondsSinceEpoch.toString(),
                                name: nameCtrl.text.trim(),
                                accountType: selectedType,
                                bank: bankCtrl.text.trim(),
                                currentBalance: balance,
                                includeInNetWorth: includeNetWorth,
                                importLater: importLater,
                                notes: notesCtrl.text.trim(),
                              );

                              final updated = List<AccountDraftItem>.from(widget.accounts);
                              if (editIdx != null) {
                                updated[editIdx] = item;
                              } else {
                                updated.add(item);
                              }
                              widget.onAccountsUpdated(updated);
                              Navigator.pop(ctx);
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.transparent,
                              shadowColor: Colors.transparent,
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                              padding: const EdgeInsets.symmetric(vertical: 16),
                              foregroundColor: Colors.white,
                            ),
                            child: const Text('Save Account', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
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
    final updated = List<AccountDraftItem>.from(widget.accounts)..removeAt(index);
    widget.onAccountsUpdated(updated);
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Financial Snapshot: Accounts',
            style: TextStyle(
              fontSize: 26,
              fontWeight: FontWeight.w800,
              color: Colors.white,
              letterSpacing: -0.5,
            ),
          ),
          const SizedBox(height: 6),
          const Text(
            'Enter your real current bank balances today so OrbitLife calculates liquid cash.',
            style: TextStyle(
              fontSize: 13,
              color: Color(0xFF94A3B8),
              height: 1.4,
            ),
          ),
          const SizedBox(height: 20),

          // Total Liquid Cash Card
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF1E3A8A), Color(0xFF2563EB), Color(0xFF3B82F6)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(22),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF2563EB).withValues(alpha: 0.35),
                  blurRadius: 18,
                  offset: const Offset(0, 8),
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
                      'TOTAL LIQUID CASH IN ACCOUNTS',
                      style: TextStyle(color: Colors.white70, fontSize: 10, fontWeight: FontWeight.bold, letterSpacing: 1.2),
                    ),
                    Icon(Icons.account_balance_wallet_rounded, color: Colors.white70, size: 22),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  '₹${_totalLiquidCash.toStringAsFixed(0)}',
                  style: const TextStyle(color: Colors.white, fontSize: 32, fontWeight: FontWeight.w800),
                ),
                const SizedBox(height: 10),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('Active Accounts: ${widget.accounts.length}', style: const TextStyle(color: Colors.white70, fontSize: 11)),
                    const Text('Real-Time Balance Sync', style: TextStyle(color: Color(0xFF60A5FA), fontSize: 11, fontWeight: FontWeight.bold)),
                  ],
                ),
              ],
            ),
          ),

          const SizedBox(height: 24),
          const Text('Quick Add Bank Templates:', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.white70)),
          const SizedBox(height: 8),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: _templates.map((t) {
                return Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: ActionChip(
                    backgroundColor: const Color(0xFF1E293B),
                    side: const BorderSide(color: Color(0xFF334155)),
                    avatar: CircleAvatar(
                      backgroundColor: Color(t['color'] as int).withValues(alpha: 0.25),
                      child: Icon(Icons.add_rounded, size: 14, color: Color(t['color'] as int)),
                    ),
                    label: Text(t['name'] as String, style: const TextStyle(fontSize: 11, color: Colors.white, fontWeight: FontWeight.w600)),
                    onPressed: () => _addTemplate(t),
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
                  'Added Accounts (${widget.accounts.length})',
                  style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: Colors.white),
                ),
              ),
              const SizedBox(width: 8),
              OutlinedButton.icon(
                onPressed: () => _showAddAccountDialog(),
                style: OutlinedButton.styleFrom(
                  foregroundColor: const Color(0xFF3B82F6),
                  side: const BorderSide(color: Color(0xFF3B82F6)),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                icon: const Icon(Icons.add_rounded, size: 18),
                label: const Text('Custom Account'),
              ),
            ],
          ),
          const SizedBox(height: 12),

          if (widget.accounts.isEmpty)
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
                  Icon(Icons.account_balance_outlined, size: 36, color: Color(0xFF475569)),
                  SizedBox(height: 10),
                  Text(
                    'No accounts added yet.\nTap a quick template above or add a custom bank account.',
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
              itemCount: widget.accounts.length,
              itemBuilder: (ctx, idx) {
                final acc = widget.accounts[idx];
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
                          color: Color(acc.colorHex).withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: Icon(Icons.account_balance_rounded, color: Color(acc.colorHex), size: 22),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              acc.name,
                              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: Colors.white),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              '${acc.accountType} • ${acc.bank.isEmpty ? "Direct" : acc.bank}',
                              style: const TextStyle(fontSize: 11, color: Color(0xFF94A3B8)),
                            ),
                          ],
                        ),
                      ),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Text(
                            '₹${acc.currentBalance.toStringAsFixed(0)}',
                            style: TextStyle(fontWeight: FontWeight.w800, fontSize: 16, color: Color(0xFF34D399)),
                          ),
                          Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              InkWell(
                                onTap: () => _showAddAccountDialog(editItem: acc, editIdx: idx),
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
