import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../theme/app_theme.dart';
import '../viewmodels/borrow_lend_view_model.dart';
import '../../core/utils/app_routes.dart';
import '../../domain/entities/borrow_lend_entity.dart';
import 'borrow_lend_detail_screen.dart';

class BorrowLendScreen extends StatefulWidget {
  const BorrowLendScreen({super.key});

  @override
  State<BorrowLendScreen> createState() => _BorrowLendScreenState();
}

class _BorrowLendScreenState extends State<BorrowLendScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<BorrowLendViewModel>().loadEntries();
    });
  }

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Borrow & Lend'),
          bottom: const TabBar(
            tabs: [
              Tab(text: "Money Lent"),
              Tab(text: "Money Borrowed"),
            ],
          ),
        ),
        body: const TabBarView(
          children: [
            _BorrowLendList(type: 'lent'),
            _BorrowLendList(type: 'borrowed'),
          ],
        ),
        floatingActionButton: FloatingActionButton(
          onPressed: () =>
              Navigator.pushNamed(context, AppRoutes.addBorrowLend),
          child: const Icon(Icons.add),
        ),
      ),
    );
  }
}

class _BorrowLendList extends StatelessWidget {
  final String type;
  const _BorrowLendList({required this.type});

  @override
  Widget build(BuildContext context) {
    final viewModel = context.watch<BorrowLendViewModel>();

    if (viewModel.isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    final allEntries = viewModel.entries.where((e) => e.type == type).toList();
    if (allEntries.isEmpty) {
      return Center(
        child: Text(
          type == 'lent' ? 'No money lent yet.' : 'No money borrowed yet.',
          style: TextStyle(
            color: Theme.of(context).colorScheme.onSurfaceVariant,
          ),
        ),
      );
    }

    // Group by phone number
    final Map<String, List<BorrowLendEntity>> grouped = {};
    for (var e in allEntries) {
      grouped.putIfAbsent(e.phoneNumber, () => []).add(e);
    }

    final uniquePersons = grouped.values.toList();

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: uniquePersons.length,
      itemBuilder: (context, index) {
        final entries = uniquePersons[index];
        final personName = entries.first.personName;
        final phoneNumber = entries.first.phoneNumber;

        // Calculate pending balance
        double pendingBalance = 0.0;
        for (var e in entries) {
          if (e.status == 'pending') {
            pendingBalance += e.amount;
          }
        }

        if (pendingBalance == 0.0) {
          return const SizedBox.shrink();
        }

        // Find nearest due date
        DateTime? nextDue;
        for (var e in entries) {
          if (e.status == 'pending' && e.dueDate != null) {
            if (nextDue == null || e.dueDate!.isBefore(nextDue)) {
              nextDue = e.dueDate;
            }
          }
        }

        return Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: GestureDetector(
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
            child: IOSCard(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  CircleAvatar(
                    backgroundColor: Theme.of(
                      context,
                    ).colorScheme.primaryContainer,
                    child: Text(
                      personName.isNotEmpty ? personName[0].toUpperCase() : '?',
                      style: TextStyle(
                        color: Theme.of(context).colorScheme.onPrimaryContainer,
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          personName,
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '₹${pendingBalance.toStringAsFixed(0)} ${type == 'lent' ? 'Lent' : 'Borrowed'}',
                          style: TextStyle(
                            color: type == 'lent'
                                ? Colors.green
                                : Theme.of(context).colorScheme.error,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        if (nextDue != null) ...[
                          const SizedBox(height: 4),
                          Text(
                            'Due: ${DateFormat('dd MMM yyyy').format(nextDue)}',
                            style: TextStyle(
                              fontSize: 12,
                              color: Theme.of(
                                context,
                              ).colorScheme.onSurfaceVariant,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                  const Icon(Icons.chevron_right, color: Colors.grey),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}
