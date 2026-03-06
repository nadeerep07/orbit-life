import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:share_plus/share_plus.dart';
import '../theme/app_theme.dart';
import '../viewmodels/borrow_lend_view_model.dart';
import '../viewmodels/accounts_view_model.dart';
import '../../domain/entities/borrow_lend_entity.dart';
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

    double balanceRemaining =
        (totalLent - totalReceived) - (totalBorrowed - totalRepaid);

    return Scaffold(
      appBar: AppBar(
        title: Text(personName),
        actions: [
          IconButton(
            icon: const Icon(Icons.share),
            onPressed: () => _shareStatement(
              personEntries,
              totalLent,
              totalReceived,
              totalBorrowed,
              totalRepaid,
              balanceRemaining,
            ),
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
            const Divider(height: 1),
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              child: Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  'Transactions',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
              ),
            ),
            Expanded(
              child: personEntries.isEmpty
                  ? const Center(child: Text('No transactions found.'))
                  : ListView.builder(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      itemCount: personEntries.length,
                      itemBuilder: (context, index) {
                        final entry = personEntries[index];
                        return _buildDismissibleCard(
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
    IconData balanceIcon;

    if (balance > 0) {
      balanceText = '₹${balance.abs().toStringAsFixed(0)} owed to you';
      balanceColor = Colors.green;
      balanceIcon = Icons.trending_up;
    } else if (balance < 0) {
      balanceText = 'You owe ₹${balance.abs().toStringAsFixed(0)}';
      balanceColor = Theme.of(context).colorScheme.error;
      balanceIcon = Icons.trending_down;
    } else {
      balanceText = 'All settled';
      balanceColor = Theme.of(context).colorScheme.onSurfaceVariant;
      balanceIcon = Icons.check_circle_outline;
    }

    return IOSCard(
      margin: const EdgeInsets.fromLTRB(16, 16, 16, 8),
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          Row(
            children: [
              CircleAvatar(
                radius: 22,
                backgroundColor: Theme.of(context).colorScheme.primaryContainer,
                child: Text(
                  personName.isNotEmpty ? personName[0].toUpperCase() : '?',
                  style: TextStyle(
                    color: Theme.of(context).colorScheme.onPrimaryContainer,
                    fontWeight: FontWeight.bold,
                    fontSize: 18,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      personName,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    if (phoneNumber.isNotEmpty)
                      Text(
                        phoneNumber,
                        style: const TextStyle(
                          color: Colors.grey,
                          fontSize: 13,
                        ),
                      ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: balanceColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    Icon(balanceIcon, color: balanceColor, size: 16),
                    const SizedBox(width: 4),
                    Text(
                      balanceText,
                      style: TextStyle(
                        color: balanceColor,
                        fontWeight: FontWeight.bold,
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          if (lent > 0 || received > 0 || borrowed > 0 || repaid > 0) ...[
            const Divider(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                if (lent > 0)
                  _summaryChip(
                    context,
                    'Lent',
                    '₹${lent.toStringAsFixed(0)}',
                    Colors.orange,
                  ),
                if (received > 0)
                  _summaryChip(
                    context,
                    'Received',
                    '₹${received.toStringAsFixed(0)}',
                    Colors.green,
                  ),
                if (borrowed > 0)
                  _summaryChip(
                    context,
                    'Borrowed',
                    '₹${borrowed.toStringAsFixed(0)}',
                    Theme.of(context).colorScheme.error,
                  ),
                if (repaid > 0)
                  _summaryChip(
                    context,
                    'Repaid',
                    '₹${repaid.toStringAsFixed(0)}',
                    Colors.teal,
                  ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _summaryChip(
    BuildContext context,
    String label,
    String value,
    Color color,
  ) {
    return Column(
      children: [
        Text(
          value,
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: color,
            fontSize: 15,
          ),
        ),
        const SizedBox(height: 2),
        Text(label, style: const TextStyle(fontSize: 11, color: Colors.grey)),
      ],
    );
  }

  Widget _buildDismissibleCard(
    BuildContext context,
    BorrowLendEntity entry,
    AccountsViewModel accountsVM,
    BorrowLendViewModel borrowLendVM,
  ) {
    return Dismissible(
      key: Key(entry.id),
      direction: DismissDirection.endToStart,
      confirmDismiss: (_) => _confirmDelete(context),
      onDismissed: (_) => borrowLendVM.deleteEntry(entry),
      background: Container(
        margin: const EdgeInsets.only(bottom: 12),
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.symmetric(horizontal: 20),
        decoration: BoxDecoration(
          color: Colors.red,
          borderRadius: BorderRadius.circular(12),
        ),
        child: const Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.delete_outline, color: Colors.white, size: 28),
            SizedBox(height: 4),
            Text(
              'Delete',
              style: TextStyle(
                color: Colors.white,
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
      child: _buildEntryCard(context, entry, accountsVM, borrowLendVM),
    );
  }

  Widget _buildEntryCard(
    BuildContext context,
    BorrowLendEntity entry,
    AccountsViewModel accountsVM,
    BorrowLendViewModel borrowLendVM,
  ) {
    final bool isPending = entry.status == 'pending';
    final bool isLent = entry.type == 'lent';
    final Color amountColor = isLent
        ? Colors.orange
        : Theme.of(context).colorScheme.error;

    return GestureDetector(
      onTap: () =>
          _showEntryDetailSheet(context, entry, accountsVM, borrowLendVM),
      child: IOSCard(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Row 1: Date + Amount
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Icon(
                      isLent ? Icons.trending_up : Icons.trending_down,
                      size: 16,
                      color: amountColor,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      DateFormat('dd MMM yyyy').format(entry.date),
                      style: const TextStyle(
                        fontWeight: FontWeight.w500,
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
                Text(
                  '₹${entry.amount.toStringAsFixed(0)}',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                    color: amountColor,
                    decoration: !isPending ? TextDecoration.lineThrough : null,
                    decorationColor: amountColor,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 6),

            // Row 2: Status + Due date
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 3,
                  ),
                  decoration: BoxDecoration(
                    color: isPending
                        ? Colors.orange.withValues(alpha: 0.12)
                        : Colors.green.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    isPending ? 'Pending' : 'Completed',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: isPending ? Colors.orange : Colors.green,
                    ),
                  ),
                ),
                if (isPending && entry.dueDate != null)
                  Row(
                    children: [
                      const Icon(Icons.event, size: 13, color: Colors.grey),
                      const SizedBox(width: 4),
                      Text(
                        'Due: ${DateFormat('dd MMM').format(entry.dueDate!)}',
                        style: const TextStyle(
                          fontSize: 12,
                          color: Colors.grey,
                        ),
                      ),
                    ],
                  ),
              ],
            ),

            // Row 3: Remaining balance
            if (isPending && entry.transactions.isNotEmpty) ...[
              const SizedBox(height: 6),
              Text(
                'Remaining: ₹${entry.remainingAmount.toStringAsFixed(0)}',
                style: TextStyle(
                  fontSize: 12,
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],

            // Row 4: Record Payment button
            if (isPending) ...[
              const SizedBox(height: 10),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: () => _showRecordPaymentDialog(
                    context,
                    entry,
                    accountsVM,
                    borrowLendVM,
                  ),
                  icon: const Icon(Icons.add_circle_outline, size: 16),
                  label: const Text('Record Payment'),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    textStyle: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Future<bool?> _confirmDelete(BuildContext context) {
    return showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Transaction'),
        content: const Text(
          'Are you sure you want to delete this entry? This action cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            child: const Text('Delete'),
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
  ) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (ctx) {
        return DraggableScrollableSheet(
          initialChildSize: 0.6,
          minChildSize: 0.4,
          maxChildSize: 0.9,
          expand: false,
          builder: (_, scrollController) {
            return SingleChildScrollView(
              controller: scrollController,
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Handle bar
                  Center(
                    child: Container(
                      width: 40,
                      height: 4,
                      margin: const EdgeInsets.only(bottom: 16),
                      decoration: BoxDecoration(
                        color: Colors.grey.withValues(alpha: 0.4),
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),

                  // Title row
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        entry.type == 'lent'
                            ? 'Amount Lent'
                            : 'Amount Borrowed',
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        '₹${entry.amount.toStringAsFixed(0)}',
                        style: TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                          color: entry.type == 'lent'
                              ? Colors.orange
                              : Theme.of(context).colorScheme.error,
                        ),
                      ),
                    ],
                  ),
                  const Divider(height: 24),

                  _detailRow(
                    'Date',
                    DateFormat('dd MMM yyyy, hh:mm a').format(entry.date),
                  ),
                  if (entry.dueDate != null)
                    _detailRow(
                      'Due Date',
                      DateFormat('dd MMM yyyy').format(entry.dueDate!),
                    ),
                  _detailRow('Status', entry.status.toUpperCase()),
                  _detailRow(
                    'Remaining',
                    '₹${entry.remainingAmount.toStringAsFixed(0)}',
                  ),
                  if (entry.note.isNotEmpty) ...[
                    const Divider(height: 20),
                    const Text(
                      'Note',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      entry.note,
                      style: const TextStyle(
                        fontSize: 14,
                        fontStyle: FontStyle.italic,
                        color: Colors.grey,
                      ),
                    ),
                  ],

                  if (entry.transactions.isNotEmpty) ...[
                    const Divider(height: 20),
                    const Text(
                      'Payment History',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                      ),
                    ),
                    const SizedBox(height: 8),
                    ...entry.transactions.map((t) {
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 8),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Row(
                              children: [
                                const Icon(
                                  Icons.check_circle,
                                  size: 14,
                                  color: Colors.green,
                                ),
                                const SizedBox(width: 6),
                                Text(
                                  DateFormat('dd MMM yyyy').format(t.date),
                                  style: const TextStyle(fontSize: 13),
                                ),
                              ],
                            ),
                            Text(
                              '+₹${t.amount.toStringAsFixed(0)}',
                              style: const TextStyle(
                                fontWeight: FontWeight.w600,
                                color: Colors.green,
                                fontSize: 13,
                              ),
                            ),
                          ],
                        ),
                      );
                    }),
                  ],

                  const Divider(height: 24),

                  // Action buttons
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton.icon(
                          icon: const Icon(Icons.edit_outlined, size: 16),
                          label: const Text('Edit'),
                          onPressed: () {
                            Navigator.pop(ctx);
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) =>
                                    AddBorrowLendScreen(editEntry: entry),
                              ),
                            );
                          },
                          style: OutlinedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: ElevatedButton.icon(
                          icon: const Icon(Icons.delete_outline, size: 16),
                          label: const Text('Delete'),
                          onPressed: () async {
                            Navigator.pop(ctx);
                            final confirmed = await _confirmDelete(context);
                            if (confirmed == true) {
                              borrowLendVM.deleteEntry(entry);
                            }
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.red.shade600,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Widget _detailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(color: Colors.grey, fontSize: 13)),
          Text(
            value,
            style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
          ),
        ],
      ),
    );
  }

  void _showRecordPaymentDialog(
    BuildContext context,
    BorrowLendEntity entry,
    AccountsViewModel accountsVM,
    BorrowLendViewModel borrowLendVM,
  ) {
    String? selectedAccountId;
    if (accountsVM.accounts.isNotEmpty) {
      selectedAccountId = accountsVM.accounts.first.id;
    }

    final amtCtrl = TextEditingController(
      text: entry.remainingAmount.toStringAsFixed(0),
    );
    final formKey = GlobalKey<FormState>();

    showDialog(
      context: context,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              title: Text(
                entry.type == 'lent'
                    ? 'Record Received Payment'
                    : 'Record Repaid Payment',
              ),
              content: Form(
                key: formKey,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextFormField(
                      controller: amtCtrl,
                      decoration: const InputDecoration(
                        labelText: 'Amount (₹)',
                        prefixText: '₹ ',
                      ),
                      keyboardType: const TextInputType.numberWithOptions(
                        decimal: true,
                      ),
                      validator: (v) {
                        if (v == null || double.tryParse(v) == null) {
                          return 'Enter a valid amount';
                        }
                        if (double.parse(v) > entry.remainingAmount) {
                          return 'Cannot exceed remaining ₹${entry.remainingAmount.toStringAsFixed(0)}';
                        }
                        if (double.parse(v) <= 0) return 'Must be > 0';
                        return null;
                      },
                    ),
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
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(ctx),
                  child: const Text('Cancel'),
                ),
                ElevatedButton(
                  onPressed: () async {
                    if (formKey.currentState!.validate() &&
                        selectedAccountId != null) {
                      Navigator.pop(ctx);
                      // Confirmation dialog
                      final confirm = await showDialog<bool>(
                        context: context,
                        builder: (c) => AlertDialog(
                          title: const Text('Record Payment'),
                          content: Text(
                            'Are you sure you want to record a payment of ₹${amtCtrl.text}?',
                          ),
                          actions: [
                            TextButton(
                              onPressed: () => Navigator.pop(c, false),
                              child: const Text('Cancel'),
                            ),
                            ElevatedButton(
                              onPressed: () => Navigator.pop(c, true),
                              child: const Text('Confirm'),
                            ),
                          ],
                        ),
                      );
                      if (confirm == true) {
                        borrowLendVM.addTransactionToEntry(
                          entry: entry,
                          amountToPay: double.parse(amtCtrl.text),
                          accountIdToUpdate: selectedAccountId!,
                          date: DateTime.now(),
                        );
                      }
                    }
                  },
                  child: const Text('Record'),
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
      sb.writeln('$dateStr - $verb ₹${e.amount.toStringAsFixed(0)}');
      for (var t in e.transactions) {
        String payDate = DateFormat('dd MMM yyyy').format(t.date);
        sb.writeln('  $payDate - Payment ₹${t.amount.toStringAsFixed(0)}');
      }
    }

    SharePlus.instance.share(
      ShareParams(text: sb.toString(), subject: 'Statement with $personName'),
    );
  }
}
