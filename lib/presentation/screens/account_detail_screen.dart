import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../core/utils/currency_formatter.dart';
import '../../domain/entities/account_entity.dart';
import '../../domain/entities/transaction_entity.dart';
import '../viewmodels/account_detail_view_model.dart';

class AccountDetailScreen extends StatefulWidget {
  final AccountEntity account;

  const AccountDetailScreen({super.key, required this.account});

  @override
  State<AccountDetailScreen> createState() => _AccountDetailScreenState();
}

class _AccountDetailScreenState extends State<AccountDetailScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<AccountDetailViewModel>().loadTransactions(widget.account.id);
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

    DateTimeRange? tempDateRange = viewModel.dateRange;
    bool? tempIsCreditFilter = viewModel.isCreditFilter;
    String? tempModuleFilter = viewModel.moduleFilter;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) {
        return StatefulBuilder(
          builder: (BuildContext context, StateSetter setModalState) {
            return Padding(
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 24) +
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
                        style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
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
                  const SizedBox(height: 12),
                  const Text('Transaction Type', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8.0,
                    children: [
                      ChoiceChip(
                        label: const Text('All'),
                        selected: tempIsCreditFilter == null,
                        onSelected: (val) => setModalState(() => tempIsCreditFilter = null),
                      ),
                      ChoiceChip(
                        label: const Text('Inflow / Credit'),
                        selected: tempIsCreditFilter == true,
                        onSelected: (val) => setModalState(() => tempIsCreditFilter = true),
                      ),
                      ChoiceChip(
                        label: const Text('Outflow / Debit'),
                        selected: tempIsCreditFilter == false,
                        onSelected: (val) => setModalState(() => tempIsCreditFilter = false),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  const Text('Category Module', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                  const SizedBox(height: 8),
                  DropdownButtonFormField<String?>(
                    value: tempModuleFilter,
                    decoration: const InputDecoration(
                      border: OutlineInputBorder(borderRadius: BorderRadius.all(Radius.circular(12))),
                      contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    ),
                    items: const [
                      DropdownMenuItem(value: null, child: Text('All Modules')),
                      DropdownMenuItem(value: 'income', child: Text('Income')),
                      DropdownMenuItem(value: 'expense', child: Text('Expense')),
                      DropdownMenuItem(value: 'transfer', child: Text('Transfer')),
                      DropdownMenuItem(value: 'borrow', child: Text('Borrow')),
                      DropdownMenuItem(value: 'lend', child: Text('Lend')),
                      DropdownMenuItem(value: 'investment', child: Text('Investment')),
                      DropdownMenuItem(value: 'emi', child: Text('EMI/Loan')),
                      DropdownMenuItem(value: 'savings', child: Text('Savings')),
                    ],
                    onChanged: (val) {
                      setModalState(() => tempModuleFilter = val);
                    },
                  ),
                  const SizedBox(height: 16),
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    title: const Text('Date Range', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                    subtitle: Text(
                      tempDateRange == null
                          ? 'All time'
                          : '${DateFormat('dd MMM yyyy').format(tempDateRange!.start)} - ${DateFormat('dd MMM yyyy').format(tempDateRange!.end)}',
                    ),
                    trailing: Icon(Icons.calendar_today, color: Theme.of(context).colorScheme.primary, size: 18),
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
                  const SizedBox(height: 24),
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.all(14),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    ),
                    onPressed: () {
                      viewModel.setFilter(
                        dateRange: tempDateRange,
                        isCredit: tempIsCreditFilter,
                        moduleType: tempModuleFilter,
                      );
                      Navigator.pop(context);
                    },
                    child: const Text('Apply Filters', style: TextStyle(fontWeight: FontWeight.bold)),
                  ),
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
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        title: Text(widget.account.name, style: const TextStyle(fontWeight: FontWeight.w700)),
        elevation: 0,
        backgroundColor: Colors.transparent,
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
          final double calculatedBalance = viewModel.getAccountCalculatedBalance(widget.account.id);

          // Compute inflows and outflows for the visible transactions list
          double inflows = 0.0;
          double outflows = 0.0;
          for (final tx in transactions) {
            bool isTxCredit = false;
            if (tx.accountId == widget.account.id) {
              if (tx.type == TransactionType.income || tx.type == TransactionType.borrow) {
                isTxCredit = true;
              }
            } else if (tx.targetAccountId == widget.account.id) {
              isTxCredit = true;
            }

            if (isTxCredit) {
              inflows += tx.amount;
            } else {
              outflows += tx.amount;
            }
          }
          final double netCashFlow = inflows - outflows;

          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // ── Financial Summary Card ──────────────────────────────────
              Container(
                margin: const EdgeInsets.all(16),
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      Theme.of(context).colorScheme.primary.withOpacity(0.08),
                      Theme.of(context).colorScheme.primary.withOpacity(0.02),
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(color: Theme.of(context).colorScheme.primary.withOpacity(0.12)),
                ),
                child: Column(
                  children: [
                    const Text(
                      'AVAILABLE ACCOUNT BALANCE',
                      style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.grey, letterSpacing: 1.2),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      '$currencySymbol${calculatedBalance.toStringAsFixed(2)}',
                      style: TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                        color: Theme.of(context).colorScheme.primary,
                      ),
                    ),
                    const SizedBox(height: 16),
                    const Divider(),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        _buildFlowSummary(context, 'Inflow', inflows, Colors.green),
                        Container(width: 1, height: 24, color: Theme.of(context).dividerColor.withOpacity(0.12)),
                        _buildFlowSummary(context, 'Outflow', outflows, Colors.red),
                        Container(width: 1, height: 24, color: Theme.of(context).dividerColor.withOpacity(0.12)),
                        _buildFlowSummary(context, 'Net Flow', netCashFlow, netCashFlow >= 0 ? Colors.green : Colors.red),
                      ],
                    ),
                  ],
                ),
              ),

              // ── Timeline Section Header ─────────────────────────────────
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                child: Text(
                  'TRANSACTION TIMELINE',
                  style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.grey, letterSpacing: 1.2),
                ),
              ),

              // ── Grouped Timeline List ────────────────────────────────────
              Expanded(
                child: transactions.isEmpty
                    ? const Center(
                        child: Text(
                          'No transactions found for this account.',
                          style: TextStyle(color: Colors.grey, fontStyle: FontStyle.italic),
                        ),
                      )
                    : ListView.builder(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        itemCount: transactions.length,
                        itemBuilder: (context, index) {
                          final tx = transactions[index];
                          return _TransactionTile(
                            transaction: tx,
                            accountId: widget.account.id,
                          );
                        },
                      ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildFlowSummary(BuildContext context, String title, double value, Color color) {
    return Expanded(
      child: Column(
        children: [
          Text(title, style: const TextStyle(fontSize: 10, color: Colors.grey, fontWeight: FontWeight.bold)),
          const SizedBox(height: 4),
          Text(
            '$currencySymbol${value.toStringAsFixed(0)}',
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: color),
            overflow: TextOverflow.ellipsis,
          ),
        ],
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
      activeColor: Theme.of(context).colorScheme.primary,
      onChanged: onChanged,
    );
  }
}

class _TransactionTile extends StatelessWidget {
  final TransactionEntity transaction;
  final String accountId;

  const _TransactionTile({required this.transaction, required this.accountId});

  @override
  Widget build(BuildContext context) {
    bool isCredit = false;
    if (transaction.accountId == accountId) {
      if (transaction.type == TransactionType.income ||
          transaction.type == TransactionType.borrow) {
        isCredit = true;
      }
    } else if (transaction.targetAccountId == accountId) {
      isCredit = true;
    }

    final color = isCredit ? Colors.green : Colors.red;
    final sign = isCredit ? '+' : '-';

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Theme.of(context).dividerColor.withOpacity(0.04)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: color.withOpacity(0.08),
              shape: BoxShape.circle,
            ),
            child: Icon(
              isCredit ? Icons.arrow_downward : Icons.arrow_upward,
              color: color,
              size: 16,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  transaction.categoryOrSource,
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                ),
                const SizedBox(height: 4),
                Text(
                  DateFormat('dd MMM yyyy, hh:mm a').format(transaction.date),
                  style: const TextStyle(fontSize: 11, color: Colors.grey),
                ),
                if (transaction.description.isNotEmpty) ...[
                  const SizedBox(height: 2),
                  Text(
                    transaction.description,
                    style: const TextStyle(fontSize: 11, fontStyle: FontStyle.italic, color: Colors.grey),
                  ),
                ],
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                '$sign$currencySymbol${transaction.amount.toStringAsFixed(2)}',
                style: TextStyle(
                  color: color,
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                ),
              ),
              const SizedBox(height: 2),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: Theme.of(context).dividerColor.withOpacity(0.06),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  transaction.type.name.toUpperCase(),
                  style: const TextStyle(fontSize: 8, color: Colors.grey, fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
