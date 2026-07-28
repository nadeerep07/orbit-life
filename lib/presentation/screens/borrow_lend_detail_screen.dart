import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:share_plus/share_plus.dart';
import '../../core/utils/currency_formatter.dart';
import '../viewmodels/borrow_lend_view_model.dart';
import '../viewmodels/accounts_view_model.dart';
import '../../domain/entities/borrow_lend_entity.dart';
import '../widgets/custom_snackbar.dart';
import 'add_borrow_lend_screen.dart';

class BorrowLendDetailScreen extends StatelessWidget {
  final String personName;
  final String phoneNumber;

  const BorrowLendDetailScreen({
    super.key,
    required this.personName,
    required this.phoneNumber,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final viewModel = context.watch<BorrowLendViewModel>();
    final accountsVM = context.watch<AccountsViewModel>();

    final personEntries = viewModel.entries
        .where((e) => e.phoneNumber == phoneNumber)
        .toList();

    double totalLent = 0;
    double totalReceived = 0;
    double totalBorrowed = 0;
    double totalRepaid = 0;

    for (var e in personEntries) {
      if (e.type == 'lent') {
        totalLent += e.amount;
        for (var t in e.transactions) {
          totalReceived += t.amount;
        }
      } else if (e.type == 'borrowed') {
        totalBorrowed += e.amount;
        for (var t in e.transactions) {
          totalRepaid += t.amount;
        }
      }
    }

    double netRemaining = (totalLent - totalReceived) - (totalBorrowed - totalRepaid);

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC),
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.transparent,
        title: Text(
          personName,
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w800,
            color: isDark ? Colors.white : const Color(0xFF0F172A),
          ),
        ),
        centerTitle: false,
        actions: [
          IconButton(
            icon: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF1E293B) : const Color(0xFFF1F5F9),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.share_rounded,
                size: 18,
                color: isDark ? const Color(0xFF38BDF8) : const Color(0xFF0284C7),
              ),
            ),
            onPressed: () => _shareStatement(
              personEntries,
              totalLent,
              totalReceived,
              totalBorrowed,
              totalRepaid,
              netRemaining,
            ),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            // Modern Hero Summary Card
            _buildHeroSummaryHeader(
              context,
              totalLent,
              totalReceived,
              totalBorrowed,
              totalRepaid,
              netRemaining,
              isDark,
            ),

            Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'DEBT LOG TRANSACTIONS',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 1.1,
                      color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: isDark ? const Color(0xFF1E293B) : const Color(0xFFE2E8F0),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      '${personEntries.length} Records',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        color: isDark ? Colors.white70 : const Color(0xFF334155),
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // Log Cards List
            Expanded(
              child: personEntries.isEmpty
                  ? _buildEmptyState(isDark)
                  : ListView.builder(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      itemCount: personEntries.length,
                      itemBuilder: (context, index) {
                        final entry = personEntries[index];
                        return _buildDismissibleCard(
                          context,
                          entry,
                          accountsVM,
                          viewModel,
                          isDark,
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeroSummaryHeader(
    BuildContext context,
    double lent,
    double received,
    double borrowed,
    double repaid,
    double balance,
    bool isDark,
  ) {
    late String statusTitle;
    late List<Color> gradientColors;
    late IconData statusIcon;

    if (balance > 0) {
      statusTitle = 'Owed to You';
      gradientColors = const [Color(0xFF059669), Color(0xFF10B981)]; // Emerald Green
      statusIcon = Icons.arrow_downward_rounded;
    } else if (balance < 0) {
      statusTitle = 'You Owe';
      gradientColors = const [Color(0xFFDC2626), Color(0xFFEF4444)]; // Vibrant Coral/Red
      statusIcon = Icons.arrow_upward_rounded;
    } else {
      statusTitle = 'All Settled';
      gradientColors = const [Color(0xFF3B82F6), Color(0xFF6366F1)]; // Indigo/Blue
      statusIcon = Icons.check_circle_rounded;
    }

    final cardBg = isDark ? const Color(0xFF1E293B) : Colors.white;
    final borderColor = isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0);

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: borderColor, width: 1.2),
        boxShadow: [
          BoxShadow(
            color: gradientColors.first.withValues(alpha: isDark ? 0.2 : 0.08),
            blurRadius: 20,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        children: [
          // Banner Row
          Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  gradientColors.first.withValues(alpha: 0.12),
                  gradientColors.last.withValues(alpha: 0.03),
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
            ),
            child: Row(
              children: [
                // Avatar Circle with Gradient Border
                Container(
                  padding: const EdgeInsets.all(3),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(colors: gradientColors),
                    shape: BoxShape.circle,
                  ),
                  child: CircleAvatar(
                    radius: 22,
                    backgroundColor: isDark ? const Color(0xFF0F172A) : Colors.white,
                    child: Text(
                      personName.isNotEmpty ? personName[0].toUpperCase() : '?',
                      style: TextStyle(
                        color: gradientColors.first,
                        fontWeight: FontWeight.w900,
                        fontSize: 20,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Text(
                            personName,
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w800,
                              color: isDark ? Colors.white : const Color(0xFF0F172A),
                            ),
                          ),
                          const SizedBox(width: 6),
                          Icon(statusIcon, color: gradientColors.first, size: 18),
                        ],
                      ),
                      if (phoneNumber.isNotEmpty)
                        Text(
                          phoneNumber,
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                            color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
                          ),
                        ),
                    ],
                  ),
                ),

                // Net Balance Badge Card
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(colors: gradientColors),
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: gradientColors.first.withValues(alpha: 0.3),
                        blurRadius: 8,
                        offset: const Offset(0, 3),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        statusTitle.toUpperCase(),
                        style: const TextStyle(
                          fontSize: 9,
                          fontWeight: FontWeight.w900,
                          letterSpacing: 0.8,
                          color: Colors.white70,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        CurrencyFormatter.format(balance.abs()),
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w900,
                          color: Colors.white,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // Metrics Tiles Grid
          if (lent > 0 || received > 0 || borrowed > 0 || repaid > 0)
            Padding(
              padding: const EdgeInsets.all(14),
              child: Row(
                children: [
                  if (lent > 0)
                    Expanded(
                      child: _metricTile(
                        context,
                        'LENT',
                        lent,
                        const Color(0xFFF59E0B),
                        Icons.north_east_rounded,
                        isDark,
                      ),
                    ),
                  if (lent > 0 && (received > 0 || borrowed > 0 || repaid > 0))
                    const SizedBox(width: 8),
                  if (received > 0)
                    Expanded(
                      child: _metricTile(
                        context,
                        'RECEIVED',
                        received,
                        const Color(0xFF10B981),
                        Icons.south_west_rounded,
                        isDark,
                      ),
                    ),
                  if (received > 0 && (borrowed > 0 || repaid > 0))
                    const SizedBox(width: 8),
                  if (borrowed > 0)
                    Expanded(
                      child: _metricTile(
                        context,
                        'BORROWED',
                        borrowed,
                        const Color(0xFFEF4444),
                        Icons.south_east_rounded,
                        isDark,
                      ),
                    ),
                  if (borrowed > 0 && repaid > 0) const SizedBox(width: 8),
                  if (repaid > 0)
                    Expanded(
                      child: _metricTile(
                        context,
                        'REPAID',
                        repaid,
                        const Color(0xFF06B6D4),
                        Icons.north_west_rounded,
                        isDark,
                      ),
                    ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  Widget _metricTile(
    BuildContext context,
    String label,
    double value,
    Color color,
    IconData icon,
    bool isDark,
  ) {
    final bg = isDark
        ? color.withValues(alpha: 0.12)
        : color.withValues(alpha: 0.08);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: color.withValues(alpha: 0.25), width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: color, size: 13),
              const SizedBox(width: 4),
              Expanded(
                child: Text(
                  label,
                  style: TextStyle(
                    fontSize: 9,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 0.6,
                    color: color,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            CurrencyFormatter.format(value),
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w900,
              color: isDark ? Colors.white : const Color(0xFF0F172A),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState(bool isDark) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF1E293B) : const Color(0xFFE2E8F0),
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.receipt_long_outlined,
              size: 44,
              color: isDark ? const Color(0xFF64748B) : const Color(0xFF94A3B8),
            ),
          ),
          const SizedBox(height: 16),
          Text(
            'No Debt Transactions Yet',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: isDark ? Colors.white : const Color(0xFF0F172A),
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'Borrow or lend records with $personName will appear here.',
            style: TextStyle(
              fontSize: 12,
              color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDismissibleCard(
    BuildContext context,
    BorrowLendEntity entry,
    AccountsViewModel accountsVM,
    BorrowLendViewModel borrowLendVM,
    bool isDark,
  ) {
    return Dismissible(
      key: Key(entry.id),
      direction: DismissDirection.endToStart,
      confirmDismiss: (_) => _confirmDelete(context, isDark),
      onDismissed: (_) => borrowLendVM.deleteEntry(entry),
      background: Container(
        margin: const EdgeInsets.only(bottom: 12),
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.symmetric(horizontal: 24),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [Color(0xFFEF4444), Color(0xFFB91C1C)],
          ),
          borderRadius: BorderRadius.circular(20),
        ),
        child: const Row(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            Icon(Icons.delete_forever_rounded, color: Colors.white, size: 24),
            SizedBox(width: 8),
            Text(
              'Delete',
              style: TextStyle(
                color: Colors.white,
                fontSize: 14,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
      child: _buildEntryCard(context, entry, accountsVM, borrowLendVM, isDark),
    );
  }

  Widget _buildEntryCard(
    BuildContext context,
    BorrowLendEntity entry,
    AccountsViewModel accountsVM,
    BorrowLendViewModel borrowLendVM,
    bool isDark,
  ) {
    final bool isPending = entry.status == 'pending';
    final bool isLent = entry.type == 'lent';
    final Color accentColor = isLent ? const Color(0xFFF59E0B) : const Color(0xFFEF4444);
    final cardBg = isDark ? const Color(0xFF1E293B) : Colors.white;
    final borderColor = isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0);
    final textPrimary = isDark ? Colors.white : const Color(0xFF0F172A);
    final textSecondary = isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B);

    final double paidAmount = entry.amount - entry.remainingAmount;
    final double paidPercentage = entry.amount > 0 ? (paidAmount / entry.amount).clamp(0.0, 1.0) : 0.0;

    return GestureDetector(
      onTap: () => _showEntryDetailSheet(context, entry, accountsVM, borrowLendVM, isDark),
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: cardBg,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: borderColor, width: 1.2),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.04),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Row 1: Type Pill + Date + Amount
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                  decoration: BoxDecoration(
                    color: accentColor.withValues(alpha: 0.14),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: accentColor.withValues(alpha: 0.3)),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        isLent ? Icons.arrow_outward_rounded : Icons.south_west_rounded,
                        size: 14,
                        color: accentColor,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        isLent ? 'LENT' : 'BORROWED',
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w900,
                          color: accentColor,
                          letterSpacing: 0.6,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 10),
                Text(
                  DateFormat('dd MMM yyyy').format(entry.date),
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 13,
                    color: textSecondary,
                  ),
                ),
                const Spacer(),
                Text(
                  CurrencyFormatter.format(entry.amount),
                  style: TextStyle(
                    fontWeight: FontWeight.w900,
                    fontSize: 17,
                    color: accentColor,
                    decoration: !isPending ? TextDecoration.lineThrough : null,
                    decorationColor: accentColor,
                  ),
                ),
              ],
            ),

            const SizedBox(height: 12),

            // Row 2: Status Tag + Due Date Indicator
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: isPending
                        ? const Color(0xFFF59E0B).withValues(alpha: 0.12)
                        : const Color(0xFF10B981).withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 6,
                        height: 6,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: isPending ? const Color(0xFFF59E0B) : const Color(0xFF10B981),
                        ),
                      ),
                      const SizedBox(width: 6),
                      Text(
                        isPending ? 'Pending Settlement' : 'Fully Settled',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          color: isPending ? const Color(0xFFD97706) : const Color(0xFF059669),
                        ),
                      ),
                    ],
                  ),
                ),
                if (isPending && entry.dueDate != null)
                  Row(
                    children: [
                      Icon(
                        Icons.event_outlined,
                        size: 14,
                        color: entry.dueDate!.isBefore(DateTime.now())
                            ? const Color(0xFFEF4444)
                            : textSecondary,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        'Due ${DateFormat('dd MMM').format(entry.dueDate!)}',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: entry.dueDate!.isBefore(DateTime.now())
                              ? const Color(0xFFEF4444)
                              : textSecondary,
                        ),
                      ),
                    ],
                  ),
              ],
            ),

            // Progress Bar & Balance breakdown
            if (isPending) ...[
              const SizedBox(height: 12),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Paid: ${CurrencyFormatter.format(paidAmount)}',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: textSecondary,
                        ),
                      ),
                      Text(
                        'Remaining: ${CurrencyFormatter.format(entry.remainingAmount)}',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w800,
                          color: textPrimary,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(4),
                    child: LinearProgressIndicator(
                      value: paidPercentage,
                      minHeight: 6,
                      backgroundColor: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0),
                      valueColor: AlwaysStoppedAnimation<Color>(
                        isLent ? const Color(0xFF10B981) : const Color(0xFF3B82F6),
                      ),
                    ),
                  ),
                ],
              ),
            ],

            // Record Payment Button
            if (isPending) ...[
              const SizedBox(height: 14),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: () => _showRecordPaymentSheet(
                    context,
                    entry,
                    accountsVM,
                    borrowLendVM,
                    isDark,
                  ),
                  icon: const Icon(Icons.add_circle_outline_rounded, size: 17, color: Colors.white),
                  label: Text(
                    isLent ? 'Record Payment Received' : 'Record Repayment Paid',
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: Colors.white,
                    ),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: isLent ? const Color(0xFF059669) : const Color(0xFF2563EB),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                    elevation: 0,
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Future<bool?> _confirmDelete(BuildContext context, bool isDark) {
    return showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: isDark ? const Color(0xFF1E293B) : Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        title: const Row(
          children: [
            Icon(Icons.warning_amber_rounded, color: Color(0xFFEF4444)),
            SizedBox(width: 10),
            Text('Delete Record?', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 18)),
          ],
        ),
        content: const Text(
          'Are you sure you want to delete this debt log entry? This action cannot be undone.',
          style: TextStyle(fontSize: 14),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel', style: TextStyle(fontWeight: FontWeight.w600)),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFEF4444),
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            child: const Text('Delete', style: TextStyle(fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  void _showEntryDetailSheet(
    BuildContext context,
    BorrowLendEntity entry,
    AccountsViewModel accountsVM,
    BorrowLendViewModel borrowLendVM,
    bool isDark,
  ) {
    final bool isLent = entry.type == 'lent';
    final Color accentColor = isLent ? const Color(0xFFF59E0B) : const Color(0xFFEF4444);
    final cardBg = isDark ? const Color(0xFF0F172A) : Colors.white;
    final textPrimary = isDark ? Colors.white : const Color(0xFF0F172A);
    final textSecondary = isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B);

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        return Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: cardBg,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
            border: Border.all(
              color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0),
            ),
          ),
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                // Handle bar
                Center(
                  child: Container(
                    width: 48,
                    height: 5,
                    margin: const EdgeInsets.only(bottom: 20),
                    decoration: BoxDecoration(
                      color: isDark ? Colors.white24 : Colors.black12,
                      borderRadius: BorderRadius.circular(3),
                    ),
                  ),
                ),

                // Header Amount Title
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          isLent ? 'LENT TO' : 'BORROWED FROM',
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w800,
                            letterSpacing: 1.1,
                            color: textSecondary,
                          ),
                        ),
                        Text(
                          personName,
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.w800,
                            color: textPrimary,
                          ),
                        ),
                      ],
                    ),
                    Text(
                      CurrencyFormatter.format(entry.amount),
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.w900,
                        color: accentColor,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),

                // Details Rows Box
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: isDark ? const Color(0xFF1E293B) : const Color(0xFFF8FAFC),
                    borderRadius: BorderRadius.circular(18),
                    border: Border.all(
                      color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0),
                    ),
                  ),
                  child: Column(
                    children: [
                      _modernDetailRow('Initial Date', DateFormat('dd MMM yyyy, hh:mm a').format(entry.date), textPrimary, textSecondary),
                      if (entry.dueDate != null) ...[
                        const Divider(height: 16),
                        _modernDetailRow('Due Date', DateFormat('dd MMM yyyy').format(entry.dueDate!), textPrimary, textSecondary),
                      ],
                      const Divider(height: 16),
                      _modernDetailRow('Current Status', entry.status.toUpperCase(), isLent ? const Color(0xFF10B981) : const Color(0xFF3B82F6), textSecondary),
                      const Divider(height: 16),
                      _modernDetailRow('Remaining Balance', CurrencyFormatter.format(entry.remainingAmount), textPrimary, textSecondary),
                    ],
                  ),
                ),

                if (entry.note.isNotEmpty) ...[
                  const SizedBox(height: 16),
                  Text(
                    'NOTE',
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 1.0,
                      color: textSecondary,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: isDark ? const Color(0xFF1E293B) : const Color(0xFFF1F5F9),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Text(
                      entry.note,
                      style: TextStyle(
                        fontSize: 13,
                        fontStyle: FontStyle.italic,
                        color: textPrimary,
                      ),
                    ),
                  ),
                ],

                // Payment History Timeline
                if (entry.transactions.isNotEmpty) ...[
                  const SizedBox(height: 20),
                  Text(
                    'PAYMENT HISTORY LOGS',
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 1.0,
                      color: textSecondary,
                    ),
                  ),
                  const SizedBox(height: 10),
                  ...entry.transactions.map((t) {
                    return Container(
                      margin: const EdgeInsets.only(bottom: 8),
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: isDark ? const Color(0xFF1E293B) : const Color(0xFFF8FAFC),
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(
                          color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0),
                        ),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Row(
                            children: [
                              const Icon(Icons.check_circle_rounded, size: 16, color: Color(0xFF10B981)),
                              const SizedBox(width: 8),
                              Text(
                                DateFormat('dd MMM yyyy').format(t.date),
                                style: TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600,
                                  color: textPrimary,
                                ),
                              ),
                            ],
                          ),
                          Text(
                            '+ ${CurrencyFormatter.format(t.amount)}',
                            style: const TextStyle(
                              fontWeight: FontWeight.w800,
                              color: Color(0xFF10B981),
                              fontSize: 14,
                            ),
                          ),
                        ],
                      ),
                    );
                  }),
                ],

                const SizedBox(height: 24),

                // Action Buttons
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        icon: const Icon(Icons.edit_rounded, size: 16),
                        label: const Text('Edit Details'),
                        onPressed: () {
                          Navigator.pop(ctx);
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => AddBorrowLendScreen(editEntry: entry),
                            ),
                          );
                        },
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: ElevatedButton.icon(
                        icon: const Icon(Icons.delete_outline_rounded, size: 16),
                        label: const Text('Delete Log'),
                        onPressed: () async {
                          Navigator.pop(ctx);
                          final confirmed = await _confirmDelete(context, isDark);
                          if (confirmed == true) {
                            borrowLendVM.deleteEntry(entry);
                          }
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFFEF4444),
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
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
    );
  }

  Widget _modernDetailRow(String label, String value, Color valueColor, Color labelColor) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: TextStyle(color: labelColor, fontSize: 13, fontWeight: FontWeight.w500)),
        Text(
          value,
          style: TextStyle(fontWeight: FontWeight.w700, fontSize: 13, color: valueColor),
        ),
      ],
    );
  }

  void _showRecordPaymentSheet(
    BuildContext context,
    BorrowLendEntity entry,
    AccountsViewModel accountsVM,
    BorrowLendViewModel borrowLendVM,
    bool isDark,
  ) {
    String? selectedAccountId = accountsVM.accounts.isNotEmpty ? accountsVM.accounts.first.id : null;
    final amtCtrl = TextEditingController(text: entry.remainingAmount.toStringAsFixed(0));
    final formKey = GlobalKey<FormState>();

    final cardBg = isDark ? const Color(0xFF1E293B) : Colors.white;
    final borderColor = isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0);
    final textPrimary = isDark ? Colors.white : const Color(0xFF0F172A);
    final textSecondary = isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B);
    final bool isLent = entry.type == 'lent';

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setState) {
            final keyboardOffset = MediaQuery.of(ctx).viewInsets.bottom;
            final currentVal = double.tryParse(amtCtrl.text) ?? 0.0;

            return Container(
              padding: EdgeInsets.only(
                top: 24,
                left: 20,
                right: 20,
                bottom: 24 + keyboardOffset,
              ),
              decoration: BoxDecoration(
                color: cardBg,
                borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
                border: Border.all(color: borderColor, width: 1.2),
              ),
              child: SingleChildScrollView(
                child: Form(
                  key: formKey,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // Handle bar
                      Center(
                        child: Container(
                          width: 48,
                          height: 4,
                          margin: const EdgeInsets.only(bottom: 20),
                          decoration: BoxDecoration(
                            color: isDark ? Colors.white24 : Colors.black12,
                            borderRadius: BorderRadius.circular(2),
                          ),
                        ),
                      ),

                      Text(
                        isLent ? 'Record Received Payment' : 'Record Repayment Paid',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w800,
                          color: textPrimary,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Record payment for $personName (${CurrencyFormatter.format(entry.remainingAmount)} remaining)',
                        style: TextStyle(
                          fontSize: 12,
                          color: textSecondary,
                        ),
                      ),
                      const SizedBox(height: 20),

                      // Quick Amount Selection Chips
                      Text(
                        'QUICK AMOUNT SHORTCUTS',
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 1.0,
                          color: textSecondary,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Expanded(
                            child: _quickPayShortcutChip(
                              'Full (100%)',
                              entry.remainingAmount,
                              currentVal == entry.remainingAmount,
                              () {
                                setState(() {
                                  amtCtrl.text = entry.remainingAmount.toStringAsFixed(0);
                                });
                              },
                              isDark,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: _quickPayShortcutChip(
                              '50%',
                              entry.remainingAmount * 0.5,
                              currentVal == (entry.remainingAmount * 0.5),
                              () {
                                setState(() {
                                  amtCtrl.text = (entry.remainingAmount * 0.5).toStringAsFixed(0);
                                });
                              },
                              isDark,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: _quickPayShortcutChip(
                              '25%',
                              entry.remainingAmount * 0.25,
                              currentVal == (entry.remainingAmount * 0.25),
                              () {
                                setState(() {
                                  amtCtrl.text = (entry.remainingAmount * 0.25).toStringAsFixed(0);
                                });
                              },
                              isDark,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),

                      // Amount Input Box
                      TextFormField(
                        controller: amtCtrl,
                        keyboardType: const TextInputType.numberWithOptions(decimal: true),
                        style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: textPrimary),
                        decoration: InputDecoration(
                          labelText: 'Payment Amount (₹)',
                          prefixText: '₹ ',
                          prefixStyle: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: isLent ? const Color(0xFF10B981) : const Color(0xFF3B82F6)),
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(16)),
                        ),
                        validator: (v) {
                          if (v == null || double.tryParse(v) == null) {
                            return 'Enter a valid payment amount';
                          }
                          final parsed = double.parse(v);
                          if (parsed > entry.remainingAmount) {
                            return 'Cannot exceed remaining ${CurrencyFormatter.format(entry.remainingAmount)}';
                          }
                          if (parsed <= 0) return 'Must be greater than 0';
                          return null;
                        },
                      ),
                      const SizedBox(height: 20),

                      // Account Selection Label
                      Text(
                        isLent ? 'RECEIVE TO ACCOUNT' : 'PAY FROM ACCOUNT',
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 1.0,
                          color: textSecondary,
                        ),
                      ),
                      const SizedBox(height: 8),

                      // Visual Account Picker Cards
                      if (accountsVM.accounts.isNotEmpty)
                        SizedBox(
                          height: 70,
                          child: ListView.builder(
                            scrollDirection: Axis.horizontal,
                            itemCount: accountsVM.accounts.length,
                            itemBuilder: (context, index) {
                              final acc = accountsVM.accounts[index];
                              final isSelected = selectedAccountId == acc.id;
                              return GestureDetector(
                                onTap: () => setState(() => selectedAccountId = acc.id),
                                child: Container(
                                  width: 140,
                                  margin: const EdgeInsets.only(right: 10),
                                  padding: const EdgeInsets.all(10),
                                  decoration: BoxDecoration(
                                    color: isSelected
                                        ? (isLent ? const Color(0xFF10B981).withValues(alpha: 0.15) : const Color(0xFF3B82F6).withValues(alpha: 0.15))
                                        : (isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC)),
                                    borderRadius: BorderRadius.circular(14),
                                    border: Border.all(
                                      color: isSelected
                                          ? (isLent ? const Color(0xFF10B981) : const Color(0xFF3B82F6))
                                          : borderColor,
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
                                            color: isSelected
                                                ? (isLent ? const Color(0xFF10B981) : const Color(0xFF3B82F6))
                                                : textSecondary,
                                          ),
                                          const SizedBox(width: 4),
                                          Expanded(
                                            child: Text(
                                              acc.name,
                                              style: TextStyle(
                                                fontSize: 12,
                                                fontWeight: FontWeight.w700,
                                                color: textPrimary,
                                              ),
                                              overflow: TextOverflow.ellipsis,
                                            ),
                                          ),
                                        ],
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        CurrencyFormatter.format(acc.openingBalance),
                                        style: TextStyle(
                                          fontSize: 11,
                                          fontWeight: FontWeight.w600,
                                          color: textSecondary,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              );
                            },
                          ),
                        ),

                      const SizedBox(height: 24),

                      // Submit Payment Button
                      ElevatedButton.icon(
                        onPressed: () async {
                          if (formKey.currentState!.validate() && selectedAccountId != null) {
                            final payAmt = double.parse(amtCtrl.text);
                            Navigator.pop(ctx);

                            borrowLendVM.addTransactionToEntry(
                              entry: entry,
                              amountToPay: payAmt,
                              accountIdToUpdate: selectedAccountId!,
                              date: DateTime.now(),
                            );

                            if (context.mounted) {
                              AppSnackBar.show(
                                context,
                                message: 'Recorded payment of ${CurrencyFormatter.format(payAmt)} successfully.',
                                isError: false,
                              );
                            }
                          }
                        },
                        icon: const Icon(Icons.check_circle_rounded, color: Colors.white, size: 18),
                        label: const Text(
                          'Confirm & Record Payment',
                          style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: Colors.white),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: isLent ? const Color(0xFF059669) : const Color(0xFF2563EB),
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                          elevation: 0,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }

  Widget _quickPayShortcutChip(
    String label,
    double amount,
    bool isSelected,
    VoidCallback onTap,
    bool isDark,
  ) {
    final chipBg = isSelected
        ? const Color(0xFF3B82F6).withValues(alpha: 0.15)
        : (isDark ? const Color(0xFF0F172A) : const Color(0xFFF1F5F9));
    final borderColor = isSelected ? const Color(0xFF3B82F6) : (isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0));

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 8),
        decoration: BoxDecoration(
          color: chipBg,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: borderColor, width: isSelected ? 1.5 : 1.0),
        ),
        child: Column(
          children: [
            Text(
              label,
              style: TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.w700,
                color: isSelected ? const Color(0xFF3B82F6) : (isDark ? Colors.white70 : const Color(0xFF475569)),
              ),
            ),
            const SizedBox(height: 2),
            Text(
              CurrencyFormatter.format(amount),
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w800,
                color: isSelected ? const Color(0xFF3B82F6) : (isDark ? Colors.white : const Color(0xFF0F172A)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _shareStatement(
    List<BorrowLendEntity> entries,
    double lent,
    double received,
    double borrowed,
    double repaid,
    double balance,
  ) {
    if (entries.isEmpty) return;

    final sb = StringBuffer();
    sb.writeln('Financial Statement');
    sb.writeln('Name: $personName');
    sb.writeln('----------------------');

    if (lent > 0 || received > 0) {
      sb.writeln('Total Lent: ${CurrencyFormatter.format(lent)}');
      sb.writeln('Total Received: ${CurrencyFormatter.format(received)}');
    }
    if (borrowed > 0 || repaid > 0) {
      sb.writeln('Total Borrowed: ${CurrencyFormatter.format(borrowed)}');
      sb.writeln('Total Repaid: ${CurrencyFormatter.format(repaid)}');
    }

    if (balance > 0) {
      sb.writeln('Balance Owed To Me: ${CurrencyFormatter.format(balance.abs())}');
    } else if (balance < 0) {
      sb.writeln('Balance I Owe: ${CurrencyFormatter.format(balance.abs())}');
    } else {
      sb.writeln('Balance: Settled');
    }

    sb.writeln('----------------------');
    sb.writeln('Transaction History:');

    for (var e in entries) {
      String dateStr = DateFormat('dd MMM yyyy').format(e.date);
      String verb = e.type == 'lent' ? 'Lent' : 'Borrowed';
      sb.writeln('$dateStr - $verb ${CurrencyFormatter.format(e.amount)}');
      for (var t in e.transactions) {
        String payDate = DateFormat('dd MMM yyyy').format(t.date);
        sb.writeln('  $payDate - Payment ${CurrencyFormatter.format(t.amount)}');
      }
    }

    SharePlus.instance.share(
      ShareParams(text: sb.toString(), subject: 'Statement with $personName'),
    );
  }
}
