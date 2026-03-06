import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';

import '../../domain/entities/account_entity.dart';
import '../../domain/entities/transaction_item_entity.dart';
import '../viewmodels/account_detail_view_model.dart';

class AccountDetailScreen extends StatefulWidget {
  final AccountEntity account;

  const AccountDetailScreen({Key? key, required this.account})
    : super(key: key);

  @override
  _AccountDetailScreenState createState() => _AccountDetailScreenState();
}

class _AccountDetailScreenState extends State<AccountDetailScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<AccountDetailViewModel>().loadTransactions(
        widget.account.id,
      );
    });
  }

  void _showSortDialog() {
    final viewModel = context.read<AccountDetailViewModel>();
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Sort Transactions'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _SortOptionTile(
                title: 'Newest First',
                value: TransactionSortOption.newestFirst,
                groupValue: viewModel.sortOption,
                onChanged: (val) {
                  viewModel.setSortOption(val!);
                  Navigator.pop(context);
                },
              ),
              _SortOptionTile(
                title: 'Oldest First',
                value: TransactionSortOption.oldestFirst,
                groupValue: viewModel.sortOption,
                onChanged: (val) {
                  viewModel.setSortOption(val!);
                  Navigator.pop(context);
                },
              ),
              _SortOptionTile(
                title: 'Highest Amount',
                value: TransactionSortOption.highestAmount,
                groupValue: viewModel.sortOption,
                onChanged: (val) {
                  viewModel.setSortOption(val!);
                  Navigator.pop(context);
                },
              ),
              _SortOptionTile(
                title: 'Lowest Amount',
                value: TransactionSortOption.lowestAmount,
                groupValue: viewModel.sortOption,
                onChanged: (val) {
                  viewModel.setSortOption(val!);
                  Navigator.pop(context);
                },
              ),
            ],
          ),
        );
      },
    );
  }

  void _showFilterSheet() {
    final viewModel = context.read<AccountDetailViewModel>();

    // Local state for the bottom sheet
    DateTimeRange? tempDateRange = viewModel.dateRange;
    bool? tempIsCreditFilter = viewModel.isCreditFilter;
    String? tempModuleFilter = viewModel.moduleFilter;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) {
        return StatefulBuilder(
          builder: (BuildContext context, StateSetter setModalState) {
            return Padding(
              padding:
                  const EdgeInsets.all(16.0) +
                  MediaQuery.of(context).viewInsets,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Filter Transactions',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      TextButton(
                        onPressed: () {
                          viewModel.clearFilters();
                          Navigator.pop(context);
                        },
                        child: const Text('Clear All'),
                      ),
                    ],
                  ),
                  const Divider(),

                  // Component Filter
                  const Text(
                    'Type',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  Wrap(
                    spacing: 8.0,
                    children: [
                      ChoiceChip(
                        label: const Text('All'),
                        selected: tempIsCreditFilter == null,
                        onSelected: (val) =>
                            setModalState(() => tempIsCreditFilter = null),
                      ),
                      ChoiceChip(
                        label: const Text('Credit'),
                        selected: tempIsCreditFilter == true,
                        onSelected: (val) =>
                            setModalState(() => tempIsCreditFilter = true),
                      ),
                      ChoiceChip(
                        label: const Text('Debit'),
                        selected: tempIsCreditFilter == false,
                        onSelected: (val) =>
                            setModalState(() => tempIsCreditFilter = false),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  // Module Filter
                  const Text(
                    'Module',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  DropdownButtonFormField<String?>(
                    value: tempModuleFilter,
                    decoration: const InputDecoration(
                      border: OutlineInputBorder(),
                    ),
                    items: const [
                      DropdownMenuItem(value: null, child: Text('All Modules')),
                      DropdownMenuItem(value: 'income', child: Text('Income')),
                      DropdownMenuItem(
                        value: 'expense',
                        child: Text('Expense'),
                      ),
                      DropdownMenuItem(
                        value: 'transfer',
                        child: Text('Transfer'),
                      ),
                      DropdownMenuItem(
                        value: 'borrow_lend',
                        child: Text('Borrow/Lend'),
                      ),
                      DropdownMenuItem(
                        value: 'investment',
                        child: Text('Investment'),
                      ),
                      DropdownMenuItem(value: 'emi', child: Text('EMI/Loan')),
                    ],
                    onChanged: (val) {
                      setModalState(() => tempModuleFilter = val);
                    },
                  ),
                  const SizedBox(height: 16),

                  // Date Filter
                  Flexible(
                    child: ListTile(
                      contentPadding: EdgeInsets.zero,
                      title: const Text(
                        'Date Range',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                      subtitle: Text(
                        tempDateRange == null
                            ? 'All time'
                            : '${DateFormat('dd MMM yyyy').format(tempDateRange!.start)} - ${DateFormat('dd MMM yyyy').format(tempDateRange!.end)}',
                      ),
                      trailing: const Icon(Icons.date_range),
                      onTap: () async {
                        final picked = await showDateRangePicker(
                          context: context,
                          firstDate: DateTime(2000),
                          lastDate: DateTime(2100),
                          initialDateRange: tempDateRange,
                        );
                        if (picked != null) {
                          setModalState(() => tempDateRange = picked);
                        }
                      },
                    ),
                  ),

                  const SizedBox(height: 24),
                  ElevatedButton(
                    onPressed: () {
                      viewModel.setFilter(
                        dateRange: tempDateRange,
                        isCredit: tempIsCreditFilter,
                        moduleType: tempModuleFilter,
                      );
                      Navigator.pop(context);
                    },
                    child: const Text('Apply Filters'),
                  ),
                  const SizedBox(height: 16),
                ],
              ),
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('${widget.account.name} History'),
        actions: [
          IconButton(
            icon: const Icon(Icons.sort),
            onPressed: _showSortDialog,
            tooltip: 'Sort Options',
          ),
          IconButton(
            icon: const Icon(Icons.filter_list),
            onPressed: _showFilterSheet,
            tooltip: 'Filter',
          ),
        ],
      ),
      body: Consumer<AccountDetailViewModel>(
        builder: (context, viewModel, child) {
          if (viewModel.isLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          final transactions = viewModel.transactions;

          return Column(
            children: [
              // Header Summary
              Container(
                padding: const EdgeInsets.all(16.0),
                color: Theme.of(context).primaryColor.withOpacity(0.1),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Account Balance:',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      '₹${viewModel.accountCalculatedBalance.toStringAsFixed(2)}',
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),

              if (transactions.isEmpty)
                const Expanded(
                  child: Center(
                    child: Text('No transactions found for this account.'),
                  ),
                )
              else
                Expanded(
                  child: ListView.separated(
                    itemCount: transactions.length,
                    separatorBuilder: (context, index) =>
                        const Divider(height: 1),
                    itemBuilder: (context, index) {
                      final tx = transactions[index];
                      return _TransactionTile(transaction: tx);
                    },
                  ),
                ),
            ],
          );
        },
      ),
    );
  }
}

class _SortOptionTile extends StatelessWidget {
  final String title;
  final TransactionSortOption value;
  final TransactionSortOption groupValue;
  final ValueChanged<TransactionSortOption?> onChanged;

  const _SortOptionTile({
    required this.title,
    required this.value,
    required this.groupValue,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return RadioListTile<TransactionSortOption>(
      title: Text(title),
      value: value,
      groupValue: groupValue,
      onChanged: onChanged,
    );
  }
}

class _TransactionTile extends StatelessWidget {
  final TransactionItemEntity transaction;

  const _TransactionTile({required this.transaction});

  @override
  Widget build(BuildContext context) {
    final currencyFormat = NumberFormat.currency(symbol: '₹', decimalDigits: 2);
    final color = transaction.isCredit ? Colors.green : Colors.red;
    final sign = transaction.isCredit ? '+' : '-';

    return ListTile(
      leading: CircleAvatar(
        backgroundColor: color.withValues(alpha: 0.12),
        child: Icon(
          transaction.isCredit ? Icons.trending_up : Icons.trending_down,
          color: color,
        ),
      ),
      title: Text(
        transaction.categoryOrSource,
        style: const TextStyle(fontWeight: FontWeight.bold),
      ),
      subtitle: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(DateFormat('dd MMM yyyy, hh:mm a').format(transaction.date)),
          if (transaction.description.isNotEmpty)
            Text(
              transaction.description,
              style: const TextStyle(fontSize: 12, fontStyle: FontStyle.italic),
            ),
        ],
      ),
      trailing: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Text(
            '$sign${currencyFormat.format(transaction.amount)}',
            style: TextStyle(
              color: color,
              fontWeight: FontWeight.bold,
              fontSize: 15,
            ),
          ),
          Text(
            transaction.moduleType.toUpperCase(),
            style: const TextStyle(fontSize: 10, color: Colors.grey),
          ),
        ],
      ),
    );
  }
}
