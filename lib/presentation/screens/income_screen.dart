import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../domain/entities/income_entity.dart';
import '../viewmodels/income_view_model.dart';
import '../viewmodels/accounts_view_model.dart';
import '../viewmodels/theme_view_model.dart';
import '../../core/utils/currency_formatter.dart';
import '../../core/utils/responsive.dart';
import '../widgets/modern_loader.dart';
import 'allocation_preview_screen.dart';

class IncomeScreen extends StatefulWidget {
  const IncomeScreen({super.key});

  @override
  State<IncomeScreen> createState() => _IncomeScreenState();
}

class _IncomeScreenState extends State<IncomeScreen> {
  DateTime _currentMonth = DateTime(DateTime.now().year, DateTime.now().month);

  @override
  void initState() {
    super.initState();
    Future.microtask(() => context.read<IncomeViewModel>().loadIncomes());
  }

  void _previousMonth() {
    setState(() {
      _currentMonth = DateTime(_currentMonth.year, _currentMonth.month - 1);
    });
  }

  void _nextMonth() {
    setState(() {
      _currentMonth = DateTime(_currentMonth.year, _currentMonth.month + 1);
    });
  }

  void _showAddIncomeSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => const _AddIncomeSheet(),
    );
  }

  IconData _getSourceIcon(String source) {
    final s = source.toLowerCase();
    if (s.contains('salary') || s.contains('job') || s.contains('pay')) {
      return Icons.payments_rounded;
    } else if (s.contains('free') || s.contains('gig') || s.contains('work')) {
      return Icons.laptop_mac_rounded;
    } else if (s.contains('refund') || s.contains('return')) {
      return Icons.replay_rounded;
    } else if (s.contains('gift') || s.contains('bonus')) {
      return Icons.card_giftcard_rounded;
    } else if (s.contains('invest') || s.contains('stock') || s.contains('div')) {
      return Icons.trending_up_rounded;
    }
    return Icons.account_balance_wallet_rounded;
  }

  @override
  Widget build(BuildContext context) {
    final themeVM = context.watch<ThemeViewModel>();
    final isDarkMode = themeVM.themeMode == ThemeMode.dark;

    final incomeVM = context.watch<IncomeViewModel>();
    final accountsVM = context.watch<AccountsViewModel>();
    final incomesForMonth = incomeVM.getIncomesForMonth(_currentMonth);
    final totalIncome = incomeVM.getTotalIncomeForMonth(_currentMonth);

    // Calculate top source for month
    String topSource = 'None';
    double topSourceAmt = 0;
    if (incomesForMonth.isNotEmpty) {
      final Map<String, double> sourceTotals = {};
      for (var inc in incomesForMonth) {
        sourceTotals[inc.source] = (sourceTotals[inc.source] ?? 0) + inc.amount;
      }
      var sorted = sourceTotals.entries.toList()..sort((a, b) => b.value.compareTo(a.value));
      topSource = sorted.first.key;
      topSourceAmt = sorted.first.value;
    }

    final r = Responsive(context);

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        title: const Text('Income Tracker', style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
      ),
      body: Align(
        alignment: Alignment.topCenter,
        child: ConstrainedBox(
          constraints: BoxConstraints(maxWidth: r.contentMaxWidth),
          child: SingleChildScrollView(
            child: Column(
              children: [
                // ── Month Selector Header ──────────────────────────────────────────
                Padding(
                  padding: EdgeInsets.symmetric(horizontal: r.horizontalPadding, vertical: 6),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                    decoration: BoxDecoration(
                      color: Theme.of(context).cardColor,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: Theme.of(context).dividerColor.withValues(alpha: 0.08)),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        IconButton(
                          icon: const Icon(Icons.chevron_left_rounded, size: 22),
                          onPressed: _previousMonth,
                        ),
                        Text(
                          DateFormat('MMMM yyyy').format(_currentMonth),
                          style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
                        ),
                        IconButton(
                          icon: const Icon(Icons.chevron_right_rounded, size: 22),
                          onPressed: _nextMonth,
                        ),
                      ],
                    ),
                  ),
                ),

                // ── Hero Total Income Obsidian Emerald Banner ──────────────────────
                Container(
                  margin: EdgeInsets.symmetric(horizontal: r.horizontalPadding, vertical: 12),
                  padding: const EdgeInsets.all(22),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFF064E3B), Color(0xFF047857), Color(0xFF022C22)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(28),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFF047857).withValues(alpha: 0.35),
                        blurRadius: 20,
                        offset: const Offset(0, 8),
                      ),
                    ],
                    border: Border.all(color: Colors.greenAccent.withValues(alpha: 0.3), width: 1.2),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text(
                            'TOTAL MONTHLY INCOME',
                            style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.greenAccent, letterSpacing: 1.2),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                            decoration: BoxDecoration(
                              color: Colors.greenAccent.withValues(alpha: 0.15),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              '${incomesForMonth.length} Credit${incomesForMonth.length == 1 ? '' : 's'}',
                              style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.greenAccent),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Text(
                        '$currencySymbol${totalIncome == totalIncome.truncateToDouble() ? totalIncome.toStringAsFixed(0) : totalIncome.toStringAsFixed(2)}',
                        style: const TextStyle(fontSize: 36, fontWeight: FontWeight.w900, color: Colors.white, letterSpacing: -0.5),
                      ),
                      const SizedBox(height: 16),
                      const Divider(color: Colors.white12),
                      const SizedBox(height: 8),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Row(
                            children: [
                              const Icon(Icons.star_rounded, color: Colors.greenAccent, size: 16),
                              const SizedBox(width: 6),
                              Text(
                                topSourceAmt > 0 ? 'Top: $topSource ($currencySymbol${topSourceAmt.toStringAsFixed(0)})' : 'No records yet',
                                style: const TextStyle(color: Colors.white70, fontSize: 12, fontWeight: FontWeight.w600),
                              ),
                            ],
                          ),
                          const Icon(Icons.arrow_upward_rounded, color: Colors.greenAccent, size: 16),
                        ],
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 8),

                // ── Section Title ──────────────────────────────────────────────────
                Padding(
                  padding: EdgeInsets.symmetric(horizontal: r.horizontalPadding + 4, vertical: 6),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('INCOME RECORDS', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.grey, letterSpacing: 1.1)),
                      Text('Swipe to delete', style: TextStyle(fontSize: 10, color: Colors.grey.shade600)),
                    ],
                  ),
                ),

                const SizedBox(height: 4),

                // ── Income List ──────────────────────────────────────────────────
                incomeVM.isLoading
                    ? const ModernShimmerLoader(itemCount: 3)
                    : incomesForMonth.isEmpty
                        ? Padding(
                            padding: const EdgeInsets.all(40),
                            child: Column(
                              children: [
                                Icon(Icons.account_balance_wallet_outlined, size: 48, color: Colors.grey.shade600),
                                const SizedBox(height: 12),
                                const Text('No income recorded for this month.', style: TextStyle(color: Colors.grey, fontWeight: FontWeight.w600)),
                                const SizedBox(height: 16),
                                ElevatedButton.icon(
                                  onPressed: () => _showAddIncomeSheet(context),
                                  icon: const Icon(Icons.add, size: 18),
                                  label: const Text('Add Income Record'),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: const Color(0xFF047857),
                                    foregroundColor: Colors.white,
                                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                                  ),
                                ),
                              ],
                            ),
                          )
                        : ListView.builder(
                            shrinkWrap: true,
                            physics: const NeverScrollableScrollPhysics(),
                            padding: EdgeInsets.symmetric(horizontal: r.horizontalPadding),
                            itemCount: incomesForMonth.length,
                            itemBuilder: (context, index) {
                              final income = incomesForMonth[index];
                              final accountName = accountsVM.accounts
                                  .firstWhere((a) => a.id == income.accountId, orElse: () => accountsVM.accounts.first)
                                  .name;

                              return Dismissible(
                                key: Key(income.id),
                                direction: DismissDirection.endToStart,
                                background: Container(
                                  alignment: Alignment.centerRight,
                                  padding: const EdgeInsets.only(right: 20),
                                  margin: const EdgeInsets.only(bottom: 12),
                                  decoration: BoxDecoration(
                                    color: Colors.redAccent.withValues(alpha: 0.8),
                                    borderRadius: BorderRadius.circular(20),
                                  ),
                                  child: const Icon(Icons.delete_outline_rounded, color: Colors.white),
                                ),
                                onDismissed: (direction) async {
                                  await incomeVM.deleteIncome(income.id);
                                },
                                child: Container(
                                  margin: const EdgeInsets.only(bottom: 12),
                                  padding: const EdgeInsets.all(16),
                                  decoration: BoxDecoration(
                                    color: Theme.of(context).cardColor,
                                    borderRadius: BorderRadius.circular(20),
                                    border: Border.all(color: Theme.of(context).dividerColor.withValues(alpha: 0.08)),
                                    boxShadow: [
                                      BoxShadow(
                                        color: Colors.black.withValues(alpha: isDarkMode ? 0.2 : 0.03),
                                        blurRadius: 10,
                                        offset: const Offset(0, 4),
                                      ),
                                    ],
                                  ),
                                  child: Row(
                                    children: [
                                      Container(
                                        padding: const EdgeInsets.all(12),
                                        decoration: BoxDecoration(
                                          color: const Color(0xFF047857).withValues(alpha: 0.12),
                                          borderRadius: BorderRadius.circular(16),
                                        ),
                                        child: Icon(_getSourceIcon(income.source), color: const Color(0xFF10B981), size: 22),
                                      ),
                                      const SizedBox(width: 14),
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Text(income.source, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                                            const SizedBox(height: 2),
                                            Row(
                                              children: [
                                                Text(DateFormat('dd MMM, yyyy').format(income.date), style: const TextStyle(fontSize: 11, color: Colors.grey)),
                                                const SizedBox(width: 6),
                                                Container(width: 4, height: 4, decoration: const BoxDecoration(color: Colors.grey, shape: BoxShape.circle)),
                                                const SizedBox(width: 6),
                                                Text(accountName, style: TextStyle(fontSize: 11, color: Theme.of(context).colorScheme.primary, fontWeight: FontWeight.bold)),
                                              ],
                                            ),
                                            if (income.description.isNotEmpty) ...[
                                              const SizedBox(height: 4),
                                              Text(
                                                income.description,
                                                style: TextStyle(color: Colors.grey.shade500, fontSize: 11),
                                                maxLines: 1,
                                                overflow: TextOverflow.ellipsis,
                                              ),
                                            ],
                                          ],
                                        ),
                                      ),
                                      const SizedBox(width: 10),
                                      Text(
                                        '+ $currencySymbol${income.amount.toStringAsFixed(0)}',
                                        style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w900, color: Color(0xFF10B981)),
                                      ),
                                    ],
                                  ),
                                ),
                              );
                            },
                          ),
                const SizedBox(height: 80), // FAB padding
              ],
            ),
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showAddIncomeSheet(context),
        backgroundColor: const Color(0xFF047857),
        foregroundColor: Colors.white,
        elevation: 4,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        icon: const Icon(Icons.add_rounded),
        label: const Text('Add Income', style: TextStyle(fontWeight: FontWeight.bold)),
      ),
    );
  }
}

class _AddIncomeSheet extends StatefulWidget {
  const _AddIncomeSheet();

  @override
  State<_AddIncomeSheet> createState() => _AddIncomeSheetState();
}

class _AddIncomeSheetState extends State<_AddIncomeSheet> {
  final _amountController = TextEditingController();
  final _descriptionController = TextEditingController();
  DateTime _selectedDate = DateTime.now();

  String _selectedSource = 'Salary';
  final List<String> _sources = [
    'Salary',
    'Freelance',
    'Refund',
    'Gift',
    'Other',
  ];

  String? _selectedAccountId;

  void _saveIncome() async {
    if (_amountController.text.isEmpty || _selectedAccountId == null) return;

    final amount = double.tryParse(_amountController.text) ?? 0;
    if (amount <= 0) return;

    final income = IncomeEntity(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      source: _selectedSource,
      description: _descriptionController.text.trim(),
      amount: amount,
      date: _selectedDate,
      accountId: _selectedAccountId!,
    );

    if (mounted) {
      Navigator.pop(context); // close bottom sheet
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => AllocationPreviewScreen(income: income),
        ),
      );
    }
  }

  Widget _buildIncomeShortcutChip(String label, double increment) {
    return InkWell(
      onTap: () {
        final current = double.tryParse(_amountController.text) ?? 0.0;
        setState(() {
          _amountController.text = (current + increment).toStringAsFixed(0);
        });
      },
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
        decoration: BoxDecoration(
          color: Theme.of(context).cardColor,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Theme.of(context).dividerColor.withValues(alpha: 0.1)),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w700,
            color: Theme.of(context).textTheme.bodyMedium?.color,
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final accountsVM = context.watch<AccountsViewModel>();

    if (_selectedAccountId == null && accountsVM.accounts.isNotEmpty) {
      _selectedAccountId = accountsVM.accounts.first.id;
    }

    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).scaffoldBackgroundColor,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
      ),
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom + 24,
        top: 24,
        left: 20,
        right: 20,
      ),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Center(
              child: Text(
                'ADD INCOME RECORD',
                style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, letterSpacing: 1.2, color: Colors.grey),
              ),
            ),
            const SizedBox(height: 18),

            // ── Hero Amount Container ─────────────────────────────────────────
            Container(
              padding: const EdgeInsets.all(22),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF064E3B), Color(0xFF047857)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(26),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF047857).withValues(alpha: 0.35),
                    blurRadius: 18,
                    offset: const Offset(0, 6),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'INCOME AMOUNT',
                    style: TextStyle(color: Colors.greenAccent, fontSize: 10, fontWeight: FontWeight.bold, letterSpacing: 1.1),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.baseline,
                    textBaseline: TextBaseline.alphabetic,
                    children: [
                      Text(
                        currencySymbol,
                        style: const TextStyle(color: Colors.greenAccent, fontSize: 34, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: TextField(
                          controller: _amountController,
                          keyboardType: const TextInputType.numberWithOptions(decimal: true),
                          style: const TextStyle(color: Colors.white, fontSize: 38, fontWeight: FontWeight.w900),
                          decoration: const InputDecoration(
                            hintText: '0',
                            hintStyle: TextStyle(color: Colors.white30),
                            border: InputBorder.none,
                            isDense: true,
                            contentPadding: EdgeInsets.zero,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            // ── Quick Amount Shortcut Pills ────────────────────────────────────
            const SizedBox(height: 14),
            Text(
              'QUICK SHORTCUTS',
              style: TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.w800,
                letterSpacing: 1.0,
                color: Theme.of(context).textTheme.bodySmall?.color ?? Colors.grey,
              ),
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                _buildIncomeShortcutChip('+₹5,000', 5000),
                _buildIncomeShortcutChip('+₹10,000', 10000),
                _buildIncomeShortcutChip('+₹25,000', 25000),
                _buildIncomeShortcutChip('+₹50,000', 50000),
              ],
            ),

            const SizedBox(height: 20),

            // ── Income Source Category Chips ────────────────────────────────
            Text(
              'INCOME SOURCE',
              style: TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.w800,
                letterSpacing: 1.0,
                color: Theme.of(context).textTheme.bodySmall?.color ?? Colors.grey,
              ),
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: _sources.map((s) {
                final isSelected = _selectedSource == s;
                return InkWell(
                  onTap: () => setState(() => _selectedSource = s),
                  borderRadius: BorderRadius.circular(12),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                    decoration: BoxDecoration(
                      color: isSelected
                          ? const Color(0xFF047857).withValues(alpha: 0.15)
                          : Theme.of(context).cardColor,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: isSelected
                            ? const Color(0xFF047857)
                            : Theme.of(context).dividerColor.withValues(alpha: 0.1),
                        width: isSelected ? 1.8 : 1.0,
                      ),
                    ),
                    child: Text(
                      s,
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,
                        color: isSelected ? const Color(0xFF047857) : Theme.of(context).textTheme.bodyMedium?.color,
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),

            const SizedBox(height: 20),

            // ── Account Picker Label & Cards ─────────────────────────────────
            Text(
              'DEPOSIT TO ACCOUNT',
              style: TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.w800,
                letterSpacing: 1.0,
                color: Theme.of(context).textTheme.bodySmall?.color ?? Colors.grey,
              ),
            ),
            const SizedBox(height: 8),
            if (accountsVM.accounts.isNotEmpty)
              SizedBox(
                height: 65,
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  itemCount: accountsVM.accounts.length,
                  itemBuilder: (context, index) {
                    final a = accountsVM.accounts[index];
                    final isSelected = _selectedAccountId == a.id;
                    return GestureDetector(
                      onTap: () => setState(() => _selectedAccountId = a.id),
                      child: Container(
                        width: 140,
                        margin: const EdgeInsets.only(right: 10),
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: isSelected
                              ? const Color(0xFF047857).withValues(alpha: 0.15)
                              : Theme.of(context).cardColor,
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(
                            color: isSelected
                                ? const Color(0xFF047857)
                                : Theme.of(context).dividerColor.withValues(alpha: 0.1),
                            width: isSelected ? 1.8 : 1.0,
                          ),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Row(
                              children: [
                                Icon(
                                  Icons.account_balance_wallet_rounded,
                                  size: 14,
                                  color: isSelected ? const Color(0xFF047857) : Theme.of(context).iconTheme.color,
                                ),
                                const SizedBox(width: 4),
                                Expanded(
                                  child: Text(
                                    a.name,
                                    style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700),
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 2),
                            Text(
                              CurrencyFormatter.format(a.openingBalance),
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                                color: Theme.of(context).textTheme.bodySmall?.color,
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),

            const SizedBox(height: 16),

            // ── Description Input ────────────────────────────────────────────
            TextField(
              controller: _descriptionController,
              decoration: InputDecoration(
                labelText: 'Description (Optional)',
                prefixIcon: const Icon(Icons.notes_rounded, size: 20),
                filled: true,
                fillColor: Theme.of(context).cardColor,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: BorderSide(color: Theme.of(context).dividerColor.withValues(alpha: 0.1)),
                ),
              ),
            ),

            const SizedBox(height: 16),

            // ── Date Selector ─────────────────────────────────────────────────
            InkWell(
              onTap: () async {
                final date = await showDatePicker(
                  context: context,
                  initialDate: _selectedDate,
                  firstDate: DateTime(2000),
                  lastDate: DateTime.now().add(const Duration(days: 365)),
                );
                if (date != null) setState(() => _selectedDate = date);
              },
              borderRadius: BorderRadius.circular(16),
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Theme.of(context).cardColor,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: Theme.of(context).dividerColor.withValues(alpha: 0.1)),
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: const Color(0xFF047857).withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Icon(Icons.calendar_month_rounded, color: Color(0xFF047857), size: 18),
                    ),
                    const SizedBox(width: 12),
                    const Text('Income Date', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
                    const Spacer(),
                    Text(
                      DateFormat('MMM dd, yyyy').format(_selectedDate),
                      style: const TextStyle(
                        color: Color(0xFF047857),
                        fontWeight: FontWeight.bold,
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 24),

            // ── Submit CTA Button ─────────────────────────────────────────────
            SizedBox(
              height: 52,
              child: ElevatedButton(
                onPressed: _saveIncome,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF047857),
                  foregroundColor: Colors.white,
                  elevation: 2,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                ),
                child: const Text(
                  'CONTINUE & ALLOCATE INCOME',
                  style: TextStyle(fontSize: 14, fontWeight: FontWeight.w900, letterSpacing: 0.8),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
