import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../viewmodels/borrow_lend_view_model.dart';
import '../../core/utils/app_routes.dart';
import '../../core/utils/currency_formatter.dart';
import '../../domain/entities/borrow_lend_entity.dart';
import 'borrow_lend_detail_screen.dart';

class BorrowLendScreen extends StatefulWidget {
  const BorrowLendScreen({super.key});

  @override
  State<BorrowLendScreen> createState() => _BorrowLendScreenState();
}

class _BorrowLendScreenState extends State<BorrowLendScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<BorrowLendViewModel>().loadEntries();
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDarkMode = theme.brightness == Brightness.dark;
    final viewModel = context.watch<BorrowLendViewModel>();

    // Compute summary figures
    double totalLent = 0;
    double totalBorrowed = 0;
    for (var e in viewModel.entries) {
      if (e.status == 'pending') {
        if (e.type == 'lent') totalLent += e.amount;
        else totalBorrowed += e.amount;
      }
    }

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        title: const Text(
          'Borrow & Lend',
          style: TextStyle(fontWeight: FontWeight.w900, fontSize: 20),
        ),
        centerTitle: false,
        elevation: 0,
        backgroundColor: Colors.transparent,
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 12),
            child: ElevatedButton.icon(
              onPressed: () => Navigator.pushNamed(context, AppRoutes.addBorrowLend),
              icon: const Icon(Icons.add_rounded, size: 16),
              label: const Text('New', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
              style: ElevatedButton.styleFrom(
                backgroundColor: theme.colorScheme.primary,
                foregroundColor: Colors.white,
                elevation: 0,
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              ),
            ),
          ),
        ],
      ),
      body: Column(
        children: [
          // ── Summary Banner ────────────────────────────────────────────────
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 4, 20, 16),
            child: Row(
              children: [
                Expanded(
                  child: _SummaryTile(
                    label: 'RECEIVABLE',
                    amount: totalLent,
                    icon: Icons.north_east_rounded,
                    color: const Color(0xFF10B981),
                    isDarkMode: isDarkMode,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _SummaryTile(
                    label: 'PAYABLE',
                    amount: totalBorrowed,
                    icon: Icons.south_west_rounded,
                    color: const Color(0xFFF43F5E),
                    isDarkMode: isDarkMode,
                  ),
                ),
              ],
            ),
          ),

          // ── Tab Bar ───────────────────────────────────────────────────────
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Container(
              padding: const EdgeInsets.all(4),
              decoration: BoxDecoration(
                color: isDarkMode ? const Color(0xFF1E293B) : const Color(0xFFF1F5F9),
                borderRadius: BorderRadius.circular(16),
              ),
              child: TabBar(
                controller: _tabController,
                indicator: BoxDecoration(
                  color: theme.colorScheme.primary,
                  borderRadius: BorderRadius.circular(12),
                ),
                indicatorSize: TabBarIndicatorSize.tab,
                labelColor: Colors.white,
                unselectedLabelColor: isDarkMode ? Colors.white54 : Colors.black54,
                labelStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                dividerColor: Colors.transparent,
                tabs: const [
                  Tab(text: 'Money Lent'),
                  Tab(text: 'Money Borrowed'),
                ],
              ),
            ),
          ),
          const SizedBox(height: 12),

          // ── Tab Content ───────────────────────────────────────────────────
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                _BorrowLendList(type: 'lent', isDarkMode: isDarkMode),
                _BorrowLendList(type: 'borrowed', isDarkMode: isDarkMode),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _SummaryTile extends StatelessWidget {
  final String label;
  final double amount;
  final IconData icon;
  final Color color;
  final bool isDarkMode;

  const _SummaryTile({
    required this.label,
    required this.amount,
    required this.icon,
    required this.color,
    required this.isDarkMode,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: color.withOpacity(isDarkMode ? 0.12 : 0.07),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: color.withOpacity(0.2)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: color.withOpacity(0.15),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: color, size: 16),
          ),
          const SizedBox(width: 10),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: TextStyle(
                  fontSize: 8,
                  fontWeight: FontWeight.bold,
                  color: color,
                  letterSpacing: 0.5,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                '$currencySymbol${amount.toStringAsFixed(0)}',
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w900,
                  color: isDarkMode ? Colors.white : Colors.black87,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _BorrowLendList extends StatelessWidget {
  final String type;
  final bool isDarkMode;

  const _BorrowLendList({required this.type, required this.isDarkMode});

  @override
  Widget build(BuildContext context) {
    final viewModel = context.watch<BorrowLendViewModel>();
    final theme = Theme.of(context);
    final cardBgColor = isDarkMode ? const Color(0xFF1E293B) : Colors.white;
    final borderColor = isDarkMode ? const Color(0xFF334155) : const Color(0xFFE2E8F0);
    final textMutedColor = isDarkMode ? Colors.white54 : Colors.black54;
    final accentColor = type == 'lent' ? const Color(0xFF10B981) : const Color(0xFFF43F5E);

    if (viewModel.isLoading) {
      return Center(
        child: CircularProgressIndicator(color: theme.colorScheme.primary),
      );
    }

    final allEntries = viewModel.entries.where((e) => e.type == type).toList();

    // Group by phone number
    final Map<String, List<BorrowLendEntity>> grouped = {};
    for (var e in allEntries) {
      if (e.status == 'pending') {
        grouped.putIfAbsent(e.phoneNumber, () => []).add(e);
      }
    }

    final persons = grouped.values.toList();
    // Remove person groups with zero pending balance
    persons.removeWhere((entries) {
      final bal = entries.fold(0.0, (sum, e) => sum + e.amount);
      return bal <= 0;
    });

    if (persons.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: accentColor.withOpacity(0.08),
                shape: BoxShape.circle,
              ),
              child: Icon(
                type == 'lent' ? Icons.north_east_rounded : Icons.south_west_rounded,
                size: 40,
                color: accentColor,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              type == 'lent' ? 'No outstanding lent money' : 'No outstanding borrowed money',
              style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(
              'All dues are settled!',
              style: TextStyle(color: textMutedColor, fontSize: 12),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
      itemCount: persons.length,
      itemBuilder: (context, index) {
        final entries = persons[index];
        final personName = entries.first.personName;
        final phoneNumber = entries.first.phoneNumber;

        final pendingBalance = entries.fold(0.0, (sum, e) => sum + e.amount);

        // Find nearest due date
        DateTime? nextDue;
        for (var e in entries) {
          if (e.dueDate != null) {
            if (nextDue == null || e.dueDate!.isBefore(nextDue)) {
              nextDue = e.dueDate;
            }
          }
        }

        final isOverdue = nextDue != null && nextDue.isBefore(DateTime.now());
        final initials = personName.isNotEmpty
            ? personName.trim().split(' ').map((w) => w[0].toUpperCase()).take(2).join()
            : '?';

        return Container(
          margin: const EdgeInsets.only(bottom: 14),
          decoration: BoxDecoration(
            color: cardBgColor,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: isOverdue ? const Color(0xFFEF4444).withOpacity(0.4) : borderColor,
              width: isOverdue ? 1.5 : 1,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(isDarkMode ? 0.15 : 0.03),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(20),
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => BorrowLendDetailScreen(
                        personName: personName,
                        phoneNumber: phoneNumber,
                      ),
                    ),
                  );
                },
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    children: [
                      // Avatar
                      Container(
                        width: 48,
                        height: 48,
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [
                              accentColor.withOpacity(0.8),
                              accentColor,
                            ],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          shape: BoxShape.circle,
                        ),
                        alignment: Alignment.center,
                        child: Text(
                          initials,
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                      ),
                      const SizedBox(width: 14),

                      // Name & Due info
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              personName,
                              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                            ),
                            const SizedBox(height: 4),
                            if (nextDue != null)
                              Row(
                                children: [
                                  Icon(
                                    isOverdue ? Icons.warning_amber_rounded : Icons.event_rounded,
                                    size: 12,
                                    color: isOverdue ? const Color(0xFFEF4444) : textMutedColor,
                                  ),
                                  const SizedBox(width: 4),
                                  Text(
                                    isOverdue
                                        ? 'Overdue · ${DateFormat('dd MMM').format(nextDue)}'
                                        : 'Due ${DateFormat('dd MMM yyyy').format(nextDue)}',
                                    style: TextStyle(
                                      fontSize: 11,
                                      color: isOverdue ? const Color(0xFFEF4444) : textMutedColor,
                                      fontWeight: isOverdue ? FontWeight.bold : FontWeight.normal,
                                    ),
                                  ),
                                ],
                              )
                            else
                              Text(
                                '${entries.length} transaction${entries.length > 1 ? 's' : ''}',
                                style: TextStyle(fontSize: 11, color: textMutedColor),
                              ),
                          ],
                        ),
                      ),

                      // Amount & Arrow
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Text(
                            '$currencySymbol${pendingBalance.toStringAsFixed(0)}',
                            style: TextStyle(
                              fontWeight: FontWeight.w900,
                              fontSize: 16,
                              color: accentColor,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Icon(Icons.chevron_right_rounded, size: 18, color: textMutedColor),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}
