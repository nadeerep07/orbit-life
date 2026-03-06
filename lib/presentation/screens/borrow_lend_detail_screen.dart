import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:share_plus/share_plus.dart';
import '../theme/app_theme.dart';
import '../viewmodels/borrow_lend_view_model.dart';
import '../viewmodels/accounts_view_model.dart';
import '../../domain/entities/borrow_lend_entity.dart';

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
    final viewModel = context.watch<BorrowLendViewModel>();
    final accountsVM = context.watch<AccountsViewModel>();

    // Filter all entries for this person
    final personEntries = viewModel.entries
        .where((e) => e.phoneNumber == phoneNumber)
        .toList();

    // Calculate totals
    double totalLent = 0;
    double totalReceived = 0;
    double totalBorrowed = 0;
    double totalRepaid = 0;

    for (var e in personEntries) {
      if (e.type == 'lent') {
        totalLent += e.amount;
        if (e.status == 'completed') {
          totalReceived += e.amount;
        }
      } else if (e.type == 'borrowed') {
        totalBorrowed += e.amount;
        if (e.status == 'completed') {
          totalRepaid += e.amount;
        }
      }
    }

    double balanceRemaining =
        (totalLent - totalReceived) - (totalBorrowed - totalRepaid);

    return Scaffold(
      appBar: AppBar(
        title: Text(personName),
        actions: [
          IconButton(
            icon: const Icon(Icons.share),
            onPressed: () {
              _shareStatement(
                personEntries,
                totalLent,
                totalReceived,
                totalBorrowed,
                totalRepaid,
                balanceRemaining,
              );
            },
          ),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            _buildSummaryHeader(
              context,
              totalLent,
              totalReceived,
              totalBorrowed,
              totalRepaid,
              balanceRemaining,
            ),
            const Divider(),
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  'Transaction History',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
              ),
            ),
            Expanded(
              child: personEntries.isEmpty
                  ? const Center(child: Text('No transactions.'))
                  : ListView.builder(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 8,
                      ),
                      itemCount: personEntries.length,
                      itemBuilder: (context, index) {
                        final entry = personEntries[index];
                        return _buildTransactionCard(
                          context,
                          entry,
                          accountsVM,
                          viewModel,
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSummaryHeader(
    BuildContext context,
    double lent,
    double received,
    double borrowed,
    double repaid,
    double balance,
  ) {
    String balanceText;
    Color balanceColor;
    if (balance > 0) {
      balanceText = 'Needs to pay you ₹${balance.abs().toStringAsFixed(0)}';
      balanceColor = Colors.green;
    } else if (balance < 0) {
      balanceText = 'You owe ₹${balance.abs().toStringAsFixed(0)}';
      balanceColor = Theme.of(context).colorScheme.error;
    } else {
      balanceText = 'Settled';
      balanceColor = Theme.of(context).colorScheme.onSurfaceVariant;
    }

    return IOSCard(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.person, size: 20),
              const SizedBox(width: 8),
              Text(
                personName,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Row(
            children: [
              const Icon(Icons.phone, size: 16, color: Colors.grey),
              const SizedBox(width: 8),
              Text(phoneNumber, style: const TextStyle(color: Colors.grey)),
            ],
          ),
          const Divider(height: 24),
          if (lent > 0 || received > 0) ...[
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Total Lent:'),
                Text(
                  '₹${lent.toStringAsFixed(0)}',
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
              ],
            ),
            const SizedBox(height: 4),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Total Received:'),
                Text(
                  '₹${received.toStringAsFixed(0)}',
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
              ],
            ),
            const SizedBox(height: 12),
          ],
          if (borrowed > 0 || repaid > 0) ...[
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Total Borrowed:'),
                Text(
                  '₹${borrowed.toStringAsFixed(0)}',
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
              ],
            ),
            const SizedBox(height: 4),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Total Repaid:'),
                Text(
                  '₹${repaid.toStringAsFixed(0)}',
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
              ],
            ),
            const SizedBox(height: 12),
          ],
          Text(
            balanceText,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: balanceColor,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTransactionCard(
    BuildContext context,
    BorrowLendEntity entry,
    AccountsViewModel accountsVM,
    BorrowLendViewModel borrowLendVM,
  ) {
    bool isLent = entry.type == 'lent';
    bool isPending = entry.status == 'pending';

    String actionWord = isLent
        ? (isPending ? 'Lent' : 'Received')
        : (isPending ? 'Borrowed' : 'Repaid');
    Color amountColor = isLent
        ? (isPending ? Theme.of(context).colorScheme.error : Colors.green)
        : (isPending ? Colors.green : Theme.of(context).colorScheme.error);

    return IOSCard(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                DateFormat('dd MMM yyyy').format(entry.date),
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
              Text(
                '₹${entry.amount.toStringAsFixed(0)}',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: amountColor,
                  fontSize: 16,
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Status: ${isPending ? 'Pending' : 'Completed ($actionWord)'}',
                style: TextStyle(
                  color: isPending ? Colors.orange : Colors.green,
                  fontWeight: FontWeight.w600,
                  fontSize: 12,
                ),
              ),
              if (isPending && entry.dueDate != null)
                Text(
                  'Due: ${DateFormat('dd MMM').format(entry.dueDate!)}',
                  style: const TextStyle(fontSize: 12, color: Colors.grey),
                ),
            ],
          ),
          if (entry.note.isNotEmpty) ...[
            const SizedBox(height: 8),
            Text(
              'Note: ${entry.note}',
              style: const TextStyle(fontSize: 12, fontStyle: FontStyle.italic),
            ),
          ],
          if (isPending) ...[
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () => _showCompletionDialog(
                  context,
                  entry,
                  accountsVM,
                  borrowLendVM,
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Theme.of(
                    context,
                  ).colorScheme.primaryContainer,
                  foregroundColor: Theme.of(
                    context,
                  ).colorScheme.onPrimaryContainer,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                child: Text(isLent ? 'Mark as Received' : 'Mark as Repaid'),
              ),
            ),
          ],
        ],
      ),
    );
  }

  void _showCompletionDialog(
    BuildContext context,
    BorrowLendEntity entry,
    AccountsViewModel accountsVM,
    BorrowLendViewModel borrowLendVM,
  ) {
    String? selectedAccountId;
    if (accountsVM.accounts.isNotEmpty) {
      selectedAccountId = accountsVM.accounts.first.id;
    }

    showDialog(
      context: context,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              title: Text(
                entry.type == 'lent' ? 'Payment Received' : 'Payment Repaid',
              ),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Amount: ₹${entry.amount.toStringAsFixed(0)}'),
                  const SizedBox(height: 16),
                  DropdownButtonFormField<String>(
                    decoration: InputDecoration(
                      labelText: entry.type == 'lent'
                          ? 'Received to Account'
                          : 'Paid from Account',
                    ),
                    initialValue: selectedAccountId,
                    items: accountsVM.accounts.map((acc) {
                      return DropdownMenuItem(
                        value: acc.id,
                        child: Text(acc.name),
                      );
                    }).toList(),
                    onChanged: (val) {
                      setState(() => selectedAccountId = val);
                    },
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(ctx),
                  child: const Text('Cancel'),
                ),
                ElevatedButton(
                  onPressed: () {
                    if (selectedAccountId != null) {
                      borrowLendVM.markAsCompleted(entry, selectedAccountId!);
                      Navigator.pop(ctx);
                    }
                  },
                  child: const Text('Confirm'),
                ),
              ],
            );
          },
        );
      },
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
      sb.writeln('Total Lent: ₹${lent.toStringAsFixed(0)}');
      sb.writeln('Total Received: ₹${received.toStringAsFixed(0)}');
    }
    if (borrowed > 0 || repaid > 0) {
      sb.writeln('Total Borrowed: ₹${borrowed.toStringAsFixed(0)}');
      sb.writeln('Total Repaid: ₹${repaid.toStringAsFixed(0)}');
    }

    if (balance > 0) {
      sb.writeln('Balance Owed To Me: ₹${balance.abs().toStringAsFixed(0)}');
    } else if (balance < 0) {
      sb.writeln('Balance I Owe: ₹${balance.abs().toStringAsFixed(0)}');
    } else {
      sb.writeln('Balance: Settled');
    }

    sb.writeln('----------------------');
    sb.writeln('Transaction History:');

    for (var e in entries) {
      String dateStr = DateFormat('dd MMM yyyy').format(e.date);
      String verb = e.type == 'lent' ? 'Lent' : 'Borrowed';
      if (e.status == 'completed') {
        verb = e.type == 'lent' ? 'Received' : 'Repaid';
      }
      sb.writeln('$dateStr - $verb ₹${e.amount.toStringAsFixed(0)}');
    }

    Share.share(sb.toString(), subject: 'Statement with $personName');
  }
}
